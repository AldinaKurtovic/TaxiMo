using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class PromoUsageUpdateDto
    {
        [Required]
        public int PromoUsageId { get; set; }

        [Required]
        public int PromoId { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public int RideId { get; set; }

        [Required]
        public DateTime UsedAt { get; set; }
    }
}

