// lib/features/invoices/domain/usecases/exchange_products_usecase.dart
//
// Orquestador del flujo "Cambio de producto":
//   1. Valida la request.
//   2. Crea nota de crédito por items devueltos (libera stock + reduce balance).
//   3. Crea factura nueva por items entregados (consume stock + registra ingreso).
//   4. Si hay diferencia a favor del cliente y eligió `storeCredit`, crea
//      un CustomerCredit por la diferencia.
//
// Cada paso reutiliza repositorios existentes que ya soportan offline:
//   - CreditNoteRepository.createCreditNote
//   - InvoiceRepository.createInvoice
//   - CustomerCreditRepository.createCredit

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../credit_notes/domain/entities/credit_note.dart';
import '../../../credit_notes/domain/repositories/credit_note_repository.dart';
import '../../../customer_credits/data/models/customer_credit_model.dart';
import '../../../customer_credits/domain/repositories/customer_credit_repository.dart';
import '../entities/invoice.dart';
import '../entities/product_exchange.dart';
import '../repositories/invoice_repository.dart';

class ExchangeProductsUseCase {
  final CreditNoteRepository creditNoteRepository;
  final InvoiceRepository invoiceRepository;
  final CustomerCreditRepository customerCreditRepository;

  const ExchangeProductsUseCase({
    required this.creditNoteRepository,
    required this.invoiceRepository,
    required this.customerCreditRepository,
  });

  Future<Either<Failure, ProductExchangeResult>> call(
    ProductExchangeRequest request,
  ) async {
    // 1) Validación de entrada
    final validation = _validate(request);
    if (validation != null) {
      return Left(ValidationFailure([validation]));
    }

    // 2) Crear nota de crédito por items devueltos
    //    Usa el flujo offline-first: si no hay red, la nota se crea local
    //    y se encola para sync. El stock se restaura local al instante
    //    (commit `ba73f82`).
    final cnParams = CreateCreditNoteParams(
      invoiceId: request.originalInvoiceId,
      type: _resolveType(request),
      reason: request.reason,
      reasonDescription: request.reasonDescription,
      restoreInventory: request.restoreInventory,
      items: request.returnedItems
          .map((item) => CreateCreditNoteItemParams(
                productId: item.productId,
                invoiceItemId: item.invoiceItemId,
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                unit: item.unit,
              ))
          .toList(),
      notes: 'Cambio de producto — devolución parcial',
    );

    final cnResult = await creditNoteRepository.createCreditNote(cnParams);
    if (cnResult.isLeft()) {
      return Left(cnResult.fold((f) => f, (_) => throw StateError('unreachable')));
    }
    final creditNote = cnResult.fold(
      (_) => throw StateError('unreachable'),
      (cn) => cn,
    );

    // 3) Si no hay items nuevos, el cambio es solo una devolución pura.
    //    Conciliación: cashRefund o storeCredit.
    if (request.newItems.isEmpty) {
      return _settleReturnOnly(request: request, creditNote: creditNote);
    }

    // 4) Crear factura nueva por items entregados (delega directo al
    //    repositorio porque su firma es más explícita que un Params object)
    final invResult = await invoiceRepository.createInvoice(
      customerId: request.customerId,
      items: request.newItems
          .map((item) => item.toCreateInvoiceItemParams())
          .toList(),
      paymentMethod: _resolvePaymentMethod(request.settlementMode),
      status: _resolveInvoiceStatus(request),
      taxPercentage: 0,
      notes: 'Cambio de producto — derivada de NC ${creditNote.number}',
      metadata: {
        'isExchange': true,
        'sourceInvoiceId': request.originalInvoiceId,
        'creditNoteId': creditNote.id,
        'totalReturned': request.totalReturned,
        'totalDelivered': request.totalDelivered,
        'difference': request.difference,
        'settlementMode': request.settlementMode.name,
      },
      bankAccountId: request.bankAccountId,
    );

    if (invResult.isLeft()) {
      // ⚠️ La nota de crédito ya se creó; aquí está el riesgo de
      // inconsistencia. El usuario verá la nota creada pero la factura
      // nueva NO. La UI debe avisar para que el usuario reintente la
      // factura manualmente o cancele la nota.
      return Left(invResult.fold(
        (f) => CompositeExchangeFailure(
          'Nota de crédito creada pero la factura nueva falló: ${f.message}. '
          'Reintente la factura desde el detalle.',
          creditNote: creditNote,
          underlying: f,
        ),
        (_) => throw StateError('unreachable'),
      ));
    }
    final newInvoice = invResult.fold(
      (_) => throw StateError('unreachable'),
      (inv) => inv,
    );

    // 5) Conciliar diferencia
    return _settleDifference(
      request: request,
      creditNote: creditNote,
      newInvoice: newInvoice,
    );
  }

  // ==================== INTERNALS ====================

  String? _validate(ProductExchangeRequest req) {
    if (req.returnedItems.isEmpty) {
      return 'Debe especificar al menos un item devuelto';
    }
    for (final item in req.returnedItems) {
      if (item.quantity <= 0) {
        return 'Cantidad devuelta debe ser positiva: ${item.description}';
      }
    }
    for (final item in req.newItems) {
      if (item.quantity <= 0) {
        return 'Cantidad entregada debe ser positiva: ${item.description}';
      }
    }
    return null;
  }

