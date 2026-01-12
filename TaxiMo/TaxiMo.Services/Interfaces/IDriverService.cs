using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.DTOs.Auth;

namespace TaxiMo.Services.Interfaces
{
    public interface IDriverService
    {
        Task<List<Driver>> GetAllAsync(string? search = null, bool? isActive = null, string? licence = null);
        Task<PagedResponse<Driver>> GetAllPagedAsync(int page = 1, int limit = 7, string? search = null, bool? isActive = null, string? licence = null);
        Task<Driver?> GetByIdAsync(int id);
        Task<Driver> CreateAsync(Driver driver);
        Task<Driver> CreateAsync(Driver driver,int roleId);
        Task<Driver> UpdateAsync(Driver driver);
        Task<Driver> UpdateAsync(DriverUpdateDto dto);
        Task<bool> DeleteAsync(int id);
        Task<Driver?> GetByUsernameAsync(string username);
        Task<DriverResponse?> AuthenticateAsync(DriverLoginRequest request);
        Task<DriverResponse> RegisterAsync(DriverRegisterDto dto);
        Task<bool> EmailExistsAsync(string email);
        Task<bool> EmailExistsAsync(string email, int excludeId);
        Task<List<Driver>> GetFreeDriversAsync();
    }
}

