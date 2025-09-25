// lib/features/inventory/presentation/bindings/create_transfer_binding.dart
import 'package:get/get.dart';
import '../controllers/create_transfer_controller.dart';

class CreateTransferBinding extends Bindings {
  @override
  void dependencies() {
    // Register the CreateTransferController
    Get.lazyPut<CreateTransferController>(
      () => CreateTransferController(
        searchProductsUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
        getInventoryBalanceByProductUseCase: Get.find(),
        createTransferUseCase: Get.find(),
      ),
      fenix: true,
    );
  }
}