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
    return pickupLocationName ?? 'Unknown';
  }

  String get dropoffLocation {
    return dropoffLocationName ?? 'Unknown';
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
      driverFirstName: json['driver'] != null
          ? (json['driver'] as Map<String, dynamic>)['firstName'] as String?
          : null,
      driverLastName: json['driver'] != null
          ? (json['driver'] as Map<String, dynamic>)['lastName'] as String?
          : null,
      riderFirstName: json['rider'] != null
          ? (json['rider'] as Map<String, dynamic>)['firstName'] as String?
          : null,
      riderLastName: json['rider'] != null
          ? (json['rider'] as Map<String, dynamic>)['lastName'] as String?
          : null,
      vehiclePlateNumber: json['vehicle'] != null
          ? (json['vehicle'] as Map<String, dynamic>)['plateNumber'] as String?
          : null,
      pickupLocationName: json['pickupLocation'] != null
          ? (json['pickupLocation'] as Map<String, dynamic>)['name'] as String?
          : null,
      pickupLocationAddress: json['pickupLocation'] != null
          ? (json['pickupLocation'] as Map<String, dynamic>)['addressLine'] as String?
          : null,
      dropoffLocationName: json['dropoffLocation'] != null
          ? (json['dropoffLocation'] as Map<String, dynamic>)['name'] as String?
          : null,
      dropoffLocationAddress: json['dropoffLocation'] != null
          ? (json['dropoffLocation'] as Map<String, dynamic>)['addressLine'] as String?
          : null,
      pickupLocationLat: json['pickupLocation'] != null
          ? (json['pickupLocation'] as Map<String, dynamic>)['lat'] != null
              ? (json['pickupLocation'] as Map<String, dynamic>)['lat'] as double
              : null
          : null,
      pickupLocationLng: json['pickupLocation'] != null
          ? (json['pickupLocation'] as Map<String, dynamic>)['lng'] != null
              ? (json['pickupLocation'] as Map<String, dynamic>)['lng'] as double
              : null
          : null,
      dropoffLocationLat: json['dropoffLocation'] != null
          ? (json['dropoffLocation'] as Map<String, dynamic>)['lat'] != null
              ? (json['dropoffLocation'] as Map<String, dynamic>)['lat'] as double
              : null
          : null,
      dropoffLocationLng: json['dropoffLocation'] != null
          ? (json['dropoffLocation'] as Map<String, dynamic>)['lng'] != null
              ? (json['dropoffLocation'] as Map<String, dynamic>)['lng'] as double
              : null
          : null,
    );
  }
}

