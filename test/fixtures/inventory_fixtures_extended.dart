// test/fixtures/inventory_fixtures_extended.dart
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_balance.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_batch.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_stats.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/warehouse_with_stats.dart';
import 'package:baudex_desktop/features/inventory/domain/entities/kardex_entry.dart' hide KardexSummary;
import 'package:baudex_desktop/features/inventory/domain/entities/kardex_report.dart';

/// Extended test fixtures for Inventory module - covers all entities
class InventoryFixturesExtended {
  // ============================================================================
  // WAREHOUSE FIXTURES
  // ============================================================================

  static Warehouse createWarehouseEntity({
    String id = 'warehouse-001',
    String name = 'Main Warehouse',
    String code = 'WH-MAIN',
    String? description,
    String? address,
    bool isActive = true,
    bool isMainWarehouse = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Warehouse(
      id: id,
      name: name,
      code: code,
      description: description ?? 'Main warehouse for all products',
      address: address ?? '123 Main St, City, Country',
      isActive: isActive,
      isMainWarehouse: isMainWarehouse,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );
  }

  static List<Warehouse> createWarehouseEntityList(int count) {
    return List.generate(count, (index) {
      return createWarehouseEntity(
        id: 'warehouse-${(index + 1).toString().padLeft(3, '0')}',
        name: 'Warehouse ${index + 1}',
        code: 'WH-${(index + 1).toString().padLeft(3, '0')}',
        isMainWarehouse: index == 0,
      );
    });
  }

  static Warehouse createMainWarehouse() {
    return createWarehouseEntity(
      id: 'warehouse-main',
      name: 'Main Warehouse',
      code: 'WH-MAIN',
      isMainWarehouse: true,
      isActive: true,
    );
  }

  static Warehouse createSecondaryWarehouse() {
    return createWarehouseEntity(
      id: 'warehouse-secondary',
      name: 'Secondary Warehouse',
      code: 'WH-SEC',
      isMainWarehouse: false,
      isActive: true,
    );
  }

  static Warehouse createInactiveWarehouse() {
    return createWarehouseEntity(
      id: 'warehouse-inactive',
      name: 'Inactive Warehouse',
      code: 'WH-INACTIVE',
      isActive: false,
    );
  }

  // ============================================================================
  // WAREHOUSE STATS FIXTURES
  // ============================================================================

  static WarehouseStats createWarehouseStatsEntity({
    int totalProducts = 100,
    double totalValue = 1000000.0,
    double totalQuantity = 500.0,
    int lowStockProducts = 5,
    int outOfStockProducts = 2,
  }) {
    return WarehouseStats(
      totalProducts: totalProducts,
      totalValue: totalValue,
      totalQuantity: totalQuantity,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
    );
  }

  static WarehouseWithStats createWarehouseWithStatsEntity({
    Warehouse? warehouse,
    WarehouseStats? stats,
  }) {
    return WarehouseWithStats(
      warehouse: warehouse ?? createWarehouseEntity(),
      stats: stats ?? createWarehouseStatsEntity(),
    );
  }

  // ============================================================================
  // INVENTORY BALANCE FIXTURES
  // ============================================================================

  static InventoryBalance createInventoryBalanceEntity({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    String categoryName = 'Electronics',
    int totalQuantity = 100,
    int minStock = 10,
    double averageCost = 50000.0,
    double totalValue = 5000000.0,
    bool isLowStock = false,
    bool isOutOfStock = false,
    String? warehouseId,
    List<InventoryLot>? fifoLots,
    int? availableQuantity,
    int reservedQuantity = 0,
    int expiredQuantity = 0,
    int nearExpiryQuantity = 0,
    DateTime? lastUpdated,
  }) {
    return InventoryBalance(
      productId: productId,
      productName: productName,
      productSku: productSku,
      categoryName: categoryName,
      totalQuantity: totalQuantity,
      minStock: minStock,
      averageCost: averageCost,
      totalValue: totalValue,
      isLowStock: isLowStock,
      isOutOfStock: isOutOfStock,
      warehouseId: warehouseId,
      fifoLots: fifoLots ?? [],
      availableQuantity: availableQuantity,
      reservedQuantity: reservedQuantity,
      expiredQuantity: expiredQuantity,
      nearExpiryQuantity: nearExpiryQuantity,
      lastUpdated: lastUpdated ?? DateTime(2024, 1, 1),
    );
  }

  static List<InventoryBalance> createInventoryBalanceEntityList(int count) {
    return List.generate(count, (index) {
      return createInventoryBalanceEntity(
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productSku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        totalQuantity: (index + 1) * 10,
      );
    });
  }

  static InventoryBalance createLowStockBalance() {
    return createInventoryBalanceEntity(
      productId: 'prod-lowstock',
      totalQuantity: 5,
      minStock: 10,
      isLowStock: true,
    );
  }

  static InventoryBalance createOutOfStockBalance() {
    return createInventoryBalanceEntity(
      productId: 'prod-outofstock',
      totalQuantity: 0,
      minStock: 10,
      isOutOfStock: true,
    );
  }

  static InventoryLot createInventoryLot({
    String lotNumber = 'LOT-2024-001',
    int quantity = 50,
    double unitCost = 50000.0,
    DateTime? entryDate,
    DateTime? expiryDate,
  }) {
    return InventoryLot(
      lotNumber: lotNumber,
      quantity: quantity,
      unitCost: unitCost,
      entryDate: entryDate ?? DateTime(2024, 1, 1),
      expiryDate: expiryDate,
    );
  }

  static FifoConsumption createFifoConsumption({
    InventoryLot? lot,
    int quantityConsumed = 10,
    double? unitCost,
    double? totalCost,
  }) {
    final fifoLot = lot ?? createInventoryLot();
    final cost = unitCost ?? fifoLot.unitCost;
    return FifoConsumption(
      lot: fifoLot,
      quantityConsumed: quantityConsumed,
      unitCost: cost,
      totalCost: totalCost ?? (quantityConsumed * cost),
    );
  }

  // ============================================================================
  // INVENTORY BATCH FIXTURES
  // ============================================================================

  static InventoryBatch createInventoryBatchEntity({
    String id = 'batch-001',
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    String batchNumber = 'BATCH-2024-001',
    int originalQuantity = 100,
    int currentQuantity = 75,
    int consumedQuantity = 25,
    double unitCost = 50000.0,
    double? totalCost,
    DateTime? entryDate,
    DateTime? expiryDate,
    InventoryBatchStatus status = InventoryBatchStatus.active,
    String? purchaseOrderId,
    String? purchaseOrderNumber,
    String? supplierId,
    String? supplierName,
    String? warehouseId,
    String? warehouseName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryBatch(
      id: id,
      productId: productId,
      productName: productName,
      productSku: productSku,
      batchNumber: batchNumber,
      originalQuantity: originalQuantity,
      currentQuantity: currentQuantity,
      consumedQuantity: consumedQuantity,
      unitCost: unitCost,
      totalCost: totalCost ?? (originalQuantity * unitCost),
      entryDate: entryDate ?? DateTime(2024, 1, 1),
      expiryDate: expiryDate,
      status: status,
      purchaseOrderId: purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber,
      supplierId: supplierId,
      supplierName: supplierName,
      warehouseId: warehouseId ?? 'warehouse-001',
      warehouseName: warehouseName ?? 'Main Warehouse',
      notes: notes,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );
  }

  static List<InventoryBatch> createInventoryBatchEntityList(int count) {
    return List.generate(count, (index) {
      return createInventoryBatchEntity(
        id: 'batch-${(index + 1).toString().padLeft(3, '0')}',
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productSku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        batchNumber: 'BATCH-2024-${(index + 1).toString().padLeft(3, '0')}',
      );
    });
  }

  static InventoryBatch createActiveBatch() {
    return createInventoryBatchEntity(
      id: 'batch-active',
      status: InventoryBatchStatus.active,
      currentQuantity: 50,
    );
  }

  static InventoryBatch createDepletedBatch() {
    return createInventoryBatchEntity(
      id: 'batch-depleted',
      status: InventoryBatchStatus.depleted,
      currentQuantity: 0,
      consumedQuantity: 100,
    );
  }

  static InventoryBatch createExpiredBatch() {
    return createInventoryBatchEntity(
      id: 'batch-expired',
      status: InventoryBatchStatus.expired,
      expiryDate: DateTime.now().subtract(const Duration(days: 30)),
    );
  }

  static InventoryBatch createNearExpiryBatch() {
    return createInventoryBatchEntity(
      id: 'batch-near-expiry',
      status: InventoryBatchStatus.active,
      expiryDate: DateTime.now().add(const Duration(days: 15)),
    );
  }

  // ============================================================================
  // INVENTORY STATS FIXTURES
  // ============================================================================

  static InventoryStats createInventoryStatsEntity({
    int totalProducts = 150,
    int totalBatches = 75,
    int totalMovements = 500,
    double totalValue = 7500000.0,
    Map<String, dynamic>? movementsByType,
  }) {
    return InventoryStats(
      totalProducts: totalProducts,
      totalBatches: totalBatches,
      totalMovements: totalMovements,
      totalValue: totalValue,
      movementsByType: movementsByType ??
          {
            'inbound': 200,
            'outbound': 250,
            'adjustment': 30,
            'transfer': 20,
            'today': 15,
            'lowStock': 8,
            'expired': 3,
          },
    );
  }

  // ============================================================================
  // KARDEX ENTRY FIXTURES
  // ============================================================================

  static KardexEntry createKardexEntryEntity({
    String id = 'entry-001',
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    DateTime? date,
    String documentType = 'inbound',
    String documentNumber = 'DOC-001',
    String? description,
    int quantityIn = 0,
    int quantityOut = 0,
    int balance = 100,
    double unitCostIn = 50000.0,
    double unitCostOut = 0.0,
    double averageCost = 50000.0,
    double totalValue = 5000000.0,
    String? lotNumber,
    String? referenceId,
    String? referenceType,
  }) {
    return KardexEntry(
      id: id,
      productId: productId,
      productName: productName,
      productSku: productSku,
      date: date ?? DateTime(2024, 1, 1),
      documentType: documentType,
      documentNumber: documentNumber,
      description: description ?? 'Kardex entry for $documentType',
      quantityIn: quantityIn,
      quantityOut: quantityOut,
      balance: balance,
      unitCostIn: unitCostIn,
      unitCostOut: unitCostOut,
      averageCost: averageCost,
      totalValue: totalValue,
      lotNumber: lotNumber,
      referenceId: referenceId,
      referenceType: referenceType,
    );
  }

  static List<KardexEntry> createKardexEntryList(int count) {
    return List.generate(count, (index) {
      final isInbound = index % 2 == 0;
      return createKardexEntryEntity(
        id: 'entry-${(index + 1).toString().padLeft(3, '0')}',
        documentType: isInbound ? 'inbound' : 'outbound',
        documentNumber: 'DOC-${(index + 1).toString().padLeft(3, '0')}',
        quantityIn: isInbound ? 10 : 0,
        quantityOut: isInbound ? 0 : 5,
        balance: 100 + (isInbound ? 10 : -5) * (index + 1),
        date: DateTime(2024, 1, 1).add(Duration(days: index)),
      );
    });
  }

  // ============================================================================
  // KARDEX REPORT FIXTURES
  // ============================================================================

  static KardexReport createKardexReportEntity({
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    String? categoryName,
    DateTime? startDate,
    DateTime? endDate,
    double initialQuantity = 50,
    double initialValue = 2500000.0,
    double initialAverageCost = 50000.0,
    double finalQuantity = 100,
    double finalValue = 5000000.0,
    double finalAverageCost = 50000.0,
    int totalEntries = 75,
    int totalExits = 25,
    double totalPurchases = 3750000.0,
    double totalSales = 1250000.0,
    List<KardexMovement>? movements,
  }) {
    return KardexReport(
      product: KardexProduct(
        id: productId,
        name: productName,
        sku: productSku,
        categoryName: categoryName,
      ),
      period: KardexPeriod(
        startDate: startDate ?? DateTime(2024, 1, 1),
        endDate: endDate ?? DateTime(2024, 1, 31),
      ),
      initialBalance: KardexBalance(
        quantity: initialQuantity,
        value: initialValue,
        averageCost: initialAverageCost,
      ),
      movements: movements ?? createKardexMovementList(5),
      finalBalance: KardexBalance(
        quantity: finalQuantity,
        value: finalValue,
        averageCost: finalAverageCost,
      ),
      summary: KardexSummary(
        totalEntries: totalEntries,
        totalExits: totalExits,
        totalPurchases: totalPurchases,
        totalSales: totalSales,
        averageUnitCost: finalAverageCost,
        totalValue: finalValue,
      ),
    );
  }

  static List<KardexMovement> createKardexMovementList(int count) {
    return List.generate(count, (index) {
      final isEntry = index % 2 == 0;
      return KardexMovement(
        date: DateTime(2024, 1, 1).add(Duration(days: index)),
        movementNumber: 'MOV-${(index + 1).toString().padLeft(3, '0')}',
        movementType: isEntry ? 'purchase' : 'sale',
        description: isEntry ? 'Purchase entry' : 'Sale exit',
        entryQuantity: isEntry ? 10.0 : 0.0,
        exitQuantity: isEntry ? 0.0 : 5.0,
        balance: (100 + (isEntry ? 10 : -5) * (index + 1)).toDouble(),
        unitCost: 50000.0,
        entryCost: isEntry ? 500000.0 : 0.0,
        exitCost: isEntry ? 0.0 : 250000.0,
        balanceValue: (100 + (isEntry ? 10 : -5) * (index + 1)) * 50000.0,
        createdBy: 'system',
      );
    });
  }
}
