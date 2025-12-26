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
    public class UserService : IUserService
    {
        private readonly TaxiMoDbContext _context;

        public UserService(TaxiMoDbContext context)
        {
            _context = context;
        }

        // =========================
        // ======== GET ALL ========
        // =========================
        public async Task<List<User>> GetAllAsync(string? search = null, bool? isActive = null)
        {
            var query = _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                query = query.Where(u =>
                    u.FirstName.Contains(search) ||
                    u.LastName.Contains(search) ||
                    u.Email.Contains(search) ||
                    u.Username.Contains(search));
            }

            if (isActive.HasValue)
            {
                query = query.Where(u =>
                    isActive.Value ? u.Status.ToLower() == "active"
                                   : u.Status.ToLower() != "active");
            }

            return await query.ToListAsync();
        }

        // =========================
        // ======== GET BY ID ======
        // =========================
        public async Task<User?> GetByIdAsync(int id)
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.UserId == id);
        }

        // =========================
        // ======== GET BY EMAIL ===
        // =========================
        public async Task<User?> GetByEmailAsync(string email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return null;

            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Email == email);
        }

        // =========================
        // ======== GET BY USERNAME =
        // =========================
        public async Task<User?> GetByUsernameAsync(string username)
        {
            if (string.IsNullOrWhiteSpace(username))
                return null;

            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == username);
        }

        // =========================
        // ======== CREATE =========
        // =========================
        public async Task<User> CreateAsync(User user)
        {
            user.CreatedAt = DateTime.UtcNow;
            user.UpdatedAt = DateTime.UtcNow;

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            // Automatically assign default "User" role if no roles are provided
            await EnsureUserHasRoleAsync(user.UserId, "User");

            return user;
        }

        /// <summary>
        /// Creates a new user with password hashing and role assignment
        /// </summary>
        public async Task<UserResponse> CreateAsync(UserCreateDto dto)
        {
            if (await _context.Users.AnyAsync(x => x.Email == dto.Email))
                throw new UserException("Email already exists.");

            if (await _context.Users.AnyAsync(x => x.Username == dto.Username))
                throw new UserException("Username already exists.");

            PasswordHelper.CreatePasswordHash(dto.Password, out string hash, out string salt);

            var user = new User
            {
                FirstName = dto.FirstName,
                LastName = dto.LastName,
                Username = dto.Username,
                Email = dto.Email,
                Phone = dto.Phone,
                DateOfBirth = dto.DateOfBirth,
                Status = dto.Status,
                PasswordHash = hash,
                PasswordSalt = salt,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var role = await _context.Roles
                .FirstOrDefaultAsync(r => r.RoleId == dto.RoleId && r.IsActive);

            if (role == null)
                throw new UserException("Invalid RoleId.");

            _context.UserRoles.Add(new UserRole
            {
                UserId = user.UserId,
                RoleId = dto.RoleId,
                DateAssigned = DateTime.UtcNow
            });

            await _context.SaveChangesAsync();

            return await GetUserResponseWithRolesAsync(user.UserId);
        }


        // =========================
        // ======== UPDATE =========
        // =========================
        public async Task<User> UpdateAsync(User user)
        {
            var db = await _context.Users.FindAsync(user.UserId);
            if (db == null)
                throw new UserException("User not found.");

            db.FirstName = user.FirstName;
            db.LastName = user.LastName;
            db.Email = user.Email;
            db.Phone = user.Phone;
            db.Status = user.Status;
            db.DateOfBirth = user.DateOfBirth;
            db.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return db;
        }

        /// <summary>
        /// Updates a user with optional role reassignment and password change
        /// </summary>
        public async Task<UserResponse> UpdateAsync(UserUpdateDto dto)
        {
            var user = await _context.Users
                .Include(u => u.UserRoles)
                .FirstOrDefaultAsync(u => u.UserId == dto.UserId);

            if (user == null)
                throw new UserException("User not found.");

            // Update fields
            if (!string.IsNullOrWhiteSpace(dto.FirstName))
                user.FirstName = dto.FirstName;

            if (!string.IsNullOrWhiteSpace(dto.LastName))
                user.LastName = dto.LastName;

            if (!string.IsNullOrWhiteSpace(dto.Email))
            {
                if (user.Email != dto.Email &&
                    await _context.Users.AnyAsync(x => x.Email == dto.Email && x.UserId != dto.UserId))
                    throw new UserException("Email already exists.");

                user.Email = dto.Email;
            }

            if (!string.IsNullOrWhiteSpace(dto.Username))
            {
                if (user.Username != dto.Username &&
                    await _context.Users.AnyAsync(x => x.Username == dto.Username && x.UserId != dto.UserId))
                    throw new UserException("Username already exists.");

                user.Username = dto.Username;
            }

            if (!string.IsNullOrWhiteSpace(dto.Status))
                user.Status = dto.Status;

            if (dto.Phone != null)
                user.Phone = dto.Phone;

            if (dto.DateOfBirth.HasValue)
                user.DateOfBirth = dto.DateOfBirth.Value;

            // Password update
            if (dto.ChangePassword && !string.IsNullOrWhiteSpace(dto.NewPassword))
            {
                // Old password is required when changing password
                if (string.IsNullOrWhiteSpace(dto.OldPassword))
                {
                    throw new UserException("Old password is required when changing password.");
                }
                
                // Verify old password
                var isOldPasswordValid = PasswordHelper.VerifyPassword(
                    dto.OldPassword, 
                    user.PasswordHash, 
                    user.PasswordSalt
                );
                
                if (!isOldPasswordValid)
                {
                    throw new UserException("Old password is incorrect.");
                }
                
                PasswordHelper.CreatePasswordHash(dto.NewPassword, out string hash, out string salt);
                user.PasswordHash = hash;
                user.PasswordSalt = salt;
            }

            // ROLE UPDATE (ONE ROLE)
            if (dto.RoleId.HasValue)
            {
                // Remove old roles
                var existingRoles = await _context.UserRoles
                    .Where(ur => ur.UserId == user.UserId)
                    .ToListAsync();

                _context.UserRoles.RemoveRange(existingRoles);
                await _context.SaveChangesAsync();

                // Validate new role
                var newRole = await _context.Roles
                    .FirstOrDefaultAsync(r => r.RoleId == dto.RoleId && r.IsActive);

                if (newRole == null)
                    throw new UserException("Invalid RoleId.");

                // Assign new role
                _context.UserRoles.Add(new UserRole
                {
                    UserId = user.UserId,
                    RoleId = newRole.RoleId,
                    DateAssigned = DateTime.UtcNow
                });
            }

            user.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return await GetUserResponseWithRolesAsync(user.UserId);
        }


        // ============================
        // ======== DELETE ===========
        // ============================
        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                var user = await _context.Users
                    .Include(u => u.UserRoles)
                    .Include(u => u.UserAuthTokens)
                    .Include(u => u.UserNotifications)
                    .FirstOrDefaultAsync(u => u.UserId == id);
                
                if (user == null)
                    return false;

                // Check for related entities that block deletion (DeleteBehavior.Restrict)
                bool hasRides = await _context.Rides.AnyAsync(r => r.RiderId == id);
                bool hasPayments = await _context.Payments.AnyAsync(p => p.UserId == id);
                bool hasReviews = await _context.Reviews.AnyAsync(r => r.RiderId == id); // Review uses RiderId, not UserId
                bool hasPromoUsages = await _context.PromoUsages.AnyAsync(pu => pu.UserId == id);
                bool hasLocations = await _context.Locations.AnyAsync(l => l.UserId == id);

                // OPTION A: Block deletion if user has rides (recommended)
                if (hasRides)
                {
                    throw new InvalidOperationException("User cannot be deleted because rides exist. Please handle or delete rides first.");
                }

                if (hasPayments)
                {
                    throw new InvalidOperationException("User cannot be deleted because payments exist. Please handle or delete payments first.");
                }

                if (hasReviews)
                {
                    throw new InvalidOperationException("User cannot be deleted because reviews exist. Please handle or delete reviews first.");
                }

                if (hasPromoUsages)
                {
                    throw new InvalidOperationException("User cannot be deleted because promo code usages exist. Please handle or delete promo usages first.");
                }

                if (hasLocations)
                {
                    throw new InvalidOperationException("User cannot be deleted because locations exist. Please handle or delete locations first.");
                }

                // Delete related entities that can be deleted (UserRoles, UserAuthTokens, UserNotifications)
                if (user.UserRoles.Any())
                {
                    _context.UserRoles.RemoveRange(user.UserRoles);
                }

                if (user.UserAuthTokens.Any())
                {
                    _context.UserAuthTokens.RemoveRange(user.UserAuthTokens);
                }

                if (user.UserNotifications.Any())
                {
                    _context.UserNotifications.RemoveRange(user.UserNotifications);
                }
                
                _context.Users.Remove(user);
                await _context.SaveChangesAsync();
                return true;
            }
            catch (InvalidOperationException)
            {
                // Re-throw business logic exceptions as-is
                throw;
            }
            catch (Exception ex)
            {
                // Log the real exception for debugging
                Console.WriteLine($"Error deleting user {id}: {ex}");
                Console.WriteLine($"Exception type: {ex.GetType().FullName}");
                Console.WriteLine($"Exception message: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                
                // Re-throw to preserve original exception
                throw;
            }
        }

        // ============================
        // ======== LOGIN =============
        // ============================
        public async Task<UserResponse?> AuthenticateAsync(UserLoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return null;

            var user = await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == request.Username);

            if (user == null)
                return null;

            // Verify password using PasswordHelper
            if (!PasswordHelper.VerifyPassword(request.Password, user.PasswordHash, user.PasswordSalt))
                return null;

            // Update LastLoginAt
            user.LastLoginAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            // Return UserResponse with roles
            return await GetUserResponseWithRolesAsync(user.UserId);
        }

        // =============================
        // ===== GET USER RESPONSE ====
        // =============================
        /// <summary>
        /// Loads a user with UserRoles and Role via Include/ThenInclude and maps to UserResponse
        /// </summary>
        public async Task<UserResponse> GetUserResponseWithRolesAsync(int userId)
        {
            var user = await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.UserId == userId);

            if (user == null)
                throw new UserException("User not found.");

            return new UserResponse
            {
                UserId = user.UserId,
                Username = user.Username,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                Phone = user.Phone,
                Status = user.Status,
                Roles = user.UserRoles
                    .Where(ur => ur.Role != null && ur.Role.IsActive)
                    .Select(ur => new RoleResponse
                    {
                        RoleId = ur.Role.RoleId,
                        Name = ur.Role.Name,
                        Description = ur.Role.Description
                    })
                    .ToList()
            };
        }

        // =============================
        // ===== ENSURE USER HAS ROLE ===
        // =============================
        /// <summary>
        /// Ensures a user has a specific role. Creates the role assignment if it doesn't exist.
        /// </summary>
        public async Task EnsureUserHasRoleAsync(int userId, string roleName)
        {
            // Check if user exists
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new UserException($"User with ID {userId} not found.");

            // Get role by name (case-insensitive)
            var role = await _context.Roles
                .FirstOrDefaultAsync(r => r.Name.ToLower() == roleName.ToLower() && r.IsActive);

            if (role == null)
                throw new UserException($"Role '{roleName}' not found or is inactive.");

            // Check if user already has this role
            var existingUserRole = await _context.UserRoles
                .FirstOrDefaultAsync(ur => ur.UserId == userId && ur.RoleId == role.RoleId);

            if (existingUserRole == null)
            {
                _context.UserRoles.Add(new UserRole
                {
                    UserId = userId,
                    RoleId = role.RoleId,
                    DateAssigned = DateTime.UtcNow
                });
                await _context.SaveChangesAsync();
            }
        }

        // =============================
        // ===== FIX USERS WITHOUT ROLES =
        // =============================
        /// <summary>
        /// Finds all users without any roles and assigns them the default "User" role.
        /// Returns the number of users fixed.
        /// </summary>
        public async Task<int> FixUsersWithoutRolesAsync()
        {
            // Get the "User" role
            var userRole = await _context.Roles
                .FirstOrDefaultAsync(r => r.Name.ToLower() == "user" && r.IsActive);

            if (userRole == null)
                throw new UserException("Default 'User' role not found or is inactive.");

            // Find all users that don't have any roles
            var usersWithoutRoles = await _context.Users
                .Where(u => !_context.UserRoles.Any(ur => ur.UserId == u.UserId))
                .ToListAsync();

            int fixedCount = 0;

            foreach (var user in usersWithoutRoles)
            {
                // Check again to prevent duplicates in case of concurrent execution
                var existingUserRole = await _context.UserRoles
                    .FirstOrDefaultAsync(ur => ur.UserId == user.UserId && ur.RoleId == userRole.RoleId);

                if (existingUserRole == null)
                {
                    _context.UserRoles.Add(new UserRole
                    {
                        UserId = user.UserId,
                        RoleId = userRole.RoleId,
                        DateAssigned = DateTime.UtcNow
                    });
                    fixedCount++;
                }
            }

            if (fixedCount > 0)
            {
                await _context.SaveChangesAsync();
            }

            return fixedCount;
        }
    }
}
