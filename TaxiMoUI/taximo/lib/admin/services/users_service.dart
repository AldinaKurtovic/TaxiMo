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

  Future<List<dynamic>> getUsers({String? search, bool? isActive}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final uri = Uri.parse('$baseUrl/api/Users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
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
    final response = await http.post(
      Uri.parse('$baseUrl/api/Users'),
      headers: _headers(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> userData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Users/$id'),
      headers: _headers(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }

  Future<bool> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/Users/$id'),
      headers: _headers(),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }
}

