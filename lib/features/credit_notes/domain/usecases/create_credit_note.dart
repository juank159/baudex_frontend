// lib/features/credit_notes/domain/usecases/create_credit_note.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class CreateCreditNote {
  final CreditNoteRepository repository;

  const CreateCreditNote(this.repository);

  Future<Either<Failure, CreditNote>> call(CreateCreditNoteParams params) {
    return repository.createCreditNote(params);
  }
}
