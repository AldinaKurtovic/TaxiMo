import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/driver_reviews_provider.dart';
import '../../user/models/review_dto.dart';

class DriverReviewsScreen extends StatefulWidget {
  const DriverReviewsScreen({
    super.key,
  });

  @override
  State<DriverReviewsScreen> createState() => _DriverReviewsScreenState();
}

class _DriverReviewsScreenState extends State<DriverReviewsScreen> {
  int? _driverId;

  @override
  void initState() {
    super.initState();
    // Read driverId from route arguments ONCE in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args > 0) {
        _driverId = args;
        print("DriverReviewsScreen: Loaded driverId from route: $_driverId");
        context.read<DriverReviewsProvider>().loadDriverReviews(_driverId!);
      } else {
        print("DriverReviewsScreen: Invalid or missing driverId from route arguments: $args");
      }
    });
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DriverReviewsProvider>(
        builder: (context, reviewsProvider, child) {
          if (reviewsProvider.isLoading && reviewsProvider.reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reviewsProvider.errorMessage != null && reviewsProvider.reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading reviews',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reviewsProvider.errorMessage!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_driverId != null && _driverId! > 0) {
                        context.read<DriverReviewsProvider>().loadDriverReviews(_driverId!);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (reviewsProvider.reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t received any reviews yet.',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          if (_driverId == null || _driverId! <= 0) {
            return const Center(
              child: Text('Driver ID is required'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<DriverReviewsProvider>().refresh(_driverId!);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: reviewsProvider.reviews.length,
              itemBuilder: (context, index) {
                final review = reviewsProvider.reviews[index];
                return _buildReviewCard(review);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(ReviewDto review) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rider name
            if (review.userName != null && review.userName!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    review.userName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Rating stars
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < review.rating.toInt()
                        ? Icons.star
                        : Icons.star_border,
                    size: 20,
                    color: Colors.amber[700],
                  );
                }),
                const SizedBox(width: 12),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // Comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

