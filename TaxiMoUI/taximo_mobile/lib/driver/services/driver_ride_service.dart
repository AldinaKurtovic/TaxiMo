import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/ride_request_model.dart';

class DriverRideService {
  Map<String, String> _headers() {
    final user = AuthProvider.username;
    final pass = AuthProvider.password;
    final basic = 'Basic ' + base64Encode(utf8.encode('$user:$pass'));
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': basic,
    };
  }

  /// Get ride requests assigned to the current driver
  /// Filters by status="requested" and driverId
  Future<List<RideRequestModel>> getRideRequests(int driverId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Ride').replace(
      queryParameters: {'status': 'requested'},
    );
    
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      
      // Handle both array and wrapped response
      List<dynamic> ridesList;
      if (jsonData is List) {
        ridesList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        ridesList = jsonData['data'] as List;
      } else {
        return [];
      }

      // Filter rides assigned to this driver and map to models
      return ridesList
          .map((json) => RideRequestModel.fromJson(json as Map<String, dynamic>))
          .where((ride) => ride.driverId == driverId)
          .toList();
    } else {
      throw Exception('Failed to fetch ride requests: ${response.statusCode} - ${response.body}');
    }
  }

  /// Accept a ride request
  Future<void> acceptRide(int rideId, int driverId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Ride/$rideId/accept');
    
    final response = await http.put(uri, headers: _headers());

    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = response.body;
      final errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
      final errorMessage = errorJson?['message'] as String? ?? 'Failed to accept ride';
      throw Exception(errorMessage);
    }
  }

  /// Reject a ride request
  Future<void> rejectRide(int rideId, int driverId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Ride/$rideId/reject');
    
    final response = await http.put(uri, headers: _headers());

    if (response.statusCode != 200 && response.statusCode != 204) {
      final errorBody = response.body;
      final errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
      final errorMessage = errorJson?['message'] as String? ?? 'Failed to reject ride';
      throw Exception(errorMessage);
    }
  }

  /// Get active or accepted rides for the current driver
  /// Returns rides with status="accepted" or status="active"
  Future<List<RideRequestModel>> getActiveRides(int driverId) async {
    final acceptedUri = Uri.parse('${ApiConfig.baseUrl}/api/Ride').replace(
      queryParameters: {'status': 'accepted'},
    );
    
    final activeUri = Uri.parse('${ApiConfig.baseUrl}/api/Ride').replace(
      queryParameters: {'status': 'active'},
    );
    
    final acceptedResponse = await http.get(acceptedUri, headers: _headers());
    final activeResponse = await http.get(activeUri, headers: _headers());

    List<RideRequestModel> allRides = [];

    // Process accepted rides
    if (acceptedResponse.statusCode == 200) {
      final jsonData = jsonDecode(acceptedResponse.body);
      List<dynamic> ridesList;
      if (jsonData is List) {
        ridesList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        ridesList = jsonData['data'] as List;
      } else {
        ridesList = [];
      }

      allRides.addAll(
        ridesList
            .map((json) => RideRequestModel.fromJson(json as Map<String, dynamic>))
            .where((ride) => ride.driverId == driverId),
      );
    }

    // Process active rides
    if (activeResponse.statusCode == 200) {
      final jsonData = jsonDecode(activeResponse.body);
      List<dynamic> ridesList;
      if (jsonData is List) {
        ridesList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('data')) {
        ridesList = jsonData['data'] as List;
      } else {
        ridesList = [];
      }

      allRides.addAll(
        ridesList
            .map((json) => RideRequestModel.fromJson(json as Map<String, dynamic>))
            .where((ride) => ride.driverId == driverId),
      );
    }

    return allRides;
  }

  /// Start a ride (changes status from Accepted to Active)
  Future<RideRequestModel> startRide(int rideId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Ride/$rideId/start');
    
    final response = await http.put(uri, headers: _headers());

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Parse the updated ride from response
      if (response.body.isNotEmpty) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return RideRequestModel.fromJson(jsonData);
      } else {
        throw Exception('Empty response from start ride endpoint');
      }
    } else {
      final errorBody = response.body;
      final errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
      final errorMessage = errorJson?['message'] as String? ?? 'Failed to start ride';
      throw Exception(errorMessage);
    }
  }

  /// Complete a ride (changes status from Active to Completed)
  Future<RideRequestModel> completeRide(int rideId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Ride/$rideId/complete');
    
    final response = await http.put(uri, headers: _headers());

    if (response.statusCode == 200 || response.statusCode == 204) {
      // Parse the updated ride from response
      if (response.body.isNotEmpty) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return RideRequestModel.fromJson(jsonData);
      } else {
        throw Exception('Empty response from complete ride endpoint');
      }
    } else {
      final errorBody = response.body;
      final errorJson = jsonDecode(errorBody) as Map<String, dynamic>?;
      final errorMessage = errorJson?['message'] as String? ?? 'Failed to complete ride';
      throw Exception(errorMessage);
    }
  }
}

