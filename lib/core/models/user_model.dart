import 'package:equatable/equatable.dart';

/// Represents an authenticated user session.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.permissions = const [],
    this.avatarUrl,
    this.phone,
    this.position,
    this.department,
    this.centerName,
    this.centerId,
    this.isActive = true,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String? role;
  final List<String> permissions;
  final String? avatarUrl;
  final String? phone;
  final String? position;
  final String? department;
  final String? centerName;
  final int? centerId;
  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'];
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String?,
      permissions: permissionsRaw is List
          ? permissionsRaw.map((e) => e.toString()).toList()
          : [],
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      position: json['position'] as String?,
      department: json['department'] as String?,
      centerName: json['center_name'] as String?,
      centerId: json['center_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'permissions': permissions,
        'avatar_url': avatarUrl,
        'phone': phone,
        'position': position,
        'department': department,
        'center_name': centerName,
        'center_id': centerId,
        'is_active': isActive,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    List<String>? permissions,
    String? avatarUrl,
    String? phone,
    String? position,
    String? department,
    String? centerName,
    int? centerId,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        permissions: permissions ?? this.permissions,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        phone: phone ?? this.phone,
        position: position ?? this.position,
        department: department ?? this.department,
        centerName: centerName ?? this.centerName,
        centerId: centerId ?? this.centerId,
        isActive: isActive ?? this.isActive,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        permissions,
        avatarUrl,
        phone,
        position,
        department,
        centerName,
        centerId,
        isActive,
        lastLoginAt,
        createdAt,
        updatedAt,
      ];
}
