class RideHistoryDto {
  final int rideId;
  final int riderId;
  final int driverId;
  final DateTime requestedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String status;
  final double? fareEstimate;
  final double? fareFinal;
  final double? distanceKm;
  final int? durationMin;
  
  // Driver information
  final DriverInfo? driver;
  
  // Location information
  final LocationInfo? pickupLocation;
  final LocationInfo? dropoffLocation;

  RideHistoryDto({
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.requestedAt,
    this.startedAt,
    this.completedAt,
    required this.status,
    this.fareEstimate,
    this.fareFinal,
    this.distanceKm,
    this.durationMin,
    this.driver,
    this.pickupLocation,
    this.dropoffLocation,
  });

  factory RideHistoryDto.fromJson(Map<String, dynamic> json) {
    return RideHistoryDto(
      rideId: json['rideId'] as int,
      riderId: json['riderId'] as int,
      driverId: json['driverId'] as int,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      startedAt: json['startedAt'] != null 
          ? DateTime.parse(json['startedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      status: json['status'] as String,
      fareEstimate: (json['fareEstimate'] as num?)?.toDouble(),
      fareFinal: (json['fareFinal'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      durationMin: json['durationMin'] as int?,
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

  // Get display price (use fareFinal if available, otherwise fareEstimate)
  double get displayPrice => fareFinal ?? fareEstimate ?? 0.0;
  
  // Get driver full name
  String get driverName => driver?.fullName ?? 'Unknown Driver';
  
  // Get driver rating
  double get driverRating => driver?.ratingAvg ?? 0.0;
  
  // Get pickup address
  String get pickupAddress {
    if (pickupLocation == null) return 'Unknown Location';
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
  
  // Get dropoff address
  String get dropoffAddress {
    if (dropoffLocation == null) return 'Unknown Location';
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
}

class DriverInfo {
  final int driverId;
  final String firstName;
  final String lastName;
  final double? ratingAvg;

  DriverInfo({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    this.ratingAvg,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      driverId: json['driverId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
    );
  }

  String get fullName => '$firstName $lastName';
}

class LocationInfo {
  final int locationId;
  final String name;
  final String? addressLine;
  final String? city;
  final double lat;
  final double lng;

  LocationInfo({
    required this.locationId,
    required this.name,
    this.addressLine,
    this.city,
    required this.lat,
    required this.lng,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      locationId: json['locationId'] as int,
      name: json['name'] as String,
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

