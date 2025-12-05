// lib/features/credit_notes/domain/usecases/get_credit_notes_by_invoice.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

class GetCreditNotesByInvoice {
  final CreditNoteRepository repository;

  const GetCreditNotesByInvoice(this.repository);

  Future<Either<Failure, List<CreditNote>>> call(String invoiceId) {
    return repository.getCreditNotesByInvoice(invoiceId);
  }
}
