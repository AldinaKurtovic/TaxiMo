using System.ComponentModel.DataAnnotations;
using TaxiMo.Services.ValidationAttributes;

namespace TaxiMo.Services.DTOs
{
    public class UserUpdateDto
    {
        [Required]
        public int UserId { get; set; }

        [MaxLength(50)]
        [LettersOnly]
        public string? FirstName { get; set; }

        [MaxLength(50)]
        [LettersOnly]
        public string? LastName { get; set; }

        [MaxLength(255)]
        [EmailAddress]
        public string? Email { get; set; }

        [MaxLength(50)]
        [LettersOnly]
        public string? Username { get; set; }

        [MaxLength(20)]
        [PhoneNumber]
        public string? Phone { get; set; }

        [DateOfBirthNotInFuture]
        public DateTime? DateOfBirth { get; set; }

        [MaxLength(50)]
        public string? Status { get; set; }

        public bool ChangePassword { get; set; }

        [ConditionalRequired("ChangePassword", true)]
        [MinLength(8)]
        [MaxLength(100)]
        public string? NewPassword { get; set; }

        [ConditionalRequired("NewPassword")]
        [PasswordMatch("NewPassword")]
        public string? ConfirmNewPassword { get; set; }

        public string? OldPassword { get; set; }

        // ONE ROLE ONLY
        public int? RoleId { get; set; }
    }
}
