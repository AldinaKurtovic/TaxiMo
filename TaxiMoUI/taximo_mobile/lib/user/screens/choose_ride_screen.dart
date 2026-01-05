import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  final DriverService _driverService = DriverService();
  final RideService _rideService = RideService();
  late final Future<List<DriverDto>> _driversFuture;
  PromoCodeDto? _selectedPromoCode;
  bool _isNavigating = false;
  
  // Cached route data
  RideRouteDto? _route;
  
  // Immutable map preview data
  _MapPreviewData? _mapPreviewData;

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
  
  void _cacheRouteData(RideRouteDto route) {
    final bounds = _calculateBounds(route.pickup, route.destination, route.polylinePoints);
    final center = _centerPoint(route.pickup, route.destination);
    final zoom = _calculateZoom(bounds);
    
    // Create immutable map preview data
    _mapPreviewData = _MapPreviewData(
      center: center,
      zoom: zoom,
      pickup: route.pickup,
      destination: route.destination,
      polylinePoints: List.unmodifiable(route.polylinePoints),
      durationSeconds: route.durationSeconds,
      distanceMeters: route.distanceMeters,
    );
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
    _driversFuture = _driverService.getAvailableDrivers();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_route == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is RideRouteDto) {
        _route = args;
        _cacheRouteData(_route!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_route == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose Ride')),
        body: const Center(child: Text('No route data provided.')),
      );
    }

    final route = _route!;

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
          if (_mapPreviewData != null)
            _RouteMapPreview(
              mapData: _mapPreviewData!,
              formatDuration: _formatDuration,
              formatDistance: _formatDistance,
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
                        return _DriverList(
                          drivers: drivers,
                          selectedDriverId: _selectedDriverId,
                          route: route,
                          selectedPromoCode: _selectedPromoCode,
                          calculateFinalPrice: _calculateFinalPrice,
                          getCapacity: _getCapacity,
                          onDriverSelected: (driverId) {
                            setState(() {
                              _selectedDriverId = _selectedDriverId == driverId ? null : driverId;
                            });
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
                      if (result is PromoCodeDto && mounted) {
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
                                if (!mounted) return;
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
                      FutureBuilder<List<DriverDto>>(
                        future: _driversFuture,
                        builder: (context, snapshot) {
                          final hasDrivers = snapshot.hasData && snapshot.data!.isNotEmpty;
                          final finalPrice = _calculateFinalPrice(route.fareEstimate, _selectedPromoCode);
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

}

// Immutable map preview data
class _MapPreviewData {
  final LatLng center;
  final double zoom;
  final LatLng pickup;
  final LatLng destination;
  final List<LatLng> polylinePoints;
  final int durationSeconds;
  final int distanceMeters;

  const _MapPreviewData({
    required this.center,
    required this.zoom,
    required this.pickup,
    required this.destination,
    required this.polylinePoints,
    required this.durationSeconds,
    required this.distanceMeters,
  });
}

// Extracted FlutterMap widget to prevent unnecessary rebuilds
class _RouteMapPreview extends StatelessWidget {
  final _MapPreviewData mapData;
  final String Function(int) formatDuration;
  final String Function(int) formatDistance;

  const _RouteMapPreview({
    required this.mapData,
    required this.formatDuration,
    required this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 200,
      color: colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: mapData.center,
              initialZoom: mapData.zoom,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taximo.mobile',
              ),
              if (mapData.polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapData.polylinePoints,
                      strokeWidth: 4,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: mapData.pickup,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.radio_button_checked,
                      color: colorScheme.primary,
                      size: 40,
                    ),
                  ),
                  Marker(
                    point: mapData.destination,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: colorScheme.error,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
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
                    '${formatDuration(mapData.durationSeconds)} • ${formatDistance(mapData.distanceMeters)}',
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
    );
  }
}

// Extracted driver list widget to prevent unnecessary rebuilds
class _DriverList extends StatelessWidget {
  final List<DriverDto> drivers;
  final int? selectedDriverId;
  final RideRouteDto route;
  final PromoCodeDto? selectedPromoCode;
  final double Function(double, PromoCodeDto?) calculateFinalPrice;
  final int Function(DriverDto) getCapacity;
  final void Function(int) onDriverSelected;

  const _DriverList({
    required this.drivers,
    required this.selectedDriverId,
    required this.route,
    required this.selectedPromoCode,
    required this.calculateFinalPrice,
    required this.getCapacity,
    required this.onDriverSelected,
  });

  @override
  Widget build(BuildContext context) {
    final finalPrice = calculateFinalPrice(route.fareEstimate, selectedPromoCode);
    
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: drivers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final driver = drivers[index];
        final isSelected = selectedDriverId == driver.driverId;
        return _DriverCard(
          key: ValueKey(driver.driverId),
          driver: driver,
          isSelected: isSelected,
          price: finalPrice,
          originalPrice: selectedPromoCode != null ? route.fareEstimate : null,
          getCapacity: getCapacity,
          onTap: () => onDriverSelected(driver.driverId),
        );
      },
    );
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
    super.key,
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