  CreditNoteType _resolveType(ProductExchangeRequest req) {
    // Una devolución parcial casi siempre — un "cambio total" sigue siendo
    // partial salvo que el cliente devuelva TODOS los items y no lleve nada.
    return CreditNoteType.partial;
  }

  PaymentMethod _resolvePaymentMethod(ExchangeSettlementMode mode) {
    switch (mode) {
      case ExchangeSettlementMode.cashPayment:
      case ExchangeSettlementMode.cashRefund:
      case ExchangeSettlementMode.exact:
        return PaymentMethod.cash;
      case ExchangeSettlementMode.storeCredit:
        // El "pago" es con crédito a favor → se modela como credit en la
        // factura nueva, el saldo a favor se concilia aparte.
        return PaymentMethod.cash;
    }
  }

  InvoiceStatus _resolveInvoiceStatus(ProductExchangeRequest req) {
    // Si el cliente ya pagó (cashPayment) o el saldo cubre exactamente,
    // marcar como paid. Si lleva más caro y no paga ahora → pending.
    if (req.difference <= 0) return InvoiceStatus.paid;
    if (req.settlementMode == ExchangeSettlementMode.cashPayment) {
      return InvoiceStatus.paid;
    }
    return InvoiceStatus.pending;
  }

  /// Caso "devolución pura": cliente devuelve y no lleva nada nuevo.
  /// Conciliación: cashRefund o storeCredit.
  Future<Either<Failure, ProductExchangeResult>> _settleReturnOnly({
    required ProductExchangeRequest request,
    required CreditNote creditNote,
  }) async {
    if (request.settlementMode == ExchangeSettlementMode.storeCredit) {
      final credit = await _createStoreCredit(
        customerId: request.customerId,
        amount: request.totalReturned,
        invoiceId: request.originalInvoiceId,
        creditNoteNumber: creditNote.number,
      );
      return credit.fold(
        (f) => Right(ProductExchangeResult(
          creditNote: creditNote,
          settledInCash: 0,
          settledAsCredit: 0,
        )),
        (cc) => Right(ProductExchangeResult(
          creditNote: creditNote,
          customerCredit: cc,
          settledAsCredit: request.totalReturned,
        )),
      );
    }
    // cashRefund por defecto en devolución pura
    return Right(ProductExchangeResult(
      creditNote: creditNote,
      settledInCash: request.totalReturned,
    ));
  }

  /// Concilia la diferencia cuando hay items devueltos Y entregados.
  Future<Either<Failure, ProductExchangeResult>> _settleDifference({
    required ProductExchangeRequest request,
    required CreditNote creditNote,
    required Invoice newInvoice,
  }) async {
    final diff = request.difference;

    // Diferencia exacta o cliente paga: no hay nada extra que conciliar.
    if (diff >= 0) {
      return Right(ProductExchangeResult(
        creditNote: creditNote,
        newInvoice: newInvoice,
        settledInCash: diff > 0 ? diff : 0,
      ));
    }

    // diff < 0: a favor del cliente
    final amountInFavor = -diff;
    if (request.settlementMode == ExchangeSettlementMode.storeCredit) {
      final credit = await _createStoreCredit(
        customerId: request.customerId,
        amount: amountInFavor,
        invoiceId: request.originalInvoiceId,
        creditNoteNumber: creditNote.number,
      );
      return credit.fold(
        (_) => Right(ProductExchangeResult(
          creditNote: creditNote,
          newInvoice: newInvoice,
          settledInCash: 0,
          settledAsCredit: 0,
        )),
        (cc) => Right(ProductExchangeResult(
          creditNote: creditNote,
          newInvoice: newInvoice,
          customerCredit: cc,
          settledAsCredit: amountInFavor,
        )),
      );
    }

    // cashRefund: comercio devuelve diferencia en efectivo
    return Right(ProductExchangeResult(
      creditNote: creditNote,
      newInvoice: newInvoice,
      settledInCash: amountInFavor,
    ));
  }

  Future<Either<Failure, dynamic>> _createStoreCredit({
    required String customerId,
    required double amount,
    required String invoiceId,
    required String creditNoteNumber,
  }) async {
    final dto = CreateCustomerCreditDto(
      customerId: customerId,
      originalAmount: amount,
      description: 'Saldo a favor por cambio de producto (NC $creditNoteNumber)',
      invoiceId: invoiceId,
      skipAutoBalance: true,
    );
    return customerCreditRepository.createCredit(dto);
  }
}

/// Failure especial cuando la nota se creó pero la factura falló — permite
/// a la UI ofrecer "reintentar" y conocer la nota ya creada.
class CompositeExchangeFailure extends Failure {
  final CreditNote creditNote;
  final Failure underlying;

  CompositeExchangeFailure(
    String message, {
    required this.creditNote,
    required this.underlying,
  }) : super(message);
}
