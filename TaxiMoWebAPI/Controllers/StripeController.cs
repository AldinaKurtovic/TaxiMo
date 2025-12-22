using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Stripe;
using TaxiMo.Services.Database;
using TaxiMo.Services.DTOs;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StripeController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<StripeController> _logger;
        private readonly TaxiMoDbContext _context;

        public StripeController(
            IConfiguration configuration,
            ILogger<StripeController> logger,
            TaxiMoDbContext context)
        {
            _configuration = configuration;
            _logger = logger;
            _context = context;
        }

        #region Helpers

        private string GetStripeSecretKey()
        {
            var secretKey = Environment.GetEnvironmentVariable("STRIPE_SECRET_KEY")
                            ?? _configuration["Stripe:SecretKey"];

            if (string.IsNullOrWhiteSpace(secretKey))
            {
                throw new InvalidOperationException("Stripe SecretKey is not configured.");
            }

            return secretKey;
        }

        private string GetStripeWebhookSecret()
        {
            var webhookSecret = Environment.GetEnvironmentVariable("STRIPE_WEBHOOK_SECRET")
                                ?? _configuration["Stripe:WebhookSecret"];

            if (string.IsNullOrWhiteSpace(webhookSecret))
            {
                throw new InvalidOperationException("Stripe WebhookSecret is not configured.");
            }

            return webhookSecret;
        }

        #endregion

        // ======================================================
        // CREATE PAYMENT INTENT
        // ======================================================
        [HttpPost("create-payment-intent")]
        [Authorize(Roles = "User,Admin")]
        public IActionResult CreatePaymentIntent([FromBody] StripePaymentIntentRequestDto request)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            StripeConfiguration.ApiKey = GetStripeSecretKey();

            var options = new PaymentIntentCreateOptions
            {
                Amount = request.Amount,
                Currency = request.Currency.ToLower(),
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                },
                Metadata = new Dictionary<string, string>
                {
                    { "rideId", request.RideId.ToString() },
                    { "paymentId", request.PaymentId.ToString() }
                }
            };

            var service = new PaymentIntentService();
            var paymentIntent = service.Create(options);

            _logger.LogInformation(
                "PaymentIntent created - PI: {PI}, RideId: {RideId}, PaymentId: {PaymentId}",
                paymentIntent.Id, request.RideId, request.PaymentId);

            return Ok(new StripePaymentIntentResponseDto
            {
                ClientSecret = paymentIntent.ClientSecret
            });
        }

        // ======================================================
        // STRIPE WEBHOOK
        // ======================================================
        [HttpPost("webhook")]
        [IgnoreAntiforgeryToken]
        public async Task<IActionResult> Webhook()
        {
            StripeConfiguration.ApiKey = GetStripeSecretKey();
            var webhookSecret = GetStripeWebhookSecret();

            Request.EnableBuffering();
            using var reader = new StreamReader(Request.Body);
            var json = await reader.ReadToEndAsync();
            Request.Body.Position = 0;

            var signature = Request.Headers["Stripe-Signature"].FirstOrDefault();
            if (string.IsNullOrWhiteSpace(signature))
            {
                _logger.LogWarning("Stripe webhook signature missing");
                return Ok(); // ⬅️ NIKAD 400
            }

            Event stripeEvent;
            try
            {
                stripeEvent = EventUtility.ConstructEvent(json, signature, webhookSecret);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Webhook signature validation failed");
                return Ok(); // ⬅️ Stripe-friendly
            }

            _logger.LogInformation(
                "Stripe webhook received - Type: {Type}, EventId: {EventId}",
                stripeEvent.Type, stripeEvent.Id);

            if (stripeEvent.Type == "payment_intent.succeeded")
            {
                await HandlePaymentIntentSucceeded(stripeEvent);
            }

            return Ok();
        }

        // ======================================================
        // PAYMENT INTENT SUCCEEDED
        // ======================================================
        private async Task HandlePaymentIntentSucceeded(Event stripeEvent)
        {
            var paymentIntent = stripeEvent.Data.Object as PaymentIntent;
            if (paymentIntent == null)
            {
                _logger.LogWarning("PaymentIntent null, ignoring");
                return;
            }

            if (paymentIntent.Metadata == null ||
                !paymentIntent.Metadata.TryGetValue("paymentId", out var paymentIdStr) ||
                !int.TryParse(paymentIdStr, out var paymentId))
            {
                _logger.LogWarning(
                    "paymentId metadata missing/invalid for PI {PI}, ignoring",
                    paymentIntent.Id);
                return;
            }

            var payment = await _context.Payments.FindAsync(paymentId);
            if (payment == null)
            {
                _logger.LogWarning(
                    "Payment {PaymentId} not found, ignoring webhook",
                    paymentId);
                return;
            }

            if (payment.Status.Equals("completed", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogInformation(
                    "Payment {PaymentId} already completed, ignoring",
                    paymentId);
                return;
            }

            payment.Status = "completed";
            payment.PaidAt = DateTime.UtcNow;
            payment.TransactionRef = paymentIntent.Id;

            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Payment COMPLETED - PaymentId: {PaymentId}, PI: {PI}",
                payment.PaymentId, paymentIntent.Id);
        }
    }
}
