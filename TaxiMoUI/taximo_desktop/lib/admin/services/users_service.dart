import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class UsersService {
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

  Future<Map<String, dynamic>> getUsers({
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

    final uri = Uri.parse('$baseUrl/api/Users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getUserById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Users/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    print('Creating user with data: $userData'); // Debug log
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/Users'),
      headers: _headers(),
      body: jsonEncode(userData),
    );

    print('Create user response status: ${response.statusCode}'); // Debug log
    print('Create user response body: ${response.body}'); // Debug log

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>? ?? responseData;
    } else {
      final errorBody = response.body;
      print('Create user error body: $errorBody'); // Debug log
      try {
        final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
        String message = 'Failed to create user';
        
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
        throw Exception('Failed to create user: ${response.statusCode} - $errorBody');
      }
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> userData) async {
    print('Updating user $id with data: $userData'); // Debug log
    
    final response = await http.put(
      Uri.parse('$baseUrl/api/Users/$id'),
      headers: _headers(),
      body: jsonEncode(userData),
    );

    print('Update user response status: ${response.statusCode}'); // Debug log
    print('Update user response body: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>? ?? responseData;
    } else {
      final errorBody = response.body;
      print('Update user error body: $errorBody'); // Debug log
      try {
        final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
        String message = 'Failed to update user';
        
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
        throw Exception('Failed to update user: ${response.statusCode} - $errorBody');
      }
    }
  }

  Future<bool> deleteUser(int id) async {
    // Validate ID
    if (id <= 0) {
      throw Exception('Invalid user ID: $id');
    }
    
    print('Deleting user with ID: $id'); // Debug log
    final url = '$baseUrl/api/Users/$id';
    print('Delete user URL: $url'); // Debug log
    
    final headers = _headers();
    print('Delete user headers: ${headers.keys}'); // Debug log
    
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );

    print('Delete user response status: ${response.statusCode}'); // Debug log
    print('Delete user response body: ${response.body}'); // Debug log

    if (response.statusCode == 204 || response.statusCode == 200) {
      print('User deleted successfully'); // Debug log
      return true;
    } else {
      final errorBody = response.body;
      print('Delete user error - Status: ${response.statusCode}, Body: $errorBody'); // Debug log
      try {
        if (errorBody.isNotEmpty) {
          final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
          final message = errorData['message'] ?? errorData['title'] ?? 'Failed to delete user';
          throw Exception(message.toString());
        } else {
          throw Exception('Failed to delete user: ${response.statusCode}');
        }
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    }
  }
}

