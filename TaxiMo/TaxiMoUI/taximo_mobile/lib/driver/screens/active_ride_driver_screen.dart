import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/active_rides_provider.dart';
import '../providers/driver_provider.dart';
import '../models/ride_request_model.dart';

// Note: This screen supports DEMO MODE for testing without real backend state
// See _createMockRideData() method for demo implementation

class ActiveRideDriverScreen extends StatefulWidget {
  final int? rideId;

  const ActiveRideDriverScreen({super.key, this.rideId});

  @override
  State<ActiveRideDriverScreen> createState() => _ActiveRideDriverScreenState();
}

class _ActiveRideDriverScreenState extends State<ActiveRideDriverScreen> {
  final MapController _mapController = MapController();
  LatLng? _driverCurrentPosition;
  Timer? _locationUpdateTimer;
  List<LatLng> _routePoints = [];
  RideRequestModel? _currentRide;
  bool _isMapReady = false;
  bool _isPositionSelected = false; // Track if driver has selected position
  bool _isRideStarted = false; // Track if ride has started
  int _currentRouteIndex = 0; // Index for simulated movement along route

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Try to load real ride data first
      try {
        final activeRidesProvider = Provider.of<ActiveRidesProvider>(context, listen: false);
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        final driver = driverProvider.currentDriver;
        
        if (driver != null) {
          final driverProfile = driverProvider.driverProfile;
          final driverId = driverProfile?.driverId ?? driver.driverId ?? 0;
          
          if (driverId > 0) {
            activeRidesProvider.loadActiveRides(driverId).then((_) {
              _loadRideData(activeRidesProvider);
            });
            return;
          }
        }
      } catch (e) {
        // If provider is not available, fall through to demo mode
      }
      
