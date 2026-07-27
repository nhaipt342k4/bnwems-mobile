import 'dart:convert';

typedef StaffRoleName = String; // 'LEAD' | 'TECHNICAL' | 'MANAGER' | ...

class UserRole {
  final String roleId;
  final StaffRoleName roleName;

  UserRole({
    required this.roleId,
    required this.roleName,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      roleId: json['roleId']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? 'TECHNICAL',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'roleName': roleName,
    };
  }
}

class AuthUser {
  final String id;
  final String username;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;

  AuthUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
  });

  bool get isLead =>
      role.roleName.toUpperCase() == 'LEAD' ||
      role.roleName.toLowerCase().contains('leader') ||
      role.roleName.toLowerCase().contains('trưởng nhóm');

  bool get isManager =>
      role.roleName.toUpperCase() == 'MANAGER' ||
      role.roleName.toUpperCase() == 'ADMIN' ||
      role.roleName.toLowerCase().contains('manager') ||
      role.roleName.toLowerCase().contains('quản lý');

  factory AuthUser.fromDtoJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      role: UserRole.fromJson(json['role'] as Map<String, dynamic>? ?? {}),
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      role: UserRole.fromJson(json['role'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role.toJson(),
    };
  }

  String encode() => jsonEncode(toJson());

  factory AuthUser.decode(String str) => AuthUser.fromJson(jsonDecode(str));
}
