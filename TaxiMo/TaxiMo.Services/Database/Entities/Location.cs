using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("Locations")]
    public class Location
    {
        [Key]
        public int LocationId { get; set; }

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

        [Required]
        public DateTime CreatedAt { get; set; }

        [Required]
        public DateTime UpdatedAt { get; set; }

        // Navigation properties
        [ForeignKey(nameof(UserId))]
        public virtual User? User { get; set; }
        [InverseProperty(nameof(Ride.PickupLocation))]
        public virtual ICollection<Ride> PickupRides { get; set; } = new List<Ride>();

        [InverseProperty(nameof(Ride.DropoffLocation))]
        public virtual ICollection<Ride> DropoffRides { get; set; } = new List<Ride>();

    }
}

