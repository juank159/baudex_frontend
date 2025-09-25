// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupplierModel _$SupplierModelFromJson(Map<String, dynamic> json) =>
    SupplierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      documentType: $enumDecode(_$DocumentTypeEnumMap, json['documentType']),
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
      status: $enumDecode(_$SupplierStatusEnumMap, json['status']),
      currency: json['currency'] as String,
      paymentTermsDays: (json['paymentTermsDays'] as num).toInt(),
      creditLimit: (json['creditLimit'] as num).toDouble(),
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      organizationId: json['organizationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
    );

Map<String, dynamic> _$SupplierModelToJson(SupplierModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'documentType': _$DocumentTypeEnumMap[instance.documentType]!,
      'documentNumber': instance.documentNumber,
      'contactPerson': instance.contactPerson,
      'email': instance.email,
      'phone': instance.phone,
      'mobile': instance.mobile,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'postalCode': instance.postalCode,
      'website': instance.website,
      'status': _$SupplierStatusEnumMap[instance.status]!,
      'currency': instance.currency,
      'paymentTermsDays': instance.paymentTermsDays,
      'creditLimit': instance.creditLimit,
      'discountPercentage': instance.discountPercentage,
      'notes': instance.notes,
      'metadata': instance.metadata,
      'organizationId': instance.organizationId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };

const _$DocumentTypeEnumMap = {
  DocumentType.nit: 'nit',
  DocumentType.cc: 'cc',
  DocumentType.ce: 'ce',
  DocumentType.passport: 'passport',
  DocumentType.rut: 'rut',
  DocumentType.other: 'other',
};

const _$SupplierStatusEnumMap = {
  SupplierStatus.active: 'active',
  SupplierStatus.inactive: 'inactive',
  SupplierStatus.blocked: 'blocked',
};
