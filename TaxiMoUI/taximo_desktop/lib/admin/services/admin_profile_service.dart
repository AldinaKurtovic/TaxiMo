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
    final authIdentifier = AuthProvider.username;
    if (authIdentifier == null || authIdentifier.isEmpty) {
      throw Exception('No authenticated user found');
    }

    // Search through users page by page to find the matching user
    // Use search parameter if backend supports it, otherwise iterate through pages
    int page = 1;
    const int limit = 50; // Use larger limit to reduce API calls
    bool hasMorePages = true;
    
    while (hasMorePages) {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'search': authIdentifier, // Try using search parameter
      };
      
      final uri = Uri.parse('$baseUrl/api/Users').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _headers());

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Handle paginated response format
        final data = decodedBody['data'] as List<dynamic>?;
        final pagination = decodedBody['pagination'] as Map<String, dynamic>?;
        
        if (data == null) {
          throw Exception('Invalid response format: missing data field');
        }
        
        // Try to find user by email or username
        Map<String, dynamic>? foundUser;
        for (var user in data) {
          if (user is! Map<String, dynamic>) continue;
          
          final userMap = user as Map<String, dynamic>;
          final userEmail = userMap['email']?.toString();
          final userUsername = userMap['username']?.toString();
          
          if (userEmail == authIdentifier || userUsername == authIdentifier) {
            foundUser = userMap;
            break;
          }
        }

        if (foundUser != null) {
          return foundUser;
        }

        // Check if there are more pages
        if (pagination != null) {
          final currentPage = pagination['currentPage'] as int? ?? page;
          final totalPages = pagination['totalPages'] as int? ?? 1;
          hasMorePages = currentPage < totalPages;
          page = currentPage + 1;
        } else {
          hasMorePages = false;
        }
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    }

    throw Exception('User not found. Please check your authentication credentials.');
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

