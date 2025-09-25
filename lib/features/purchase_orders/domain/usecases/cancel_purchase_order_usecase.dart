// lib/features/purchase_orders/domain/usecases/cancel_purchase_order_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class CancelPurchaseOrderParams {
  final String id;
  final String cancellationReason;

  const CancelPurchaseOrderParams({
    required this.id,
    required this.cancellationReason,
  });
}

class CancelPurchaseOrderUseCase {
  final PurchaseOrderRepository repository;

  CancelPurchaseOrderUseCase(this.repository);

  Future<Either<Failure, PurchaseOrder>> call(CancelPurchaseOrderParams params) async {
    return await repository.cancelPurchaseOrder(params.id, params.cancellationReason);
  }
}