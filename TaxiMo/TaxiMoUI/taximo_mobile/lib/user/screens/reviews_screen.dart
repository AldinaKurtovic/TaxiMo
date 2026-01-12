import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/review_dto.dart';
import '../services/review_service.dart';
import '../widgets/driver_avatar.dart';
import '../../auth/providers/mobile_auth_provider.dart';
import '../widgets/user_app_bar.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  Future<List<ReviewDto>>? _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _loadReviews();
  }

  Future<List<ReviewDto>> _loadReviews() async {
      // Get current user
      final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
      throw Exception('Please login to view reviews');
      }

      // Use the new method that properly handles ReviewResponse format
    return await _reviewService.getReviewsByUserId(currentUser.userId);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const UserAppBar(title: 'Reviews'),
      body: FutureBuilder<List<ReviewDto>>(
        future: _reviewsFuture ?? _loadReviews(),
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
                        _reviewsFuture = _loadReviews();
                      });
                    },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
            );
          }

          final reviews = snapshot.data ?? [];
          
          if (reviews.isEmpty) {
            return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your reviews will appear here',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
            );
          }

          return ListView.builder(
                      padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewCard(review);
            },
          );
                      },
                    ),
    );
  }

  Widget _buildReviewCard(ReviewDto review) {
    return Container(
      key: ValueKey(review.reviewId),
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
            // Driver name and avatar
            if (review.driverName != null && review.driverName!.isNotEmpty) ...[
              Row(
                children: [
                  DriverAvatar(
                    photoUrl: review.driverPhotoUrl,
                    firstName: review.driverFirstName ?? review.driverName!.split(' ').first,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                    review.driverName!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Rating stars
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating.toInt()
                      ? Icons.star
                      : Icons.star_border,
                  size: 20,
                  color: Colors.amber[700],
                );
              }),
            ),
            const SizedBox(height: 12),
            
            // Comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Trip reference and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trip #${review.rideId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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

