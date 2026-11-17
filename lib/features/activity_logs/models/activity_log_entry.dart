/// An audit entry returned by GET /activity-logs.
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.id,
    required this.action,
    required this.module,
    required this.userName,
    this.description,
    this.ipAddress,
    this.createdAt,
  });

  final int id;
  final String action;
  final String module;
  final String userName;
  final String? description;
  final String? ipAddress;
  final DateTime? createdAt;

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return ActivityLogEntry(
      id: json['id'] as int,
      action: json['action'] as String,
      module: json['module'] as String,
      userName: user is Map<String, dynamic>
          ? (user['name'] as String? ?? 'Unknown user')
          : 'Unknown user',
      description: json['description'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
