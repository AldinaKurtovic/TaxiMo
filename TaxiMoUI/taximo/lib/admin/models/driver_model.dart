class DriverModel {
  final int driverId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? currentLatitude;
  final double? currentLongitude;

  DriverModel({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.currentLatitude,
    this.currentLongitude,
  });

  String get fullName => '$firstName $lastName';

  bool get isActive => status.toLowerCase() == 'active';

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      driverId: json['driverId'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      licenseNumber: json['licenseNumber'] as String? ?? '',
      licenseExpiry: json['licenseExpiry'] != null
          ? DateTime.parse(json['licenseExpiry'] as String)
          : DateTime.now().add(const Duration(days: 365)),
      status: json['status'] as String? ?? 'Inactive',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      currentLatitude: json['currentLatitude'] != null
          ? (json['currentLatitude'] as num).toDouble()
          : null,
      currentLongitude: json['currentLongitude'] != null
          ? (json['currentLongitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

