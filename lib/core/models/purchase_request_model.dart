import 'package:equatable/equatable.dart';

/// Enum representing the status of a purchase request.
enum PurchaseRequestStatus {
  draft,
  pending,
  approved,
  rejected,
  converted;

  String get label {
    switch (this) {
      case PurchaseRequestStatus.draft:
        return 'Draft';
      case PurchaseRequestStatus.pending:
        return 'Pending Approval';
      case PurchaseRequestStatus.approved:
        return 'Approved';
      case PurchaseRequestStatus.rejected:
        return 'Rejected';
      case PurchaseRequestStatus.converted:
        return 'Converted to PO';
    }
  }

  static PurchaseRequestStatus fromString(String? value) {
    return PurchaseRequestStatus.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => PurchaseRequestStatus.draft,
    );
  }
}

/// Represents a line item in a purchase request.
class PurchaseRequestItemModel extends Equatable {
  const PurchaseRequestItemModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitCost,
    this.unit = 'pcs',
    this.notes,
  });

  final int id;
  final int itemId;
  final String itemName;
  final int quantity;
  final double unitCost;
  final String unit;
  final String? notes;

  double get totalCost => quantity * unitCost;

  factory PurchaseRequestItemModel.fromJson(Map<String, dynamic> json) =>
      PurchaseRequestItemModel(
        id: json['id'] as int,
        itemId: json['item_id'] as int,
        itemName: json['item_name'] as String,
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
        unitCost: json['unit_cost'] is num
            ? (json['unit_cost'] as num).toDouble()
            : double.tryParse(json['unit_cost']?.toString() ?? '') ?? 0,
        unit: json['unit'] as String? ?? 'pcs',
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
        'unit_cost': unitCost,
        'unit': unit,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, itemId, itemName, quantity, unitCost, unit, notes];
}

/// Represents a purchase request.
class PurchaseRequestModel extends Equatable {
  const PurchaseRequestModel({
    required this.id,
    required this.prNumber,
    required this.status,
    required this.requestedBy,
    required this.requestedByName,
    required this.items,
    this.totalAmount = 0,
    this.purpose,
    this.department,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectedReason,
    this.purchaseOrderId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String prNumber;
  final PurchaseRequestStatus status;
  final int requestedBy;
  final String requestedByName;
  final List<PurchaseRequestItemModel> items;
  final double totalAmount;
  final String? purpose;
  final String? department;
  final int? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectedReason;
  final int? purchaseOrderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PurchaseRequestModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return PurchaseRequestModel(
      id: json['id'] as int,
      prNumber: json['pr_number'] as String,
      status: PurchaseRequestStatus.fromString(json['status'] as String?),
      requestedBy: json['requested_by'] is int
          ? json['requested_by'] as int
          : (json['requested_by'] is Map ? json['requested_by']['id'] as int? : null) ?? 0,
      requestedByName: json['requested_by_name'] as String? ??
          (json['requested_by'] is Map ? json['requested_by']['name'] as String? : null) ?? '',
      items: itemsRaw
          .map((e) => PurchaseRequestItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
      purpose: json['purpose'] as String?,
      department: json['department'] as String?,
      approvedBy: json['approved_by'] is int
          ? json['approved_by'] as int
          : (json['approved_by'] is Map ? json['approved_by']['id'] as int? : null),
      approvedByName: json['approved_by_name'] as String? ??
          (json['approved_by'] is Map ? json['approved_by']['name'] as String? : null),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectedReason: json['rejected_reason'] as String?,
      purchaseOrderId: json['purchase_order_id'] is int
          ? json['purchase_order_id'] as int
          : int.tryParse(json['purchase_order_id']?.toString() ?? ''),
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
        'pr_number': prNumber,
        'status': status.name,
        'requested_by': requestedBy,
        'total_amount': totalAmount,
        'purpose': purpose,
        'department': department,
        'items': items.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id, prNumber, status, requestedBy, requestedByName, items,
        totalAmount, purpose, department, approvedBy, approvedByName,
        approvedAt, rejectedReason, purchaseOrderId, createdAt, updatedAt,
      ];
}
