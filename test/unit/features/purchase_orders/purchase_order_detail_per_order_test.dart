import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/get_warehouses_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/approve_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/cancel_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/delete_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/get_purchase_order_by_id_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/receive_purchase_order_and_update_inventory_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/send_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/domain/usecases/update_purchase_order_usecase.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/bindings/purchase_orders_binding.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/controllers/purchase_order_detail_controller.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/screens/futuristic_purchase_order_detail_screen.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _GetById extends Mock implements GetPurchaseOrderByIdUseCase {}

class _Del extends Mock implements DeletePurchaseOrderUseCase {}

class _Upd extends Mock implements UpdatePurchaseOrderUseCase {}

class _App extends Mock implements ApprovePurchaseOrderUseCase {}

class _Snd extends Mock implements SendPurchaseOrderUseCase {}

class _Rcv extends Mock implements ReceivePurchaseOrderAndUpdateInventoryUseCase {}

class _Cnl extends Mock implements CancelPurchaseOrderUseCase {}

class _Wh extends Mock implements GetWarehousesUseCase {}

class _Mov extends Mock implements CreateInventoryMovementUseCase {}

/// Muestra qué orden tiene el controlador que encuentra la pantalla.
class _Probe extends StatelessWidget {
  _Probe() : screen = FuturisticPurchaseOrderDetailScreen();
  final FuturisticPurchaseOrderDetailScreen screen;
  @override
  Widget build(BuildContext context) => Obx(() => Text(
      'orden:${screen.controller.purchaseOrderId.value}',
      textDirection: TextDirection.ltr));
}

void main() {
  setUp(() {
    Get.reset();
    final getById = _GetById();
    when(() => getById(any()))
        .thenAnswer((_) async => const Left(ServerFailure('sin servidor')));
    final wh = _Wh();
    when(() => wh()).thenAnswer((_) async => const Right([]));
    Get.put<GetPurchaseOrderByIdUseCase>(getById);
    Get.put<DeletePurchaseOrderUseCase>(_Del());
    Get.put<UpdatePurchaseOrderUseCase>(_Upd());
    Get.put<ApprovePurchaseOrderUseCase>(_App());
    Get.put<SendPurchaseOrderUseCase>(_Snd());
    Get.put<ReceivePurchaseOrderAndUpdateInventoryUseCase>(_Rcv());
    Get.put<CancelPurchaseOrderUseCase>(_Cnl());
    Get.put<GetWarehousesUseCase>(wh);
    Get.put<CreateInventoryMovementUseCase>(_Mov());
  });

  testWidgets('abrir el detalle de otra orden con la anterior abierta muestra la nueva',
      (tester) async {
    await tester.pumpWidget(GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SizedBox()),
        GetPage(
          name: '/purchase-orders/detail/:id',
          page: () => _Probe(),
          binding: PurchaseOrderDetailBinding(),
        ),
      ],
    ));
    Get.toNamed('/purchase-orders/detail/orden-A');
    await tester.pumpAndSettle();
    expect(find.text('orden:orden-A'), findsOneWidget);

    // Se abre el detalle de B con A aún debajo (p. ej. Productos → volver).
    Get.toNamed('/purchase-orders/detail/orden-B');
    await tester.pumpAndSettle();
    // Antes: un solo controlador sin etiqueta → B mostraba A (6 de 6).
    expect(find.text('orden:orden-B'), findsOneWidget);
    expect(Get.find<PurchaseOrderDetailController>(tag: 'orden-A').purchaseOrderId.value,
        'orden-A');

    Get.back();
    await tester.pumpAndSettle();
    expect(find.text('orden:orden-A'), findsOneWidget);
    expect(Get.isRegistered<PurchaseOrderDetailController>(tag: 'orden-B'), isFalse,
        reason: 'el controlador de B se libera al cerrarla');
  });
}
