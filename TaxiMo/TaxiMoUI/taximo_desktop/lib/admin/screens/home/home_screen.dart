import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';
import '../../layout/master_screen.dart';
import '../users/users_screen.dart';
import '../drivers/drivers_screen.dart';
import '../rides/rides_screen.dart';
import '../reviews/reviews_screen.dart';
import '../statistics/statistics_screen.dart';
import '../promo_codes/promo_codes_screen.dart';
import '../payments/payments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load statistics for dashboard
      final statsProvider = Provider.of<StatisticsProvider>(context, listen: false);
      statsProvider.fetchAll();
    });
  }

  void _navigateToRoute(String route) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MasterScreen(
          child: _getScreenForRoute(route),
          currentRoute: route,
        ),
      ),
    );
  }

  Widget _getScreenForRoute(String route) {
    switch (route) {
      case '/home':
        return const HomeScreen();
      case '/users':
        return const UsersScreen();
      case '/drivers':
        return const DriversScreen();
      case '/rides':
        return const RidesScreen();
      case '/reviews':
        return const ReviewsScreen();
      case '/statistics':
        return const StatisticsScreen();
      case '/promo-codes':
        return const PromoCodesScreen();
      case '/payments':
        return const PaymentsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back! Here\'s what\'s happening with TaxiMo today.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.dashboard,
                  size: 32,
                  color: Colors.deepPurple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Statistics Cards
          Consumer<StatisticsProvider>(
            builder: (context, statsProvider, child) {
              return GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Users',
                    value: statsProvider.totalUsers.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                    onTap: () => _navigateToRoute('/users'),
                  ),
                  _buildStatCard(
                    context,
                    title: 'Total Drivers',
                    value: statsProvider.totalDrivers.toString(),
                    icon: Icons.local_taxi,
                    color: Colors.orange,
                    onTap: () => _navigateToRoute('/drivers'),
                  ),
                  _buildStatCard(
                    context,
                    title: 'Total Rides',
                    value: statsProvider.totalRides.toString(),
                    icon: Icons.directions_car,
                    color: Colors.green,
                    onTap: () => _navigateToRoute('/rides'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Quick Access Section
          Text(
            'Quick Access',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildQuickAccessCard(
                context,
                title: 'Users',
                icon: Icons.people_outline,
                color: Colors.blue,
                route: '/users',
              ),
              _buildQuickAccessCard(
                context,
                title: 'Drivers',
                icon: Icons.people_outline,
                color: Colors.orange,
                route: '/drivers',
              ),
              _buildQuickAccessCard(
                context,
                title: 'Rides',
                icon: Icons.local_taxi_outlined,
                color: Colors.green,
                route: '/rides',
              ),
              _buildQuickAccessCard(
                context,
                title: 'Reviews',
                icon: Icons.star_outline,
                color: Colors.amber,
                route: '/reviews',
              ),
              _buildQuickAccessCard(
                context,
                title: 'Statistics',
                icon: Icons.access_time_outlined,
                color: Colors.purple,
                route: '/statistics',
              ),
              _buildQuickAccessCard(
                context,
                title: 'Promo Codes',
                icon: Icons.percent_outlined,
                color: Colors.teal,
                route: '/promo-codes',
              ),
              _buildQuickAccessCard(
                context,
                title: 'Payments',
                icon: Icons.payment_outlined,
                color: Colors.indigo,
                route: '/payments',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () => _navigateToRoute(route),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

