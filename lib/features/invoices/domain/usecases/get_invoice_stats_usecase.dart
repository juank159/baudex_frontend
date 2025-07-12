import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_stats.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class GetInvoiceStatsUseCase implements UseCase<InvoiceStats, NoParams> {
  final InvoiceRepository repository;

  GetInvoiceStatsUseCase(this.repository);

  @override
  Future<Either<Failure, InvoiceStats>> call(NoParams params) async {
    return await repository.getInvoiceStats();
  }
}
