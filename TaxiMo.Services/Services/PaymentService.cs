using TaxiMo.Services.Database;
using TaxiMo.Services.Database.Entities;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class PaymentService : BaseCRUDService<Payment>, IPaymentService
    {
        public PaymentService(TaxiMoDbContext context) : base(context)
        {
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

