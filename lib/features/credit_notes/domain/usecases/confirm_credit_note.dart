// lib/features/credit_notes/domain/usecases/confirm_credit_note.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class ConfirmCreditNote {
  final CreditNoteRepository repository;

  const ConfirmCreditNote(this.repository);

  Future<Either<Failure, CreditNote>> call(String id) {
    return repository.confirmCreditNote(id);
  }
}
