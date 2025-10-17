namespace Fleet_Management_App.Models
{
    /// <summary>
    /// Represents a single rental transaction in the fleet management system.
    /// </summary>
    public class RentalListItem
    {
        /// <summary>
        /// Unique identifier for the rental (e.g., "R-1035").
        /// </summary>
        public string Id { get; set; } = "";

        /// <summary>
        /// Name of the client who made the rental.
        /// </summary>
        public string Client { get; set; } = "";

        /// <summary>
        /// Category of the rented items (e.g., Cameras, Drones, Vehicles).
        /// </summary>
        public string Category { get; set; } = "";

        /// <summary>
        /// Description or list of items included in the rental.
        /// </summary>
        public string Items { get; set; } = "";

        /// <summary>
        /// Date when the rental period starts.
        /// </summary>
        public DateTime Out { get; set; }

        /// <summary>
        /// Date when the rental is due to be returned.
        /// </summary>
        public DateTime Due { get; set; }

        /// <summary>
        /// Current status of the rental (e.g., On Rent, Due Soon, Overdue, Returned, Cancelled, Scheduled).
        /// </summary>
        public string Status { get; set; } = "";

        /// <summary>
        /// Total cost of the rental.
        /// </summary>
        public decimal Total { get; set; }
    }
}
