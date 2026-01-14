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
        /// Gets Stripe secret key from environment variables or configuration
        /// Priority: 1) Stripe__SecretKey env var (Docker format), 2) STRIPE_SECRET_KEY env var, 3) Configuration (appsettings.json)
        /// </summary>
        private string GetSecretKey()
        {
            if (!string.IsNullOrWhiteSpace(_secretKey))
            {
                return _secretKey;
            }

            // Try Stripe__SecretKey environment variable first (Docker Compose format - ASP.NET Core automatically converts __ to :)
            var secretKey = Environment.GetEnvironmentVariable("Stripe__SecretKey");
            if (!string.IsNullOrWhiteSpace(secretKey) && !secretKey.Contains("your_stripe_secret_key"))
            {
                _secretKey = secretKey;
                _logger.LogInformation("Stripe SecretKey loaded from Stripe__SecretKey environment variable");
                return _secretKey;
            }

            // Try STRIPE_SECRET_KEY environment variable (alternative format)
            secretKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY");
            if (!string.IsNullOrWhiteSpace(secretKey) && !secretKey.Contains("your_stripe_secret_key"))
            {
                _secretKey = secretKey;
                _logger.LogInformation("Stripe SecretKey loaded from STRIPE_SECRET_KEY environment variable");
                return _secretKey;
            }

            // Try configuration (appsettings.json or ASP.NET Core configuration which reads from Stripe__SecretKey env var)
            secretKey = _configuration["Stripe:SecretKey"];
            if (!string.IsNullOrWhiteSpace(secretKey) && !secretKey.Contains("your_stripe_secret_key"))
            {
                _secretKey = secretKey;
                _logger.LogInformation("Stripe SecretKey loaded from configuration (appsettings.json or env var via ASP.NET Core)");
                return _secretKey;
            }

            _logger.LogError("Stripe SecretKey is not configured or contains placeholder value. " +
                "Current value: {SecretKeyValue}. " +
                "Set Stripe__SecretKey or STRIPE_SECRET_KEY environment variable, or configure it in appsettings.json (Stripe:SecretKey).",
                secretKey ?? "null");
            
            throw new InvalidOperationException(
                "Stripe SecretKey is not configured or contains placeholder value. " +
                "Please set a valid Stripe secret key in appsettings.json (Stripe:SecretKey) or as Stripe__SecretKey/STRIPE_SECRET_KEY environment variable. " +
                "Get your key from https://dashboard.stripe.com/apikeys");
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

        /// <summary>
        /// Confirms a PaymentIntent by retrieving it from Stripe and verifying its status
        /// </summary>
        public async Task<bool> ConfirmPaymentIntentAsync(string paymentIntentId)
        {
            try
            {
                // Configure Stripe API key
                StripeConfiguration.ApiKey = GetSecretKey();

                // Retrieve PaymentIntent from Stripe
                var service = new PaymentIntentService();
                var paymentIntent = await service.GetAsync(paymentIntentId);

                _logger.LogInformation(
                    "PaymentIntent retrieved - PaymentIntentId: {PaymentIntentId}, Status: {Status}",
                    paymentIntent.Id, paymentIntent.Status);

                // Check if payment was successful
                return paymentIntent.Status == "succeeded";
            }
            catch (StripeException ex)
            {
                _logger.LogError(ex, 
                    "Stripe error confirming PaymentIntent - PaymentIntentId: {PaymentIntentId}",
                    paymentIntentId);
                throw new InvalidOperationException($"Stripe error: {ex.Message}", ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, 
                    "Error confirming PaymentIntent - PaymentIntentId: {PaymentIntentId}",
                    paymentIntentId);
                throw;
            }
        }
    }
}

