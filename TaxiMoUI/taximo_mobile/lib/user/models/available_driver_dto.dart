class AvailableDriverDto {
  final int driverId;
  final String driverName;
  final String vehicleType;
  final int capacity;
  final double priceKm;
  final int etaMinutes;

  const AvailableDriverDto({
    required this.driverId,
    required this.driverName,
    required this.vehicleType,
    required this.capacity,
    required this.priceKm,
    required this.etaMinutes,
  });

  factory AvailableDriverDto.fromJson(Map<String, dynamic> json) {
    return AvailableDriverDto(
      driverId: json['driverId'] as int,
      driverName: json['driverName'] as String,
      vehicleType: json['vehicleType'] as String? ?? '',
      capacity: json['capacity'] as int,
      priceKm: (json['priceKm'] as num).toDouble(),
      etaMinutes: json['etaMinutes'] as int,
    );
  }
}

