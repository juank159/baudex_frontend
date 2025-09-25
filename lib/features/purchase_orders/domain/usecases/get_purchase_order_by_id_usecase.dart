// lib/features/purchase_orders/domain/usecases/get_purchase_order_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class GetPurchaseOrderByIdUseCase implements UseCase<PurchaseOrder, String> {
  final PurchaseOrderRepository repository;

  const GetPurchaseOrderByIdUseCase(this.repository);

  @override
  Future<Either<Failure, PurchaseOrder>> call(String id) async {
    return await repository.getPurchaseOrderById(id);
  }
}