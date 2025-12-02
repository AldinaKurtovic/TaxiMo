using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs.Auth;
using TaxiMo.Services.Helpers;
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

        public async Task<Driver> CreateAsync(Driver driver, int roleId = 3)
        {
            driver.CreatedAt = DateTime.UtcNow;
            driver.UpdatedAt = DateTime.UtcNow;

            // 1. Kreiramo vozaèa
            _context.Drivers.Add(driver);
            await _context.SaveChangesAsync();

            // 2. Dodajemo mu driver role
            var driverRole = new DriverRole
            {
                DriverId = driver.DriverId,
                RoleId = roleId, // UVIJEK DRIVER = 3
                DateAssigned = DateTime.UtcNow
            };

            _context.DriverRoles.Add(driverRole);
            await _context.SaveChangesAsync();

            // 3. Uèitaj role u objekt drivera prije vraæanja
            driver.DriverRoles = new List<DriverRole> { driverRole };

            return driver;
        }
        public async Task<Driver> CreateAsync(Driver driver)
        {
            // Poziva drugu metodu koja automatski koristi roleId = 3
            return await CreateAsync(driver, 3);
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

        public async Task<Driver?> GetByUsernameAsync(string username)
        {
            return await _context.Drivers
                .Include(d => d.DriverRoles)
                    .ThenInclude(dr => dr.Role)
                .FirstOrDefaultAsync(d => d.Username == username);
        }

        public async Task<DriverResponse?> AuthenticateAsync(DriverLoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
            {
                return null;
            }

            var driver = await GetByUsernameAsync(request.Username);
            if (driver == null)
            {
                return null;
            }

            // Verify password using PasswordHelper
            if (!PasswordHelper.VerifyPassword(request.Password, driver.PasswordHash, driver.PasswordSalt))
            {
                return null;
            }

            // Update LastLoginAt
            driver.LastLoginAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            // Map to DriverResponse with roles
            var response = new DriverResponse
            {
                DriverId = driver.DriverId,
                Username = driver.Username,
                FirstName = driver.FirstName,
                LastName = driver.LastName,
                Email = driver.Email,
                Phone = driver.Phone,
                Status = driver.Status,
                Roles = driver.DriverRoles
                    .Where(dr => dr.Role != null && dr.Role.IsActive)
                    .Select(dr => new RoleResponse
                    {
                        RoleId = dr.Role.RoleId,
                        Name = dr.Role.Name,
                        Description = dr.Role.Description
                    })
                    .ToList()
            };

            return response;
        }

        public async Task<bool> EmailExistsAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return false;

            return await _context.Drivers
                .AnyAsync(d => d.Email.ToLower() == email.ToLower());
        }

        public async Task<bool> EmailExistsAsync(string email, int excludeId)
        {
            if (string.IsNullOrWhiteSpace(email))
                return false;

            return await _context.Drivers
                .AnyAsync(d => d.Email.ToLower() == email.ToLower() && d.DriverId != excludeId);
        }
    }
}

