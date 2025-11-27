using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Database
{
    public static class DataSeed
    {
        private static string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }

        public static void Seed(this ModelBuilder modelBuilder)
        {
            var baseDate = DateTime.UtcNow;
            var passwordHash = HashPassword("test");

            // Users (5 records)
            modelBuilder.Entity<User>().HasData(
                new User
                {
                    UserId = 1,
                    Username = "admin",
                    Role = "admin",
                    FirstName = "Admin",
                    LastName = "User",
                    Email = "admin@taximo.ba",
                    Phone = "38761123456",
                    PasswordHash = passwordHash,
                    DateOfBirth = new DateTime(1985, 5, 15),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-365),
                    UpdatedAt = baseDate.AddDays(-1)
                },
                new User
                {
                    UserId = 2,
                    Username = "desktop",
                    Role = "desktop",
                    FirstName = "Desktop",
                    LastName = "Operator",
                    Email = "desktop@taximo.ba",
                    Phone = "38761234567",
                    PasswordHash = passwordHash,
                    DateOfBirth = new DateTime(1990, 8, 20),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-300),
                    UpdatedAt = baseDate.AddDays(-2)
                },
                new User
                {
                    UserId = 3,
                    Username = "mobile",
                    Role = "mobile",
                    FirstName = "Mobile",
                    LastName = "Operator",
                    Email = "mobile@taximo.ba",
                    Phone = "38761345678",
                    PasswordHash = passwordHash,
                    DateOfBirth = new DateTime(1992, 3, 10),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-280),
                    UpdatedAt = baseDate.AddDays(-3)
                },
                new User
                {
                    UserId = 4,
                    Username = "john.doe",
                    Role = "user",
                    FirstName = "John",
                    LastName = "Doe",
                    Email = "john.doe@example.com",
                    Phone = "38761456789",
                    PasswordHash = passwordHash,
                    DateOfBirth = new DateTime(1995, 11, 25),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-200),
                    UpdatedAt = baseDate.AddDays(-5)
                },
                new User
                {
                    UserId = 5,
                    Username = "support",
                    Role = "support",
                    FirstName = "Support",
                    LastName = "Agent",
                    Email = "support@taximo.ba",
                    Phone = "38761567890",
                    PasswordHash = passwordHash,
                    DateOfBirth = new DateTime(1988, 7, 5),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-150),
                    UpdatedAt = baseDate.AddDays(-4)
                }
            );

            // Drivers (5 records)
            modelBuilder.Entity<Driver>().HasData(
                new Driver
                {
                    DriverId = 1,
                    Username = "driver.ahmed",
                    Role = "driver",
                    FirstName = "Ahmed",
                    LastName = "Hasanovic",
                    Email = "ahmed.hasanovic@taximo.ba",
                    Phone = "38762123456",
                    PasswordHash = passwordHash,
                    LicenseNumber = "BIH-2020-001",
                    LicenseExpiry = baseDate.AddYears(2),
                    RatingAvg = 4.8m,
                    TotalRides = 1250,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-400),
                    UpdatedAt = baseDate.AddDays(-1)
                },
                new Driver
                {
                    DriverId = 2,
                    Username = "driver.amina",
                    Role = "driver",
                    FirstName = "Amina",
                    LastName = "Kovacevic",
                    Email = "amina.kovacevic@taximo.ba",
                    Phone = "38762234567",
                    PasswordHash = passwordHash,
                    LicenseNumber = "BIH-2019-045",
                    LicenseExpiry = baseDate.AddYears(1).AddMonths(6),
                    RatingAvg = 4.9m,
                    TotalRides = 2100,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-450),
                    UpdatedAt = baseDate.AddDays(-2)
                },
                new Driver
                {
                    DriverId = 3,
                    Username = "driver.mirza",
                    Role = "driver",
                    FirstName = "Mirza",
                    LastName = "Begic",
                    Email = "mirza.begic@taximo.ba",
                    Phone = "38762345678",
                    PasswordHash = passwordHash,
                    LicenseNumber = "BIH-2021-078",
                    LicenseExpiry = baseDate.AddYears(3),
                    RatingAvg = 4.6m,
                    TotalRides = 850,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-350),
                    UpdatedAt = baseDate.AddDays(-3)
                },
                new Driver
                {
                    DriverId = 4,
                    Username = "driver.sara",
                    Role = "driver",
                    FirstName = "Sara",
                    LastName = "Dedic",
                    Email = "sara.dedic@taximo.ba",
                    Phone = "38762456789",
                    PasswordHash = passwordHash,
                    LicenseNumber = "BIH-2018-112",
                    LicenseExpiry = baseDate.AddMonths(8),
                    RatingAvg = 4.7m,
                    TotalRides = 1650,
                    Status = "offline",
                    CreatedAt = baseDate.AddDays(-500),
                    UpdatedAt = baseDate.AddDays(-10)
                },
                new Driver
                {
                    DriverId = 5,
                    Username = "driver.emir",
                    Role = "driver",
                    FirstName = "Emir",
                    LastName = "Jahic",
                    Email = "emir.jahic@taximo.ba",
                    Phone = "38762567890",
                    PasswordHash = passwordHash,
                    LicenseNumber = "BIH-2022-023",
                    LicenseExpiry = baseDate.AddYears(4),
                    RatingAvg = 4.5m,
                    TotalRides = 420,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-250),
                    UpdatedAt = baseDate.AddDays(-5)
                }
            );

            // Vehicles (5 records)
            modelBuilder.Entity<Vehicle>().HasData(
                new Vehicle
                {
                    VehicleId = 1,
                    DriverId = 1,
                    Make = "Skoda",
                    Model = "Octavia",
                    Year = 2020,
                    PlateNumber = "A-123-BH",
                    Color = "White",
                    VehicleType = "Sedan",
                    Capacity = 4,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-400),
                    UpdatedAt = baseDate.AddDays(-1)
                },
                new Vehicle
                {
                    VehicleId = 2,
                    DriverId = 2,
                    Make = "Volkswagen",
                    Model = "Golf",
                    Year = 2019,
                    PlateNumber = "S-456-SA",
                    Color = "Black",
                    VehicleType = "Hatchback",
                    Capacity = 4,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-450),
                    UpdatedAt = baseDate.AddDays(-2)
                },
                new Vehicle
                {
                    VehicleId = 3,
                    DriverId = 3,
                    Make = "Mercedes-Benz",
                    Model = "E-Class",
                    Year = 2021,
                    PlateNumber = "T-789-TU",
                    Color = "Silver",
                    VehicleType = "Sedan",
                    Capacity = 4,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-350),
                    UpdatedAt = baseDate.AddDays(-3)
                },
                new Vehicle
                {
                    VehicleId = 4,
                    DriverId = 4,
                    Make = "Toyota",
                    Model = "Corolla",
                    Year = 2018,
                    PlateNumber = "Z-321-ZE",
                    Color = "Blue",
                    VehicleType = "Sedan",
                    Capacity = 4,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-500),
                    UpdatedAt = baseDate.AddDays(-10)
                },
                new Vehicle
                {
                    VehicleId = 5,
                    DriverId = 5,
                    Make = "Ford",
                    Model = "Focus",
                    Year = 2022,
                    PlateNumber = "B-654-BI",
                    Color = "Red",
                    VehicleType = "Hatchback",
                    Capacity = 4,
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-250),
                    UpdatedAt = baseDate.AddDays(-5)
                }
            );

            // Locations (5 records)
            modelBuilder.Entity<Location>().HasData(
                new Location
                {
                    LocationId = 1,
                    UserId = 4,
                    Name = "Home",
                    AddressLine = "Zmaja od Bosne 12",
                    City = "Sarajevo",
                    Lat = 43.8563m,
                    Lng = 18.4131m,
                    CreatedAt = baseDate.AddDays(-200),
                    UpdatedAt = baseDate.AddDays(-5)
                },
                new Location
                {
                    LocationId = 2,
                    UserId = null,
                    Name = "Sarajevo Airport",
                    AddressLine = "Kurta Schorka 36",
                    City = "Sarajevo",
                    Lat = 43.8247m,
                    Lng = 18.3314m,
                    CreatedAt = baseDate.AddDays(-180),
                    UpdatedAt = baseDate.AddDays(-10)
                },
                new Location
                {
                    LocationId = 3,
                    UserId = 4,
                    Name = "Work Office",
                    AddressLine = "Titova 15",
                    City = "Sarajevo",
                    Lat = 43.8517m,
                    Lng = 18.3889m,
                    CreatedAt = baseDate.AddDays(-190),
                    UpdatedAt = baseDate.AddDays(-8)
                },
                new Location
                {
                    LocationId = 4,
                    UserId = null,
                    Name = "City Center",
                    AddressLine = "Ferhadija 1",
                    City = "Sarajevo",
                    Lat = 43.8586m,
                    Lng = 18.4281m,
                    CreatedAt = baseDate.AddDays(-170),
                    UpdatedAt = baseDate.AddDays(-12)
                },
                new Location
                {
                    LocationId = 5,
                    UserId = 4,
                    Name = "Shopping Mall",
                    AddressLine = "Zmaja od Bosne 88",
                    City = "Sarajevo",
                    Lat = 43.8625m,
                    Lng = 18.4103m,
                    CreatedAt = baseDate.AddDays(-160),
                    UpdatedAt = baseDate.AddDays(-6)
                }
            );

            // PromoCodes (5 records)
            modelBuilder.Entity<PromoCode>().HasData(
                new PromoCode
                {
                    PromoId = 1,
                    Code = "WELCOME10",
                    Description = "Welcome discount for new users",
                    DiscountType = "percentage",
                    DiscountValue = 10.00m,
                    UsageLimit = 100,
                    ValidFrom = baseDate.AddDays(-100),
                    ValidUntil = baseDate.AddDays(200),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-100)
                },
                new PromoCode
                {
                    PromoId = 2,
                    Code = "FIRST20",
                    Description = "20% off first ride",
                    DiscountType = "percentage",
                    DiscountValue = 20.00m,
                    UsageLimit = 50,
                    ValidFrom = baseDate.AddDays(-80),
                    ValidUntil = baseDate.AddDays(120),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-80)
                },
                new PromoCode
                {
                    PromoId = 3,
                    Code = "FIXED5",
                    Description = "5 BAM off your ride",
                    DiscountType = "fixed",
                    DiscountValue = 5.00m,
                    UsageLimit = 200,
                    ValidFrom = baseDate.AddDays(-60),
                    ValidUntil = baseDate.AddDays(140),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-60)
                },
                new PromoCode
                {
                    PromoId = 4,
                    Code = "WEEKEND15",
                    Description = "15% off weekend rides",
                    DiscountType = "percentage",
                    DiscountValue = 15.00m,
                    UsageLimit = 75,
                    ValidFrom = baseDate.AddDays(-40),
                    ValidUntil = baseDate.AddDays(60),
                    Status = "active",
                    CreatedAt = baseDate.AddDays(-40)
                },
                new PromoCode
                {
                    PromoId = 5,
                    Code = "EXPIRED",
                    Description = "Expired promo code",
                    DiscountType = "percentage",
                    DiscountValue = 10.00m,
                    UsageLimit = 100,
                    ValidFrom = baseDate.AddDays(-200),
                    ValidUntil = baseDate.AddDays(-50),
                    Status = "expired",
                    CreatedAt = baseDate.AddDays(-200)
                }
            );

            // Rides (5 records)
            modelBuilder.Entity<Ride>().HasData(
                new Ride
                {
                    RideId = 1,
                    RiderId = 4,
                    DriverId = 1,
                    VehicleId = 1,
                    PickupLocationId = 1,
                    DropoffLocationId = 3,
                    RequestedAt = baseDate.AddDays(-30),
                    StartedAt = baseDate.AddDays(-30).AddMinutes(5),
                    CompletedAt = baseDate.AddDays(-30).AddMinutes(25),
                    Status = "completed",
                    FareEstimate = 8.50m,
                    FareFinal = 8.50m,
                    DistanceKm = 5.2m,
                    DurationMin = 20
                },
                new Ride
                {
                    RideId = 2,
                    RiderId = 4,
                    DriverId = 2,
                    VehicleId = 2,
                    PickupLocationId = 2,
                    DropoffLocationId = 4,
                    RequestedAt = baseDate.AddDays(-25),
                    StartedAt = baseDate.AddDays(-25).AddMinutes(10),
                    CompletedAt = baseDate.AddDays(-25).AddMinutes(45),
                    Status = "completed",
                    FareEstimate = 15.00m,
                    FareFinal = 12.00m,
                    DistanceKm = 12.5m,
                    DurationMin = 35
                },
                new Ride
                {
                    RideId = 3,
                    RiderId = 4,
                    DriverId = 3,
                    VehicleId = 3,
                    PickupLocationId = 4,
                    DropoffLocationId = 5,
                    RequestedAt = baseDate.AddDays(-20),
                    StartedAt = baseDate.AddDays(-20).AddMinutes(3),
                    CompletedAt = null,
                    Status = "active",
                    FareEstimate = 6.00m,
                    FareFinal = null,
                    DistanceKm = null,
                    DurationMin = null
                },
                new Ride
                {
                    RideId = 4,
                    RiderId = 4,
                    DriverId = 1,
                    VehicleId = 1,
                    PickupLocationId = 3,
                    DropoffLocationId = 1,
                    RequestedAt = baseDate.AddDays(-15),
                    StartedAt = null,
                    CompletedAt = null,
                    Status = "accepted",
                    FareEstimate = 7.50m,
                    FareFinal = null,
                    DistanceKm = null,
                    DurationMin = null
                },
                new Ride
                {
                    RideId = 5,
                    RiderId = 4,
                    DriverId = 2,
                    VehicleId = 2,
                    PickupLocationId = 5,
                    DropoffLocationId = 2,
                    RequestedAt = baseDate.AddDays(-10),
                    StartedAt = null,
                    CompletedAt = null,
                    Status = "requested",
                    FareEstimate = 18.00m,
                    FareFinal = null,
                    DistanceKm = null,
                    DurationMin = null
                }
            );

            // Payments (5 records)
            modelBuilder.Entity<Payment>().HasData(
                new Payment
                {
                    PaymentId = 1,
                    RideId = 1,
                    UserId = 4,
                    Amount = 8.50m,
                    Currency = "BAM",
                    Method = "online",
                    Status = "completed",
                    TransactionRef = "TXN-2024-001",
                    PaidAt = baseDate.AddDays(-30).AddMinutes(25)
                },
                new Payment
                {
                    PaymentId = 2,
                    RideId = 2,
                    UserId = 4,
                    Amount = 12.00m,
                    Currency = "BAM",
                    Method = "cash",
                    Status = "completed",
                    TransactionRef = null,
                    PaidAt = baseDate.AddDays(-25).AddMinutes(45)
                },
                new Payment
                {
                    PaymentId = 3,
                    RideId = 1,
                    UserId = 4,
                    Amount = 8.50m,
                    Currency = "BAM",
                    Method = "online",
                    Status = "pending",
                    TransactionRef = "TXN-2024-002",
                    PaidAt = null
                },
                new Payment
                {
                    PaymentId = 4,
                    RideId = 2,
                    UserId = 4,
                    Amount = 15.00m,
                    Currency = "BAM",
                    Method = "online",
                    Status = "refunded",
                    TransactionRef = "TXN-2024-003",
                    PaidAt = baseDate.AddDays(-25).AddMinutes(50)
                },
                new Payment
                {
                    PaymentId = 5,
                    RideId = 1,
                    UserId = 4,
                    Amount = 8.50m,
                    Currency = "BAM",
                    Method = "cash",
                    Status = "completed",
                    TransactionRef = null,
                    PaidAt = baseDate.AddDays(-30).AddMinutes(26)
                }
            );

            // Reviews (5 records)
            modelBuilder.Entity<Review>().HasData(
                new Review
                {
                    ReviewId = 1,
                    RideId = 1,
                    RiderId = 4,
                    DriverId = 1,
                    Rating = 5.00m,
                    Comment = "Excellent service, very professional driver!",
                    CreatedAt = baseDate.AddDays(-30).AddHours(1)
                },
                new Review
                {
                    ReviewId = 2,
                    RideId = 2,
                    RiderId = 4,
                    DriverId = 2,
                    Rating = 4.50m,
                    Comment = "Good ride, clean car and friendly driver.",
                    CreatedAt = baseDate.AddDays(-25).AddHours(2)
                },
                new Review
                {
                    ReviewId = 3,
                    RideId = 1,
                    RiderId = 4,
                    DriverId = 1,
                    Rating = 4.00m,
                    Comment = "Punctual and safe driving.",
                    CreatedAt = baseDate.AddDays(-29).AddHours(12)
                },
                new Review
                {
                    ReviewId = 4,
                    RideId = 2,
                    RiderId = 4,
                    DriverId = 2,
                    Rating = 5.00m,
                    Comment = "Best taxi service in Sarajevo!",
                    CreatedAt = baseDate.AddDays(-24).AddHours(6)
                },
                new Review
                {
                    ReviewId = 5,
                    RideId = 1,
                    RiderId = 4,
                    DriverId = 1,
                    Rating = 4.75m,
                    Comment = "Very satisfied with the service.",
                    CreatedAt = baseDate.AddDays(-28).AddHours(18)
                }
            );

            // PromoUsages (5 records)
            modelBuilder.Entity<PromoUsage>().HasData(
                new PromoUsage
                {
                    PromoUsageId = 1,
                    PromoId = 1,
                    UserId = 4,
                    RideId = 1,
                    UsedAt = baseDate.AddDays(-30)
                },
                new PromoUsage
                {
                    PromoUsageId = 2,
                    PromoId = 2,
                    UserId = 4,
                    RideId = 2,
                    UsedAt = baseDate.AddDays(-25)
                },
                new PromoUsage
                {
                    PromoUsageId = 3,
                    PromoId = 3,
                    UserId = 4,
                    RideId = 1,
                    UsedAt = baseDate.AddDays(-29)
                },
                new PromoUsage
                {
                    PromoUsageId = 4,
                    PromoId = 1,
                    UserId = 4,
                    RideId = 2,
                    UsedAt = baseDate.AddDays(-24)
                },
                new PromoUsage
                {
                    PromoUsageId = 5,
                    PromoId = 4,
                    UserId = 4,
                    RideId = 1,
                    UsedAt = baseDate.AddDays(-20)
                }
            );

            // DriverAvailabilities (5 records)
            modelBuilder.Entity<DriverAvailability>().HasData(
                new DriverAvailability
                {
                    AvailabilityId = 1,
                    DriverId = 1,
                    IsOnline = true,
                    CurrentLat = 43.8563m,
                    CurrentLng = 18.4131m,
                    LastLocationUpdate = baseDate.AddMinutes(-5),
                    UpdatedAt = baseDate.AddMinutes(-5)
                },
                new DriverAvailability
                {
                    AvailabilityId = 2,
                    DriverId = 2,
                    IsOnline = true,
                    CurrentLat = 43.8586m,
                    CurrentLng = 18.4281m,
                    LastLocationUpdate = baseDate.AddMinutes(-10),
                    UpdatedAt = baseDate.AddMinutes(-10)
                },
                new DriverAvailability
                {
                    AvailabilityId = 3,
                    DriverId = 3,
                    IsOnline = false,
                    CurrentLat = 43.8517m,
                    CurrentLng = 18.3889m,
                    LastLocationUpdate = baseDate.AddHours(-2),
                    UpdatedAt = baseDate.AddHours(-2)
                },
                new DriverAvailability
                {
                    AvailabilityId = 4,
                    DriverId = 4,
                    IsOnline = false,
                    CurrentLat = null,
                    CurrentLng = null,
                    LastLocationUpdate = null,
                    UpdatedAt = baseDate.AddDays(-1)
                },
                new DriverAvailability
                {
                    AvailabilityId = 5,
                    DriverId = 5,
                    IsOnline = true,
                    CurrentLat = 43.8625m,
                    CurrentLng = 18.4103m,
                    LastLocationUpdate = baseDate.AddMinutes(-15),
                    UpdatedAt = baseDate.AddMinutes(-15)
                }
            );

            // UserNotifications (5 records)
            modelBuilder.Entity<UserNotification>().HasData(
                new UserNotification
                {
                    NotificationId = 1,
                    RecipientUserId = 4,
                    Title = "Welcome to TaxiMo!",
                    Body = "Thank you for joining TaxiMo. Get 10% off your first ride with code WELCOME10",
                    Type = "welcome",
                    IsRead = true,
                    SentAt = baseDate.AddDays(-200)
                },
                new UserNotification
                {
                    NotificationId = 2,
                    RecipientUserId = 4,
                    Title = "Ride Completed",
                    Body = "Your ride from Home to Work Office has been completed. Thank you for using TaxiMo!",
                    Type = "ride_completed",
                    IsRead = true,
                    SentAt = baseDate.AddDays(-30).AddMinutes(25)
                },
                new UserNotification
                {
                    NotificationId = 3,
                    RecipientUserId = 4,
                    Title = "Payment Received",
                    Body = "Your payment of 8.50 BAM has been processed successfully.",
                    Type = "payment",
                    IsRead = false,
                    SentAt = baseDate.AddDays(-25)
                },
                new UserNotification
                {
                    NotificationId = 4,
                    RecipientUserId = 4,
                    Title = "New Promo Code Available",
                    Body = "Use code WEEKEND15 for 15% off your weekend rides!",
                    Type = "promotion",
                    IsRead = false,
                    SentAt = baseDate.AddDays(-10)
                },
                new UserNotification
                {
                    NotificationId = 5,
                    RecipientUserId = 4,
                    Title = "Driver Assigned",
                    Body = "Your driver Ahmed Hasanovic is on the way to your pickup location.",
                    Type = "ride_update",
                    IsRead = true,
                    SentAt = baseDate.AddDays(-20).AddMinutes(3)
                }
            );

            // DriverNotifications (5 records)
            modelBuilder.Entity<DriverNotification>().HasData(
                new DriverNotification
                {
                    NotificationId = 1,
                    RecipientDriverId = 1,
                    Title = "New Ride Request",
                    Body = "You have received a new ride request from John Doe.",
                    Type = "ride_request",
                    IsRead = true,
                    SentAt = baseDate.AddDays(-30)
                },
                new DriverNotification
                {
                    NotificationId = 2,
                    RecipientDriverId = 1,
                    Title = "Payment Received",
                    Body = "Payment of 8.50 BAM has been received for ride #1.",
                    Type = "payment",
                    IsRead = true,
                    SentAt = baseDate.AddDays(-30).AddMinutes(25)
                },
                new DriverNotification
                {
                    NotificationId = 3,
                    RecipientDriverId = 2,
                    Title = "New Ride Request",
                    Body = "You have received a new ride request from Sarajevo Airport.",
                    Type = "ride_request",
                    IsRead = true,
                    SentAt = baseDate.AddDays(-25)
                },
                new DriverNotification
                {
                    NotificationId = 4,
                    RecipientDriverId = 2,
                    Title = "Rating Received",
                    Body = "You received a 4.5 star rating from a passenger.",
                    Type = "rating",
                    IsRead = false,
                    SentAt = baseDate.AddDays(-25).AddHours(2)
                },
                new DriverNotification
                {
                    NotificationId = 5,
                    RecipientDriverId = 3,
                    Title = "System Maintenance",
                    Body = "Scheduled maintenance will occur tonight from 2 AM to 4 AM.",
                    Type = "system",
                    IsRead = false,
                    SentAt = baseDate.AddDays(-5)
                }
            );

            // UserAuthTokens (5 records)
            modelBuilder.Entity<UserAuthToken>().HasData(
                new UserAuthToken
                {
                    TokenId = 1,
                    UserId = 1,
                    DeviceId = "desktop-app",
                    TokenHash = "fake_token_hash_admin_001",
                    RefreshTokenHash = "fake_refresh_token_hash_admin_001",
                    ExpiresAt = baseDate.AddDays(30),
                    RevokedAt = null,
                    IpAddress = "192.168.1.100"
                },
                new UserAuthToken
                {
                    TokenId = 2,
                    UserId = 2,
                    DeviceId = "desktop-app",
                    TokenHash = "fake_token_hash_desktop_002",
                    RefreshTokenHash = "fake_refresh_token_hash_desktop_002",
                    ExpiresAt = baseDate.AddDays(30),
                    RevokedAt = null,
                    IpAddress = "192.168.1.101"
                },
                new UserAuthToken
                {
                    TokenId = 3,
                    UserId = 3,
                    DeviceId = "mobile-app",
                    TokenHash = "fake_token_hash_mobile_003",
                    RefreshTokenHash = "fake_refresh_token_hash_mobile_003",
                    ExpiresAt = baseDate.AddDays(7),
                    RevokedAt = null,
                    IpAddress = "192.168.1.102"
                },
                new UserAuthToken
                {
                    TokenId = 4,
                    UserId = 4,
                    DeviceId = "mobile-app",
                    TokenHash = "fake_token_hash_user_004",
                    RefreshTokenHash = "fake_refresh_token_hash_user_004",
                    ExpiresAt = baseDate.AddDays(7),
                    RevokedAt = null,
                    IpAddress = "10.0.0.50"
                },
                new UserAuthToken
                {
                    TokenId = 5,
                    UserId = 5,
                    DeviceId = "desktop-app",
                    TokenHash = "fake_token_hash_support_005",
                    RefreshTokenHash = "fake_refresh_token_hash_support_005",
                    ExpiresAt = baseDate.AddDays(30),
                    RevokedAt = baseDate.AddDays(-5),
                    IpAddress = "192.168.1.103"
                }
            );

            // DriverAuthTokens (5 records)
            modelBuilder.Entity<DriverAuthToken>().HasData(
                new DriverAuthToken
                {
                    TokenId = 1,
                    DriverId = 1,
                    DeviceId = "mobile-app",
                    TokenHash = "fake_token_hash_driver_ahmed_001",
                    RefreshTokenHash = "fake_refresh_token_hash_driver_ahmed_001",
                    ExpiresAt = baseDate.AddDays(7),
                    RevokedAt = null,
                    IpAddress = "192.168.1.200"
                },
                new DriverAuthToken
                {
                    TokenId = 2,
                    DriverId = 2,
                    DeviceId = "mobile-app",
                    TokenHash = "fake_token_hash_driver_amina_002",
                    RefreshTokenHash = "fake_refresh_token_hash_driver_amina_002",
                    ExpiresAt = baseDate.AddDays(7),
                    RevokedAt = null,
                    IpAddress = "192.168.1.201"
                },
                new DriverAuthToken
                {
                    TokenId = 3,
                    DriverId = 3,
                    DeviceId = "mobile-app",
                    TokenHash = "fake_token_hash_driver_mirza_003",
                    RefreshTokenHash = "fake_refresh_token_hash_driver_mirza_003",
                    ExpiresAt = baseDate.AddDays(7),
                    RevokedAt = null,
                    IpAddress = "192.168.1.202"
                },
                new DriverAuthToken
                {
                    TokenId = 4,
                    DriverId = 4,
                    DeviceId = "mobile-app",
                    TokenHash = "fake_token_hash_driver_sara_004",
                    RefreshTokenHash = "fake_refresh_token_hash_driver_sara_004",
                    ExpiresAt = baseDate.AddDays(7),
                    RevokedAt = baseDate.AddDays(-2),
                    IpAddress = "192.168.1.203"
                },
                new DriverAuthToken
                {
                    TokenId = 5,
                    DriverId = 5,
                    DeviceId = "mobile-app",
                    TokenHash = "fake_token_hash_driver_emir_005",
                    RefreshTokenHash = "fake_refresh_token_hash_driver_emir_005",
                    ExpiresAt = baseDate.AddDays(7),
                    RevokedAt = null,
                    IpAddress = "192.168.1.204"
                }
            );
        }
    }
}

