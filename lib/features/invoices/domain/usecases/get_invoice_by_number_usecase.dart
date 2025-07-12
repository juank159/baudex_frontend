import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class GetInvoiceByNumberUseCase
    implements UseCase<Invoice, GetInvoiceByNumberParams> {
  final InvoiceRepository repository;

  GetInvoiceByNumberUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(GetInvoiceByNumberParams params) async {
    return await repository.getInvoiceByNumber(params.number);
  }
}

class GetInvoiceByNumberParams {
  final String number;

  const GetInvoiceByNumberParams({required this.number});
}
