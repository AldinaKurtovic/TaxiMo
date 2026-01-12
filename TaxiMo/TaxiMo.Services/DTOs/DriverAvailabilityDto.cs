namespace TaxiMo.Services.DTOs
{
    public class DriverAvailabilityDto
    {
        public int AvailabilityId { get; set; }
        public int DriverId { get; set; }
        public bool IsOnline { get; set; }
        public decimal? CurrentLat { get; set; }
        public decimal? CurrentLng { get; set; }
        public DateTime? LastLocationUpdate { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}

