namespace TaxiMo.Services.DTOs
{
    public class PaymentDto
    {
        public int PaymentId { get; set; }
        public int RideId { get; set; }
        public int UserId { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string? TransactionRef { get; set; }
        public DateTime? PaidAt { get; set; }
    }
}

