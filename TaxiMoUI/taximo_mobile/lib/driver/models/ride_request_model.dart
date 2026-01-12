class RideRequestModel {
  final int rideId;
  final int riderId;
  final int driverId;
  final int vehicleId;
  final int pickupLocationId;
  final int dropoffLocationId;
  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String status;
  final double? fareEstimate;
  final double? fareFinal;
  final double? distanceKm;
  final int? durationMin;

  // Navigation properties
  final RiderInfo? rider;
  final DriverInfo? driver;
  final LocationInfo? pickupLocation;
  final LocationInfo? dropoffLocation;

  RideRequestModel({
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.vehicleId,
    required this.pickupLocationId,
    required this.dropoffLocationId,
    required this.requestedAt,
    this.startedAt,
    this.completedAt,
    required this.status,
    this.fareEstimate,
    this.fareFinal,
    this.distanceKm,
    this.durationMin,
    this.rider,
    this.driver,
    this.pickupLocation,
    this.dropoffLocation,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) {
    return RideRequestModel(
      rideId: json['rideId'] as int,
      riderId: json['riderId'] as int,
      driverId: json['driverId'] as int,
      vehicleId: json['vehicleId'] as int,
      pickupLocationId: json['pickupLocationId'] as int,
      dropoffLocationId: json['dropoffLocationId'] as int,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      status: json['status'] as String,
      fareEstimate: json['fareEstimate'] != null 
          ? (json['fareEstimate'] as num).toDouble() 
          : null,
      fareFinal: json['fareFinal'] != null 
          ? (json['fareFinal'] as num).toDouble() 
          : null,
      distanceKm: json['distanceKm'] != null 
          ? (json['distanceKm'] as num).toDouble() 
          : null,
      durationMin: json['durationMin'] as int?,
      rider: json['rider'] != null 
          ? RiderInfo.fromJson(json['rider'] as Map<String, dynamic>) 
          : null,
      driver: json['driver'] != null 
          ? DriverInfo.fromJson(json['driver'] as Map<String, dynamic>) 
          : null,
      pickupLocation: json['pickupLocation'] != null 
          ? LocationInfo.fromJson(json['pickupLocation'] as Map<String, dynamic>) 
          : null,
      dropoffLocation: json['dropoffLocation'] != null 
          ? LocationInfo.fromJson(json['dropoffLocation'] as Map<String, dynamic>) 
          : null,
    );
  }

  String get passengerName {
    if (rider != null) {
      return '${rider!.firstName} ${rider!.lastName}';
    }
    return 'Unknown Passenger';
  }

  String get pickupAddress {
    if (pickupLocation != null) {
      final parts = <String>[];
      if (pickupLocation!.name.isNotEmpty) parts.add(pickupLocation!.name);
      if (pickupLocation!.addressLine != null && pickupLocation!.addressLine!.isNotEmpty) {
        parts.add(pickupLocation!.addressLine!);
      }
      if (pickupLocation!.city != null && pickupLocation!.city!.isNotEmpty) {
        parts.add(pickupLocation!.city!);
      }
      return parts.join(', ');
    }
    return 'Unknown Location';
  }

  String get dropoffAddress {
    if (dropoffLocation != null) {
      final parts = <String>[];
      if (dropoffLocation!.name.isNotEmpty) parts.add(dropoffLocation!.name);
      if (dropoffLocation!.addressLine != null && dropoffLocation!.addressLine!.isNotEmpty) {
        parts.add(dropoffLocation!.addressLine!);
      }
      if (dropoffLocation!.city != null && dropoffLocation!.city!.isNotEmpty) {
        parts.add(dropoffLocation!.city!);
      }
      return parts.join(', ');
    }
    return 'Unknown Location';
  }

  String get pickupCoordinates {
    if (pickupLocation != null) {
      return '${pickupLocation!.lat.toStringAsFixed(6)}, ${pickupLocation!.lng.toStringAsFixed(6)}';
    }
    return 'Unknown';
  }

  String get dropoffCoordinates {
    if (dropoffLocation != null) {
      return '${dropoffLocation!.lat.toStringAsFixed(6)}, ${dropoffLocation!.lng.toStringAsFixed(6)}';
    }
    return 'Unknown';
  }

  String get formattedPrice {
    final price = fareEstimate ?? 0.0;
    return '${price.toStringAsFixed(2)} EUR';
  }

  String get formattedRequestTime {
    final now = DateTime.now();
    final difference = now.difference(requestedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }
}

class RiderInfo {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  RiderInfo({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  factory RiderInfo.fromJson(Map<String, dynamic> json) {
    return RiderInfo(
      userId: json['userId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class DriverInfo {
  final int driverId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  DriverInfo({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      driverId: json['driverId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class LocationInfo {
  final int locationId;
  final int? userId;
  final String name;
  final String? addressLine;
  final String? city;
  final double lat;
  final double lng;

  LocationInfo({
    required this.locationId,
    this.userId,
    required this.name,
    this.addressLine,
    this.city,
    required this.lat,
    required this.lng,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
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

