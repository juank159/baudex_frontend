// lib/features/purchase_orders/domain/usecases/delete_purchase_order_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/purchase_order_repository.dart';

class DeletePurchaseOrderUseCase implements UseCase<void, String> {
  final PurchaseOrderRepository repository;

  const DeletePurchaseOrderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deletePurchaseOrder(id);
  }
}