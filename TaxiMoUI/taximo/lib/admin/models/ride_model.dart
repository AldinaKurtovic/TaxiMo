class RideModel {
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
  final String? driverFirstName;
  final String? driverLastName;
  final String? riderFirstName;
  final String? riderLastName;
  final String? vehiclePlateNumber;
  final String? pickupLocationName;
  final String? pickupLocationAddress;
  final String? dropoffLocationName;
  final String? dropoffLocationAddress;
  final double? pickupLocationLat;
  final double? pickupLocationLng;
  final double? dropoffLocationLat;
  final double? dropoffLocationLng;
  final double? driverLatitude;
  final double? driverLongitude;

  RideModel({
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
    this.driverFirstName,
    this.driverLastName,
    this.riderFirstName,
    this.riderLastName,
    this.vehiclePlateNumber,
    this.pickupLocationName,
    this.pickupLocationAddress,
    this.dropoffLocationName,
    this.dropoffLocationAddress,
    this.pickupLocationLat,
    this.pickupLocationLng,
    this.dropoffLocationLat,
    this.dropoffLocationLng,
    this.driverLatitude,
    this.driverLongitude,
  });

  String get driverName {
    if (driverFirstName != null && driverLastName != null) {
      return '$driverFirstName $driverLastName';
    }
    return 'Driver $driverId';
  }

  String get riderName {
    if (riderFirstName != null && riderLastName != null) {
      return '$riderFirstName $riderLastName';
    }
    return 'User $riderId';
  }

  String get vehicleCode {
    return vehiclePlateNumber ?? 'TX-000';
  }

  String get pickupLocation {
    if (pickupLocationName != null && pickupLocationName!.isNotEmpty) {
      return pickupLocationName!;
    }
    if (pickupLocationAddress != null && pickupLocationAddress!.isNotEmpty) {
      return pickupLocationAddress!;
    }
    return 'Location $pickupLocationId';
  }

  String get dropoffLocation {
    if (dropoffLocationName != null && dropoffLocationName!.isNotEmpty) {
      return dropoffLocationName!;
    }
    if (dropoffLocationAddress != null && dropoffLocationAddress!.isNotEmpty) {
      return dropoffLocationAddress!;
    }
    return 'Location $dropoffLocationId';
  }

  String get timeRange {
    if (startedAt != null && completedAt != null) {
      return '${startedAt!.hour.toString().padLeft(2, '0')}:${startedAt!.minute.toString().padLeft(2, '0')}-'
          '${completedAt!.hour.toString().padLeft(2, '0')}:${completedAt!.minute.toString().padLeft(2, '0')}';
    } else if (requestedAt != null) {
      final estEnd = requestedAt.add(Duration(minutes: durationMin ?? 20));
      return '${requestedAt.hour.toString().padLeft(2, '0')}:${requestedAt.minute.toString().padLeft(2, '0')}-'
          '${estEnd.hour.toString().padLeft(2, '0')}:${estEnd.minute.toString().padLeft(2, '0')}';
    }
    return '--:--';
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>?;
    final rider = json['rider'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final pickupLocation = json['pickupLocation'] as Map<String, dynamic>?;
    final dropoffLocation = json['dropoffLocation'] as Map<String, dynamic>?;

    return RideModel(
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
      driverFirstName: driver?['firstName'] as String?,
      driverLastName: driver?['lastName'] as String?,
      riderFirstName: rider?['firstName'] as String?,
      riderLastName: rider?['lastName'] as String?,
      vehiclePlateNumber: vehicle?['plateNumber'] as String?,
      pickupLocationName: pickupLocation?['name'] as String?,
      pickupLocationAddress: pickupLocation?['addressLine'] as String?,
      dropoffLocationName: dropoffLocation?['name'] as String?,
      dropoffLocationAddress: dropoffLocation?['addressLine'] as String?,
      pickupLocationLat: pickupLocation?['lat'] != null
          ? (pickupLocation!['lat'] as num).toDouble()
          : null,
      pickupLocationLng: pickupLocation?['lng'] != null
          ? (pickupLocation!['lng'] as num).toDouble()
          : null,
      dropoffLocationLat: dropoffLocation?['lat'] != null
          ? (dropoffLocation!['lat'] as num).toDouble()
          : null,
      dropoffLocationLng: dropoffLocation?['lng'] != null
          ? (dropoffLocation!['lng'] as num).toDouble()
          : null,
      driverLatitude: json['driverLatitude'] != null
          ? (json['driverLatitude'] as num).toDouble()
          : null,
      driverLongitude: json['driverLongitude'] != null
          ? (json['driverLongitude'] as num).toDouble()
          : null,
    );
  }
}

