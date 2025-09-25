// lib/features/suppliers/domain/usecases/update_supplier_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class UpdateSupplierUseCase implements UseCase<Supplier, UpdateSupplierParams> {
  final SupplierRepository repository;

  UpdateSupplierUseCase(this.repository);

  @override
  Future<Either<Failure, Supplier>> call(UpdateSupplierParams params) async {
    return await repository.updateSupplier(
      id: params.id,
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

class UpdateSupplierParams {
  final String id;
  final String? name;
  final String? code;
  final DocumentType? documentType;
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
  final SupplierStatus? status;
  final String? currency;
  final int? paymentTermsDays;
  final double? creditLimit;
  final double? discountPercentage;
  final String? notes;
  final Map<String, dynamic>? metadata;

  UpdateSupplierParams({
    required this.id,
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
}