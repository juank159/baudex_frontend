// lib/features/suppliers/domain/usecases/create_supplier_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class CreateSupplierUseCase implements UseCase<Supplier, CreateSupplierParams> {
  final SupplierRepository repository;

  CreateSupplierUseCase(this.repository);

  @override
  Future<Either<Failure, Supplier>> call(CreateSupplierParams params) async {
    return await repository.createSupplier(
      name: params.name,
      code: params.code,
      documentType: params.documentType,
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
      status: params.status,
      currency: params.currency,
      paymentTermsDays: params.paymentTermsDays,
      creditLimit: params.creditLimit,
      discountPercentage: params.discountPercentage,
      notes: params.notes,
      metadata: params.metadata,
    );
  }
}

class CreateSupplierParams {
  final String name;
  final String? code;
  final DocumentType documentType;
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
  final SupplierStatus? status;
  final String? currency;
  final int? paymentTermsDays;
  final double? creditLimit;
  final double? discountPercentage;
  final String? notes;
  final Map<String, dynamic>? metadata;

  CreateSupplierParams({
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
}