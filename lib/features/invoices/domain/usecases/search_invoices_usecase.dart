import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:dartz/dartz.dart';

class SearchInvoicesUseCase
    implements UseCase<List<Invoice>, SearchInvoicesParams> {
  final InvoiceRepository repository;

  SearchInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(
    SearchInvoicesParams params,
  ) async {
    return await repository.searchInvoices(params.searchTerm);
  }
}

class SearchInvoicesParams {
  final String searchTerm;

  const SearchInvoicesParams({required this.searchTerm});
}
