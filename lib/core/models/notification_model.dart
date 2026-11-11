import 'package:equatable/equatable.dart';

/// Enum representing notification type.
enum NotificationType {
  lowStock,
  purchaseRequestApproved,
  purchaseRequestRejected,
  purchaseOrderReceived,
  borrowingDue,
  borrowingOverdue,
  maintenanceDue,
  maintenanceCompleted,
  auditAssigned,
  general;

  String get label {
    switch (this) {
      case NotificationType.lowStock:
        return 'Low Stock Alert';
      case NotificationType.purchaseRequestApproved:
        return 'Purchase Request Approved';
      case NotificationType.purchaseRequestRejected:
        return 'Purchase Request Rejected';
      case NotificationType.purchaseOrderReceived:
        return 'Purchase Order Received';
      case NotificationType.borrowingDue:
        return 'Borrowing Due Soon';
      case NotificationType.borrowingOverdue:
        return 'Borrowing Overdue';
      case NotificationType.maintenanceDue:
        return 'Maintenance Due';
      case NotificationType.maintenanceCompleted:
        return 'Maintenance Completed';
      case NotificationType.auditAssigned:
        return 'Audit Assigned';
      case NotificationType.general:
        return 'Notification';
    }
  }

  static NotificationType fromString(String? value) {
    if (value == null) return NotificationType.general;
    final camel = value.toLowerCase().split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join();
    final lowerFirst = camel.isEmpty ? '' : '${camel[0].toLowerCase()}${camel.substring(1)}';
    return NotificationType.values.firstWhere(
      (e) => e.name == lowerFirst,
      orElse: () => NotificationType.general,
    );
  }
}

/// Represents a notification.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    this.actionUrl,
    this.data,
    this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as int,
        title: json['title'] as String,
        message: json['message'] as String,
        type: NotificationType.fromString(json['type'] as String?),
        isRead: json['is_read'] as bool? ?? false,
        actionUrl: json['action_url'] as String?,
        data: json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    String? actionUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        type: type ?? this.type,
        isRead: isRead ?? this.isRead,
        actionUrl: actionUrl ?? this.actionUrl,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, title, message, type, isRead, actionUrl, data, createdAt];
}
