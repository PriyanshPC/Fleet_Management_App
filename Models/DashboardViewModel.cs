namespace Fleet_Management_App.Models
{
    /// <summary>
    /// Represents key performance indicators for the dashboard.
    /// </summary>
    public class DashboardKpi
    {
        /// <summary>Total number of equipment items in the fleet.</summary>
        public int TotalEquipment { get; set; }

        /// <summary>Number of rentals currently active.</summary>
        public int ActiveRentals { get; set; }

        /// <summary>Number of equipment items pending maintenance.</summary>
        public int PendingMaintenance { get; set; }

        /// <summary>Number of fleet vehicles or items currently available.</summary>
        public int FleetAvailable { get; set; }

        /// <summary>Percentage of fleet available (0-100).</summary>
        public int FleetAvailablePct { get; set; }

        /// <summary>Number of equipment items added to the fleet this week.</summary>
        public int AddedThisWeek { get; set; }

        /// <summary>Change in active rentals today (positive or negative delta).</summary>
        public int ActiveRentalsTodayDelta { get; set; }

        /// <summary>Change in pending maintenance items (positive or negative delta).</summary>
        public int PendingMaintDelta { get; set; }
    }

    /// <summary>
    /// Represents the availability of equipment by category.
    /// </summary>
    public class AvailabilityByCategory
    {
        /// <summary>Name of the equipment category.</summary>
        public string Category { get; set; } = "";

        /// <summary>Number of available items in this category.</summary>
        public int Available { get; set; }
    }

    /// <summary>
    /// Represents a row of data for an active rental displayed on the dashboard.
    /// </summary>
    public class ActiveRentalRow
    {
        /// <summary>Unique identifier for the rental.</summary>
        public string RentalId { get; set; } = "";

        /// <summary>Name of the client renting the equipment.</summary>
        public string Client { get; set; } = "";

        /// <summary>List of items included in the rental.</summary>
        public string Items { get; set; } = "";

        /// <summary>Date when the rental started (string format).</summary>
        public string OutDate { get; set; } = "";

        /// <summary>Date when the rental is due (string format).</summary>
        public string DueDate { get; set; } = "";

        /// <summary>Status of the rental (e.g., On Rent, Due Soon, On Track, Overdue).</summary>
        public string Status { get; set; } = "";
    }

    /// <summary>
    /// ViewModel for the dashboard, aggregating KPIs, availability, maintenance, and active rentals.
    /// </summary>
    public class DashboardViewModel
    {
        /// <summary>Key performance indicators for the dashboard.</summary>
        public DashboardKpi Kpi { get; set; } = new();

        /// <summary>Availability of equipment grouped by category.</summary>
        public List<AvailabilityByCategory> Availability { get; set; } = new();

        /// <summary>Maintenance status donut chart data: [ok, scheduled, urgent].</summary>
        public List<int> MaintDonut { get; set; } = new();

        /// <summary>List of currently active rentals.</summary>
        public List<ActiveRentalRow> ActiveRentals { get; set; } = new();
    }
}