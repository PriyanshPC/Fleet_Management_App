using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Data.Entities;

[Table("MaintenanceEvent")]
public partial class MaintenanceEvent
{
    [Key]
    public Guid MaintenanceEventId { get; set; }

    public Guid EquipmentId { get; set; }

    public Guid? RentalId { get; set; }

    public DateOnly LastServiceDate { get; set; }

    public DateOnly? NextServiceDue { get; set; }

    [StringLength(20)]
    public string EventStatus { get; set; } = null!;

    [Precision(0)]
    public DateTime OpenedAt { get; set; }

    [Precision(0)]
    public DateTime? ClosedAt { get; set; }

    [StringLength(20)]
    public string? MaintenanceOutcome { get; set; }

    public string? Notes { get; set; }

    [ForeignKey("EquipmentId")]
    [InverseProperty("MaintenanceEvents")]
    public virtual Equipment Equipment { get; set; } = null!;

    [ForeignKey("RentalId")]
    [InverseProperty("MaintenanceEvents")]
    public virtual Rental? Rental { get; set; }
}