      // DEMO MODE: If no real data available, use mock data immediately
      _createMockRideData();
    });
  }

  void _loadRideData(ActiveRidesProvider provider) {
    RideRequestModel? ride;
    if (widget.rideId != null) {
      try {
        ride = provider.activeRides.firstWhere(
          (r) => r.rideId == widget.rideId,
        );
      } catch (e) {
        ride = provider.currentActiveRide;
      }
    } else {
      ride = provider.currentActiveRide;
    }

    // DEMO MODE: If no real ride data found, create mock data for demo/testing
    if (ride == null || ride.status.toLowerCase() != 'active') {
      _createMockRideData();
      return;
    }

    if (ride.status.toLowerCase() == 'active') {
      final activeRide = ride; // Non-null local variable
      setState(() {
        _currentRide = activeRide;
        // Automatically initialize driver position at pickup location
        if (activeRide.pickupLocation != null) {
          _driverCurrentPosition = LatLng(
            activeRide.pickupLocation!.lat,
            activeRide.pickupLocation!.lng,
          );
          _isPositionSelected = true;
        }
        // Automatically initialize route for ride simulation
        if (activeRide.dropoffLocation != null && _driverCurrentPosition != null) {
          final destination = LatLng(
            activeRide.dropoffLocation!.lat,
            activeRide.dropoffLocation!.lng,
          );
          // Defer route generation to avoid blocking setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _driverCurrentPosition != null) {
              setState(() {
          _routePoints = _generateRoutePoints(_driverCurrentPosition!, destination);
          _currentRouteIndex = 0;
          _isRideStarted = true;
              });
          // Location updates will start when map is ready (in _onMapReady)
            }
          });
        }
      });
      // Start location updates if map is already ready, otherwise wait for _onMapReady
      if (_isMapReady && _isRideStarted && _locationUpdateTimer == null) {
        _startLocationUpdates();
      }
    }
  }

  // ========== DEMO MODE: Create mock ride data for testing ==========
  // This allows the screen to work standalone without backend state
  // REMOVE THIS METHOD IN PRODUCTION
  void _createMockRideData() {
    // Mock locations in Mostar, Bosnia and Herzegovina
    // Pickup: City center
    // Destination: Slightly north
    final mockPickupLocation = LocationInfo(
      locationId: 1,
      name: 'City Center',
      addressLine: 'Trg Musala',
      city: 'Mostar',
      lat: 43.3438,
      lng: 17.8078,
    );
    
    final mockDropoffLocation = LocationInfo(
      locationId: 2,
      name: 'Destination',
      addressLine: 'North Mostar',
      city: 'Mostar',
      lat: 43.3650,
      lng: 17.8100,
    );

    final mockRider = RiderInfo(
      userId: 1,
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      phone: '+1234567890',
    );

    // Calculate mock distance (using Haversine formula inline for demo)
    const double earthRadiusKm = 6371.0;
    final dLatRad = (mockDropoffLocation.lat - mockPickupLocation.lat) * (math.pi / 180.0);
    final dLonRad = (mockDropoffLocation.lng - mockPickupLocation.lng) * (math.pi / 180.0);
    final lat1Rad = mockPickupLocation.lat * (math.pi / 180.0);
    final lat2Rad = mockDropoffLocation.lat * (math.pi / 180.0);
    final a = math.sin(dLatRad / 2) * math.sin(dLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLonRad / 2) * math.sin(dLonRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final mockDistance = earthRadiusKm * c;

    final mockRide = RideRequestModel(
      rideId: widget.rideId ?? 1,
      riderId: 1,
      driverId: 1,
      vehicleId: 1,
      pickupLocationId: 1,
      dropoffLocationId: 2,
      requestedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      startedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      status: 'active',
      fareEstimate: mockDistance * 1.5, // Mock pricing
      distanceKm: mockDistance,
      durationMin: (mockDistance / 30 * 60).round(), // Assuming 30 km/h
      rider: mockRider,
      pickupLocation: mockPickupLocation,
      dropoffLocation: mockDropoffLocation,
    );

    setState(() {
      _currentRide = mockRide;
      // Automatically initialize driver position at pickup location
      _driverCurrentPosition = LatLng(
        mockPickupLocation.lat,
        mockPickupLocation.lng,
      );
        _isPositionSelected = true;
      // Automatically initialize route for ride simulation
      final destination = LatLng(
        mockDropoffLocation.lat,
        mockDropoffLocation.lng,
      );
      // Defer route generation to avoid blocking setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _driverCurrentPosition != null) {
          setState(() {
        _routePoints = _generateRoutePoints(_driverCurrentPosition!, destination);
        _currentRouteIndex = 0;
      _isRideStarted = true;
          });
      // Location updates will start when map is ready (in _onMapReady)
        }
      });
      });
    // Start location updates if map is already ready, otherwise wait for _onMapReady
    if (_isMapReady && _isRideStarted && _locationUpdateTimer == null) {
      _startLocationUpdates();
    }
  }
  // ========== END DEMO MODE ==========

  // Map tap handler removed - no longer needed as driver position is automatically set at pickup
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Tap handling removed - ride starts automatically at pickup location
  }

  void _initializeRoute(RideRequestModel ride) {
    if (ride.pickupLocation != null && ride.dropoffLocation != null) {
      final pickup = LatLng(ride.pickupLocation!.lat, ride.pickupLocation!.lng);
      final destination = LatLng(ride.dropoffLocation!.lat, ride.dropoffLocation!.lng);
      
      // Initialize driver position at pickup (or slightly offset for demo)
      _driverCurrentPosition = pickup;
      
      // Generate route points from current position to destination
      // In production, you'd use a routing service like OSRM or Mapbox
      _updateRoutePoints();
      
      // Center map on route - only if map is ready
      if (_isMapReady) {
        final center = _centerPoint(pickup, destination);
        _mapController.move(center, 15.0);
      }
    }
  }

  void _onMapReady() {
    setState(() {
      _isMapReady = true;
    });
    
    // Center map on pickup/destination center when ready
    if (_currentRide != null && 
        _currentRide!.pickupLocation != null && 
        _currentRide!.dropoffLocation != null) {
      final pickup = LatLng(
        _currentRide!.pickupLocation!.lat,
        _currentRide!.pickupLocation!.lng,
      );
      final destination = LatLng(
        _currentRide!.dropoffLocation!.lat,
        _currentRide!.dropoffLocation!.lng,
      );
      final center = _centerPoint(pickup, destination);
      _mapController.move(center, 13.0);
      
      // Start location updates if ride is already started but updates haven't started yet
      if (_isRideStarted && _locationUpdateTimer == null) {
        _startLocationUpdates();
      }
    }
  }

  void _updateRoutePoints() {
    if (_currentRide != null && 
        _currentRide!.dropoffLocation != null && 
        _driverCurrentPosition != null) {
      final destination = LatLng(
        _currentRide!.dropoffLocation!.lat,
        _currentRide!.dropoffLocation!.lng,
      );
      _routePoints = _generateRoutePoints(_driverCurrentPosition!, destination);
    }
  }

  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    // Generate route points with interpolation - moved to isolate-compatible format
    // Use smaller number of points to reduce computation overhead
    final points = <LatLng>[];
    const numPoints = 30; // Reduced from 50 to improve performance
    
    // Defer heavy computation to next frame to avoid blocking
    final startLat = start.latitude;
    final startLng = start.longitude;
    final latDiff = end.latitude - startLat;
    final lngDiff = end.longitude - startLng;
    
    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      points.add(LatLng(
        startLat + latDiff * t,
        startLng + lngDiff * t,
      ));
    }
    
    return points;
  }

  LatLng _centerPoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }

  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    
    // Update every 7 seconds to move the vehicle along the route
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted || !_isRideStarted || _routePoints.isEmpty || 
          _currentRide == null || _driverCurrentPosition == null) {
        if (!mounted || !_isRideStarted) {
          timer.cancel();
        }
        return;
      }
      
      // Directly update position without deferring
      _updateDriverPosition();
    });
  }
  
  void _updateDriverPosition() {
    if (!mounted || !_isRideStarted || _routePoints.isEmpty || 
        _currentRide == null || _driverCurrentPosition == null) {
      return;
    }
    
    final destination = LatLng(
      _currentRide!.dropoffLocation!.lat,
      _currentRide!.dropoffLocation!.lng,
    );
    
    // Check if we've reached the destination (within 5 meters)
    final latDiff = (destination.latitude - _driverCurrentPosition!.latitude).abs();
    final lngDiff = (destination.longitude - _driverCurrentPosition!.longitude).abs();
    final approxDistanceKm = (latDiff + lngDiff) * 111.0;
    
    if (approxDistanceKm < 0.005) { // ~5 meters threshold - reached destination
      _locationUpdateTimer?.cancel();
      return;
    }
    
    // Move to the next point in the route
    // Calculate how many points to advance (approximately 1 point per update for smooth movement)
    // With 30 points total and 7 second intervals, this provides good movement
    int nextIndex = _currentRouteIndex + 1;
    
    if (nextIndex >= _routePoints.length) {
      // Reached the end of the route, move to destination
      nextIndex = _routePoints.length - 1;
    }
    
    final newPosition = _routePoints[nextIndex];
    
    // Update state
    if (mounted) {
      setState(() {
        _driverCurrentPosition = newPosition;
        _currentRouteIndex = nextIndex;
      });
      
      // Update map center to follow the vehicle
      if (_isMapReady && _driverCurrentPosition != null) {
        try {
          _mapController.move(_driverCurrentPosition!, _mapController.camera.zoom);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Map update error: $e');
          }
        }
      }
    }
  }

  // Optimized distance calculation with early exit for nearby points
  double _calculateDistance(LatLng point1, LatLng point2) {
    // Fast approximation check first - if points are very close, use simple calculation
    final latDiff = (point2.latitude - point1.latitude).abs();
    final lngDiff = (point2.longitude - point1.longitude).abs();
    
    // For very small distances, use simplified calculation (faster)
    if (latDiff < 0.001 && lngDiff < 0.001) {
      // Rough approximation for nearby points (good enough for movement simulation)
      return (latDiff + lngDiff) * 111.0;
    }
    
    // Full Haversine formula for accurate distances
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(point2.latitude - point1.latitude);
    final double dLon = _toRadians(point2.longitude - point1.longitude);
    
    // Pre-calculate radians to avoid repeated conversions
    final lat1Rad = _toRadians(point1.latitude);
    final lat2Rad = _toRadians(point2.latitude);
    
    final double sinDlatHalf = math.sin(dLat / 2);
    final double sinDlonHalf = math.sin(dLon / 2);
    final double a = sinDlatHalf * sinDlatHalf +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        sinDlonHalf * sinDlonHalf;
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);
    
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - 
              math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    
    final bearing = math.atan2(y, x);
    return _toDegrees(bearing);
  }

  LatLng _movePosition(LatLng from, double bearing, double distanceKm) {
    const double earthRadiusKm = 6371.0;
    final lat1 = _toRadians(from.latitude);
    final lon1 = _toRadians(from.longitude);
    final bearingRad = _toRadians(bearing);
    
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(distanceKm / earthRadiusKm) +
      math.cos(lat1) * math.sin(distanceKm / earthRadiusKm) * math.cos(bearingRad),
    );
    
    final lon2 = lon1 + math.atan2(
      math.sin(bearingRad) * math.sin(distanceKm / earthRadiusKm) * math.cos(lat1),
      math.cos(distanceKm / earthRadiusKm) - math.sin(lat1) * math.sin(lat2),
    );
    
    return LatLng(_toDegrees(lat2), _toDegrees(lon2));
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
  double _toDegrees(double radians) => radians * (180.0 / math.pi);

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _currentRide == null || 
          _currentRide!.pickupLocation == null || 
          _currentRide!.dropoffLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading ride data...'),
                ],
              ),
            )
          : _buildMapContent(theme, colorScheme),
    );
  }

  Widget _buildMapContent(ThemeData theme, ColorScheme colorScheme) {
    final pickup = LatLng(
      _currentRide!.pickupLocation!.lat,
      _currentRide!.pickupLocation!.lng,
    );
    final destination = LatLng(
      _currentRide!.dropoffLocation!.lat,
      _currentRide!.dropoffLocation!.lng,
    );

    // Calculate remaining distance and ETA - use cached values when possible
    double remainingDistance;
    if (_driverCurrentPosition != null) {
      // Use fast approximation for UI display (updated less frequently)
      final latDiff = (destination.latitude - _driverCurrentPosition!.latitude).abs();
      final lngDiff = (destination.longitude - _driverCurrentPosition!.longitude).abs();
      remainingDistance = (latDiff + lngDiff) * 111.0; // Fast approximation
    } else {
      remainingDistance = _currentRide!.distanceKm ?? 0.0;
    }
    final estimatedTime = (remainingDistance / 30 * 60).round(); // Assuming 30 km/h average speed

    return Stack(
            children: [
              // Map - Optimized for performance
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: pickup, // Center on pickup/destination center initially
                  initialZoom: 13.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onMapReady: _onMapReady,
                  onTap: _onMapTap, // Map tap handler (no longer used, kept for compatibility)
                  // Reduce interaction overhead
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.taximo.mobile',
                    // Optimize tile loading to reduce CPU usage
                    maxNativeZoom: 18,
                    maxZoom: 18,
                  ),
                  // Route polyline (shown when ride is active)
                  if (_isRideStarted && _routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      // Destination marker
                      Marker(
                        point: destination,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      // Driver/Vehicle marker
                      if (_driverCurrentPosition != null)
                        Marker(
                          point: _driverCurrentPosition!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.local_taxi,
                            color: Colors.blue,
                            size: 36,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // Overlay message removed - driver position is automatically set at pickup location
              // Bottom panel with ride info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Ride info row (always shown since ride is already started)
                        if (_isRideStarted) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                icon: Icons.straighten,
                                label: 'Distance',
                                value: '${remainingDistance.toStringAsFixed(1)} km',
                              ),
                              _buildInfoItem(
                                icon: Icons.access_time,
                                label: 'ETA',
                                value: '$estimatedTime min',
                              ),
                              _buildInfoItem(
                                icon: Icons.attach_money,
                                label: 'Price',
                                value: _currentRide!.formattedPrice,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Finish Ride button
                          ElevatedButton.icon(
                            onPressed: () {
                              // Use existing ride completion service/method
                              try {
                                final activeRidesProvider = Provider.of<ActiveRidesProvider>(context, listen: false);
                                _handleFinishRide(context, activeRidesProvider);
                              } catch (e) {
                                // If provider is not available, show error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          icon: const Icon(Icons.check_circle),
                          label: const Text(
                            'FINISH RIDE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.deepPurple),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _handleFinishRide(
    BuildContext context,
    ActiveRidesProvider provider,
  ) async {
    if (_currentRide == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Ride'),
        content: const Text('Are you sure you want to finish the ride?'),
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
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.completeRide(_currentRide!.rideId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to driver home
          Navigator.pushNamedAndRemoveUntil(context, '/driver-home', (route) => false);
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

