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

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    // Core dependencies - use global instances
    Get.lazyPut<FlutterSecureStorage>(() => const FlutterSecureStorage());
    Get.lazyPut<NetworkInfo>(() => Get.find());

    // Data sources - use global DioClient instead of local Dio
    Get.lazyPut<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
    );
    Get.lazyPut<InventoryLocalDataSource>(
      () => InventoryLocalDataSourceImpl(secureStorage: Get.find()),
    );

    // Repository - register as interface directly
    Get.lazyPut<InventoryRepository>(
      () => InventoryRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
        networkInfo: Get.find(),
      ),
    );

    // Use cases - Query operations
    Get.lazyPut(() => GetInventoryBalancesUseCase(Get.find()));
    Get.lazyPut(() => GetInventoryMovementsUseCase(Get.find()));
    Get.lazyPut(() => GetWarehouseMovementsUseCase(Get.find()));
    Get.lazyPut(() => GetInventoryStatsUseCase(Get.find()));
    Get.lazyPut(() => inventory_usecases.GetLowStockProductsUseCase(Get.find()), tag: 'inventory');
    Get.lazyPut(() => GetInventoryMovementByIdUseCase(Get.find()));
    Get.lazyPut(() => SearchInventoryMovementsUseCase(Get.find()));
    Get.put(GetInventoryBalanceByProductUseCase(Get.find()));
    Get.lazyPut(() => GetBalancesByProductsUseCase(Get.find()));
    Get.lazyPut(() => GetOutOfStockProductsUseCase(Get.find()));
    Get.lazyPut(() => GetExpiredProductsUseCase(Get.find()));
    Get.lazyPut(() => GetNearExpiryProductsUseCase(Get.find()));

    // Use cases - Movement operations
    Get.lazyPut<CreateInventoryMovementUseCase>(() => CreateInventoryMovementUseCase(Get.find()));
    Get.lazyPut<UpdateInventoryMovementUseCase>(() => UpdateInventoryMovementUseCase(Get.find()));
    Get.lazyPut<DeleteInventoryMovementUseCase>(() => DeleteInventoryMovementUseCase(Get.find()));
    Get.lazyPut<ConfirmInventoryMovementUseCase>(() => ConfirmInventoryMovementUseCase(Get.find()));
    Get.lazyPut<CancelInventoryMovementUseCase>(() => CancelInventoryMovementUseCase(Get.find()));

    // Use cases - FIFO operations
    Get.lazyPut<CalculateFifoConsumptionUseCase>(() => CalculateFifoConsumptionUseCase(Get.find()));
    Get.lazyPut<ProcessOutboundMovementFifoUseCase>(() => ProcessOutboundMovementFifoUseCase(Get.find()));
    Get.lazyPut<ProcessBulkOutboundMovementFifoUseCase>(() => ProcessBulkOutboundMovementFifoUseCase(Get.find()));

    // Use cases - Stock operations
    Get.lazyPut<CreateStockAdjustmentUseCase>(() => CreateStockAdjustmentUseCase(Get.find()));
    Get.lazyPut<CreateBulkStockAdjustmentsUseCase>(() => CreateBulkStockAdjustmentsUseCase(Get.find()));

    // Use cases - Transfer operations
    Get.lazyPut<CreateInventoryTransferUseCase>(() => CreateInventoryTransferUseCase(Get.find()));
    Get.lazyPut<ConfirmInventoryTransferUseCase>(() => ConfirmInventoryTransferUseCase(Get.find()));

    // Use cases - Reports
    Get.lazyPut(() => GetInventoryValuationUseCase(Get.find()));
    Get.lazyPut(() => GetKardexReportUseCase(Get.find()));
    Get.lazyPut(() => GetInventoryAgingUseCase(Get.find()));
    
    // Use cases - Batches
    Get.lazyPut(() => GetInventoryBatchesUseCase(Get.find()));
    
    // Use cases - Warehouses (usar Get.put para disponibilidad inmediata)
    Get.put(GetWarehousesUseCase(Get.find()));
    Get.put(CreateWarehouseUseCase(Get.find()));
    Get.put(UpdateWarehouseUseCase(Get.find()));
    Get.put(DeleteWarehouseUseCase(Get.find()));
    Get.put(GetWarehouseByIdUseCase(Get.find()));
    Get.put(CheckWarehouseCodeExistsUseCase(Get.find()));
    Get.put(CheckWarehouseHasMovementsUseCase(Get.find()));
    Get.put(GetActiveWarehousesCountUseCase(Get.find()));
    Get.put(GetWarehouseStatsUseCase(Get.find()));

    // Controllers
    Get.lazyPut<InventoryController>(
      () => InventoryController(
        getInventoryBalancesUseCase: Get.find(),
        getInventoryMovementsUseCase: Get.find(),
        getInventoryStatsUseCase: Get.find(),
        getLowStockProductsUseCase: Get.find(tag: 'inventory'),
        getOutOfStockProductsUseCase: Get.find(),
        getExpiredProductsUseCase: Get.find(),
        getNearExpiryProductsUseCase: Get.find(),
      ),
    );

    Get.lazyPut<InventoryMovementsController>(
      () => InventoryMovementsController(
        getInventoryMovementsUseCase: Get.find(),
        getWarehouseMovementsUseCase: Get.find(),
        createInventoryMovementUseCase: Get.find(),
        getInventoryMovementByIdUseCase: Get.find(),
        confirmInventoryMovementUseCase: Get.find(),
        cancelInventoryMovementUseCase: Get.find(),
        calculateFifoConsumptionUseCase: Get.find(),
        searchProductsUseCase: Get.find(), // From products module
      ),
    );

    Get.lazyPut<InventoryAdjustmentsController>(
      () => InventoryAdjustmentsController(
        createStockAdjustmentUseCase: Get.find(),
        getInventoryBalanceByProductUseCase: Get.find(),
        searchProductsUseCase: Get.find(), // From products module
        getWarehousesUseCase: Get.find(), // For warehouse selection
      ),
    );

    Get.lazyPut<InventoryBulkAdjustmentsController>(
      () => InventoryBulkAdjustmentsController(
        createBulkStockAdjustmentsUseCase: Get.find<CreateBulkStockAdjustmentsUseCase>(),
        getInventoryBalanceByProductUseCase: Get.find<GetInventoryBalanceByProductUseCase>(),
        searchProductsUseCase: Get.find(), // From products module
        getWarehousesUseCase: Get.find(), // For warehouse selection
      ),
    );

    // New controllers for the complete inventory system
    Get.lazyPut<KardexController>(
      () => KardexController(
        getKardexReportUseCase: Get.find(),
      ),
    );

    Get.lazyPut<InventoryBalanceController>(
      () => InventoryBalanceController(
        getInventoryBalancesUseCase: Get.find(),
        getInventoryValuationUseCase: Get.find(),
      ),
    );

    Get.lazyPut<InventoryBatchesController>(
      () => InventoryBatchesController(
        getInventoryBatchesUseCase: Get.find(),
      ),
    );

    // New controllers for transfers and aging reports
    Get.lazyPut<InventoryTransfersController>(
      () => InventoryTransfersController(
        createTransferUseCase: Get.find(),
        confirmTransferUseCase: Get.find(),
        getMovementsUseCase: Get.find(),
        cancelInventoryMovementUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
        searchProductsUseCase: Get.find(), // From products module
        getInventoryBalanceByProductUseCase: Get.find(),
      ),
    );

    Get.lazyPut<InventoryAgingController>(
      () => InventoryAgingController(
        getInventoryAgingUseCase: Get.find(),
      ),
    );

    Get.put<WarehousesController>(
      WarehousesController(
        getWarehousesUseCase: Get.find(),
        getWarehouseStatsUseCase: Get.find(),
        deleteWarehouseUseCase: Get.find(),
      ),
      permanent: true, // Mantener el controlador en memoria
    );

    Get.lazyPut<WarehouseFormController>(
      () => WarehouseFormController(
        createWarehouseUseCase: Get.find(),
        updateWarehouseUseCase: Get.find(),
        getWarehouseByIdUseCase: Get.find(),
        checkWarehouseCodeExistsUseCase: Get.find(),
      ),
    );

    Get.lazyPut<WarehouseDetailController>(
      () => WarehouseDetailController(
        getWarehouseByIdUseCase: Get.find(),
        deleteWarehouseUseCase: Get.find(),
        checkWarehouseHasMovementsUseCase: Get.find(),
        getActiveWarehousesCountUseCase: Get.find(),
      ),
    );
  }
}