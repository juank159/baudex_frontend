// lib/features/purchase_orders/domain/usecases/receive_purchase_order_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class ReceivePurchaseOrderUseCase implements UseCase<PurchaseOrder, ReceivePurchaseOrderParams> {
  final PurchaseOrderRepository repository;

  const ReceivePurchaseOrderUseCase(this.repository);

  @override
  Future<Either<Failure, PurchaseOrder>> call(ReceivePurchaseOrderParams params) async {
    return await repository.receivePurchaseOrder(params);
  }
}