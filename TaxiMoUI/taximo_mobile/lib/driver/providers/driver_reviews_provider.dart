import 'package:flutter/foundation.dart';
import '../../user/services/review_service.dart';
import '../../user/services/driver_service.dart';
import '../../user/models/review_dto.dart';

class DriverReviewsProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  final DriverService _driverService = DriverService();
  
  bool _isLoading = false;
  bool _isLoadingStats = false;
  String? _errorMessage;
  List<ReviewDto> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  int _totalCompletedRides = 0;
  double _totalEarnings = 0.0;

  bool get isLoading => _isLoading;
  bool get isLoadingStats => _isLoadingStats;
  String? get errorMessage => _errorMessage;
  List<ReviewDto> get reviews => _reviews;
  double get averageRating => _averageRating;
  int get totalReviews => _totalReviews;
  int get totalCompletedRides => _totalCompletedRides;
  double get totalEarnings => _totalEarnings;
  
  /// Get recent reviews (last 5)
  List<ReviewDto> get recentReviews => _reviews.take(5).toList();

  /// Load driver stats from backend (single source of truth)
  Future<void> loadDriverStats(int driverId) async {
    print("Fetching stats for driverId: $driverId");
    _isLoadingStats = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stats = await _driverService.getDriverStats(driverId);
      
      // Get stats from backend (single source of truth)
      _averageRating = (stats['averageRating'] as num?)?.toDouble() ?? 0.0;
      _totalReviews = stats['totalReviews'] as int? ?? 0;
      _totalCompletedRides = stats['totalCompletedRides'] as int? ?? 0;
      _totalEarnings = (stats['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      
      print("Stats loaded - averageRating: $_averageRating, totalReviews: $_totalReviews, totalCompletedRides: $_totalCompletedRides, totalEarnings: $_totalEarnings");
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _averageRating = 0.0;
      _totalReviews = 0;
      _totalCompletedRides = 0;
      _totalEarnings = 0.0;
      debugPrint('Error loading driver stats: $e');
      print("Error loading driver stats: $e");
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  /// Load reviews for a specific driver from backend
  Future<void> loadDriverReviews(int driverId) async {
    print("Fetching reviews for driverId: $driverId");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _reviewService.getReviewsByDriver(driverId);
      print("Reviews loaded - count: ${_reviews.length}");
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _reviews = [];
      debugPrint('Error loading driver reviews: $e');
      print("Error loading driver reviews: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh both stats and reviews
  Future<void> refresh(int driverId) async {
    await Future.wait([
      loadDriverStats(driverId),
      loadDriverReviews(driverId),
    ]);
  }
}

