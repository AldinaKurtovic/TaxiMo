import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class RidesService {
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

  Future<List<dynamic>> getAll({String? search, String? status}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final uri = Uri.parse('$baseUrl/api/Ride').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load rides: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getFreeDrivers() async {
    final uri = Uri.parse('$baseUrl/api/Driver/free');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to load free drivers: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> assignDriver(int rideId, int driverId) async {
    final uri = Uri.parse('$baseUrl/api/Ride/$rideId/assign-driver');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'driverId': driverId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 400) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(errorBody['message'] ?? 'Failed to assign driver');
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: Please check your credentials');
    } else {
      throw Exception('Failed to assign driver: ${response.statusCode}');
    }
  }
}

