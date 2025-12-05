// lib/features/credit_notes/domain/usecases/get_remaining_creditable_amount.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/credit_note_repository.dart';

class GetRemainingCreditableAmount {
  final CreditNoteRepository repository;

  const GetRemainingCreditableAmount(this.repository);

  Future<Either<Failure, double>> call(String invoiceId) {
    return repository.getRemainingCreditableAmount(invoiceId);
  }
}
