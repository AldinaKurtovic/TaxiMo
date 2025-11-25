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

        public async Task<List<Driver>> GetAllAsync(string? search = null, bool? isActive = null, string? licence = null)
        {
            var query = _context.Drivers.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                query = query.Where(d =>
                    d.FirstName.Contains(search) ||
                    d.LastName.Contains(search) ||
                    d.Email.Contains(search) ||
                    d.Status.Contains(search) ||
                    d.LicenseNumber.Contains(search));
            }

            if (isActive.HasValue)
            {
                if (isActive.Value)
                {
                    query = query.Where(d => d.Status.ToLower() == "active");
                }
                else
                {
                    query = query.Where(d => d.Status.ToLower() != "active");
                }
            }

            if (!string.IsNullOrWhiteSpace(licence))
            {
                licence = licence.Trim();
                query = query.Where(d => d.LicenseNumber.Contains(licence));
            }

            return await query.ToListAsync();
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

