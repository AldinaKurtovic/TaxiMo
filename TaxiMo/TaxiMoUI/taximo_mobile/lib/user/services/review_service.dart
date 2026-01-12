import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../models/review_dto.dart';

class ReviewService {
  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      throw Exception('Authentication credentials are missing. Please login again.');
    }
    
    final credentials = base64Encode(utf8.encode('$user:$pass'));
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic $credentials',
    };
  }

  /// Get all reviews (optionally filter by user)
  Future<List<Map<String, dynamic>>> getReviews() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Review');
    
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body);
      
      // Handle both array and wrapped response
      if (jsonData is List) {
        return jsonData.cast<Map<String, dynamic>>();
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        return (jsonData['data'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch reviews: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get review for a specific ride
  Future<ReviewDto?> getReviewByRideId(int rideId) async {
    try {
      final reviews = await getReviews();
      final reviewData = reviews.firstWhere(
        (r) => r['rideId'] == rideId,
        orElse: () => <String, dynamic>{},
      );
      
      if (reviewData.isEmpty) {
        return null;
      }
      
      return ReviewDto.fromJson(reviewData);
    } catch (e) {
      return null;
    }
  }

  /// Get review for a specific ride by a specific user (rideId AND userId)
  Future<ReviewDto?> getReviewByRideIdAndUserId(int rideId, int userId) async {
    try {
      final reviews = await getReviews();
      
      for (final reviewJson in reviews) {
        // Check if rideId matches
        final reviewRideId = reviewJson['rideId'];
        if (reviewRideId != rideId) continue;
        
        // Check if userId matches (check both userId and riderId fields)
        final userIdValue = reviewJson['userId'];
        final riderIdValue = reviewJson['riderId'];
        
        int? reviewUserId;
        
        // Try userId first (ReviewResponse format)
        if (userIdValue != null) {
          if (userIdValue is int) {
            reviewUserId = userIdValue;
          } else if (userIdValue is num) {
            reviewUserId = userIdValue.toInt();
          }
        }
        
        // Fallback to riderId if userId not found
        if (reviewUserId == null && riderIdValue != null) {
          if (riderIdValue is int) {
            reviewUserId = riderIdValue;
          } else if (riderIdValue is num) {
            reviewUserId = riderIdValue.toInt();
          }
        }
        
        // If userId matches, return this review
        if (reviewUserId != null && reviewUserId == userId) {
          return ReviewDto.fromJson(reviewJson);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a new review
  Future<ReviewDto> createReview(ReviewCreateDto review) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Review');
    final body = jsonEncode(review.toJson());

    final response = await http.post(uri, headers: _headers(), body: body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Handle both direct DTO and wrapped response
      if (jsonData.containsKey('data')) {
        return ReviewDto.fromJson(jsonData['data'] as Map<String, dynamic>);
      }
      return ReviewDto.fromJson(jsonData);
    } else {
      final errorBody = response.body;
      throw Exception('Failed to create review: ${response.statusCode} - $errorBody');
    }
  }

  /// Get reviews for a specific driver
  Future<List<ReviewDto>> getReviewsByDriverId(int driverId) async {
    try {
      final reviews = await getReviews();
      final driverReviews = reviews
          .where((r) => r['driverId'] == driverId)
          .map((json) => ReviewDto.fromJson(json))
          .toList();
      
      // Sort by created date (most recent first)
      driverReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return driverReviews;
    } catch (e) {
      throw Exception('Failed to fetch driver reviews: $e');
    }
  }

  /// Get reviews for the current user (rider)
  Future<List<ReviewDto>> getReviewsByUserId(int userId) async {
    try {
      final reviews = await getReviews();
      final userReviews = <ReviewDto>[];
      
      for (final reviewJson in reviews) {
        try {
          // The API returns ReviewResponse with 'userId' field (mapped from RiderId)
          // Check both 'userId' (from ReviewResponse) and 'riderId' (from ReviewDto)
          final userIdValue = reviewJson['userId'];
          final riderIdValue = reviewJson['riderId'];
          
          int? reviewUserId;
          
          // Try userId first (ReviewResponse format)
          if (userIdValue != null) {
            if (userIdValue is int) {
              reviewUserId = userIdValue;
            } else if (userIdValue is num) {
              reviewUserId = userIdValue.toInt();
            }
          }
          
          // Fallback to riderId if userId not found
          if (reviewUserId == null && riderIdValue != null) {
            if (riderIdValue is int) {
              reviewUserId = riderIdValue;
            } else if (riderIdValue is num) {
              reviewUserId = riderIdValue.toInt();
            }
          }
          
          // Compare and add if matches
          if (reviewUserId != null && reviewUserId == userId) {
            final review = ReviewDto.fromJson(reviewJson);
            userReviews.add(review);
          }
        } catch (e) {
          // Skip invalid review entries
          continue;
        }
      }
      
      // Sort by created date (most recent first)
      userReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return userReviews;
    } catch (e) {
      throw Exception('Failed to fetch user reviews: $e');
    }
  }

  /// Get reviews by rider ID (returns reviews with rideId included)
  Future<List<ReviewDto>> getReviewsByRider(int riderId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Review/by-rider/$riderId');
    
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body);
      
      // Handle both array and wrapped response
      List<dynamic> reviewList;
      if (jsonData is List) {
        reviewList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        reviewList = jsonData['data'] as List;
      } else {
        return [];
      }
      
      return reviewList
          .map((json) => ReviewDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch reviews by rider: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get reviews for a specific driver
  Future<List<ReviewDto>> getReviewsByDriver(int driverId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Review/by-driver/$driverId');
    
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body);
      
      // Handle both array and wrapped response
      List<dynamic> reviewList;
      if (jsonData is List) {
        reviewList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        reviewList = jsonData['data'] as List;
      } else {
        return [];
      }
      
      // Map ReviewResponse format to ReviewDto (includes user photo info)
      return reviewList
          .map((json) => ReviewDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch reviews by driver: ${response.statusCode} - ${response.body}');
    }
  }
}

