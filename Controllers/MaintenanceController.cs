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
    // Restricts access to authenticated users only
    [Authorize]
    public class MaintenanceController : Controller
    {
        private readonly GhostbustersFleetContext _context;

        public MaintenanceController(GhostbustersFleetContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Main maintenance workspace.
        /// Left side: current/completed tickets tables.
        /// Right side: Add Maintenance Record panel for the selected open ticket.
        /// </summary>
        public async Task<IActionResult> Index()
        {
            var vm = await BuildIndexViewModel(selectedId: null);
            return View(vm);
        }

        /// <summary>
        /// Returns full ticket details for a given maintenance ID as JSON.
        /// Used by the UI when clicking rows in the tables.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Ticket(Guid id)
        {
            var m = await _context.Maintenances
                .Include(x => x.Equipment)
                .Include(x => x.Rental)
                .FirstOrDefaultAsync(x => x.MaintenanceId == id);

            if (m == null)
            {
                return NotFound();
            }

            var dto = new
            {
                id = m.MaintenanceId,
                ticketCode = m.MaintenanceCode,
                equipmentCode = m.Equipment.EquipmentCode,
                equipmentType = m.Equipment.EquipmentType,
                equipmentDescription = m.Equipment.EquipmentDescription ?? string.Empty,
                openedDate = m.OpenDate.ToString("yyyy-MM-dd"),
                closedDate = m.CloseDate?.ToString("yyyy-MM-dd HH:mm"),
                status = m.Status,
                outcome = m.Outcome,
                lastRentalCode = m.Rental?.RentalCode,
                lastTechnicianName = m.Technician,
                lastNotes = m.Notes
            };

            return Json(dto);
        }

        /// <summary>
        /// Closes an open maintenance ticket and records the outcome + technician input.
        /// Invoked after the user confirms the popup.
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Complete(MaintenanceFormViewModel model)
        {
            if (!ModelState.IsValid)
            {
                var vmInvalid = await BuildIndexViewModel(model.MaintenanceId);
                vmInvalid.SelectedTicket ??= model;
                return View("Index", vmInvalid);
            }

            var m = await _context.Maintenances
                .Include(x => x.Equipment)
                .FirstOrDefaultAsync(x => x.MaintenanceId == model.MaintenanceId);

            if (m == null || m.Status != "Open")
            {
                return NotFound();
            }

            // Map dynamic fields (Outcome=Working/Damaged, Status=Open/Closed) :contentReference[oaicite:1]{index=1}
            m.Outcome = model.Outcome;
            m.Technician = model.Technician;
            m.Notes = model.Notes;
            m.Status = "Closed";
            m.CloseDate = DateTime.UtcNow;

            // Update equipment availability based on outcome (Available/Damaged) :contentReference[oaicite:2]{index=2}
            if (string.Equals(model.Outcome, "Working", StringComparison.OrdinalIgnoreCase))
            {
                m.Equipment.EquipmentAvailability = "Available";
            }
            else if (string.Equals(model.Outcome, "Damaged", StringComparison.OrdinalIgnoreCase))
            {
                m.Equipment.EquipmentAvailability = "Damaged";
            }

            await _context.SaveChangesAsync();

            // Refresh page with updated data
            return RedirectToAction(nameof(Index));
        }

        #region Private helpers

        private async Task<MaintenanceIndexViewModel> BuildIndexViewModel(Guid? selectedId)
        {
            var maintQuery = _context.Maintenances
                .Include(m => m.Equipment)
                .Include(m => m.Rental)
                .OrderByDescending(m => m.OpenDate);

            var all = await maintQuery.ToListAsync();

            var current = all
                .Where(m => m.Status == "Open")
                .Select(m => new MaintenanceTicketRow
                {
                    MaintenanceId = m.MaintenanceId,
                    TicketCode = m.MaintenanceCode,
                    EquipmentCode = m.Equipment.EquipmentCode,
                    EquipmentType = m.Equipment.EquipmentType,
                    OpenDate = m.OpenDate,
                    CloseDate = m.CloseDate,
                    Technician = m.Technician
                })
                .ToList();

            var completed = all
                .Where(m => m.Status != "Open")
                .Select(m => new MaintenanceTicketRow
                {
                    MaintenanceId = m.MaintenanceId,
                    TicketCode = m.MaintenanceCode,
                    EquipmentCode = m.Equipment.EquipmentCode,
                    EquipmentType = m.Equipment.EquipmentType,
                    OpenDate = m.OpenDate,
                    CloseDate = m.CloseDate,
                    Technician = m.Technician
                })
                .ToList();

            MaintenanceFormViewModel? selectedVm = null;

            var selectedMaintenance = selectedId.HasValue
                ? all.FirstOrDefault(x => x.MaintenanceId == selectedId.Value && x.Status == "Open")
                : all.FirstOrDefault(x => x.Status == "Open");

            if (selectedMaintenance != null)
            {
                selectedVm = BuildFormViewModel(selectedMaintenance);
            }

            return new MaintenanceIndexViewModel
            {
                CurrentTickets = current,
                CompletedTickets = completed,
                SelectedTicket = selectedVm
            };
        }

        private MaintenanceFormViewModel BuildFormViewModel(Maintenance m)
        {
            return new MaintenanceFormViewModel
            {
                MaintenanceId = m.MaintenanceId,
                TicketCode = m.MaintenanceCode,
                EquipmentCode = m.Equipment.EquipmentCode,
                EquipmentDescription = m.Equipment.EquipmentDescription ?? string.Empty,
                OpenDate = m.OpenDate,
                LastRentalCode = m.Rental?.RentalCode,
                LastTechnicianName = m.Technician,
                LastNotes = m.Notes
            };
        }

        #endregion
    }
}
