using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class VehicleService : BaseCRUDService<Vehicle>, IVehicleService
    {
        public VehicleService(TaxiMoDbContext context) : base(context)
        {
        }

        public override async Task<Vehicle> CreateAsync(Vehicle vehicle)
        {
            vehicle.CreatedAt = DateTime.UtcNow;
            vehicle.UpdatedAt = DateTime.UtcNow;
            return await base.CreateAsync(vehicle);
        }

        public override async Task<Vehicle> UpdateAsync(Vehicle vehicle)
        {
            var existingVehicle = await GetByIdAsync(vehicle.VehicleId);
            if (existingVehicle == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Vehicle with ID {vehicle.VehicleId} not found.");
            }

            // Update properties
            existingVehicle.DriverId = vehicle.DriverId;
            existingVehicle.Make = vehicle.Make;
            existingVehicle.Model = vehicle.Model;
            existingVehicle.Year = vehicle.Year;
            existingVehicle.PlateNumber = vehicle.PlateNumber;
            existingVehicle.Color = vehicle.Color;
            existingVehicle.VehicleType = vehicle.VehicleType;
            existingVehicle.Capacity = vehicle.Capacity;
            existingVehicle.Status = vehicle.Status;
            existingVehicle.UpdatedAt = DateTime.UtcNow;

            await Context.SaveChangesAsync();
            return existingVehicle;
        }
    }
}

