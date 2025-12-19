import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/ride_request_dto.dart';

class LocationDto {
  final int locationId;
  final int? userId;
  final String name;
  final String? addressLine;
  final String? city;
  final double lat;
  final double lng;

  LocationDto({
    required this.locationId,
    this.userId,
    required this.name,
    this.addressLine,
    this.city,
    required this.lat,
    required this.lng,
  });

  factory LocationDto.fromJson(Map<String, dynamic> json) {
    return LocationDto(
      locationId: json['locationId'] as int,
      userId: json['userId'] as int?,
      name: json['name'] as String,
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class RideService {
  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic bW9iaWxlOnRlc3Q=',
    };
  }

  Future<LocationDto> createLocation(LocationRequest locationRequest, int? userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/Location');
    final body = jsonEncode({
      if (userId != null) 'userId': userId,
      'name': locationRequest.name,
      if (locationRequest.addressLine != null) 'addressLine': locationRequest.addressLine,
      if (locationRequest.city != null) 'city': locationRequest.city,
      'lat': locationRequest.lat,
      'lng': locationRequest.lng,
    });

    final response = await http.post(uri, headers: _headers(), body: body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      // Handle both direct DTO and wrapped response
      if (jsonData.containsKey('data')) {
        return LocationDto.fromJson(jsonData['data'] as Map<String, dynamic>);
      }
      return LocationDto.fromJson(jsonData);
    } else {
      final errorBody = response.body;
      throw Exception('Failed to create location: ${response.statusCode} - $errorBody');
    }
  }

  Future<RideBookingResponse> bookRide(RideRequestDto request) async {
    try {
      // Step 1: Create pickup location
      final pickupLocation = await createLocation(request.pickupLocation, request.riderId);

      // Step 2: Create dropoff location
      final dropoffLocation = await createLocation(request.dropoffLocation, request.riderId);

      // Step 3: Create ride (backend will automatically select the active vehicle for the driver)
      final rideUri = Uri.parse('${ApiConfig.baseUrl}/api/Ride');
      final rideBody = jsonEncode({
        'riderId': request.riderId,
        'driverId': request.driverId,
        'pickupLocationId': pickupLocation.locationId,
        'dropoffLocationId': dropoffLocation.locationId,
        'requestedAt': DateTime.now().toIso8601String(),
        'status': 'requested',
        'distanceKm': request.distanceKm,
        'durationMin': request.durationMin,
      });

      print('Booking ride - URL: $rideUri');
      print('Booking ride - Request body: $rideBody');
      print('Booking ride - Headers: ${_headers()}');

      final rideResponse = await http.post(rideUri, headers: _headers(), body: rideBody);

      print('Booking ride - Response status: ${rideResponse.statusCode}');
      print('Booking ride - Response body: ${rideResponse.body}');

      if (rideResponse.statusCode == 201 || rideResponse.statusCode == 200) {
        final jsonData = jsonDecode(rideResponse.body) as Map<String, dynamic>;
        
        // Extract rideId from response
        int rideId = 0;
        if (jsonData.containsKey('data')) {
          final data = jsonData['data'] as Map<String, dynamic>;
          rideId = data['rideId'] as int? ?? 0;
        } else if (jsonData.containsKey('rideId')) {
          rideId = jsonData['rideId'] as int;
        } else if (jsonData.containsKey('rideId')) {
          rideId = jsonData['rideId'] as int;
        }

        // Step 4: Create PromoUsage if promo code was used
        if (request.promoCodeId != null && rideId > 0) {
          try {
            await createPromoUsage(rideId, request.riderId, request.promoCodeId!);
          } catch (e) {
            // Log error but don't fail the booking if promo usage creation fails
            print('Failed to create promo usage: $e');
          }
        }

        return RideBookingResponse(
          rideId: rideId,
          message: jsonData['message'] as String? ?? 'Ride booked successfully',
        );
      } else {
        final errorBody = rideResponse.body;
        print('ERROR - Failed to create ride: ${rideResponse.statusCode}');
        print('ERROR - Response body: $errorBody');
        throw Exception('Failed to create ride: ${rideResponse.statusCode} - $errorBody');
      }
    } catch (e) {
      print('ERROR - Booking failed: $e');
      rethrow;
    }
  }

  Future<void> createPromoUsage(int rideId, int userId, int promoId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/PromoUsage');
    final body = jsonEncode({
      'promoId': promoId,
      'userId': userId,
      'rideId': rideId,
      'usedAt': DateTime.now().toIso8601String(),
    });

    final response = await http.post(uri, headers: _headers(), body: body);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create promo usage: ${response.statusCode}');
    }
  }

}

