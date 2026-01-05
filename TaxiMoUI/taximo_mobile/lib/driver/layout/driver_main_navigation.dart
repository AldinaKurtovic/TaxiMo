import 'package:flutter/material.dart';
import '../screens/driver_home_screen.dart';
import '../screens/ride_requests_screen.dart';
import '../screens/driver_statistics_screen.dart';
import '../screens/driver_reviews_screen.dart';
import '../screens/driver_profile_screen.dart';

class DriverMainNavigation extends StatefulWidget {
  const DriverMainNavigation({super.key});

  @override
  State<DriverMainNavigation> createState() => DriverMainNavigationState();
}

class DriverMainNavigationState extends State<DriverMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DriverHomeScreen(),        // Index 0: Home
    const RideRequestsScreen(),      // Index 1: Requests
    const DriverStatisticsScreen(),  // Index 2: Statistics
    const DriverReviewsScreen(),     // Index 3: Reviews
    const DriverProfileScreen(),     // Index 4: Profile
  ];

  void changeTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Reviews',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

