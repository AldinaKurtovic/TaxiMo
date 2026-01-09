using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class StripeConfirmPaymentRequestDto
    {
        [Required]
        [MaxLength(200)]
        public string PaymentIntentId { get; set; } = string.Empty;

        [Required]
        public int PaymentId { get; set; }
    }
}

