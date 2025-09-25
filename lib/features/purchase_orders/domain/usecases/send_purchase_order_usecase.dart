// lib/features/purchase_orders/domain/usecases/send_purchase_order_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class SendPurchaseOrderParams {
  final String id;
  final String? sendNotes;

  const SendPurchaseOrderParams({
    required this.id,
    this.sendNotes,
  });
}

class SendPurchaseOrderUseCase {
  final PurchaseOrderRepository repository;

  SendPurchaseOrderUseCase(this.repository);

  Future<Either<Failure, PurchaseOrder>> call(SendPurchaseOrderParams params) async {
    return await repository.sendPurchaseOrder(params.id, params.sendNotes);
  }
}