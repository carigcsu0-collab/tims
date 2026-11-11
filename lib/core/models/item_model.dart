import 'package:equatable/equatable.dart';

import 'package:tims/core/models/category_model.dart';

/// Enum representing the type of inventory item.
enum ItemType {
  tool,
  equipment,
  consumable,
  material,
  asset;

  String get label {
    switch (this) {
      case ItemType.tool:
        return 'Tool';
      case ItemType.equipment:
        return 'Equipment';
      case ItemType.consumable:
        return 'Consumable';
      case ItemType.material:
        return 'Material';
      case ItemType.asset:
        return 'Asset';
    }
  }

  static ItemType fromString(String? value) {
    return ItemType.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => ItemType.tool,
    );
  }
}

/// Enum representing the status of an inventory item.
enum ItemStatus {
  inStock,
  lowStock,
  outOfStock,
  reserved,
  damaged,
  deprecated;

  String get label {
    switch (this) {
      case ItemStatus.inStock:
        return 'In Stock';
      case ItemStatus.lowStock:
        return 'Low Stock';
      case ItemStatus.outOfStock:
        return 'Out of Stock';
      case ItemStatus.reserved:
        return 'Reserved';
      case ItemStatus.damaged:
        return 'Damaged';
      case ItemStatus.deprecated:
        return 'Deprecated';
    }
  }

  static ItemStatus fromString(String? value) {
    final normalized = value?.toLowerCase().replaceAll('_', '');
    return ItemStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => ItemStatus.inStock,
    );
  }
}

/// Physical condition of an item.
enum ItemCondition {
  working,
  needsRepair,
  condemned,
  missing;

  String get label {
    switch (this) {
      case ItemCondition.working:
        return 'Working';
      case ItemCondition.needsRepair:
        return 'Needs Repair';
      case ItemCondition.condemned:
        return 'Condemned / Disposed';
      case ItemCondition.missing:
        return 'Missing';
    }
  }

  /// Value used by the API (snake_case).
  String get apiValue {
    switch (this) {
      case ItemCondition.working:
        return 'working';
      case ItemCondition.needsRepair:
        return 'needs_repair';
      case ItemCondition.condemned:
        return 'condemned';
      case ItemCondition.missing:
        return 'missing';
    }
  }

  static ItemCondition fromString(String? value) {
    return ItemCondition.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => ItemCondition.working,
    );
  }
}

