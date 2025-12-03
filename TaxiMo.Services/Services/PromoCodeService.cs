using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class PromoCodeService : BaseCRUDService<PromoCode>, IPromoCodeService
    {
        public PromoCodeService(TaxiMoDbContext context) : base(context)
        {
        }

        public async Task<List<PromoCode>> GetAllAsync(string? search = null, bool? isActive = null)
        {
            var query = DbSet.AsQueryable();

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

        public override async Task<PromoCode> CreateAsync(PromoCode promoCode)
        {
            promoCode.CreatedAt = DateTime.UtcNow;
            return await base.CreateAsync(promoCode);
        }

        public override async Task<PromoCode> UpdateAsync(PromoCode promoCode)
        {
            var existingPromoCode = await GetByIdAsync(promoCode.PromoId);
            if (existingPromoCode == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"PromoCode with ID {promoCode.PromoId} not found.");
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

            await Context.SaveChangesAsync();
            return existingPromoCode;
        }
    }
}

