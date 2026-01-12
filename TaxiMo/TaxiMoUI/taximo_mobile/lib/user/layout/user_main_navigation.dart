import 'package:flutter/material.dart';
import '../screens/user_home_screen.dart';
import '../screens/trip_history_screen.dart';
import '../screens/payment_history_screen.dart';
import '../screens/reviews_screen.dart';
import '../screens/profile_screen.dart';

class UserMainNavigation extends StatefulWidget {
  const UserMainNavigation({super.key});

  @override
  State<UserMainNavigation> createState() => UserMainNavigationState();
}

class UserMainNavigationState extends State<UserMainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const UserHomeScreen(),
    const TripHistoryScreen(),
    const PaymentHistoryScreen(),
    const ReviewsScreen(),
    const ProfileScreen(),
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Trip History',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Payments',
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

