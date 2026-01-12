
class LocationRequest {
  final String name;
  final String? addressLine;
  final String? city;
  final double lat;
  final double lng;

  const LocationRequest({
    required this.name,
    this.addressLine,
    this.city,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (addressLine != null) 'addressLine': addressLine,
      if (city != null) 'city': city,
      'lat': lat,
      'lng': lng,
    };
  }
}

class RideRequestDto {
  final int riderId;
  final int driverId;
  final LocationRequest pickupLocation;
  final LocationRequest dropoffLocation;
  final double distanceKm;
  final int durationMin;
  final double fareEstimate;
  final double fareFinal;
  final int? promoCodeId;
  final String paymentMethod;

  const RideRequestDto({
    required this.riderId,
    required this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.distanceKm,
    required this.durationMin,
    required this.fareEstimate,
    required this.fareFinal,
    this.promoCodeId,
    this.paymentMethod = 'cash',
  });
}

class RideBookingResponse {
  final int rideId;
  final int paymentId;
  final double totalAmount;
  final String currency;
  final String message;

  const RideBookingResponse({
    required this.rideId,
    required this.paymentId,
    required this.totalAmount,
    required this.currency,
    required this.message,
  });

  factory RideBookingResponse.fromJson(Map<String, dynamic> json) {
    return RideBookingResponse(
      rideId: json['rideId'] as int? ?? 0,
      paymentId: json['paymentId'] as int? ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
      message: json['message'] as String? ?? 'Ride booked successfully',
    );
  }
}

