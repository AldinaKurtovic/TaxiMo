using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IUserService
    {
        Task<List<User>> GetAllAsync(string? search = null, bool? isActive = null);
        Task<User?> GetByIdAsync(int id);
        Task<User> CreateAsync(User user);
        Task<User> UpdateAsync(User user);
        Task<bool> DeleteAsync(int id);
        Task<User?> GetByEmailAsync(string email);
    }
}

