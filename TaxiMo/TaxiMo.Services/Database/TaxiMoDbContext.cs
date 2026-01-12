using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Database
{
    public class TaxiMoDbContext : DbContext
    {
        public TaxiMoDbContext(DbContextOptions<TaxiMoDbContext> options)
            : base(options)
        {
        }

        // DbSets
        public DbSet<User> Users { get; set; }
        public DbSet<Driver> Drivers { get; set; }
        public DbSet<Vehicle> Vehicles { get; set; }
        public DbSet<Location> Locations { get; set; }
        public DbSet<Ride> Rides { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<PromoCode> PromoCodes { get; set; }
        public DbSet<PromoUsage> PromoUsages { get; set; }
        public DbSet<DriverAvailability> DriverAvailabilities { get; set; }
        public DbSet<UserNotification> UserNotifications { get; set; }
        public DbSet<DriverNotification> DriverNotifications { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<UserRole> UserRoles { get; set; }
        public DbSet<DriverRole> DriverRoles { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Pickup i Dropoff Location
            modelBuilder.Entity<Ride>()
                .HasOne(r => r.PickupLocation)
                .WithMany(l => l.PickupRides)
                .HasForeignKey(r => r.PickupLocationId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Ride>()
                .HasOne(r => r.DropoffLocation)
                .WithMany(l => l.DropoffRides)
                .HasForeignKey(r => r.DropoffLocationId)
                .OnDelete(DeleteBehavior.Restrict);

            // Vehicle
            modelBuilder.Entity<Ride>()
                .HasOne(r => r.Vehicle)
                .WithMany(v => v.Rides) 
                .HasForeignKey(r => r.VehicleId)
                .OnDelete(DeleteBehavior.Restrict);

            // Driver
            modelBuilder.Entity<Ride>()
                .HasOne(r => r.Driver)
                .WithMany(d => d.Rides) 
                .HasForeignKey(r => r.DriverId)
                .OnDelete(DeleteBehavior.Restrict);

            // Rider (User)
            modelBuilder.Entity<Ride>()
                .HasOne(r => r.Rider)
                .WithMany(u => u.Rides) 
                .HasForeignKey(r => r.RiderId)
                .OnDelete(DeleteBehavior.Restrict);

            // UserRole many-to-many relationship
            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserRole>()
                .HasOne(ur => ur.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(ur => ur.RoleId)
                .OnDelete(DeleteBehavior.Restrict);

            // DriverRole many-to-many relationship
            modelBuilder.Entity<DriverRole>()
                .HasOne(dr => dr.Driver)
                .WithMany(d => d.DriverRoles)
                .HasForeignKey(dr => dr.DriverId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DriverRole>()
                .HasOne(dr => dr.Role)
                .WithMany(r => r.DriverRoles)
                .HasForeignKey(dr => dr.RoleId)
                .OnDelete(DeleteBehavior.Restrict);

            // Review unique constraint: one review per ride per rider per driver
            modelBuilder.Entity<Review>()
                .HasIndex(r => new { r.RideId, r.RiderId, r.DriverId })
                .IsUnique();

            // PromoUsage unique constraint: one usage per promo per user per ride
            modelBuilder.Entity<PromoUsage>()
                .HasIndex(p => new { p.PromoId, p.UserId, p.RideId })
                .IsUnique();
        }

    }
}

