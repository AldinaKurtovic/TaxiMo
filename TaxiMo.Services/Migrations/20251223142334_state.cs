using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TaxiMo.Services.Migrations
{
    /// <inheritdoc />
    public partial class state : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reviews_RideId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_PromoUsages_PromoId",
                table: "PromoUsages");

            migrationBuilder.AddColumn<string>(
                name: "RideState",
                table: "Rides",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_RideId_RiderId_DriverId",
                table: "Reviews",
                columns: new[] { "RideId", "RiderId", "DriverId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PromoUsages_PromoId_UserId_RideId",
                table: "PromoUsages",
                columns: new[] { "PromoId", "UserId", "RideId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Reviews_RideId_RiderId_DriverId",
                table: "Reviews");

            migrationBuilder.DropIndex(
                name: "IX_PromoUsages_PromoId_UserId_RideId",
                table: "PromoUsages");

            migrationBuilder.DropColumn(
                name: "RideState",
                table: "Rides");

            migrationBuilder.CreateIndex(
                name: "IX_Reviews_RideId",
                table: "Reviews",
                column: "RideId");

            migrationBuilder.CreateIndex(
                name: "IX_PromoUsages_PromoId",
                table: "PromoUsages",
                column: "PromoId");
        }
    }
}
