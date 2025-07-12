import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class DeleteInvoiceUseCase implements UseCase<void, DeleteInvoiceParams> {
  final InvoiceRepository repository;

  DeleteInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteInvoiceParams params) async {
    return await repository.deleteInvoice(params.id);
  }
}

class DeleteInvoiceParams {
  final String id;

  const DeleteInvoiceParams({required this.id});
}
