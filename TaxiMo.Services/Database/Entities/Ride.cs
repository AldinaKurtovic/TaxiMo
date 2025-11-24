using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("Rides")]
    public class Ride
    {
        [Key]
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

        [Column(TypeName = "decimal(10,2)")]
        public decimal? FareEstimate { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? FareFinal { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? DistanceKm { get; set; }

        public int? DurationMin { get; set; }

        // Navigation properties
        [ForeignKey(nameof(RiderId))]
        public virtual User Rider { get; set; } = null!;

        [ForeignKey(nameof(DriverId))]
        public virtual Driver Driver { get; set; } = null!;

        [ForeignKey(nameof(VehicleId))]
        public virtual Vehicle Vehicle { get; set; } = null!;

        [ForeignKey(nameof(PickupLocationId))]
        public virtual Location PickupLocation { get; set; } = null!;

        [ForeignKey(nameof(DropoffLocationId))]
        public virtual Location DropoffLocation { get; set; } = null!;

        public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<PromoUsage> PromoUsages { get; set; } = new List<PromoUsage>();
    }
}

