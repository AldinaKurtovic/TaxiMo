using TaxiMo.Services.Interfaces;

namespace TaxiMo.Services.Services
{
    public class RidePriceCalculator : IRidePriceCalculator
    {
        public decimal PricePerKm => 1.0m;

        public decimal CalculateFareEstimate(double distanceKm, decimal pricePerKm)
        {
            var fare = (decimal)distanceKm * pricePerKm;
            return Math.Round(fare, 2);
        }
    }
}

