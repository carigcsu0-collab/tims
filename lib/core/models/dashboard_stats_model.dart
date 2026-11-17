import 'package:equatable/equatable.dart';

/// A consumable that has fallen to or below its minimum restock threshold.
class LowStockAlert extends Equatable {
  const LowStockAlert({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.minimumStock,
    this.qualificationCode,
  });

  final int id;
  final String name;
  final String sku;
  final String unit;
  final int quantity;
  final int minimumStock;
  final String? qualificationCode;

  bool get isOutOfStock => quantity <= 0;

  factory LowStockAlert.fromJson(Map<String, dynamic> json) => LowStockAlert(
        id: json['id'] as int,
        name: json['name'] as String,
        sku: json['sku'] as String? ?? '',
        unit: json['unit'] as String? ?? 'pcs',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        minimumStock: (json['minimum_stock'] as num?)?.toInt() ?? 0,
        qualificationCode: (json['qualification'] as Map?)?['code'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, name, sku, unit, quantity, minimumStock, qualificationCode];
}

/// Represents dashboard statistics.
class DashboardStatsModel extends Equatable {
  const DashboardStatsModel({
    required this.totalItems,
    required this.totalTools,
    this.totalEquipment = 0,
    this.totalConsumables = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.totalValue = 0,
    this.needsRepairCount = 0,
    this.condemnedCount = 0,
    this.missingCount = 0,
    this.lowStockConsumables = const [],
    this.pendingPurchaseRequests = 0,
    this.activeBorrowings = 0,
    this.pendingMaintenance = 0,
    this.recentMovements = 0,
  });

  final int totalItems;
  final int totalTools;
  final int totalEquipment;
  final int totalConsumables;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalValue;
  final int needsRepairCount;
  final int condemnedCount;
  final int missingCount;
  final List<LowStockAlert> lowStockConsumables;
  final int pendingPurchaseRequests;
  final int activeBorrowings;
  final int pendingMaintenance;
  final int recentMovements;

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      DashboardStatsModel(
        totalItems: _int(json['total_items']),
        totalTools: _int(json['total_tools']),
        totalEquipment: _int(json['total_equipment']),
        totalConsumables: _int(json['total_consumables']),
        lowStockCount: _int(json['low_stock_count']),
        outOfStockCount: _int(json['out_of_stock_count']),
        // The API sends total_inventory_value, possibly as a numeric string.
        totalValue: double.tryParse(
                (json['total_inventory_value'] ?? json['total_value'] ?? '0')
                    .toString()) ??
            0,
        needsRepairCount: _int(json['needs_repair_count']),
        condemnedCount: _int(json['condemned_count']),
        missingCount: _int(json['missing_count']),
        lowStockConsumables: (json['low_stock_consumables'] as List? ?? [])
            .map((e) => LowStockAlert.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingPurchaseRequests: _int(json['pending_purchase_requests']),
        activeBorrowings: _int(json['active_borrowings']),
        pendingMaintenance: _int(json['pending_maintenance']),
        recentMovements: _int(json['recent_movements']),
      );

  @override
  List<Object?> get props => [
        totalItems, totalTools, totalEquipment, totalConsumables,
        lowStockCount, outOfStockCount, totalValue, needsRepairCount,
        condemnedCount, missingCount, lowStockConsumables,
        pendingPurchaseRequests, activeBorrowings, pendingMaintenance,
        recentMovements,
      ];
}
