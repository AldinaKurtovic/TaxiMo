namespace TaxiMo.Services.DTOs
{
    public class ReviewDto
    {
        public int ReviewId { get; set; }
        public int RideId { get; set; }
        public int RiderId { get; set; }
        public int DriverId { get; set; }
        public decimal Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

