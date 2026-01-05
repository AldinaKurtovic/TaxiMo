import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ride_history_dto.dart';
import '../models/review_dto.dart';
import '../services/ride_service.dart';
import '../services/review_service.dart';
import '../../auth/providers/mobile_auth_provider.dart';
import '../widgets/user_app_bar.dart';
import 'rate_trip_screen.dart';

enum TimeFilter {
  all,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
}

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final RideService _rideService = RideService();
  final ReviewService _reviewService = ReviewService();
  Future<_TripHistoryData>? _historyFuture;
  final ValueNotifier<TimeFilter> _filterNotifier = ValueNotifier<TimeFilter>(TimeFilter.thisMonth);
  Map<int, ReviewDto> _rideReviews = {}; // Cache reviews by rideId

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadRideHistory();
  }
  
  @override
  void dispose() {
    _filterNotifier.dispose();
    super.dispose();
  }

  Future<_TripHistoryData> _loadRideHistory() async {
    // Get current user
    final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      throw Exception('Please login to view trip history');
    }

    final ridesData = await _rideService.getRideHistory(status: 'completed');
    
    // Filter rides by current user ID and map to DTOs
    final rides = ridesData
        .where((json) => json['riderId'] == currentUser.userId)
        .map((json) => RideHistoryDto.fromJson(json))
        .toList();

    // Sort by completed date (most recent first)
    rides.sort((a, b) {
      final aDate = a.completedAt ?? a.requestedAt;
      final bDate = b.completedAt ?? b.requestedAt;
      return bDate.compareTo(aDate);
    });

    // Load reviews for all rides
    await _loadReviewsForRides(rides);

    return _TripHistoryData(rides: rides, reviews: Map.from(_rideReviews));
  }
  Future<void> _loadReviewsForRides(List<RideHistoryDto> rides) async {
    try {
      final authProvider =
          Provider.of<MobileAuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) return;

      // Use the new endpoint that returns reviews with rideId
      final reviews = await _reviewService.getReviewsByRider(currentUser.userId);

      // Populate map EXACTLY as specified
      _rideReviews.clear();
      for (final review in reviews) {
        if (review.rideId > 0) {
          _rideReviews[review.rideId] = review;
        }
      }
    } catch (e) {
      // Silently fail - reviews are optional
    }
  }

  List<RideHistoryDto> _applyFilter(List<RideHistoryDto> allRides, TimeFilter filter) {
    final now = DateTime.now();
    List<RideHistoryDto> filtered = List.from(allRides);

    switch (filter) {
      case TimeFilter.thisMonth:
        filtered = filtered.where((ride) {
          final date = ride.completedAt ?? ride.requestedAt;
          return date.year == now.year && date.month == now.month;
        }).toList();
        break;
      case TimeFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        filtered = filtered.where((ride) {
          final date = ride.completedAt ?? ride.requestedAt;
          return date.year == lastMonth.year && date.month == lastMonth.month;
        }).toList();
        break;
      case TimeFilter.last3Months:
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        filtered = filtered.where((ride) {
          final date = ride.completedAt ?? ride.requestedAt;
          return date.isAfter(threeMonthsAgo);
        }).toList();
        break;
      case TimeFilter.thisYear:
        filtered = filtered.where((ride) {
          final date = ride.completedAt ?? ride.requestedAt;
          return date.year == now.year;
        }).toList();
        break;
      case TimeFilter.all:
        // No filtering
        break;
    }

    return filtered;
  }

  String _getFilterLabel(TimeFilter filter) {
    switch (filter) {
      case TimeFilter.all:
        return 'All Time';
      case TimeFilter.thisMonth:
        return 'This Month';
      case TimeFilter.lastMonth:
        return 'Last Month';
      case TimeFilter.last3Months:
        return 'Last 3 Months';
      case TimeFilter.thisYear:
        return 'This Year';
    }
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserAppBar(title: 'Trip History'),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showFilterDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<TimeFilter>(
                          valueListenable: _filterNotifier,
                          builder: (context, filter, _) {
                            return Text(
                              _getFilterLabel(filter),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Content
          Expanded(
            child: FutureBuilder<_TripHistoryData>(
              future: _historyFuture ?? _loadRideHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          snapshot.error.toString().replaceFirst('Exception: ', ''),
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              _historyFuture = _loadRideHistory();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data!;
                _rideReviews = data.reviews;

                return ValueListenableBuilder<TimeFilter>(
                  valueListenable: _filterNotifier,
                  builder: (context, filter, _) {
                    final filteredRides = _applyFilter(data.rides, filter);

                    if (filteredRides.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No trips found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your completed trips will appear here',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRides.length,
                      itemBuilder: (context, index) {
                        final ride = filteredRides[index];
                        return _buildRideCard(ride);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideHistoryDto ride) {
    return Container(
      key: ValueKey(ride.rideId),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route visualization
            Row(
              children: [
                // Pickup point
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                    child: CustomPaint(
                      painter: DashedLinePainter(),
                    ),
                  ),
                ),
                // Dropoff point
                Icon(Icons.location_on, color: Colors.red[400], size: 20),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pickup location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.startedAt != null
                            ? _formatTime(ride.startedAt!)
                            : ride.completedAt != null
                                ? _formatTime(ride.completedAt!)
                                : _formatTime(ride.requestedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Dropoff location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.dropoffAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ride.completedAt != null
                            ? _formatTime(ride.completedAt!)
                            : 'Not completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Driver info and price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Driver info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.driverName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber[700]),
                            const SizedBox(width: 2),
                            Text(
                              ride.driverRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // Price
                Text(
                  '${ride.displayPrice.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Rating section
            _buildRatingSection(ride),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(RideHistoryDto ride) {
    if (ride.status.toLowerCase() != 'completed') {
      return const SizedBox.shrink();
    }
    
    if (_rideReviews.containsKey(ride.rideId)) {
      final review = _rideReviews[ride.rideId]!;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 20, color: Colors.green[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'You rated: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      ...List.generate(5, (index) {
                        return Icon(
                          index < review.rating.toInt()
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: Colors.amber[700],
                        );
                      }),
                    ],
                  ),
                  if (review.comment != null && review.comment!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      review.comment!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _navigateToRateTrip(ride),
          icon: Icon(Icons.star, size: 18, color: Colors.deepPurple),
          label: const Text(
            'Rate This Trip',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.deepPurple),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToRateTrip(RideHistoryDto ride) async {
    // Guard: Check if trip is completed
    if (ride.status.toLowerCase() != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only review completed trips. Current status: ${ride.status}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Guard: Check if review already exists for this trip
    final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      // Check if review exists in cache
      if (_rideReviews.containsKey(ride.rideId) && _rideReviews[ride.rideId] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already reviewed this trip.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Double-check with API (in case cache is stale)
      try {
        final existingReview = await _reviewService.getReviewByRideIdAndUserId(
          ride.rideId,
          currentUser.userId,
        );
        
        if (existingReview != null) {
          // Update cache
          if (mounted) {
            _rideReviews[ride.rideId] = existingReview;
            setState(() {});
          }
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already reviewed this trip.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      } catch (e) {
        // If check fails, continue with navigation (backend will handle duplicate)
      }
    }

    final result = await Navigator.pushNamed(
      context,
      '/rate-trip',
      arguments: ride,
    );

    // If review was submitted, reload history (which includes reviews)
    if (result == true && mounted) {
      setState(() {
        _historyFuture = _loadRideHistory();
      });
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Filter by Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...TimeFilter.values.map((filter) {
                return ListTile(
                  title: Text(_getFilterLabel(filter)),
                  trailing: ValueListenableBuilder<TimeFilter>(
                    valueListenable: _filterNotifier,
                    builder: (context, currentFilter, _) {
                      return currentFilter == filter
                          ? const Icon(Icons.check, color: Colors.deepPurple)
                          : const SizedBox.shrink();
                    },
                  ),
                  onTap: () {
                    _filterNotifier.value = filter;
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// Immutable trip history data
class _TripHistoryData {
  final List<RideHistoryDto> rides;
  final Map<int, ReviewDto> reviews;

  const _TripHistoryData({
    required this.rides,
    required this.reviews,
  });
}

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurple.withOpacity(0.3)
      ..strokeWidth = 2;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

