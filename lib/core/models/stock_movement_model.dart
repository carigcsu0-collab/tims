import 'package:equatable/equatable.dart';

/// Enum representing stock movement type.
enum StockMovementType {
  purchase,
  issuance,
  borrowing,
  returnIn,
  returnOut,
  adjustment,
  transfer,
  damage,
  disposal;

  String get label {
    switch (this) {
      case StockMovementType.purchase:
        return 'Purchase / Receiving';
      case StockMovementType.issuance:
        return 'Issuance';
      case StockMovementType.borrowing:
        return 'Borrowing Out';
      case StockMovementType.returnIn:
        return 'Return In';
      case StockMovementType.returnOut:
        return 'Return Out';
      case StockMovementType.adjustment:
        return 'Stock Adjustment';
      case StockMovementType.transfer:
        return 'Transfer';
      case StockMovementType.damage:
        return 'Damage / Loss';
      case StockMovementType.disposal:
        return 'Disposal';
    }
  }

  static StockMovementType fromString(String? value) {
    return StockMovementType.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => StockMovementType.adjustment,
    );
  }
}

/// Represents a stock movement record.
class StockMovementModel extends Equatable {
  const StockMovementModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.balanceAfter,
    required this.userId,
    required this.userName,
    this.reference,
    this.referenceId,
    this.notes,
    this.createdAt,
  });

  final int id;
  final int itemId;
  final String itemName;
  final StockMovementType type;
  final int quantity;
  final int balanceAfter;
  final int userId;
  final String userName;
  final String? reference;
  final int? referenceId;
  final String? notes;
  final DateTime? createdAt;

  bool get isIncoming =>
      type == StockMovementType.purchase ||
      type == StockMovementType.returnIn;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) =>
      StockMovementModel(
        id: json['id'] as int,
        itemId: json['item_id'] as int,
        itemName: json['item_name'] as String,
        type: StockMovementType.fromString(json['type'] as String?),
        quantity: json['quantity'] as int? ?? 0,
        balanceAfter: json['balance_after'] as int? ?? 0,
        userId: json['user_id'] as int,
        userName: json['user_name'] as String,
        reference: json['reference'] as String?,
        referenceId: json['reference_id'] as int?,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  @override
  List<Object?> get props => [
        id, itemId, itemName, type, quantity, balanceAfter,
        userId, userName, reference, referenceId, notes, createdAt,
      ];
}
