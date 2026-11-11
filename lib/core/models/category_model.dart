import 'package:equatable/equatable.dart';

/// Represents an inventory category.
class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.parentId,
    this.itemCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? code;
  final String? description;
  final int? parentId;
  final int itemCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String?,
        description: json['description'] as String?,
        parentId: json['parent_id'] as int?,
        itemCount: json['item_count'] as int? ?? 0,
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
        'code': code,
        'description': description,
        'parent_id': parentId,
        'is_active': isActive,
      };

  CategoryModel copyWith({
    int? id,
    String? name,
    String? code,
    String? description,
    int? parentId,
    int? itemCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        description: description ?? this.description,
        parentId: parentId ?? this.parentId,
        itemCount: itemCount ?? this.itemCount,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, name, code, description, parentId, itemCount, isActive, createdAt, updatedAt];
}
