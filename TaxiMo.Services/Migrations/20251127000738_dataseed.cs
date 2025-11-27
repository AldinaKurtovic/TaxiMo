using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace TaxiMo.Services.Migrations
{
    /// <inheritdoc />
    public partial class dataseed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Drivers",
                columns: new[] { "DriverId", "CreatedAt", "Email", "FirstName", "LastName", "LicenseExpiry", "LicenseNumber", "PasswordHash", "Phone", "RatingAvg", "Role", "Status", "TotalRides", "UpdatedAt", "Username" },
                values: new object[,]
                {
                    { 1, new DateTime(2024, 10, 23, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "ahmed.hasanovic@taximo.ba", "Ahmed", "Hasanovic", new DateTime(2027, 11, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "BIH-2020-001", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38762123456", 4.8m, "driver", "active", 1250, new DateTime(2025, 11, 26, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "driver.ahmed" },
                    { 2, new DateTime(2024, 9, 3, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "amina.kovacevic@taximo.ba", "Amina", "Kovacevic", new DateTime(2027, 5, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "BIH-2019-045", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38762234567", 4.9m, "driver", "active", 2100, new DateTime(2025, 11, 25, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "driver.amina" },
                    { 3, new DateTime(2024, 12, 12, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "mirza.begic@taximo.ba", "Mirza", "Begic", new DateTime(2028, 11, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "BIH-2021-078", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38762345678", 4.6m, "driver", "active", 850, new DateTime(2025, 11, 24, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "driver.mirza" },
                    { 4, new DateTime(2024, 7, 15, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "sara.dedic@taximo.ba", "Sara", "Dedic", new DateTime(2026, 7, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "BIH-2018-112", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38762456789", 4.7m, "driver", "offline", 1650, new DateTime(2025, 11, 17, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "driver.sara" },
                    { 5, new DateTime(2025, 3, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "emir.jahic@taximo.ba", "Emir", "Jahic", new DateTime(2029, 11, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "BIH-2022-023", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38762567890", 4.5m, "driver", "active", 420, new DateTime(2025, 11, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "driver.emir" }
                });

            migrationBuilder.InsertData(
                table: "Locations",
                columns: new[] { "LocationId", "AddressLine", "City", "CreatedAt", "Lat", "Lng", "Name", "UpdatedAt", "UserId" },
                values: new object[,]
                {
                    { 2, "Kurta Schorka 36", "Sarajevo", new DateTime(2025, 5, 31, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 43.8247m, 18.3314m, "Sarajevo Airport", new DateTime(2025, 11, 17, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), null },
                    { 4, "Ferhadija 1", "Sarajevo", new DateTime(2025, 6, 10, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 43.8586m, 18.4281m, "City Center", new DateTime(2025, 11, 15, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), null }
                });

            migrationBuilder.InsertData(
                table: "PromoCodes",
                columns: new[] { "PromoId", "Code", "CreatedAt", "Description", "DiscountType", "DiscountValue", "Status", "UsageLimit", "ValidFrom", "ValidUntil" },
                values: new object[,]
                {
                    { 1, "WELCOME10", new DateTime(2025, 8, 19, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Welcome discount for new users", "percentage", 10.00m, "active", 100, new DateTime(2025, 8, 19, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2026, 6, 15, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 2, "FIRST20", new DateTime(2025, 9, 8, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "20% off first ride", "percentage", 20.00m, "active", 50, new DateTime(2025, 9, 8, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2026, 3, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 3, "FIXED5", new DateTime(2025, 9, 28, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "5 BAM off your ride", "fixed", 5.00m, "active", 200, new DateTime(2025, 9, 28, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2026, 4, 16, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 4, "WEEKEND15", new DateTime(2025, 10, 18, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "15% off weekend rides", "percentage", 15.00m, "active", 75, new DateTime(2025, 10, 18, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2026, 1, 26, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 5, "EXPIRED", new DateTime(2025, 5, 11, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Expired promo code", "percentage", 10.00m, "expired", 100, new DateTime(2025, 5, 11, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2025, 10, 8, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919) }
                });

            migrationBuilder.InsertData(
                table: "Users",
                columns: new[] { "UserId", "CreatedAt", "DateOfBirth", "Email", "FirstName", "LastName", "PasswordHash", "Phone", "Role", "Status", "UpdatedAt", "Username" },
                values: new object[,]
                {
                    { 1, new DateTime(2024, 11, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(1985, 5, 15, 0, 0, 0, 0, DateTimeKind.Unspecified), "admin@taximo.ba", "Admin", "User", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38761123456", "admin", "active", new DateTime(2025, 11, 26, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "admin" },
                    { 2, new DateTime(2025, 1, 31, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(1990, 8, 20, 0, 0, 0, 0, DateTimeKind.Unspecified), "desktop@taximo.ba", "Desktop", "Operator", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38761234567", "desktop", "active", new DateTime(2025, 11, 25, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "desktop" },
                    { 3, new DateTime(2025, 2, 20, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(1992, 3, 10, 0, 0, 0, 0, DateTimeKind.Unspecified), "mobile@taximo.ba", "Mobile", "Operator", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38761345678", "mobile", "active", new DateTime(2025, 11, 24, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "mobile" },
                    { 4, new DateTime(2025, 5, 11, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(1995, 11, 25, 0, 0, 0, 0, DateTimeKind.Unspecified), "john.doe@example.com", "John", "Doe", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38761456789", "user", "active", new DateTime(2025, 11, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "john.doe" },
                    { 5, new DateTime(2025, 6, 30, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(1988, 7, 5, 0, 0, 0, 0, DateTimeKind.Unspecified), "support@taximo.ba", "Support", "Agent", "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=", "38761567890", "support", "active", new DateTime(2025, 11, 23, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "support" }
                });

            migrationBuilder.InsertData(
                table: "DriverAuthTokens",
                columns: new[] { "TokenId", "DeviceId", "DriverId", "ExpiresAt", "IpAddress", "RefreshTokenHash", "RevokedAt", "TokenHash" },
                values: new object[,]
                {
                    { 1, "mobile-app", 1, new DateTime(2025, 12, 4, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.200", "fake_refresh_token_hash_driver_ahmed_001", null, "fake_token_hash_driver_ahmed_001" },
                    { 2, "mobile-app", 2, new DateTime(2025, 12, 4, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.201", "fake_refresh_token_hash_driver_amina_002", null, "fake_token_hash_driver_amina_002" },
                    { 3, "mobile-app", 3, new DateTime(2025, 12, 4, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.202", "fake_refresh_token_hash_driver_mirza_003", null, "fake_token_hash_driver_mirza_003" },
                    { 4, "mobile-app", 4, new DateTime(2025, 12, 4, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.203", "fake_refresh_token_hash_driver_sara_004", new DateTime(2025, 11, 25, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "fake_token_hash_driver_sara_004" },
                    { 5, "mobile-app", 5, new DateTime(2025, 12, 4, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.204", "fake_refresh_token_hash_driver_emir_005", null, "fake_token_hash_driver_emir_005" }
                });

            migrationBuilder.InsertData(
                table: "DriverAvailabilities",
                columns: new[] { "AvailabilityId", "CurrentLat", "CurrentLng", "DriverId", "IsOnline", "LastLocationUpdate", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, 43.8563m, 18.4131m, 1, true, new DateTime(2025, 11, 27, 0, 2, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2025, 11, 27, 0, 2, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 2, 43.8586m, 18.4281m, 2, true, new DateTime(2025, 11, 26, 23, 57, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2025, 11, 26, 23, 57, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 3, 43.8517m, 18.3889m, 3, false, new DateTime(2025, 11, 26, 22, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2025, 11, 26, 22, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 4, null, null, 4, false, null, new DateTime(2025, 11, 26, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919) },
                    { 5, 43.8625m, 18.4103m, 5, true, new DateTime(2025, 11, 26, 23, 52, 38, 228, DateTimeKind.Utc).AddTicks(7919), new DateTime(2025, 11, 26, 23, 52, 38, 228, DateTimeKind.Utc).AddTicks(7919) }
                });

            migrationBuilder.InsertData(
                table: "DriverNotifications",
                columns: new[] { "NotificationId", "Body", "IsRead", "RecipientDriverId", "SentAt", "Title", "Type" },
                values: new object[,]
                {
                    { 1, "You have received a new ride request from John Doe.", true, 1, new DateTime(2025, 10, 28, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "New Ride Request", "ride_request" },
                    { 2, "Payment of 8.50 BAM has been received for ride #1.", true, 1, new DateTime(2025, 10, 28, 0, 32, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Payment Received", "payment" },
                    { 3, "You have received a new ride request from Sarajevo Airport.", true, 2, new DateTime(2025, 11, 2, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "New Ride Request", "ride_request" },
                    { 4, "You received a 4.5 star rating from a passenger.", false, 2, new DateTime(2025, 11, 2, 2, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Rating Received", "rating" },
                    { 5, "Scheduled maintenance will occur tonight from 2 AM to 4 AM.", false, 3, new DateTime(2025, 11, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "System Maintenance", "system" }
                });

            migrationBuilder.InsertData(
                table: "Locations",
                columns: new[] { "LocationId", "AddressLine", "City", "CreatedAt", "Lat", "Lng", "Name", "UpdatedAt", "UserId" },
                values: new object[,]
                {
                    { 1, "Zmaja od Bosne 12", "Sarajevo", new DateTime(2025, 5, 11, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 43.8563m, 18.4131m, "Home", new DateTime(2025, 11, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 },
                    { 3, "Titova 15", "Sarajevo", new DateTime(2025, 5, 21, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 43.8517m, 18.3889m, "Work Office", new DateTime(2025, 11, 19, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 },
                    { 5, "Zmaja od Bosne 88", "Sarajevo", new DateTime(2025, 6, 20, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 43.8625m, 18.4103m, "Shopping Mall", new DateTime(2025, 11, 21, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 }
                });

            migrationBuilder.InsertData(
                table: "UserAuthTokens",
                columns: new[] { "TokenId", "DeviceId", "ExpiresAt", "IpAddress", "RefreshTokenHash", "RevokedAt", "TokenHash", "UserId" },
                values: new object[,]
                {
                    { 1, "desktop-app", new DateTime(2025, 12, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.100", "fake_refresh_token_hash_admin_001", null, "fake_token_hash_admin_001", 1 },
                    { 2, "desktop-app", new DateTime(2025, 12, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.101", "fake_refresh_token_hash_desktop_002", null, "fake_token_hash_desktop_002", 2 },
                    { 3, "mobile-app", new DateTime(2025, 12, 4, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.102", "fake_refresh_token_hash_mobile_003", null, "fake_token_hash_mobile_003", 3 },
                    { 4, "mobile-app", new DateTime(2025, 12, 4, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "10.0.0.50", "fake_refresh_token_hash_user_004", null, "fake_token_hash_user_004", 4 },
                    { 5, "desktop-app", new DateTime(2025, 12, 27, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "192.168.1.103", "fake_refresh_token_hash_support_005", new DateTime(2025, 11, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "fake_token_hash_support_005", 5 }
                });

            migrationBuilder.InsertData(
                table: "UserNotifications",
                columns: new[] { "NotificationId", "Body", "IsRead", "RecipientUserId", "SentAt", "Title", "Type" },
                values: new object[,]
                {
                    { 1, "Thank you for joining TaxiMo. Get 10% off your first ride with code WELCOME10", true, 4, new DateTime(2025, 5, 11, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Welcome to TaxiMo!", "welcome" },
                    { 2, "Your ride from Home to Work Office has been completed. Thank you for using TaxiMo!", true, 4, new DateTime(2025, 10, 28, 0, 32, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Ride Completed", "ride_completed" },
                    { 3, "Your payment of 8.50 BAM has been processed successfully.", false, 4, new DateTime(2025, 11, 2, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Payment Received", "payment" },
                    { 4, "Use code WEEKEND15 for 15% off your weekend rides!", false, 4, new DateTime(2025, 11, 17, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "New Promo Code Available", "promotion" },
                    { 5, "Your driver Ahmed Hasanovic is on the way to your pickup location.", true, 4, new DateTime(2025, 11, 7, 0, 10, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Driver Assigned", "ride_update" }
                });

            migrationBuilder.InsertData(
                table: "Vehicles",
                columns: new[] { "VehicleId", "Capacity", "Color", "CreatedAt", "DriverId", "Make", "Model", "PlateNumber", "Status", "UpdatedAt", "VehicleType", "Year" },
                values: new object[,]
                {
                    { 1, 4, "White", new DateTime(2024, 10, 23, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 1, "Skoda", "Octavia", "A-123-BH", "active", new DateTime(2025, 11, 26, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Sedan", 2020 },
                    { 2, 4, "Black", new DateTime(2024, 9, 3, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 2, "Volkswagen", "Golf", "S-456-SA", "active", new DateTime(2025, 11, 25, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Hatchback", 2019 },
                    { 3, 4, "Silver", new DateTime(2024, 12, 12, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 3, "Mercedes-Benz", "E-Class", "T-789-TU", "active", new DateTime(2025, 11, 24, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Sedan", 2021 },
                    { 4, 4, "Blue", new DateTime(2024, 7, 15, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4, "Toyota", "Corolla", "Z-321-ZE", "active", new DateTime(2025, 11, 17, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Sedan", 2018 },
                    { 5, 4, "Red", new DateTime(2025, 3, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 5, "Ford", "Focus", "B-654-BI", "active", new DateTime(2025, 11, 22, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), "Hatchback", 2022 }
                });

            migrationBuilder.InsertData(
                table: "Rides",
                columns: new[] { "RideId", "CompletedAt", "DistanceKm", "DriverId", "DropoffLocationId", "DurationMin", "FareEstimate", "FareFinal", "PickupLocationId", "RequestedAt", "RiderId", "StartedAt", "Status", "VehicleId" },
                values: new object[,]
                {
                    { 1, new DateTime(2025, 10, 28, 0, 32, 38, 228, DateTimeKind.Utc).AddTicks(7919), 5.2m, 1, 3, 20, 8.50m, 8.50m, 1, new DateTime(2025, 10, 28, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4, new DateTime(2025, 10, 28, 0, 12, 38, 228, DateTimeKind.Utc).AddTicks(7919), "completed", 1 },
                    { 2, new DateTime(2025, 11, 2, 0, 52, 38, 228, DateTimeKind.Utc).AddTicks(7919), 12.5m, 2, 4, 35, 15.00m, 12.00m, 2, new DateTime(2025, 11, 2, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4, new DateTime(2025, 11, 2, 0, 17, 38, 228, DateTimeKind.Utc).AddTicks(7919), "completed", 2 },
                    { 3, null, null, 3, 5, null, 6.00m, null, 4, new DateTime(2025, 11, 7, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4, new DateTime(2025, 11, 7, 0, 10, 38, 228, DateTimeKind.Utc).AddTicks(7919), "active", 3 },
                    { 4, null, null, 1, 1, null, 7.50m, null, 3, new DateTime(2025, 11, 12, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4, null, "accepted", 1 },
                    { 5, null, null, 2, 2, null, 18.00m, null, 5, new DateTime(2025, 11, 17, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4, null, "requested", 2 }
                });

            migrationBuilder.InsertData(
                table: "Payments",
                columns: new[] { "PaymentId", "Amount", "Currency", "Method", "PaidAt", "RideId", "Status", "TransactionRef", "UserId" },
                values: new object[,]
                {
                    { 1, 8.50m, "BAM", "online", new DateTime(2025, 10, 28, 0, 32, 38, 228, DateTimeKind.Utc).AddTicks(7919), 1, "completed", "TXN-2024-001", 4 },
                    { 2, 12.00m, "BAM", "cash", new DateTime(2025, 11, 2, 0, 52, 38, 228, DateTimeKind.Utc).AddTicks(7919), 2, "completed", null, 4 },
                    { 3, 8.50m, "BAM", "online", null, 1, "pending", "TXN-2024-002", 4 },
                    { 4, 15.00m, "BAM", "online", new DateTime(2025, 11, 2, 0, 57, 38, 228, DateTimeKind.Utc).AddTicks(7919), 2, "refunded", "TXN-2024-003", 4 },
                    { 5, 8.50m, "BAM", "cash", new DateTime(2025, 10, 28, 0, 33, 38, 228, DateTimeKind.Utc).AddTicks(7919), 1, "completed", null, 4 }
                });

            migrationBuilder.InsertData(
                table: "PromoUsages",
                columns: new[] { "PromoUsageId", "PromoId", "RideId", "UsedAt", "UserId" },
                values: new object[,]
                {
                    { 1, 1, 1, new DateTime(2025, 10, 28, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 },
                    { 2, 2, 2, new DateTime(2025, 11, 2, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 },
                    { 3, 3, 1, new DateTime(2025, 10, 29, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 },
                    { 4, 1, 2, new DateTime(2025, 11, 3, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 },
                    { 5, 4, 1, new DateTime(2025, 11, 7, 0, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 4 }
                });

            migrationBuilder.InsertData(
                table: "Reviews",
                columns: new[] { "ReviewId", "Comment", "CreatedAt", "DriverId", "Rating", "RideId", "RiderId" },
                values: new object[,]
                {
                    { 1, "Excellent service, very professional driver!", new DateTime(2025, 10, 28, 1, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 1, 5.00m, 1, 4 },
                    { 2, "Good ride, clean car and friendly driver.", new DateTime(2025, 11, 2, 2, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 2, 4.50m, 2, 4 },
                    { 3, "Punctual and safe driving.", new DateTime(2025, 10, 29, 12, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 1, 4.00m, 1, 4 },
                    { 4, "Best taxi service in Sarajevo!", new DateTime(2025, 11, 3, 6, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 2, 5.00m, 2, 4 },
                    { 5, "Very satisfied with the service.", new DateTime(2025, 10, 30, 18, 7, 38, 228, DateTimeKind.Utc).AddTicks(7919), 1, 4.75m, 1, 4 }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "DriverAuthTokens",
                keyColumn: "TokenId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "DriverAuthTokens",
                keyColumn: "TokenId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "DriverAuthTokens",
                keyColumn: "TokenId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "DriverAuthTokens",
                keyColumn: "TokenId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "DriverAuthTokens",
                keyColumn: "TokenId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "DriverAvailabilities",
                keyColumn: "AvailabilityId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "DriverAvailabilities",
                keyColumn: "AvailabilityId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "DriverAvailabilities",
                keyColumn: "AvailabilityId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "DriverAvailabilities",
                keyColumn: "AvailabilityId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "DriverAvailabilities",
                keyColumn: "AvailabilityId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "DriverNotifications",
                keyColumn: "NotificationId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "DriverNotifications",
                keyColumn: "NotificationId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "DriverNotifications",
                keyColumn: "NotificationId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "DriverNotifications",
                keyColumn: "NotificationId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "DriverNotifications",
                keyColumn: "NotificationId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "PaymentId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "PaymentId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "PaymentId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "PaymentId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Payments",
                keyColumn: "PaymentId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "PromoCodes",
                keyColumn: "PromoId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "PromoUsages",
                keyColumn: "PromoUsageId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "PromoUsages",
                keyColumn: "PromoUsageId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "PromoUsages",
                keyColumn: "PromoUsageId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "PromoUsages",
                keyColumn: "PromoUsageId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "PromoUsages",
                keyColumn: "PromoUsageId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "ReviewId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "ReviewId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "ReviewId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "ReviewId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Reviews",
                keyColumn: "ReviewId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Rides",
                keyColumn: "RideId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Rides",
                keyColumn: "RideId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Rides",
                keyColumn: "RideId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "UserAuthTokens",
                keyColumn: "TokenId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "UserAuthTokens",
                keyColumn: "TokenId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "UserAuthTokens",
                keyColumn: "TokenId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "UserAuthTokens",
                keyColumn: "TokenId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "UserAuthTokens",
                keyColumn: "TokenId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "UserNotifications",
                keyColumn: "NotificationId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "UserNotifications",
                keyColumn: "NotificationId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "UserNotifications",
                keyColumn: "NotificationId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "UserNotifications",
                keyColumn: "NotificationId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "UserNotifications",
                keyColumn: "NotificationId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Vehicles",
                keyColumn: "VehicleId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Vehicles",
                keyColumn: "VehicleId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Drivers",
                keyColumn: "DriverId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Drivers",
                keyColumn: "DriverId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Locations",
                keyColumn: "LocationId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "PromoCodes",
                keyColumn: "PromoId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "PromoCodes",
                keyColumn: "PromoId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "PromoCodes",
                keyColumn: "PromoId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "PromoCodes",
                keyColumn: "PromoId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Rides",
                keyColumn: "RideId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Rides",
                keyColumn: "RideId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "UserId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "UserId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "UserId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "UserId",
                keyValue: 5);

            migrationBuilder.DeleteData(
                table: "Vehicles",
                keyColumn: "VehicleId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Drivers",
                keyColumn: "DriverId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Locations",
                keyColumn: "LocationId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Locations",
                keyColumn: "LocationId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Locations",
                keyColumn: "LocationId",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Locations",
                keyColumn: "LocationId",
                keyValue: 4);

            migrationBuilder.DeleteData(
                table: "Vehicles",
                keyColumn: "VehicleId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Vehicles",
                keyColumn: "VehicleId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Drivers",
                keyColumn: "DriverId",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Drivers",
                keyColumn: "DriverId",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Users",
                keyColumn: "UserId",
                keyValue: 4);
        }
    }
}
