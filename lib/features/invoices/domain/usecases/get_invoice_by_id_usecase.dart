import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class GetInvoiceByIdUseCase implements UseCase<Invoice, GetInvoiceByIdParams> {
  final InvoiceRepository repository;

  GetInvoiceByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(GetInvoiceByIdParams params) async {
    return await repository.getInvoiceById(params.id);
  }
}

class GetInvoiceByIdParams {
  final String id;

  const GetInvoiceByIdParams({required this.id});
}
