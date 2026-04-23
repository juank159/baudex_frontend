// lib/features/purchase_orders/presentation/bindings/purchase_orders_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../inventory/data/datasources/inventory_remote_datasource.dart';
import '../../../inventory/data/datasources/inventory_local_datasource.dart';
import '../../../inventory/data/datasources/inventory_local_datasource_isar.dart';
import '../../../inventory/data/repositories/inventory_repository_impl.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../inventory/domain/usecases/create_inventory_movement_usecase.dart';
import '../../../inventory/domain/usecases/get_warehouses_usecase.dart';
import '../../data/datasources/purchase_order_local_datasource.dart';
import '../../data/datasources/purchase_order_remote_datasource.dart';
import '../../data/repositories/purchase_order_repository_impl.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../../domain/usecases/get_purchase_orders_usecase.dart';
import '../../domain/usecases/get_purchase_order_by_id_usecase.dart';
import '../../domain/usecases/create_purchase_order_usecase.dart';
import '../../domain/usecases/update_purchase_order_usecase.dart';
import '../../domain/usecases/delete_purchase_order_usecase.dart';
import '../../domain/usecases/search_purchase_orders_usecase.dart';
import '../../domain/usecases/get_purchase_order_stats_usecase.dart';
import '../../domain/usecases/approve_purchase_order_usecase.dart';
import '../../domain/usecases/send_purchase_order_usecase.dart';
import '../../domain/usecases/receive_purchase_order_usecase.dart';
import '../../domain/usecases/receive_purchase_order_and_update_inventory_usecase.dart';
import '../../domain/usecases/cancel_purchase_order_usecase.dart';
import '../controllers/purchase_orders_controller.dart';
import '../controllers/purchase_order_detail_controller.dart';

class PurchaseOrdersBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure inventory dependencies are available
    _ensureInventoryDependencies();
    
    // Datasources
    Get.lazyPut<PurchaseOrderRemoteDataSource>(
      () => PurchaseOrderRemoteDataSourceImpl(
        dioClient: Get.find(),
      ),
    );
    
    Get.lazyPut<PurchaseOrderLocalDataSource>(
      () => PurchaseOrderLocalDataSourceImpl(
        secureStorageService: Get.find(),
      ),
    );

    // Repository
    Get.lazyPut<PurchaseOrderRepository>(
      () => PurchaseOrderRepositoryImpl(
        remoteDataSource: Get.find<PurchaseOrderRemoteDataSource>(),
        localDataSource: Get.find<PurchaseOrderLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
    );

    // Use Cases
    Get.lazyPut(() => GetPurchaseOrdersUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => GetPurchaseOrderByIdUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => CreatePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => UpdatePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => DeletePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => SearchPurchaseOrdersUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => GetPurchaseOrderStatsUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => ApprovePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => SendPurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => ReceivePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    Get.lazyPut(() => ReceivePurchaseOrderAndUpdateInventoryUseCase(
      purchaseOrderRepository: Get.find<PurchaseOrderRepository>(),
    ));
    Get.lazyPut(() => CancelPurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));

    // Controllers - Using put to keep controller alive across navigations
    Get.put(
      PurchaseOrdersController(
        getPurchaseOrdersUseCase: Get.find(),
        deletePurchaseOrderUseCase: Get.find(),
        searchPurchaseOrdersUseCase: Get.find(),
        getPurchaseOrderStatsUseCase: Get.find(),
        approvePurchaseOrderUseCase: Get.find(),
      ),
      permanent: true, // Keep alive to prevent TextEditingController disposal issues
    );
  }

  /// Registrar SOLO las dependencias de inventario que PO necesita.
  /// NO carga InventoryBinding completo (evita 12 controllers + 30+ requests).
  void _ensureInventoryDependencies() {
    if (Get.isRegistered<CreateInventoryMovementUseCase>() &&
        Get.isRegistered<GetWarehousesUseCase>()) {
      return; // Ya están registradas
    }

    // DataSources — fenix: true para que GetX recree la instancia si fue
    // descartada al salir del scope. Sin fenix, isRegistered sigue siendo
    // true pero la instancia se perdió y falla el Get.find() en los lazy
    // de abajo (ej. al entrar a inventario inicial después de PO).
    if (!Get.isRegistered<InventoryRemoteDataSource>()) {
      Get.lazyPut<InventoryRemoteDataSource>(
        () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
        fenix: true,
      );
    }
    if (!Get.isRegistered<InventoryLocalDataSource>()) {
      Get.lazyPut<InventoryLocalDataSource>(
        () => InventoryLocalDataSourceIsar(Get.find<IsarDatabase>()),
        fenix: true,
      );
    }

    // Repository
    if (!Get.isRegistered<InventoryRepository>()) {
      Get.lazyPut<InventoryRepository>(
        () => InventoryRepositoryImpl(
          remoteDataSource: Get.find(),
          localDataSource: Get.find(),
          networkInfo: Get.find(),
        ),
        fenix: true,
      );
    }

    // Solo 2 use cases necesarios para PO
    if (!Get.isRegistered<CreateInventoryMovementUseCase>()) {
      Get.lazyPut(
        () => CreateInventoryMovementUseCase(Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GetWarehousesUseCase>()) {
      Get.lazyPut(() => GetWarehousesUseCase(Get.find()), fenix: true);
    }
  }
}

class PurchaseOrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure inventory dependencies are available first
    _ensureInventoryDependencies();
    
    // Ensure all required dependencies are registered
    _ensurePurchaseOrderDependencies();

    // Detail Controller
    Get.lazyPut(() => PurchaseOrderDetailController(
      getPurchaseOrderByIdUseCase: Get.find(),
      deletePurchaseOrderUseCase: Get.find(),
      updatePurchaseOrderUseCase: Get.find(),
      approvePurchaseOrderUseCase: Get.find(),
      sendPurchaseOrderUseCase: Get.find(),
      receivePurchaseOrderAndUpdateInventoryUseCase: Get.find(),
      cancelPurchaseOrderUseCase: Get.find(),
      getWarehousesUseCase: Get.find(),
    ));
  }

  void _ensurePurchaseOrderDependencies() {
    // Datasources
    if (!Get.isRegistered<PurchaseOrderRemoteDataSource>()) {
      Get.lazyPut<PurchaseOrderRemoteDataSource>(
        () => PurchaseOrderRemoteDataSourceImpl(
          dioClient: Get.find(),
        ),
      );
    }
    
    if (!Get.isRegistered<PurchaseOrderLocalDataSource>()) {
      Get.lazyPut<PurchaseOrderLocalDataSource>(
        () => PurchaseOrderLocalDataSourceImpl(
          secureStorageService: Get.find(),
        ),
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

    // Use Cases - Register all required use cases
    if (!Get.isRegistered<GetPurchaseOrderByIdUseCase>()) {
      Get.lazyPut(() => GetPurchaseOrderByIdUseCase(Get.find<PurchaseOrderRepository>()));
    }
    
    if (!Get.isRegistered<DeletePurchaseOrderUseCase>()) {
      Get.lazyPut(() => DeletePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    }
    
    if (!Get.isRegistered<UpdatePurchaseOrderUseCase>()) {
      Get.lazyPut(() => UpdatePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    }
    
    if (!Get.isRegistered<ApprovePurchaseOrderUseCase>()) {
      Get.lazyPut(() => ApprovePurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    }
    
    if (!Get.isRegistered<SendPurchaseOrderUseCase>()) {
      Get.lazyPut(() => SendPurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    }
    
    if (!Get.isRegistered<ReceivePurchaseOrderAndUpdateInventoryUseCase>()) {
      Get.lazyPut(() => ReceivePurchaseOrderAndUpdateInventoryUseCase(
        purchaseOrderRepository: Get.find<PurchaseOrderRepository>(),
      ));
    }
    
    if (!Get.isRegistered<CancelPurchaseOrderUseCase>()) {
      Get.lazyPut(() => CancelPurchaseOrderUseCase(Get.find<PurchaseOrderRepository>()));
    }
  }

  /// Registrar SOLO las dependencias de inventario que PO necesita.
  /// NO carga InventoryBinding completo (evita 12 controllers + 30+ requests).
  void _ensureInventoryDependencies() {
    if (Get.isRegistered<CreateInventoryMovementUseCase>() &&
        Get.isRegistered<GetWarehousesUseCase>()) {
      return;
    }

    if (!Get.isRegistered<InventoryRemoteDataSource>()) {
      Get.lazyPut<InventoryRemoteDataSource>(
        () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
        fenix: true,
      );
    }
    if (!Get.isRegistered<InventoryLocalDataSource>()) {
      Get.lazyPut<InventoryLocalDataSource>(
        () => InventoryLocalDataSourceIsar(Get.find<IsarDatabase>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<InventoryRepository>()) {
      Get.lazyPut<InventoryRepository>(
        () => InventoryRepositoryImpl(
          remoteDataSource: Get.find(),
          localDataSource: Get.find(),
          networkInfo: Get.find(),
        ),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CreateInventoryMovementUseCase>()) {
      Get.lazyPut(
        () => CreateInventoryMovementUseCase(Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<GetWarehousesUseCase>()) {
      Get.lazyPut(() => GetWarehousesUseCase(Get.find()), fenix: true);
    }
  }
}

