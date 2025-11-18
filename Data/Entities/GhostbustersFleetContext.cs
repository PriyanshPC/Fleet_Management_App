using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace Fleet_Management_App.Data.Entities;

public partial class GhostbustersFleetContext : DbContext
{
    public GhostbustersFleetContext()
    {
    }

    public GhostbustersFleetContext(DbContextOptions<GhostbustersFleetContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Customer> Customers { get; set; }

    public virtual DbSet<Employee> Employees { get; set; }

    public virtual DbSet<Equipment> Equipment { get; set; }

    public virtual DbSet<MaintenanceEvent> MaintenanceEvents { get; set; }

    public virtual DbSet<Rental> Rentals { get; set; }

    public virtual DbSet<RentedEquipment> RentedEquipment { get; set; }

    public virtual DbSet<Vehicle> Vehicles { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)=> optionsBuilder.UseSqlServer("Server=(localdb)\\MSSQLLocalDB;Database=GhostbustersFleet;Trusted_Connection=True;MultipleActiveResultSets=true");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.Property(e => e.CustomerId).HasDefaultValueSql("(newid())");
        });

        modelBuilder.Entity<Employee>(entity =>
        {
            entity.Property(e => e.EmployeeId).HasDefaultValueSql("(newid())");
        });

        modelBuilder.Entity<Equipment>(entity =>
        {
            entity.Property(e => e.EquipmentId).HasDefaultValueSql("(newid())");
        });

        modelBuilder.Entity<MaintenanceEvent>(entity =>
        {
            entity.Property(e => e.MaintenanceEventId).HasDefaultValueSql("(newid())");
            entity.Property(e => e.OpenedAt).HasDefaultValueSql("(sysutcdatetime())");

            entity.HasOne(d => d.Equipment).WithMany(p => p.MaintenanceEvents)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_MaintenanceEvent_Equipment");

            entity.HasOne(d => d.Rental).WithMany(p => p.MaintenanceEvents).HasConstraintName("FK_MaintenanceEvent_Rental");
        });

        modelBuilder.Entity<Rental>(entity =>
        {
            entity.Property(e => e.RentalId).HasDefaultValueSql("(newid())");

            entity.HasOne(d => d.Customer).WithMany(p => p.Rentals).HasConstraintName("FK_Rental_Customer");
        });

        modelBuilder.Entity<RentedEquipment>(entity =>
        {
            entity.Property(e => e.RentedEquipmentId).HasDefaultValueSql("(newid())");

            entity.HasOne(d => d.Equipment).WithMany(p => p.RentedEquipments)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RentedEquipment_Equipment");

            entity.HasOne(d => d.Rental).WithMany(p => p.RentedEquipments)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_RentedEquipment_Rental");
        });

        modelBuilder.Entity<Vehicle>(entity =>
        {
            entity.Property(e => e.VehicleId).HasDefaultValueSql("(newid())");

            entity.HasOne(d => d.Equipment).WithOne(p => p.Vehicle)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Vehicle_Equipment");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
