import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class GetInvoicesUseCase
    implements UseCase<PaginatedResult<Invoice>, GetInvoicesParams> {
  final InvoiceRepository repository;

  GetInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Invoice>>> call(
    GetInvoicesParams params,
  ) async {
    return await repository.getInvoices(
      page: params.page,
      limit: params.limit,
      search: params.search,
      status: params.status,
      paymentMethod: params.paymentMethod,
      customerId: params.customerId,
      createdById: params.createdById,
      bankAccountId: params.bankAccountId,
      bankAccountName: params.bankAccountName,
      startDate: params.startDate,
      endDate: params.endDate,
      minAmount: params.minAmount,
      maxAmount: params.maxAmount,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}

class GetInvoicesParams {
  final int page;
  final int limit;
  final String? search;
  final InvoiceStatus? status;
  final PaymentMethod? paymentMethod;
  final String? customerId;
  final String? createdById;
  final String? bankAccountId; // Filtro por ID de cuenta bancaria (legacy)
  final String? bankAccountName; // ✅ NUEVO: Filtro por nombre de método de pago (Nequi, Bancolombia, etc.)
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final String sortOrder;

  const GetInvoicesParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.paymentMethod,
    this.customerId,
    this.createdById,
    this.bankAccountId,
    this.bankAccountName,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sortBy = 'createdAt',
    this.sortOrder = 'DESC',
  });
}
