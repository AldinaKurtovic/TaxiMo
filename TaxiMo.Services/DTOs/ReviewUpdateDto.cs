using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.DTOs
{
    public class ReviewUpdateDto
    {
        [Required]
        public int ReviewId { get; set; }

        [Required]
        public int RideId { get; set; }

        [Required]
        public int RiderId { get; set; }

        [Required]
        public int DriverId { get; set; }

        [Required]
        [Column(TypeName = "decimal(3,2)")]
        public decimal Rating { get; set; }

        [MaxLength(1000)]
        public string? Comment { get; set; }
    }
}

