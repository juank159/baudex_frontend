import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class CancelInvoiceUseCase implements UseCase<Invoice, CancelInvoiceParams> {
  final InvoiceRepository repository;

  CancelInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(CancelInvoiceParams params) async {
    return await repository.cancelInvoice(params.id);
  }
}

class CancelInvoiceParams {
  final String id;

  const CancelInvoiceParams({required this.id});
}
