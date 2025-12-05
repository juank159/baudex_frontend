// lib/features/credit_notes/domain/usecases/download_credit_note_pdf.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/credit_note_repository.dart';

class DownloadCreditNotePdf {
  final CreditNoteRepository repository;

  const DownloadCreditNotePdf(this.repository);

  Future<Either<Failure, List<int>>> call(String id) {
    return repository.downloadCreditNotePdf(id);
  }
}
