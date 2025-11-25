using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class ReviewService : IReviewService
    {
        private readonly TaxiMoDbContext _context;

        public ReviewService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<Review>> GetAllAsync(string? search = null, decimal? minRating = null)
        {
            var query = _context.Reviews
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

        public async Task<Review?> GetByIdAsync(int id)
        {
            return await _context.Reviews.FindAsync(id);
        }

        public async Task<Review> CreateAsync(Review review)
        {
            review.CreatedAt = DateTime.UtcNow;

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            return review;
        }

        public async Task<Review> UpdateAsync(Review review)
        {
            var existingReview = await _context.Reviews.FindAsync(review.ReviewId);
            if (existingReview == null)
            {
                throw new KeyNotFoundException($"Review with ID {review.ReviewId} not found.");
            }

            // Update properties
            existingReview.RideId = review.RideId;
            existingReview.RiderId = review.RiderId;
            existingReview.DriverId = review.DriverId;
            existingReview.Rating = review.Rating;
            existingReview.Comment = review.Comment;

            await _context.SaveChangesAsync();

            return existingReview;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var review = await _context.Reviews.FindAsync(id);
            if (review == null)
            {
                return false;
            }

            _context.Reviews.Remove(review);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

