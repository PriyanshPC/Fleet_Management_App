using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Data.Entities;

[Table("Rental")]
public partial class Rental
{
    [Key]
    public Guid RentalId { get; set; }

    [StringLength(32)]
    [Unicode(false)]
    public string RentalCode { get; set; } = null!;

    public Guid? CustomerId { get; set; }

    public DateOnly StartDate { get; set; }

    public DateOnly EndDate { get; set; }

    [StringLength(20)]
    public string Status { get; set; } = null!;

    public string? Note { get; set; }

    [StringLength(20)]
    public string? Scope { get; set; }

    [ForeignKey("CustomerId")]
    [InverseProperty("Rentals")]
    public virtual Customer? Customer { get; set; }

    [InverseProperty("Rental")]
    public virtual ICollection<MaintenanceEvent> MaintenanceEvents { get; set; } = new List<MaintenanceEvent>();

    [InverseProperty("Rental")]
    public virtual ICollection<RentedEquipment> RentedEquipments { get; set; } = new List<RentedEquipment>();
}
