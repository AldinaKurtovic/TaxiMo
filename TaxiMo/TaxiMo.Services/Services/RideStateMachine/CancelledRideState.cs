using AutoMapper;
using TaxiMo.Services.Database;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public class CancelledRideState : BaseRideState
    {
        public CancelledRideState(TaxiMoDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        // No transitions allowed from Cancelled state
        // All methods throw "Not allowed" from base class
    }
}

