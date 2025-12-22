import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/ride_route_dto.dart';
import '../models/driver_dto.dart';
import '../models/promo_code_dto.dart';
import '../models/ride_request_dto.dart';
import '../services/driver_service.dart';
import '../services/ride_service.dart';
import '../../auth/providers/mobile_auth_provider.dart';

class ChooseRideScreen extends StatefulWidget {
  const ChooseRideScreen({super.key});

  @override
  State<ChooseRideScreen> createState() => _ChooseRideScreenState();
}

class _ChooseRideScreenState extends State<ChooseRideScreen> {
  int? _selectedDriverId;
  List<DriverDto>? _drivers;
  final DriverService _driverService = DriverService();
  final RideService _rideService = RideService();
  late final Future<List<DriverDto>> _driversFuture;
  PromoCodeDto? _selectedPromoCode;
  bool _isNavigating = false;

  String _formatDistance(int meters) => '${(meters / 1000).toStringAsFixed(1)} km';
  String _formatDuration(int seconds) => '${(seconds / 60).round()} min';

  // Default values for UI (not in API response)
  int _getCapacity(DriverDto driver) => 3; // Default capacity

  double _calculateFinalPrice(double fareEstimate, PromoCodeDto? promoCode) {
    if (promoCode == null) {
      return fareEstimate;
    }

    double discount = 0;
    if (promoCode.isPercentage) {
      discount = fareEstimate * (promoCode.discountValue / 100);
    } else {
      discount = promoCode.discountValue;
    }

    final finalPrice = fareEstimate - discount;
    return finalPrice < 0 ? 0 : finalPrice;
  }

  Future<void> _navigateToPayment(RideRouteDto route) async {
    if (_selectedDriverId == null) {
      return;
    }

    final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book a ride'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      final finalPrice = _calculateFinalPrice(route.fareEstimate, _selectedPromoCode);

      // Navigate to PaymentScreen with ride booking data
      // Ride will be created when user selects payment method
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'riderId': currentUser.userId,
          'driverId': _selectedDriverId!,
          'pickupLocation': {
            'name': 'Pickup Location',
            'addressLine': 'Pickup Address',
            'city': 'Mostar',
            'lat': route.pickup.latitude,
            'lng': route.pickup.longitude,
          },
          'dropoffLocation': {
            'name': 'Destination',
            'addressLine': 'Destination Address',
            'city': 'Mostar',
            'lat': route.destination.latitude,
            'lng': route.destination.longitude,
          },
          'distanceKm': route.distanceKm,
          'durationMin': route.durationMin,
          'fareEstimate': route.fareEstimate,
          'fareFinal': finalPrice,
          'promoCodeId': _selectedPromoCode?.promoId,
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to proceed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _driversFuture = _fetchDrivers();
  }

  Future<List<DriverDto>> _fetchDrivers() async {
    final drivers = await _driverService.getAvailableDrivers();
    if (mounted) {
      setState(() {
        _drivers = drivers;
      });
    }
    return drivers;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final route = args is RideRouteDto ? args : null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (route == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose Ride')),
        body: const Center(child: Text('No route data provided.')),
      );
    }

    // Calculate bounds for map preview
    final bounds = _calculateBounds(route.pickup, route.destination, route.polylinePoints);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your ride'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map preview section
          Container(
            height: 200,
            color: colorScheme.surfaceContainerHighest,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _centerPoint(route.pickup, route.destination),
                    zoom: _calculateZoom(bounds),
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('pickup'),
                      position: route.pickup,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                    ),
                    Marker(
                      markerId: const MarkerId('destination'),
                      position: route.destination,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                  polylines: route.polylinePoints.isNotEmpty
                      ? {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: route.polylinePoints,
                            color: colorScheme.primary,
                            width: 4,
                          ),
                        }
                      : {},
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                ),
                // Distance and duration overlay
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatDuration(route.durationSeconds)} • ${_formatDistance(route.distanceMeters)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Driver list
          Expanded(
            child: Container(
              color: colorScheme.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'Choose your ride',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: colorScheme.onSurfaceVariant),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder<List<DriverDto>>(
                      future: _driversFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: colorScheme.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading drivers',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions_car_outlined,
                                    size: 48, color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 16),
                                Text(
                                  'No available drivers with vehicles nearby',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please try again later',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final drivers = snapshot.data!;
                        final finalPrice = _calculateFinalPrice(route.fareEstimate, _selectedPromoCode);
                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: drivers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final driver = drivers[index];
                            final isSelected = _selectedDriverId == driver.driverId;
                            return _DriverCard(
                              driver: driver,
                              isSelected: isSelected,
                              price: finalPrice,
                              originalPrice: _selectedPromoCode != null ? route.fareEstimate : null,
                              getCapacity: _getCapacity,
                              onTap: () {
                                setState(() {
                                  _selectedDriverId = isSelected ? null : driver.driverId;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom CTA button
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voucher row
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.pushNamed(context, '/voucher');
                      if (result is PromoCodeDto) {
                        setState(() {
                          _selectedPromoCode = result;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedPromoCode != null
                                  ? _selectedPromoCode!.code
                                  : 'Voucher',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_selectedPromoCode != null)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _selectedPromoCode = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Spacer(),
                      // Book button
                      Builder(
                        builder: (context) {
                          final finalPrice = _calculateFinalPrice(route.fareEstimate, _selectedPromoCode);
                          final hasDrivers = _drivers != null && _drivers!.isNotEmpty;
                          return FilledButton(
                            onPressed: (_selectedDriverId != null && !_isNavigating && hasDrivers)
                                ? () => _navigateToPayment(route)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _isNavigating
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Book this car',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (_selectedPromoCode != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${route.fareEstimate.toStringAsFixed(2)}',
                                              style: theme.textTheme.labelLarge?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black54,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                        ),
                                      Text(
                                        '${finalPrice.toStringAsFixed(2)} KM',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LatLng _centerPoint(LatLng a, LatLng b) {
    return LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
  }

  Map<String, double> _calculateBounds(LatLng pickup, LatLng destination, List<LatLng> points) {
    final allPoints = [pickup, destination, ...points];
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (final point in allPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  double _calculateZoom(Map<String, double> bounds) {
    final latDiff = bounds['maxLat']! - bounds['minLat']!;
    final lngDiff = bounds['maxLng']! - bounds['minLng']!;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff > 0.1) return 11.0;
    if (maxDiff > 0.05) return 12.0;
    if (maxDiff > 0.01) return 13.0;
    return 14.0;
  }
}

class _DriverCard extends StatelessWidget {
  final DriverDto driver;
  final bool isSelected;
  final VoidCallback onTap;
  final double price;
  final double? originalPrice;
  final int Function(DriverDto) getCapacity;

  const _DriverCard({
    required this.driver,
    required this.isSelected,
    required this.onTap,
    required this.price,
    this.originalPrice,
    required this.getCapacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${getCapacity(driver) - 1}-${getCapacity(driver)} person',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (originalPrice != null)
                    Text(
                      '${originalPrice!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.6)
                            : colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    '${price.toStringAsFixed(2)} KM',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? colorScheme.onPrimaryContainer : null,
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
}


