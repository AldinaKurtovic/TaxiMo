using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Linq;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Helpers;

namespace TaxiMo.Services.Database
{
    public static class DataSeed
    {
        public static async Task SeedAsync(IServiceProvider serviceProvider)
        {
            Console.WriteLine("DataSeed: start SeedAsync...");

            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<TaxiMoDbContext>();

            var baseDate = DateTime.UtcNow;

            // Roles - UPSERT by Name
            await UpsertRolesAsync(context, baseDate);

            // Users - UPSERT by Username
            await UpsertUsersAsync(context, baseDate);

            // Drivers - UPSERT by LicenseNumber
            await UpsertDriversAsync(context, baseDate);

            // UserRoles - UPSERT by UserId + RoleId
            await UpsertUserRolesAsync(context, baseDate);

            // DriverRoles - UPSERT by DriverId + RoleId
            await UpsertDriverRolesAsync(context, baseDate);

            // Vehicles - UPSERT by PlateNumber
            await UpsertVehiclesAsync(context, baseDate);

            // Locations - UPSERT by Name + AddressLine + City + UserId
            await UpsertLocationsAsync(context, baseDate);

            // PromoCodes - UPSERT by Code
            await UpsertPromoCodesAsync(context, baseDate);

            // Rides - UPSERT by RiderId + DriverId + PickupLocationId + DropoffLocationId
            await UpsertRidesAsync(context, baseDate);

            // Payments - UPSERT by RideId + TransactionRef (or RideId + Amount + Method if TransactionRef is null)
            await UpsertPaymentsAsync(context, baseDate);

            // Reviews - UPSERT by RideId + RiderId + DriverId
            await UpsertReviewsAsync(context, baseDate);

            // PromoUsages - UPSERT by PromoId + UserId + RideId
            await UpsertPromoUsagesAsync(context, baseDate);

            // DriverAvailabilities - UPSERT by DriverId (one per driver)
            await UpsertDriverAvailabilitiesAsync(context, baseDate);

            // UserNotifications - UPSERT by RecipientUserId + Title
            await UpsertUserNotificationsAsync(context, baseDate);

            // DriverNotifications - UPSERT by RecipientDriverId + Title
            await UpsertDriverNotificationsAsync(context, baseDate);

            Console.WriteLine("DataSeed: seed completed.");
        }

        private static async Task UpsertRolesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var rolesToSeed = new[]
            {
                new { Name = "Admin", IsActive = true },
                new { Name = "User", IsActive = true },
                new { Name = "Driver", IsActive = true }
            };

