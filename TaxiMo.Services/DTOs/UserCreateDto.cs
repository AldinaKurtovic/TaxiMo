using System.ComponentModel.DataAnnotations;
using TaxiMo.Services.ValidationAttributes;

namespace TaxiMo.Services.DTOs
{
    public class UserCreateDto
    {
        [Required(ErrorMessage = "First name is required.")]
        [MaxLength(50)]
        [LettersOnly]
        public string FirstName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Last name is required.")]
        [MaxLength(50)]
        [LettersOnly]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        [LettersOnly]
        public string Username { get; set; } = string.Empty;

        [MaxLength(20)]
        [PhoneNumber]
        public string? Phone { get; set; }

        [DateOfBirthNotInFuture]
        public DateTime? DateOfBirth { get; set; }

        [Required]
        [MaxLength(50)]
        public string Status { get; set; } = string.Empty;

        [Required]
        [MinLength(8)]
        [MaxLength(100)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [PasswordMatch("Password")]
        public string ConfirmPassword { get; set; } = string.Empty;

        // Only ONE role
        [Required(ErrorMessage = "RoleId is required.")]
        public int RoleId { get; set; }
    }
}
