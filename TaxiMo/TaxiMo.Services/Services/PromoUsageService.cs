using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class PromoUsageService : BaseCRUDService<PromoUsage>, IPromoUsageService
    {
        public PromoUsageService(TaxiMoDbContext context) : base(context)
        {
        }

        public override async Task<PromoUsage> UpdateAsync(PromoUsage promoUsage)
        {
            var existingPromoUsage = await GetByIdAsync(promoUsage.PromoUsageId);
            if (existingPromoUsage == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"PromoUsage with ID {promoUsage.PromoUsageId} not found.");
            }

            // Update properties
            existingPromoUsage.PromoId = promoUsage.PromoId;
            existingPromoUsage.UserId = promoUsage.UserId;
            existingPromoUsage.RideId = promoUsage.RideId;
            existingPromoUsage.UsedAt = promoUsage.UsedAt;

            await Context.SaveChangesAsync();
            return existingPromoUsage;
        }
    }
}