            foreach (var roleData in rolesToSeed)
            {
                var existing = await context.Roles.FirstOrDefaultAsync(r => r.Name == roleData.Name);
                if (existing != null)
                {
                    existing.IsActive = roleData.IsActive;
                }
                else
                {
                    context.Roles.Add(new Role
                    {
                        Name = roleData.Name,
                        IsActive = roleData.IsActive
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertUsersAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var usersToSeed = new[]
            {
                new { Username = "admin", FirstName = "Admin", LastName = "User", Email = "admin@taximo.ba", Phone = "38761123456", DateOfBirth = new DateTime(1985, 5, 15), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-365), UpdatedAt = baseDate.AddDays(-1) },
                new { Username = "desktop", FirstName = "Desktop", LastName = "Operator", Email = "desktop@taximo.ba", Phone = "38761234567", DateOfBirth = new DateTime(1990, 8, 20), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-300), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "mobile", FirstName = "Mobile", LastName = "Operator", Email = "mobile@taximo.ba", Phone = "38761345678", DateOfBirth = new DateTime(1992, 3, 10), Status = "active", PhotoUrl = "/users/user1a.png", CreatedAt = baseDate.AddDays(-280), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "aldinakurtovic", FirstName = "Aldina", LastName = "Kurtovic", Email = "aldinakurtovic7@gmail.com", Phone = "3876181997", DateOfBirth = new DateTime(1995, 11, 25), Status = "active", PhotoUrl = "/users/user3a.png", CreatedAt = baseDate.AddDays(-200), UpdatedAt = baseDate.AddDays(-5) },
                new { Username = "elmedinamaric", FirstName = "Elmedina", LastName = "Maric", Email = "elmedinamaric@gmail.com", Phone = "38761567890", DateOfBirth = new DateTime(1988, 7, 5), Status = "active", PhotoUrl = "/users/user2.png", CreatedAt = baseDate.AddDays(-150), UpdatedAt = baseDate.AddDays(-4) },
                new { Username = "amirsaric", FirstName = "Amir", LastName = "Saric", Email = "amir.saric@gmail.com", Phone = "38761111222", DateOfBirth = new DateTime(1994, 2, 14), Status = "active", PhotoUrl = "/users/user4.png", CreatedAt = baseDate.AddDays(-180), UpdatedAt = baseDate.AddDays(-10) },
                new { Username = "lejlahadzic", FirstName = "Lejla", LastName = "Hadzic", Email = "lejla.hadzic@gmail.com", Phone = "38762222333", DateOfBirth = new DateTime(1996, 6, 30), Status = "active", PhotoUrl = "/users/user5.png", CreatedAt = baseDate.AddDays(-170), UpdatedAt = baseDate.AddDays(-9) },
                new { Username = "harisbegic", FirstName = "Haris", LastName = "Begic", Email = "haris.begic@gmail.com", Phone = "38763333444", DateOfBirth = new DateTime(1991, 9, 12), Status = "active", PhotoUrl = "/users/user6.png", CreatedAt = baseDate.AddDays(-160), UpdatedAt = baseDate.AddDays(-8) },
                new { Username = "majaperic", FirstName = "Maja", LastName = "Peric", Email = "maja.peric@gmail.com", Phone = "38764444555", DateOfBirth = new DateTime(1998, 1, 8), Status = "active", PhotoUrl = "/users/user7.png", CreatedAt = baseDate.AddDays(-155), UpdatedAt = baseDate.AddDays(-7) },
                new { Username = "nedimkapetanovic", FirstName = "Nedim", LastName = "Kapetanovic", Email = "nedim.k@gmail.com", Phone = "38765555666", DateOfBirth = new DateTime(1989, 4, 22), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-145), UpdatedAt = baseDate.AddDays(-6) },
                new { Username = "sanjakovac", FirstName = "Sanja", LastName = "Kovac", Email = "sanja.kovac@gmail.com", Phone = "38766666777", DateOfBirth = new DateTime(1993, 12, 3), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-140), UpdatedAt = baseDate.AddDays(-5) },
                new { Username = "tarikmujic", FirstName = "Tarik", LastName = "Mujic", Email = "tarik.mujic@gmail.com", Phone = "38767777888", DateOfBirth = new DateTime(1997, 5, 19), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-130), UpdatedAt = baseDate.AddDays(-4) },
                new { Username = "ivanamarkovic", FirstName = "Ivana", LastName = "Markovic", Email = "ivana.markovic@gmail.com", Phone = "38768888999", DateOfBirth = new DateTime(1990, 10, 27), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-125), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "denislukic", FirstName = "Denis", LastName = "Lukic", Email = "denis.lukic@gmail.com", Phone = "38769999000", DateOfBirth = new DateTime(1987, 3, 6), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-120), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "anapetrovic", FirstName = "Ana", LastName = "Petrovic", Email = "ana.petrovic@gmail.com", Phone = "38760000111", DateOfBirth = new DateTime(1999, 8, 16), Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-110), UpdatedAt = baseDate.AddDays(-1) }
            };

            foreach (var userData in usersToSeed)
            {
                var existing = await context.Users.FirstOrDefaultAsync(u => u.Username == userData.Username);
                if (existing != null)
                {
                    existing.FirstName = userData.FirstName;
                    existing.LastName = userData.LastName;
                    existing.Email = userData.Email;
                    existing.Phone = userData.Phone;
                    existing.DateOfBirth = userData.DateOfBirth;
                    existing.Status = userData.Status;
                    existing.PhotoUrl = userData.PhotoUrl;
                    existing.UpdatedAt = userData.UpdatedAt;
                    // Update password hash if needed
                    PasswordHelper.CreatePasswordHash("test", out string hash, out string salt);
                    existing.PasswordHash = hash;
                    existing.PasswordSalt = salt;
                }
                else
                {
                    var newUser = new User
                    {
                        Username = userData.Username,
                        FirstName = userData.FirstName,
                        LastName = userData.LastName,
                        Email = userData.Email,
                        Phone = userData.Phone,
                        DateOfBirth = userData.DateOfBirth,
                        Status = userData.Status,
                        PhotoUrl = userData.PhotoUrl,
                        CreatedAt = userData.CreatedAt,
                        UpdatedAt = userData.UpdatedAt
                    };
                    PasswordHelper.CreatePasswordHash("test", out string hash, out string salt);
                    newUser.PasswordHash = hash;
                    newUser.PasswordSalt = salt;
                    context.Users.Add(newUser);
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertDriversAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var driversToSeed = new[]
            {
                new { Username = "driver.ahmed", FirstName = "Ahmed", LastName = "Hasanovic", Email = "ahmed.hasanovic@taximo.ba", Phone = "38762123456", LicenseNumber = "BIH-2020-001", LicenseExpiry = baseDate.AddYears(2), RatingAvg = 4.8m, TotalRides = 1250, Status = "active", PhotoUrl = "/drivers/driver1.png", CreatedAt = baseDate.AddDays(-400), UpdatedAt = baseDate.AddDays(-1) },
                new { Username = "driver.amina", FirstName = "Amina", LastName = "Kovacevic", Email = "amina.kovacevic@taximo.ba", Phone = "38762234567", LicenseNumber = "BIH-2019-045", LicenseExpiry = baseDate.AddYears(1).AddMonths(6), RatingAvg = 4.9m, TotalRides = 2100, Status = "active", PhotoUrl = "/drivers/driver2.png", CreatedAt = baseDate.AddDays(-450), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "driver.mirza", FirstName = "Mirza", LastName = "Begic", Email = "mirza.begic@taximo.ba", Phone = "38762345678", LicenseNumber = "BIH-2021-078", LicenseExpiry = baseDate.AddYears(3), RatingAvg = 4.6m, TotalRides = 850, Status = "active", PhotoUrl = "/drivers/driver3.png", CreatedAt = baseDate.AddDays(-350), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "driver.sara", FirstName = "Sara", LastName = "Dedic", Email = "sara.dedic@taximo.ba", Phone = "38762456789", LicenseNumber = "BIH-2018-112", LicenseExpiry = baseDate.AddMonths(8), RatingAvg = 4.7m, TotalRides = 1650, Status = "offline", PhotoUrl = "/drivers/driver6.png", CreatedAt = baseDate.AddDays(-500), UpdatedAt = baseDate.AddDays(-10) },
                new { Username = "driver.emir", FirstName = "Emir", LastName = "Jahic", Email = "emir.jahic@taximo.ba", Phone = "38762567890", LicenseNumber = "BIH-2022-023", LicenseExpiry = baseDate.AddYears(4), RatingAvg = 4.5m, TotalRides = 420, Status = "active", PhotoUrl = "/drivers/driver5.png", CreatedAt = baseDate.AddDays(-250), UpdatedAt = baseDate.AddDays(-5) },
                new { Username = "driver", FirstName = "Driver", LastName = "Driver", Email = "driver@taximo.ba", Phone = "3876243190", LicenseNumber = "BIH-2022-025", LicenseExpiry = baseDate.AddYears(4), RatingAvg = 4.5m, TotalRides = 150, Status = "active", PhotoUrl = "/drivers/driver4.png", CreatedAt = baseDate.AddDays(-250), UpdatedAt = baseDate.AddDays(-5) },
                new { Username = "driver.nedim", FirstName = "Nedim", LastName = "Kurtovic", Email = "nedim.kurtovic@taximo.ba", Phone = "38762611111", LicenseNumber = "BIH-2020-130", LicenseExpiry = baseDate.AddYears(2), RatingAvg = 4.6m, TotalRides = 980, Status = "active", PhotoUrl = "/drivers/driver7.png", CreatedAt = baseDate.AddDays(-380), UpdatedAt = baseDate.AddDays(-6) },
                new { Username = "driver.adnan", FirstName = "Adnan", LastName = "Basic", Email = "adnan.basic@taximo.ba", Phone = "38762622222", LicenseNumber = "BIH-2019-141", LicenseExpiry = baseDate.AddYears(1), RatingAvg = 4.4m, TotalRides = 640, Status = "active", PhotoUrl = "/drivers/driver8.png", CreatedAt = baseDate.AddDays(-360), UpdatedAt = baseDate.AddDays(-8) },
                new { Username = "driver.tarık", FirstName = "Tarik", LastName = "Mujic", Email = "tarik.mujic@taximo.ba", Phone = "38762633333", LicenseNumber = "BIH-2021-152", LicenseExpiry = baseDate.AddYears(3), RatingAvg = 4.7m, TotalRides = 1100, Status = "active", PhotoUrl = "/drivers/driver9a.png", CreatedAt = baseDate.AddDays(-340), UpdatedAt = baseDate.AddDays(-4) },
                new { Username = "driver.harun", FirstName = "Harun", LastName = "Memic", Email = "harun.memic@taximo.ba", Phone = "38762644444", LicenseNumber = "BIH-2018-163", LicenseExpiry = baseDate.AddMonths(10), RatingAvg = 4.3m, TotalRides = 520, Status = "offline", PhotoUrl = "/drivers/driver10a.png", CreatedAt = baseDate.AddDays(-520), UpdatedAt = baseDate.AddDays(-15) },
                new { Username = "driver.kenan", FirstName = "Kenan", LastName = "Hodzic", Email = "kenan.hodzic@taximo.ba", Phone = "38762655555", LicenseNumber = "BIH-2022-174", LicenseExpiry = baseDate.AddYears(4), RatingAvg = 4.8m, TotalRides = 760, Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-230), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "driver.samir", FirstName = "Samir", LastName = "Omerovic", Email = "samir.omerovic@taximo.ba", Phone = "38762666666", LicenseNumber = "BIH-2019-185", LicenseExpiry = baseDate.AddYears(1), RatingAvg = 4.2m, TotalRides = 410, Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-390), UpdatedAt = baseDate.AddDays(-12) },
                new { Username = "driver.eldar", FirstName = "Eldar", LastName = "Imamovic", Email = "eldar.imamovic@taximo.ba", Phone = "38762677777", LicenseNumber = "BIH-2020-196", LicenseExpiry = baseDate.AddYears(2), RatingAvg = 4.5m, TotalRides = 890, Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-370), UpdatedAt = baseDate.AddDays(-7) },
                new { Username = "driver.amar", FirstName = "Amar", LastName = "Selimovic", Email = "amar.selimovic@taximo.ba", Phone = "38762688888", LicenseNumber = "BIH-2021-207", LicenseExpiry = baseDate.AddYears(3), RatingAvg = 4.9m, TotalRides = 1340, Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-330), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "driver.alma", FirstName = "Alma", LastName = "Music", Email = "alma.music@taximo.ba", Phone = "38762699999", LicenseNumber = "BIH-2018-218", LicenseExpiry = baseDate.AddMonths(6), RatingAvg = 4.6m, TotalRides = 690, Status = "offline", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-480), UpdatedAt = baseDate.AddDays(-20) },
                new { Username = "driver.ivana", FirstName = "Ivana", LastName = "Petrovic", Email = "ivana.petrovic@taximo.ba", Phone = "38762700000", LicenseNumber = "BIH-2022-229", LicenseExpiry = baseDate.AddYears(4), RatingAvg = 4.7m, TotalRides = 310, Status = "active", PhotoUrl = (string?)null, CreatedAt = baseDate.AddDays(-210), UpdatedAt = baseDate.AddDays(-5) }
            };

            foreach (var driverData in driversToSeed)
            {
                var existing = await context.Drivers.FirstOrDefaultAsync(d => d.LicenseNumber == driverData.LicenseNumber);
                if (existing != null)
                {
                    existing.FirstName = driverData.FirstName;
                    existing.LastName = driverData.LastName;
                    existing.Email = driverData.Email;
                    existing.Phone = driverData.Phone;
                    existing.LicenseNumber = driverData.LicenseNumber;
                    existing.LicenseExpiry = driverData.LicenseExpiry;
                    existing.RatingAvg = driverData.RatingAvg;
                    existing.TotalRides = driverData.TotalRides;
                    existing.Status = driverData.Status;
                    existing.PhotoUrl = driverData.PhotoUrl;
                    existing.UpdatedAt = driverData.UpdatedAt;
                    // Update password hash if needed
                    PasswordHelper.CreatePasswordHash("test", out string hash, out string salt);
                    existing.PasswordHash = hash;
                    existing.PasswordSalt = salt;
                }
                else
                {
                    var newDriver = new Driver
                    {
                        Username = driverData.Username,
                        FirstName = driverData.FirstName,
                        LastName = driverData.LastName,
                        Email = driverData.Email,
                        Phone = driverData.Phone,
                        LicenseNumber = driverData.LicenseNumber,
                        LicenseExpiry = driverData.LicenseExpiry,
                        RatingAvg = driverData.RatingAvg,
                        TotalRides = driverData.TotalRides,
                        Status = driverData.Status,
                        PhotoUrl = driverData.PhotoUrl,
                        CreatedAt = driverData.CreatedAt,
                        UpdatedAt = driverData.UpdatedAt
                    };
                    PasswordHelper.CreatePasswordHash("test", out string hash, out string salt);
                    newDriver.PasswordHash = hash;
                    newDriver.PasswordSalt = salt;
                    context.Drivers.Add(newDriver);
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertUserRolesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get roles by their unique keys
            var adminRole = await context.Roles.FirstOrDefaultAsync(r => r.Name == "Admin");
            var userRole = await context.Roles.FirstOrDefaultAsync(r => r.Name == "User");

            if (adminRole == null || userRole == null)
            {
                return; // Cannot proceed without required roles
            }

            // Get all users that need roles assigned
            var adminUsers = await context.Users
                .Where(u => u.Username == "admin" || u.Username == "desktop")
                .ToListAsync();

            var regularUsers = await context.Users
                .Where(u => u.Username != "admin" && u.Username != "desktop")
                .ToListAsync();

            // Assign Admin role to admin and desktop users
            foreach (var user in adminUsers)
            {
                var existing = await context.UserRoles.FirstOrDefaultAsync(ur => ur.UserId == user.UserId && ur.RoleId == adminRole.RoleId);
                if (existing == null)
                {
                    context.UserRoles.Add(new UserRole
                    {
                        UserId = user.UserId,
                        RoleId = adminRole.RoleId,
                        DateAssigned = baseDate
                    });
                }
            }

            // Assign User role to all other users
            foreach (var user in regularUsers)
            {
                var existing = await context.UserRoles.FirstOrDefaultAsync(ur => ur.UserId == user.UserId && ur.RoleId == userRole.RoleId);
                if (existing == null)
                {
                    context.UserRoles.Add(new UserRole
                    {
                        UserId = user.UserId,
                        RoleId = userRole.RoleId,
                        DateAssigned = baseDate
                    });
                }
            }

            await context.SaveChangesAsync();
        }

        private static async Task UpsertDriverRolesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get drivers and role by their unique keys
            var drivers = await context.Drivers.ToListAsync();
            var driverRole = await context.Roles.FirstOrDefaultAsync(r => r.Name == "Driver");

            if (driverRole == null || drivers.Count == 0)
            {
                return; // Cannot proceed without required entities
            }

            foreach (var driver in drivers)
            {
                var existing = await context.DriverRoles.FirstOrDefaultAsync(dr => dr.DriverId == driver.DriverId && dr.RoleId == driverRole.RoleId);
                if (existing == null)
                {
                    context.DriverRoles.Add(new DriverRole
                    {
                        DriverId = driver.DriverId,
                        RoleId = driverRole.RoleId,
                        DateAssigned = baseDate
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertVehiclesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get all drivers by username
            var driverUsernames = new[]
            {
                "driver.ahmed", "driver.amina", "driver.mirza", "driver.sara", "driver.emir",
                "driver", "driver.nedim", "driver.adnan", "driver.tarık", "driver.harun",
                "driver.kenan", "driver.samir", "driver.eldar", "driver.amar", "driver.alma", "driver.ivana"
            };

            var drivers = new Dictionary<string, Driver>();
            foreach (var username in driverUsernames)
            {
                var driver = await context.Drivers.FirstOrDefaultAsync(d => d.Username == username);
                if (driver != null)
                {
                    drivers[username] = driver;
                }
            }

            if (drivers.Count == 0)
            {
                return; // Cannot proceed without drivers
            }

            // Vehicle data mapped to driver usernames
            var vehiclesToSeed = new[]
            {
                new { Username = "driver.ahmed", PlateNumber = "A-123-BH", Make = "Skoda", Model = "Octavia", Year = 2020, Color = "White", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-400), UpdatedAt = baseDate.AddDays(-1) },
                new { Username = "driver.amina", PlateNumber = "S-456-SA", Make = "Volkswagen", Model = "Golf", Year = 2019, Color = "Black", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-450), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "driver.mirza", PlateNumber = "T-789-TU", Make = "Mercedes-Benz", Model = "E-Class", Year = 2021, Color = "Silver", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-350), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "driver.sara", PlateNumber = "Z-321-ZE", Make = "Toyota", Model = "Corolla", Year = 2018, Color = "Blue", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-500), UpdatedAt = baseDate.AddDays(-10) },
                new { Username = "driver.emir", PlateNumber = "B-654-BI", Make = "Ford", Model = "Focus", Year = 2022, Color = "Red", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-250), UpdatedAt = baseDate.AddDays(-5) },
                new { Username = "driver", PlateNumber = "D-111-BH", Make = "Peugeot", Model = "308", Year = 2021, Color = "Gray", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-250), UpdatedAt = baseDate.AddDays(-5) },
                new { Username = "driver.nedim", PlateNumber = "N-222-SA", Make = "Opel", Model = "Astra", Year = 2020, Color = "Black", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-380), UpdatedAt = baseDate.AddDays(-6) },
                new { Username = "driver.adnan", PlateNumber = "AD-333-TU", Make = "Renault", Model = "Clio", Year = 2019, Color = "Blue", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-360), UpdatedAt = baseDate.AddDays(-8) },
                new { Username = "driver.tarık", PlateNumber = "T-444-ZE", Make = "BMW", Model = "3 Series", Year = 2022, Color = "White", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-340), UpdatedAt = baseDate.AddDays(-4) },
                new { Username = "driver.harun", PlateNumber = "H-555-BI", Make = "Audi", Model = "A4", Year = 2021, Color = "Silver", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-520), UpdatedAt = baseDate.AddDays(-15) },
                new { Username = "driver.kenan", PlateNumber = "K-666-BH", Make = "Hyundai", Model = "i30", Year = 2020, Color = "Red", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-230), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "driver.samir", PlateNumber = "S-777-SA", Make = "Kia", Model = "Ceed", Year = 2019, Color = "White", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-390), UpdatedAt = baseDate.AddDays(-12) },
                new { Username = "driver.eldar", PlateNumber = "E-888-TU", Make = "Mazda", Model = "3", Year = 2021, Color = "Black", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-370), UpdatedAt = baseDate.AddDays(-7) },
                new { Username = "driver.amar", PlateNumber = "AM-999-ZE", Make = "Volvo", Model = "S60", Year = 2022, Color = "Blue", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-330), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "driver.alma", PlateNumber = "AL-101-BI", Make = "Seat", Model = "Leon", Year = 2020, Color = "Gray", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-480), UpdatedAt = baseDate.AddDays(-20) },
                new { Username = "driver.ivana", PlateNumber = "I-202-BH", Make = "Fiat", Model = "Tipo", Year = 2021, Color = "Red", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-210), UpdatedAt = baseDate.AddDays(-5) }
            };

            foreach (var vehicleData in vehiclesToSeed)
            {
                if (!drivers.ContainsKey(vehicleData.Username))
                {
                    continue; // Skip if driver not found
                }

                var driver = drivers[vehicleData.Username];
                var existing = await context.Vehicles.FirstOrDefaultAsync(v => v.PlateNumber == vehicleData.PlateNumber);
                
                if (existing != null)
                {
                    existing.DriverId = driver.DriverId;
                    existing.Make = vehicleData.Make;
                    existing.Model = vehicleData.Model;
                    existing.Year = vehicleData.Year;
                    existing.Color = vehicleData.Color;
                    existing.VehicleType = vehicleData.VehicleType;
                    existing.Capacity = vehicleData.Capacity;
                    existing.Status = vehicleData.Status;
                    existing.UpdatedAt = vehicleData.UpdatedAt;
                }
                else
                {
                    context.Vehicles.Add(new Vehicle
                    {
                        DriverId = driver.DriverId,
                        Make = vehicleData.Make,
                        Model = vehicleData.Model,
                        Year = vehicleData.Year,
                        PlateNumber = vehicleData.PlateNumber,
                        Color = vehicleData.Color,
                        VehicleType = vehicleData.VehicleType,
                        Capacity = vehicleData.Capacity,
                        Status = vehicleData.Status,
                        CreatedAt = vehicleData.CreatedAt,
                        UpdatedAt = vehicleData.UpdatedAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertLocationsAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get users for personal locations
            var userUsernames = new[] { "aldinakurtovic", "elmedinamaric", "amirsaric", "lejlahadzic", "harisbegic", "majaperic", "nedimkapetanovic", "sanjakovac" };
            var users = new Dictionary<string, User>();
            foreach (var username in userUsernames)
            {
                var user = await context.Users.FirstOrDefaultAsync(u => u.Username == username);
                if (user != null)
                {
                    users[username] = user;
                }
            }

            var locationsToSeed = new[]
            {
                // Public locations in Mostar
                new { Name = "Mostar Airport", AddressLine = "Mostar Airport, M17", City = "Mostar", Lat = 43.2828m, Lng = 17.8458m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-180), UpdatedAt = baseDate.AddDays(-10) },
                new { Name = "Stari Most (Old Bridge)", AddressLine = "Stari Most bb", City = "Mostar", Lat = 43.3370m, Lng = 17.8150m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-170), UpdatedAt = baseDate.AddDays(-12) },
                new { Name = "City Center Mostar", AddressLine = "Marsala Tita 12", City = "Mostar", Lat = 43.3438m, Lng = 17.8078m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-165), UpdatedAt = baseDate.AddDays(-11) },
                new { Name = "Shopping Center Mostar", AddressLine = "Rondo bb", City = "Mostar", Lat = 43.3480m, Lng = 17.8120m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-160), UpdatedAt = baseDate.AddDays(-6) },
                new { Name = "Train Station Mostar", AddressLine = "Kolodvorska 5", City = "Mostar", Lat = 43.3520m, Lng = 17.8020m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-155), UpdatedAt = baseDate.AddDays(-8) },
                new { Name = "Bus Station Mostar", AddressLine = "Kolodvorska 2", City = "Mostar", Lat = 43.3510m, Lng = 17.8010m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-150), UpdatedAt = baseDate.AddDays(-7) },
                new { Name = "University of Mostar", AddressLine = "Matice hrvatske bb", City = "Mostar", Lat = 43.3488m, Lng = 17.8095m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-145), UpdatedAt = baseDate.AddDays(-9) },
                new { Name = "Mostar Hospital", AddressLine = "Crkve 65", City = "Mostar", Lat = 43.3400m, Lng = 17.8150m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-140), UpdatedAt = baseDate.AddDays(-5) },
                
                // Personal locations (Home addresses)
                new { Name = "Home", AddressLine = "Bulevar bb 15", City = "Mostar", Lat = 43.3380m, Lng = 17.8050m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-200), UpdatedAt = baseDate.AddDays(-5) },
                new { Name = "Home", AddressLine = "Kralja Tvrtka 23", City = "Mostar", Lat = 43.3450m, Lng = 17.8100m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-195), UpdatedAt = baseDate.AddDays(-4) },
                new { Name = "Home", AddressLine = "Mehmeda Spahe 8", City = "Mostar", Lat = 43.3420m, Lng = 17.8080m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-190), UpdatedAt = baseDate.AddDays(-8) },
                new { Name = "Work Office", AddressLine = "Aleja Bosanskih Viteza 12", City = "Mostar", Lat = 43.3470m, Lng = 17.8060m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-185), UpdatedAt = baseDate.AddDays(-3) },
                new { Name = "Work Office", AddressLine = "Bulevar 1", City = "Mostar", Lat = 43.3440m, Lng = 17.8090m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-180), UpdatedAt = baseDate.AddDays(-2) },
                new { Name = "Home", AddressLine = "Carinska 25", City = "Mostar", Lat = 43.3410m, Lng = 17.8070m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-175), UpdatedAt = baseDate.AddDays(-6) },
                new { Name = "Home", AddressLine = "Jadranska 42", City = "Mostar", Lat = 43.3460m, Lng = 17.8110m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-170), UpdatedAt = baseDate.AddDays(-4) }
            };

            // Assign personal locations to users if available
            var userList = users.Values.ToList();
            var homeLocationCount = 0;
            var workOfficeCount = 0;

            foreach (var locationData in locationsToSeed)
            {
                int? userId = locationData.UserId;
                
                // Assign Home locations to users sequentially
                if (locationData.Name == "Home" && userList.Count > 0)
                {
                    userId = userList[homeLocationCount % userList.Count].UserId;
                    homeLocationCount++;
                }
                // Assign Work Office locations to users sequentially
                else if (locationData.Name == "Work Office" && userList.Count > 0)
                {
                    userId = userList[workOfficeCount % userList.Count].UserId;
                    workOfficeCount++;
                }

                var existing = await context.Locations.FirstOrDefaultAsync(l =>
                    l.Name == locationData.Name &&
                    l.AddressLine == locationData.AddressLine &&
                    l.City == locationData.City &&
                    l.UserId == userId);
                
                if (existing != null)
                {
                    existing.Lat = locationData.Lat;
                    existing.Lng = locationData.Lng;
                    existing.UpdatedAt = locationData.UpdatedAt;
                }
                else
                {
                    context.Locations.Add(new Location
                    {
                        UserId = userId,
                        Name = locationData.Name,
                        AddressLine = locationData.AddressLine,
                        City = locationData.City,
                        Lat = locationData.Lat,
                        Lng = locationData.Lng,
                        CreatedAt = locationData.CreatedAt,
                        UpdatedAt = locationData.UpdatedAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertPromoCodesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var promoCodesToSeed = new[]
            {
                new { Code = "WELCOME10", Description = "Welcome discount for new users", DiscountType = "percentage", DiscountValue = 10.00m, UsageLimit = 100, ValidFrom = baseDate.AddDays(-100), ValidUntil = baseDate.AddDays(200), Status = "active", CreatedAt = baseDate.AddDays(-100) },
                new { Code = "FIRST20", Description = "20% off first ride", DiscountType = "percentage", DiscountValue = 20.00m, UsageLimit = 50, ValidFrom = baseDate.AddDays(-80), ValidUntil = baseDate.AddDays(120), Status = "active", CreatedAt = baseDate.AddDays(-80) },
                new { Code = "FIXED5", Description = "5 EUR off your ride", DiscountType = "fixed", DiscountValue = 5.00m, UsageLimit = 200, ValidFrom = baseDate.AddDays(-60), ValidUntil = baseDate.AddDays(140), Status = "active", CreatedAt = baseDate.AddDays(-60) },
                new { Code = "WEEKEND15", Description = "15% off weekend rides", DiscountType = "percentage", DiscountValue = 15.00m, UsageLimit = 75, ValidFrom = baseDate.AddDays(-40), ValidUntil = baseDate.AddDays(60), Status = "active", CreatedAt = baseDate.AddDays(-40) },
                new { Code = "EXPIRED", Description = "Expired promo code", DiscountType = "percentage", DiscountValue = 10.00m, UsageLimit = 100, ValidFrom = baseDate.AddDays(-200), ValidUntil = baseDate.AddDays(-50), Status = "expired", CreatedAt = baseDate.AddDays(-200) }
            };

            foreach (var promoData in promoCodesToSeed)
            {
                var existing = await context.PromoCodes.FirstOrDefaultAsync(p => p.Code == promoData.Code);
                if (existing != null)
                {
                    existing.Description = promoData.Description;
                    existing.DiscountType = promoData.DiscountType;
                    existing.DiscountValue = promoData.DiscountValue;
                    existing.UsageLimit = promoData.UsageLimit;
                    existing.ValidFrom = promoData.ValidFrom;
                    existing.ValidUntil = promoData.ValidUntil;
                    existing.Status = promoData.Status;
                }
                else
                {
                    context.PromoCodes.Add(new PromoCode
                    {
                        Code = promoData.Code,
                        Description = promoData.Description,
                        DiscountType = promoData.DiscountType,
                        DiscountValue = promoData.DiscountValue,
                        UsageLimit = promoData.UsageLimit,
                        ValidFrom = promoData.ValidFrom,
                        ValidUntil = promoData.ValidUntil,
                        Status = promoData.Status,
                        CreatedAt = promoData.CreatedAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertRidesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get main driver (driver) and mobile user
            var mainDriver = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver");
            var mobileUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "mobile");
            
            // Get all other drivers (excluding main driver)
            var otherDrivers = await context.Drivers
                .Where(d => d.Username != "driver")
                .ToListAsync();

            // Get all users (excluding mobile for now, will add rides for mobile separately)
            var allUsers = await context.Users
                .Where(u => u.Username != "mobile" && u.Username != "admin" && u.Username != "desktop")
                .ToListAsync();

            // Get all vehicles
            var vehicles = await context.Vehicles.ToListAsync();
            var vehicleByDriver = vehicles.ToDictionary(v => v.DriverId);

            // Get all locations in Mostar
            var locations = await context.Locations
                .Where(l => l.City == "Mostar")
                .ToListAsync();

            if (mainDriver == null || mobileUser == null || otherDrivers.Count == 0 || locations.Count < 2)
            {
                return;
            }

            var mainDriverVehicle = vehicleByDriver.GetValueOrDefault(mainDriver.DriverId);
            if (mainDriverVehicle == null)
            {
                return;
            }

            // Helper class for ride data
            var ridesToSeed = new List<(int RiderId, int DriverId, int VehicleId, int PickupLocationId, int DropoffLocationId, DateTime RequestedAt, DateTime? StartedAt, DateTime? CompletedAt, string Status, decimal FareEstimate, decimal? FareFinal, decimal? DistanceKm, int? DurationMin)>();

            // 1. Mobile user - sve completed vožnje (najviše sa main driver "driver")
            // Mobile: 10 completed (6 sa "driver", 4 sa ostalima)
            var mobileRidesWithMainDriver = 6;
            for (int i = 0; i < mobileRidesWithMainDriver; i++)
            {
                var pickupLoc = locations[i % locations.Count];
                var dropoffLoc = locations[(i + 1) % locations.Count];
                
                if (pickupLoc.LocationId == dropoffLoc.LocationId)
                {
                    dropoffLoc = locations[(i + 2) % locations.Count];
                }

                var requestedAt = baseDate.AddDays(-(mobileRidesWithMainDriver - i)).AddHours(-i * 2);
                var startedAt = requestedAt.AddMinutes(5);
                var completedAt = startedAt.AddMinutes(15 + (i % 20));
                var distance = 3.5m + (i % 10) * 0.5m;
                var duration = 15 + (i % 20);
                var fare = 8.0m + (i % 15) * 1.5m;

                ridesToSeed.Add((
                    RiderId: mobileUser.UserId,
                    DriverId: mainDriver.DriverId,
                    VehicleId: mainDriverVehicle.VehicleId,
                    PickupLocationId: pickupLoc.LocationId,
                    DropoffLocationId: dropoffLoc.LocationId,
                    RequestedAt: requestedAt,
                    StartedAt: (DateTime?)startedAt,
                    CompletedAt: (DateTime?)completedAt,
                    Status: "completed",
                    FareEstimate: fare,
                    FareFinal: (decimal?)fare,
                    DistanceKm: (decimal?)distance,
                    DurationMin: (int?)duration
                ));
            }

            // Mobile: 4 completed sa ostalim driverima
            var mobileRidesWithOthers = 4;
            var availableDriversForMobile = otherDrivers.Take(Math.Min(mobileRidesWithOthers, otherDrivers.Count)).ToList();
            for (int i = 0; i < mobileRidesWithOthers; i++)
            {
                var driver = availableDriversForMobile[i % availableDriversForMobile.Count];
                var driverVehicle = vehicleByDriver.GetValueOrDefault(driver.DriverId);
                if (driverVehicle == null) continue;

                var pickupLoc = locations[(i + 10) % locations.Count];
                var dropoffLoc = locations[(i + 12) % locations.Count];
                
                if (pickupLoc.LocationId == dropoffLoc.LocationId)
                {
                    dropoffLoc = locations[(i + 14) % locations.Count];
                }

                var requestedAt = baseDate.AddDays(-(mobileRidesWithOthers - i + 10)).AddHours(-i * 3);
                var startedAt = requestedAt.AddMinutes(7);
                var completedAt = startedAt.AddMinutes(18 + (i % 15));
                var distance = 4.0m + (i % 12) * 0.6m;
                var duration = 18 + (i % 15);
                var fare = 9.0m + (i % 12) * 1.8m;

                ridesToSeed.Add((
                    RiderId: mobileUser.UserId,
                    DriverId: driver.DriverId,
                    VehicleId: driverVehicle.VehicleId,
                    PickupLocationId: pickupLoc.LocationId,
                    DropoffLocationId: dropoffLoc.LocationId,
                    RequestedAt: requestedAt,
                    StartedAt: (DateTime?)startedAt,
                    CompletedAt: (DateTime?)completedAt,
                    Status: "completed",
                    FareEstimate: fare,
                    FareFinal: (decimal?)fare,
                    DistanceKm: (decimal?)distance,
                    DurationMin: (int?)duration
                ));
            }

            // 2. Ostali korisnici - po jedna completed vožnja (6 korisnika)
            var otherUsersCompletedCount = 6;
            var driversForOtherUsers = otherDrivers.ToList();
            for (int i = 0; i < otherUsersCompletedCount && i < allUsers.Count; i++)
            {
                var rider = allUsers[i];
                var driver = driversForOtherUsers[i % driversForOtherUsers.Count];
                var driverVehicle = vehicleByDriver.GetValueOrDefault(driver.DriverId);
                if (driverVehicle == null) continue;

                var pickupLoc = locations[(i + 20) % locations.Count];
                var dropoffLoc = locations[(i + 21) % locations.Count];
                
                if (pickupLoc.LocationId == dropoffLoc.LocationId)
                {
                    dropoffLoc = locations[(i + 22) % locations.Count];
                }

                var requestedAt = baseDate.AddDays(-(otherUsersCompletedCount - i + 20)).AddHours(-i * 2);
                var startedAt = requestedAt.AddMinutes(5);
                var completedAt = startedAt.AddMinutes(15 + (i % 20));
                var distance = 3.5m + (i % 10) * 0.5m;
                var duration = 15 + (i % 20);
                var fare = 8.0m + (i % 15) * 1.5m;

                ridesToSeed.Add((
                    RiderId: rider.UserId,
                    DriverId: driver.DriverId,
                    VehicleId: driverVehicle.VehicleId,
                    PickupLocationId: pickupLoc.LocationId,
                    DropoffLocationId: dropoffLoc.LocationId,
                    RequestedAt: requestedAt,
                    StartedAt: (DateTime?)startedAt,
                    CompletedAt: (DateTime?)completedAt,
                    Status: "completed",
                    FareEstimate: fare,
                    FareFinal: (decimal?)fare,
                    DistanceKm: (decimal?)distance,
                    DurationMin: (int?)duration
                ));
            }

            // 3. Samo 3 requested ride općenito (od drugih korisnika, ne od mobile)
            var requestedRidesCount = 3;
            for (int i = 0; i < requestedRidesCount && i < allUsers.Count; i++)
            {
                var rider = allUsers[(i + otherUsersCompletedCount) % allUsers.Count]; // Različiti korisnici od onih sa completed
                var driver = driversForOtherUsers[(i + 2) % driversForOtherUsers.Count];
                var driverVehicle = vehicleByDriver.GetValueOrDefault(driver.DriverId);
                if (driverVehicle == null) continue;

                var pickupLoc = locations[(i + 30) % locations.Count];
                var dropoffLoc = locations[(i + 31) % locations.Count];
                
                if (pickupLoc.LocationId == dropoffLoc.LocationId)
                {
                    dropoffLoc = locations[(i + 32) % locations.Count];
                }

                var requestedAt = baseDate.AddDays(-(requestedRidesCount - i)).AddHours(-i * 2);
                var fare = 7.0m + (i % 5) * 1.2m;

                ridesToSeed.Add((
                    RiderId: rider.UserId,
                    DriverId: driver.DriverId,
                    VehicleId: driverVehicle.VehicleId,
                    PickupLocationId: pickupLoc.LocationId,
                    DropoffLocationId: dropoffLoc.LocationId,
                    RequestedAt: requestedAt,
                    StartedAt: (DateTime?)null,
                    CompletedAt: (DateTime?)null,
                    Status: "requested",
                    FareEstimate: fare,
                    FareFinal: (decimal?)null,
                    DistanceKm: (decimal?)null,
                    DurationMin: (int?)null
                ));
            }

            // 4. Jedna active ride od nekog drugog korisnika
            if (allUsers.Count > 0)
            {
                var activeRideRider = allUsers[(otherUsersCompletedCount + requestedRidesCount) % allUsers.Count];
                var activeRideDriver = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.mirza");
                if (activeRideDriver != null)
            {
                    var activeRideVehicle = vehicleByDriver.GetValueOrDefault(activeRideDriver.DriverId);
                    if (activeRideVehicle != null && locations.Count >= 2)
                {
                        var pickupLoc = locations[0];
                        var dropoffLoc = locations[1];
                    
                    if (pickupLoc.LocationId == dropoffLoc.LocationId && locations.Count > 2)
                    {
                        dropoffLoc = locations[2];
                    }

                        var requestedAt = baseDate.AddHours(-1);
                        var startedAt = requestedAt.AddMinutes(5);
                    var distance = 5.5m;
                    var duration = 20;
                    var fare = 12.0m;

                    ridesToSeed.Add((
                            RiderId: activeRideRider.UserId,
                            DriverId: activeRideDriver.DriverId,
                            VehicleId: activeRideVehicle.VehicleId,
                        PickupLocationId: pickupLoc.LocationId,
                        DropoffLocationId: dropoffLoc.LocationId,
                        RequestedAt: requestedAt,
                        StartedAt: (DateTime?)startedAt,
                            CompletedAt: (DateTime?)null,
                        Status: "active",
                        FareEstimate: fare,
                            FareFinal: (decimal?)null,
                        DistanceKm: (decimal?)distance,
                        DurationMin: (int?)duration
                    ));
                    }
                }
            }

            // Upsert all rides
            foreach (var rideData in ridesToSeed)
            {
                var existing = await context.Rides.FirstOrDefaultAsync(r =>
                    r.RiderId == rideData.RiderId &&
                    r.DriverId == rideData.DriverId &&
                    r.PickupLocationId == rideData.PickupLocationId &&
                    r.DropoffLocationId == rideData.DropoffLocationId &&
                    r.RequestedAt.Date == rideData.RequestedAt.Date);
                
                if (existing != null)
                {
                    existing.VehicleId = rideData.VehicleId;
                    existing.StartedAt = rideData.StartedAt;
                    existing.CompletedAt = rideData.CompletedAt;
                    existing.Status = rideData.Status;
                    existing.FareEstimate = rideData.FareEstimate;
                    existing.FareFinal = rideData.FareFinal;
                    existing.DistanceKm = rideData.DistanceKm;
                    existing.DurationMin = rideData.DurationMin;
                }
                else
                {
                    context.Rides.Add(new Ride
                    {
                        RiderId = rideData.RiderId,
                        DriverId = rideData.DriverId,
                        VehicleId = rideData.VehicleId,
                        PickupLocationId = rideData.PickupLocationId,
                        DropoffLocationId = rideData.DropoffLocationId,
                        RequestedAt = rideData.RequestedAt,
                        StartedAt = rideData.StartedAt,
                        CompletedAt = rideData.CompletedAt,
                        Status = rideData.Status,
                        FareEstimate = rideData.FareEstimate,
                        FareFinal = rideData.FareFinal,
                        DistanceKm = rideData.DistanceKm,
                        DurationMin = rideData.DurationMin
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertPaymentsAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get mobile user - will have most payments
            var mobileUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "mobile");
            
            // Get all users who can have payments
            var allUsers = await context.Users
                .Where(u => u.Username != "admin" && u.Username != "desktop")
                .ToListAsync();

            if (allUsers.Count == 0) return;

            // Get all completed rides with fare information
            var allCompletedRides = await context.Rides
                .Where(r => r.Status == "completed" && r.FareFinal.HasValue)
                .OrderBy(r => r.RequestedAt)
                .ToListAsync();

            if (allCompletedRides.Count == 0) return;

            var paymentCounter = 1;

            // Mobile user - most payments (for all completed rides)
            if (mobileUser != null)
            {
                var mobileCompletedRides = allCompletedRides
                    .Where(r => r.RiderId == mobileUser.UserId)
                    .ToList();

                foreach (var ride in mobileCompletedRides)
                {
                    var fareAmount = ride.FareFinal.Value;
                    var rideIndex = mobileCompletedRides.IndexOf(ride);

                    // Most payments are completed (online or cash)
                    // 70% online, 30% cash
                    var isOnline = (rideIndex % 10) < 7;
                    var paymentMethod = isOnline ? "online" : "cash";
                    
                    // Generate transaction ref for online payments
                    string? transactionRef = null;
                    if (isOnline)
                    {
                        transactionRef = $"TXN-MOB-2024-{paymentCounter.ToString("D6")}";
                        paymentCounter++;
                    }

                    // 95% completed, 4% pending, 1% refunded
                    string status;
                    DateTime? paidAt;
                    var statusIndex = rideIndex % 100;
                    
                    if (statusIndex < 95)
                    {
                        status = "completed";
                        paidAt = ride.CompletedAt?.AddMinutes(2 + (rideIndex % 5));
                    }
                    else if (statusIndex < 99)
                    {
                        status = "pending";
                        paidAt = null;
                }
                else
                {
                        status = "refunded";
                        paidAt = ride.CompletedAt?.AddMinutes(10 + (rideIndex % 5));
                        transactionRef = isOnline ? $"TXN-MOB-REF-2024-{paymentCounter.ToString("D6")}" : null;
                    }

                    var existing = await GetExistingPayment(context, ride.RideId, transactionRef, fareAmount, paymentMethod);

                if (existing != null)
                {
                        existing.UserId = mobileUser.UserId;
                        existing.Amount = fareAmount;
                        existing.Currency = "EUR";
                        existing.Method = paymentMethod;
                        existing.Status = status;
                        existing.TransactionRef = transactionRef;
                        existing.PaidAt = paidAt;
                }
                else
                {
                    context.Payments.Add(new Payment
                    {
                            RideId = ride.RideId,
                            UserId = mobileUser.UserId,
                            Amount = fareAmount,
                            Currency = "EUR",
                            Method = paymentMethod,
                            Status = status,
                            TransactionRef = transactionRef,
                            PaidAt = paidAt
                    });
                }
            }
            }

            // Other users - payments for ALL completed rides (100%)
            var otherUsersRides = allCompletedRides
                .Where(r => mobileUser == null || r.RiderId != mobileUser.UserId)
                .GroupBy(r => r.RiderId)
                .ToList();

            foreach (var userRides in otherUsersRides)
            {
                var user = allUsers.FirstOrDefault(u => u.UserId == userRides.Key);
                if (user == null) continue;

                // Each user pays for ALL of their completed rides (100%)
                var ridesToPay = userRides.ToList();

                foreach (var ride in ridesToPay)
                {
                    var fareAmount = ride.FareFinal.Value;
                    var rideIndex = ridesToPay.IndexOf(ride);

                    // Mix of online and cash (50/50)
                    var isOnline = (rideIndex % 2) == 0;
                    var paymentMethod = isOnline ? "online" : "cash";
                    
                    string? transactionRef = null;
                    if (isOnline)
                    {
                        transactionRef = $"TXN-{user.UserId}-2024-{paymentCounter.ToString("D6")}";
                        paymentCounter++;
                    }

                    // 90% completed, 8% pending, 2% refunded
                    string status;
                    DateTime? paidAt;
                    var statusIndex = (ride.RideId + user.UserId) % 100;
                    
                    if (statusIndex < 90)
                    {
                        status = "completed";
                        paidAt = ride.CompletedAt?.AddMinutes(1 + (rideIndex % 4));
                    }
                    else if (statusIndex < 98)
                    {
                        status = "pending";
                        paidAt = null;
                    }
                    else
                    {
                        status = "refunded";
                        paidAt = ride.CompletedAt?.AddMinutes(8 + (rideIndex % 3));
                        transactionRef = isOnline ? $"TXN-{user.UserId}-REF-2024-{paymentCounter.ToString("D6")}" : null;
                    }

                    var existing = await GetExistingPayment(context, ride.RideId, transactionRef, fareAmount, paymentMethod);
                    
                    if (existing != null)
                    {
                        existing.UserId = user.UserId;
                        existing.Amount = fareAmount;
                        existing.Currency = "EUR";
                        existing.Method = paymentMethod;
                        existing.Status = status;
                        existing.TransactionRef = transactionRef;
                        existing.PaidAt = paidAt;
                    }
                    else
                    {
                        context.Payments.Add(new Payment
                        {
                            RideId = ride.RideId,
                            UserId = user.UserId,
                            Amount = fareAmount,
                            Currency = "EUR",
                            Method = paymentMethod,
                            Status = status,
                            TransactionRef = transactionRef,
                            PaidAt = paidAt
                        });
                    }
                }
            }

            await context.SaveChangesAsync();
        }

        private static async Task<Payment?> GetExistingPayment(TaxiMoDbContext context, int rideId, string? transactionRef, decimal amount, string method)
        {
            if (!string.IsNullOrEmpty(transactionRef))
            {
                return await context.Payments.FirstOrDefaultAsync(p =>
                    p.RideId == rideId &&
                    p.TransactionRef == transactionRef);
            }
            else
            {
                return await context.Payments.FirstOrDefaultAsync(p =>
                    p.RideId == rideId &&
                    p.Amount == amount &&
                    p.Method == method &&
                    p.TransactionRef == null);
            }
        }

        private static async Task UpsertReviewsAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get mobile user - will leave most reviews
            var mobileUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "mobile");
            
            // Get all users who can leave reviews
            var allUsers = await context.Users
                .Where(u => u.Username != "admin" && u.Username != "desktop")
                .ToListAsync();

            // Review comments pool
            var positiveComments = new[]
            {
                "Great ride, professional driver!",
                "Excellent service, very polite and safe driver.",
                "Fast and efficient. Highly recommended!",
                "Punctual and friendly driver. Great experience.",
                "Clean car and smooth ride. Thank you!",
                "Best taxi service in Mostar. Will use again!",
                "Very professional and courteous. 5 stars!",
                "Driver was on time and drove safely. Excellent!",
                "Great communication and clean vehicle. Loved it!",
                "Perfect service from start to finish. Thank you!",
                "Driver was very helpful and professional.",
                "Smooth ride, good driver. Recommended!",
                "Excellent experience, will definitely use again.",
                "Very satisfied with the service. Top notch!",
                "Professional driver, clean car. Great job!"
            };

            var goodComments = new[]
            {
                "Good ride overall, driver was friendly.",
                "Satisfactory service. Car was clean.",
                "Decent experience. Driver was okay.",
                "Average service but got to destination safely.",
                "Driver was punctual and car was fine.",
                "Acceptable ride. Nothing special but okay.",
                "Driver was nice but could be more talkative.",
                "Good service, would use again."
            };

            // Get all completed rides
            var allCompletedRides = await context.Rides
                .Where(r => r.Status == "completed")
                .OrderBy(r => r.RequestedAt)
                .ToListAsync();

            if (allCompletedRides.Count == 0) return;

            // Mobile user leaves reviews for all their completed rides
            if (mobileUser != null)
            {
                var mobileCompletedRides = allCompletedRides
                    .Where(r => r.RiderId == mobileUser.UserId)
                    .ToList();

                foreach (var ride in mobileCompletedRides)
            {
                var existingReview = await context.Reviews.FirstOrDefaultAsync(r =>
                    r.RideId == ride.RideId &&
                    r.RiderId == ride.RiderId &&
                    r.DriverId == ride.DriverId);

                if (existingReview != null)
                {
                        continue; // Skip if review already exists
                }

                    // Mobile user gives mostly high ratings with varied comments
                    var ratingIndex = ride.RideId % mobileCompletedRides.Count;
                    var rating = 4.5m + (ratingIndex % 5) * 0.1m; // 4.5 to 5.0
                    var comment = positiveComments[ratingIndex % positiveComments.Length];

                context.Reviews.Add(new Review
                {
                    RideId = ride.RideId,
                    RiderId = ride.RiderId,
                    DriverId = ride.DriverId,
                        Rating = rating,
                        Comment = comment,
                        CreatedAt = ride.CompletedAt?.AddMinutes(5) ?? baseDate
                    });
                }
            }

            // Other users leave reviews for some of their completed rides (not all)
            var otherUsersCompletedRides = allCompletedRides
                .Where(r => mobileUser == null || r.RiderId != mobileUser.UserId)
                .GroupBy(r => r.RiderId)
                .ToList();

            foreach (var userRides in otherUsersCompletedRides)
            {
                // Each user leaves reviews for about 60-80% of their completed rides
                var ridesToReview = userRides
                    .Take((int)(userRides.Count() * (0.6 + (userRides.Key % 3) * 0.1)))
                    .ToList();

                foreach (var ride in ridesToReview)
                {
                    var existingReview = await context.Reviews.FirstOrDefaultAsync(r =>
                        r.RideId == ride.RideId &&
                        r.RiderId == ride.RiderId &&
                        r.DriverId == ride.DriverId);

                    if (existingReview != null)
                    {
                        continue; // Skip if review already exists
                    }

                    // Other users give varied ratings
                    var ratingIndex = ride.RideId % 10;
                    decimal rating;
                    string comment;

                    if (ratingIndex < 7) // 70% positive ratings
                    {
                        rating = 4.0m + (ratingIndex % 5) * 0.2m; // 4.0 to 4.8
                        comment = positiveComments[ratingIndex % positiveComments.Length];
                    }
                    else // 30% good but not perfect
                    {
                        rating = 3.5m + ((ratingIndex - 7) % 3) * 0.3m; // 3.5 to 4.4
                        comment = goodComments[(ratingIndex - 7) % goodComments.Length];
                    }

                    context.Reviews.Add(new Review
                    {
                        RideId = ride.RideId,
                        RiderId = ride.RiderId,
                        DriverId = ride.DriverId,
                        Rating = rating,
                        Comment = comment,
                        CreatedAt = ride.CompletedAt?.AddMinutes(3 + (ratingIndex % 10)) ?? baseDate
                    });
                }
            }

            await context.SaveChangesAsync();
        }

        private static async Task UpsertPromoUsagesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            if (johnDoeUser == null) return;

            var rides = await context.Rides
                .Where(r => r.RiderId == johnDoeUser.UserId)
                .OrderBy(r => r.RequestedAt)
                .ToListAsync();

            var welcomePromo = await context.PromoCodes.FirstOrDefaultAsync(p => p.Code == "WELCOME10");
            var first20Promo = await context.PromoCodes.FirstOrDefaultAsync(p => p.Code == "FIRST20");
            var fixed5Promo = await context.PromoCodes.FirstOrDefaultAsync(p => p.Code == "FIXED5");
            var weekend15Promo = await context.PromoCodes.FirstOrDefaultAsync(p => p.Code == "WEEKEND15");

            if (rides.Count < 2 || welcomePromo == null || first20Promo == null || fixed5Promo == null || weekend15Promo == null)
            {
                return;
            }

            var promoUsagesToSeed = new[]
            {
                new { PromoId = welcomePromo.PromoId, UserId = johnDoeUser.UserId, RideId = rides[0].RideId, UsedAt = baseDate.AddDays(-30) },
                new { PromoId = first20Promo.PromoId, UserId = johnDoeUser.UserId, RideId = rides[1].RideId, UsedAt = baseDate.AddDays(-25) },
                new { PromoId = fixed5Promo.PromoId, UserId = johnDoeUser.UserId, RideId = rides[0].RideId, UsedAt = baseDate.AddDays(-29) },
                new { PromoId = welcomePromo.PromoId, UserId = johnDoeUser.UserId, RideId = rides[1].RideId, UsedAt = baseDate.AddDays(-24) },
                new { PromoId = weekend15Promo.PromoId, UserId = johnDoeUser.UserId, RideId = rides[0].RideId, UsedAt = baseDate.AddDays(-20) }
            };

            foreach (var promoUsageData in promoUsagesToSeed)
            {
                var existing = await context.PromoUsages.FirstOrDefaultAsync(pu =>
                    pu.PromoId == promoUsageData.PromoId &&
                    pu.UserId == promoUsageData.UserId &&
                    pu.RideId == promoUsageData.RideId);
                if (existing != null)
                {
                    existing.UsedAt = promoUsageData.UsedAt;
                }
                else
                {
                    context.PromoUsages.Add(new PromoUsage
                    {
                        PromoId = promoUsageData.PromoId,
                        UserId = promoUsageData.UserId,
                        RideId = promoUsageData.RideId,
                        UsedAt = promoUsageData.UsedAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertDriverAvailabilitiesAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            // Get all drivers
            var drivers = await context.Drivers.ToListAsync();
            if (drivers.Count == 0) return;

            // Get all completed rides to determine which drivers are free (have completed their rides)
            var completedRides = await context.Rides
                .Where(r => r.Status == "completed")
                .ToListAsync();

            // Group completed rides by driver to find their latest completed ride
            var driverLatestCompletedRide = completedRides
                .GroupBy(r => r.DriverId)
                .ToDictionary(g => g.Key, g => g.OrderByDescending(r => r.CompletedAt).FirstOrDefault());

            // Mostar coordinates (center and surrounding areas)
            var mostarCoordinates = new[]
            {
                (Lat: 43.3438m, Lng: 17.8078m), // City Center
                (Lat: 43.3470m, Lng: 17.8060m), // Aleja Bosanskih Viteza
                (Lat: 43.3450m, Lng: 17.8100m), // Kralja Tvrtka
                (Lat: 43.3420m, Lng: 17.8080m), // Mehmeda Spahe
                (Lat: 43.3480m, Lng: 17.8120m), // Shopping Center
                (Lat: 43.3510m, Lng: 17.8010m), // Bus Station
                (Lat: 43.3520m, Lng: 17.8020m), // Train Station
                (Lat: 43.3400m, Lng: 17.8150m), // Hospital
                (Lat: 43.3488m, Lng: 17.8095m), // University
                (Lat: 43.3380m, Lng: 17.8050m), // Bulevar bb
                (Lat: 43.3440m, Lng: 17.8090m), // Bulevar 1
                (Lat: 43.3460m, Lng: 17.8110m), // Jadranska
                (Lat: 43.3410m, Lng: 17.8070m), // Carinska
                (Lat: 43.3370m, Lng: 17.8150m), // Stari Most
                (Lat: 43.3430m, Lng: 17.8080m), // Additional area
                (Lat: 43.3490m, Lng: 17.8100m)  // Additional area
            };

            foreach (var driver in drivers)
            {
                // Check if driver has completed rides
                var hasCompletedRides = driverLatestCompletedRide.ContainsKey(driver.DriverId);
                var latestCompletedRide = hasCompletedRides ? driverLatestCompletedRide[driver.DriverId] : null;

                // Drivers with completed rides are free (IsOnline = true)
                // Drivers without completed rides or only with requested rides are offline or have limited availability
                bool isOnline;
                DateTime? lastLocationUpdate;
                decimal? currentLat;
                decimal? currentLng;

                if (hasCompletedRides && latestCompletedRide != null && latestCompletedRide.CompletedAt.HasValue)
                {
                    // Driver has completed rides - they are free/online
                    isOnline = true;
                    
                    // Location updated recently (within last 30 minutes of latest completed ride)
                    var timeSinceLastRide = baseDate - latestCompletedRide.CompletedAt.Value;
                    if (timeSinceLastRide.TotalMinutes <= 30)
                    {
                        lastLocationUpdate = baseDate.AddMinutes(-(int)(timeSinceLastRide.TotalMinutes % 30));
                        // Use coordinates near their last dropoff location or random Mostar coordinates
                        var coordIndex = driver.DriverId % mostarCoordinates.Length;
                        currentLat = mostarCoordinates[coordIndex].Lat + (decimal)((driver.DriverId % 5) * 0.001m);
                        currentLng = mostarCoordinates[coordIndex].Lng + (decimal)((driver.DriverId % 3) * 0.001m);
                    }
                    else
                    {
                        // Last ride was longer ago - still online but location might be older
                        lastLocationUpdate = latestCompletedRide.CompletedAt.Value.AddMinutes(15);
                        var coordIndex = driver.DriverId % mostarCoordinates.Length;
                        currentLat = mostarCoordinates[coordIndex].Lat + (decimal)((driver.DriverId % 5) * 0.001m);
                        currentLng = mostarCoordinates[coordIndex].Lng + (decimal)((driver.DriverId % 3) * 0.001m);
                    }
                }
                else
                {
                    // Driver has no completed rides or only requested rides - they might be busy or offline
                    // Check if they have requested rides
                    var hasRequestedRides = await context.Rides
                        .AnyAsync(r => r.DriverId == driver.DriverId && r.Status == "requested");

                    if (hasRequestedRides)
                    {
                        // Has requested rides - might be busy
                        isOnline = false; // Not available for new rides
                        lastLocationUpdate = baseDate.AddHours(-1);
                        var coordIndex = driver.DriverId % mostarCoordinates.Length;
                        currentLat = mostarCoordinates[coordIndex].Lat;
                        currentLng = mostarCoordinates[coordIndex].Lng;
                    }
                    else
                    {
                        // No rides at all - completely offline
                        isOnline = false;
                        lastLocationUpdate = null;
                        currentLat = null;
                        currentLng = null;
                    }
                }

                var existing = await context.DriverAvailabilities.FirstOrDefaultAsync(da => da.DriverId == driver.DriverId);
                if (existing != null)
                {
                    existing.IsOnline = isOnline;
                    existing.CurrentLat = currentLat;
                    existing.CurrentLng = currentLng;
                    existing.LastLocationUpdate = lastLocationUpdate;
                    existing.UpdatedAt = baseDate;
                }
                else
                {
                    context.DriverAvailabilities.Add(new DriverAvailability
                    {
                        DriverId = driver.DriverId,
                        IsOnline = isOnline,
                        CurrentLat = currentLat,
                        CurrentLng = currentLng,
                        LastLocationUpdate = lastLocationUpdate,
                        UpdatedAt = baseDate
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertUserNotificationsAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "mobile");
            if (johnDoeUser == null) return;

            var notificationsToSeed = new[]
            {
                new { RecipientUserId = johnDoeUser.UserId, Title = "Welcome to TaxiMo!", Body = "Thank you for joining TaxiMo. Get 10% off your first ride with code WELCOME10", Type = "welcome", IsRead = true, SentAt = baseDate.AddDays(-200) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "Ride Completed", Body = "Your ride from Home to Work Office has been completed. Thank you for using TaxiMo!", Type = "ride_completed", IsRead = true, SentAt = baseDate.AddDays(-30).AddMinutes(25) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "Payment Received", Body = "Your payment of 8.50 EUR has been processed successfully.", Type = "payment", IsRead = false, SentAt = baseDate.AddDays(-25) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "New Promo Code Available", Body = "Use code WEEKEND15 for 15% off your weekend rides!", Type = "promotion", IsRead = false, SentAt = baseDate.AddDays(-10) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "Driver Assigned", Body = "Your driver Ahmed Hasanovic is on the way to your pickup location.", Type = "ride_update", IsRead = true, SentAt = baseDate.AddDays(-20).AddMinutes(3) }
            };

            foreach (var notificationData in notificationsToSeed)
            {
                var existing = await context.UserNotifications.FirstOrDefaultAsync(un =>
                    un.RecipientUserId == notificationData.RecipientUserId &&
                    un.Title == notificationData.Title);
                if (existing != null)
                {
                    existing.Body = notificationData.Body;
                    existing.Type = notificationData.Type;
                    existing.IsRead = notificationData.IsRead;
                }
                else
                {
                    context.UserNotifications.Add(new UserNotification
                    {
                        RecipientUserId = notificationData.RecipientUserId,
                        Title = notificationData.Title,
                        Body = notificationData.Body,
                        Type = notificationData.Type,
                        IsRead = notificationData.IsRead,
                        SentAt = notificationData.SentAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertDriverNotificationsAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var drivers = await context.Drivers.ToListAsync();
            if (drivers.Count < 3) return;

            var notificationsToSeed = new[]
            {
                new { RecipientDriverId = drivers[0].DriverId, Title = "New Ride Request", Body = "You have received a new ride request from John Doe.", Type = "ride_request", IsRead = true, SentAt = baseDate.AddDays(-30) },
                new { RecipientDriverId = drivers[0].DriverId, Title = "Payment Received", Body = "Payment of 8.50 EUR has been received for ride #1.", Type = "payment", IsRead = true, SentAt = baseDate.AddDays(-30).AddMinutes(25) },
                new { RecipientDriverId = drivers[1].DriverId, Title = "New Ride Request", Body = "You have received a new ride request from Sarajevo Airport.", Type = "ride_request", IsRead = true, SentAt = baseDate.AddDays(-25) },
                new { RecipientDriverId = drivers[1].DriverId, Title = "Rating Received", Body = "You received a 4.5 star rating from a passenger.", Type = "rating", IsRead = false, SentAt = baseDate.AddDays(-25).AddHours(2) },
                new { RecipientDriverId = drivers[2].DriverId, Title = "System Maintenance", Body = "Scheduled maintenance will occur tonight from 2 AM to 4 AM.", Type = "system", IsRead = false, SentAt = baseDate.AddDays(-5) }
            };

            foreach (var notificationData in notificationsToSeed)
            {
                var existing = await context.DriverNotifications.FirstOrDefaultAsync(dn =>
                    dn.RecipientDriverId == notificationData.RecipientDriverId &&
                    dn.Title == notificationData.Title);
                if (existing != null)
                {
                    existing.Body = notificationData.Body;
                    existing.Type = notificationData.Type;
                    existing.IsRead = notificationData.IsRead;
                }
                else
                {
                    context.DriverNotifications.Add(new DriverNotification
                    {
                        RecipientDriverId = notificationData.RecipientDriverId,
                        Title = notificationData.Title,
                        Body = notificationData.Body,
                        Type = notificationData.Type,
                        IsRead = notificationData.IsRead,
                        SentAt = notificationData.SentAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

    }
}
