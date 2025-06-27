import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class ConfirmInvoiceUseCase implements UseCase<Invoice, ConfirmInvoiceParams> {
  final InvoiceRepository repository;

  ConfirmInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(ConfirmInvoiceParams params) async {
    return await repository.confirmInvoice(params.id);
  }
}

class ConfirmInvoiceParams {
  final String id;

  const ConfirmInvoiceParams({required this.id});
}
