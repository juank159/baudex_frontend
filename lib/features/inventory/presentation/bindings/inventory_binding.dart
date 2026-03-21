// lib/features/inventory/presentation/bindings/inventory_binding.dart
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/usecases/get_inventory_balances_usecase.dart';
import '../../domain/usecases/get_inventory_movements_usecase.dart';
import '../../domain/usecases/get_warehouse_movements_usecase.dart';
import '../../domain/usecases/get_inventory_stats_usecase.dart';
import '../../domain/usecases/get_low_stock_products_usecase.dart' as inventory_usecases;
import '../../domain/usecases/create_inventory_movement_usecase.dart';
import '../../domain/usecases/update_inventory_movement_usecase.dart';
import '../../domain/usecases/delete_inventory_movement_usecase.dart';
import '../../domain/usecases/confirm_inventory_movement_usecase.dart';
import '../../domain/usecases/cancel_inventory_movement_usecase.dart';
import '../../domain/usecases/get_inventory_movement_by_id_usecase.dart';
import '../../domain/usecases/search_inventory_movements_usecase.dart';
import '../../domain/usecases/get_inventory_balance_by_product_usecase.dart';
import '../../domain/usecases/calculate_fifo_consumption_usecase.dart';
import '../../domain/usecases/process_outbound_movement_fifo_usecase.dart';
import '../../domain/usecases/process_bulk_outbound_movement_fifo_usecase.dart';
import '../../domain/usecases/create_stock_adjustment_usecase.dart';
import '../../domain/usecases/create_bulk_stock_adjustments_usecase.dart';
import '../../domain/usecases/create_inventory_transfer_usecase.dart';
import '../../domain/usecases/confirm_inventory_transfer_usecase.dart';
import '../../domain/usecases/get_inventory_valuation_usecase.dart';
import '../../domain/usecases/get_kardex_report_usecase.dart';
import '../../domain/usecases/get_inventory_aging_usecase.dart';
import '../../domain/usecases/get_balances_by_products_usecase.dart';
import '../../domain/usecases/get_out_of_stock_products_usecase.dart';
import '../../domain/usecases/get_expired_products_usecase.dart';
import '../../domain/usecases/get_near_expiry_products_usecase.dart';
import '../../domain/usecases/get_inventory_batches_usecase.dart';
import '../../domain/usecases/get_warehouses_usecase.dart';
import '../../domain/usecases/create_warehouse_usecase.dart';
import '../../domain/usecases/update_warehouse_usecase.dart';
import '../../domain/usecases/delete_warehouse_usecase.dart';
import '../../domain/usecases/get_warehouse_by_id_usecase.dart';
import '../../domain/usecases/check_warehouse_code_exists_usecase.dart';
import '../../domain/usecases/check_warehouse_has_movements_usecase.dart';
import '../../domain/usecases/get_active_warehouses_count_usecase.dart';
import '../../domain/usecases/get_warehouse_stats_usecase.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/datasources/inventory_remote_datasource.dart';
import '../../data/datasources/inventory_local_datasource.dart';
import '../../data/datasources/inventory_local_datasource_isar.dart';
import '../controllers/inventory_controller.dart';
import '../controllers/inventory_movements_controller.dart';
import '../controllers/inventory_adjustments_controller.dart';
import '../controllers/inventory_bulk_adjustments_controller.dart';
import '../controllers/kardex_controller.dart';
import '../controllers/inventory_balance_controller.dart';
import '../controllers/inventory_batches_controller.dart';
import '../controllers/inventory_transfers_controller.dart';
import '../controllers/inventory_aging_controller.dart';
import '../controllers/warehouses_controller.dart';
import '../controllers/warehouse_form_controller.dart';
import '../controllers/warehouse_detail_controller.dart';

// Product dependencies (needed for SearchProductsUseCase)
import '../../../products/domain/usecases/search_products_usecase.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/data/datasources/product_remote_datasource.dart';
import '../../../products/data/datasources/product_local_datasource.dart';
import '../../../products/data/datasources/product_local_datasource_isar.dart';
import '../../../products/data/repositories/product_repository_impl.dart';
import '../../../../app/data/local/isar_database.dart';

class InventoryBinding extends Bindings {
  /// Helper: delete + put to guarantee fresh instance (survives Get.offAllNamed)
  void _safePut<T>(T instance, {String? tag}) {
    if (Get.isRegistered<T>(tag: tag)) {
      Get.delete<T>(tag: tag, force: true);
    }
    Get.put<T>(instance, tag: tag);
  }

