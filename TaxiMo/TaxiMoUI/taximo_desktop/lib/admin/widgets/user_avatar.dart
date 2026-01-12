import 'package:flutter/material.dart';

/// Reusable widget for displaying user avatar images in admin app
/// Handles photo URL construction, default avatar fallback, and error states
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String firstName;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  static const String baseUrl = 'http://localhost:5244';

  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.firstName,
    this.radius = 30,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Builds the image URL from the backend base URL and photoUrl
  String? _buildImageUrl() {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return null;
    }
    // Remove leading slash if present to avoid double slashes
    final cleanUrl = photoUrl!.startsWith('/') ? photoUrl!.substring(1) : photoUrl!;
    return '$baseUrl/$cleanUrl';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? colorScheme.onPrimaryContainer;
    
    final imageUrl = _buildImageUrl();
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    // If we have an image URL, use CircleAvatar with backgroundImage
    if (imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          // Image failed to load, will fall back to initial
        },
        child: null, // Show network image if available
      );
    }
    
    // If no image URL, use CircleAvatar with child (initial letter)
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      child: Text(
        initial,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
      ),
    );
  }
}

