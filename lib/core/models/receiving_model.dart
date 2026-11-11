import 'package:equatable/equatable.dart';

class ReceivingModel extends Equatable {
  const ReceivingModel({
    required this.id,
    required this.receivingNumber,
    this.purchaseOrderId,
    this.supplierId,
    required this.receivedDate,
    required this.receivedBy,
    this.notes,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String receivingNumber;
  final int? purchaseOrderId;
  final int? supplierId;
  final String receivedDate;
  final int receivedBy;
  final String? notes;
  final List<ReceivingItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReceivingModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return ReceivingModel(
      id: json['id'] as int,
      receivingNumber: json['receiving_number'] as String,
      purchaseOrderId: json['purchase_order_id'] as int?,
      supplierId: json['supplier_id'] as int?,
      receivedDate: json['received_date'] as String,
      receivedBy: json['received_by'] is int ? json['received_by'] as int : (json['received_by'] as Map?)?['id'] as int? ?? 0,
      notes: json['notes'] as String?,
      items: itemsRaw is List
          ? itemsRaw
              .map((e) => ReceivingItemModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
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
        'receiving_number': receivingNumber,
        'purchase_order_id': purchaseOrderId,
        'supplier_id': supplierId,
        'received_date': receivedDate,
        'received_by': receivedBy,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        receivingNumber,
        purchaseOrderId,
        supplierId,
        receivedDate,
        receivedBy,
        notes,
        items,
      ];
}

class ReceivingItemModel extends Equatable {
  const ReceivingItemModel({
    required this.id,
    required this.receivingId,
    required this.itemId,
    required this.quantityReceived,
    required this.unitCost,
    this.notes,
  });

  final int id;
  final int receivingId;
  final int itemId;
  final int quantityReceived;
  final double unitCost;
  final String? notes;

  factory ReceivingItemModel.fromJson(Map<String, dynamic> json) =>
      ReceivingItemModel(
        id: json['id'] as int,
        receivingId: json['receiving_id'] as int,
        itemId: json['item_id'] as int,
        quantityReceived: json['quantity_received'] is int
            ? json['quantity_received'] as int
            : int.tryParse(json['quantity_received']?.toString() ?? '') ?? 0,
        unitCost: json['unit_cost'] is num
            ? (json['unit_cost'] as num).toDouble()
            : double.tryParse(json['unit_cost']?.toString() ?? '') ?? 0.0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiving_id': receivingId,
        'item_id': itemId,
        'quantity_received': quantityReceived,
        'unit_cost': unitCost,
        'notes': notes,
      };

  @override
  List<Object?> get props =>
      [id, receivingId, itemId, quantityReceived, unitCost, notes];
}
