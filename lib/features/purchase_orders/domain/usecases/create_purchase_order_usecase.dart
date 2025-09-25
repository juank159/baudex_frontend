// lib/features/purchase_orders/domain/usecases/create_purchase_order_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class CreatePurchaseOrderUseCase implements UseCase<PurchaseOrder, CreatePurchaseOrderParams> {
  final PurchaseOrderRepository repository;

  const CreatePurchaseOrderUseCase(this.repository);

  @override
  Future<Either<Failure, PurchaseOrder>> call(CreatePurchaseOrderParams params) async {
    return await repository.createPurchaseOrder(params);
  }
}