using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.DTOs.Auth;

namespace TaxiMo.Services.Interfaces
{
    public interface IUserService
    {
        Task<List<User>> GetAllAsync(string? search = null, bool? isActive = null);
        Task<User?> GetByIdAsync(int id);
        Task<User> CreateAsync(User user);
        Task<UserResponse> CreateAsync(UserCreateDto dto);
        Task<User> UpdateAsync(User user);
        Task<UserResponse> UpdateAsync(UserUpdateDto dto);
        Task<bool> DeleteAsync(int id);
        Task<User?> GetByEmailAsync(string email);
        Task<User?> GetByUsernameAsync(string username);
        Task<UserResponse?> AuthenticateAsync(UserLoginRequest request);
        Task<UserResponse> RegisterAsync(UserRegisterDto dto);
        Task<UserResponse> GetUserResponseWithRolesAsync(int userId);
        
        /// <summary>
        /// Ensures a user has a specific role. Creates the role assignment if it doesn't exist.
        /// </summary>
        Task EnsureUserHasRoleAsync(int userId, string roleName);
        
        /// <summary>
        /// Finds all users without any roles and assigns them the default "User" role.
        /// </summary>
        Task<int> FixUsersWithoutRolesAsync();
    }
}

