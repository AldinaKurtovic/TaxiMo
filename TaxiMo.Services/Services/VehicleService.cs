using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class VehicleService : IVehicleService
    {
        private readonly TaxiMoDbContext _context;

        public VehicleService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<Vehicle>> GetAllAsync()
        {
            return await _context.Vehicles.ToListAsync();
        }

        public async Task<Vehicle?> GetByIdAsync(int id)
        {
            return await _context.Vehicles.FindAsync(id);
        }

        public async Task<Vehicle> CreateAsync(Vehicle vehicle)
        {
            vehicle.CreatedAt = DateTime.UtcNow;
            vehicle.UpdatedAt = DateTime.UtcNow;

            _context.Vehicles.Add(vehicle);
            await _context.SaveChangesAsync();

            return vehicle;
        }

        public async Task<Vehicle> UpdateAsync(Vehicle vehicle)
        {
            var existingVehicle = await _context.Vehicles.FindAsync(vehicle.VehicleId);
            if (existingVehicle == null)
            {
                throw new UserException($"Vehicle with ID {vehicle.VehicleId} not found.");
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

            await _context.SaveChangesAsync();

            return existingVehicle;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var vehicle = await _context.Vehicles.FindAsync(id);
            if (vehicle == null)
            {
                return false;
            }

            _context.Vehicles.Remove(vehicle);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

