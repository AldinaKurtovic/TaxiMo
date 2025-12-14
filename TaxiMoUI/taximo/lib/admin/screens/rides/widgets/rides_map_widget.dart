import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/ride_model.dart';
import '../../../models/driver_model.dart';
import '../../../providers/rides_provider.dart';
import 'desktop_map_placeholder.dart';

class RidesMapWidget extends StatefulWidget {
  final List<RideModel> rides;
  final List<DriverModel> freeDrivers;
  final RideFilter currentFilter;
  final RideModel? selectedRide;
  final DriverModel? selectedDriver;
  final Function(RideModel)? onRideSelected;
  final Function(DriverModel)? onDriverSelected;

  const RidesMapWidget({
    super.key,
    required this.rides,
    required this.freeDrivers,
    required this.currentFilter,
    this.selectedRide,
    this.selectedDriver,
    this.onRideSelected,
    this.onDriverSelected,
  });

  @override
  State<RidesMapWidget> createState() => _RidesMapWidgetState();
}

class _RidesMapWidgetState extends State<RidesMapWidget> {
  GoogleMapController? _mapController;
  
  // Mostar coordinates (center of the city)
  static const LatLng _mostarCenter = LatLng(43.3438, 17.8078);
  static const double _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnMostar();
    });
  }

  @override
  void didUpdateWidget(RidesMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedRide != oldWidget.selectedRide && widget.selectedRide != null) {
      _centerOnRide(widget.selectedRide!);
    } else if (widget.selectedDriver != oldWidget.selectedDriver && widget.selectedDriver != null) {
      // Center on free driver if coordinates available
      if (widget.selectedDriver!.currentLatitude != null && widget.selectedDriver!.currentLongitude != null) {
        final position = LatLng(widget.selectedDriver!.currentLatitude!, widget.selectedDriver!.currentLongitude!);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 15.0),
        );
      } else {
        _centerOnMostar();
      }
    } else if (widget.rides != oldWidget.rides || widget.freeDrivers != oldWidget.freeDrivers) {
      // Update markers when data changes
      setState(() {});
    }
  }

  void _centerOnMostar() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_mostarCenter, _defaultZoom),
    );
  }

  void _centerOnRide(RideModel ride) {
    if (ride.driverLatitude != null && ride.driverLongitude != null) {
      final position = LatLng(ride.driverLatitude!, ride.driverLongitude!);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15.0),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    // Add markers for active/accepted/requested rides
    if (widget.currentFilter != RideFilter.freeDrivers) {
      for (final ride in widget.rides) {
        final statusLower = ride.status.toLowerCase();
        
        // Only show markers for active, accepted, or requested rides
        if (statusLower == 'active' || statusLower == 'accepted' || statusLower == 'requested') {
          if (ride.driverLatitude != null && ride.driverLongitude != null) {
            final color = _getMarkerColorForStatus(ride.status);
            final isSelected = widget.selectedRide?.rideId == ride.rideId;
            
            final hue = _getMarkerHueForStatus(ride.status);
            markers.add(
              Marker(
                markerId: MarkerId('ride_${ride.rideId}'),
                position: LatLng(ride.driverLatitude!, ride.driverLongitude!),
                icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                infoWindow: InfoWindow(
                  title: ride.driverName,
                  snippet: '${ride.status.toUpperCase()} - ${ride.vehicleCode}',
                ),
                onTap: () {
                  if (widget.onRideSelected != null) {
                    widget.onRideSelected!(ride);
                  }
                },
              ),
            );
          }
        }
      }
    } else {
      // Add markers for free drivers
      for (final driver in widget.freeDrivers) {
        final vehicleCode = 'TX-${driver.driverId.toString().padLeft(3, '0')}';
        final isSelected = widget.selectedDriver?.driverId == driver.driverId;
        
        // Use coordinates from DriverAvailability if available
        if (driver.currentLatitude != null && driver.currentLongitude != null) {
          final position = LatLng(driver.currentLatitude!, driver.currentLongitude!);
          
          markers.add(
            Marker(
              markerId: MarkerId('driver_${driver.driverId}'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Blue for free drivers
              infoWindow: InfoWindow(
                title: driver.fullName,
                snippet: 'Free Driver - $vehicleCode',
              ),
              onTap: () {
                if (widget.onDriverSelected != null) {
                  widget.onDriverSelected!(driver);
                }
              },
            ),
          );
        }
      }
    }

    return markers;
  }

  double _getMarkerHueForStatus(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'active') {
      return BitmapDescriptor.hueGreen;
    } else if (statusLower == 'accepted') {
      return BitmapDescriptor.hueViolet; // Purple
    } else if (statusLower == 'requested') {
      return BitmapDescriptor.hueOrange;
    }
    return BitmapDescriptor.hueRed;
  }

  Color _getMarkerColorForStatus(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'active') {
      return Colors.green;
    } else if (statusLower == 'accepted') {
      return Colors.purple;
    } else if (statusLower == 'requested') {
      return Colors.orange;
    }
    return Colors.red;
  }

  bool get _isMapSupported {
    // Google Maps is supported on Web, Android, and iOS
    if (kIsWeb) return true;
    
    // Check target platform for mobile
    if (defaultTargetPlatform == TargetPlatform.android) return true;
    if (defaultTargetPlatform == TargetPlatform.iOS) return true;
    
    // Not supported on Windows, Linux, macOS desktop
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Show placeholder on unsupported platforms (Windows desktop)
    // This check happens FIRST to prevent any GoogleMap widget creation on Windows
    if (!_isMapSupported) {
      return const DesktopMapPlaceholder();
    }

    // Show Google Maps on supported platforms (Web, Android, iOS)
    // This code path is NEVER executed on Windows
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
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _mostarCenter,
            zoom: _defaultZoom,
          ),
          markers: _buildMarkers(),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          mapType: MapType.normal,
          zoomControlsEnabled: true,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

