using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class PromoCodeService : IPromoCodeService
    {
        private readonly TaxiMoDbContext _context;

        public PromoCodeService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<PromoCode>> GetAllAsync(string? search = null, bool? isActive = null)
        {
            var query = _context.PromoCodes.AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                query = query.Where(p =>
                    p.Code.Contains(search) ||
                    (p.Description != null && p.Description.Contains(search)) ||
                    p.Status.Contains(search));
            }

            if (isActive.HasValue)
            {
                if (isActive.Value)
                {
                    query = query.Where(p => p.Status.ToLower() == "active");
                }
                else
                {
                    query = query.Where(p => p.Status.ToLower() != "active");
                }
            }

            return await query.ToListAsync();
        }

        public async Task<PromoCode?> GetByIdAsync(int id)
        {
            return await _context.PromoCodes.FindAsync(id);
        }

        public async Task<PromoCode> CreateAsync(PromoCode promoCode)
        {
            promoCode.CreatedAt = DateTime.UtcNow;

            _context.PromoCodes.Add(promoCode);
            await _context.SaveChangesAsync();

            return promoCode;
        }

        public async Task<PromoCode> UpdateAsync(PromoCode promoCode)
        {
            var existingPromoCode = await _context.PromoCodes.FindAsync(promoCode.PromoId);
            if (existingPromoCode == null)
            {
                throw new KeyNotFoundException($"PromoCode with ID {promoCode.PromoId} not found.");
            }

            // Update properties
            existingPromoCode.Code = promoCode.Code;
            existingPromoCode.Description = promoCode.Description;
            existingPromoCode.DiscountType = promoCode.DiscountType;
            existingPromoCode.DiscountValue = promoCode.DiscountValue;
            existingPromoCode.UsageLimit = promoCode.UsageLimit;
            existingPromoCode.ValidFrom = promoCode.ValidFrom;
            existingPromoCode.ValidUntil = promoCode.ValidUntil;
            existingPromoCode.Status = promoCode.Status;

            await _context.SaveChangesAsync();

            return existingPromoCode;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var promoCode = await _context.PromoCodes.FindAsync(id);
            if (promoCode == null)
            {
                return false;
            }

            _context.PromoCodes.Remove(promoCode);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

