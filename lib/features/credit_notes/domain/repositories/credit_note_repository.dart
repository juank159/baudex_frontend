// lib/features/credit_notes/domain/repositories/credit_note_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/credit_note.dart';

// Parámetros para crear nota de crédito
class CreateCreditNoteParams {
  final String invoiceId;
  final String? number;
  final DateTime? date;
  final CreditNoteType type;
  final CreditNoteReason reason;
  final String? reasonDescription;
  final List<CreateCreditNoteItemParams> items;
  final double? taxPercentage;
  final bool restoreInventory;
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;

  const CreateCreditNoteParams({
    required this.invoiceId,
    this.number,
    this.date,
    required this.type,
    required this.reason,
    this.reasonDescription,
    required this.items,
    this.taxPercentage,
    this.restoreInventory = true,
    this.notes,
    this.terms,
    this.metadata,
  });
}

// Parámetros para item de nota de crédito
class CreateCreditNoteItemParams {
  final String? productId;
  final String? invoiceItemId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final String? unit;
  final String? notes;
  final double? unitCost;

  const CreateCreditNoteItemParams({
    this.productId,
    this.invoiceItemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.unit,
    this.notes,
    this.unitCost,
  });
}

// Parámetros para actualizar nota de crédito
// NOTA: El backend solo permite actualizar estos campos en notas de crédito en estado DRAFT
class UpdateCreditNoteParams {
  final String id;
  final CreditNoteReason? reason;
  final String? reasonDescription;
  final bool? restoreInventory;
  final String? notes;
  final String? terms;

  const UpdateCreditNoteParams({
    required this.id,
    this.reason,
    this.reasonDescription,
    this.restoreInventory,
    this.notes,
    this.terms,
  });
}

// Parámetros para consultar notas de crédito
class QueryCreditNotesParams {
  final int page;
  final int limit;
  final String? search;
  final CreditNoteStatus? status;
  final CreditNoteType? type;
  final CreditNoteReason? reason;
  final String? invoiceId;
  final String? customerId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final String sortOrder;

  const QueryCreditNotesParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.type,
    this.reason,
    this.invoiceId,
    this.customerId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'createdAt',
    this.sortOrder = 'DESC',
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (search != null && search!.isNotEmpty) params['search'] = search;
    if (status != null) params['status'] = status!.value;
    if (type != null) params['type'] = type!.value;
    if (reason != null) params['reason'] = reason!.value;
    if (invoiceId != null) params['invoiceId'] = invoiceId;
    if (customerId != null) params['customerId'] = customerId;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    if (minAmount != null) params['minAmount'] = minAmount;
    if (maxAmount != null) params['maxAmount'] = maxAmount;

    return params;
  }
}

abstract class CreditNoteRepository {
  // CREATE
  Future<Either<Failure, CreditNote>> createCreditNote(
    CreateCreditNoteParams params,
  );

  // READ
  Future<Either<Failure, CreditNote>> getCreditNoteById(String id);

  Future<Either<Failure, PaginatedResult<CreditNote>>> getCreditNotes(
    QueryCreditNotesParams params,
  );

  Future<Either<Failure, List<CreditNote>>> getCreditNotesByInvoice(
    String invoiceId,
  );

  Future<Either<Failure, double>> getRemainingCreditableAmount(
    String invoiceId,
  );

  Future<Either<Failure, AvailableQuantitiesResponse>> getAvailableQuantitiesForCreditNote(
    String invoiceId,
  );

  // UPDATE
  Future<Either<Failure, CreditNote>> updateCreditNote(
    UpdateCreditNoteParams params,
  );

  Future<Either<Failure, CreditNote>> confirmCreditNote(String id);

  Future<Either<Failure, CreditNote>> cancelCreditNote(String id);

  // DELETE
  Future<Either<Failure, void>> deleteCreditNote(String id);

  // PDF
  Future<Either<Failure, List<int>>> downloadCreditNotePdf(String id);

  // SYNC (opcional para offline-first)
  Future<Either<Failure, void>> syncCreditNotes();
}
