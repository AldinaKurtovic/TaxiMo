import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideRouteDto {
  final LatLng pickup;
  final LatLng destination;
  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> polylinePoints;
  final double fareEstimate;
  final double distanceKm;
  final int durationMin;

  const RideRouteDto({
    required this.pickup,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylinePoints,
    required this.fareEstimate,
    required this.distanceKm,
    required this.durationMin,
  });
}


