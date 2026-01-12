class DriverModel {
  final int driverId;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String status;
  final List<RoleModel> roles;
  final String? photoUrl;

  DriverModel({
    required this.driverId,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.status,
    required this.roles,
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName';

  bool get isActive => status.toLowerCase() == 'active';

  bool hasRole(String roleName) {
    return roles.any((role) => role.name.toLowerCase() == roleName.toLowerCase());
  }

  bool get isDriver => hasRole('Driver');

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      driverId: json['driverId'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'Inactive',
      roles: json['roles'] != null
          ? (json['roles'] as List)
              .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'status': status,
      'roles': roles.map((e) => e.toJson()).toList(),
      'photoUrl': photoUrl,
    };
  }
}

class RoleModel {
  final int roleId;
  final String name;
  final String? description;

  RoleModel({
    required this.roleId,
    required this.name,
    this.description,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      roleId: json['roleId'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'name': name,
      'description': description,
    };
  }
}

