// lib/features/credit_notes/domain/usecases/get_credit_note_by_id.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class GetCreditNoteById {
  final CreditNoteRepository repository;

  const GetCreditNoteById(this.repository);

  Future<Either<Failure, CreditNote>> call(String id) {
    return repository.getCreditNoteById(id);
  }
}
