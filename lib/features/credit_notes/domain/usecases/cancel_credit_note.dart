// lib/features/credit_notes/domain/usecases/cancel_credit_note.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class CancelCreditNote {
  final CreditNoteRepository repository;

  const CancelCreditNote(this.repository);

  Future<Either<Failure, CreditNote>> call(String id) {
    return repository.cancelCreditNote(id);
  }
}
