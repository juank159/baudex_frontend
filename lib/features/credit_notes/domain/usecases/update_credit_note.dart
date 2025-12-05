// lib/features/credit_notes/domain/usecases/update_credit_note.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class UpdateCreditNote {
  final CreditNoteRepository repository;

  const UpdateCreditNote(this.repository);

  Future<Either<Failure, CreditNote>> call(UpdateCreditNoteParams params) {
    return repository.updateCreditNote(params);
  }
}
