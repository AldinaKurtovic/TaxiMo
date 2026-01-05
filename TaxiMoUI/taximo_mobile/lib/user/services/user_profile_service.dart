import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../config/api_config.dart';

class UserProfileService {
  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      throw Exception('Authentication credentials are missing. Please login again.');
    }
    
    final credentials = base64Encode(utf8.encode('$user:$pass'));
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $credentials',
    };
  }

  /// Get current authenticated user by email or username
  Future<Map<String, dynamic>> getCurrentUser() async {
    final authIdentifier = AuthProvider.username;
    if (authIdentifier == null || authIdentifier.isEmpty) {
      throw Exception('No authenticated user found');
    }

    // Get all users and find the one matching the authenticated email or username
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Users'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! List) {
        throw Exception('Invalid response format: expected list of users');
      }
      
      final users = decodedBody as List<dynamic>;
      
      // Try to find user by email first, then by username
      Map<String, dynamic>? foundUser;
      for (var user in users) {
        if (user is! Map<String, dynamic>) continue;
        
        final userMap = user as Map<String, dynamic>;
        final userEmail = userMap['email']?.toString();
        final userUsername = userMap['username']?.toString();
        
        if (userEmail == authIdentifier || userUsername == authIdentifier) {
          foundUser = userMap;
          break;
        }
      }

      if (foundUser == null) {
        throw Exception('User not found. Please check your authentication credentials.');
      }

      return foundUser;
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(int userId, Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/Users/$userId'),
      headers: _headers(),
      body: jsonEncode(profileData),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
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
      Uri.parse('${ApiConfig.baseUrl}/api/Users/$userId'),
      headers: _headers(),
      body: jsonEncode(passwordData),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Update stored password after successful change
      AuthProvider.password = newPassword;
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

