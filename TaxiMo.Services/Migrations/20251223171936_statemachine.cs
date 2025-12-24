using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TaxiMo.Services.Migrations
{
    /// <inheritdoc />
    public partial class statemachine : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "RideState",
                table: "Rides",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RideState",
                table: "Rides");
        }
    }
}
