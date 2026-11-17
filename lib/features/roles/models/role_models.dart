/// A role definition returned by GET /roles.
class RoleModel {
  const RoleModel({
    required this.name,
    required this.label,
    this.description,
  });

  final String name;
  final String label;
  final String? description;

  factory RoleModel.fromJson(Map<String, dynamic> json) => RoleModel(
        name: json['name'] as String,
        label: json['label'] as String,
        description: json['description'] as String?,
      );
}

/// A permission definition returned by GET /permissions.
class PermissionModel {
  const PermissionModel({
    required this.name,
    required this.label,
    required this.module,
  });

  final String name;
  final String label;
  final String module;

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      PermissionModel(
        name: json['name'] as String,
        label: json['label'] as String,
        module: json['module'] as String,
      );
}
