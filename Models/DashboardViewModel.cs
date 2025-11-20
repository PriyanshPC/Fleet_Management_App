using System.Collections.Generic;

namespace Fleet_Management_App.Models
{
    /// <summary>
    /// Represents key performance indicators for the dashboard.
    /// </summary>
    public class DashboardKpi
    {
        /// <summary>Total number of equipment items in the fleet.</summary>
        public int TotalEquipment { get; set; }

        /// <summary>Number of rentals currently checked out (on rent).</summary>
        public int ActiveRentals { get; set; }

        /// <summary>Number of equipment items with open maintenance.</summary>
        public int PendingMaintenance { get; set; }

        /// <summary>Number of equipment items currently available.</summary>
        public int FleetAvailable { get; set; }

        /// <summary>Percentage of fleet that is available.</summary>
        public int FleetAvailablePct { get; set; }

        // The following are kept for future use, but not shown in the UI now
        public int AddedThisWeek { get; set; }
        public int ActiveRentalsTodayDelta { get; set; }
        public int PendingMaintDelta { get; set; }
    }

    /// <summary>
    /// Represents availability of equipment for a specific category.
    /// </summary>
    public class AvailabilityByCategory
    {
        /// <summary>Category name (e.g., PPE, Vehicles, Drones).</summary>
        public string Category { get; set; } = string.Empty;

        /// <summary>Number of equipment items available in this category.</summary>
        public int Available { get; set; }
    }

    /// <summary>
    /// Represents a single row in the scheduled/upcoming rentals table.
    /// </summary>
    public class ActiveRentalRow
    {
        /// <summary>Rental code from the Rental table (e.g., RT-1234).</summary>
        public string RentalCode { get; set; } = string.Empty;

        /// <summary>Client name (or internal team name).</summary>
        public string Client { get; set; } = string.Empty;

        /// <summary>Notes for the rental.</summary>
        public string Notes { get; set; } = string.Empty;

        /// <summary>Formatted start date (e.g., Nov 19).</summary>
        public string OutDate { get; set; } = string.Empty;

        /// <summary>Formatted end date (e.g., Nov 22).</summary>
        public string DueDate { get; set; } = string.Empty;

        /// <summary>
        /// Status label for UI: for this dashboard section it will be "Scheduled".
        /// (Kept flexible if you later want variants.)
        /// </summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>Scope: "Internal" vs "External" (for modal details).</summary>
        public string Scope { get; set; } = string.Empty;
    }

    /// <summary>
    /// View model for the main fleet dashboard.
    /// </summary>
    public class DashboardViewModel
    {
        /// <summary>Key performance indicators for the dashboard.</summary>
        public DashboardKpi Kpi { get; set; } = new();

        /// <summary>Availability of equipment grouped by category.</summary>
        public List<AvailabilityByCategory> Availability { get; set; } = new();

        /// <summary>Maintenance status donut chart data: [ok, scheduled, urgent].</summary>
        public List<int> MaintDonut { get; set; } = new();

        /// <summary>Scheduled rentals for today and upcoming.</summary>
        public List<ActiveRentalRow> ActiveRentals { get; set; } = new();
    }
}
