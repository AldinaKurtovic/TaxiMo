using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class StripePaymentIntentRequestDto
    {
        [Required]
        public long Amount { get; set; }

        [Required]
        [MaxLength(10)]
        public string Currency { get; set; } = string.Empty;

        [Required]
        public int RideId { get; set; }

        [Required]
        public int PaymentId { get; set; }
    }
}

