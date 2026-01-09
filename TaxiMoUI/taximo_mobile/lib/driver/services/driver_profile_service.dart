import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../config/api_config.dart';

class DriverProfileService {
  Map<String, String> _headers({bool includeContentType = true}) {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      throw Exception('Authentication credentials are missing. Please login again.');
    }
    
    final credentials = base64Encode(utf8.encode('$user:$pass'));
    final headers = <String, String>{
      'Authorization': 'Basic $credentials',
    };
    
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }
    
    return headers;
  }

  /// Get current authenticated driver by username
  Future<Map<String, dynamic>> getCurrentDriver() async {
    final authIdentifier = AuthProvider.username;
    if (authIdentifier == null || authIdentifier.isEmpty) {
      throw Exception('No authenticated driver found');
    }

    // Get all drivers and find the one matching the authenticated username
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/Driver').replace(
        queryParameters: {'search': authIdentifier},
      ),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(response.body);
      if (decodedBody is! List) {
        throw Exception('Invalid response format: expected list of drivers');
      }
      
      final drivers = decodedBody as List<dynamic>;
      
      // Try to find driver by username or email
      Map<String, dynamic>? foundDriver;
      for (var driver in drivers) {
        if (driver is! Map<String, dynamic>) continue;
        
        final driverMap = driver as Map<String, dynamic>;
        final driverEmail = driverMap['email']?.toString();
        final driverUsername = driverMap['username']?.toString();
        
        if (driverEmail == authIdentifier || driverUsername == authIdentifier) {
          foundDriver = driverMap;
          break;
        }
      }

      if (foundDriver == null) {
        throw Exception('Driver not found. Please check your authentication credentials.');
      }

      return foundDriver;
    } else {
      throw Exception('Failed to load driver profile: ${response.statusCode}');
    }
  }

  /// Update driver profile
  Future<Map<String, dynamic>> updateProfile(int driverId, Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/Driver/$driverId?isSelfUpdate=true'),
      headers: _headers(),
      body: jsonEncode(profileData),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Extract the data field if it exists, otherwise use the whole response
      final driverData = responseData['data'];
      if (driverData != null && driverData is Map<String, dynamic>) {
        return driverData;
      } else if (responseData.containsKey('driverId')) {
        // Response is already the driver data
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
  /// Security: Only allows changing the authenticated driver's own password
  Future<bool> changePassword(int driverId, String oldPassword, String newPassword, String confirmPassword) async {
    // Security check: Verify the driver is changing their own password
    final currentDriver = await getCurrentDriver();
    final currentDriverId = currentDriver['driverId'] as int;
    
    if (driverId != currentDriverId) {
      throw Exception('You can only change your own password.');
    }
    
    final passwordData = {
      'driverId': driverId,
      'changePassword': true,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmNewPassword': confirmPassword,
    };

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/Driver/$driverId?isSelfUpdate=true'),
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

  /// Upload driver profile photo
  /// Accepts a File and uploads it as multipart/form-data
  /// Returns updated DriverDto with photoUrl
  Future<Map<String, dynamic>> uploadPhoto(int driverId, File imageFile) async {
    // Validate file exists
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

    // Validate file size (max 5MB)
    final fileSize = await imageFile.length();
    const maxFileSize = 5 * 1024 * 1024; // 5MB
    if (fileSize > maxFileSize) {
      throw Exception('File size exceeds the maximum allowed size of 5MB');
    }

    // Validate file extension
    final fileName = imageFile.path.split('/').last.toLowerCase();
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final hasValidExtension = allowedExtensions.any((ext) => fileName.endsWith(ext));
    if (!hasValidExtension) {
      throw Exception('Invalid file type. Only image files (jpg, jpeg, png, gif, webp) are allowed.');
    }

    try {
      // Create multipart request
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/Driver/$driverId/photo');
      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      final headers = _headers(includeContentType: false);
      request.headers.addAll(headers);

      // Add file to request with field name "file"
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Extract the data field if it exists, otherwise use the whole response
        final driverData = responseData['data'];
        if (driverData != null && driverData is Map<String, dynamic>) {
          return driverData;
        } else if (responseData.containsKey('driverId')) {
          // Response is already the driver data
          return responseData;
        } else {
          throw Exception('Invalid response format from server');
        }
      } else {
        final errorBody = response.body;
        try {
          final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
          String message = 'Failed to upload photo';
          
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
          throw Exception('Failed to upload photo: ${response.statusCode} - $errorBody');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error uploading photo: $e');
    }
  }
}

