import 'package:equatable/equatable.dart';

enum ReturnCondition { good, damaged, lost, repaired }

extension ReturnConditionX on ReturnCondition {
  String get label {
    switch (this) {
      case ReturnCondition.good:
        return 'Good';
      case ReturnCondition.damaged:
        return 'Damaged';
      case ReturnCondition.lost:
        return 'Lost';
      case ReturnCondition.repaired:
        return 'Repaired';
    }
  }

  static ReturnCondition fromString(String? value) {
    return ReturnCondition.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => ReturnCondition.good,
    );
  }
}

class ReturnModel extends Equatable {
  const ReturnModel({
    required this.id,
    required this.returnNumber,
    this.borrowingId,
    required this.itemId,
    required this.returnedBy,
    required this.returnDate,
    required this.quantity,
    this.condition,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String returnNumber;
  final int? borrowingId;
  final int itemId;
  final int returnedBy;
  final String returnDate;
  final int quantity;
  final ReturnCondition? condition;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReturnModel.fromJson(Map<String, dynamic> json) => ReturnModel(
        id: json['id'] as int,
        returnNumber: json['return_number'] as String,
        borrowingId: json['borrowing_id'] is int
            ? json['borrowing_id'] as int
            : (json['borrowing_id'] is Map ? json['borrowing_id']['id'] as int? : null)
                ?? int.tryParse(json['borrowing_id']?.toString() ?? ''),
        itemId: json['item_id'] is int
            ? json['item_id'] as int
            : (json['item_id'] is Map ? json['item_id']['id'] as int? : null)
                ?? int.tryParse(json['item_id']?.toString() ?? '') ?? 0,
        returnedBy: json['returned_by'] is int ? json['returned_by'] as int : (json['returned_by'] as Map?)?['id'] as int? ?? 0,
        returnDate: json['return_date'] as String,
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
        condition: json['condition'] != null
            ? ReturnConditionX.fromString(json['condition'] as String?)
            : null,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'return_number': returnNumber,
        'borrowing_id': borrowingId,
        'item_id': itemId,
        'returned_by': returnedBy,
        'return_date': returnDate,
        'quantity': quantity,
        'condition': condition?.name,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id,
        returnNumber,
        borrowingId,
        itemId,
        returnedBy,
        returnDate,
        quantity,
        condition,
        notes,
      ];
}
