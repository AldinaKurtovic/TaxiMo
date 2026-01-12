using Microsoft.ML.Data;

namespace TaxiMo.Services.MLModels
{
    /// <summary>
    /// Features extracted from completed rides used for training the content-based recommendation model.
    /// This class represents the input features for ML.NET model training and prediction.
    /// </summary>
    public class DriverFeatures
    {
        /// <summary>
        /// Driver's average rating at the time of the ride.
        /// Why: Represents driver quality/reputation. Higher-rated drivers are typically preferred.
        /// </summary>
        [LoadColumn(0)]
        public float DriverAverageRating { get; set; }

        /// <summary>
        /// Driver's total number of completed rides (experience indicator).
        /// Why: Experienced drivers (more rides) are generally more reliable and preferred.
        /// </summary>
        [LoadColumn(1)]
        public float DriverTotalRides { get; set; }

        /// <summary>
        /// Average ride price (FareFinal or FareEstimate) for the ride.
        /// Why: Captures user's price sensitivity. Some users prefer cheaper rides, others value premium service.
        /// </summary>
        [LoadColumn(2)]
        public float AverageRidePrice { get; set; }

        /// <summary>
        /// Ride distance in kilometers.
        /// Why: Users may have preferences for certain trip lengths (short trips vs long trips).
        /// </summary>
        [LoadColumn(3)]
        public float RideDistanceKm { get; set; }

        /// <summary>
        /// Ride duration in minutes.
        /// Why: Captures user preferences for trip duration, which may correlate with driver efficiency.
        /// </summary>
        [LoadColumn(4)]
        public float RideDurationMin { get; set; }

        /// <summary>
        /// Time of day category: 0 = Morning (6-12), 1 = Afternoon (12-18), 2 = Night (18-6).
        /// Why: Temporal preferences - users may prefer different drivers at different times of day.
        /// </summary>
        [LoadColumn(5)]
        public float TimeOfDay { get; set; }

        /// <summary>
        /// Label representing user satisfaction/preference score (used for training only).
        /// - 1.0: Rating 4-5 stars (highly satisfied - user strongly liked this driver)
        /// - 0.6: Rating 3 stars (neutral/moderately satisfied - user had acceptable experience)
        /// - 0.2: Rating 1-2 stars (dissatisfied - user did not like this driver)
        /// 
        /// Why continuous scale: Allows regression model to learn nuanced preferences rather than binary classification.
        /// The SDCA regression model learns to predict these preference scores based on driver/ride features.
        /// </summary>
        [LoadColumn(6)]
        public float Label { get; set; }
    }
}
