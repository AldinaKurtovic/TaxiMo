using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;
using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class StripeService : IStripeService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<StripeService> _logger;
        private string? _secretKey;

        public StripeService(IConfiguration configuration, ILogger<StripeService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        /// <summary>
        /// Gets Stripe secret key from environment variables or User Secrets
        /// </summary>
        private string GetSecretKey()
        {
            if (!string.IsNullOrWhiteSpace(_secretKey))
            {
                return _secretKey;
            }

            // Try environment variable first (production)
            var secretKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
            if (!string.IsNullOrWhiteSpace(secretKey))
            {
                _secretKey = secretKey;
                return _secretKey;
            }

            // Try User Secrets or configuration (local development)
            secretKey = _configuration["Stripe:SecretKey"];
            if (!string.IsNullOrWhiteSpace(secretKey))
            {
                _secretKey = secretKey;
                return _secretKey;
            }

            throw new InvalidOperationException(
                "Stripe SecretKey is not configured. " +
                "Set STRIPE_SECRET_KEY environment variable or configure it in User Secrets (Stripe:SecretKey).");
        }

        /// <summary>
        /// Creates a Stripe PaymentIntent for a ride payment
        /// </summary>
        public async Task<string> CreatePaymentIntentAsync(long amount, string currency, int rideId, int paymentId)
        {
            try
            {
                // Configure Stripe API key
                StripeConfiguration.ApiKey = GetSecretKey();

                // Create PaymentIntent options
                var options = new PaymentIntentCreateOptions
                {
                    Amount = amount,
                    Currency = currency.ToLower(),
                    AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                    {
                        Enabled = true,
                    },
                    Metadata = new Dictionary<string, string>
                    {
                        { "rideId", rideId.ToString() },
                        { "paymentId", paymentId.ToString() }
                    }
                };

                // Create PaymentIntent
                var service = new PaymentIntentService();
                var paymentIntent = await service.CreateAsync(options);

                _logger.LogInformation(
                    "PaymentIntent created - PaymentIntentId: {PaymentIntentId}, RideId: {RideId}, PaymentId: {PaymentId}, Amount: {Amount}, Currency: {Currency}",
                    paymentIntent.Id, rideId, paymentId, amount, currency);

                return paymentIntent.ClientSecret;
            }
            catch (StripeException ex)
            {
                _logger.LogError(ex, 
                    "Stripe error creating PaymentIntent - RideId: {RideId}, PaymentId: {PaymentId}, Amount: {Amount}, Currency: {Currency}",
                    rideId, paymentId, amount, currency);
                throw new InvalidOperationException($"Stripe error: {ex.Message}", ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, 
                    "Error creating PaymentIntent - RideId: {RideId}, PaymentId: {PaymentId}",
                    rideId, paymentId);
                throw;
            }
        }
    }
}

