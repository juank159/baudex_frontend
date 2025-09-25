// lib/features/purchase_orders/domain/usecases/receive_purchase_order_and_update_inventory_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';
import '../../../inventory/domain/usecases/create_inventory_movement_usecase.dart';
import '../../../inventory/domain/entities/inventory_movement.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';

class ReceivePurchaseOrderAndUpdateInventoryUseCase implements UseCase<PurchaseOrder, ReceivePurchaseOrderParams> {
  final PurchaseOrderRepository purchaseOrderRepository;
  final CreateInventoryMovementUseCase createInventoryMovementUseCase;

  const ReceivePurchaseOrderAndUpdateInventoryUseCase({
    required this.purchaseOrderRepository,
    required this.createInventoryMovementUseCase,
  });

  @override
  Future<Either<Failure, PurchaseOrder>> call(ReceivePurchaseOrderParams params) async {
    // 1. Recibir la orden de compra
    final receivePurchaseOrderResult = await purchaseOrderRepository.receivePurchaseOrder(params);
    
    return receivePurchaseOrderResult.fold(
      (failure) => Left(failure),
      (receivedOrder) async {
        
        // 2. Crear movimientos de inventario para cada item recibido
        try {
          for (final item in receivedOrder.items) {
            if (item.receivedQuantity != null && item.receivedQuantity! > 0) {
              
              final inventoryMovementParams = CreateInventoryMovementParams(
                productId: item.productId,
                type: InventoryMovementType.inbound,
                reason: InventoryMovementReason.purchase,
                quantity: item.receivedQuantity!,
                unitCost: item.unitPrice, // Precio de compra
                warehouseId: params.warehouseId, // Add warehouse ID from params
                notes: 'Recepción de orden de compra: ${receivedOrder.orderNumber ?? receivedOrder.id}',
                referenceType: 'purchase_order',
                referenceId: receivedOrder.id,
                movementDate: DateTime.now(),
              );

              final movementResult = await createInventoryMovementUseCase(inventoryMovementParams);
              
              // Si algún movimiento de inventario falla, log pero continúa
              movementResult.fold(
                (failure) => print('⚠️ Error creando movimiento de inventario para producto ${item.productId}: ${failure.message}'),
                (movement) => print('✅ Movimiento de inventario creado para producto ${item.productId}: cantidad ${item.receivedQuantity}'),
              );
            }
          }
          
          return Right(receivedOrder);
          
        } catch (e) {
          print('❌ Error actualizando inventario después de recibir orden: $e');
          // Aunque el inventario falle, la orden fue recibida exitosamente
          return Right(receivedOrder);
        }
      },
    );
  }
}