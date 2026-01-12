class DriverDto {
  final int driverId;
  final String firstName;
  final String lastName;
  final double ratingAvg;
  final int totalRides;
  final String status;
  final double? currentLatitude;
  final double? currentLongitude;
  final int? vehicleId;
  final String? photoUrl;

  const DriverDto({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    required this.ratingAvg,
    required this.totalRides,
    required this.status,
    this.currentLatitude,
    this.currentLongitude,
    this.vehicleId,
    this.photoUrl,
  });

  factory DriverDto.fromJson(Map<String, dynamic> json) {
    return DriverDto(
      driverId: json['driverId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      totalRides: json['totalRides'] as int? ?? 0,
      status: json['status'] as String? ?? 'offline',
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      vehicleId: (json['vehicleId'] as int?),
      photoUrl: json['photoUrl'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
  bool get isOnline => status.toLowerCase() == 'active';
}

