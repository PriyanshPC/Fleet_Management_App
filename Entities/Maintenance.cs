using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Entities;

[Table("Maintenance")]
[Index("MaintenanceCode", Name = "UQ_Maintenance_Code", IsUnique = true)]
[Index("EquipmentId", Name = "UQ_Maintenance_Equipment", IsUnique = true)]
public partial class Maintenance
{
    [Key]
    public Guid MaintenanceId { get; set; }

    [StringLength(32)]
    [Unicode(false)]
    public string MaintenanceCode { get; set; } = null!;

    public Guid EquipmentId { get; set; }

    public Guid? RentalId { get; set; }

    public DateOnly LastServiceDate { get; set; }

    [StringLength(20)]
    public string Status { get; set; } = null!;

    [Precision(0)]
    public DateTime OpenDate { get; set; }

    [Precision(0)]
    public DateTime? CloseDate { get; set; }

    [StringLength(20)]
    public string? Outcome { get; set; }

    [StringLength(200)]
    public string? Technician { get; set; }

    public string? Notes { get; set; }

    [ForeignKey("EquipmentId")]
    [InverseProperty("Maintenance")]
    public virtual Equipment Equipment { get; set; } = null!;

    [ForeignKey("RentalId")]
    [InverseProperty("Maintenances")]
    public virtual Rental? Rental { get; set; }
}
