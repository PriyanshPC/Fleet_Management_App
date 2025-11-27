using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Entities;

[Table("Customer")]
[Index("CustomerPhone", Name = "IX_Customer_Phone")]
[Index("CustomerCode", Name = "UQ_Customer_Code", IsUnique = true)]
public partial class Customer
{
    [Key]
    public Guid CustomerId { get; set; }

    [StringLength(32)]
    [Unicode(false)]
    public string CustomerCode { get; set; } = null!;

    [StringLength(200)]
    public string CustomerName { get; set; } = null!;

    public string? CustomerAddress { get; set; }

    [StringLength(100)]
    public string? CustomerGovtId { get; set; }

    [StringLength(200)]
    public string? CustomerEmail { get; set; }

    [StringLength(50)]
    public string? CustomerPhone { get; set; }

    [StringLength(50)]
    public string? Username { get; set; }

    [StringLength(200)]
    public string? Password { get; set; }

    [InverseProperty("Customer")]
    public virtual ICollection<Rental> Rentals { get; set; } = new List<Rental>();
}
