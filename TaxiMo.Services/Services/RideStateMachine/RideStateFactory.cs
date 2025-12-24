using Microsoft.Extensions.DependencyInjection;
using TaxiMo.Model.Exceptions;

namespace TaxiMo.Services.Services.RideStateMachine
{
    public class RideStateFactory
    {
        private readonly IServiceProvider _serviceProvider;

        public RideStateFactory(IServiceProvider serviceProvider)
        {
            _serviceProvider = serviceProvider;
        }

        public InitialRideState GetInitialState()
        {
            return _serviceProvider.GetRequiredService<InitialRideState>();
        }

        public BaseRideState GetState(string status)
        {
            if (string.IsNullOrWhiteSpace(status))
            {
                throw new UserException("Invalid ride state");
            }

            return status.ToLower() switch
            {
                RideStatuses.Requested => _serviceProvider.GetRequiredService<RequestedRideState>(),
                RideStatuses.Accepted => _serviceProvider.GetRequiredService<AcceptedRideState>(),
                RideStatuses.Active => _serviceProvider.GetRequiredService<ActiveRideState>(),
                RideStatuses.Completed => _serviceProvider.GetRequiredService<CompletedRideState>(),
                RideStatuses.Cancelled => _serviceProvider.GetRequiredService<CancelledRideState>(),
                _ => throw new UserException("Invalid ride state")
            };
        }
    }
}

