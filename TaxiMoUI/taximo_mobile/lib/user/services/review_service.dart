import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/review_dto.dart';

class ReviewService {
  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
    };
  }

  /// Get all reviews (optionally filter by user)
  Future<List<Map<String, dynamic>>> getReviews() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Review');
    
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
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

  /// Create a new review
  Future<ReviewDto> createReview(ReviewCreateDto review) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Review');
    final body = jsonEncode(review.toJson());

    final response = await http.post(uri, headers: _headers(), body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
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
}

