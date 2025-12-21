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

    // Data sources - use put for immediate availability
    Get.put<InventoryRemoteDataSource>(
      InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
    );
    Get.put<InventoryLocalDataSource>(
      InventoryLocalDataSourceImpl(secureStorage: Get.find()),
    );

    // Repository - register with put for immediate availability
    Get.put<InventoryRepository>(
      InventoryRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
        networkInfo: Get.find(),
      ),
    );

    // Use cases - Query operations (usar Get.put para disponibilidad inmediata)
    Get.put(GetInventoryBalancesUseCase(Get.find()));
    Get.put(GetInventoryMovementsUseCase(Get.find()));
    Get.put(GetWarehouseMovementsUseCase(Get.find()));
    Get.put(GetInventoryStatsUseCase(Get.find()));
    Get.put(inventory_usecases.GetLowStockProductsUseCase(Get.find()), tag: 'inventory');
    Get.put(GetInventoryMovementByIdUseCase(Get.find()));
    Get.put(SearchInventoryMovementsUseCase(Get.find()));
    Get.put(GetInventoryBalanceByProductUseCase(Get.find()));
    Get.put(GetBalancesByProductsUseCase(Get.find()));
    Get.put(GetOutOfStockProductsUseCase(Get.find()));
    Get.put(GetExpiredProductsUseCase(Get.find()));
    Get.put(GetNearExpiryProductsUseCase(Get.find()));

    // Use cases - Movement operations (usar Get.put para disponibilidad inmediata)
    Get.put<CreateInventoryMovementUseCase>(CreateInventoryMovementUseCase(Get.find()));
    Get.put<UpdateInventoryMovementUseCase>(UpdateInventoryMovementUseCase(Get.find()));
    Get.put<DeleteInventoryMovementUseCase>(DeleteInventoryMovementUseCase(Get.find()));
    Get.put<ConfirmInventoryMovementUseCase>(ConfirmInventoryMovementUseCase(Get.find()));
    Get.put<CancelInventoryMovementUseCase>(CancelInventoryMovementUseCase(Get.find()));

    // Use cases - FIFO operations
    Get.put<CalculateFifoConsumptionUseCase>(CalculateFifoConsumptionUseCase(Get.find()));
    Get.put<ProcessOutboundMovementFifoUseCase>(ProcessOutboundMovementFifoUseCase(Get.find()));
    Get.put<ProcessBulkOutboundMovementFifoUseCase>(ProcessBulkOutboundMovementFifoUseCase(Get.find()));

    // Use cases - Stock operations
    Get.put<CreateStockAdjustmentUseCase>(CreateStockAdjustmentUseCase(Get.find()));
    Get.put<CreateBulkStockAdjustmentsUseCase>(CreateBulkStockAdjustmentsUseCase(Get.find()));

    // Use cases - Transfer operations
    Get.put<CreateInventoryTransferUseCase>(CreateInventoryTransferUseCase(Get.find()));
    Get.put<ConfirmInventoryTransferUseCase>(ConfirmInventoryTransferUseCase(Get.find()));

    // Use cases - Reports
    Get.put(GetInventoryValuationUseCase(Get.find()));
    Get.put(GetKardexReportUseCase(Get.find()));
    Get.put(GetInventoryAgingUseCase(Get.find()));

    // Use cases - Batches
    Get.put(GetInventoryBatchesUseCase(Get.find()));
    
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

    // Controllers (usar Get.put para disponibilidad inmediata)
    Get.put<InventoryController>(
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

    Get.put<InventoryMovementsController>(
      InventoryMovementsController(
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

    Get.put<InventoryAdjustmentsController>(
      InventoryAdjustmentsController(
        createStockAdjustmentUseCase: Get.find(),
        getInventoryBalanceByProductUseCase: Get.find(),
        searchProductsUseCase: Get.find(), // From products module
        getWarehousesUseCase: Get.find(), // For warehouse selection
      ),
    );

    Get.put<InventoryBulkAdjustmentsController>(
      InventoryBulkAdjustmentsController(
        createBulkStockAdjustmentsUseCase: Get.find<CreateBulkStockAdjustmentsUseCase>(),
        getInventoryBalanceByProductUseCase: Get.find<GetInventoryBalanceByProductUseCase>(),
        searchProductsUseCase: Get.find(), // From products module
        getWarehousesUseCase: Get.find(), // For warehouse selection
      ),
    );

    // New controllers for the complete inventory system
    Get.put<KardexController>(
      KardexController(
        getKardexReportUseCase: Get.find(),
      ),
    );

    Get.put<InventoryBalanceController>(
      InventoryBalanceController(
        getInventoryBalancesUseCase: Get.find(),
        getInventoryValuationUseCase: Get.find(),
      ),
    );

    Get.put<InventoryBatchesController>(
      InventoryBatchesController(
        getInventoryBatchesUseCase: Get.find(),
      ),
    );

    // New controllers for transfers and aging reports
    Get.put<InventoryTransfersController>(
      InventoryTransfersController(
        createTransferUseCase: Get.find(),
        confirmTransferUseCase: Get.find(),
        getMovementsUseCase: Get.find(),
        cancelInventoryMovementUseCase: Get.find(),
        getWarehousesUseCase: Get.find(),
        searchProductsUseCase: Get.find(), // From products module
        getInventoryBalanceByProductUseCase: Get.find(),
      ),
    );

    Get.put<InventoryAgingController>(
      InventoryAgingController(
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

    Get.put<WarehouseFormController>(
      WarehouseFormController(
        createWarehouseUseCase: Get.find(),
        updateWarehouseUseCase: Get.find(),
        getWarehouseByIdUseCase: Get.find(),
        checkWarehouseCodeExistsUseCase: Get.find(),
      ),
    );

    Get.put<WarehouseDetailController>(
      WarehouseDetailController(
        getWarehouseByIdUseCase: Get.find(),
        deleteWarehouseUseCase: Get.find(),
        checkWarehouseHasMovementsUseCase: Get.find(),
        getActiveWarehousesCountUseCase: Get.find(),
      ),
    );
  }
}