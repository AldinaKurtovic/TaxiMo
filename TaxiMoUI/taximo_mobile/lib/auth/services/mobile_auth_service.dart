import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../../config/api_config.dart';

class MobileAuthService {
  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    final basic = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
    return {
      'Content-Type': 'application/json',
      'Authorization': basic,
    };
  }

  /// Validates credentials using Basic Authentication
  /// Similar to AdminAuthService.login but adapted for mobile
  Future<bool> validateCredentials(String email, String password) async {
    // Save credentials
    AuthProvider.username = email;
    AuthProvider.password = password;

    try {
      // Make a test GET request to /api/Users using BasicAuth
      // Note: This endpoint requires Admin role, but Basic Auth handler validates credentials first
      // For non-admin users, we'll get 403 but credentials are still validated
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Users'),
        headers: _headers(),
      );

      // 200 = authenticated successfully
      // 401/403 = invalid credentials (Basic Auth handler validates before role check)
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Check if it's a 403 due to role (credentials valid) or 401 (invalid credentials)
        // For now, we'll treat 403 as potentially valid credentials but wrong role
        // We'll validate further by fetching user data
        return false;
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Fetches current user data with roles using Basic Authentication
  /// Uses the login endpoint to get UserResponse with roles
  Future<UserModel?> fetchCurrentUser() async {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;

    if (user == null || pass == null) {
      return null;
    }

    try {
      // Use the login endpoint to get user data with roles
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Users/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': user,
          'password': pass,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  /// Complete login flow: validate credentials and fetch user data
  /// Mirrors AdminAuthService pattern but also fetches user data with roles
  Future<UserModel?> login(String email, String password) async {
    // Save credentials first (like Admin does)
    AuthProvider.username = email;
    AuthProvider.password = password;

    try {
      // Step 1: Validate credentials using Basic Auth with GET /api/Users (like Admin)
      // This endpoint requires Admin role, but Basic Auth handler validates credentials first
      final validationResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Users'),
        headers: _headers(),
      );

      // Step 2: Handle response
      if (validationResponse.statusCode == 200) {
        // Admin user - credentials valid, fetch user data
        final userModel = await fetchCurrentUser();
        return userModel;
      } else if (validationResponse.statusCode == 401) {
        // Invalid credentials
        return null;
      } else if (validationResponse.statusCode == 403) {
        // Could be valid credentials but wrong role (non-admin user)
        // Try login endpoint to get user data and validate
        final userModel = await fetchCurrentUser();
        return userModel; // Returns null if credentials are actually invalid
      } else {
        throw Exception('Unexpected status code: ${validationResponse.statusCode}');
      }
    } catch (e) {
      // If Basic Auth validation fails (network error, etc.), try login endpoint as fallback
      // This handles cases where GET /api/Users fails for non-admin users
      try {
        final userModel = await fetchCurrentUser();
        return userModel;
      } catch (_) {
        throw Exception('Login failed: $e');
      }
    }
  }
}

