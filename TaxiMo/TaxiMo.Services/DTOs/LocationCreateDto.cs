using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.DTOs
{
    public class LocationCreateDto
    {
        public int? UserId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? AddressLine { get; set; }

        [MaxLength(100)]
        public string? City { get; set; }

        [Required]
        [Column(TypeName = "decimal(10,8)")]
        public decimal Lat { get; set; }

        [Required]
        [Column(TypeName = "decimal(11,8)")]
        public decimal Lng { get; set; }
    }
}

