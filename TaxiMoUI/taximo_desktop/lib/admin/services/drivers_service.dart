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

  Future<Map<String, dynamic>> getDrivers({
    int page = 1,
    int limit = 7,
    String? search,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('$baseUrl/api/Driver').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
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
    // Validate ID
    if (id <= 0) {
      throw Exception('Invalid driver ID: $id');
    }
    
    print('Updating driver $id with data: $driverData'); // Debug log
    
    final response = await http.put(
      Uri.parse('$baseUrl/api/Driver/$id'),
      headers: _headers(),
      body: jsonEncode(driverData),
    );

    print('Update driver response status: ${response.statusCode}'); // Debug log
    print('Update driver response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>? ?? responseData;
    } else {
      final errorBody = response.body;
      print('Update driver error body: $errorBody'); // Debug log
      try {
        final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
        String message = 'Failed to update driver';
        
        if (errorData.containsKey('message')) {
          message = errorData['message'].toString();
        } else if (errorData.containsKey('title')) {
          message = errorData['title'].toString();
        } else if (errorData.containsKey('errors')) {
          // Handle ModelState errors
          final errors = errorData['errors'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });
          message = errorMessages.join(', ');
        }
        
        throw Exception(message);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to update driver: ${response.statusCode} - $errorBody');
      }
    }
  }

  Future<bool> deleteDriver(int id) async {
    // Validate ID
    if (id <= 0) {
      throw Exception('Invalid driver ID: $id');
    }
    
    print('Deleting driver with ID: $id'); // Debug log
    final url = '$baseUrl/api/Driver/$id';
    print('Delete driver URL: $url'); // Debug log
    
    final headers = _headers();
    print('Delete driver headers: ${headers.keys}'); // Debug log
    
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    print('Delete driver response status: ${response.statusCode}'); // Debug log
    print('Delete driver response body: ${response.body}'); // Debug log

    if (response.statusCode == 204 || response.statusCode == 200) {
      print('Driver deleted successfully'); // Debug log
      return true;
    } else {
      final errorBody = response.body;
      print('Delete driver error - Status: ${response.statusCode}, Body: $errorBody'); // Debug log
      try {
        if (errorBody.isNotEmpty) {
          final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
          final message = errorData['message'] ?? errorData['title'] ?? 'Failed to delete driver';
          throw Exception(message.toString());
        } else {
          throw Exception('Failed to delete driver: ${response.statusCode}');
        }
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to delete driver: ${response.statusCode}');
      }
    }
  }
}

