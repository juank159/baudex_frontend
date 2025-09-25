// lib/features/purchase_orders/domain/usecases/approve_purchase_order_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class ApprovePurchaseOrderParams {
  final String id;
  final String? approvalNotes;

  const ApprovePurchaseOrderParams({
    required this.id,
    this.approvalNotes,
  });
}

class ApprovePurchaseOrderUseCase implements UseCase<PurchaseOrder, ApprovePurchaseOrderParams> {
  final PurchaseOrderRepository repository;

  const ApprovePurchaseOrderUseCase(this.repository);

  @override
  Future<Either<Failure, PurchaseOrder>> call(ApprovePurchaseOrderParams params) async {
    return await repository.approvePurchaseOrder(params.id, params.approvalNotes);
  }
}