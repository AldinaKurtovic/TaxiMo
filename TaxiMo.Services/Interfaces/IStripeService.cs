namespace TaxiMo.Services.Interfaces
{
    public interface IStripeService
    {
        /// <summary>
        /// Creates a Stripe PaymentIntent for a ride payment
        /// </summary>
        /// <param name="amount">Amount in cents (e.g., 500 for $5.00)</param>
        /// <param name="currency">Currency code (e.g., "usd", "eur")</param>
        /// <param name="rideId">The ride ID associated with this payment</param>
        /// <param name="paymentId">The payment ID in the database</param>
        /// <returns>Client secret for the PaymentIntent</returns>
        Task<string> CreatePaymentIntentAsync(long amount, string currency, int rideId, int paymentId);
    }
}

