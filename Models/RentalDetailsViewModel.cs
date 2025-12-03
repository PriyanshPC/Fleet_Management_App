using System;
using System.Collections.Generic;

namespace Fleet_Management_App.Models
{
    public class RentalDetailsEquipmentRow
    {
        public string Category { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal DailyRate { get; set; }
        public decimal Subtotal { get; set; }
    }

    public class RentalDetailsViewModel
    {
        // Header (Rental Details card)
        public Guid RentalId { get; set; }
        public string RentalCode { get; set; } = string.Empty;

        public string CustomerName { get; set; } = string.Empty;
        public string? CustomerPhone { get; set; }

        public DateOnly StartDate { get; set; }
        public DateOnly EndDate { get; set; }

        /// <summary>Raw value from DB: Draft | Reserved | CheckedOut | Returned | Overdue | Closed.</summary>
        public string DbStatus { get; set; } = string.Empty;

        /// <summary>UI-facing label: Reserved / Checked Out / Returned / Overdue / Closed.</summary>
        public string UiStatus { get; set; } = string.Empty;

        /// <summary>Is the status pill displayed as Overdue in the UI?</summary>
        public bool IsOverdueUi { get; set; }

        /// <summary>True when UI shows Overdue and DB status is Overdue (Scenario 1).</summary>
        public bool IsOverdueScenario1 =>
            IsOverdueUi && string.Equals(DbStatus, "Overdue", StringComparison.OrdinalIgnoreCase);

        /// <summary>True when UI shows Overdue but DB status is CheckedOut (Scenario 2).</summary>
        public bool IsOverdueScenario2 =>
            IsOverdueUi && string.Equals(DbStatus, "CheckedOut", StringComparison.OrdinalIgnoreCase);

        // Notes card
        public string? Note { get; set; }

        // Rented Equipment card
        public List<RentalDetailsEquipmentRow> Lines { get; set; } = new();

        public decimal Subtotal { get; set; }
        public decimal Tax { get; set; }
        public decimal Total { get; set; }

        // Convenience flags for the Actions card
        public bool CanEdit =>
            !string.Equals(DbStatus, "Closed", StringComparison.OrdinalIgnoreCase);

        public bool CanCancel =>
            string.Equals(DbStatus, "Reserved", StringComparison.OrdinalIgnoreCase);

        public bool CanCheckout =>
            string.Equals(DbStatus, "Reserved", StringComparison.OrdinalIgnoreCase);

        public bool CanMarkReturned =>
            string.Equals(DbStatus, "CheckedOut", StringComparison.OrdinalIgnoreCase);

        public bool CanReview =>
            string.Equals(DbStatus, "Returned", StringComparison.OrdinalIgnoreCase);
    }
}
