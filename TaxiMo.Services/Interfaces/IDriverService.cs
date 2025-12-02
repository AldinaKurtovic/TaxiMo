using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs.Auth;

namespace TaxiMo.Services.Interfaces
{
    public interface IDriverService
    {
        Task<List<Driver>> GetAllAsync(string? search = null, bool? isActive = null, string? licence = null);
        Task<Driver?> GetByIdAsync(int id);
        Task<Driver> CreateAsync(Driver driver);
        Task<Driver> CreateAsync(Driver driver,int roleId);
        Task<Driver> UpdateAsync(Driver driver);
        Task<bool> DeleteAsync(int id);
        Task<Driver?> GetByUsernameAsync(string username);
        Task<DriverResponse?> AuthenticateAsync(DriverLoginRequest request);
        Task<bool> EmailExistsAsync(string email);
        Task<bool> EmailExistsAsync(string email, int excludeId);
    }
}

