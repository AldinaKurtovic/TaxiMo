using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("Vehicles")]
    public class Vehicle
    {
        [Key]
        public int VehicleId { get; set; }

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

        [Required]
        public DateTime CreatedAt { get; set; }

        [Required]
        public DateTime UpdatedAt { get; set; }

        // Navigation properties
        [ForeignKey(nameof(DriverId))]
        public virtual Driver Driver { get; set; } = null!;

        public virtual ICollection<Ride> Rides { get; set; } = new List<Ride>();
    }
}

