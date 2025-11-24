using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class RideUpdateDto
    {
        [Required]
        public int RideId { get; set; }

        [Required]
        public int RiderId { get; set; }

        [Required]
        public int DriverId { get; set; }

        [Required]
        public int VehicleId { get; set; }

        [Required]
        public int PickupLocationId { get; set; }

        [Required]
        public int DropoffLocationId { get; set; }

        [Required]
        public DateTime RequestedAt { get; set; }

        public DateTime? StartedAt { get; set; }

        public DateTime? CompletedAt { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;

        public decimal? FareEstimate { get; set; }

        public decimal? FareFinal { get; set; }

        public decimal? DistanceKm { get; set; }

        public int? DurationMin { get; set; }
    }
}

