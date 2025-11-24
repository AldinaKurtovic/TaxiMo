using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("DriverAuthTokens")]
    public class DriverAuthToken
    {
        [Key]
        public int TokenId { get; set; }

        [Required]
        public int DriverId { get; set; }

        [MaxLength(200)]
        public string? DeviceId { get; set; }

        [Required]
        [MaxLength(500)]
        public string TokenHash { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? RefreshTokenHash { get; set; }

        [Required]
        public DateTime ExpiresAt { get; set; }

        public DateTime? RevokedAt { get; set; }

        [MaxLength(50)]
        public string? IpAddress { get; set; }

        // Navigation properties
        [ForeignKey(nameof(DriverId))]
        public virtual Driver Driver { get; set; } = null!;
    }
}

