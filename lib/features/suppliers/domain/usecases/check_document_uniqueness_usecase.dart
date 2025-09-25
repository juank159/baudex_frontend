// lib/features/suppliers/domain/usecases/check_document_uniqueness_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class CheckDocumentUniquenessUseCase implements UseCase<bool, CheckDocumentUniquenessParams> {
  final SupplierRepository repository;

  CheckDocumentUniquenessUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckDocumentUniquenessParams params) async {
    return await repository.checkDocumentUniqueness(
      documentType: params.documentType,
      documentNumber: params.documentNumber,
      excludeId: params.excludeId,
    );
  }
}

class CheckDocumentUniquenessParams {
  final DocumentType documentType;
  final String documentNumber;
  final String? excludeId; // For excluding current supplier during updates

  CheckDocumentUniquenessParams({
    required this.documentType,
    required this.documentNumber,
    this.excludeId,
  });
}