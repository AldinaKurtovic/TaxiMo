using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.DTOs
{
    public class DriverAvailabilityUpdateDto
    {
        [Required]
        public int AvailabilityId { get; set; }

        [Required]
        public int DriverId { get; set; }

        [Required]
        public bool IsOnline { get; set; }

        [Column(TypeName = "decimal(10,8)")]
        public decimal? CurrentLat { get; set; }

        [Column(TypeName = "decimal(11,8)")]
        public decimal? CurrentLng { get; set; }

        public DateTime? LastLocationUpdate { get; set; }
    }
}

