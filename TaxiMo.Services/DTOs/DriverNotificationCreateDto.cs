using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class DriverNotificationCreateDto
    {
        [Required]
        public int RecipientDriverId { get; set; }

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
    }
}

