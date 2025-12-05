// lib/features/credit_notes/domain/usecases/sync_credit_notes.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/credit_note_repository.dart';

class SyncCreditNotes {
  final CreditNoteRepository repository;

  const SyncCreditNotes(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.syncCreditNotes();
  }
}
