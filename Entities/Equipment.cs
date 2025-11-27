using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Entities;

[Index("EquipmentCode", Name = "UQ_Equipment_EquipmentCode", IsUnique = true)]
public partial class Equipment
{
    [Key]
    public Guid EquipmentId { get; set; }

    [StringLength(32)]
    [Unicode(false)]
    public string EquipmentCode { get; set; } = null!;

    public string? EquipmentDescription { get; set; }

    [Column(TypeName = "decimal(12, 2)")]
    public decimal EquipmentValue { get; set; }

    [StringLength(50)]
    public string EquipmentCategory { get; set; } = null!;

    [StringLength(50)]
    public string EquipmentType { get; set; } = null!;

    [StringLength(100)]
    public string? EquipmentTrackingId { get; set; }

    [StringLength(30)]
    public string EquipmentAvailability { get; set; } = null!;

    [InverseProperty("Equipment")]
    public virtual Maintenance? Maintenance { get; set; }

    [InverseProperty("Equipment")]
    public virtual ICollection<RentedEquipment> RentedEquipments { get; set; } = new List<RentedEquipment>();
}
