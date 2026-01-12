namespace TaxiMo.Services.DTOs
{
    public class DriverReviewDto
    {
        public int ReviewId { get; set; }
        public int RideId { get; set; }
        public int RiderId { get; set; }
        public string RiderName { get; set; } = string.Empty;
        public decimal Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

