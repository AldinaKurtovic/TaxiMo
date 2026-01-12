namespace TaxiMo.Model.Messages
{
    public class RideCreated
    {
        public int RideId { get; set; }
        public int RiderId { get; set; }
        public int DriverId { get; set; }
        public string PickupLocation { get; set; } = string.Empty;
        public string DropoffLocation { get; set; } = string.Empty;
        public decimal? FareEstimate { get; set; }
       
    }
}

