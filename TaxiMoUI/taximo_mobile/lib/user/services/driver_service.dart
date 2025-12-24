import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/driver_dto.dart';

class DriverService {
  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    final basic = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
    return {
      'Accept': 'application/json',
      'Authorization': basic,
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

  /// Get driver profile by username search
  Future<DriverDto?> getDriverByUsername(String username) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Driver').replace(
      queryParameters: {'search': username},
    );
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      if (jsonList.isNotEmpty) {
        return DriverDto.fromJson(jsonList[0] as Map<String, dynamic>);
      }
      return null;
    } else {
      throw Exception('Error loading driver profile');
    }
  }

  /// Get driver review stats (averageRating, totalReviews)
  Future<Map<String, dynamic>> getDriverStats(int driverId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Driver/$driverId/stats');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error loading driver stats: ${response.statusCode}');
    }
  }
}

