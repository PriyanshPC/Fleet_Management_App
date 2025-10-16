namespace Fleet_Management_App.Models
{
    public class DashboardKpi
    {
        public int TotalEquipment { get; set; }
        public int ActiveRentals { get; set; }
        public int PendingMaintenance { get; set; }
        public int FleetAvailable { get; set; }   // count
        public int FleetAvailablePct { get; set; } // 0-100
        public int AddedThisWeek { get; set; }
        public int ActiveRentalsTodayDelta { get; set; }  // +/- change
        public int PendingMaintDelta { get; set; }        // +/- change
    }

    public class AvailabilityByCategory
    {
        public string Category { get; set; } = "";
        public int Available { get; set; }
    }

    public class ActiveRentalRow
    {
        public string RentalId { get; set; } = "";
        public string Client { get; set; } = "";
        public string Items { get; set; } = "";
        public string OutDate { get; set; } = ""; // keep as string for now
        public string DueDate { get; set; } = "";
        public string Status { get; set; } = "";  // On Rent, Due Soon, On Track, Overdue
    }

    public class DashboardViewModel
    {
        public DashboardKpi Kpi { get; set; } = new();
        public List<AvailabilityByCategory> Availability { get; set; } = new();
        public List<int> MaintDonut { get; set; } = new(); // [ok, scheduled, urgent]
        public List<ActiveRentalRow> ActiveRentals { get; set; } = new();
    }
}
