import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_requests_provider.dart';
import '../providers/driver_provider.dart';
import '../models/ride_request_model.dart';
import '../widgets/driver_app_bar.dart';

class RideRequestsScreen extends StatefulWidget {
  const RideRequestsScreen({super.key});

  @override
  State<RideRequestsScreen> createState() => _RideRequestsScreenState();
}

class _RideRequestsScreenState extends State<RideRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Load ride requests when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      final driver = driverProvider.currentDriver;
      final rideRequestsProvider = Provider.of<RideRequestsProvider>(context, listen: false);
      
      if (driver != null) {
        // Get driverId from driver profile or model
        final driverProfile = driverProvider.driverProfile;
        final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
        
        if (driverId > 0) {
          rideRequestsProvider.loadRideRequests(driverId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DriverAppBar(
        title: 'Ride Requests',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              final driver = driverProvider.currentDriver;
              final rideRequestsProvider = Provider.of<RideRequestsProvider>(context, listen: false);
              
              if (driver != null) {
                final driverProfile = driverProvider.driverProfile;
                final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
                
                if (driverId > 0) {
                  rideRequestsProvider.refresh(driverId);
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<RideRequestsProvider>(
        builder: (context, rideRequestsProvider, child) {
          if (rideRequestsProvider.isLoading && rideRequestsProvider.rideRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (rideRequestsProvider.errorMessage != null && rideRequestsProvider.rideRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading ride requests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rideRequestsProvider.errorMessage!,
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
                          rideRequestsProvider.refresh(driverId);
                        }
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (rideRequestsProvider.rideRequests.isEmpty) {
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
                    'No ride requests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You don\'t have any pending ride requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              final driver = driverProvider.currentDriver;
              
              if (driver != null) {
                final driverProfile = driverProvider.driverProfile;
                final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
                
                if (driverId > 0) {
                  await rideRequestsProvider.refresh(driverId);
                }
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: rideRequestsProvider.rideRequests.length,
              itemBuilder: (context, index) {
                final ride = rideRequestsProvider.rideRequests[index];
                return _RideRequestCard(
                  ride: ride,
                  onAccept: () => _handleAccept(context, ride, rideRequestsProvider),
                  onReject: () => _handleReject(context, ride, rideRequestsProvider),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context, RideRequestModel ride, RideRequestsProvider provider) async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final driver = driverProvider.currentDriver;
    
    if (driver == null) return;
    
    final driverProfile = driverProvider.driverProfile;
    final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
    
    if (driverId == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Ride Request'),
        content: Text('Do you want to accept the ride request from ${ride.passengerName}?'),
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
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.acceptRide(ride.rideId, driverId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride request accepted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to active ride screen
          Navigator.pushNamed(context, '/active-ride', arguments: ride.rideId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to accept ride request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleReject(BuildContext context, RideRequestModel ride, RideRequestsProvider provider) async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final driver = driverProvider.currentDriver;
    
    if (driver == null) return;
    
    final driverProfile = driverProvider.driverProfile;
    final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
    
    if (driverId == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Ride Request'),
        content: Text('Do you want to reject the ride request from ${ride.passengerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.rejectRide(ride.rideId, driverId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride request rejected'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to reject ride request'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _RideRequestCard extends StatelessWidget {
  final RideRequestModel ride;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RideRequestCard({
    required this.ride,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRideDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with passenger name and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ride.passengerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ride.formattedRequestTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Pickup location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ride.pickupCoordinates,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Dropoff location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dropoff',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ride.dropoffCoordinates,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Price and distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.amber, size: 20),
                      Text(
                        ride.formattedPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  if (ride.distanceKm != null)
                    Row(
                      children: [
                        const Icon(Icons.straighten, color: Colors.grey, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${ride.distanceKm!.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRideDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ride Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(
                  icon: Icons.person,
                  label: 'Passenger',
                  value: ride.passengerName,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Pickup',
                  value: ride.pickupCoordinates,
                  iconColor: Colors.green,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Dropoff',
                  value: ride.dropoffCoordinates,
                  iconColor: Colors.red,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.attach_money,
                  label: 'Fare Estimate',
                  value: ride.formattedPrice,
                ),
                if (ride.distanceKm != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${ride.distanceKm!.toStringAsFixed(1)} km',
                  ),
                ],
                if (ride.durationMin != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Estimated Duration',
                    value: '${ride.durationMin} minutes',
                  ),
                ],
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.schedule,
                  label: 'Requested At',
                  value: '${ride.requestedAt.day}/${ride.requestedAt.month}/${ride.requestedAt.year} ${ride.requestedAt.hour}:${ride.requestedAt.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onReject();
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onAccept();
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? Colors.deepPurple, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
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

