import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../../config/api_config.dart';

class MobileAuthService {
  /// User login using dedicated user authentication endpoint
  Future<UserModel?> login(String username, String password) async {
    // Save credentials for future API calls
    AuthProvider.username = username;
    AuthProvider.password = password;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/User/Login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return UserModel.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('User login failed: $e');
    }
  }
}
