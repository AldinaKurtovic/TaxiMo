namespace TaxiMo.Services.DTOs
{
    public class RideResponse
    {
        public int RideId { get; set; }
        public int RiderId { get; set; }
        public int DriverId { get; set; }
        public int VehicleId { get; set; }
        public int PickupLocationId { get; set; }
        public int DropoffLocationId { get; set; }
        public DateTime RequestedAt { get; set; }
        public DateTime? StartedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public string Status { get; set; } = string.Empty;
        public decimal? FareEstimate { get; set; }
        public decimal? FareFinal { get; set; }
        public decimal? DistanceKm { get; set; }
        public int? DurationMin { get; set; }

        // Navigation properties
        public DriverDto? Driver { get; set; }
        public UserDto? Rider { get; set; }
        public VehicleDto? Vehicle { get; set; }
        public LocationDto? PickupLocation { get; set; }
        public LocationDto? DropoffLocation { get; set; }
        
        // Driver coordinates for map display (only for active/accepted/requested rides)
        public double? DriverLatitude { get; set; }
        public double? DriverLongitude { get; set; }
    }
}

