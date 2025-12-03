using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class RoleService : IRoleService
    {
        private readonly TaxiMoDbContext _context;

        public RoleService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<Role>> GetAllAsync()
        {
            return await _context.Roles
                .Where(r => r.IsActive)
                .ToListAsync();
        }

        public async Task<Role?> GetByIdAsync(int id)
        {
            return await _context.Roles.FindAsync(id);
        }

        public async Task<Role?> GetByNameAsync(string name)
        {
            return await _context.Roles
                .FirstOrDefaultAsync(r => r.Name == name);
        }

        public async Task<Role> CreateAsync(Role role)
        {
            _context.Roles.Add(role);
            await _context.SaveChangesAsync();
            return role;
        }

        public async Task<Role> UpdateAsync(Role role)
        {
            var existingRole = await _context.Roles.FindAsync(role.RoleId);
            if (existingRole == null)
            {
                throw new UserException($"Role with ID {role.RoleId} not found.");
            }

            existingRole.Name = role.Name;
            existingRole.Description = role.Description;
            existingRole.IsActive = role.IsActive;

            await _context.SaveChangesAsync();
            return existingRole;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var role = await _context.Roles.FindAsync(id);
            if (role == null)
            {
                return false;
            }

            // Soft delete by setting IsActive to false
            role.IsActive = false;
            await _context.SaveChangesAsync();
            return true;
        }
    }
}

