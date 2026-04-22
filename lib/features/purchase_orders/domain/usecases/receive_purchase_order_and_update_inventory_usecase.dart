// lib/features/purchase_orders/domain/usecases/receive_purchase_order_and_update_inventory_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

/// Recibe una orden de compra.
///
/// IMPORTANTE — por qué este use case NO crea movimientos de inventario
/// desde el cliente:
///
/// El endpoint backend `POST /purchase-orders/:id/receive` (ver
/// backend/src/inventory/services/purchase-orders.service.ts:513) ya ejecuta
/// `inventoryService.registerPurchase()` por cada item recibido, que en UNA
/// sola transacción crea:
///   - InventoryBatch (lote FIFO)
///   - InventoryMovement (MovementType.PURCHASE)
///   - Actualiza Product.stock
///
/// Antes este use case tenía un segundo paso que volvía a llamar
/// `POST /inventory/movements`, lo cual internamente también invoca
/// `registerPurchase()` → se creaba un segundo batch + segundo movement y el
/// stock se sumaba dos veces (10 unidades recibidas → +20 en stock).
///
/// El nombre del use case se mantiene por compatibilidad con los bindings y
/// el detail controller, pero ahora es un wrapper delgado: el backend hace
/// todo el trabajo de inventario durante la recepción.
///
/// NOTA OFFLINE: cuando la recepción se hace sin conexión, el repositorio
/// `_receiveOffline` solo marca `status=received` + `receivedQuantity`
/// localmente y encola la operación de sync. El stock local no refleja la
/// entrada hasta que se sincroniza y se hace pull del servidor. Esto es un
/// trade-off aceptado para evitar el doble conteo al sincronizar.
class ReceivePurchaseOrderAndUpdateInventoryUseCase
    implements UseCase<PurchaseOrder, ReceivePurchaseOrderParams> {
  final PurchaseOrderRepository purchaseOrderRepository;

  const ReceivePurchaseOrderAndUpdateInventoryUseCase({
    required this.purchaseOrderRepository,
  });

  @override
  Future<Either<Failure, PurchaseOrder>> call(
      ReceivePurchaseOrderParams params) {
    return purchaseOrderRepository.receivePurchaseOrder(params);
  }
}
