import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../auth/models/user_model.dart';

/// Service for uploading user profile photos
class UserPhotoService {
  final ImagePicker _picker = ImagePicker();
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      throw Exception('Authentication credentials are missing. Please login again.');
    }
    
    final credentials = base64Encode(utf8.encode('$user:$pass'));
    return {
      'Authorization': 'Basic $credentials',
    };
  }

  /// Pick an image from gallery or file system
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Compress to reduce file size
        maxWidth: 1024, // Limit dimensions
        maxHeight: 1024,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Show image source selection dialog and pick image
  Future<XFile?> pickImageWithSource(BuildContext context) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose from Files'),
              onTap: () => Navigator.pop(context, ImageSource.gallery), // Still uses gallery but allows file access
            ),
            // Camera option (optional, can be enabled if needed)
            // ListTile(
            //   leading: const Icon(Icons.camera_alt),
            //   title: const Text('Take Photo'),
            //   onTap: () => Navigator.pop(context, ImageSource.camera),
            // ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    return await pickImage(source: source);
  }

  /// Validate image file
  void _validateImage(XFile image) {
    // Check file extension
    final extension = image.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Unsupported image format. Please use JPG, JPEG, PNG, or WEBP.');
    }

    // Check file size (will be checked after reading, but validate path first)
    // Note: File size check will be done in upload method after reading bytes
  }

  /// Upload user photo to backend
  /// Returns updated UserModel with new photoUrl
  Future<UserModel> uploadPhoto(int userId, XFile imageFile) async {
    try {
      // Validate image
      _validateImage(imageFile);

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Check file size
      if (bytes.length > maxFileSizeBytes) {
        throw Exception('Image file is too large. Maximum size is 5MB.');
      }

      // Create multipart request
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/photo');
      final request = http.MultipartRequest('POST', uri);

      // Add headers (excluding Content-Type, which will be set by multipart)
      final headers = _headers();
      headers.forEach((key, value) {
        request.headers[key] = value;
      });

      // Determine content type based on file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      String contentType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      // Add file to request with field name "file"
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.name.split('/').last,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse response
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Handle both wrapped and direct responses
        Map<String, dynamic> userData;
        if (responseData.containsKey('data')) {
          userData = responseData['data'] as Map<String, dynamic>;
        } else if (responseData.containsKey('userId')) {
          userData = responseData;
        } else {
          throw Exception('Invalid response format from server');
        }

        // Create and return updated UserModel
        return UserModel.fromJson(userData);
      } else {
        // Parse error response
        String errorMessage = 'Failed to upload photo: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          } else if (errorData.containsKey('title')) {
            errorMessage = errorData['title'].toString();
          }
        } catch (e) {
          errorMessage = 'Failed to upload photo: ${response.statusCode} - ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  /// Delete user photo
  Future<bool> deletePhoto(int userId) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/photo');
      final response = await http.delete(
        uri,
        headers: _headers(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        String errorMessage = 'Failed to delete photo: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
          }
        } catch (e) {
          // Ignore parsing errors
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete photo: ${e.toString()}');
    }
  }
}

