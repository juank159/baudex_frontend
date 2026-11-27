// lib/features/inventory/presentation/bindings/create_transfer_binding.dart
import 'package:get/get.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/usecases/get_balance_for_stock_action_usecase.dart';
import '../controllers/create_transfer_controller.dart';

class CreateTransferBinding extends Bindings {
  @override
  void dependencies() {
    // Register the CreateTransferController
    Get.lazyPut<CreateTransferController>(
      () => CreateTransferController(
        searchProductsUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
        // Si el equipo duda del saldo de origen, se confirma con el servidor.
        getInventoryBalanceByProductUseCase: GetBalanceForStockActionUseCase(
          Get.find<InventoryRepository>(),
          forTransfer: true,
        ),
        createTransferUseCase: Get.find(),
      ),
      fenix: true,
    );
  }
}