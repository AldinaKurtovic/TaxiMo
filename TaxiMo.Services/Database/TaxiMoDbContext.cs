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
        public DbSet<UserAuthToken> UserAuthTokens { get; set; }
        public DbSet<DriverAuthToken> DriverAuthTokens { get; set; }

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
        }

    }
}

