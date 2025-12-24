import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride_history_dto.dart';
import '../models/review_dto.dart';
import '../services/review_service.dart';
import '../../auth/providers/mobile_auth_provider.dart';

class RateTripScreen extends StatefulWidget {
  const RateTripScreen({super.key});

  @override
  State<RateTripScreen> createState() => _RateTripScreenState();
}

class _RateTripScreenState extends State<RateTripScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;
  RideHistoryDto? _ride;
  ReviewDto? _existingReview;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ride == null) {
      _loadRideData();
    }
  }

  void _loadRideData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RideHistoryDto) {
      setState(() {
        _ride = args;
        // If ride already has a review, load it
        _checkExistingReview();
      });
    }
  }

  Future<void> _checkExistingReview() async {
    if (_ride == null) return;

    try {
      final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) return;

      // Check for existing review by rideId AND userId
      final review = await _reviewService.getReviewByRideIdAndUserId(
        _ride!.rideId,
        currentUser.userId,
      );

      if (review != null) {
        setState(() {
          _existingReview = review;
          _selectedRating = review.rating.toInt();
          _feedbackController.text = review.comment ?? '';
        });

        // Show message and navigate back
        Future.microtask(() {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have already reviewed this trip.'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).pop(false);
          }
        });
      }
    } catch (e) {
      // No review exists → OK
    }
  }


  Future<void> _submitReview() async {
    if (_ride == null || _selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent submission if review already exists
    if (_existingReview != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already reviewed this trip'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate that trip is completed
    if (_ride!.status.toLowerCase() != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only review completed trips. Current status: ${_ride!.status}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<MobileAuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to submit a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Double-check for existing review before submission (by rideId AND userId)
    try {
      final existingReview = await _reviewService.getReviewByRideIdAndUserId(
        _ride!.rideId,
        currentUser.userId,
      );
      if (existingReview != null) {
        setState(() {
          _existingReview = existingReview;
          _selectedRating = existingReview.rating.toInt();
          _feedbackController.text = existingReview.comment ?? '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already reviewed this trip.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } catch (e) {
      // If check fails, continue with submission (backend will handle duplicate)
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final review = ReviewCreateDto(
        rideId: _ride!.rideId,
        riderId: currentUser.userId,
        driverId: _ride!.driverId,
        rating: _selectedRating.toDouble(),
        comment: _feedbackController.text.trim().isEmpty 
            ? null 
            : _feedbackController.text.trim(),
      );

      await _reviewService.createReview(review);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your review!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.of(context).pop(true); // Return true to indicate review was submitted
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rate Your Trip')),
        body: const Center(child: Text('Invalid ride data')),
      );
    }

    final driverName = _ride!.driverName;
    final driverRating = _ride!.driverRating;
    final tripExpense = _ride!.displayPrice;
    final total = _ride!.displayPrice;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Purple header
          Container(
            color: Colors.deepPurple,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    'Rate Your Trip',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          // White content area
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver information
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    driverRating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Message icon (optional - for future feature)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.message,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Rating section
                    Text(
                      'How is your trip?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: _existingReview == null
                              ? () {
                                  setState(() {
                                    _selectedRating = starIndex;
                                  });
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starIndex <= _selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 40,
                              color: starIndex <= _selectedRating
                                  ? Colors.amber[700]
                                  : Colors.grey[400],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Feedback text field
                    TextField(
                      controller: _feedbackController,
                      enabled: _existingReview == null,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Write your feedback',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Trip Detail section
                    Text(
                      'Trip Detail',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Pickup location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _ride!.pickupAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Dashed line
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Container(
                        height: 20,
                        width: 2,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey[300]!,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                        child: CustomPaint(
                          painter: DashedLinePainter(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Dropoff location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.red[400], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ride!.dropoffAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Payment Detail section
                    Text(
                      'Payment Detail',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Trip Expense
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trip Expense',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${tripExpense.toStringAsFixed(2)} KM',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)} KM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Submit button
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_existingReview == null && !_isSubmitting && _selectedRating > 0)
                      ? () => _submitReview()
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          _existingReview != null ? 'Review Submitted' : 'Submit',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 2;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

