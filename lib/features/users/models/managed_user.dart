/// A user account as managed from the User Management screen.
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.phone,
    this.position,
    this.department,
    this.centerName,
    this.isActive = true,
    this.lastLoginAt,
  });

  final int id;
  final String name;
  final String email;
  final String? role;
  final String? phone;
  final String? position;
  final String? department;
  final String? centerName;
  final bool isActive;
  final DateTime? lastLoginAt;

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String?,
        phone: json['phone'] as String?,
        position: json['position'] as String?,
        department: json['department'] as String?,
        centerName: json['center_name'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.parse(json['last_login_at'] as String)
            : null,
      );
}
