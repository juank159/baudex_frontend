// lib/features/suppliers/data/models/create_supplier_request_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/create_supplier_usecase.dart';

part 'create_supplier_request_model.g.dart';

@JsonSerializable()
class CreateSupplierRequestModel {
  final String name;
  final String? code;
  final String documentType;
  final String documentNumber;
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

  const CreateSupplierRequestModel({
    required this.name,
    this.code,
    required this.documentType,
    required this.documentNumber,
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

  factory CreateSupplierRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CreateSupplierRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSupplierRequestModelToJson(this);

  // Constructor desde parámetros del caso de uso
  factory CreateSupplierRequestModel.fromParams(CreateSupplierParams params) {
    return CreateSupplierRequestModel(
      name: params.name,
      code: params.code,
      documentType: params.documentType.name,
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