// lib/features/purchase_orders/domain/usecases/get_purchase_orders_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class GetPurchaseOrdersUseCase implements UseCase<PaginatedResult<PurchaseOrder>, PurchaseOrderQueryParams> {
  final PurchaseOrderRepository repository;

  const GetPurchaseOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<PurchaseOrder>>> call(PurchaseOrderQueryParams params) async {
    return await repository.getPurchaseOrders(params);
  }
}