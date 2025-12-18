namespace TaxiMo.Services.Interfaces
{
    public interface IRidePriceCalculator
    {
        decimal CalculateFareEstimate(double distanceKm, decimal pricePerKm);
        decimal PricePerKm { get; }
    }
}

