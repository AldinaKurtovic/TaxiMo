import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ride_route_dto.dart';

enum LocationSelection { pickup, destination }

class RideReservationScreen extends StatefulWidget {
  const RideReservationScreen({super.key});

  @override
  State<RideReservationScreen> createState() => _RideReservationScreenState();
}

class _RideReservationScreenState extends State<RideReservationScreen> {
  static const LatLng _mostar = LatLng(43.3438, 17.8078);
  final MapController _mapController = MapController();

  LocationSelection _selection = LocationSelection.pickup;
  LatLng? _pickup;
  LatLng? _destination;

  void _setSelection(LocationSelection selection) {
    setState(() => _selection = selection);
  }

  String _formatLatLng(LatLng? p, String placeholder) {
    if (p == null) return placeholder;
    return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  // Calculate distance in kilometers using Haversine formula
  double _calculateDistanceKm(LatLng point1, LatLng point2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(point2.latitude - point1.latitude);
    final double dLon = _toRadians(point2.longitude - point1.longitude);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(point1.latitude)) * math.cos(_toRadians(point2.latitude)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final canProceed = _pickup != null && _destination != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Reservation'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mostar,
                initialZoom: 13.0,
                onTap: (tapPosition, latLng) {
                  setState(() {
                    if (_selection == LocationSelection.pickup) {
                      _pickup = latLng;
                    } else {
                      _destination = latLng;
                    }
                  });
                },
                minZoom: 5.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.taximo.mobile',
                ),
                MarkerLayer(
                  markers: [
                    if (_pickup != null)
                      Marker(
                        point: _pickup!,
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.radio_button_checked,
                          color: colorScheme.primary,
                          size: 40,
                        ),
                      ),
                    if (_destination != null)
                      Marker(
                        point: _destination!,
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
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Where are you going today?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LocationField(
                      leading: Icons.radio_button_checked,
                      leadingColor: colorScheme.primary,
                      text: _formatLatLng(_pickup, 'Choose pick up point'),
                      isSelected: _selection == LocationSelection.pickup,
                      onTap: () {
                        _setSelection(LocationSelection.pickup);
                      },
                    ),
                    const SizedBox(height: 10),
                    _LocationField(
                      leading: Icons.location_on,
                      leadingColor: colorScheme.error,
                      text: _formatLatLng(_destination, 'Choose your destination'),
                      isSelected: _selection == LocationSelection.destination,
                      onTap: () {
                        _setSelection(LocationSelection.destination);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canProceed
                            ? () {
                                // Calculate distance and duration from coordinates
                                final distanceKm = _calculateDistanceKm(_pickup!, _destination!);
                                final distanceMeters = (distanceKm * 1000).round();
                                
                                // Calculate duration based on distance (average city speed: 30 km/h)
                                // Formula: durationSeconds = round((distanceKm / 30) * 3600)
                                final durationSeconds = ((distanceKm / 30) * 3600).round();
                                final durationMin = (durationSeconds / 60).round();
                                
                                // Backend will recalculate fare, this is just for UI
                                final fareEstimate = (distanceKm * 1.0);
                                
                                Navigator.pushNamed(
                                  context,
                                  '/choose-ride',
                                  arguments: RideRouteDto(
                                    pickup: _pickup!,
                                    destination: _destination!,
                                    distanceMeters: distanceMeters,
                                    durationSeconds: durationSeconds,
                                    polylinePoints: [],
                                    fareEstimate: fareEstimate,
                                    distanceKm: distanceKm,
                                    durationMin: durationMin,
                                  ),
                                );
                              }
                            : null,
                        child: const Text('Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final IconData leading;
  final Color leadingColor;
  final String text;
  final bool isSelected;
  final VoidCallback? onTap;

  const _LocationField({
    required this.leading,
    required this.leadingColor,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(leading, color: leadingColor),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.chevron_right,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

