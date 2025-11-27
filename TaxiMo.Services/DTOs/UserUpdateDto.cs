using System.ComponentModel.DataAnnotations;
using TaxiMo.Services.ValidationAttributes;

namespace TaxiMo.Services.DTOs
{
    public class UserUpdateDto
    {
        [Required(ErrorMessage = "User ID is required.")]
        public int UserId { get; set; }

        [MaxLength(50, ErrorMessage = "First name cannot exceed 50 characters.")]
        [LettersOnly(ErrorMessage = "First name must contain only letters.")]
        public string? FirstName { get; set; }

        [MaxLength(50, ErrorMessage = "Last name cannot exceed 50 characters.")]
        [LettersOnly(ErrorMessage = "Last name must contain only letters.")]
        public string? LastName { get; set; }

        [MaxLength(255, ErrorMessage = "Email cannot exceed 255 characters.")]
        [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
        public string? Email { get; set; }

        [MaxLength(20, ErrorMessage = "Phone number cannot exceed 20 characters.")]
        [PhoneNumber(ErrorMessage = "Phone number may contain digits only.")]
        public string? Phone { get; set; }

        [DateOfBirthNotInFuture(ErrorMessage = "Date of birth cannot be in the future.")]
        public DateTime? DateOfBirth { get; set; }

        [MaxLength(50, ErrorMessage = "Status cannot exceed 50 characters.")]
        public string? Status { get; set; }

        // Optional password change fields
        public bool ChangePassword { get; set; }

        [ConditionalRequired("ChangePassword", true, ErrorMessage = "New password is required when changing password.")]
        [MinLength(8, ErrorMessage = "Password must be at least 8 characters long.")]
        [MaxLength(100, ErrorMessage = "Password cannot exceed 100 characters.")]
        public string? NewPassword { get; set; }

        [ConditionalRequired("NewPassword", ErrorMessage = "Password confirmation is required when providing a new password.")]
        [PasswordMatch("NewPassword", ErrorMessage = "Password and confirmation password do not match.")]
        public string? ConfirmNewPassword { get; set; }

        // Old password - required only when user is changing their own password (handled in controller/service)
        public string? OldPassword { get; set; }
    }
}

