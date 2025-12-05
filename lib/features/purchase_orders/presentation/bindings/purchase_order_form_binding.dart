// lib/features/purchase_orders/presentation/bindings/purchase_order_form_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/network_info.dart';
import '../controllers/purchase_order_form_controller.dart';
import '../../domain/usecases/get_purchase_order_by_id_usecase.dart';
import '../../domain/usecases/create_purchase_order_usecase.dart';
import '../../domain/usecases/update_purchase_order_usecase.dart';
import '../../data/repositories/purchase_order_repository_impl.dart';
import '../../data/datasources/purchase_order_remote_datasource.dart';
import '../../data/datasources/purchase_order_local_datasource.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../../../suppliers/presentation/bindings/suppliers_binding.dart';
import '../../../products/presentation/bindings/product_binding.dart';
import '../../../categories/presentation/bindings/category_binding.dart';

class PurchaseOrderFormBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure all required dependencies are registered
    _ensurePurchaseOrderDependencies();

    // Ensure category dependencies are available FIRST (required by ProductBinding)
    if (!Get.isRegistered<CategoryBinding>()) {
      CategoryBinding().dependencies();
    }

    // Ensure supplier dependencies are available
    if (!Get.isRegistered<SuppliersBinding>()) {
      SuppliersBinding().dependencies();
    }

    // Ensure product dependencies are available (depends on categories)
    if (!Get.isRegistered<ProductBinding>()) {
      ProductBinding().dependencies();
    }

    // Force cleanup of existing controller to prevent GlobalKey conflicts
    cleanup();

    print('🏷️ Registrando nuevo PurchaseOrderFormController...');

    // Controller with proper cleanup and fenix for recreation
    Get.lazyPut(
      () => PurchaseOrderFormController(
        createPurchaseOrderUseCase: Get.find(),
        updatePurchaseOrderUseCase: Get.find(),
        getPurchaseOrderByIdUseCase: Get.find(),
        searchSuppliersUseCase: Get.find(),
        searchProductsUseCase: Get.find(),
      ),
      fenix: true, // Allow recreation to prevent GlobalKey conflicts
    );

    print('✅ PurchaseOrderFormController registrado correctamente');
  }

  void _ensurePurchaseOrderDependencies() {
    // Datasources
    if (!Get.isRegistered<PurchaseOrderRemoteDataSource>()) {
      Get.lazyPut<PurchaseOrderRemoteDataSource>(
        () => PurchaseOrderRemoteDataSourceImpl(dioClient: Get.find()),
      );
    }

    if (!Get.isRegistered<PurchaseOrderLocalDataSource>()) {
      Get.lazyPut<PurchaseOrderLocalDataSource>(
        () =>
            PurchaseOrderLocalDataSourceImpl(secureStorageService: Get.find()),
      );
    }

    // Repository
    if (!Get.isRegistered<PurchaseOrderRepository>()) {
      Get.lazyPut<PurchaseOrderRepository>(
        () => PurchaseOrderRepositoryImpl(
          remoteDataSource: Get.find<PurchaseOrderRemoteDataSource>(),
          localDataSource: Get.find<PurchaseOrderLocalDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
      );
    }

    // Use Cases - Register only the required use cases for the form
    if (!Get.isRegistered<CreatePurchaseOrderUseCase>()) {
      Get.lazyPut(
        () => CreatePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()),
      );
    }

    if (!Get.isRegistered<UpdatePurchaseOrderUseCase>()) {
      Get.lazyPut(
        () => UpdatePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()),
      );
    }

    if (!Get.isRegistered<GetPurchaseOrderByIdUseCase>()) {
      Get.lazyPut(
        () => GetPurchaseOrderByIdUseCase(Get.find<PurchaseOrderRepository>()),
      );
    }
  }

  /// Clean up method to prevent GlobalKey conflicts
  static void cleanup() {
    try {
      if (Get.isRegistered<PurchaseOrderFormController>()) {
        print('🧹 Iniciando cleanup de PurchaseOrderFormController...');

        // Only delete the controller - GetX will handle onClose() automatically
        Get.delete<PurchaseOrderFormController>(force: true);

        print('✅ PurchaseOrderFormController eliminado del registro GetX');
      } else {
        print('ℹ️ No hay PurchaseOrderFormController para limpiar');
      }
    } catch (e) {
      print('⚠️ Error durante cleanup: $e');
    }
  }
}
