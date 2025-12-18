import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/driver_dto.dart';

class DriverService {
  Map<String, String> _headers() {
    return {
      'Accept': 'application/json',
      'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
    };
  }

  Future<List<DriverDto>> getAvailableDrivers() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/rides/available-drivers');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map((json) => DriverDto.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error loading drivers');
    }
  }
}

