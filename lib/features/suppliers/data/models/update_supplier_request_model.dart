// lib/features/suppliers/data/models/update_supplier_request_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/update_supplier_usecase.dart';

part 'update_supplier_request_model.g.dart';

@JsonSerializable()
class UpdateSupplierRequestModel {
  final String? name;
  final String? code;
  final String? documentType;
  final String? documentNumber;
  final String? contactPerson;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? website;
  final String? status;
  final String? currency;
  final int? paymentTermsDays;
  final double? creditLimit;
  final double? discountPercentage;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const UpdateSupplierRequestModel({
    this.name,
    this.code,
    this.documentType,
    this.documentNumber,
    this.contactPerson,
    this.email,
    this.phone,
    this.mobile,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.website,
    this.status,
    this.currency,
    this.paymentTermsDays,
    this.creditLimit,
    this.discountPercentage,
    this.notes,
    this.metadata,
  });

  factory UpdateSupplierRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateSupplierRequestModelFromJson(json);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    // Solo incluir campos que no son nulos
    if (name != null) data['name'] = name;
    if (code != null) data['code'] = code;
    if (documentType != null) data['documentType'] = documentType;
    if (documentNumber != null) data['documentNumber'] = documentNumber;
    if (contactPerson != null) data['contactPerson'] = contactPerson;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (mobile != null) data['mobile'] = mobile;
    if (address != null) data['address'] = address;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (country != null) data['country'] = country;
    if (postalCode != null) data['postalCode'] = postalCode;
    if (website != null) data['website'] = website;
    if (status != null) data['status'] = status;
    if (currency != null) data['currency'] = currency;
    if (paymentTermsDays != null) data['paymentTermsDays'] = paymentTermsDays;
    if (creditLimit != null) data['creditLimit'] = creditLimit;
    if (discountPercentage != null) data['discountPercentage'] = discountPercentage;
    if (notes != null) data['notes'] = notes;
    if (metadata != null) data['metadata'] = metadata;
    
    return data;
  }

  // Constructor desde parámetros del caso de uso
  factory UpdateSupplierRequestModel.fromParams(UpdateSupplierParams params) {
    return UpdateSupplierRequestModel(
      name: params.name,
      code: params.code,
      documentType: params.documentType?.name,
      documentNumber: params.documentNumber,
      contactPerson: params.contactPerson,
      email: params.email,
      phone: params.phone,
      mobile: params.mobile,
      address: params.address,
      city: params.city,
      state: params.state,
      country: params.country,
      postalCode: params.postalCode,
      website: params.website,
      status: params.status?.name,
      currency: params.currency,
      paymentTermsDays: params.paymentTermsDays,
      creditLimit: params.creditLimit,
      discountPercentage: params.discountPercentage,
      notes: params.notes,
      metadata: params.metadata,
    );
  }
}