// lib/features/purchase_orders/domain/usecases/update_purchase_order_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class UpdatePurchaseOrderUseCase implements UseCase<PurchaseOrder, UpdatePurchaseOrderParams> {
  final PurchaseOrderRepository repository;

  const UpdatePurchaseOrderUseCase(this.repository);

  @override
  Future<Either<Failure, PurchaseOrder>> call(UpdatePurchaseOrderParams params) async {
    return await repository.updatePurchaseOrder(params);
  }
}