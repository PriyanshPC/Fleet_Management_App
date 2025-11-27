using System;
using System.Collections.Generic;
using System.Linq;
using Fleet_Management_App.Entities;
using Fleet_Management_App.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Controllers
{
    /// <summary>
    /// Handles the main fleet dashboard. All numbers and tables are driven from the database.
    /// </summary>
    [Authorize]
    public class DashboardController : Controller
    {
        private readonly GhostbustersFleetContext _context;

        public DashboardController(GhostbustersFleetContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Main dashboard view.
        /// </summary>
        public IActionResult Index()
        {
            var viewModel = new DashboardViewModel
            {
                Kpi = BuildKpi(),
                Availability = BuildAvailability(),
                MaintDonut = BuildMaintenanceDonut(),
                ActiveRentals = BuildScheduledRentals()
            };

            return View(viewModel);
        }

        /// <summary>
        /// Returns rental details as JSON so the dashboard can show them in a modal popup.
        /// </summary>
        [HttpGet]
        public IActionResult RentalDetails(Guid id)
        {
            var rental = _context.Rentals
                .Include(r => r.Customer)
                .Include(r => r.RentedEquipments)
                    .ThenInclude(re => re.Equipment)
                .FirstOrDefault(r => r.RentalId == id);

            if (rental == null)
            {
                return NotFound();
            }

            var dto = new
            {
                rentalId = rental.RentalId,
                rentalCode = GetRentalCode(rental),
                status = rental.Status,
                scope = rental.Scope,
                note = rental.Note,
                startDate = rental.StartDate.ToString("yyyy-MM-dd"),
                endDate = rental.EndDate.ToString("yyyy-MM-dd"),
                customerName = rental.Customer?.CustomerName,
                customerPhone = rental.Customer?.CustomerPhone,
                customerGovtId = rental.Customer?.CustomerGovtId,
                equipments = rental.RentedEquipments.Select(re => new
                {
                    code = re.Equipment.EquipmentCode,
                    //name = re.Equipment.EquipmentName,
                    category = re.Equipment.EquipmentCategory,
                    type = re.Equipment.EquipmentType
                }).ToList()
            };

            return Json(dto);
        }

        #region Private helpers

        /// <summary>
        /// Builds KPI numbers from the database.
        /// </summary>
        private DashboardKpi BuildKpi()
        {
            var today = DateOnly.FromDateTime(DateTime.Today);

            var totalEquipment = _context.Equipment.Count();

            // Rentals that are currently checked out and overlap today.
            var activeRentals = _context.Rentals.Count(r =>
                r.Status == "CheckedOut" &&
                r.StartDate <= today &&
                r.EndDate >= today);

            // Open maintenance events.
            var pendingMaintenance = _context.Maintenances.Count(m => m.Status == "Open");

            // Simple availability based on EquipmentAvailability flag.
            var fleetAvailable = _context.Equipment.Count(e => e.EquipmentAvailability == "Available");

            var fleetAvailablePct = totalEquipment == 0
                ? 0
                : (int)Math.Round(fleetAvailable * 100m / totalEquipment);

            return new DashboardKpi
            {
                TotalEquipment = totalEquipment,
                ActiveRentals = activeRentals,
                PendingMaintenance = pendingMaintenance,
                FleetAvailable = fleetAvailable,
                FleetAvailablePct = fleetAvailablePct
            };
        }

        /// <summary>
        /// Builds availability data grouped by category (for the bar chart).
        /// </summary>
        private List<AvailabilityByCategory> BuildAvailability()
        {
            return _context.Equipment
                .Where(e => e.EquipmentAvailability == "Available")
                .GroupBy(e => e.EquipmentCategory)
                .Select(g => new AvailabilityByCategory
                {
                    Category = g.Key,
                    Available = g.Count()
                })
                .OrderByDescending(x => x.Available)
                .ToList();
        }

        /// <summary>
        /// Builds donut data for maintenance:
        /// [OK (no open event), Scheduled (future NextServiceDue), Urgent (overdue NextServiceDue)].
        /// </summary>
        private List<int> BuildMaintenanceDonut()
        {
            var today = DateOnly.FromDateTime(DateTime.Today);

            var openMaint = _context.Maintenances
                .Where(m => m.Status == "Open");

                // "OK" = equipment with no open maintenance event.
            var equipmentIdsWithOpenMaint = openMaint
                .Select(m => m.EquipmentId)
                .Distinct()
                .ToList();

            var ok = _context.Equipment
                .Count(e => !equipmentIdsWithOpenMaint.Contains(e.EquipmentId));

            return new List<int> { ok};
        }

        /// <summary>
        /// Builds list of rentals that are scheduled for today and upcoming (Status = Reserved).
        /// </summary>
        private List<ActiveRentalRow> BuildScheduledRentals(int take = 20)
        {
            var today = DateOnly.FromDateTime(DateTime.Today);

            var rentals = _context.Rentals
                .Include(r => r.Customer)
                .Where(r =>
                    r.Status == "Reserved" &&
                    r.StartDate >= today)
                .OrderBy(r => r.StartDate)
                .ThenBy(r => r.RentalId)
                .Take(take)
                .ToList();

            string FormatDate(DateOnly d) =>
                d.ToDateTime(TimeOnly.MinValue).ToString("MMM dd");

            return rentals.Select(r =>
            {
                var client = r.Customer != null
                    ? r.Customer.CustomerName
                    : (r.Scope == "Internal" ? "Ghost Diagnostics" : "(No Customer)");

                return new ActiveRentalRow
                {
                    RentalCode = GetRentalCode(r),
                    Client = client,
                    Notes = r.Note ?? string.Empty,
                    OutDate = FormatDate(r.StartDate),
                    DueDate = FormatDate(r.EndDate),
                    Status = "Scheduled"
                };
            }).ToList();
        }

        /// <summary>
        /// Helper to get a safe rental code string.
        /// Expects Rental.RentalCode to exist; falls back to the Guid if needed.
        /// </summary>
        private static string GetRentalCode(Rental rental)
        {
            // If your Rental entity has a RentalCode property, use it via reflection.
            var codeProperty = rental.GetType().GetProperty("RentalCode");
            var fromProperty = codeProperty?.GetValue(rental) as string;

            if (!string.IsNullOrWhiteSpace(fromProperty))
            {
                return fromProperty;
            }

            // Fallback: short Guid
            return "#" + rental.RentalId.ToString()[..8].ToUpperInvariant();
        }

        #endregion
    }
}
