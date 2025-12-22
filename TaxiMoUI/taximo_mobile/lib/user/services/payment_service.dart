import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class PaymentService {
  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
    };
  }

  /// Get all payments for the current user
  Future<List<Map<String, dynamic>>> getPayments() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Payment');
    
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
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