/// Represents an inventory item.
class ItemModel extends Equatable {
  const ItemModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.type,
    required this.status,
    required this.unit,
    this.condition = ItemCondition.working,
    this.qualificationId,
    this.qualificationName,
    this.qualificationCode,
    this.category,
    this.categoryId,
    this.barcode,
    this.description,
    this.brand,
    this.model,
    this.serialNumber,
    this.quantity = 0,
    this.minimumStock = 0,
    this.maximumStock = 0,
    this.reorderLevel = 0,
    this.unitCost = 0,
    this.totalValue = 0,
    this.location,
    this.imageUrl,
    this.supplierId,
    this.supplierName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String sku;
  final ItemType type;
  final ItemStatus status;
  final String unit;
  final ItemCondition condition;
  final int? qualificationId;
  final String? qualificationName;
  final String? qualificationCode;
  final CategoryModel? category;
  final int? categoryId;
  final String? barcode;
  final String? description;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final int quantity;
  final int minimumStock;
  final int maximumStock;
  final int reorderLevel;
  final double unitCost;
  final double totalValue;
  final String? location;
  final String? imageUrl;
  final int? supplierId;
  final String? supplierName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isConsumable =>
      type == ItemType.consumable || type == ItemType.material;
  bool get isLowStock => quantity <= minimumStock && quantity > 0;
  bool get isOutOfStock => quantity == 0;
  bool get needsReorder => quantity <= reorderLevel;
  bool get belowMinimum => quantity <= minimumStock;

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        id: json['id'] as int,
        name: json['name'] as String,
        sku: json['sku'] as String,
        type: ItemType.fromString(json['type'] as String?),
        status: ItemStatus.fromString(json['status'] as String?),
        unit: json['unit'] as String? ?? 'pcs',
        condition: ItemCondition.fromString(json['condition'] as String?),
        qualificationId: json['qualification_id'] is int
            ? json['qualification_id'] as int
            : int.tryParse(json['qualification_id']?.toString() ?? ''),
        qualificationName: (json['qualification'] as Map?)?['name'] as String?,
        qualificationCode: (json['qualification'] as Map?)?['code'] as String?,
        category: json['category'] != null
            ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        categoryId: json['category_id'] is int
            ? json['category_id'] as int
            : int.tryParse(json['category_id']?.toString() ?? '') ,
        barcode: json['barcode'] as String?,
        description: json['description'] as String?,
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        serialNumber: json['serial_number'] as String?,
        quantity: json['quantity'] is int
            ? json['quantity'] as int
            : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
        minimumStock: json['minimum_stock'] is int
            ? json['minimum_stock'] as int
            : int.tryParse(json['minimum_stock']?.toString() ?? '') ?? 0,
        maximumStock: json['maximum_stock'] is int
            ? json['maximum_stock'] as int
            : int.tryParse(json['maximum_stock']?.toString() ?? '') ?? 0,
        reorderLevel: json['reorder_level'] is int
            ? json['reorder_level'] as int
            : int.tryParse(json['reorder_level']?.toString() ?? '') ?? 0,
        unitCost: json['unit_cost'] is num
            ? (json['unit_cost'] as num).toDouble()
            : double.tryParse(json['unit_cost']?.toString() ?? '') ?? 0,
        totalValue: json['total_value'] is num
            ? (json['total_value'] as num).toDouble()
            : double.tryParse(json['total_value']?.toString() ?? '') ?? 0,
        location: json['location'] as String?,
        imageUrl: json['image_url'] as String?,
        supplierId: json['supplier_id'] is int
            ? json['supplier_id'] as int
            : int.tryParse(json['supplier_id']?.toString() ?? ''),
        supplierName: json['supplier_name'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'type': type.name,
        'status': status.name,
        'unit': unit,
        'condition': condition.apiValue,
        'qualification_id': qualificationId,
        'category_id': categoryId,
        'barcode': barcode,
        'description': description,
        'brand': brand,
        'model': model,
        'serial_number': serialNumber,
        'quantity': quantity,
        'minimum_stock': minimumStock,
        'maximum_stock': maximumStock,
        'reorder_level': reorderLevel,
        'unit_cost': unitCost,
        'location': location,
        'supplier_id': supplierId,
        'is_active': isActive,
      };

  ItemModel copyWith({
    int? id,
    String? name,
    String? sku,
    ItemType? type,
    ItemStatus? status,
    String? unit,
    ItemCondition? condition,
    int? qualificationId,
    CategoryModel? category,
    int? categoryId,
    String? barcode,
    String? description,
    String? brand,
    String? model,
    String? serialNumber,
    int? quantity,
    int? minimumStock,
    int? maximumStock,
    int? reorderLevel,
    double? unitCost,
    double? totalValue,
    String? location,
    String? imageUrl,
    int? supplierId,
    String? supplierName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ItemModel(
        id: id ?? this.id,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        type: type ?? this.type,
        status: status ?? this.status,
        unit: unit ?? this.unit,
        condition: condition ?? this.condition,
        qualificationId: qualificationId ?? this.qualificationId,
        qualificationName: qualificationName,
        qualificationCode: qualificationCode,
        category: category ?? this.category,
        categoryId: categoryId ?? this.categoryId,
        barcode: barcode ?? this.barcode,
        description: description ?? this.description,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        serialNumber: serialNumber ?? this.serialNumber,
        quantity: quantity ?? this.quantity,
        minimumStock: minimumStock ?? this.minimumStock,
        maximumStock: maximumStock ?? this.maximumStock,
        reorderLevel: reorderLevel ?? this.reorderLevel,
        unitCost: unitCost ?? this.unitCost,
        totalValue: totalValue ?? this.totalValue,
        location: location ?? this.location,
        imageUrl: imageUrl ?? this.imageUrl,
        supplierId: supplierId ?? this.supplierId,
        supplierName: supplierName ?? this.supplierName,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id, name, sku, type, status, unit, condition, qualificationId,
        qualificationName, qualificationCode, categoryId, barcode,
        description, brand, model, serialNumber, quantity, minimumStock,
        maximumStock, reorderLevel, unitCost, totalValue, location,
        imageUrl, supplierId, supplierName, isActive, createdAt, updatedAt,
      ];
}
