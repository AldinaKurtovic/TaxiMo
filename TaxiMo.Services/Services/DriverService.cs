using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class DriverService : IDriverService
    {
        private readonly TaxiMoDbContext _context;

        public DriverService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<Driver>> GetAllAsync()
        {
            return await _context.Drivers.ToListAsync();
        }

        public async Task<Driver?> GetByIdAsync(int id)
        {
            return await _context.Drivers.FindAsync(id);
        }

        public async Task<Driver> CreateAsync(Driver driver)
        {
            driver.CreatedAt = DateTime.UtcNow;
            driver.UpdatedAt = DateTime.UtcNow;

            _context.Drivers.Add(driver);
            await _context.SaveChangesAsync();

            return driver;
        }

        public async Task<Driver> UpdateAsync(Driver driver)
        {
            var existingDriver = await _context.Drivers.FindAsync(driver.DriverId);
            if (existingDriver == null)
            {
                throw new KeyNotFoundException($"Driver with ID {driver.DriverId} not found.");
            }

            // Update properties
            existingDriver.FirstName = driver.FirstName;
            existingDriver.LastName = driver.LastName;
            existingDriver.Email = driver.Email;
            existingDriver.Phone = driver.Phone;
            existingDriver.PasswordHash = driver.PasswordHash;
            existingDriver.LicenseNumber = driver.LicenseNumber;
            existingDriver.LicenseExpiry = driver.LicenseExpiry;
            existingDriver.RatingAvg = driver.RatingAvg;
            existingDriver.TotalRides = driver.TotalRides;
            existingDriver.Status = driver.Status;
            existingDriver.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return existingDriver;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var driver = await _context.Drivers.FindAsync(id);
            if (driver == null)
            {
                return false;
            }

            _context.Drivers.Remove(driver);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

