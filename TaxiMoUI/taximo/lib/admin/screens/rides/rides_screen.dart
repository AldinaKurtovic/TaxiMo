import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rides_provider.dart';
import '../../models/ride_model.dart';
import '../../models/driver_model.dart';
import 'widgets/admin_map_widget.dart';
import 'widgets/assign_driver_modal.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  final _searchController = TextEditingController();
  RideModel? _selectedRide;
  DriverModel? _selectedDriver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RidesProvider>(context, listen: false).loadRides();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'active' || statusLower == 'accepted' || statusLower == 'requested') {
      return Colors.green;
    } else if (statusLower == 'completed') {
      return Colors.purple;
    } else if (statusLower == 'cancelled') {
      return Colors.red;
    }
    return Colors.grey;
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final statusDisplay = status.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusDisplay,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRideCard(RideModel ride) {
    final isSelected = _selectedRide?.rideId == ride.rideId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRide = ride;
          _selectedDriver = null;
        });
      },
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? Colors.purple.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: isSelected ? 2 : 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      ride.driverName.isNotEmpty ? ride.driverName[0].toUpperCase() : 'D',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driverName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D3F),
                        ),
                      ),
                      Text(
                        ride.vehicleCode,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(ride.status),
            ],
          ),
          const SizedBox(height: 12),
          // User name
          Row(
            children: [
              Icon(Icons.person, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ride.riderName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Pickup location
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.green[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ride.pickupLocation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2D2D3F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Dropoff location
          Row(
            children: [
              Icon(Icons.place, size: 14, color: Colors.red[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  ride.dropoffLocation,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time range
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                ride.timeRange,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          // Show "Assign to Ride" button for unassigned rides
          if (_isUnassignedRide(ride)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showAssignDriverModal(context, ride);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Assign to Ride',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  bool _isUnassignedRide(RideModel ride) {
    // Show "Assign to Ride" button ONLY when status is "requested"
    final statusLower = ride.status.toLowerCase();
    return statusLower == 'requested';
  }

  void _showAssignDriverModal(BuildContext context, RideModel ride) {
    showDialog(
      context: context,
      builder: (context) => AssignDriverModal(ride: ride),
    );
  }

  Widget _buildFreeDriverCard(DriverModel driver) {
    final isSelected = _selectedDriver?.driverId == driver.driverId;
    // Generate vehicle code from driver ID (format: TX-XXX)
    final vehicleCode = 'TX-${driver.driverId.toString().padLeft(3, '0')}';
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDriver = driver;
          _selectedRide = null;
        });
      },
      child: Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.purple : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? Colors.purple.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: isSelected ? 2 : 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: Text(
                  driver.firstName.isNotEmpty ? driver.firstName[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D3F),
                    ),
                  ),
                  Text(
                    vehicleCode,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Current location (placeholder - would need backend support for actual location)
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Available for assignment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Open assign to ride modal
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Assign ${driver.fullName} to ride - Coming soon')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Assign to Ride',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMapWidget(RidesProvider provider) {
    // Use activeRides from provider (always shows active rides regardless of filter)
    return AdminMapWidget(
      activeRides: provider.activeRides,
      freeDrivers: provider.freeDrivers,
      selectedRide: _selectedRide,
      selectedDriver: _selectedDriver,
      onRideSelected: (ride) {
        setState(() {
          _selectedRide = ride;
          _selectedDriver = null;
        });
      },
      onDriverSelected: (driver) {
        setState(() {
          _selectedDriver = driver;
          _selectedRide = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Rides',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D3F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          // Header with Search
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Empty space (no button needed for rides)
              const SizedBox.shrink(),
              // Search Bar (right side)
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.purple.shade300!, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    Provider.of<RidesProvider>(context, listen: false).search(value.isEmpty ? null : value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Filter Tabs
          Consumer<RidesProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  _buildFilterTab('ALL', RideFilter.all, provider.currentFilter == RideFilter.all, () {
                    provider.setFilter(RideFilter.all);
                  }),
                  const SizedBox(width: 8),
                  _buildFilterTab('COMPLETED', RideFilter.completed, provider.currentFilter == RideFilter.completed, () {
                    provider.setFilter(RideFilter.completed);
                  }),
                  const SizedBox(width: 8),
                  _buildFilterTab('CANCELLED', RideFilter.cancelled, provider.currentFilter == RideFilter.cancelled, () {
                    provider.setFilter(RideFilter.cancelled);
                  }),
                  const SizedBox(width: 8),
                  _buildFilterTab('FREE DRIVERS', RideFilter.freeDrivers, provider.currentFilter == RideFilter.freeDrivers, () {
                    provider.setFilter(RideFilter.freeDrivers);
                  }),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Content: Cards and Map
          Expanded(
            child: Consumer<RidesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading rides',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48.0),
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => provider.refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Cards grid
                    Expanded(
                      flex: 2,
                      child: provider.currentFilter == RideFilter.freeDrivers
                          ? provider.freeDrivers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.drive_eta_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No free drivers available',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: provider.freeDrivers
                                        .map((driver) => _buildFreeDriverCard(driver))
                                        .toList(),
                                  ),
                                )
                          : provider.filteredRides.isEmpty
                              ? Center(
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
                                        'No rides found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: provider.filteredRides
                                        .map((ride) => _buildRideCard(ride))
                                        .toList(),
                                  ),
                                ),
                    ),
                    const SizedBox(width: 16),
                    // Right side: Map
                    Expanded(
                      flex: 1,
                      child: _buildMapWidget(provider),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, RideFilter filter, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

