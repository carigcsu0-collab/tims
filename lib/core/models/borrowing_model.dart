import 'package:equatable/equatable.dart';

/// Enum representing borrowing status.
enum BorrowingStatus {
  requested,
  approved,
  borrowed,
  returned,
  overdue,
  rejected,
  cancelled;

  String get label {
    switch (this) {
      case BorrowingStatus.requested:
        return 'Requested';
      case BorrowingStatus.approved:
        return 'Approved';
      case BorrowingStatus.borrowed:
        return 'Borrowed';
      case BorrowingStatus.returned:
        return 'Returned';
      case BorrowingStatus.overdue:
        return 'Overdue';
      case BorrowingStatus.rejected:
        return 'Rejected';
      case BorrowingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BorrowingStatus fromString(String? value) {
    return BorrowingStatus.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => BorrowingStatus.requested,
    );
  }
}

/// Represents a borrowing transaction.
class BorrowingModel extends Equatable {
  const BorrowingModel({
    required this.id,
    required this.borrowNumber,
    required this.itemId,
    required this.itemName,
    required this.borrowerId,
    required this.borrowerName,
    required this.status,
    required this.borrowDate,
    this.expectedReturnDate,
    this.actualReturnDate,
    this.quantity = 1,
    this.purpose,
    this.approvedBy,
    this.approvedByName,
    this.conditionOut,
    this.conditionIn,
    this.notes,
    this.returnId,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String borrowNumber;
  final int itemId;
  final String itemName;
  final int borrowerId;
  final String borrowerName;
  final BorrowingStatus status;
  final DateTime borrowDate;
  final DateTime? expectedReturnDate;
  final DateTime? actualReturnDate;
  final int quantity;
  final String? purpose;
  final int? approvedBy;
  final String? approvedByName;
  final String? conditionOut;
  final String? conditionIn;
  final String? notes;
  final int? returnId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOverdue {
    if (status != BorrowingStatus.borrowed) return false;
    final due = expectedReturnDate;
    if (due == null) return false;
    return DateTime.now().isAfter(due);
  }

  factory BorrowingModel.fromJson(Map<String, dynamic> json) {
    // Handle Laravel relation overwriting foreign key columns
    final approvedByRaw = json['approved_by'];
    final int? approvedById = approvedByRaw is int
        ? approvedByRaw
        : (approvedByRaw is Map ? approvedByRaw['id'] as int? : null);

    // Extract item_name from nested relation if not a direct column
    final itemName = json['item_name'] as String? ??
        (json['item'] is Map ? json['item']['name'] as String? : null) ??
        '';

    // Extract borrower_name from nested relation if not a direct column
    final borrowerName = json['borrower_name'] as String? ??
        (json['borrower'] is Map ? json['borrower']['name'] as String? : null) ??
        '';

    // Extract approved_by_name from nested relation if not a direct column
    final approvedByName = json['approved_by_name'] as String? ??
        (approvedByRaw is Map ? approvedByRaw['name'] as String? : null);

    return BorrowingModel(
      id: json['id'] as int,
      borrowNumber: json['borrow_number'] as String,
      itemId: json['item_id'] is int
          ? json['item_id'] as int
          : (json['item'] is Map ? json['item']['id'] as int? : null) ?? 0,
      itemName: itemName,
      borrowerId: json['borrower_id'] is int
          ? json['borrower_id'] as int
          : (json['borrower'] is Map ? json['borrower']['id'] as int? : null) ?? 0,
      borrowerName: borrowerName,
      status: BorrowingStatus.fromString(json['status'] as String?),
      borrowDate: DateTime.parse(json['borrow_date'] as String),
      expectedReturnDate: json['expected_return_date'] != null
          ? DateTime.parse(json['expected_return_date'] as String)
          : null,
      actualReturnDate: json['actual_return_date'] != null
          ? DateTime.parse(json['actual_return_date'] as String)
          : null,
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      purpose: json['purpose'] as String?,
      approvedBy: approvedById,
      approvedByName: approvedByName,
      conditionOut: json['condition_out'] as String?,
      conditionIn: json['condition_in'] as String?,
      notes: json['notes'] as String?,
      returnId: json['return_id'] is int
          ? json['return_id'] as int
          : (json['return_id'] is Map ? json['return_id']['id'] as int? : null)
              ?? int.tryParse(json['return_id']?.toString() ?? ''),
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
        'item_id': itemId,
        'borrower_id': borrowerId,
        'status': status.name,
        'borrow_date': borrowDate.toIso8601String(),
        'expected_return_date': expectedReturnDate?.toIso8601String(),
        'quantity': quantity,
        'purpose': purpose,
        'condition_out': conditionOut,
        'notes': notes,
      };

  @override
  List<Object?> get props => [
        id, borrowNumber, itemId, itemName, borrowerId, borrowerName,
        status, borrowDate, expectedReturnDate, actualReturnDate,
        quantity, purpose, approvedBy, approvedByName, conditionOut,
        conditionIn, notes, returnId, createdAt, updatedAt,
      ];
}
