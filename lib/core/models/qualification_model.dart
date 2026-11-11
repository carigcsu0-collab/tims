import 'package:equatable/equatable.dart';

/// A TVET qualification / training program (e.g. EIM NC II).
class QualificationModel extends Equatable {
  const QualificationModel({
    required this.id,
    required this.name,
    required this.code,
    this.ncLevel,
    this.isActive = true,
    this.itemsCount = 0,
  });

  final int id;
  final String name;
  final String code;
  final String? ncLevel;
  final bool isActive;
  final int itemsCount;

  String get displayName => ncLevel == null ? name : '$name $ncLevel';

  factory QualificationModel.fromJson(Map<String, dynamic> json) =>
      QualificationModel(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String? ?? '',
        ncLevel: json['nc_level'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        itemsCount: json['items_count'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, name, code, ncLevel, isActive, itemsCount];
}
