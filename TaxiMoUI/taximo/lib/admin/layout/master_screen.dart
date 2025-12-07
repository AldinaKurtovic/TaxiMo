import 'package:flutter/material.dart';
import '../screens/users/users_screen.dart';

class MasterScreen extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const MasterScreen({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          Container(
            width: 250,
            color: const Color(0xFF1E1E2E),
            child: Column(
              children: [
                // Logo/Title
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: const Text(
                    'TaxiMo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.grey, height: 1),
                // Navigation Menu
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(
                        icon: Icons.home_outlined,
                        title: 'HOME PAGE',
                        route: '/home',
                        isSelected: widget.currentRoute == '/home',
                      ),
                      _buildNavItem(
                        icon: Icons.people_outline,
                        title: 'USERS',
                        route: '/users',
                        isSelected: widget.currentRoute == '/users',
                      ),
                      _buildNavItem(
                        icon: Icons.drive_eta_outlined,
                        title: 'DRIVERS',
                        route: '/drivers',
                        isSelected: widget.currentRoute == '/drivers',
                      ),
                      _buildNavItem(
                        icon: Icons.local_taxi_outlined,
                        title: 'RIDES',
                        route: '/rides',
                        isSelected: widget.currentRoute == '/rides',
                      ),
                      _buildNavItem(
                        icon: Icons.star_outline,
                        title: 'REVIEWS',
                        route: '/reviews',
                        isSelected: widget.currentRoute == '/reviews',
                      ),
                      _buildNavItem(
                        icon: Icons.access_time_outlined,
                        title: 'STATISTICS',
                        route: '/statistics',
                        isSelected: widget.currentRoute == '/statistics',
                      ),
                      _buildNavItem(
                        icon: Icons.percent_outlined,
                        title: 'PROMO CODES',
                        route: '/promo-codes',
                        isSelected: widget.currentRoute == '/promo-codes',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        child: const Row(
                          children: [
                            Text(
                              'Admin',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                        onSelected: (value) {
                          // Handle menu selection
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Text('Profile'),
                          ),
                          const PopupMenuItem(
                            value: 'settings',
                            child: Text('Settings'),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Text('Logout'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Page Content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        if (route == '/users') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MasterScreen(
                child: UsersScreen(),
                currentRoute: '/users',
              ),
            ),
          );
        } else {
          // TODO: Navigate to other routes
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title - Coming soon')),
          );
        }
      },
      child: Container(
        color: isSelected
            ? Colors.deepPurple.withOpacity(0.2)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.deepPurple : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

