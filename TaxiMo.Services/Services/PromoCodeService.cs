using System.Linq;
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

        public async Task<List<PromoCode>> GetAllAsync(string? search = null, bool? isActive = null, string? sortBy = null, string? sortOrder = null)
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

            // Apply sorting
            if (!string.IsNullOrWhiteSpace(sortBy))
            {
                var ascending = string.IsNullOrWhiteSpace(sortOrder) || sortOrder.ToLower() == "asc";
                
                switch (sortBy.ToLower())
                {
                    case "code":
                        query = ascending 
                            ? query.OrderBy(p => p.Code)
                            : query.OrderByDescending(p => p.Code);
                        break;
                    case "discount":
                    case "discountvalue":
                        query = ascending
                            ? query.OrderBy(p => p.DiscountValue)
                            : query.OrderByDescending(p => p.DiscountValue);
                        break;
                    default:
                        // Default sort by PromoId if invalid sortBy
                        query = query.OrderBy(p => p.PromoId);
                        break;
                }
            }
            else
            {
                // Default sort by PromoId
                query = query.OrderBy(p => p.PromoId);
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

