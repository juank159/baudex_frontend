import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class GetOverdueInvoicesUseCase implements UseCase<List<Invoice>, NoParams> {
  final InvoiceRepository repository;

  GetOverdueInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(NoParams params) async {
    return await repository.getOverdueInvoices();
  }
}
