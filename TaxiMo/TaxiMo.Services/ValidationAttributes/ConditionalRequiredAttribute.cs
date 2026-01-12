using System.ComponentModel.DataAnnotations;

namespace TaxiMo.Services.ValidationAttributes
{
    /// <summary>
    /// Makes a field required only if another field has a specific value
    /// </summary>
    public class ConditionalRequiredAttribute : ValidationAttribute
    {
        private readonly string _dependentPropertyName;
        private readonly object? _dependentPropertyValue;

        public ConditionalRequiredAttribute(string dependentPropertyName, object? dependentPropertyValue = null)
        {
            _dependentPropertyName = dependentPropertyName;
            _dependentPropertyValue = dependentPropertyValue;
        }

        protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
        {
            var dependentProperty = validationContext.ObjectType.GetProperty(_dependentPropertyName);
            if (dependentProperty == null)
            {
                return new ValidationResult($"Property {_dependentPropertyName} not found.");
            }

            var dependentValue = dependentProperty.GetValue(validationContext.ObjectInstance);

            // Check if condition is met
            bool conditionMet;
            if (_dependentPropertyValue == null)
            {
                // If no specific value provided, check if dependent property is not null/empty
                conditionMet = dependentValue != null && 
                              !(dependentValue is string str && string.IsNullOrWhiteSpace(str));
            }
            else
            {
                // Handle boolean comparisons properly
                if (dependentValue is bool boolValue && _dependentPropertyValue is bool boolTarget)
                {
                    conditionMet = boolValue == boolTarget;
                }
                else
                {
                    conditionMet = Equals(dependentValue, _dependentPropertyValue);
                }
            }

            // If condition is met, the field is required
            if (conditionMet)
            {
                if (value == null || (value is string str && string.IsNullOrWhiteSpace(str)))
                {
                    return new ValidationResult(ErrorMessage ?? $"{validationContext.DisplayName} is required.");
                }
            }

            return ValidationResult.Success;
        }
    }
}

