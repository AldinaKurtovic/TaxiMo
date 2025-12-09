import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class DriversService {
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

  Future<List<dynamic>> getDrivers({String? search, bool? isActive}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('$baseUrl/api/Driver').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load drivers: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getDriverById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Driver/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load driver: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> driverData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Driver'),
      headers: _headers(),
      body: jsonEncode(driverData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>? ?? responseData;
    } else {
      throw Exception('Failed to create driver: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateDriver(int id, Map<String, dynamic> driverData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Driver/$id'),
      headers: _headers(),
      body: jsonEncode(driverData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>? ?? responseData;
    } else {
      throw Exception('Failed to update driver: ${response.statusCode}');
    }
  }

  Future<bool> deleteDriver(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/Driver/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete driver: ${response.statusCode}');
    }
  }
}

