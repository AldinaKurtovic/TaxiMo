using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("Drivers")]
    public class Driver
    {

        [Key]
        public int DriverId { get; set; }
        public string Username { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [MaxLength(20)]
        public string? Phone { get; set; }

        [Required]
        [MaxLength(255)]
        public string PasswordHash { get; set; } = string.Empty;

      
        public string PasswordSalt { get; set; } = string.Empty;

        public string LicenseNumber { get; set; } = string.Empty;

        public DateTime? LastLoginAt { get; set; }

        [Required]
        public DateTime LicenseExpiry { get; set; }

        [Column(TypeName = "decimal(3,2)")]
        public decimal? RatingAvg { get; set; }

        public int TotalRides { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? PhotoUrl { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; }

        [Required]
        public DateTime UpdatedAt { get; set; }

        // Navigation properties
        public virtual ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
        public virtual ICollection<Ride> Rides { get; set; } = new List<Ride>();
        public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
        public virtual ICollection<DriverAvailability> DriverAvailabilities { get; set; } = new List<DriverAvailability>();
        public virtual ICollection<DriverNotification> DriverNotifications { get; set; } = new List<DriverNotification>();
        public virtual ICollection<DriverAuthToken> DriverAuthTokens { get; set; } = new List<DriverAuthToken>();
        public virtual ICollection<DriverRole> DriverRoles { get; set; } = new List<DriverRole>();
    }
}

