import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class AddPaymentUseCase implements UseCase<Invoice, AddPaymentParams> {
  final InvoiceRepository repository;

  AddPaymentUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(AddPaymentParams params) async {
    return await repository.addPayment(
      invoiceId: params.invoiceId,
      amount: params.amount,
      paymentMethod: params.paymentMethod,
      bankAccountId: params.bankAccountId,
      paymentDate: params.paymentDate,
      reference: params.reference,
      notes: params.notes,
    );
  }
}

class AddPaymentParams {
  final String invoiceId;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? bankAccountId;
  final DateTime? paymentDate;
  final String? reference;
  final String? notes;

  const AddPaymentParams({
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    this.bankAccountId,
    this.paymentDate,
    this.reference,
    this.notes,
  });
}
