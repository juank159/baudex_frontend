// lib/features/credit_notes/domain/usecases/get_credit_notes.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class GetCreditNotes {
  final CreditNoteRepository repository;

  const GetCreditNotes(this.repository);

  Future<Either<Failure, PaginatedResult<CreditNote>>> call(
    QueryCreditNotesParams params,
  ) {
    return repository.getCreditNotes(params);
  }
}
