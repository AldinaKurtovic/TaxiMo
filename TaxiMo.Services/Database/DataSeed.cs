using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
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

            // Drivers - UPSERT by Username
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

            // Rides - UPSERT by RiderId + DriverId + RequestedAt (combination to identify unique rides)
            await UpsertRidesAsync(context, baseDate);

            // Payments - UPSERT by RideId + TransactionRef (or RideId + Amount + Method if TransactionRef is null)
            await UpsertPaymentsAsync(context, baseDate);

            // Reviews - UPSERT by RideId + RiderId + DriverId
            await UpsertReviewsAsync(context, baseDate);

            // PromoUsages - UPSERT by PromoId + UserId + RideId
            await UpsertPromoUsagesAsync(context, baseDate);

            // DriverAvailabilities - UPSERT by DriverId (one per driver)
            await UpsertDriverAvailabilitiesAsync(context, baseDate);

            // UserNotifications - UPSERT by RecipientUserId + Title + SentAt
            await UpsertUserNotificationsAsync(context, baseDate);

            // DriverNotifications - UPSERT by RecipientDriverId + Title + SentAt
            await UpsertDriverNotificationsAsync(context, baseDate);

            // UserAuthTokens - UPSERT by UserId + DeviceId
            await UpsertUserAuthTokensAsync(context, baseDate);

            // DriverAuthTokens - UPSERT by DriverId + DeviceId
            await UpsertDriverAuthTokensAsync(context, baseDate);

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
                new { Username = "admin", FirstName = "Admin", LastName = "User", Email = "admin@taximo.ba", Phone = "38761123456", DateOfBirth = new DateTime(1985, 5, 15), Status = "active", CreatedAt = baseDate.AddDays(-365), UpdatedAt = baseDate.AddDays(-1) },
                new { Username = "desktop", FirstName = "Desktop", LastName = "Operator", Email = "desktop@taximo.ba", Phone = "38761234567", DateOfBirth = new DateTime(1990, 8, 20), Status = "active", CreatedAt = baseDate.AddDays(-300), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "mobile", FirstName = "Mobile", LastName = "Operator", Email = "mobile@taximo.ba", Phone = "38761345678", DateOfBirth = new DateTime(1992, 3, 10), Status = "active", CreatedAt = baseDate.AddDays(-280), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "john.doe", FirstName = "John", LastName = "Doe", Email = "john.doe@example.com", Phone = "38761456789", DateOfBirth = new DateTime(1995, 11, 25), Status = "active", CreatedAt = baseDate.AddDays(-200), UpdatedAt = baseDate.AddDays(-5) },
                new { Username = "support", FirstName = "Support", LastName = "Agent", Email = "support@taximo.ba", Phone = "38761567890", DateOfBirth = new DateTime(1988, 7, 5), Status = "active", CreatedAt = baseDate.AddDays(-150), UpdatedAt = baseDate.AddDays(-4) }
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
                new { Username = "driver.ahmed", FirstName = "Ahmed", LastName = "Hasanovic", Email = "ahmed.hasanovic@taximo.ba", Phone = "38762123456", LicenseNumber = "BIH-2020-001", LicenseExpiry = baseDate.AddYears(2), RatingAvg = 4.8m, TotalRides = 1250, Status = "active", CreatedAt = baseDate.AddDays(-400), UpdatedAt = baseDate.AddDays(-1) },
                new { Username = "driver.amina", FirstName = "Amina", LastName = "Kovacevic", Email = "amina.kovacevic@taximo.ba", Phone = "38762234567", LicenseNumber = "BIH-2019-045", LicenseExpiry = baseDate.AddYears(1).AddMonths(6), RatingAvg = 4.9m, TotalRides = 2100, Status = "active", CreatedAt = baseDate.AddDays(-450), UpdatedAt = baseDate.AddDays(-2) },
                new { Username = "driver.mirza", FirstName = "Mirza", LastName = "Begic", Email = "mirza.begic@taximo.ba", Phone = "38762345678", LicenseNumber = "BIH-2021-078", LicenseExpiry = baseDate.AddYears(3), RatingAvg = 4.6m, TotalRides = 850, Status = "active", CreatedAt = baseDate.AddDays(-350), UpdatedAt = baseDate.AddDays(-3) },
                new { Username = "driver.sara", FirstName = "Sara", LastName = "Dedic", Email = "sara.dedic@taximo.ba", Phone = "38762456789", LicenseNumber = "BIH-2018-112", LicenseExpiry = baseDate.AddMonths(8), RatingAvg = 4.7m, TotalRides = 1650, Status = "offline", CreatedAt = baseDate.AddDays(-500), UpdatedAt = baseDate.AddDays(-10) },
                new { Username = "driver.emir", FirstName = "Emir", LastName = "Jahic", Email = "emir.jahic@taximo.ba", Phone = "38762567890", LicenseNumber = "BIH-2022-023", LicenseExpiry = baseDate.AddYears(4), RatingAvg = 4.5m, TotalRides = 420, Status = "active", CreatedAt = baseDate.AddDays(-250), UpdatedAt = baseDate.AddDays(-5) }
            };

            foreach (var driverData in driversToSeed)
            {
                var existing = await context.Drivers.FirstOrDefaultAsync(d => d.Username == driverData.Username);
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
            // Get users and roles by their unique keys
            var adminUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "admin");
            var desktopUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "desktop");
            var mobileUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "mobile");
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            var supportUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "support");

            var adminRole = await context.Roles.FirstOrDefaultAsync(r => r.Name == "Admin");
            var userRole = await context.Roles.FirstOrDefaultAsync(r => r.Name == "User");

            if (adminUser == null || desktopUser == null || mobileUser == null || johnDoeUser == null || supportUser == null ||
                adminRole == null || userRole == null)
            {
                return; // Cannot proceed without required entities
            }

            var userRolesToSeed = new[]
            {
                new { UserId = adminUser.UserId, RoleId = adminRole.RoleId },
                new { UserId = desktopUser.UserId, RoleId = adminRole.RoleId },
                new { UserId = mobileUser.UserId, RoleId = userRole.RoleId },
                new { UserId = supportUser.UserId, RoleId = userRole.RoleId }
            };

            foreach (var userRoleData in userRolesToSeed)
            {
                var existing = await context.UserRoles.FirstOrDefaultAsync(ur => ur.UserId == userRoleData.UserId && ur.RoleId == userRoleData.RoleId);
                if (existing == null)
                {
                    context.UserRoles.Add(new UserRole
                    {
                        UserId = userRoleData.UserId,
                        RoleId = userRoleData.RoleId,
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

            if (driverRole == null || drivers.Count < 5)
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
            // Get drivers by username
            var driverAhmed = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.ahmed");
            var driverAmina = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.amina");
            var driverMirza = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.mirza");
            var driverSara = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.sara");
            var driverEmir = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.emir");

            if (driverAhmed == null || driverAmina == null || driverMirza == null || driverSara == null || driverEmir == null)
            {
                return; // Cannot proceed without required entities
            }

            var vehiclesToSeed = new[]
            {
                new { PlateNumber = "A-123-BH", DriverId = driverAhmed.DriverId, Make = "Skoda", Model = "Octavia", Year = 2020, Color = "White", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-400), UpdatedAt = baseDate.AddDays(-1) },
                new { PlateNumber = "S-456-SA", DriverId = driverAmina.DriverId, Make = "Volkswagen", Model = "Golf", Year = 2019, Color = "Black", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-450), UpdatedAt = baseDate.AddDays(-2) },
                new { PlateNumber = "T-789-TU", DriverId = driverMirza.DriverId, Make = "Mercedes-Benz", Model = "E-Class", Year = 2021, Color = "Silver", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-350), UpdatedAt = baseDate.AddDays(-3) },
                new { PlateNumber = "Z-321-ZE", DriverId = driverSara.DriverId, Make = "Toyota", Model = "Corolla", Year = 2018, Color = "Blue", VehicleType = "Sedan", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-500), UpdatedAt = baseDate.AddDays(-10) },
                new { PlateNumber = "B-654-BI", DriverId = driverEmir.DriverId, Make = "Ford", Model = "Focus", Year = 2022, Color = "Red", VehicleType = "Hatchback", Capacity = 4, Status = "active", CreatedAt = baseDate.AddDays(-250), UpdatedAt = baseDate.AddDays(-5) }
            };

            foreach (var vehicleData in vehiclesToSeed)
            {
                var existing = await context.Vehicles.FirstOrDefaultAsync(v => v.PlateNumber == vehicleData.PlateNumber);
                if (existing != null)
                {
                    existing.DriverId = vehicleData.DriverId;
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
                        DriverId = vehicleData.DriverId,
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
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            if (johnDoeUser == null) return;

            var locationsToSeed = new[]
            {
                new { Name = "Home", AddressLine = "Zmaja od Bosne 12", City = "Sarajevo", Lat = 43.8563m, Lng = 18.4131m, UserId = (int?)johnDoeUser.UserId, CreatedAt = baseDate.AddDays(-200), UpdatedAt = baseDate.AddDays(-5) },
                new { Name = "Sarajevo Airport", AddressLine = "Kurta Schorka 36", City = "Sarajevo", Lat = 43.8247m, Lng = 18.3314m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-180), UpdatedAt = baseDate.AddDays(-10) },
                new { Name = "Work Office", AddressLine = "Titova 15", City = "Sarajevo", Lat = 43.8517m, Lng = 18.3889m, UserId = (int?)johnDoeUser.UserId, CreatedAt = baseDate.AddDays(-190), UpdatedAt = baseDate.AddDays(-8) },
                new { Name = "City Center", AddressLine = "Ferhadija 1", City = "Sarajevo", Lat = 43.8586m, Lng = 18.4281m, UserId = (int?)null, CreatedAt = baseDate.AddDays(-170), UpdatedAt = baseDate.AddDays(-12) },
                new { Name = "Shopping Mall", AddressLine = "Zmaja od Bosne 88", City = "Sarajevo", Lat = 43.8625m, Lng = 18.4103m, UserId = (int?)johnDoeUser.UserId, CreatedAt = baseDate.AddDays(-160), UpdatedAt = baseDate.AddDays(-6) }
            };

            foreach (var locationData in locationsToSeed)
            {
                var existing = await context.Locations.FirstOrDefaultAsync(l =>
                    l.Name == locationData.Name &&
                    l.AddressLine == locationData.AddressLine &&
                    l.City == locationData.City &&
                    l.UserId == locationData.UserId);
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
                        UserId = locationData.UserId,
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
                new { Code = "FIXED5", Description = "5 BAM off your ride", DiscountType = "fixed", DiscountValue = 5.00m, UsageLimit = 200, ValidFrom = baseDate.AddDays(-60), ValidUntil = baseDate.AddDays(140), Status = "active", CreatedAt = baseDate.AddDays(-60) },
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
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            var driverAhmed = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.ahmed");
            var driverAmina = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.amina");
            var driverMirza = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.mirza");

            if (johnDoeUser == null || driverAhmed == null || driverAmina == null || driverMirza == null)
            {
                return;
            }

            var vehicle1 = await context.Vehicles.FirstOrDefaultAsync(v => v.PlateNumber == "A-123-BH");
            var vehicle2 = await context.Vehicles.FirstOrDefaultAsync(v => v.PlateNumber == "S-456-SA");
            var vehicle3 = await context.Vehicles.FirstOrDefaultAsync(v => v.PlateNumber == "T-789-TU");

            var location1 = await context.Locations.FirstOrDefaultAsync(l => l.Name == "Home" && l.AddressLine == "Zmaja od Bosne 12");
            var location2 = await context.Locations.FirstOrDefaultAsync(l => l.Name == "Sarajevo Airport" && l.AddressLine == "Kurta Schorka 36");
            var location3 = await context.Locations.FirstOrDefaultAsync(l => l.Name == "Work Office" && l.AddressLine == "Titova 15");
            var location4 = await context.Locations.FirstOrDefaultAsync(l => l.Name == "City Center" && l.AddressLine == "Ferhadija 1");
            var location5 = await context.Locations.FirstOrDefaultAsync(l => l.Name == "Shopping Mall" && l.AddressLine == "Zmaja od Bosne 88");

            if (vehicle1 == null || vehicle2 == null || vehicle3 == null ||
                location1 == null || location2 == null || location3 == null || location4 == null || location5 == null)
            {
                return;
            }

            var ridesToSeed = new[]
            {
                new { RiderId = johnDoeUser.UserId, DriverId = driverAhmed.DriverId, VehicleId = vehicle1.VehicleId, PickupLocationId = location1.LocationId, DropoffLocationId = location3.LocationId, RequestedAt = baseDate.AddDays(-30), StartedAt = (DateTime?)baseDate.AddDays(-30).AddMinutes(5), CompletedAt = (DateTime?)baseDate.AddDays(-30).AddMinutes(25), Status = "completed", FareEstimate = 8.50m, FareFinal = (decimal?)8.50m, DistanceKm = (decimal?)5.2m, DurationMin = (int?)20 },
                new { RiderId = johnDoeUser.UserId, DriverId = driverAmina.DriverId, VehicleId = vehicle2.VehicleId, PickupLocationId = location2.LocationId, DropoffLocationId = location4.LocationId, RequestedAt = baseDate.AddDays(-25), StartedAt = (DateTime?)baseDate.AddDays(-25).AddMinutes(10), CompletedAt = (DateTime?)baseDate.AddDays(-25).AddMinutes(45), Status = "completed", FareEstimate = 15.00m, FareFinal = (decimal?)12.00m, DistanceKm = (decimal?)12.5m, DurationMin = (int?)35 },
                new { RiderId = johnDoeUser.UserId, DriverId = driverMirza.DriverId, VehicleId = vehicle3.VehicleId, PickupLocationId = location4.LocationId, DropoffLocationId = location5.LocationId, RequestedAt = baseDate.AddDays(-20), StartedAt = (DateTime?)baseDate.AddDays(-20).AddMinutes(3), CompletedAt = (DateTime?)null, Status = "active", FareEstimate = 6.00m, FareFinal = (decimal?)null, DistanceKm = (decimal?)null, DurationMin = (int?)null },
                new { RiderId = johnDoeUser.UserId, DriverId = driverAhmed.DriverId, VehicleId = vehicle1.VehicleId, PickupLocationId = location3.LocationId, DropoffLocationId = location1.LocationId, RequestedAt = baseDate.AddDays(-15), StartedAt = (DateTime?)null, CompletedAt = (DateTime?)null, Status = "accepted", FareEstimate = 7.50m, FareFinal = (decimal?)null, DistanceKm = (decimal?)null, DurationMin = (int?)null },
                new { RiderId = johnDoeUser.UserId, DriverId = driverAmina.DriverId, VehicleId = vehicle2.VehicleId, PickupLocationId = location5.LocationId, DropoffLocationId = location2.LocationId, RequestedAt = baseDate.AddDays(-10), StartedAt = (DateTime?)null, CompletedAt = (DateTime?)null, Status = "requested", FareEstimate = 18.00m, FareFinal = (decimal?)null, DistanceKm = (decimal?)null, DurationMin = (int?)null }
            };

            foreach (var rideData in ridesToSeed)
            {
                var existing = await context.Rides.FirstOrDefaultAsync(r =>
                    r.RiderId == rideData.RiderId &&
                    r.DriverId == rideData.DriverId &&
                    r.RequestedAt == rideData.RequestedAt);
                if (existing != null)
                {
                    existing.VehicleId = rideData.VehicleId;
                    existing.PickupLocationId = rideData.PickupLocationId;
                    existing.DropoffLocationId = rideData.DropoffLocationId;
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
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            if (johnDoeUser == null) return;

            var rides = await context.Rides
                .Where(r => r.RiderId == johnDoeUser.UserId)
                .OrderBy(r => r.RequestedAt)
                .ToListAsync();

            if (rides.Count < 2) return;

            var paymentsToSeed = new[]
            {
                new { RideId = rides[0].RideId, UserId = johnDoeUser.UserId, Amount = 8.50m, Currency = "BAM", Method = "online", Status = "completed", TransactionRef = "TXN-2024-001", PaidAt = (DateTime?)baseDate.AddDays(-30).AddMinutes(25) },
                new { RideId = rides[1].RideId, UserId = johnDoeUser.UserId, Amount = 12.00m, Currency = "BAM", Method = "cash", Status = "completed", TransactionRef = (string?)null, PaidAt = (DateTime?)baseDate.AddDays(-25).AddMinutes(45) },
                new { RideId = rides[0].RideId, UserId = johnDoeUser.UserId, Amount = 8.50m, Currency = "BAM", Method = "online", Status = "pending", TransactionRef = "TXN-2024-002", PaidAt = (DateTime?)null },
                new { RideId = rides[1].RideId, UserId = johnDoeUser.UserId, Amount = 15.00m, Currency = "BAM", Method = "online", Status = "refunded", TransactionRef = "TXN-2024-003", PaidAt = (DateTime?)baseDate.AddDays(-25).AddMinutes(50) },
                new { RideId = rides[0].RideId, UserId = johnDoeUser.UserId, Amount = 8.50m, Currency = "BAM", Method = "cash", Status = "completed", TransactionRef = (string?)null, PaidAt = (DateTime?)baseDate.AddDays(-30).AddMinutes(26) }
            };

            foreach (var paymentData in paymentsToSeed)
            {
                Payment? existing = null;
                if (!string.IsNullOrEmpty(paymentData.TransactionRef))
                {
                    existing = await context.Payments.FirstOrDefaultAsync(p =>
                        p.RideId == paymentData.RideId &&
                        p.TransactionRef == paymentData.TransactionRef);
                }
                else
                {
                    existing = await context.Payments.FirstOrDefaultAsync(p =>
                        p.RideId == paymentData.RideId &&
                        p.Amount == paymentData.Amount &&
                        p.Method == paymentData.Method &&
                        p.TransactionRef == null);
                }

                if (existing != null)
                {
                    existing.UserId = paymentData.UserId;
                    existing.Amount = paymentData.Amount;
                    existing.Currency = paymentData.Currency;
                    existing.Method = paymentData.Method;
                    existing.Status = paymentData.Status;
                    existing.TransactionRef = paymentData.TransactionRef;
                    existing.PaidAt = paymentData.PaidAt;
                }
                else
                {
                    context.Payments.Add(new Payment
                    {
                        RideId = paymentData.RideId,
                        UserId = paymentData.UserId,
                        Amount = paymentData.Amount,
                        Currency = paymentData.Currency,
                        Method = paymentData.Method,
                        Status = paymentData.Status,
                        TransactionRef = paymentData.TransactionRef,
                        PaidAt = paymentData.PaidAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertReviewsAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            if (johnDoeUser == null) return;

            var rides = await context.Rides
                .Where(r => r.RiderId == johnDoeUser.UserId)
                .OrderBy(r => r.RequestedAt)
                .ToListAsync();

            if (rides.Count < 2) return;

            var driverAhmed = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.ahmed");
            var driverAmina = await context.Drivers.FirstOrDefaultAsync(d => d.Username == "driver.amina");
            if (driverAhmed == null || driverAmina == null) return;

            var reviewsToSeed = new[]
            {
                new { RideId = rides[0].RideId, RiderId = johnDoeUser.UserId, DriverId = driverAhmed.DriverId, Rating = 5.00m, Comment = "Excellent service, very professional driver!", CreatedAt = baseDate.AddDays(-30).AddHours(1) },
                new { RideId = rides[1].RideId, RiderId = johnDoeUser.UserId, DriverId = driverAmina.DriverId, Rating = 4.50m, Comment = "Good ride, clean car and friendly driver.", CreatedAt = baseDate.AddDays(-25).AddHours(2) },
                new { RideId = rides[0].RideId, RiderId = johnDoeUser.UserId, DriverId = driverAhmed.DriverId, Rating = 4.00m, Comment = "Punctual and safe driving.", CreatedAt = baseDate.AddDays(-29).AddHours(12) },
                new { RideId = rides[1].RideId, RiderId = johnDoeUser.UserId, DriverId = driverAmina.DriverId, Rating = 5.00m, Comment = "Best taxi service in Sarajevo!", CreatedAt = baseDate.AddDays(-24).AddHours(6) },
                new { RideId = rides[0].RideId, RiderId = johnDoeUser.UserId, DriverId = driverAhmed.DriverId, Rating = 4.75m, Comment = "Very satisfied with the service.", CreatedAt = baseDate.AddDays(-28).AddHours(18) }
            };

            foreach (var reviewData in reviewsToSeed)
            {
                var existing = await context.Reviews.FirstOrDefaultAsync(r =>
                    r.RideId == reviewData.RideId &&
                    r.RiderId == reviewData.RiderId &&
                    r.DriverId == reviewData.DriverId &&
                    r.CreatedAt == reviewData.CreatedAt);
                if (existing != null)
                {
                    existing.Rating = reviewData.Rating;
                    existing.Comment = reviewData.Comment;
                }
                else
                {
                    context.Reviews.Add(new Review
                    {
                        RideId = reviewData.RideId,
                        RiderId = reviewData.RiderId,
                        DriverId = reviewData.DriverId,
                        Rating = reviewData.Rating,
                        Comment = reviewData.Comment,
                        CreatedAt = reviewData.CreatedAt
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
                    pu.RideId == promoUsageData.RideId &&
                    pu.UsedAt == promoUsageData.UsedAt);
                if (existing == null)
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
            var drivers = await context.Drivers.ToListAsync();
            if (drivers.Count < 5) return;

            var availabilitiesToSeed = new[]
            {
                new { DriverId = drivers[0].DriverId, IsOnline = true, CurrentLat = (decimal?)43.8563m, CurrentLng = (decimal?)18.4131m, LastLocationUpdate = (DateTime?)baseDate.AddMinutes(-5), UpdatedAt = baseDate.AddMinutes(-5) },
                new { DriverId = drivers[1].DriverId, IsOnline = true, CurrentLat = (decimal?)43.8586m, CurrentLng = (decimal?)18.4281m, LastLocationUpdate = (DateTime?)baseDate.AddMinutes(-10), UpdatedAt = baseDate.AddMinutes(-10) },
                new { DriverId = drivers[2].DriverId, IsOnline = false, CurrentLat = (decimal?)43.8517m, CurrentLng = (decimal?)18.3889m, LastLocationUpdate = (DateTime?)baseDate.AddHours(-2), UpdatedAt = baseDate.AddHours(-2) },
                new { DriverId = drivers[3].DriverId, IsOnline = false, CurrentLat = (decimal?)null, CurrentLng = (decimal?)null, LastLocationUpdate = (DateTime?)null, UpdatedAt = baseDate.AddDays(-1) },
                new { DriverId = drivers[4].DriverId, IsOnline = true, CurrentLat = (decimal?)43.8625m, CurrentLng = (decimal?)18.4103m, LastLocationUpdate = (DateTime?)baseDate.AddMinutes(-15), UpdatedAt = baseDate.AddMinutes(-15) }
            };

            foreach (var availabilityData in availabilitiesToSeed)
            {
                var existing = await context.DriverAvailabilities.FirstOrDefaultAsync(da => da.DriverId == availabilityData.DriverId);
                if (existing != null)
                {
                    existing.IsOnline = availabilityData.IsOnline;
                    existing.CurrentLat = availabilityData.CurrentLat;
                    existing.CurrentLng = availabilityData.CurrentLng;
                    existing.LastLocationUpdate = availabilityData.LastLocationUpdate;
                    existing.UpdatedAt = availabilityData.UpdatedAt;
                }
                else
                {
                    context.DriverAvailabilities.Add(new DriverAvailability
                    {
                        DriverId = availabilityData.DriverId,
                        IsOnline = availabilityData.IsOnline,
                        CurrentLat = availabilityData.CurrentLat,
                        CurrentLng = availabilityData.CurrentLng,
                        LastLocationUpdate = availabilityData.LastLocationUpdate,
                        UpdatedAt = availabilityData.UpdatedAt
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertUserNotificationsAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            if (johnDoeUser == null) return;

            var notificationsToSeed = new[]
            {
                new { RecipientUserId = johnDoeUser.UserId, Title = "Welcome to TaxiMo!", Body = "Thank you for joining TaxiMo. Get 10% off your first ride with code WELCOME10", Type = "welcome", IsRead = true, SentAt = baseDate.AddDays(-200) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "Ride Completed", Body = "Your ride from Home to Work Office has been completed. Thank you for using TaxiMo!", Type = "ride_completed", IsRead = true, SentAt = baseDate.AddDays(-30).AddMinutes(25) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "Payment Received", Body = "Your payment of 8.50 BAM has been processed successfully.", Type = "payment", IsRead = false, SentAt = baseDate.AddDays(-25) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "New Promo Code Available", Body = "Use code WEEKEND15 for 15% off your weekend rides!", Type = "promotion", IsRead = false, SentAt = baseDate.AddDays(-10) },
                new { RecipientUserId = johnDoeUser.UserId, Title = "Driver Assigned", Body = "Your driver Ahmed Hasanovic is on the way to your pickup location.", Type = "ride_update", IsRead = true, SentAt = baseDate.AddDays(-20).AddMinutes(3) }
            };

            foreach (var notificationData in notificationsToSeed)
            {
                var existing = await context.UserNotifications.FirstOrDefaultAsync(un =>
                    un.RecipientUserId == notificationData.RecipientUserId &&
                    un.Title == notificationData.Title &&
                    un.SentAt == notificationData.SentAt);
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
                new { RecipientDriverId = drivers[0].DriverId, Title = "Payment Received", Body = "Payment of 8.50 BAM has been received for ride #1.", Type = "payment", IsRead = true, SentAt = baseDate.AddDays(-30).AddMinutes(25) },
                new { RecipientDriverId = drivers[1].DriverId, Title = "New Ride Request", Body = "You have received a new ride request from Sarajevo Airport.", Type = "ride_request", IsRead = true, SentAt = baseDate.AddDays(-25) },
                new { RecipientDriverId = drivers[1].DriverId, Title = "Rating Received", Body = "You received a 4.5 star rating from a passenger.", Type = "rating", IsRead = false, SentAt = baseDate.AddDays(-25).AddHours(2) },
                new { RecipientDriverId = drivers[2].DriverId, Title = "System Maintenance", Body = "Scheduled maintenance will occur tonight from 2 AM to 4 AM.", Type = "system", IsRead = false, SentAt = baseDate.AddDays(-5) }
            };

            foreach (var notificationData in notificationsToSeed)
            {
                var existing = await context.DriverNotifications.FirstOrDefaultAsync(dn =>
                    dn.RecipientDriverId == notificationData.RecipientDriverId &&
                    dn.Title == notificationData.Title &&
                    dn.SentAt == notificationData.SentAt);
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

        private static async Task UpsertUserAuthTokensAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var adminUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "admin");
            var desktopUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "desktop");
            var mobileUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "mobile");
            var johnDoeUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "john.doe");
            var supportUser = await context.Users.FirstOrDefaultAsync(u => u.Username == "support");

            if (adminUser == null || desktopUser == null || mobileUser == null || johnDoeUser == null || supportUser == null)
            {
                return;
            }

            var tokensToSeed = new[]
            {
                new { UserId = adminUser.UserId, DeviceId = "desktop-app", TokenHash = "fake_token_hash_admin_001", RefreshTokenHash = "fake_refresh_token_hash_admin_001", ExpiresAt = baseDate.AddDays(30), RevokedAt = (DateTime?)null, IpAddress = "192.168.1.100" },
                new { UserId = desktopUser.UserId, DeviceId = "desktop-app", TokenHash = "fake_token_hash_desktop_002", RefreshTokenHash = "fake_refresh_token_hash_desktop_002", ExpiresAt = baseDate.AddDays(30), RevokedAt = (DateTime?)null, IpAddress = "192.168.1.101" },
                new { UserId = mobileUser.UserId, DeviceId = "mobile-app", TokenHash = "fake_token_hash_mobile_003", RefreshTokenHash = "fake_refresh_token_hash_mobile_003", ExpiresAt = baseDate.AddDays(7), RevokedAt = (DateTime?)null, IpAddress = "192.168.1.102" },
                new { UserId = johnDoeUser.UserId, DeviceId = "mobile-app", TokenHash = "fake_token_hash_user_004", RefreshTokenHash = "fake_refresh_token_hash_user_004", ExpiresAt = baseDate.AddDays(7), RevokedAt = (DateTime?)null, IpAddress = "10.0.0.50" },
                new { UserId = supportUser.UserId, DeviceId = "desktop-app", TokenHash = "fake_token_hash_support_005", RefreshTokenHash = "fake_refresh_token_hash_support_005", ExpiresAt = baseDate.AddDays(30), RevokedAt = (DateTime?)baseDate.AddDays(-5), IpAddress = "192.168.1.103" }
            };

            foreach (var tokenData in tokensToSeed)
            {
                var existing = await context.UserAuthTokens.FirstOrDefaultAsync(t =>
                    t.UserId == tokenData.UserId &&
                    t.DeviceId == tokenData.DeviceId);
                if (existing != null)
                {
                    existing.TokenHash = tokenData.TokenHash;
                    existing.RefreshTokenHash = tokenData.RefreshTokenHash;
                    existing.ExpiresAt = tokenData.ExpiresAt;
                    existing.RevokedAt = tokenData.RevokedAt;
                    existing.IpAddress = tokenData.IpAddress;
                }
                else
                {
                    context.UserAuthTokens.Add(new UserAuthToken
                    {
                        UserId = tokenData.UserId,
                        DeviceId = tokenData.DeviceId,
                        TokenHash = tokenData.TokenHash,
                        RefreshTokenHash = tokenData.RefreshTokenHash,
                        ExpiresAt = tokenData.ExpiresAt,
                        RevokedAt = tokenData.RevokedAt,
                        IpAddress = tokenData.IpAddress
                    });
                }
            }
            await context.SaveChangesAsync();
        }

        private static async Task UpsertDriverAuthTokensAsync(TaxiMoDbContext context, DateTime baseDate)
        {
            var drivers = await context.Drivers.ToListAsync();
            if (drivers.Count < 5) return;

            var tokensToSeed = new[]
            {
                new { DriverId = drivers[0].DriverId, DeviceId = "mobile-app", TokenHash = "fake_token_hash_driver_ahmed_001", RefreshTokenHash = "fake_refresh_token_hash_driver_ahmed_001", ExpiresAt = baseDate.AddDays(7), RevokedAt = (DateTime?)null, IpAddress = "192.168.1.200" },
                new { DriverId = drivers[1].DriverId, DeviceId = "mobile-app", TokenHash = "fake_token_hash_driver_amina_002", RefreshTokenHash = "fake_refresh_token_hash_driver_amina_002", ExpiresAt = baseDate.AddDays(7), RevokedAt = (DateTime?)null, IpAddress = "192.168.1.201" },
                new { DriverId = drivers[2].DriverId, DeviceId = "mobile-app", TokenHash = "fake_token_hash_driver_mirza_003", RefreshTokenHash = "fake_refresh_token_hash_driver_mirza_003", ExpiresAt = baseDate.AddDays(7), RevokedAt = (DateTime?)null, IpAddress = "192.168.1.202" },
                new { DriverId = drivers[3].DriverId, DeviceId = "mobile-app", TokenHash = "fake_token_hash_driver_sara_004", RefreshTokenHash = "fake_refresh_token_hash_driver_sara_004", ExpiresAt = baseDate.AddDays(7), RevokedAt = (DateTime?)baseDate.AddDays(-2), IpAddress = "192.168.1.203" },
                new { DriverId = drivers[4].DriverId, DeviceId = "mobile-app", TokenHash = "fake_token_hash_driver_emir_005", RefreshTokenHash = "fake_refresh_token_hash_driver_emir_005", ExpiresAt = baseDate.AddDays(7), RevokedAt = (DateTime?)null, IpAddress = "192.168.1.204" }
            };

            foreach (var tokenData in tokensToSeed)
            {
                var existing = await context.DriverAuthTokens.FirstOrDefaultAsync(t =>
                    t.DriverId == tokenData.DriverId &&
                    t.DeviceId == tokenData.DeviceId);
                if (existing != null)
                {
                    existing.TokenHash = tokenData.TokenHash;
                    existing.RefreshTokenHash = tokenData.RefreshTokenHash;
                    existing.ExpiresAt = tokenData.ExpiresAt;
                    existing.RevokedAt = tokenData.RevokedAt;
                    existing.IpAddress = tokenData.IpAddress;
                }
                else
                {
                    context.DriverAuthTokens.Add(new DriverAuthToken
                    {
                        DriverId = tokenData.DriverId,
                        DeviceId = tokenData.DeviceId,
                        TokenHash = tokenData.TokenHash,
                        RefreshTokenHash = tokenData.RefreshTokenHash,
                        ExpiresAt = tokenData.ExpiresAt,
                        RevokedAt = tokenData.RevokedAt,
                        IpAddress = tokenData.IpAddress
                    });
                }
            }
            await context.SaveChangesAsync();
        }
    }
}
