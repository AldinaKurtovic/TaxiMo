import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';
import '../providers/notification_provider.dart';

class DriverAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const DriverAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Combine custom actions with notifications and logout button
    final allActions = [
      if (actions != null) ...actions!,
      _NotificationsButton(),
      _LogoutButton(),
    ];

    return AppBar(
      title: Text(title),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: allActions,
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DriverNotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;
        
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () {
                // Load notifications before navigating
                final driverProvider = Provider.of<DriverProvider>(context, listen: false);
                final driver = driverProvider.currentDriver;
                final driverProfile = driverProvider.driverProfile;
                final driverId = driverProfile?.driverId ?? driver?.driverId ?? 0;
                
                if (driverId > 0) {
                  notificationProvider.loadNotifications(driverId);
                }
                Navigator.pushNamed(context, '/driver-notifications');
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () {
        final driverProvider = Provider.of<DriverProvider>(context, listen: false);
        driverProvider.logout();
        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}

