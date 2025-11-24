using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TaxiMo.Services.Database.Entities
{
    [Table("UserNotifications")]
    public class UserNotification
    {
        [Key]
        public int NotificationId { get; set; }

        [Required]
        public int RecipientUserId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Body { get; set; }

        [Required]
        [MaxLength(50)]
        public string Type { get; set; } = string.Empty;

        [Required]
        public bool IsRead { get; set; }

        [Required]
        public DateTime SentAt { get; set; }

        // Navigation properties
        [ForeignKey(nameof(RecipientUserId))]
        public virtual User RecipientUser { get; set; } = null!;
    }
}