  @override
  void dependencies() {
    // Asegurar SearchProductsUseCase disponible (normalmente registrado por ProductBinding)
    if (!Get.isRegistered<SearchProductsUseCase>()) {
      if (!Get.isRegistered<ProductRemoteDataSource>()) {
        Get.lazyPut<ProductRemoteDataSource>(
          () => ProductRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ProductLocalDataSource>()) {
        Get.lazyPut<ProductLocalDataSource>(
          () => ProductLocalDataSourceIsar(Get.find<IsarDatabase>()),
          fenix: true,
        );
      }
      if (!Get.isRegistered<ProductRepository>()) {
        Get.lazyPut<ProductRepository>(
          () => ProductRepositoryImpl(
            remoteDataSource: Get.find<ProductRemoteDataSource>(),
            localDataSource: Get.find<ProductLocalDataSource>(),
            networkInfo: Get.find<NetworkInfo>(),
          ),
          fenix: true,
        );
      }
      Get.lazyPut(() => SearchProductsUseCase(Get.find<ProductRepository>()), fenix: true);
    }

    // Core dependencies - use global instances
    if (!Get.isRegistered<FlutterSecureStorage>()) {
      Get.lazyPut<FlutterSecureStorage>(() => const FlutterSecureStorage());
    }

    // Data sources - safePut guarantees fresh instance after route disposal
    _safePut<InventoryRemoteDataSource>(
      InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
    );
    _safePut<InventoryLocalDataSource>(
      InventoryLocalDataSourceIsar(Get.find<IsarDatabase>()),
    );

    // Repository
    _safePut<InventoryRepository>(
      InventoryRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
        networkInfo: Get.find(),
      ),
    );

    // Use cases - Query operations
    _safePut(GetInventoryBalancesUseCase(Get.find()));
    _safePut(GetInventoryMovementsUseCase(Get.find()));
    _safePut(GetWarehouseMovementsUseCase(Get.find()));
    _safePut(GetInventoryStatsUseCase(Get.find()));
    _safePut(inventory_usecases.GetLowStockProductsUseCase(Get.find()), tag: 'inventory');
    _safePut(GetInventoryMovementByIdUseCase(Get.find()));
    _safePut(SearchInventoryMovementsUseCase(Get.find()));
    _safePut(GetInventoryBalanceByProductUseCase(Get.find()));
    _safePut(GetBalancesByProductsUseCase(Get.find()));
    _safePut(GetOutOfStockProductsUseCase(Get.find()));
    _safePut(GetExpiredProductsUseCase(Get.find()));
    _safePut(GetNearExpiryProductsUseCase(Get.find()));

    // Use cases - Movement operations
    _safePut<CreateInventoryMovementUseCase>(CreateInventoryMovementUseCase(Get.find()));
    _safePut<UpdateInventoryMovementUseCase>(UpdateInventoryMovementUseCase(Get.find()));
    _safePut<DeleteInventoryMovementUseCase>(DeleteInventoryMovementUseCase(Get.find()));
    _safePut<ConfirmInventoryMovementUseCase>(ConfirmInventoryMovementUseCase(Get.find()));
    _safePut<CancelInventoryMovementUseCase>(CancelInventoryMovementUseCase(Get.find()));

    // Use cases - FIFO operations
    _safePut<CalculateFifoConsumptionUseCase>(CalculateFifoConsumptionUseCase(Get.find()));
    _safePut<ProcessOutboundMovementFifoUseCase>(ProcessOutboundMovementFifoUseCase(Get.find()));
    _safePut<ProcessBulkOutboundMovementFifoUseCase>(ProcessBulkOutboundMovementFifoUseCase(Get.find()));

    // Use cases - Stock operations
    _safePut<CreateStockAdjustmentUseCase>(CreateStockAdjustmentUseCase(Get.find()));
    _safePut<CreateBulkStockAdjustmentsUseCase>(CreateBulkStockAdjustmentsUseCase(Get.find()));

    // Use cases - Transfer operations
    _safePut<CreateInventoryTransferUseCase>(CreateInventoryTransferUseCase(Get.find()));
    _safePut<ConfirmInventoryTransferUseCase>(ConfirmInventoryTransferUseCase(Get.find()));

    // Use cases - Reports
    _safePut(GetInventoryValuationUseCase(Get.find()));
    _safePut(GetKardexReportUseCase(Get.find()));
    _safePut(GetInventoryAgingUseCase(Get.find()));

    // Use cases - Batches
    _safePut(GetInventoryBatchesUseCase(Get.find()));

    // Use cases - Warehouses
    _safePut(GetWarehousesUseCase(Get.find()));
    _safePut(CreateWarehouseUseCase(Get.find()));
    _safePut(UpdateWarehouseUseCase(Get.find()));
    _safePut(DeleteWarehouseUseCase(Get.find()));
    _safePut(GetWarehouseByIdUseCase(Get.find()));
    _safePut(CheckWarehouseCodeExistsUseCase(Get.find()));
    _safePut(CheckWarehouseHasMovementsUseCase(Get.find()));
    _safePut(GetActiveWarehousesCountUseCase(Get.find()));
    _safePut(GetWarehouseStatsUseCase(Get.find()));

    // Controllers - safePut guarantees fresh instance
    _safePut<InventoryController>(
      InventoryController(
        getInventoryBalancesUseCase: Get.find(),
        getInventoryMovementsUseCase: Get.find(),
        getInventoryStatsUseCase: Get.find(),
        getLowStockProductsUseCase: Get.find(tag: 'inventory'),
        getOutOfStockProductsUseCase: Get.find(),
        getExpiredProductsUseCase: Get.find(),
        getNearExpiryProductsUseCase: Get.find(),
      ),
    );

    _safePut<InventoryMovementsController>(
      InventoryMovementsController(
        getInventoryMovementsUseCase: Get.find(),
        getWarehouseMovementsUseCase: Get.find(),
        createInventoryMovementUseCase: Get.find(),
        getInventoryMovementByIdUseCase: Get.find(),
        confirmInventoryMovementUseCase: Get.find(),
        cancelInventoryMovementUseCase: Get.find(),
        calculateFifoConsumptionUseCase: Get.find(),
        searchProductsUseCase: Get.find(),
      ),
    );

    _safePut<InventoryAdjustmentsController>(
      InventoryAdjustmentsController(
        createStockAdjustmentUseCase: Get.find(),
        getInventoryBalanceByProductUseCase: Get.find(),
        searchProductsUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
      ),
    );

    _safePut<InventoryBulkAdjustmentsController>(
      InventoryBulkAdjustmentsController(
        createBulkStockAdjustmentsUseCase: Get.find<CreateBulkStockAdjustmentsUseCase>(),
        getInventoryBalanceByProductUseCase: Get.find<GetInventoryBalanceByProductUseCase>(),
        searchProductsUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
      ),
    );

    _safePut<KardexController>(
      KardexController(
        getKardexReportUseCase: Get.find(),
      ),
    );

    _safePut<InventoryBalanceController>(
      InventoryBalanceController(
        getInventoryBalancesUseCase: Get.find(),
        getInventoryValuationUseCase: Get.find(),
      ),
    );

    _safePut<InventoryBatchesController>(
      InventoryBatchesController(
        getInventoryBatchesUseCase: Get.find(),
      ),
    );

    _safePut<InventoryTransfersController>(
      InventoryTransfersController(
        createTransferUseCase: Get.find(),
        confirmTransferUseCase: Get.find(),
        getMovementsUseCase: Get.find(),
        cancelInventoryMovementUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
        searchProductsUseCase: Get.find(),
        getInventoryBalanceByProductUseCase: Get.find(),
      ),
    );

    _safePut<InventoryAgingController>(
      InventoryAgingController(
        getInventoryAgingUseCase: Get.find(),
      ),
    );

    if (!Get.isRegistered<WarehousesController>()) {
      Get.put<WarehousesController>(
        WarehousesController(
          getWarehousesUseCase: Get.find(),
          getWarehouseStatsUseCase: Get.find(),
          deleteWarehouseUseCase: Get.find(),
        ),
        permanent: true,
      );
    }

    _safePut<WarehouseFormController>(
      WarehouseFormController(
        createWarehouseUseCase: Get.find(),
        updateWarehouseUseCase: Get.find(),
        getWarehouseByIdUseCase: Get.find(),
        checkWarehouseCodeExistsUseCase: Get.find(),
      ),
    );

    _safePut<WarehouseDetailController>(
      WarehouseDetailController(
        getWarehouseByIdUseCase: Get.find(),
        deleteWarehouseUseCase: Get.find(),
        checkWarehouseHasMovementsUseCase: Get.find(),
        getActiveWarehousesCountUseCase: Get.find(),
      ),
    );
  }
}
