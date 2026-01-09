import 'package:flutter/material.dart';
import '../../config/api_config.dart';

/// Reusable widget for displaying driver avatar images in driver app
/// Handles photo URL construction, default avatar fallback, and error states
class DriverAvatar extends StatefulWidget {
  final String? photoUrl;
  final String firstName;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const DriverAvatar({
    super.key,
    this.photoUrl,
    required this.firstName,
    this.radius = 30,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  State<DriverAvatar> createState() => _DriverAvatarState();
}

class _DriverAvatarState extends State<DriverAvatar> {
  bool _imageError = false;
  String? _previousPhotoUrl;

  /// Builds the image URL from the backend base URL and photoUrl
  String? _buildImageUrl() {
    if (widget.photoUrl == null || widget.photoUrl!.isEmpty) {
      return null;
    }
    // Remove leading slash if present to avoid double slashes
    final cleanUrl = widget.photoUrl!.startsWith('/') 
        ? widget.photoUrl!.substring(1) 
        : widget.photoUrl!;
    return '${ApiConfig.baseUrl}/$cleanUrl';
  }

  @override
  void didUpdateWidget(DriverAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state if photoUrl changes
    if (widget.photoUrl != oldWidget.photoUrl) {
      _imageError = false;
      _previousPhotoUrl = widget.photoUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = widget.backgroundColor ?? colorScheme.primaryContainer;
    final fgColor = widget.foregroundColor ?? colorScheme.onPrimaryContainer;
    
    final imageUrl = _buildImageUrl();
    final initial = widget.firstName.isNotEmpty 
        ? widget.firstName[0].toUpperCase() 
        : 'D';

    Widget avatarWidget;

    // If we have an image URL and no error, show the photo ONLY (no initial letter)
    if (imageUrl != null && imageUrl.isNotEmpty && !_imageError) {
      avatarWidget = ClipOval(
        child: Image.network(
          imageUrl,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Image failed to load - set error state and show fallback initial
            if (mounted && !_imageError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _imageError = true;
                  });
                }
              });
            }
            // Return fallback immediately - will be clipped to circle by parent ClipOval
            return Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              color: bgColor,
              child: Center(
                child: Text(
                  initial,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            // Show loading indicator while image loads
            return Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              color: bgColor,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // If no image URL or image error, use CircleAvatar with child (initial letter)
      avatarWidget = CircleAvatar(
        radius: widget.radius,
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

    // If onTap is provided or showEditIcon is true, wrap in GestureDetector/Stack
    if (widget.onTap != null || widget.showEditIcon) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: avatarWidget,
          ),
          if (widget.showEditIcon || widget.onTap != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.camera_alt,
                  size: widget.radius * 0.4,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    return avatarWidget;
  }
}

