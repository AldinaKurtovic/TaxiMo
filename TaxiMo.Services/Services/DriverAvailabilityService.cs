using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class DriverAvailabilityService : IDriverAvailabilityService
    {
        private readonly TaxiMoDbContext _context;

        public DriverAvailabilityService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<DriverAvailability>> GetAllAsync()
        {
            return await _context.DriverAvailabilities.ToListAsync();
        }

        public async Task<DriverAvailability?> GetByIdAsync(int id)
        {
            return await _context.DriverAvailabilities.FindAsync(id);
        }

        public async Task<DriverAvailability> CreateAsync(DriverAvailability driverAvailability)
        {
            driverAvailability.UpdatedAt = DateTime.UtcNow;

            _context.DriverAvailabilities.Add(driverAvailability);
            await _context.SaveChangesAsync();

            return driverAvailability;
        }

        public async Task<DriverAvailability> UpdateAsync(DriverAvailability driverAvailability)
        {
            var existingDriverAvailability = await _context.DriverAvailabilities.FindAsync(driverAvailability.AvailabilityId);
            if (existingDriverAvailability == null)
            {
                throw new UserException($"DriverAvailability with ID {driverAvailability.AvailabilityId} not found.");
            }

            // Update properties
            existingDriverAvailability.DriverId = driverAvailability.DriverId;
            existingDriverAvailability.IsOnline = driverAvailability.IsOnline;
            existingDriverAvailability.CurrentLat = driverAvailability.CurrentLat;
            existingDriverAvailability.CurrentLng = driverAvailability.CurrentLng;
            existingDriverAvailability.LastLocationUpdate = driverAvailability.LastLocationUpdate;
            existingDriverAvailability.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return existingDriverAvailability;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var driverAvailability = await _context.DriverAvailabilities.FindAsync(id);
            if (driverAvailability == null)
            {
                return false;
            }

            _context.DriverAvailabilities.Remove(driverAvailability);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

