import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class ReviewsService {
  static const String baseUrl = 'http://localhost:5244';

  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    final basic = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
    return {
      'Content-Type': 'application/json',
      'Authorization': basic,
    };
  }

  Future<Map<String, dynamic>> getAll({
    int page = 1,
    int limit = 7,
    String? search,
    double? minRating,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (minRating != null) {
      queryParams['minRating'] = minRating.toString();
    }

    final uri = Uri.parse('$baseUrl/api/Review').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load reviews: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Review/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else if (response.statusCode == 404) {
      throw Exception('Review not found');
    } else {
      throw Exception('Failed to load review: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> reviewData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Review/$id'),
      headers: _headers(),
      body: jsonEncode(reviewData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>? ?? responseData;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else if (response.statusCode == 404) {
      throw Exception('Review not found');
    } else {
      final errorBody = response.body;
      try {
        final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
        throw Exception(errorData['message'] as String? ?? 'Failed to update review');
      } catch (e) {
        throw Exception('Failed to update review: ${response.statusCode}');
      }
    }
  }

  Future<bool> delete(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/Review/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else if (response.statusCode == 404) {
      throw Exception('Review not found');
    } else {
      throw Exception('Failed to delete review: ${response.statusCode}');
    }
  }
}

