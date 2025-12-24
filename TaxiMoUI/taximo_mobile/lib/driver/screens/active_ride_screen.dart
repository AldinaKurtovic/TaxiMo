import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/active_rides_provider.dart';
import '../providers/driver_provider.dart';
import '../models/ride_request_model.dart';

class ActiveRideScreen extends StatefulWidget {
  final int? rideId; // Optional: if provided, show specific ride

  const ActiveRideScreen({super.key, this.rideId});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  @override
  void initState() {
    super.initState();
    // Load active rides when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      final driver = driverProvider.currentDriver;
      final activeRidesProvider = Provider.of<ActiveRidesProvider>(context, listen: false);
      
      if (driver != null) {
        final driverProfile = driverProvider.driverProfile;
        final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
        
        if (driverId > 0) {
          activeRidesProvider.loadActiveRides(driverId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              final driver = driverProvider.currentDriver;
              final activeRidesProvider = Provider.of<ActiveRidesProvider>(context, listen: false);
              
              if (driver != null) {
                final driverProfile = driverProvider.driverProfile;
                final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
                
                if (driverId > 0) {
                  activeRidesProvider.refresh(driverId);
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<ActiveRidesProvider>(
        builder: (context, activeRidesProvider, child) {
          if (activeRidesProvider.isLoading && activeRidesProvider.activeRides.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (activeRidesProvider.errorMessage != null && activeRidesProvider.activeRides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading active ride',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeRidesProvider.errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                      final driver = driverProvider.currentDriver;
                      
                      if (driver != null) {
                        final driverProfile = driverProvider.driverProfile;
                        final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
                        
                        if (driverId > 0) {
                          activeRidesProvider.refresh(driverId);
                        }
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Find the ride to display
          RideRequestModel? ride;
          if (widget.rideId != null) {
            try {
              ride = activeRidesProvider.activeRides.firstWhere(
                (r) => r.rideId == widget.rideId,
              );
            } catch (e) {
              // Ride not found, fall back to current active ride
              ride = activeRidesProvider.currentActiveRide;
            }
          } else {
            ride = activeRidesProvider.currentActiveRide;
          }

          if (ride == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Active Ride',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have any active or accepted rides',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ride-requests');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('View Ride Requests'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ride.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ride.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Ride Details Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Passenger Info
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.deepPurple, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Passenger',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ride.passengerName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Pickup Location
                        _LocationRow(
                          icon: Icons.location_on,
                          iconColor: Colors.green,
                          label: 'Pickup',
                          address: ride.pickupAddress,
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        Divider(color: Colors.grey[300]),
                        const SizedBox(height: 20),

                        // Dropoff Location
                        _LocationRow(
                          icon: Icons.location_on,
                          iconColor: Colors.red,
                          label: 'Dropoff',
                          address: ride.dropoffAddress,
                        ),
                        const SizedBox(height: 24),

                        // Price and Distance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Fare Estimate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ride.formattedPrice,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                            if (ride.distanceKm != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Distance',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${ride.distanceKm!.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons based on status
                _buildActionButtons(context, ride, activeRidesProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.blue;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    RideRequestModel ride,
    ActiveRidesProvider provider,
  ) {
    final status = ride.status.toLowerCase();
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final driver = driverProvider.currentDriver;
    final driverProfile = driverProvider.driverProfile;
    final driverId = driverProfile?.driverId ?? driver?.driverId ?? 0;

    if (status == 'accepted') {
      // Show Start button for accepted rides
      return ElevatedButton.icon(
        onPressed: provider.isLoading
            ? null
            : () => _handleStartRide(context, ride, provider, driverId),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Ride'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    } else if (status == 'active') {
      // Show Complete button for active rides
      return ElevatedButton.icon(
        onPressed: provider.isLoading
            ? null
            : () => _handleCompleteRide(context, ride, provider, driverId),
        icon: const Icon(Icons.check_circle),
        label: const Text('Complete Ride'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      // No action available
      return const SizedBox.shrink();
    }
  }

  Future<void> _handleStartRide(
    BuildContext context,
    RideRequestModel ride,
    ActiveRidesProvider provider,
    int driverId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Ride'),
        content: Text('Start the ride for ${ride.passengerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.startRide(ride.rideId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride started successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh to get updated ride
          provider.refresh(driverId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to start ride'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleCompleteRide(
    BuildContext context,
    RideRequestModel ride,
    ActiveRidesProvider provider,
    int driverId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Ride'),
        content: Text('Complete the ride for ${ride.passengerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.completeRide(ride.rideId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back or show completion screen
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to complete ride'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _LocationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

