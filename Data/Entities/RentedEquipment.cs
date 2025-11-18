using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Data.Entities;

[Table("RentedEquipment")]
public partial class RentedEquipment
{
    [Key]
    public Guid RentedEquipmentId { get; set; }

    public Guid RentalId { get; set; }

    public Guid EquipmentId { get; set; }

    [Column(TypeName = "decimal(10, 2)")]
    public decimal EquipmentDailyRate { get; set; }

    [Column(TypeName = "decimal(10, 2)")]
    public decimal EquipmentSecurityFee { get; set; }

    [Column(TypeName = "decimal(10, 2)")]
    public decimal EquipmentDamageFee { get; set; }

    [ForeignKey("EquipmentId")]
    [InverseProperty("RentedEquipments")]
    public virtual Equipment Equipment { get; set; } = null!;

    [ForeignKey("RentalId")]
    [InverseProperty("RentedEquipments")]
    public virtual Rental Rental { get; set; } = null!;
}
