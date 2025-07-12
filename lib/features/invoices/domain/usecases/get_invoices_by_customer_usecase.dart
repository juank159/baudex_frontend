import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class GetInvoicesByCustomerUseCase
    implements UseCase<List<Invoice>, GetInvoicesByCustomerParams> {
  final InvoiceRepository repository;

  GetInvoicesByCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(
    GetInvoicesByCustomerParams params,
  ) async {
    return await repository.getInvoicesByCustomer(params.customerId);
  }
}

class GetInvoicesByCustomerParams {
  final String customerId;

  const GetInvoicesByCustomerParams({required this.customerId});
}
