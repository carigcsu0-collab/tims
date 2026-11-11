import 'package:equatable/equatable.dart';

/// Represents a supplier.
class SupplierModel extends Equatable {
  const SupplierModel({
    required this.id,
    required this.name,
    this.code,
    this.contactPerson,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.province,
    this.zipCode,
    this.tin,
    this.website,
    this.notes,
    this.isActive = true,
    this.rating,
    this.totalPurchases = 0,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? code;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? province;
  final String? zipCode;
  final String? tin;
  final String? website;
  final String? notes;
  final bool isActive;
  final double? rating;
  final int totalPurchases;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
        id: json['id'] as int,
        name: json['name'] as String,
        code: json['code'] as String?,
        contactPerson: json['contact_person'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        province: json['province'] as String?,
        zipCode: json['zip_code'] as String?,
        tin: json['tin'] as String?,
        website: json['website'] as String?,
        notes: json['notes'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        rating: json['rating'] is num
            ? (json['rating'] as num).toDouble()
            : double.tryParse(json['rating']?.toString() ?? ''),
        totalPurchases: json['total_purchases'] is int
            ? json['total_purchases'] as int
            : int.tryParse(json['total_purchases']?.toString() ?? '') ?? 0,
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
        'contact_person': contactPerson,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'province': province,
        'zip_code': zipCode,
        'tin': tin,
        'website': website,
        'notes': notes,
        'is_active': isActive,
      };

  SupplierModel copyWith({
    int? id,
    String? name,
    String? code,
    String? contactPerson,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? province,
    String? zipCode,
    String? tin,
    String? website,
    String? notes,
    bool? isActive,
    double? rating,
    int? totalPurchases,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SupplierModel(
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        contactPerson: contactPerson ?? this.contactPerson,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        city: city ?? this.city,
        province: province ?? this.province,
        zipCode: zipCode ?? this.zipCode,
        tin: tin ?? this.tin,
        website: website ?? this.website,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        rating: rating ?? this.rating,
        totalPurchases: totalPurchases ?? this.totalPurchases,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [
        id, name, code, contactPerson, email, phone, address, city,
        province, zipCode, tin, website, notes, isActive, rating,
        totalPurchases, createdAt, updatedAt,
      ];
}
