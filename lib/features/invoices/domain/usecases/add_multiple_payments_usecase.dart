import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

/// UseCase para agregar múltiples pagos a una factura
///
/// Permite dividir un pago entre diferentes métodos (ej: parte en efectivo, parte en Nequi)
/// y opcionalmente crear un crédito por el saldo restante
class AddMultiplePaymentsUseCase implements UseCase<MultiplePaymentsResult, AddMultiplePaymentsParams> {
  final InvoiceRepository repository;

  AddMultiplePaymentsUseCase(this.repository);

  @override
  Future<Either<Failure, MultiplePaymentsResult>> call(AddMultiplePaymentsParams params) async {
    // Convertir PaymentItemParams a PaymentItemData para el repositorio
    final paymentData = params.payments.map((p) => PaymentItemData(
      amount: p.amount,
      paymentMethod: p.paymentMethod,
      bankAccountId: p.bankAccountId,
      reference: p.reference,
      notes: p.notes,
    )).toList();

    return await repository.addMultiplePayments(
      invoiceId: params.invoiceId,
      payments: paymentData,
      paymentDate: params.paymentDate,
      createCreditForRemaining: params.createCreditForRemaining,
      generalNotes: params.generalNotes,
    );
  }
}

/// Parámetros para agregar múltiples pagos
class AddMultiplePaymentsParams {
  final String invoiceId;
  final List<PaymentItemParams> payments;
  final DateTime? paymentDate;
  final bool createCreditForRemaining;
  final String? generalNotes;

  const AddMultiplePaymentsParams({
    required this.invoiceId,
    required this.payments,
    this.paymentDate,
    this.createCreditForRemaining = false,
    this.generalNotes,
  });

  /// Valida que los parámetros sean correctos
  bool get isValid {
    if (payments.isEmpty) return false;
    return payments.every((p) => p.isValid);
  }

  /// Suma total de todos los pagos
  double get totalAmount {
    return payments.fold(0.0, (sum, p) => sum + p.amount);
  }
}

/// Parámetros para un ítem de pago individual
class PaymentItemParams {
  final double amount;
  final PaymentMethod paymentMethod;
  final String? bankAccountId;
  final String? bankAccountName; // Para mostrar en UI
  final String? reference;
  final String? notes;

  const PaymentItemParams({
    required this.amount,
    required this.paymentMethod,
    this.bankAccountId,
    this.bankAccountName,
    this.reference,
    this.notes,
  });

  bool get isValid => amount > 0;
}
