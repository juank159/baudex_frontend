import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateCustomerParams {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String? email;
  final String? phone;
  final String? mobile;
  final DocumentType? documentType;
  final String? documentNumber;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final CustomerStatus? status;
  final double? creditLimit;
  final int? paymentTerms;
  final DateTime? birthDate;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const UpdateCustomerParams({
    required this.id,
    this.firstName,
    this.lastName,
    this.companyName,
    this.email,
    this.phone,
    this.mobile,
    this.documentType,
    this.documentNumber,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.status,
    this.creditLimit,
    this.paymentTerms,
    this.birthDate,
    this.notes,
    this.metadata,
  });
}

class UpdateCustomerUseCase implements UseCase<Customer, UpdateCustomerParams> {
  final CustomerRepository repository;

  const UpdateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, Customer>> call(UpdateCustomerParams params) async {
    return await repository.updateCustomer(
      id: params.id,
      firstName: params.firstName,
      lastName: params.lastName,
      companyName: params.companyName,
      email: params.email,
      phone: params.phone,
      mobile: params.mobile,
      documentType: params.documentType,
      documentNumber: params.documentNumber,
      address: params.address,
      city: params.city,
      state: params.state,
      zipCode: params.zipCode,
      country: params.country,
      status: params.status,
      creditLimit: params.creditLimit,
      paymentTerms: params.paymentTerms,
      birthDate: params.birthDate,
      notes: params.notes,
      metadata: params.metadata,
    );
  }
}
