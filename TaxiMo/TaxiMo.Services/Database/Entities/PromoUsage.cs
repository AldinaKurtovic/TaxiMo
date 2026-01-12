using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("PromoUsages")]
    public class PromoUsage
    {
        [Key]
        public int PromoUsageId { get; set; }

        [Required]
        public int PromoId { get; set; }

        [Required]
        public int UserId { get; set; }

        [Required]
        public int RideId { get; set; }

        [Required]
        public DateTime UsedAt { get; set; }

        // Navigation properties
        [ForeignKey(nameof(PromoId))]
        public virtual PromoCode PromoCode { get; set; } = null!;

        [ForeignKey(nameof(UserId))]
        public virtual User User { get; set; } = null!;

        [ForeignKey(nameof(RideId))]
        public virtual Ride Ride { get; set; } = null!;
    }
}

