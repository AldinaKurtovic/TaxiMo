import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/ride_model.dart';
import '../../../models/driver_model.dart';

/// A reusable map widget for the Admin Rides screen using OpenStreetMap.
/// 
/// Implements route-based taxi simulation matching ActiveRideDriverScreen behavior:
/// - ACTIVE rides: automatic simulation with moving taxi
/// - REQUESTED/ACCEPTED: markers + polyline, no taxi
/// - COMPLETED/CANCELLED: not rendered
class AdminMapWidget extends StatefulWidget {
  final List<RideModel> activeRides;
  final List<DriverModel> freeDrivers;
  final RideModel? selectedRide;
  final DriverModel? selectedDriver;
  final Function(RideModel)? onRideSelected;
  final Function(DriverModel)? onDriverSelected;

  const AdminMapWidget({
    super.key,
    required this.activeRides,
    required this.freeDrivers,
    this.selectedRide,
    this.selectedDriver,
    this.onRideSelected,
    this.onDriverSelected,
  });

  @override
  State<AdminMapWidget> createState() => _AdminMapWidgetState();
}

class _AdminMapWidgetState extends State<AdminMapWidget> {
  final MapController _mapController = MapController();
  Timer? _simulationTimer;
  bool _isMapReady = false;

  // Cache route polylines per ride
  final Map<int, List<LatLng>> _routePolylines = {};
  
  // Persist fixed simulation start time per ACTIVE ride (do NOT recalculate each tick)
  final Map<int, DateTime> _simulationStartTimes = {};

  // Mostar coordinates (center of the city)
  static const LatLng _mostarCenter = LatLng(43.3438, 17.8078);
  static const double _defaultZoom = 13.0;

