import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/driver_provider.dart';
import '../providers/driver_reviews_provider.dart';

class DriverStatisticsScreen extends StatefulWidget {
  const DriverStatisticsScreen({super.key});

  @override
  State<DriverStatisticsScreen> createState() => _DriverStatisticsScreenState();
}

class _DriverStatisticsScreenState extends State<DriverStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Load stats when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProvider = context.read<DriverProvider>();
      final driver = driverProvider.currentDriver;
      final driverProfile = driverProvider.driverProfile;
      final driverId = driverProfile?.driverId ?? driver?.driverId ?? 0;
      
      if (driverId > 0) {
        context.read<DriverReviewsProvider>().loadDriverStats(driverId);
      }
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'EUR', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer2<DriverProvider, DriverReviewsProvider>(
        builder: (context, driverProvider, reviewsProvider, child) {
          final driver = driverProvider.currentDriver;
          final driverProfile = driverProvider.driverProfile;
          final isLoading = reviewsProvider.isLoadingStats;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver Name and Rating
                  if (driver != null || driverProfile != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driverProfile != null
                                ? '${driverProfile.firstName} ${driverProfile.lastName}'
                                : driver?.fullName ?? 'Driver',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (reviewsProvider.averageRating > 0) ...[
                          Icon(Icons.star, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 4),
                          Text(
                            reviewsProvider.averageRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Average Rating Section
                  const Text(
                    'AVERAGE RATING',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Text(
                      reviewsProvider.averageRating > 0
                          ? reviewsProvider.averageRating.toStringAsFixed(1)
                          : '0.0',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Star visualization
                    Row(
                      children: List.generate(5, (index) {
                        final rating = reviewsProvider.averageRating;
                        final filledStars = rating.floor();
                        final hasHalfStar = (rating - filledStars) >= 0.5;
                        
                        if (index < filledStars) {
                          return Icon(Icons.star, color: Colors.amber[700], size: 32);
                        } else if (index == filledStars && hasHalfStar) {
                          return Icon(Icons.star_half, color: Colors.amber[700], size: 32);
                        } else {
                          return Icon(Icons.star_border, color: Colors.grey[300], size: 32);
                        }
                      }),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // Stats Cards
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard(
                            'Total Trips',
                            reviewsProvider.totalCompletedRides.toString(),
                            Icons.directions_car,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _buildStatCard(
                            'Total Earnings',
                            _formatCurrency(reviewsProvider.totalEarnings),
                            Icons.attach_money,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

