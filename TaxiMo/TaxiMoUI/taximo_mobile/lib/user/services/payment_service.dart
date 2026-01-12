import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../config/api_config.dart';

class PaymentService {
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

  /// Get all payments for the current user
  Future<List<Map<String, dynamic>>> getPayments() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Payment');
    
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body);
      
      // Handle both array and wrapped response
      if (jsonData is List) {
        return jsonData.cast<Map<String, dynamic>>();
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        return (jsonData['data'] as List).cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch payments: ${response.statusCode} - ${response.body}');
    }
  }
}

