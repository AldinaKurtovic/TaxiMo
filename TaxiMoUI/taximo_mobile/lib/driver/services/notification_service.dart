import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../models/notification_dto.dart';

class DriverNotificationService {
  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    
    if (user == null || user.isEmpty || pass == null || pass.isEmpty) {
      throw Exception('Authentication credentials are missing. Please login again.');
    }
    
    final credentials = base64Encode(utf8.encode('$user:$pass'));
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic $credentials',
    };
  }

  Future<List<DriverNotificationDto>> getDriverNotifications(int driverId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/notifications/driver/$driverId');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map((json) => DriverNotificationDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error loading notifications: ${response.statusCode} - ${response.body}');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/notifications/$notificationId/mark-read?type=driver');
    final response = await http.post(uri, headers: _headers());

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Error marking notification as read: ${response.statusCode} - ${response.body}');
    }
  }
}

