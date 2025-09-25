// lib/features/purchase_orders/domain/usecases/search_purchase_orders_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class SearchPurchaseOrdersUseCase implements UseCase<List<PurchaseOrder>, SearchPurchaseOrdersParams> {
  final PurchaseOrderRepository repository;

  const SearchPurchaseOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<PurchaseOrder>>> call(SearchPurchaseOrdersParams params) async {
    return await repository.searchPurchaseOrders(params);
  }
}