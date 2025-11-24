using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.DTOs
{
    public class UserUpdateDto
    {
        [Required]
        public int UserId { get; set; }

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

        public DateTime? DateOfBirth { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;
    }
}

