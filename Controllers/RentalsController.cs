using System;
using System.Linq;
using System.Threading.Tasks;
using Fleet_Management_App.Entities;
using Fleet_Management_App.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Controllers
{
    // Ensures only authenticated users can access rental management features
    [Authorize]
    public class RentalsController : Controller
    {
        private readonly GhostbustersFleetContext _context;

        public RentalsController(GhostbustersFleetContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Displays a list of all rental records from the database.
        /// </summary>
        public async Task<IActionResult> List()
        {
            var rentals = await _context.Rentals
                .Include(r => r.Customer)
                .OrderByDescending(r => r.StartDate)
                .ThenByDescending(r => r.RentalId)
                .ToListAsync();

            var today = DateOnly.FromDateTime(DateTime.Today);

            // Map DB rentals to lightweight list view models
            var model = rentals.Select(r =>
            {
                var baseStatus = r.Status ?? "Reserved"; // Draft | Reserved | CheckedOut | Returned | Overdue | Closed

                string uiStatus;
                if (string.Equals(baseStatus, "CheckedOut", StringComparison.OrdinalIgnoreCase) && r.EndDate < today)
                {
                    uiStatus = "Overdue";
                }
                else if (string.Equals(baseStatus, "CheckedOut", StringComparison.OrdinalIgnoreCase))
                {
                    uiStatus = "Checked Out";
                }
                else if (string.Equals(baseStatus, "Returned", StringComparison.OrdinalIgnoreCase))
                {
                    uiStatus = "Returned";
                }
                else if (string.Equals(baseStatus, "Closed", StringComparison.OrdinalIgnoreCase))
                {
                    uiStatus = "Closed";
                }
                else
                {
                    uiStatus = "Reserved";
                }

                var customerName = r.Customer != null
                    ? r.Customer.CustomerName
                    : (r.Scope == "Internal" ? "Ghost Diagnostics" : "(No customer)");

                return new RentalListViewModel
                {
                    RentalId = r.RentalId,
                    RentalCode = r.RentalCode,
                    CustomerName = customerName,
                    StartDate = r.StartDate,
                    EndDate = r.EndDate,
                    Status = uiStatus
                };
            }).ToList();

            return View(model);
        }

        /// <summary>
        /// Shows details for a specific rental, including rented equipment.
        /// </summary>
        /// <param name="id">RentalId (Guid).</param>
        public async Task<IActionResult> Details(Guid id)
        {
            var rental = await _context.Rentals
                .Include(r => r.Customer)
                .Include(r => r.RentedEquipments)
                    .ThenInclude(re => re.Equipment)
                .FirstOrDefaultAsync(r => r.RentalId == id);

            if (rental == null)
            {
                return NotFound();
            }

            var today = DateOnly.FromDateTime(DateTime.Today);

            // Base DB status
            var baseStatus = rental.Status ?? "Reserved";

            // UI-facing status + overdue flag (same idea as List())
            string uiStatus;
            var isOverdueUi = false;

            if (string.Equals(baseStatus, "CheckedOut", StringComparison.OrdinalIgnoreCase)
                && rental.EndDate < today)
            {
                uiStatus = "Overdue";
                isOverdueUi = true;
            }
            else if (string.Equals(baseStatus, "CheckedOut", StringComparison.OrdinalIgnoreCase))
            {
                uiStatus = "Checked Out";
            }
            else if (string.Equals(baseStatus, "Returned", StringComparison.OrdinalIgnoreCase))
            {
                uiStatus = "Returned";
            }
            else if (string.Equals(baseStatus, "Closed", StringComparison.OrdinalIgnoreCase))
            {
                uiStatus = "Closed";
            }
            else if (string.Equals(baseStatus, "Overdue", StringComparison.OrdinalIgnoreCase))
            {
                uiStatus = "Overdue";
                isOverdueUi = true;
            }
            else
            {
                uiStatus = "Reserved";
            }

            // Number of days for the rental (inclusive)
            var totalDays = (rental.EndDate.ToDateTime(TimeOnly.MinValue)
                             - rental.StartDate.ToDateTime(TimeOnly.MinValue)).Days + 1;
            if (totalDays <= 0)
            {
                totalDays = 1;
            }

            // Group RentedEquipment by Category + Type so we can show QTY/Rate/Subtotal
            var lines = new List<RentalDetailsEquipmentRow>();
            decimal subtotal = 0m;

            var groups = rental.RentedEquipments
                .GroupBy(re => new
                {
                    re.Equipment.EquipmentCategory,
                    re.Equipment.EquipmentType,
                    re.Equipment.EquipmentValue
                });

            foreach (var g in groups)
            {
                var quantity = g.Count();
                var equipmentValue = g.Key.EquipmentValue;
                var dailyRate = ComputeDailyRate(equipmentValue);
                var lineSubtotal = dailyRate * totalDays * quantity;

                subtotal += lineSubtotal;

                lines.Add(new RentalDetailsEquipmentRow
                {
                    Category = g.Key.EquipmentCategory,
                    Type = g.Key.EquipmentType,
                    Quantity = quantity,
                    DailyRate = dailyRate,
                    Subtotal = lineSubtotal
                });
            }

            var tax = Math.Round(subtotal * 0.13m, 2);
            var total = subtotal + tax;

            // Customer display name is the same pattern as in List()
            var customerName = rental.Customer != null
                ? rental.Customer.CustomerName
                : (rental.Scope == "Internal" ? "Ghost Diagnostics" : "(No customer)");

            var vm = new RentalDetailsViewModel
            {
                RentalId = rental.RentalId,
                RentalCode = rental.RentalCode,
                CustomerName = customerName,
                CustomerPhone = rental.Customer?.CustomerPhone,
                StartDate = rental.StartDate,
                EndDate = rental.EndDate,
                DbStatus = baseStatus,
                UiStatus = uiStatus,
                IsOverdueUi = isOverdueUi,
                Note = rental.Note,
                Lines = lines,
                Subtotal = subtotal,
                Tax = tax,
                Total = total
            };

            return View(vm);
        }


        /// <summary>
        /// Updates the status of a rental based on an action from the details page.
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateStatus(Guid id, string actionType)
        {
            if (string.IsNullOrWhiteSpace(actionType))
            {
                return RedirectToAction(nameof(Details), new { id });
            }

            var rental = await _context.Rentals
                .Include(r => r.RentedEquipments)
                    .ThenInclude(re => re.Equipment)
                .FirstOrDefaultAsync(r => r.RentalId == id);

            if (rental == null)
            {
                return NotFound();
            }

            switch (actionType)
            {
                case "CheckedOut":
                    // From Reserved -> CheckedOut
                    rental.Status = "CheckedOut";

                    foreach (var re in rental.RentedEquipments)
                    {
                        if (re.Equipment != null)
                        {
                            // Out with customer
                            re.Equipment.EquipmentAvailability = "OutForRental";
                        }
                    }
                    break;

                case "Returned":
                    // From CheckedOut -> Returned
                    rental.Status = "Returned";

                    // All equipment on this rental
                    var equipmentIds = rental.RentedEquipments
                        .Where(re => re.Equipment != null)
                        .Select(re => re.EquipmentId)
                        .ToList();

                    // Load any existing maintenance tickets for these units
                    var maintByEquip = await _context.Maintenances
                        .Where(m => equipmentIds.Contains(m.EquipmentId))
                        .ToDictionaryAsync(m => m.EquipmentId);

                    foreach (var re in rental.RentedEquipments)
                    {
                        if (re.Equipment == null) continue;

                        // Awaiting inspection
                        re.Equipment.EquipmentAvailability = "UnderMaintenance";

                        // Either reopen an existing ticket or create a new one
                        if (!maintByEquip.TryGetValue(re.EquipmentId, out var maint))
                        {
                            // No existing row for this equipment → create a new open ticket
                            maint = new Maintenance
                            {
                                EquipmentId = re.EquipmentId,
                                RentalId = rental.RentalId,
                                Status = "Open",
                                LastServiceDate = DateOnly.FromDateTime(DateTime.Today),
                                Outcome = null,
                                Technician = null,
                                Notes = null
                                // OpenDate will be filled by default constraint in DB
                            };

                            _context.Maintenances.Add(maint);
                            maintByEquip[re.EquipmentId] = maint;
                        }
                        else
                        {
                            // Reopen the ticket for this equipment
                            maint.Status = "Open";
                            maint.CloseDate = null;
                            maint.RentalId = rental.RentalId;
                            maint.LastServiceDate = DateOnly.FromDateTime(DateTime.Today);
                            // Outcome/Technician/Notes can stay as last record; UI already shows them as "last"
                        }
                    }

                    break;

                case "Cancel":
                    // Only allow cancel on Reserved / Draft rentals
                    if (string.Equals(rental.Status, "Reserved", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(rental.Status, "Draft", StringComparison.OrdinalIgnoreCase))
                    {
                        foreach (var re in rental.RentedEquipments)
                        {
                            if (re.Equipment != null &&
                                re.Equipment.EquipmentAvailability == "Unavailable")
                            {
                                // Back to free pool
                                re.Equipment.EquipmentAvailability = "Available";
                            }
                        }

                        // Remove rented equipment links, then the rental itself
                        _context.RentedEquipments.RemoveRange(rental.RentedEquipments);
                        _context.Rentals.Remove(rental);

                        await _context.SaveChangesAsync();

                        // After cancel, go back to list
                        return RedirectToAction(nameof(List));
                    }
                    break;

                // For now: Charge, Review, etc. are left for later wiring.
                default:
                    break;
            }

            await _context.SaveChangesAsync();

            // For status changes, return to the same rental details
            return RedirectToAction(nameof(Details), new { id });
        }


        /// <summary>
        /// Displays the New Rental page.
        /// </summary>
        [HttpGet]
        public IActionResult New() => View();

        /// <summary>
        /// Equipment catalog for the New Rental page:
        /// returns category / type / available units / daily rate.
        /// Only includes currently-available equipment.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> EquipmentCatalog()
        {
            var catalog = await _context.Equipment
                .Where(e => e.EquipmentAvailability == "Available")
                .GroupBy(e => new { e.EquipmentCategory, e.EquipmentType })
                .Select(g => new EquipmentTypeInfo
                {
                    Category = g.Key.EquipmentCategory,
                    Type = g.Key.EquipmentType,
                    Available = g.Count(),
                    DailyRate = ComputeDailyRate(g.Min(e => e.EquipmentValue))
                })
                .OrderBy(x => x.Category)
                .ThenBy(x => x.Type)
                .ToListAsync();

            return Json(catalog);
        }


        /// <summary>
        /// Lookup a customer by 10-digit phone (Canada/US).
        /// Matches by the last 10 digits so formats like "+1-416-555-0107"
        /// or "4165550107" both work.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> LookupCustomer(string phone)
        {
            var digits = ExtractLastTenDigits(phone);
            if (digits.Length != 10)
            {
                return Json(new CustomerLookupResult { Found = false });
            }

            // Small table, so pull into memory and do digit-only comparison.
            var all = await _context.Customers
                .AsNoTracking()
                .ToListAsync();

            var match = all.FirstOrDefault(c =>
                ExtractLastTenDigits(c.CustomerPhone) == digits);

            if (match == null)
            {
                return Json(new CustomerLookupResult { Found = false });
            }

            return Json(new CustomerLookupResult
            {
                Found = true,
                CustomerId = match.CustomerId,
                CustomerName = match.CustomerName,
                CustomerEmail = match.CustomerEmail,
                CustomerPhone = match.CustomerPhone,
                CustomerAddress = match.CustomerAddress,
                CustomerGovtId = match.CustomerGovtId
            });
        }

        /// <summary>
        /// Creates a new rental + customer update/create + rented equipment.
        /// Called via AJAX from the New Rental page.
        /// Status is created as "Reserved".
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] NewRentalRequest request)
        {
            if (request == null)
            {
                return BadRequest("Invalid payload.");
            }

            if (request.Items == null || request.Items.Count == 0)
            {
                return BadRequest("At least one equipment item is required.");
            }

            if (!DateOnly.TryParse(request.StartDate, out var start))
            {
                return BadRequest("Invalid start date.");
            }

            if (!DateOnly.TryParse(request.EndDate, out var end))
            {
                return BadRequest("Invalid end date.");
            }

            if (start > end)
            {
                return BadRequest("Start date cannot be after end date.");
            }

            var phoneDigits = ExtractLastTenDigits(request.CustomerPhone);
            if (phoneDigits.Length != 10)
            {
                return BadRequest("Customer phone must be a 10-digit Canada/US number.");
            }

            // Upsert customer: if we got an Id, update; otherwise create.
            Customer customer;
            if (request.CustomerId.HasValue)
            {
                customer = await _context.Customers
                    .FirstOrDefaultAsync(c => c.CustomerId == request.CustomerId.Value)
                    ?? new Customer();

                if (customer.CustomerId == Guid.Empty)
                {
                    _context.Customers.Add(customer);
                }
            }
            else
            {
                customer = new Customer();
                _context.Customers.Add(customer);
            }

            customer.CustomerName = request.CustomerName;
            customer.CustomerEmail = request.CustomerEmail;
            customer.CustomerAddress = request.CustomerAddress;
            customer.CustomerGovtId = request.CustomerGovtId;
            customer.CustomerPhone = FormatNorthAmericanPhone(phoneDigits);

            // Create rental
            var rental = new Rental
            {
                Customer = customer,
                StartDate = start,
                EndDate = end,
                Status = "Reserved",       // UI status mapping will show Reserved
                Note = request.Note,
                Scope = "External"         // you can extend UI later to pick Internal/External
            };

            _context.Rentals.Add(rental);

            // Compute days (inclusive)
            var totalDays = (end.ToDateTime(TimeOnly.MinValue) - start.ToDateTime(TimeOnly.MinValue)).Days + 1;
            if (totalDays <= 0)
            {
                totalDays = 1;
            }

            decimal subtotal = 0m;

            foreach (var item in request.Items)
            {
                if (item.Quantity <= 0)
                {
                    continue;
                }

                // Fetch available units for this category/type
                var units = await _context.Equipment
                    .Where(e =>
                        e.EquipmentCategory == item.Category &&
                        e.EquipmentType == item.Type &&
                        e.EquipmentAvailability == "Available")
                    .OrderBy(e => e.EquipmentCode)
                    .Take(item.Quantity)
                    .ToListAsync();

                if (units.Count < item.Quantity)
                {
                    return BadRequest($"Not enough available units for {item.Category} / {item.Type}.");
                }

                var dailyRate = item.DailyRate > 0
                    ? item.DailyRate
                    : units.First().EquipmentValue;

                var lineSubtotal = dailyRate * totalDays * item.Quantity;
                subtotal += lineSubtotal;

                foreach (var eq in units)
                {
                    // For a Reserved rental, mark the units as Unavailable
                    eq.EquipmentAvailability = "Unavailable";

                    _context.RentedEquipments.Add(new RentedEquipment
                    {
                        Rental = rental,
                        Equipment = eq
                    });
                }
            }

            await _context.SaveChangesAsync();

            // Ensure RentalCode is populated from DB default
            await _context.Entry(rental).ReloadAsync();

            var response = new NewRentalResponse
            {
                // Redirect straight to the rental details page
                DetailsUrl = Url.Action("Details", "Rentals", new { id = rental.RentalId })!
            };

            return Json(response);

        }


        // GET: /Rentals/Edit/{id}
        [HttpGet]
        public async Task<IActionResult> Edit(Guid id)
        {
            var rental = await _context.Rentals
                .Include(r => r.Customer)
                .Include(r => r.RentedEquipments)
                    .ThenInclude(re => re.Equipment)
                .FirstOrDefaultAsync(r => r.RentalId == id);

            if (rental == null)
            {
                return NotFound();
            }

            return View(rental); // View is Edit.cshtml with @model Rental
        }

        // POST: /Rentals/Edit
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(EditRentalPostModel model)
        {
            if (!DateOnly.TryParse(model.StartDate, out var start))
            {
                ModelState.AddModelError("", "Invalid start date.");
            }
            if (!DateOnly.TryParse(model.EndDate, out var end))
            {
                ModelState.AddModelError("", "Invalid end date.");
            }
            if (ModelState.ErrorCount > 0)
            {
                // Reload rental for redisplay
                var rentalForView = await _context.Rentals
                    .Include(r => r.Customer)
                    .Include(r => r.RentedEquipments)
                        .ThenInclude(re => re.Equipment)
                    .FirstOrDefaultAsync(r => r.RentalId == model.RentalId);

                if (rentalForView == null)
                {
                    return NotFound();
                }

                return View(rentalForView);
            }

            var rental = await _context.Rentals
                .Include(r => r.RentedEquipments)
                    .ThenInclude(re => re.Equipment)
                .FirstOrDefaultAsync(r => r.RentalId == model.RentalId);

            if (rental == null)
            {
                return NotFound();
            }

            var status = rental.Status ?? "Reserved";

            if (status.Equals("Reserved", StringComparison.OrdinalIgnoreCase))
            {
                // Update dates & note
                rental.StartDate = start;
                rental.EndDate = end;
                rental.Note = string.IsNullOrWhiteSpace(model.Note) ? null : model.Note.Trim();

                // Release existing equipment
                foreach (var re in rental.RentedEquipments)
                {
                    re.Equipment.EquipmentAvailability = "Available";
                }

                _context.RentedEquipments.RemoveRange(rental.RentedEquipments);

                // Re-attach equipment using Items from form
                foreach (var item in model.Items.Where(i => i.Quantity > 0))
                {
                    var units = await _context.Equipment
                        .Where(e =>
                            e.EquipmentCategory == item.Category &&
                            e.EquipmentType == item.Type &&
                            e.EquipmentAvailability == "Available")
                        .OrderBy(e => e.EquipmentCode)
                        .Take(item.Quantity)
                        .ToListAsync();

                    if (units.Count < item.Quantity)
                    {
                        ModelState.AddModelError("",
                            $"Not enough available units for {item.Category} / {item.Type}.");

                        // Reload original rental for redisplay
                        var rentalForView = await _context.Rentals
                            .Include(r => r.Customer)
                            .Include(r => r.RentedEquipments)
                                .ThenInclude(re => re.Equipment)
                            .FirstOrDefaultAsync(r => r.RentalId == model.RentalId);

                        return View(rentalForView!);
                    }

                    foreach (var eq in units)
                    {
                        eq.EquipmentAvailability = "Unavailable";

                        _context.RentedEquipments.Add(new RentedEquipment
                        {
                            RentalId = rental.RentalId,
                            EquipmentId = eq.EquipmentId
                        });
                    }
                }
            }
            else if (status.Equals("CheckedOut", StringComparison.OrdinalIgnoreCase))
            {
                // Only allow end date + note
                rental.EndDate = end;
                rental.Note = string.IsNullOrWhiteSpace(model.Note) ? null : model.Note.Trim();
            }
            else
            {
                ModelState.AddModelError("", "This rental cannot be edited in its current status.");

                var rentalForView = await _context.Rentals
                    .Include(r => r.Customer)
                    .Include(r => r.RentedEquipments)
                        .ThenInclude(re => re.Equipment)
                    .FirstOrDefaultAsync(r => r.RentalId == model.RentalId);

                return View(rentalForView!);
            }

            await _context.SaveChangesAsync();

            // Normal MVC redirect, no AJAX
            return RedirectToAction(nameof(Details), new { id = rental.RentalId });
        }




        #region Private helpers

        private static string ExtractLastTenDigits(string? phone)
        {
            if (string.IsNullOrWhiteSpace(phone))
            {
                return string.Empty;
            }

            var digits = new string(phone.Where(char.IsDigit).ToArray());
            if (digits.Length <= 10)
            {
                return digits;
            }

            return digits[^10..];
        }

        private static string FormatNorthAmericanPhone(string digits)
        {
            if (string.IsNullOrWhiteSpace(digits) || digits.Length != 10)
            {
                return digits;
            }

            var area = digits[..3];
            var mid = digits.Substring(3, 3);
            var last = digits.Substring(6, 4);
            return $"+1-{area}-{mid}-{last}";
        }

        private static decimal ComputeDailyRate(decimal equipmentValue)
        {
            if (equipmentValue >= 80000m) return equipmentValue * 0.005m;   // 0.5%
            if (equipmentValue >= 50000m) return equipmentValue * 0.0075m;  // 0.75%
            if (equipmentValue >= 25000m) return equipmentValue * 0.010m;   // 1.0%
            if (equipmentValue >= 10000m) return equipmentValue * 0.0125m;  // 1.25%
            if (equipmentValue >= 1000m) return equipmentValue * 0.0175m;  // 1.75%
            return equipmentValue * 0.02m;                                  // 2.0%
        }
        #endregion
    }
}
