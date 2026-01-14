using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class ReviewService : BaseCRUDService<Review>, IReviewService
    {
        public ReviewService(TaxiMoDbContext context) : base(context)
        {
        }

        protected override IQueryable<Review> AddInclude(IQueryable<Review> query)
        {
            return query
                .Include(r => r.Rider)
                .Include(r => r.Driver);
        }

        public override async Task<List<Review>> GetAllAsync()
        {
            var query = AddInclude(DbSet);
            return await query.ToListAsync();
        }

        public override async Task<Review?> GetByIdAsync(int id)
        {
            var query = AddInclude(DbSet);
            return await query.FirstOrDefaultAsync(r => r.ReviewId == id);
        }

        public async Task<List<Review>> GetAllAsync(string? search = null, decimal? minRating = null)
        {
            var query = AddInclude(DbSet).AsQueryable();

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

        public async Task<PagedResponse<Review>> GetAllPagedAsync(int page = 1, int limit = 7, string? search = null, decimal? minRating = null)
        {
            // Validate parameters
            if (page < 1) page = 1;
            if (limit < 1) limit = 7;

            var query = AddInclude(DbSet).AsQueryable();

            // Apply filters
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

            // Get total count BEFORE pagination
            var totalItems = await query.CountAsync();

            // Calculate pagination
            var skip = (page - 1) * limit;
            var totalPages = (int)Math.Ceiling(totalItems / (double)limit);

            // Apply pagination
            var data = await query
                .Skip(skip)
                .Take(limit)
                .ToListAsync();

            return new PagedResponse<Review>
            {
                Data = data,
                Pagination = new PaginationInfo
                {
                    CurrentPage = page,
                    TotalPages = totalPages,
                    TotalItems = totalItems,
                    Limit = limit
                }
            };
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

        public async Task<List<Review>> GetByRiderIdAsync(int riderId)
        {
            var query = AddInclude(DbSet);
            return await query.Where(r => r.RiderId == riderId).ToListAsync();
        }

        public async Task<List<Review>> GetByDriverIdAsync(int driverId)
        {
            // Use AddInclude to ensure Driver and Rider are included for photo mapping
            var query = AddInclude(DbSet)
                .Include(r => r.Ride)
                .Where(r => r.Ride.DriverId == driverId);
            
            return await query.ToListAsync();
        }

        public async Task<Review?> GetByRideIdAsync(int rideId)
        {
            var query = AddInclude(DbSet);
            return await query.FirstOrDefaultAsync(r => r.RideId == rideId);
        }

        public async Task<(decimal averageRating, int totalReviews)> GetDriverReviewStatsAsync(int driverId)
        {
            var reviews = await DbSet
                .Include(r => r.Ride)
                .Where(r => r.Ride.DriverId == driverId)
                .ToListAsync();

            if (reviews.Count == 0)
            {
                return (0, 0);
            }

            var averageRating = reviews.Average(r => r.Rating);
            var totalReviews = reviews.Count;

            return (averageRating, totalReviews);
        }

        public async Task<(int totalCompletedRides, decimal totalEarnings)> GetDriverRideStatsAsync(int driverId)
        {
            // Count completed rides for the driver
            var totalCompletedRides = await Context.Rides
                .Where(r => r.DriverId == driverId && r.Status.ToLower() == "completed")
                .CountAsync();

            // Calculate total earnings from payments for completed rides
            // Use Include to join with Ride and filter by DriverId and status
            var totalEarnings = await Context.Payments
                .Include(p => p.Ride)
                .Where(p =>
                    p.Ride.DriverId == driverId &&
                    p.Ride.Status.ToLower() == "completed" &&
                    p.Status.ToLower() == "completed")
                .SumAsync(p => (decimal?)p.Amount) ?? 0;

            return (totalCompletedRides, totalEarnings);
        }
    }
}

