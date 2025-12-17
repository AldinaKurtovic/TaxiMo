import 'package:flutter/material.dart';

import '../models/ride_route_dto.dart';

class ChooseRideScreen extends StatelessWidget {
  const ChooseRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final route = args is RideRouteDto ? args : null;

    String formatDistance(int meters) => '${(meters / 1000).toStringAsFixed(1)} km';
    String formatDuration(int seconds) => '${(seconds / 60).round()} min';

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Ride')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: route == null
            ? const Text('No route data provided.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text('Pickup: ${route.pickup.latitude.toStringAsFixed(5)}, ${route.pickup.longitude.toStringAsFixed(5)}'),
                  const SizedBox(height: 6),
                  Text(
                    'Destination: ${route.destination.latitude.toStringAsFixed(5)}, ${route.destination.longitude.toStringAsFixed(5)}',
                  ),
                  const SizedBox(height: 12),
                  Text('Distance: ${formatDistance(route.distanceMeters)}'),
                  const SizedBox(height: 6),
                  Text('Duration: ${formatDuration(route.durationSeconds)}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Placeholder screen: you will choose a ride type here later (no driver selection on this step).',
                  ),
                ],
              ),
      ),
    );
  }
}


