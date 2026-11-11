import 'package:equatable/equatable.dart';

class IssuanceModel extends Equatable {
  const IssuanceModel({
    required this.id,
    required this.issuanceNumber,
    required this.issuedTo,
    required this.issuedBy,
    required this.issueDate,
    this.purpose,
    this.notes,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String issuanceNumber;
  final int issuedTo;
  final int issuedBy;
  final String issueDate;
  final String? purpose;
  final String? notes;
  final List<IssuanceItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory IssuanceModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return IssuanceModel(
      id: json['id'] as int,
      issuanceNumber: json['issuance_number'] as String,
      issuedTo: json['issued_to'] is int ? json['issued_to'] as int : (json['issued_to'] as Map?)?['id'] as int? ?? 0,
      issuedBy: json['issued_by'] is int ? json['issued_by'] as int : (json['issued_by'] as Map?)?['id'] as int? ?? 0,
      issueDate: json['issue_date'] as String,
      purpose: json['purpose'] as String?,
      notes: json['notes'] as String?,
      items: itemsRaw is List
          ? itemsRaw
              .map((e) => IssuanceItemModel.fromJson(e as Map<String, dynamic>))
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
        'issuance_number': issuanceNumber,
        'issued_to': issuedTo,
        'issued_by': issuedBy,
        'issue_date': issueDate,
        'purpose': purpose,
        'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props =>
      [id, issuanceNumber, issuedTo, issuedBy, issueDate, purpose, notes, items];
}

class IssuanceItemModel extends Equatable {
  const IssuanceItemModel({
    required this.id,
    required this.issuanceId,
    required this.itemId,
    required this.quantity,
    this.notes,
  });

  final int id;
  final int issuanceId;
  final int itemId;
  final int quantity;
  final String? notes;

  factory IssuanceItemModel.fromJson(Map<String, dynamic> json) =>
      IssuanceItemModel(
        id: json['id'] as int,
        issuanceId: json['issuance_id'] as int,
        itemId: json['item_id'] as int,
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'issuance_id': issuanceId,
        'item_id': itemId,
        'quantity': quantity,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, issuanceId, itemId, quantity, notes];
}
