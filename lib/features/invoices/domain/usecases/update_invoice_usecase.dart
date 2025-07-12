import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateInvoiceUseCase implements UseCase<Invoice, UpdateInvoiceParams> {
  final InvoiceRepository repository;

  UpdateInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(UpdateInvoiceParams params) async {
    return await repository.updateInvoice(
      id: params.id,
      number: params.number,
      date: params.date,
      dueDate: params.dueDate,
      paymentMethod: params.paymentMethod,
      status: params.status,
      taxPercentage: params.taxPercentage,
      discountPercentage: params.discountPercentage,
      discountAmount: params.discountAmount,
      notes: params.notes,
      terms: params.terms,
      metadata: params.metadata,
      customerId: params.customerId,
      items: params.items,
    );
  }
}

class UpdateInvoiceParams {
  final String id;
  final String? number;
  final DateTime? date;
  final DateTime? dueDate;
  final PaymentMethod? paymentMethod;
  final InvoiceStatus? status;
  final double? taxPercentage;
  final double? discountPercentage;
  final double? discountAmount;
  final String? notes;
  final String? terms;
  final Map<String, dynamic>? metadata;
  final String? customerId;
  final List<CreateInvoiceItemParams>? items;

  const UpdateInvoiceParams({
    required this.id,
    this.number,
    this.date,
    this.dueDate,
    this.paymentMethod,
    this.status,
    this.taxPercentage,
    this.discountPercentage,
    this.discountAmount,
    this.notes,
    this.terms,
    this.metadata,
    this.customerId,
    this.items,
  });
}
