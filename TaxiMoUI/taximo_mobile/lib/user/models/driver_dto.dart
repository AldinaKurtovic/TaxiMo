class DriverDto {
  final int driverId;
  final String firstName;
  final String lastName;
  final double ratingAvg;
  final double? currentLatitude;
  final double? currentLongitude;
  final int? vehicleId;

  const DriverDto({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    required this.ratingAvg,
    this.currentLatitude,
    this.currentLongitude,
    this.vehicleId,
  });

  factory DriverDto.fromJson(Map<String, dynamic> json) {
    return DriverDto(
      driverId: json['driverId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      vehicleId: (json['vehicleId'] as int?),
    );
  }

  String get fullName => '$firstName $lastName';
}

