import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';

class UserProfileService {
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

  /// Get current authenticated user by email or username
  Future<Map<String, dynamic>> getCurrentUser() async {
    // Use the /me endpoint which returns the current authenticated user
    final response = await http.get(
      Uri.parse('$baseUrl/api/Users/me'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! Map<String, dynamic>) {
        throw Exception('Invalid response format: expected user object');
      }
      
      return decodedBody as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('User not authenticated. Please login again.');
    } else if (response.statusCode == 404) {
      throw Exception('User not found. Please check your authentication credentials.');
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// Update user profile
  /// Security: Only allows updating the authenticated user's own profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final userId = profileData['userId'] as int;
    final authIdentifier = AuthProvider.username;
    
    // Security check: Verify the user is updating their own profile
    // Get current user to verify the userId matches
    final currentUser = await getCurrentUser();
    final currentUserId = currentUser['userId'] as int;
    
    if (userId != currentUserId) {
      throw Exception('You can only update your own profile.');
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl/api/Users/$userId'),
      headers: _headers(),
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Extract the data field if it exists, otherwise use the whole response
      final userData = responseData['data'];
      if (userData != null && userData is Map<String, dynamic>) {
        return userData;
      } else if (responseData.containsKey('userId')) {
        // Response is already the user data
        return responseData;
      } else {
        throw Exception('Invalid response format from server');
      }
    } else {
      final errorBody = response.body;
      try {
        final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
        String message = 'Failed to update profile';
        
        if (errorData.containsKey('message')) {
          message = errorData['message'].toString();
        } else if (errorData.containsKey('title')) {
          message = errorData['title'].toString();
        } else if (errorData.containsKey('errors')) {
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
        throw Exception('Failed to update profile: ${response.statusCode} - $errorBody');
      }
    }
  }

  /// Change password
  /// Security: Only allows changing the authenticated user's own password
  Future<bool> changePassword(int userId, String oldPassword, String newPassword, String confirmPassword) async {
    // Security check: Verify the user is changing their own password
    final currentUser = await getCurrentUser();
    final currentUserId = currentUser['userId'] as int;
    
    if (userId != currentUserId) {
      throw Exception('You can only change your own password.');
    }
    
    final passwordData = {
      'userId': userId,
      'changePassword': true,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmNewPassword': confirmPassword,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/api/Users/$userId'),
      headers: _headers(),
      body: jsonEncode(passwordData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final errorBody = response.body;
      try {
        final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
        String message = 'Failed to change password';
        
        if (errorData.containsKey('message')) {
          message = errorData['message'].toString();
        } else if (errorData.containsKey('title')) {
          message = errorData['title'].toString();
        } else if (errorData.containsKey('errors')) {
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
        throw Exception('Failed to change password: ${response.statusCode} - $errorBody');
      }
    }
  }
}

