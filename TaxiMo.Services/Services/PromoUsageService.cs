using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class PromoUsageService : IPromoUsageService
    {
        private readonly TaxiMoDbContext _context;

        public PromoUsageService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<PromoUsage>> GetAllAsync()
        {
            return await _context.PromoUsages.ToListAsync();
        }

        public async Task<PromoUsage?> GetByIdAsync(int id)
        {
            return await _context.PromoUsages.FindAsync(id);
        }

        public async Task<PromoUsage> CreateAsync(PromoUsage promoUsage)
        {
            _context.PromoUsages.Add(promoUsage);
            await _context.SaveChangesAsync();

            return promoUsage;
        }

        public async Task<PromoUsage> UpdateAsync(PromoUsage promoUsage)
        {
            var existingPromoUsage = await _context.PromoUsages.FindAsync(promoUsage.PromoUsageId);
            if (existingPromoUsage == null)
            {
                throw new KeyNotFoundException($"PromoUsage with ID {promoUsage.PromoUsageId} not found.");
            }

            // Update properties
            existingPromoUsage.PromoId = promoUsage.PromoId;
            existingPromoUsage.UserId = promoUsage.UserId;
            existingPromoUsage.RideId = promoUsage.RideId;
            existingPromoUsage.UsedAt = promoUsage.UsedAt;

            await _context.SaveChangesAsync();

            return existingPromoUsage;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var promoUsage = await _context.PromoUsages.FindAsync(id);
            if (promoUsage == null)
            {
                return false;
            }

            _context.PromoUsages.Remove(promoUsage);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

