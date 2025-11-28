using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Fleet_Management_App.Models
{
    /// <summary>
    /// Represents a row in the maintenance tickets tables.
    /// </summary>
    public class MaintenanceTicketRow
    {
        public Guid MaintenanceId { get; set; }

        public string TicketCode { get; set; } = string.Empty;

        /// <summary>Equipment business-facing code (e.g., EQP-SUV-0001).</summary>
        public string EquipmentCode { get; set; } = string.Empty;

        /// <summary>Equipment type (e.g., SUV, Drone, Proton Pack).</summary>
        public string EquipmentType { get; set; } = string.Empty;

        /// <summary>Ticket opened date.</summary>
        public DateTime OpenDate { get; set; }

        /// <summary>Ticket closed date (only set for completed tickets).</summary>
        public DateTime? CloseDate { get; set; }

        /// <summary>Technician who last worked on this ticket.</summary>
        public string? Technician { get; set; }
    }

    /// <summary>
    /// View model for the right-hand "Add Maintenance Record" panel.
    /// </summary>
    public class MaintenanceFormViewModel
    {
        public Guid MaintenanceId { get; set; }

        // Static info (read-only in the UI)
        public string TicketCode { get; set; } = string.Empty;
        public string EquipmentCode { get; set; } = string.Empty;
        public string EquipmentDescription { get; set; } = string.Empty;
        public DateTime OpenDate { get; set; }
        public string? LastRentalCode { get; set; }
        public string? LastTechnicianName { get; set; }
        public string? LastNotes { get; set; }

        // Dynamic fields (technician input)
        [Required]
        [Display(Name = "Status")]
        public string Outcome { get; set; } = string.Empty; // "Working" / "Damaged"

        [Required]
        [Display(Name = "Technician Name")]
        public string Technician { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Maintenance Notes")]
        public string Notes { get; set; } = string.Empty;
    }

    /// <summary>
    /// Main view model for the Maintenance/Index page.
    /// </summary>
    public class MaintenanceIndexViewModel
    {
        public List<MaintenanceTicketRow> CurrentTickets { get; set; } = new();
        public List<MaintenanceTicketRow> CompletedTickets { get; set; } = new();

        /// <summary>
        /// Initially-selected ticket for the right-hand details panel.
        /// </summary>
        public MaintenanceFormViewModel? SelectedTicket { get; set; }
    }
}
