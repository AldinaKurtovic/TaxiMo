class UserModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? phone;
  final DateTime? dateOfBirth;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> roles;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.phone,
    this.dateOfBirth,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.roles,
  });

  String get fullName => '$firstName $lastName';

  bool get isActive => status.toLowerCase() == 'active';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      status: json['status'] as String? ?? 'Inactive',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      roles: json['roles'] != null
          ? (json['roles'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'roles': roles,
    };
  }
}

