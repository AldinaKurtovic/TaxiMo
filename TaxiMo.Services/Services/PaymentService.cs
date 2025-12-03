using Microsoft.EntityFrameworkCore;
using TaxiMo.Model.Exceptions;
using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly TaxiMoDbContext _context;

        public PaymentService(TaxiMoDbContext context)
        {
            _context = context;
        }

        public async Task<List<Payment>> GetAllAsync()
        {
            return await _context.Payments.ToListAsync();
        }

        public async Task<Payment?> GetByIdAsync(int id)
        {
            return await _context.Payments.FindAsync(id);
        }

        public async Task<Payment> CreateAsync(Payment payment)
        {
            _context.Payments.Add(payment);
            await _context.SaveChangesAsync();

            return payment;
        }

        public async Task<Payment> UpdateAsync(Payment payment)
        {
            var existingPayment = await _context.Payments.FindAsync(payment.PaymentId);
            if (existingPayment == null)
            {
                throw new UserException($"Payment with ID {payment.PaymentId} not found.");
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

            await _context.SaveChangesAsync();

            return existingPayment;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var payment = await _context.Payments.FindAsync(id);
            if (payment == null)
            {
                return false;
            }

            _context.Payments.Remove(payment);
            await _context.SaveChangesAsync();

            return true;
        }
    }
}

