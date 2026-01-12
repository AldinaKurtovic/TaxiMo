import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class AdminAuthService {
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

  Future<bool> login(String email, String password) async {
    // Save credentials
    AuthProvider.username = email;
    AuthProvider.password = password;

    try {
      // Make a test GET request to /api/Users using BasicAuth
      final response = await http.get(
        Uri.parse('$baseUrl/api/Users'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return false;
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}

