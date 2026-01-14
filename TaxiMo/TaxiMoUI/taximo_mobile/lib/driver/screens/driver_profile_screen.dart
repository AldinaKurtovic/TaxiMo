import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../providers/driver_profile_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'edit_driver_profile_screen.dart';
import 'change_driver_password_screen.dart';
import '../widgets/driver_avatar.dart';
import '../widgets/driver_app_bar.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load profile data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<DriverProfileProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      // Use current driver from driver provider if available, otherwise load
      if (driverProvider.currentDriver != null) {
        profileProvider.updateDriverFromAuth(driverProvider.currentDriver!);
      } else {
        profileProvider.loadProfile();
      }
    });
  }

  Future<void> _selectAndUploadPhoto() async {
    final profileProvider = Provider.of<DriverProfileProvider>(context, listen: false);
    
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from photo gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Files'),
                subtitle: const Text('Browse files on device'),
                onTap: () => Navigator.pop(context, ImageSource.gallery), // Use gallery for file picker too on Android
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) return;

      // Convert to File
      final File imageFile = File(pickedFile.path);

      // Upload photo
      final success = await profileProvider.uploadPhoto(imageFile);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Update driver provider if it has driver data
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        if (profileProvider.driverProfile != null) {
          driverProvider.currentDriver = profileProvider.driverProfile!;
        }
      } else if (mounted) {
        // Show error message
        final errorMessage = profileProvider.errorMessage ?? 'Failed to upload photo';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: DriverAppBar(title: 'My Profile'),
      body: Consumer2<DriverProfileProvider, DriverProvider>(
        builder: (context, profileProvider, driverProvider, child) {
          final driver = profileProvider.driverProfile ?? driverProvider.currentDriver;
          final profile = driverProvider.driverProfile;

          if (driver == null) {
            return Center(
              child: profileProvider.isLoading || driverProvider.isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileProvider.errorMessage ?? 'No driver data available',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            profileProvider.loadProfile();
                          },
                          child: const Text('Retry Load Profile'),
                        ),
                      ],
                    ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                // Profile Avatar with upload functionality
                Stack(
                  alignment: Alignment.center,
                  children: [
                    DriverAvatar(
                      photoUrl: driver.photoUrl,
                      firstName: driver.firstName,
                      radius: 60,
                      onTap: profileProvider.isUploadingPhoto ? null : _selectAndUploadPhoto,
                      showEditIcon: true,
                    ),
                    if (profileProvider.isUploadingPhoto)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Explicit "Edit profile picture" action
                TextButton.icon(
                  onPressed: profileProvider.isUploadingPhoto ? null : _selectAndUploadPhoto,
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: profileProvider.isUploadingPhoto 
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
                        : colorScheme.primary,
                  ),
                  label: Text(
                    'Edit profile picture',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: profileProvider.isUploadingPhoto
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
                          : colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(height: 8),

                // Driver Name
                Text(
                  driver.fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  driver.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Information Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: driver.fullName,
                        ),
                        const Divider(height: 32),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: driver.email,
                        ),
                        if (driver.phone != null && driver.phone!.isNotEmpty) ...[
                          const Divider(height: 32),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: driver.phone!,
                          ),
                        ],
                        if (profile != null) ...[
                          const Divider(height: 32),
                          _InfoRow(
                            icon: Icons.circle,
                            label: 'Status',
                            value: profile.isOnline ? 'Online' : 'Offline',
                            valueColor: profile.isOnline ? Colors.green : Colors.grey,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditDriverProfileScreen(),
                        ),
                      ).then((_) {
                        // Refresh profile after editing
                        profileProvider.loadProfile();
                        // Also refresh driver provider if it has driver data
                        if (profileProvider.driverProfile != null) {
                          driverProvider.currentDriver = profileProvider.driverProfile!;
                        }
                      });
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangeDriverPasswordScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_outlined),
                    label: const Text('Change Password'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

