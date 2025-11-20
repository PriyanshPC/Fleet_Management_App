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

    public virtual DbSet<RentedEquipment> RentedEquipments { get; set; }

    public virtual DbSet<Vehicle> Vehicles { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=(localdb)\\MSSQLLocalDB;Database=GhostbustersFleet;Trusted_Connection=True;MultipleActiveResultSets=true");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.Property(e => e.CustomerId).HasDefaultValueSql("(newid())");
            entity.Property(e => e.CustomerCode).HasDefaultValueSql("('CT-'+right('0000'+CONVERT([varchar](4),NEXT VALUE FOR [Seq_CustomerCode]),(4)))");
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
            entity.Property(e => e.MaintenanceCode).HasDefaultValueSql("('MT-GEN-'+right('0000'+CONVERT([varchar](4),NEXT VALUE FOR [Seq_MaintenanceCode]),(4)))");
            entity.Property(e => e.OpenedAt).HasDefaultValueSql("(sysutcdatetime())");

            entity.HasOne(d => d.Equipment).WithMany(p => p.MaintenanceEvents)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_MaintenanceEvent_Equipment");

            entity.HasOne(d => d.Rental).WithMany(p => p.MaintenanceEvents).HasConstraintName("FK_MaintenanceEvent_Rental");
        });

        modelBuilder.Entity<Rental>(entity =>
        {
            entity.Property(e => e.RentalId).HasDefaultValueSql("(newid())");
            entity.Property(e => e.RentalCode).HasDefaultValueSql("('RT-'+right('0000'+CONVERT([varchar](4),NEXT VALUE FOR [Seq_RentalCode]),(4)))");

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
            entity.HasIndex(e => e.LicensePlate, "UQ_Vehicle_LicensePlate")
                .IsUnique()
                .HasFilter("([LicensePlate] IS NOT NULL)");

            entity.HasIndex(e => e.VIN, "UQ_Vehicle_VIN")
                .IsUnique()
                .HasFilter("([VIN] IS NOT NULL)");

            entity.Property(e => e.VehicleId).HasDefaultValueSql("(newid())");

            entity.HasOne(d => d.Equipment).WithOne(p => p.Vehicle)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Vehicle_Equipment");
        });
        modelBuilder.HasSequence<int>("Seq_CustomerCode");
        modelBuilder.HasSequence<int>("Seq_MaintenanceCode");
        modelBuilder.HasSequence<int>("Seq_RentalCode");

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
