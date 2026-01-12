class UserModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? phone;
  final DateTime? dateOfBirth;
  final String status;
  final String? photoUrl;
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
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.roles,
  });

  String get fullName => '$firstName $lastName';

  bool get isActive => status.toLowerCase() == 'active';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int? ?? 0,
      firstName: (json['firstName'] as String?)?.trim() ?? '',
      lastName: (json['lastName'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim(),
      dateOfBirth: json['dateOfBirth'] != null && json['dateOfBirth'] is String
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      status: (json['status'] as String?)?.trim() ?? 'Inactive',
      photoUrl: (json['photoUrl'] as String?)?.trim(),
      createdAt: json['createdAt'] != null && json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null && json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      roles: json['roles'] != null && json['roles'] is List
          ? (json['roles'] as List).map((e) => e.toString()).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'roles': roles,
    };
    
    // Only include optional fields if they are not null
    if (phone != null && phone!.isNotEmpty) {
      json['phone'] = phone;
    }
    
    if (dateOfBirth != null) {
      json['dateOfBirth'] = dateOfBirth!.toIso8601String();
    }
    
    return json;
  }
}

