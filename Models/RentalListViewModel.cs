using System;

namespace Fleet_Management_App.Models
{
    /// <summary>
    /// Lightweight projection of Rental used on the list page.
    /// </summary>
    public class RentalListViewModel
    {
        /// <summary>Database primary key for the rental.</summary>
        public Guid RentalId { get; set; }

        /// <summary>Business-facing rental code (e.g., RT-0001).</summary>
        public string RentalCode { get; set; } = string.Empty;

        /// <summary>Customer / client name to display.</summary>
        public string CustomerName { get; set; } = string.Empty;

        /// <summary>Rental start date.</summary>
        public DateOnly StartDate { get; set; }

        /// <summary>Rental end / due date.</summary>
        public DateOnly EndDate { get; set; }

        /// <summary>
        /// UI-facing status label:
        /// Reserved / Checked Out / Returned / Overdue / Closed.
        /// </summary>
        public string Status { get; set; } = string.Empty;
    }
}
