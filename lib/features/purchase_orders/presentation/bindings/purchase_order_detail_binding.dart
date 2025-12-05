// lib/features/purchase_orders/presentation/bindings/purchase_order_detail_binding.dart
import 'package:baudex_desktop/features/purchase_orders/presentation/bindings/purchase_orders_binding.dart';
import 'package:get/get.dart';
import '../controllers/purchase_order_detail_controller.dart';
import '../../domain/usecases/cancel_purchase_order_usecase.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../../../inventory/domain/usecases/get_warehouses_usecase.dart';
import '../../../inventory/presentation/bindings/inventory_binding.dart';

class PurchaseOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure base dependencies are available
    if (!Get.isRegistered<PurchaseOrderRepository>()) {
      PurchaseOrdersBinding().dependencies();
    }

    // Ensure CancelPurchaseOrderUseCase is registered
    if (!Get.isRegistered<CancelPurchaseOrderUseCase>()) {
      Get.lazyPut(
        () => CancelPurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()),
      );
    }

    // Ensure InventoryBinding is loaded to have required dependencies
    if (!Get.isRegistered<GetWarehousesUseCase>()) {
      print('🔧 Loading InventoryBinding dependencies...');
      InventoryBinding().dependencies();
    }

    // Controller
    Get.lazyPut(
      () => PurchaseOrderDetailController(
        getPurchaseOrderByIdUseCase: Get.find(),
        deletePurchaseOrderUseCase: Get.find(),
        updatePurchaseOrderUseCase: Get.find(),
        approvePurchaseOrderUseCase: Get.find(),
        sendPurchaseOrderUseCase: Get.find(),
        receivePurchaseOrderAndUpdateInventoryUseCase: Get.find(),
        cancelPurchaseOrderUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
      ),
    );
  }
}
