using TaxiMo.Services.Database.Entities;

namespace TaxiMo.Services.Interfaces
{
    public interface IDriverService
    {
        Task<List<Driver>> GetAllAsync(string? search = null, bool? isActive = null, string? licence = null);
        Task<Driver?> GetByIdAsync(int id);
        Task<Driver> CreateAsync(Driver driver);
        Task<Driver> UpdateAsync(Driver driver);
        Task<bool> DeleteAsync(int id);
    }
}

