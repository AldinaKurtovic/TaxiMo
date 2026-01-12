using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.ValidationAttributes
{
    /// <summary>
    /// Validates that a password confirmation field matches the password field
    /// </summary>
    public class PasswordMatchAttribute : ValidationAttribute
    {
        private readonly string _passwordPropertyName;

        public PasswordMatchAttribute(string passwordPropertyName)
        {
            _passwordPropertyName = passwordPropertyName;
            ErrorMessage = "Password and confirmation password do not match.";
        }

        protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
        {
            if (value == null)
            {
                return ValidationResult.Success; // Allow null if password is optional
            }

            var passwordProperty = validationContext.ObjectType.GetProperty(_passwordPropertyName);
            if (passwordProperty == null)
            {
                return new ValidationResult($"Property {_passwordPropertyName} not found.");
            }

            var passwordValue = passwordProperty.GetValue(validationContext.ObjectInstance);

            if (passwordValue == null && value == null)
            {
                return ValidationResult.Success;
            }

            if (passwordValue == null || value == null)
            {
                return new ValidationResult(ErrorMessage);
            }

            if (!passwordValue.Equals(value))
            {
                return new ValidationResult(ErrorMessage);
            }

            return ValidationResult.Success;
        }
    }
}

