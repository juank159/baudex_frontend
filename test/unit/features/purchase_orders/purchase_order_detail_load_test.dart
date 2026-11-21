import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/approve_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/cancel_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/delete_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/get_purchase_order_by_id_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/receive_purchase_order_and_update_inventory_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/send_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/update_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/controllers/purchase_order_detail_controller.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/purchase_order_fixtures.dart';

class _GetById extends Mock implements GetPurchaseOrderByIdUseCase {}
class _Delete extends Mock implements DeletePurchaseOrderUseCase {}
class _Update extends Mock implements UpdatePurchaseOrderUseCase {}
class _Approve extends Mock implements ApprovePurchaseOrderUseCase {}
class _Send extends Mock implements SendPurchaseOrderUseCase {}
class _Receive extends Mock implements ReceivePurchaseOrderAndUpdateInventoryUseCase {}
class _Cancel extends Mock implements CancelPurchaseOrderUseCase {}
class _Warehouses extends Mock implements GetWarehousesUseCase {}

/// Detalle de una orden de compra (borrador) al volver a ella.
void main() {
  const realId = '9605083f-19ff-4acc-ad1d-5a323518ab6e';
  const tempId = 'po_offline_1763700000000_42';
  late _GetById getById;
  late PurchaseOrderDetailController c;

  setUp(() {
    Get.testMode = true;
    getById = _GetById();
    c = PurchaseOrderDetailController(
      getPurchaseOrderByIdUseCase: getById,
      deletePurchaseOrderUseCase: _Delete(),
      updatePurchaseOrderUseCase: _Update(),
      approvePurchaseOrderUseCase: _Approve(),
      sendPurchaseOrderUseCase: _Send(),
      receivePurchaseOrderAndUpdateInventoryUseCase: _Receive(),
      cancelPurchaseOrderUseCase: _Cancel(),
      getWarehousesUseCase: _Warehouses(),
      resolveTempId: (id) async => id == tempId ? realId : null,
    );
  });
  tearDown(Get.reset);

  test('orden creada sin conexión que ya subió: se abre con su id real', () async {
    when(() => getById(tempId)).thenAnswer((_) async => const Left(CacheFailure('Purchase order not found')));
    when(() => getById(realId)).thenAnswer(
        (_) async => Right(PurchaseOrderFixtures.createDraftPurchaseOrder(id: realId)));
    c.purchaseOrderId.value = tempId;

    await c.loadPurchaseOrder();

    expect(c.error.value, isEmpty, reason: 'antes quedaba en "Error al cargar" sin salida');
    expect(c.purchaseOrder.value?.id, realId);
    expect(c.purchaseOrderId.value, realId);
  });

  test('refresco por sincronización: no cambia la pantalla por el esqueleto ni la tapa con un error',
      () async {
    when(() => getById(realId)).thenAnswer(
        (_) async => Right(PurchaseOrderFixtures.createDraftPurchaseOrder(id: realId)));
    c.purchaseOrderId.value = realId;
    await c.loadPurchaseOrder();

    final loadingStates = <bool>[];
    c.isLoading.listen(loadingStates.add);
    when(() => getById(realId)).thenAnswer((_) async => const Left(ServerFailure('caído')));
    await c.loadPurchaseOrder(silent: true);
    await Future<void>.delayed(Duration.zero);

    expect(loadingStates, isEmpty, reason: 'sin parpadeo de esqueleto');
    expect(c.error.value, isEmpty);
    expect(c.purchaseOrder.value?.id, realId);
  });

  test('ids temporales vs ids del servidor', () {
    expect(isTemporaryPurchaseOrderId(tempId), isTrue);
    expect(isTemporaryPurchaseOrderId(realId), isFalse);
  });
}
