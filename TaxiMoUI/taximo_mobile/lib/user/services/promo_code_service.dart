import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../models/promo_code_dto.dart';

class PromoCodeService {
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

  Future<List<PromoCodeDto>> getActivePromoCodes() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/PromoCode').replace(
      queryParameters: {'status': 'active'},
    );
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      // API returns paginated response with 'data' and 'pagination' fields
      final List<dynamic> jsonList = jsonData['data'] as List<dynamic>;
      return jsonList
          .map((json) => PromoCodeDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error loading promo codes: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get all promo codes (for viewing in promo codes screen)
  Future<List<PromoCodeDto>> getAllPromoCodes() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/PromoCode');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      // API returns paginated response with 'data' and 'pagination' fields
      final List<dynamic> jsonList = jsonData['data'] as List<dynamic>;
      return jsonList
          .map((json) => PromoCodeDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error loading promo codes: ${response.statusCode} - ${response.body}');
    }
  }
}

