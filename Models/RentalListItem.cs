namespace Fleet_Management_App.Models
{
    public class RentalListItem
    {
        public string Id { get; set; } = "";
        public string Client { get; set; } = "";
        public string Category { get; set; } = "";
        public string Items { get; set; } = "";
        public DateTime Out { get; set; }
        public DateTime Due { get; set; }
        public string Status { get; set; } = ""; // On Rent, Due Soon, Overdue, Returned, Cancelled, Scheduled
        public decimal Total { get; set; }
    }
}
