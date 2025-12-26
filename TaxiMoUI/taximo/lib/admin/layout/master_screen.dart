import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../screens/admin_login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/users/users_screen.dart';
import '../screens/drivers/drivers_screen.dart';
import '../screens/promo_codes/promo_codes_screen.dart';
import '../screens/reviews/reviews_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/rides/rides_screen.dart';
import '../screens/profile/profile_screen.dart';

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
  void _navigateToRoute(String route) {
    Widget? screen;
    switch (route) {
      case '/home':
        screen = const HomeScreen();
        break;
      case '/users':
        screen = const UsersScreen();
        break;
      case '/drivers':
        screen = const DriversScreen();
        break;
      case '/promo-codes':
        screen = const PromoCodesScreen();
        break;
      case '/reviews':
        screen = const ReviewsScreen();
        break;
      case '/statistics':
        screen = const StatisticsScreen();
        break;
      case '/rides':
        screen = const RidesScreen();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$route - Coming soon')),
        );
        return;
    }

    if (screen != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MasterScreen(
            child: screen!,
            currentRoute: route,
          ),
        ),
      );
    }
  }

  void _handleLogout() {
    Provider.of<AdminAuthProvider>(context, listen: false).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar - Dark Theme
          Container(
            width: 250,
            color: const Color(0xFF2D2D3F), // Dark gray background
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
                        icon: Icons.people_outline,
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
          // Main Content Area - White Background
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Admin',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _handleLogout();
                          } else if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MasterScreen(
                                  child: const ProfileScreen(),
                                  currentRoute: '/profile',
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'profile',
                            child: Text('Profile'),
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
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
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
      onTap: () => _navigateToRoute(route),
      child: Container(
        color: isSelected
            ? const Color(0xFF3D3D4F) // Slightly lighter dark gray when selected
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
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

