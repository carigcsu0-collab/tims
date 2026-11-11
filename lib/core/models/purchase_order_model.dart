import 'package:equatable/equatable.dart';

/// Enum representing the status of a purchase order.
enum PurchaseOrderStatus {
  draft,
  sent,
  acknowledged,
  partial,
  received,
  cancelled;

  String get label {
    switch (this) {
      case PurchaseOrderStatus.draft:
        return 'Draft';
      case PurchaseOrderStatus.sent:
        return 'Sent to Supplier';
      case PurchaseOrderStatus.acknowledged:
        return 'Acknowledged';
      case PurchaseOrderStatus.partial:
        return 'Partially Received';
      case PurchaseOrderStatus.received:
        return 'Fully Received';
      case PurchaseOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PurchaseOrderStatus fromString(String? value) {
    return PurchaseOrderStatus.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => PurchaseOrderStatus.draft,
    );
  }
}

/// Represents a purchase order line item.
class PurchaseOrderItemModel extends Equatable {
  const PurchaseOrderItemModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantityOrdered,
    required this.unitCost,
    this.quantityReceived = 0,
    this.unit = 'pcs',
    this.notes,
  });

  final int id;
  final int itemId;
  final String itemName;
  final int quantityOrdered;
  final int quantityReceived;
  final double unitCost;
  final String unit;
  final String? notes;

  double get totalCost => quantityOrdered * unitCost;
  bool get isFullyReceived => quantityReceived >= quantityOrdered;

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) =>
      PurchaseOrderItemModel(
        id: json['id'] as int,
        itemId: json['item_id'] as int,
        itemName: json['item_name'] as String,
        quantityOrdered: json['quantity_ordered'] is int
            ? json['quantity_ordered'] as int
            : int.tryParse(json['quantity_ordered']?.toString() ?? '') ?? 0,
        quantityReceived: json['quantity_received'] is int
            ? json['quantity_received'] as int
            : int.tryParse(json['quantity_received']?.toString() ?? '') ?? 0,
        unitCost: json['unit_cost'] is num
            ? (json['unit_cost'] as num).toDouble()
            : double.tryParse(json['unit_cost']?.toString() ?? '') ?? 0,
        unit: json['unit'] as String? ?? 'pcs',
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity_ordered': quantityOrdered,
        'unit_cost': unitCost,
        'unit': unit,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id, itemId, itemName, quantityOrdered, quantityReceived,
        unitCost, unit, notes,
      ];
}

/// Represents a purchase order.
class PurchaseOrderModel extends Equatable {
  const PurchaseOrderModel({
    required this.id,
    required this.poNumber,
    required this.status,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    this.totalAmount = 0,
    this.purchaseRequestId,
    this.expectedDeliveryDate,
    this.actualDeliveryDate,
    this.paymentTerms,
    this.deliveryAddress,
    this.notes,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String poNumber;
  final PurchaseOrderStatus status;
  final int supplierId;
  final String supplierName;
  final List<PurchaseOrderItemModel> items;
  final double totalAmount;
  final int? purchaseRequestId;
  final DateTime? expectedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? paymentTerms;
  final String? deliveryAddress;
  final String? notes;
  final int? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return PurchaseOrderModel(
      id: json['id'] as int,
      poNumber: json['po_number'] as String,
      status: PurchaseOrderStatus.fromString(json['status'] as String?),
      supplierId: json['supplier_id'] is int
          ? json['supplier_id'] as int
          : (json['supplier_id'] is Map ? json['supplier_id']['id'] as int? : null) ?? 0,
      supplierName: json['supplier_name'] as String? ??
          (json['supplier'] is Map ? json['supplier']['name'] as String? : null) ?? '',
      items: itemsRaw
          .map((e) => PurchaseOrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
      purchaseRequestId: json['purchase_request_id'] is int
          ? json['purchase_request_id'] as int
          : int.tryParse(json['purchase_request_id']?.toString() ?? ''),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      actualDeliveryDate: json['actual_delivery_date'] != null
          ? DateTime.parse(json['actual_delivery_date'] as String)
          : null,
      paymentTerms: json['payment_terms'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] is int
          ? json['created_by'] as int
          : (json['created_by'] is Map ? json['created_by']['id'] as int? : null),
      createdByName: json['created_by_name'] as String? ??
          (json['created_by'] is Map ? json['created_by']['name'] as String? : null),
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
        'po_number': poNumber,
        'status': status.name,
        'supplier_id': supplierId,
        'total_amount': totalAmount,
        'purchase_request_id': purchaseRequestId,
        'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
        'payment_terms': paymentTerms,
        'delivery_address': deliveryAddress,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id, poNumber, status, supplierId, supplierName, items,
        totalAmount, purchaseRequestId, expectedDeliveryDate,
        actualDeliveryDate, paymentTerms, deliveryAddress, notes,
        createdBy, createdByName, createdAt, updatedAt,
      ];
}
