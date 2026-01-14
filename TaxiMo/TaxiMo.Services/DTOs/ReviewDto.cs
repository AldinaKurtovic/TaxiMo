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
        
        // Optional fields for driver and rider info (for UI display)
        public string? UserName { get; set; }
        public string? UserPhotoUrl { get; set; }
        public string? UserFirstName { get; set; }
        public string? DriverName { get; set; }
        public string? DriverPhotoUrl { get; set; }
        public string? DriverFirstName { get; set; }
    }
}

