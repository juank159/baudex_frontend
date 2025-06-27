import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class CreateInvoiceUseCase implements UseCase<Invoice, CreateInvoiceParams> {
  final InvoiceRepository repository;

  CreateInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(CreateInvoiceParams params) async {
    return await repository.createInvoice(
      customerId: params.customerId,
      items: params.items,
      number: params.number,
      date: params.date,
      dueDate: params.dueDate,
      paymentMethod: params.paymentMethod,
      taxPercentage: params.taxPercentage,
      discountPercentage: params.discountPercentage,
      discountAmount: params.discountAmount,
      notes: params.notes,
      terms: params.terms,
      metadata: params.metadata,
    );
  }
}

class CreateInvoiceParams {
  final String customerId;
  final List<CreateInvoiceItemParams> items;
  final String? number;
  final DateTime? date;
  final DateTime? dueDate;
  final PaymentMethod paymentMethod;
  final double taxPercentage;
  final double discountPercentage;
  final double discountAmount;
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;

  const CreateInvoiceParams({
    required this.customerId,
    required this.items,
    this.number,
    this.date,
    this.dueDate,
    this.paymentMethod = PaymentMethod.cash,
    this.taxPercentage = 19,
    this.discountPercentage = 0,
    this.discountAmount = 0,
    this.notes,
    this.terms,
    this.metadata,
  });
}
