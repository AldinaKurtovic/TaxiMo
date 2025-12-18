import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/promo_code_dto.dart';

class PromoCodeService {
  Map<String, String> _headers() {
    return {
      'Accept': 'application/json',
      'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
    };
  }

  Future<List<PromoCodeDto>> getActivePromoCodes() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/PromoCode').replace(
      queryParameters: {'status': 'active'},
    );
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map((json) => PromoCodeDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error loading promo codes');
    }
  }
}

