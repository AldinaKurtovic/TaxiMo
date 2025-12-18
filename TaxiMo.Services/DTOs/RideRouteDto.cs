namespace TaxiMo.Services.DTOs
{
    public class RideRouteDto
    {
        public double DistanceKm { get; set; }
        public decimal PricePerKm { get; set; }
        public decimal FareEstimate { get; set; }
        public int? DurationMin { get; set; }
    }
}

