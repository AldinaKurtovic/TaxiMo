import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class StatisticsService {
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

  Future<int> getTotalUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/statistics/total-users'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['count'] as int;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load total users: ${response.statusCode}');
    }
  }

  Future<int> getTotalDrivers({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse('$baseUrl/api/statistics/total-drivers')
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['count'] as int;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load total drivers: ${response.statusCode}');
    }
  }

  Future<int> getTotalRides() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/statistics/total-rides'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['count'] as int;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load total rides: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getAvgRatingPerMonth(int year) async {
    final uri = Uri.parse('$baseUrl/api/statistics/avg-rating-per-month')
        .replace(queryParameters: {'year': year.toString()});
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load average rating: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getRevenuePerMonth(int year) async {
    final uri = Uri.parse('$baseUrl/api/statistics/revenue-per-month')
        .replace(queryParameters: {'year': year.toString()});
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load revenue: ${response.statusCode}');
    }
  }
}

