import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationSelection { pickup, destination }

class RideReservationScreen extends StatefulWidget {
  const RideReservationScreen({super.key});

  @override
  State<RideReservationScreen> createState() => _RideReservationScreenState();
}

class _RideReservationScreenState extends State<RideReservationScreen> {
  static const LatLng _mostar = LatLng(43.3438, 17.8078);

  LocationSelection _selection = LocationSelection.pickup;
  LatLng? _pickup;
  LatLng? _destination;

  void _setSelection(LocationSelection selection) {
    setState(() => _selection = selection);
  }

  void _handleMapTap(LatLng position) {
    setState(() {
      if (_selection == LocationSelection.pickup) {
        _pickup = position;
      } else {
        _destination = position;
      }
    });
  }

  String _formatLatLng(LatLng? p, String placeholder) {
    if (p == null) return placeholder;
    return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final markers = <Marker>{
      if (_pickup != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      if (_destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };

    final canProceed = _pickup != null && _destination != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Reservation'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: _mostar, zoom: 13),
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              markers: markers,
              onTap: _handleMapTap,
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
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _QuickChip(label: 'Home', icon: Icons.bookmark),
                        _QuickChip(label: 'Office', icon: Icons.work_outline),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canProceed
                            ? () {
                                // UI-only for now
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

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _QuickChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () {},
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}


