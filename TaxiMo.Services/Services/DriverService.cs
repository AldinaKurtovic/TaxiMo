using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
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

        public async Task<PagedResponse<Driver>> GetAllPagedAsync(int page = 1, int limit = 7, string? search = null, bool? isActive = null, string? licence = null)
        {
            // Validate parameters
            if (page < 1) page = 1;
            if (limit < 1) limit = 7;

            var query = _context.Drivers.AsQueryable();

            // Apply filters
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

            // Get total count BEFORE pagination
            var totalItems = await query.CountAsync();

            // Calculate pagination
            var skip = (page - 1) * limit;
            var totalPages = (int)Math.Ceiling(totalItems / (double)limit);

            // Apply pagination
            var data = await query
                .Skip(skip)
                .Take(limit)
                .ToListAsync();

            return new PagedResponse<Driver>
            {
                Data = data,
                Pagination = new PaginationInfo
                {
                    CurrentPage = page,
                    TotalPages = totalPages,
                    TotalItems = totalItems,
                    Limit = limit
                }
            };
        }

        public async Task<Driver?> GetByIdAsync(int id)
        {
            return await _context.Drivers
                .Include(d => d.Vehicles)
                .FirstOrDefaultAsync(d => d.DriverId == id);
        }

        public async Task<Driver> CreateAsync(Driver driver, int roleId = 3)
        {
            driver.CreatedAt = DateTime.UtcNow;
            driver.UpdatedAt = DateTime.UtcNow;

            // 1. Kreiramo voza�a
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

            // 3. U�itaj role u objekt drivera prije vra�anja
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
                throw new UserException($"Driver with ID {driver.DriverId} not found.");
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
            existingDriver.PhotoUrl = driver.PhotoUrl;
            existingDriver.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return existingDriver;
        }

        /// <summary>
        /// Updates a driver with optional role reassignment and password change
        /// Updates only scalar fields - does NOT update navigation properties
        /// </summary>
        public async Task<Driver> UpdateAsync(DriverUpdateDto dto)
        {
            // Load driver WITHOUT navigation properties to avoid loading unnecessary data
            // We only update scalar fields, so we don't need navigation properties
            var driver = await _context.Drivers.FindAsync(dto.DriverId);

            if (driver == null)
                throw new UserException($"Driver with ID {dto.DriverId} not found.");

            // Update fields only if provided
            if (!string.IsNullOrWhiteSpace(dto.FirstName))
                driver.FirstName = dto.FirstName;

            if (!string.IsNullOrWhiteSpace(dto.LastName))
                driver.LastName = dto.LastName;

            if (!string.IsNullOrWhiteSpace(dto.Email))
            {
                if (driver.Email != dto.Email &&
                    await _context.Drivers.AnyAsync(x => x.Email == dto.Email && x.DriverId != dto.DriverId))
                    throw new UserException("Email already exists.");

                driver.Email = dto.Email;
            }

            if (!string.IsNullOrWhiteSpace(dto.Username))
            {
                if (driver.Username != dto.Username &&
                    await _context.Drivers.AnyAsync(x => x.Username == dto.Username && x.DriverId != dto.DriverId))
                    throw new UserException("Username already exists.");

                driver.Username = dto.Username;
            }

            if (dto.Phone != null)
                driver.Phone = dto.Phone;

            if (!string.IsNullOrWhiteSpace(dto.LicenseNumber))
                driver.LicenseNumber = dto.LicenseNumber;

            // LicenseExpiry is required in Driver entity, only update if provided
            if (dto.LicenseExpiry.HasValue)
                driver.LicenseExpiry = dto.LicenseExpiry.Value;
            // If not provided, keep existing value (required field must not be null)

            if (!string.IsNullOrWhiteSpace(dto.Status))
                driver.Status = dto.Status;

            if (dto.PhotoUrl != null)
                driver.PhotoUrl = dto.PhotoUrl;

            // Password update
            if (dto.ChangePassword && !string.IsNullOrWhiteSpace(dto.NewPassword))
            {
                PasswordHelper.CreatePasswordHash(dto.NewPassword, out string hash, out string salt);
                driver.PasswordHash = hash;
                driver.PasswordSalt = salt;
            }

            // ROLE UPDATE (similar to User)
            // Note: RoleId is required in DriverUpdateDto, but we only update if provided
            // For drivers, typically they only have one role (Driver = 3)
            // If RoleId needs to be changed, we would handle it here similar to User
            
            driver.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return driver;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                var driver = await _context.Drivers
                    .Include(d => d.DriverRoles)
                    .FirstOrDefaultAsync(d => d.DriverId == id);
                
                if (driver == null)
                    return false;

                // Check for related entities that block deletion (DeleteBehavior.Restrict)
                bool hasRides = await _context.Rides.AnyAsync(r => r.DriverId == id);

                // Block deletion if driver has rides (recommended approach)
                if (hasRides)
                {
                    throw new InvalidOperationException("Driver cannot be deleted because rides exist. Please handle or delete rides first.");
                }

                // Delete DriverRoles manually (Restrict relationship)
                // Note: The following will cascade delete automatically:
                // - Vehicles (Cascade)
                // - Reviews (Cascade)
                // - DriverAuthTokens (Cascade)
                // - DriverNotifications (Cascade)
                // - DriverAvailabilities (Cascade)
                if (driver.DriverRoles.Any())
                {
                    _context.DriverRoles.RemoveRange(driver.DriverRoles);
                    await _context.SaveChangesAsync();
                }

                // Now delete the driver
                _context.Drivers.Remove(driver);
                await _context.SaveChangesAsync();

                return true;
            }
            catch (InvalidOperationException)
            {
                throw; // Re-throw business logic exceptions
            }
            catch (Exception ex)
            {
                throw new UserException($"Error deleting driver: {ex.Message}");
            }
        }

        public async Task<Driver?> GetByUsernameAsync(string username)
        {
            return await _context.Drivers
                .Include(d => d.DriverRoles)
                    .ThenInclude(dr => dr.Role)
                .FirstOrDefaultAsync(d => d.Username == username);
        }

        /// <summary>
        /// Registers a new driver with password hashing and automatic "Driver" role assignment
        /// </summary>
        public async Task<DriverResponse> RegisterAsync(DriverRegisterDto dto)
        {
            // Validate email uniqueness
            if (await EmailExistsAsync(dto.Email))
                throw new UserException("Email already exists.");

            // Validate username uniqueness
            if (await _context.Drivers.AnyAsync(x => x.Username.ToLower() == dto.Username.ToLower()))
                throw new UserException("Username already exists.");

            // Hash password
            PasswordHelper.CreatePasswordHash(dto.Password, out string hash, out string salt);

            // Create driver
            var driver = new Driver
            {
                FirstName = dto.FirstName,
                LastName = dto.LastName,
                Username = dto.Username,
                Email = dto.Email,
                Phone = dto.Phone,
                PasswordHash = hash,
                PasswordSalt = salt,
                LicenseNumber = dto.LicenseNumber,
                LicenseExpiry = DateTime.UtcNow.AddYears(1), // Default, should be updated later
                Status = string.IsNullOrWhiteSpace(dto.Status) ? "active" : dto.Status, // Default to active
                TotalRides = 0,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Drivers.Add(driver);
            await _context.SaveChangesAsync();

            // Assign "Driver" role (typically RoleId = 3)
            var driverRole = await _context.Roles
                .FirstOrDefaultAsync(r => r.Name.ToLower() == "driver" && r.IsActive);

            if (driverRole == null)
                throw new UserException("Driver role not found.");

            _context.DriverRoles.Add(new DriverRole
            {
                DriverId = driver.DriverId,
                RoleId = driverRole.RoleId,
                DateAssigned = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            // Return DriverResponse with roles
            var response = new DriverResponse
            {
                DriverId = driver.DriverId,
                Username = driver.Username,
                FirstName = driver.FirstName,
                LastName = driver.LastName,
                Email = driver.Email,
                Phone = driver.Phone,
                Status = driver.Status,
                PhotoUrl = string.IsNullOrWhiteSpace(driver.PhotoUrl) ? "images/default-avatar.png" : driver.PhotoUrl,
                Roles = new List<RoleResponse>
                {
                    new RoleResponse
                    {
                        RoleId = driverRole.RoleId,
                        Name = driverRole.Name,
                        Description = driverRole.Description
                    }
                }
            };

            return response;
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
                PhotoUrl = string.IsNullOrWhiteSpace(driver.PhotoUrl) ? "images/default-avatar.png" : driver.PhotoUrl,
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

        public async Task<List<Driver>> GetFreeDriversAsync()
        {
            // Get drivers with status "active" who don't have any active rides
            // AND who have at least one active vehicle
            // Include DriverAvailabilities to get coordinates and Vehicles to get vehicleId
            var activeDrivers = await _context.Drivers
                .Include(d => d.DriverAvailabilities)
                .Include(d => d.Vehicles)
                .Where(d => 
                    d.Status.ToLower() == "active" &&
                    d.Vehicles.Any(v => v.Status.ToLower() == "active")
                )
                .ToListAsync();

            var activeRideDriverIds = await _context.Rides
                .Where(r => r.Status.ToLower() == "active" || 
                           r.Status.ToLower() == "requested" || 
                           r.Status.ToLower() == "accepted")
                .Select(r => r.DriverId)
                .Distinct()
                .ToListAsync();

            var freeDrivers = activeDrivers
                .Where(d => !activeRideDriverIds.Contains(d.DriverId))
                .ToList();

            return freeDrivers;
        }
    }
}

