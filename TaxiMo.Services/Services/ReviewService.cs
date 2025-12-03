using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class ReviewService : BaseCRUDService<Review>, IReviewService
    {
        public ReviewService(TaxiMoDbContext context) : base(context)
        {
        }

        public async Task<List<Review>> GetAllAsync(string? search = null, decimal? minRating = null)
        {
            var query = DbSet
                .Include(r => r.Driver)
                .Include(r => r.Rider)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                query = query.Where(r =>
                    (r.Comment != null && r.Comment.Contains(search)) ||
                    (r.Driver != null && (r.Driver.FirstName.Contains(search) || r.Driver.LastName.Contains(search))) ||
                    (r.Rider != null && (r.Rider.FirstName.Contains(search) || r.Rider.LastName.Contains(search))));
            }

            if (minRating.HasValue)
            {
                query = query.Where(r => r.Rating >= minRating.Value);
            }

            return await query.ToListAsync();
        }

        public override async Task<Review> CreateAsync(Review review)
        {
            review.CreatedAt = DateTime.UtcNow;
            return await base.CreateAsync(review);
        }

        public override async Task<Review> UpdateAsync(Review review)
        {
            var existingReview = await GetByIdAsync(review.ReviewId);
            if (existingReview == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Review with ID {review.ReviewId} not found.");
            }

            // Update properties
            existingReview.RideId = review.RideId;
            existingReview.RiderId = review.RiderId;
            existingReview.DriverId = review.DriverId;
            existingReview.Rating = review.Rating;
            existingReview.Comment = review.Comment;

            await Context.SaveChangesAsync();
            return existingReview;
        }
    }
}

