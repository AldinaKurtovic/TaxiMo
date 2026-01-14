import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/rides_provider.dart';
import '../../../models/ride_model.dart';
import '../../../models/driver_model.dart';
import '../../../services/rides_service.dart';

class AssignRideToDriverModal extends StatefulWidget {
  final DriverModel driver;

  const AssignRideToDriverModal({
    super.key,
    required this.driver,
  });

  @override
  State<AssignRideToDriverModal> createState() => _AssignRideToDriverModalState();
}

class _AssignRideToDriverModalState extends State<AssignRideToDriverModal> {
  RideModel? _selectedRide;
  bool _isLoading = false;
  bool _isFetchingRides = false;
  List<RideModel> _requestedRides = [];
  final RidesService _ridesService = RidesService();

  @override
  void initState() {
    super.initState();
    _fetchRequestedRides();
  }

  Future<void> _fetchRequestedRides() async {
    setState(() {
      _isFetchingRides = true;
    });

    try {
      final ridesList = await _ridesService.getAll(status: 'requested');
      setState(() {
        _requestedRides = ridesList
            .map((json) => RideModel.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching requested rides: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading rides: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRides = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedRide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ride')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<RidesProvider>(context, listen: false);
      await provider.assignDriver(_selectedRide!.rideId, widget.driver.driverId);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver ${widget.driver.fullName} assigned to ride #${_selectedRide!.rideId} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign Ride to Driver',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D3F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Driver: ${widget.driver.fullName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: _isFetchingRides
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _requestedRides.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No requested rides available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select a ride:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2D2D3F),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._requestedRides.map((ride) {
                                final isSelected = _selectedRide?.rideId == ride.rideId;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedRide = ride;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.purple.withOpacity(0.1)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.purple
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Ride #${ride.rideId}',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSelected
                                                          ? Colors.purple
                                                          : Color(0xFF2D2D3F),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    ride.riderName,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.purple,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 14, color: Colors.green[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                ride.pickupLocation,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
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
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading || _selectedRide == null ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Assign Ride'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

