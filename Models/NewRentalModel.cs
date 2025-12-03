using System;
using System.Collections.Generic;

namespace Fleet_Management_App.Models
{
    /// <summary>
    /// Projection of a category/type combo and its availability
    /// for the Add Equipment dropdown on New Rental.
    /// </summary>
    public class EquipmentTypeInfo
    {
        public string Category { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int Available { get; set; }
        public decimal DailyRate { get; set; }
    }

    /// <summary>
    /// Result returned when looking up a customer by phone number.
    /// </summary>
    public class CustomerLookupResult
    {
        public bool Found { get; set; }

        public Guid? CustomerId { get; set; }
        public string? CustomerName { get; set; }
        public string? CustomerEmail { get; set; }
        public string? CustomerPhone { get; set; }
        public string? CustomerAddress { get; set; }
        public string? CustomerGovtId { get; set; }
    }

    /// <summary>
    /// Single equipment line in the New Rental request.
    /// </summary>
    public class NewRentalItem
    {
        public string Category { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal DailyRate { get; set; }
    }

    /// <summary>
    /// Payload posted from the New Rental page as JSON.
    /// </summary>
    public class NewRentalRequest
    {
        // Customer
        public Guid? CustomerId { get; set; }          // existing customer (if found by phone)
        public string CustomerName { get; set; } = string.Empty;
        public string? CustomerEmail { get; set; }
        public string? CustomerPhone { get; set; }     // raw from input (we normalize in controller)
        public string? CustomerAddress { get; set; }
        public string? CustomerGovtId { get; set; }

        // Dates (ISO yyyy-MM-dd from the date inputs)
        public string StartDate { get; set; } = string.Empty;
        public string EndDate { get; set; } = string.Empty;

        public string? Note { get; set; }

        public List<NewRentalItem> Items { get; set; } = new();
    }

    public class NewRentalResponse
    {
        public string DetailsUrl { get; set; } = string.Empty;

    }

    public class EditRentalItemDto
    {
        public string Category { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public int Quantity { get; set; }
    }

    public class EditRentalPostModel
    {
        public Guid RentalId { get; set; }
        public string Status { get; set; } = string.Empty;
        public string StartDate { get; set; } = string.Empty;
        public string EndDate { get; set; } = string.Empty;
        public string? Note { get; set; }

        // Only used / honoured when status is Reserved.
        public List<EditRentalItemDto> Items { get; set; } = new();
    }
}
