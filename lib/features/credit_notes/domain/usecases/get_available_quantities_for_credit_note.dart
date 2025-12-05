// lib/features/credit_notes/domain/usecases/get_available_quantities_for_credit_note.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/credit_note.dart';
import '../repositories/credit_note_repository.dart';

/// Caso de uso para obtener las cantidades disponibles para crear notas de crédito
///
/// Este caso de uso consulta el backend para obtener información detallada sobre:
/// - Cantidades originales, acreditadas y disponibles por item de factura
/// - Notas de crédito en borrador que afectan las cantidades disponibles
/// - Si se puede crear una nota de crédito completa o parcial
class GetAvailableQuantitiesForCreditNote {
  final CreditNoteRepository repository;

  const GetAvailableQuantitiesForCreditNote(this.repository);

  Future<Either<Failure, AvailableQuantitiesResponse>> call(String invoiceId) {
    return repository.getAvailableQuantitiesForCreditNote(invoiceId);
  }
}
