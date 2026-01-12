using Microsoft.EntityFrameworkCore;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class PaymentService : BaseCRUDService<Payment>, IPaymentService
    {
        public PaymentService(TaxiMoDbContext context) : base(context)
        {
        }

        public async Task<PagedResponse<Payment>> GetAllPagedAsync(int page = 1, int limit = 7, string? search = null)
        {
            // Validate parameters
            if (page < 1) page = 1;
            if (limit < 1) limit = 7;

            var query = DbSet.AsQueryable();

            // Apply filters
            if (!string.IsNullOrWhiteSpace(search))
            {
                search = search.Trim();
                query = query.Where(p =>
                    p.PaymentId.ToString().Contains(search) ||
                    p.RideId.ToString().Contains(search) ||
                    p.UserId.ToString().Contains(search) ||
                    p.Amount.ToString().Contains(search) ||
                    p.Currency.Contains(search) ||
                    p.Method.Contains(search) ||
                    p.Status.Contains(search) ||
                    (p.TransactionRef != null && p.TransactionRef.Contains(search)));
            }

            // Get total count BEFORE pagination
            var totalItems = await query.CountAsync();

            // Calculate pagination
            var skip = (page - 1) * limit;
            var totalPages = (int)Math.Ceiling(totalItems / (double)limit);

            // Apply pagination
            var data = await query
                .OrderByDescending(p => p.PaymentId)
                .Skip(skip)
                .Take(limit)
                .ToListAsync();

            return new PagedResponse<Payment>
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

        public override async Task<Payment> UpdateAsync(Payment payment)
        {
            var existingPayment = await GetByIdAsync(payment.PaymentId);
            if (existingPayment == null)
            {
                throw new TaxiMo.Model.Exceptions.UserException($"Payment with ID {payment.PaymentId} not found.");
            }

            // Update properties
            existingPayment.RideId = payment.RideId;
            existingPayment.UserId = payment.UserId;
            existingPayment.Amount = payment.Amount;
            existingPayment.Currency = payment.Currency;
            existingPayment.Method = payment.Method;
            existingPayment.Status = payment.Status;
            existingPayment.TransactionRef = payment.TransactionRef;
            existingPayment.PaidAt = payment.PaidAt;

            await Context.SaveChangesAsync();
            return existingPayment;
        }
    }
}

