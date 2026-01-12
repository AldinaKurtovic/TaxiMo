using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TaxiMo.Services.Database;
using TaxiMo.Services.DTOs;
using TaxiMo.Services.Interfaces;

namespace TaxiMoWebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StripeController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<StripeController> _logger;
        private readonly TaxiMoDbContext _context;
        private readonly IStripeService _stripeService;
        private readonly IUserNotificationService _userNotificationService;

        public StripeController(
            IConfiguration configuration,
            ILogger<StripeController> logger,
            TaxiMoDbContext context,
            IStripeService stripeService,
            IUserNotificationService userNotificationService)
        {
            _configuration = configuration;
            _logger = logger;
            _context = context;
            _stripeService = stripeService;
            _userNotificationService = userNotificationService;
        }

        // ======================================================
        // CREATE PAYMENT INTENT
        // ======================================================
        [HttpPost("create-payment-intent")]
        [Authorize(Roles = "User,Admin")]
        public async Task<IActionResult> CreatePaymentIntent([FromBody] StripePaymentIntentRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                // Use StripeService to create PaymentIntent
                var clientSecret = await _stripeService.CreatePaymentIntentAsync(
                    request.Amount,
                    request.Currency,
                    request.RideId,
                    request.PaymentId);

                return Ok(new StripePaymentIntentResponseDto
                {
                    ClientSecret = clientSecret
                });
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Error creating PaymentIntent - RideId: {RideId}, PaymentId: {PaymentId}",
                    request.RideId, request.PaymentId);
                return StatusCode(500, new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error creating PaymentIntent - RideId: {RideId}, PaymentId: {PaymentId}",
                    request.RideId, request.PaymentId);
                return StatusCode(500, new { message = "An error occurred while creating the payment intent" });
            }
        }

        // ======================================================
        // CONFIRM PAYMENT INTENT
        // ======================================================
        [HttpPost("confirm-payment-intent")]
        [Authorize(Roles = "User,Admin")]
        public async Task<IActionResult> ConfirmPaymentIntent([FromBody] StripeConfirmPaymentRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                // Verify payment exists and belongs to the user
                var payment = await _context.Payments.FindAsync(request.PaymentId);
                if (payment == null)
                {
                    _logger.LogWarning("Payment {PaymentId} not found", request.PaymentId);
                    return NotFound(new { message = "Payment not found" });
                }

                // Check if payment is already completed
                if (payment.Status.Equals("completed", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogInformation(
                        "Payment {PaymentId} already completed",
                        request.PaymentId);
                    return Ok(new { message = "Payment already completed", completed = true });
                }

                // Confirm payment with Stripe
                var isSuccessful = await _stripeService.ConfirmPaymentIntentAsync(request.PaymentIntentId);

                if (isSuccessful)
                {
                    // Update payment status immediately
                    payment.Status = "completed";
                    payment.PaidAt = DateTime.UtcNow;
                    payment.TransactionRef = request.PaymentIntentId;

                    await _context.SaveChangesAsync();

                    _logger.LogInformation(
                        "Payment COMPLETED - PaymentId: {PaymentId}, PaymentIntentId: {PaymentIntentId}",
                        payment.PaymentId, request.PaymentIntentId);

                    // Create notification for user - payment completed
                    try
                    {
                        var amountInfo = payment.Amount > 0 
                            ? $"Amount: {payment.Amount:F2} {payment.Currency}" 
                            : "";
                        await _userNotificationService.CreateNotificationAsync(
                            payment.UserId,
                            "Payment Completed",
                            $"Your payment has been processed successfully. Payment ID: {payment.PaymentId}. {amountInfo}",
                            "payment");
                    }
                    catch (Exception ex)
                    {
                        // Log error but don't fail the payment confirmation
                        _logger.LogWarning(ex, "Failed to create notification for payment completion - PaymentId: {PaymentId}", payment.PaymentId);
                    }

                    return Ok(new { message = "Payment confirmed successfully", completed = true });
                }
                else
                {
                    _logger.LogWarning(
                        "PaymentIntent {PaymentIntentId} not succeeded - PaymentId: {PaymentId}",
                        request.PaymentIntentId, request.PaymentId);
                    return BadRequest(new { message = "Payment was not successful", completed = false });
                }
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Error confirming PaymentIntent - PaymentIntentId: {PaymentIntentId}, PaymentId: {PaymentId}",
                    request.PaymentIntentId, request.PaymentId);
                return StatusCode(500, new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error confirming PaymentIntent - PaymentIntentId: {PaymentIntentId}, PaymentId: {PaymentId}",
                    request.PaymentIntentId, request.PaymentId);
                return StatusCode(500, new { message = "An error occurred while confirming the payment" });
            }
        }
    }
}
