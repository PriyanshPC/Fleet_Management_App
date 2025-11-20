using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Data.Entities;

[Table("Vehicle")]
[Index("EquipmentId", Name = "UQ_Vehicle_EquipmentId", IsUnique = true)]
public partial class Vehicle
{
    [Key]
    public Guid VehicleId { get; set; }

    public Guid EquipmentId { get; set; }

    public int? Year { get; set; }

    [StringLength(100)]
    public string? Make { get; set; }

    [StringLength(100)]
    public string? Model { get; set; }

    public int? Odometer { get; set; }

    [StringLength(50)]
    public string? VIN { get; set; }

    [StringLength(50)]
    public string? LicensePlate { get; set; }

    [ForeignKey("EquipmentId")]
    [InverseProperty("Vehicle")]
    public virtual Equipment Equipment { get; set; } = null!;
}
