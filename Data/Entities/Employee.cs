using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Data.Entities;

[Index("Username", Name = "UQ__Employee__536C85E4B7BAE1D7", IsUnique = true)]
public partial class Employee
{
    [Key]
    public Guid EmployeeId { get; set; }

    [StringLength(100)]
    public string Name { get; set; } = null!;

    [StringLength(50)]
    public string Username { get; set; } = null!;

    [StringLength(200)]
    public string Password { get; set; } = null!;
}
