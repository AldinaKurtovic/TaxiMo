class DriverModel {
  final int driverId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String licenseNumber;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.driverId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.licenseNumber,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
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
      status: json['status'] as String? ?? 'Inactive',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
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
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

