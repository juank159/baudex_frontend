// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_supplier_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateSupplierRequestModel _$UpdateSupplierRequestModelFromJson(
        Map<String, dynamic> json) =>
    UpdateSupplierRequestModel(
      name: json['name'] as String?,
      code: json['code'] as String?,
      documentType: json['documentType'] as String?,
      documentNumber: json['documentNumber'] as String?,
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
      status: json['status'] as String?,
      currency: json['currency'] as String?,
      paymentTermsDays: (json['paymentTermsDays'] as num?)?.toInt(),
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UpdateSupplierRequestModelToJson(
        UpdateSupplierRequestModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'code': instance.code,
      'documentType': instance.documentType,
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
      'status': instance.status,
      'currency': instance.currency,
      'paymentTermsDays': instance.paymentTermsDays,
      'creditLimit': instance.creditLimit,
      'discountPercentage': instance.discountPercentage,
      'notes': instance.notes,
      'metadata': instance.metadata,
    };
