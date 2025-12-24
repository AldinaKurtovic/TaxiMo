using AutoMapper;
using TaxiMo.Services.Database;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public class CompletedRideState : BaseRideState
    {
        public CompletedRideState(TaxiMoDbContext context, IMapper mapper)
            : base(context, mapper)
        {
        }

        // No transitions allowed from Completed state
        // All methods throw "Not allowed" from base class
    }
}

