using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class RideCreateDto
    {
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

        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
    }
}

