using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("Reviews")]
    public class Review
    {
        [Key]
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

        [Required]
        public DateTime CreatedAt { get; set; }

        // Navigation properties
        [ForeignKey(nameof(RideId))]
        public virtual Ride Ride { get; set; } = null!;

        [ForeignKey(nameof(RiderId))]
        public virtual User Rider { get; set; } = null!;

        [ForeignKey(nameof(DriverId))]
        public virtual Driver Driver { get; set; } = null!;
    }
}

