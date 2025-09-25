// lib/features/suppliers/data/models/supplier_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/supplier.dart';

part 'supplier_model.g.dart';

@JsonSerializable()
class SupplierModel extends Supplier {
  const SupplierModel({
    required super.id,
    required super.name,
    super.code,
    required super.documentType,
    required super.documentNumber,
    super.contactPerson,
    super.email,
    super.phone,
    super.mobile,
    super.address,
    super.city,
    super.state,
    super.country,
    super.postalCode,
    super.website,
    required super.status,
    required super.currency,
    required super.paymentTermsDays,
    required super.creditLimit,
    required super.discountPercentage,
    super.notes,
    super.metadata,
    required super.organizationId,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      documentType: _parseDocumentType(json['documentType'] as String)!,
      documentNumber: json['documentNumber'] as String,
      contactPerson: json['contactPerson'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      mobile: json['mobile'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      website: json['website'] as String?,
      status: _parseSupplierStatus(json['status'] as String),
      currency: json['currency'] as String? ?? 'COP',
      paymentTermsDays: (json['paymentTermsDays'] as num?)?.toInt() ?? 30,
      creditLimit: _parseDouble(json['creditLimit']) ?? 0.0,
      discountPercentage: _parseDouble(json['discountPercentage']) ?? 0.0,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      organizationId: json['organizationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null 
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'documentType': documentType.name,
      'documentNumber': documentNumber,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'website': website,
      'status': status.name,
      'currency': currency,
      'paymentTermsDays': paymentTermsDays,
      'creditLimit': creditLimit,
      'discountPercentage': discountPercentage,
      'notes': notes,
      'metadata': metadata,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // Métodos para convertir entidad a model y viceversa
  factory SupplierModel.fromEntity(Supplier supplier) {
    return SupplierModel(
      id: supplier.id,
      name: supplier.name,
      code: supplier.code,
      documentType: supplier.documentType,
      documentNumber: supplier.documentNumber,
      contactPerson: supplier.contactPerson,
      email: supplier.email,
      phone: supplier.phone,
      mobile: supplier.mobile,
      address: supplier.address,
      city: supplier.city,
      state: supplier.state,
      country: supplier.country,
      postalCode: supplier.postalCode,
      website: supplier.website,
      status: supplier.status,
      currency: supplier.currency,
      paymentTermsDays: supplier.paymentTermsDays,
      creditLimit: supplier.creditLimit,
      discountPercentage: supplier.discountPercentage,
      notes: supplier.notes,
      metadata: supplier.metadata,
      organizationId: supplier.organizationId,
      createdAt: supplier.createdAt,
      updatedAt: supplier.updatedAt,
      deletedAt: supplier.deletedAt,
    );
  }

  Supplier toEntity() {
    return Supplier(
      id: id,
      name: name,
      code: code,
      documentType: documentType,
      documentNumber: documentNumber,
      contactPerson: contactPerson,
      email: email,
      phone: phone,
      mobile: mobile,
      address: address,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      website: website,
      status: status,
      currency: currency,
      paymentTermsDays: paymentTermsDays,
      creditLimit: creditLimit,
      discountPercentage: discountPercentage,
      notes: notes,
      metadata: metadata,
      organizationId: organizationId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Métodos auxiliares para parsear enums
  static SupplierStatus _parseSupplierStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SupplierStatus.active;
      case 'inactive':
        return SupplierStatus.inactive;
      case 'blocked':
        return SupplierStatus.blocked;
      default:
        return SupplierStatus.inactive;
    }
  }

  static DocumentType? _parseDocumentType(String? documentType) {
    if (documentType == null) return DocumentType.other; // Default value instead of null
    
    switch (documentType.toLowerCase()) {
      case 'nit':
        return DocumentType.nit;
      case 'cc':
      case 'cedula':
        return DocumentType.cc;
      case 'ce':
        return DocumentType.ce;
      case 'passport':
      case 'pasaporte':
        return DocumentType.passport;
      case 'rut':
        return DocumentType.rut;
      case 'other':
      case 'otro':
        return DocumentType.other;
      default:
        return DocumentType.other;
    }
  }

  /// Helper method to parse double values that might come as strings
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}