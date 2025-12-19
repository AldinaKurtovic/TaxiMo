using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class RideCreateDto
    {
        [Required]
        public int RiderId { get; set; }

        [Required]
        public int DriverId { get; set; }

        // VehicleId is optional - backend will select the first active vehicle for the driver
        public int? VehicleId { get; set; }

        [Required]
        public int PickupLocationId { get; set; }

        [Required]
        public int DropoffLocationId { get; set; }

        [Required]
        public DateTime RequestedAt { get; set; }

        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;

        public double? DistanceKm { get; set; }

        public int? DurationMin { get; set; }
    }
}