  // Fixed simulated duration for rides (in seconds) - MUST match mobile app
  static const int _simulatedDurationSeconds = 120; // 2 minutes (120 seconds)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnMostar();
      _initializeRoutePolylines();
      _initializeSimulationStartTimes();
      _startSimulationTimer();
    });
  }

  @override
  void didUpdateWidget(AdminMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Rebuild polylines if rides changed or selected ride changed
    if (widget.activeRides != oldWidget.activeRides || 
        widget.selectedRide != oldWidget.selectedRide) {
      _initializeRoutePolylines();
      _initializeSimulationStartTimes();
    }
    
    // Center on selected ride when it changes
    if (widget.selectedRide != oldWidget.selectedRide && widget.selectedRide != null) {
      _centerOnRide(widget.selectedRide!);
    } 
    // Center on selected driver when it changes
    else if (widget.selectedDriver != oldWidget.selectedDriver && widget.selectedDriver != null) {
      _centerOnDriver(widget.selectedDriver!);
    }
    // If selected ride is cleared, center back on Mostar
    else if (oldWidget.selectedRide != null && widget.selectedRide == null) {
      _centerOnMostar();
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _startSimulationTimer() {
    // Update simulation every 3-5 seconds (using 4 seconds for balance)
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        // CRITICAL: setState() must be called inside timer to trigger rebuild
        setState(() {
          // Trigger rebuild to recalculate taxi positions
          // This will call _getTaxiPositionFromPolyline() which uses persisted start times
        });
      }
    });
  }

  void _initializeRoutePolylines() {
    _routePolylines.clear();
    
    // Get rides to display (only selected ride if selected, otherwise all active rides)
    final ridesToDisplay = _getRidesToDisplay();
    
    // Generate route polylines for all rides that need them
    for (final ride in ridesToDisplay) {
      final statusLower = ride.status.toLowerCase();
      
      // Generate polylines for active, accepted, requested, or completed rides
      if (statusLower == 'active' || statusLower == 'accepted' || statusLower == 'requested' || statusLower == 'completed') {
        if (ride.pickupLocationLat != null && 
            ride.pickupLocationLng != null &&
            ride.dropoffLocationLat != null &&
            ride.dropoffLocationLng != null) {
          final pickup = LatLng(ride.pickupLocationLat!, ride.pickupLocationLng!);
          final dropoff = LatLng(ride.dropoffLocationLat!, ride.dropoffLocationLng!);
          final polyline = _generateRoutePoints(pickup, dropoff);
          _routePolylines[ride.rideId] = polyline;
          
          // Verify polyline length > 2
          assert(polyline.length > 2, 'Polyline for ride ${ride.rideId} must have length > 2, got ${polyline.length}');
        }
      }
    }
  }
  
  /// Initialize simulation start times for ACTIVE rides
  /// Persists a fixed start time per ride (do NOT recalculate each tick)
  /// CRITICAL: Always starts from "now" - NEVER uses backend ride.startedAt
  void _initializeSimulationStartTimes() {
    final now = DateTime.now();
    
    // Get rides to display (only selected ride if selected, otherwise all active rides)
    final ridesToDisplay = _getRidesToDisplay();
    
    // Remove start times for rides that are no longer displayed
    final displayedRideIds = ridesToDisplay.map((r) => r.rideId).toSet();
    _simulationStartTimes.removeWhere((rideId, _) => !displayedRideIds.contains(rideId));
    
    for (final ride in ridesToDisplay) {
      final statusLower = ride.status.toLowerCase();
      
      // Only initialize start time for ACTIVE rides
      if (statusLower == 'active') {
        // Use putIfAbsent to initialize ONLY ONCE per ride
        // ALWAYS use current time - NEVER use ride.startedAt from backend
        _simulationStartTimes.putIfAbsent(
          ride.rideId,
          () {
            debugPrint('AdminMap: Initialized simulation start time for ride ${ride.rideId}: $now');
            return now; // 👈 ALWAYS start simulation from "now"
          },
        );
      } else {
        // Remove start time for non-active rides
        _simulationStartTimes.remove(ride.rideId);
      }
    }
  }

  /// Generate route polyline points (50 points) - EXACTLY like mobile app
  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const numPoints = 50;
    
    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }

  /// Get taxi position from polyline based on time-based progress
  /// Uses ONLY persisted local start time (NEVER uses backend ride.startedAt)
  /// For ACTIVE rides: simulation starts IMMEDIATELY from pickup point
  LatLng? _getTaxiPositionFromPolyline(RideModel ride) {
    final polyline = _routePolylines[ride.rideId];
    if (polyline == null || polyline.isEmpty) {
      return null;
    }
    
    // Verify polyline length > 2
    if (polyline.length <= 2) {
      return polyline.first;
    }
    
    // Use ONLY persisted local simulation start time (NEVER use ride.startedAt from backend)
    final startTime = _simulationStartTimes[ride.rideId];
    if (startTime == null) {
      // If no persisted start time, position taxi at pickup (first point)
      return polyline.first;
    }
    
    // Calculate elapsed time from persisted local start time
    final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
    
    // Use fixed simulated duration (MUST match mobile app: 120 seconds = 2 minutes)
    const simulatedDurationSeconds = _simulatedDurationSeconds;
    
    // Calculate progress (0.0 to 1.0)
    final progress = (elapsedSeconds / simulatedDurationSeconds).clamp(0.0, 1.0);
    
    // Calculate index in polyline
    final index = (progress * (polyline.length - 1))
        .floor()
        .clamp(0, polyline.length - 1);
    
    return polyline[index];
  }

  void _centerOnMostar() {
    if (_isMapReady) {
      _mapController.move(_mostarCenter, _defaultZoom);
    }
  }

  void _centerOnRide(RideModel ride) {
    if (!_isMapReady) return;

    // Center on pickup location if available
    if (ride.pickupLocationLat != null && ride.pickupLocationLng != null) {
      final pickup = LatLng(ride.pickupLocationLat!, ride.pickupLocationLng!);
      
      // If dropoff is also available, center between pickup and dropoff
      if (ride.dropoffLocationLat != null && ride.dropoffLocationLng != null) {
        final dropoff = LatLng(ride.dropoffLocationLat!, ride.dropoffLocationLng!);
        final center = _centerPoint(pickup, dropoff);
        _mapController.move(center, 13.0);
      } else {
        _mapController.move(pickup, 15.0);
      }
    }
  }

  void _centerOnDriver(DriverModel driver) {
    if (!_isMapReady) return;

    if (driver.currentLatitude != null && driver.currentLongitude != null) {
      final position = LatLng(driver.currentLatitude!, driver.currentLongitude!);
      _mapController.move(position, 15.0);
    } else {
      _centerOnMostar();
    }
  }

  LatLng _centerPoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }

  void _onMapReady() {
    setState(() {
      _isMapReady = true;
    });
    _centerOnMostar();
  }

  /// Get all rides to display
  /// If a ride is selected, show ONLY that ride (regardless of status)
  /// Otherwise, show only ACTIVE rides (for simulation)
  List<RideModel> _getRidesToDisplay() {
    // If a ride is selected, show ONLY that ride (not all active rides)
    // Show selected ride regardless of status (active, accepted, requested, or completed)
    if (widget.selectedRide != null) {
      return [widget.selectedRide!];
    }
    
    // If no ride is selected, show only ACTIVE rides (for simulation)
    // Filter to show only rides with status "active" (not accepted or requested)
    return widget.activeRides
        .where((ride) => ride.status.toLowerCase() == 'active')
        .toList();
  }

  /// Build polylines for rides that should show routes
  List<Polyline> _buildPolylines() {
    final List<Polyline> polylines = [];
    final ridesToDisplay = _getRidesToDisplay();

    for (final ride in ridesToDisplay) {
      final statusLower = ride.status.toLowerCase();
      
      // Show polyline for active, accepted, requested, or completed rides
      if (statusLower == 'active' || statusLower == 'accepted' || statusLower == 'requested' || statusLower == 'completed') {
        final polyline = _routePolylines[ride.rideId];
        if (polyline != null && polyline.isNotEmpty) {
          final isSelected = widget.selectedRide?.rideId == ride.rideId;
          // Use different color for completed rides
          final color = statusLower == 'completed' ? Colors.grey : Colors.blue;
          polylines.add(
            Polyline(
              points: polyline,
              strokeWidth: isSelected ? 5 : 4,
              color: color,
            ),
          );
        }
      }
    }

    return polylines;
  }

  /// Build markers for rides and drivers
  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    final ridesToDisplay = _getRidesToDisplay();

    for (final ride in ridesToDisplay) {
      final statusLower = ride.status.toLowerCase();
      final isSelected = widget.selectedRide?.rideId == ride.rideId;
      
      // REQUESTED / ACCEPTED: Show pickup + destination markers, NO taxi
      if (statusLower == 'requested' || statusLower == 'accepted') {
        // Pickup location marker (green)
        if (ride.pickupLocationLat != null && ride.pickupLocationLng != null) {
          markers.add(
            Marker(
              point: LatLng(ride.pickupLocationLat!, ride.pickupLocationLng!),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onRideSelected?.call(ride),
                child: Icon(
                  Icons.radio_button_checked,
                  color: Colors.green,
                  size: isSelected ? 50 : 40,
                ),
              ),
            ),
          );
        }

        // Dropoff location marker (red)
        if (ride.dropoffLocationLat != null && ride.dropoffLocationLng != null) {
          markers.add(
            Marker(
              point: LatLng(ride.dropoffLocationLat!, ride.dropoffLocationLng!),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onRideSelected?.call(ride),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: isSelected ? 50 : 40,
                ),
              ),
            ),
          );
        }
      }
      
      // ACTIVE: Show pickup + destination markers + MOVING taxi
      else if (statusLower == 'active') {
        // Pickup location marker (green)
        if (ride.pickupLocationLat != null && ride.pickupLocationLng != null) {
          markers.add(
            Marker(
              point: LatLng(ride.pickupLocationLat!, ride.pickupLocationLng!),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onRideSelected?.call(ride),
                child: Icon(
                  Icons.radio_button_checked,
                  color: Colors.green,
                  size: isSelected ? 50 : 40,
                ),
              ),
            ),
          );
        }

        // Dropoff location marker (red)
        if (ride.dropoffLocationLat != null && ride.dropoffLocationLng != null) {
          markers.add(
            Marker(
              point: LatLng(ride.dropoffLocationLat!, ride.dropoffLocationLng!),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onRideSelected?.call(ride),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: isSelected ? 50 : 40,
                ),
              ),
            ),
          );
        }

        // Taxi marker (blue) - MOVING based on time-based simulation
        final taxiPosition = _getTaxiPositionFromPolyline(ride);
        if (taxiPosition != null) {
          markers.add(
            Marker(
              point: taxiPosition,
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onRideSelected?.call(ride),
                child: Icon(
                  Icons.local_taxi,
                  color: Colors.blue,
                  size: isSelected ? 50 : 40,
                ),
              ),
            ),
          );
        }
      }
      
      // COMPLETED: Show pickup + destination markers (grey), NO taxi
      else if (statusLower == 'completed') {
        // Pickup location marker (grey)
        if (ride.pickupLocationLat != null && ride.pickupLocationLng != null) {
          markers.add(
            Marker(
              point: LatLng(ride.pickupLocationLat!, ride.pickupLocationLng!),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onRideSelected?.call(ride),
                child: Icon(
                  Icons.radio_button_checked,
                  color: Colors.grey,
                  size: isSelected ? 50 : 40,
                ),
              ),
            ),
          );
        }

        // Dropoff location marker (grey)
        if (ride.dropoffLocationLat != null && ride.dropoffLocationLng != null) {
          markers.add(
            Marker(
              point: LatLng(ride.dropoffLocationLat!, ride.dropoffLocationLng!),
              width: isSelected ? 50 : 40,
              height: isSelected ? 50 : 40,
              child: GestureDetector(
                onTap: () => widget.onRideSelected?.call(ride),
                child: Icon(
                  Icons.location_on,
                  color: Colors.grey,
                  size: isSelected ? 50 : 40,
                ),
              ),
            ),
          );
        }
      }
      
      // CANCELLED: Show NOTHING (do not add markers)
    }

    // Add markers for free drivers (blue taxi icons) - only show when no ride is selected
    if (widget.selectedRide == null) {
    for (final driver in widget.freeDrivers) {
      if (driver.currentLatitude != null && driver.currentLongitude != null) {
        final isSelected = widget.selectedDriver?.driverId == driver.driverId;
        final position = LatLng(driver.currentLatitude!, driver.currentLongitude!);
        
        markers.add(
          Marker(
            point: position,
            width: isSelected ? 50 : 40,
            height: isSelected ? 50 : 40,
            child: GestureDetector(
              onTap: () => widget.onDriverSelected?.call(driver),
              child: Icon(
                Icons.local_taxi,
                color: Colors.blue,
                size: isSelected ? 50 : 40,
              ),
            ),
          ),
        );
        }
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mostarCenter,
            initialZoom: _defaultZoom,
            minZoom: 5.0,
            maxZoom: 18.0,
            onMapReady: _onMapReady,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.taximo.admin',
            ),
            // Route polylines
            PolylineLayer(
              polylines: _buildPolylines(),
            ),
            // Markers (pickup, dropoff, taxi, free drivers)
            MarkerLayer(
              markers: _buildMarkers(),
            ),
          ],
        ),
      ),
    );
  }
}
