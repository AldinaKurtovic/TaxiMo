using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class VehicleCreateDto
    {
        [Required]
        public int DriverId { get; set; }

        [Required]
        [MaxLength(50)]
        public string Make { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Model { get; set; } = string.Empty;

        [Required]
        public int Year { get; set; }

        [Required]
        [MaxLength(20)]
        public string PlateNumber { get; set; } = string.Empty;

        [MaxLength(30)]
        public string? Color { get; set; }

        [Required]
        [MaxLength(50)]
        public string VehicleType { get; set; } = string.Empty;

        [Required]
        public int Capacity { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
    }
}

