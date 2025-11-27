using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace TaxiMo.Services.ValidationAttributes
{
    /// <summary>
    /// Validates that a phone number contains only digits with an optional '+' at the beginning
    /// </summary>
    public class PhoneNumberAttribute : ValidationAttribute
    {
        private static readonly Regex PhoneRegex = new Regex(@"^\+?[0-9]+$", RegexOptions.Compiled);

        public PhoneNumberAttribute()
        {
            ErrorMessage = "Phone number may contain digits only.";
        }

        public override bool IsValid(object? value)
        {
            if (value == null)
            {
                return true; // Allow null values (optional field)
            }

            if (value is not string phoneNumber)
            {
                return false;
            }

            if (string.IsNullOrWhiteSpace(phoneNumber))
            {
                return true; // Allow empty strings (optional field)
            }

            return PhoneRegex.IsMatch(phoneNumber);
        }
    }
}

