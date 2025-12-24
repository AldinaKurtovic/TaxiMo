import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../models/driver_model.dart';
import '../../config/api_config.dart';

class DriverAuthService {
  /// Driver login using dedicated driver authentication endpoint
  Future<DriverModel?> login(String username, String password) async {
    // Save credentials for future API calls
    AuthProvider.username = username;
    AuthProvider.password = password;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/Driver/Login'),
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
        return DriverModel.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Driver login failed: $e');
    }
  }
}

