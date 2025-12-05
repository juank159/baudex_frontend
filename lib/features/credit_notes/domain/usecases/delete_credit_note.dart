// lib/features/credit_notes/domain/usecases/delete_credit_note.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/credit_note_repository.dart';

class DeleteCreditNote {
  final CreditNoteRepository repository;

  const DeleteCreditNote(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteCreditNote(id);
  }
}
