import 'package:equatable/equatable.dart';

/// Enum representing maintenance status.
enum MaintenanceStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  overdue;

  String get label {
    switch (this) {
      case MaintenanceStatus.scheduled:
        return 'Scheduled';
      case MaintenanceStatus.inProgress:
        return 'In Progress';
      case MaintenanceStatus.completed:
        return 'Completed';
      case MaintenanceStatus.cancelled:
        return 'Cancelled';
      case MaintenanceStatus.overdue:
        return 'Overdue';
    }
  }

  static MaintenanceStatus fromString(String? value) {
    return MaintenanceStatus.values.firstWhere(
      (e) => e.name == value?.toLowerCase().replaceAll('_', ''),
      orElse: () => MaintenanceStatus.scheduled,
    );
  }
}

/// Enum representing maintenance type.
enum MaintenanceType {
  preventive,
  corrective,
  calibration,
  inspection,
  repair;

  String get label {
    switch (this) {
      case MaintenanceType.preventive:
        return 'Preventive';
      case MaintenanceType.corrective:
        return 'Corrective';
      case MaintenanceType.calibration:
        return 'Calibration';
      case MaintenanceType.inspection:
        return 'Inspection';
      case MaintenanceType.repair:
        return 'Repair';
    }
  }

  static MaintenanceType fromString(String? value) {
    return MaintenanceType.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => MaintenanceType.preventive,
    );
  }
}

/// Represents a maintenance record.
class MaintenanceModel extends Equatable {
  const MaintenanceModel({
    required this.id,
    required this.maintenanceNumber,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.status,
    required this.scheduledDate,
    this.completedDate,
    this.technician,
    this.cost = 0,
    this.description,
    this.findings,
    this.recommendations,
    this.nextMaintenanceDate,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String maintenanceNumber;
  final int itemId;
  final String itemName;
  final MaintenanceType type;
  final MaintenanceStatus status;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final String? technician;
  final double cost;
  final String? description;
  final String? findings;
  final String? recommendations;
  final DateTime? nextMaintenanceDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) =>
      MaintenanceModel(
        id: json['id'] as int,
        maintenanceNumber: json['maintenance_number'] as String,
        itemId: json['item_id'] as int,
        itemName: json['item_name'] as String,
        type: MaintenanceType.fromString(json['type'] as String?),
        status: MaintenanceStatus.fromString(json['status'] as String?),
        scheduledDate: DateTime.parse(json['scheduled_date'] as String),
        completedDate: json['completed_date'] != null
            ? DateTime.parse(json['completed_date'] as String)
            : null,
        technician: json['technician'] as String?,
        cost: (json['cost'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String?,
        findings: json['findings'] as String?,
        recommendations: json['recommendations'] as String?,
        nextMaintenanceDate: json['next_maintenance_date'] != null
            ? DateTime.parse(json['next_maintenance_date'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'type': type.name,
        'status': status.name,
        'scheduled_date': scheduledDate.toIso8601String(),
        'technician': technician,
        'cost': cost,
        'description': description,
        'findings': findings,
        'recommendations': recommendations,
        'next_maintenance_date': nextMaintenanceDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id, maintenanceNumber, itemId, itemName, type, status,
        scheduledDate, completedDate, technician, cost, description,
        findings, recommendations, nextMaintenanceDate, createdAt, updatedAt,
      ];
}
