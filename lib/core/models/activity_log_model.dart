import 'package:equatable/equatable.dart';

/// Represents an activity log entry.
class ActivityLogModel extends Equatable {
  const ActivityLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.module,
    this.description,
    this.ipAddress,
    this.userAgent,
    this.properties,
    this.createdAt,
  });

  final int id;
  final int userId;
  final String userName;
  final String action;
  final String module;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? properties;
  final DateTime? createdAt;

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) =>
      ActivityLogModel(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        userName: json['user_name'] as String,
        action: json['action'] as String,
        module: json['module'] as String,
        description: json['description'] as String?,
        ipAddress: json['ip_address'] as String?,
        userAgent: json['user_agent'] as String?,
        properties: json['properties'] as Map<String, dynamic>?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  @override
  List<Object?> get props =>
      [id, userId, userName, action, module, description, ipAddress, userAgent, properties, createdAt];
}
