// test/fixtures/inventory_fixtures.dart
import 'package:baudex_desktop/features/inventory/domain/entities/inventory_movement.dart';

/// Test fixtures for Inventory module
class InventoryFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single inventory movement entity with default test data
  static InventoryMovement createInventoryMovementEntity({
    String id = 'inv-mov-001',
    String productId = 'prod-001',
    String productName = 'Test Product',
    String productSku = 'SKU-001',
    InventoryMovementType type = InventoryMovementType.inbound,
    InventoryMovementStatus status = InventoryMovementStatus.confirmed,
    InventoryMovementReason reason = InventoryMovementReason.purchase,
    int quantity = 10,
    double unitCost = 50000.0,
    double totalCost = 500000.0,
    double? unitPrice,
    double? totalPrice,
    String? lotNumber,
    DateTime? expiryDate,
    String? warehouseId = 'warehouse-001',
    String? warehouseName = 'Main Warehouse',
    String? referenceId,
    String? referenceType,
    String? notes,
    String? userId = 'user-001',
    String? userName = 'Test User',
    DateTime? movementDate,
  }) {
    return InventoryMovement(
      id: id,
      productId: productId,
      productName: productName,
      productSku: productSku,
      type: type,
      status: status,
      reason: reason,
      quantity: quantity,
      unitCost: unitCost,
      totalCost: totalCost,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      lotNumber: lotNumber,
      expiryDate: expiryDate,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      referenceId: referenceId,
      referenceType: referenceType,
      notes: notes,
      userId: userId,
      userName: userName,
      movementDate: movementDate ?? DateTime(2024, 1, 1),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of inventory movement entities
  static List<InventoryMovement> createInventoryMovementEntityList(int count) {
    return List.generate(count, (index) {
      return createInventoryMovementEntity(
        id: 'inv-mov-${(index + 1).toString().padLeft(3, '0')}',
        productId: 'prod-${(index + 1).toString().padLeft(3, '0')}',
        productName: 'Product ${index + 1}',
        productSku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        quantity: (index + 1) * 5,
        movementDate: DateTime(2024, 1, 1).add(Duration(days: index)),
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES
  // ============================================================================

  /// Creates an inbound movement (purchase)
  static InventoryMovement createInboundMovement({
    String id = 'inv-mov-inbound',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.inbound,
      reason: InventoryMovementReason.purchase,
      quantity: 50,
      referenceId: 'po-001',
      referenceType: 'purchase_order',
    );
  }

  /// Creates an outbound movement (sale)
  static InventoryMovement createOutboundMovement({
    String id = 'inv-mov-outbound',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.outbound,
      reason: InventoryMovementReason.sale,
      quantity: 10,
      unitPrice: 100000.0,
      totalPrice: 1000000.0,
      referenceId: 'inv-001',
      referenceType: 'invoice',
    );
  }

  /// Creates an adjustment movement
  static InventoryMovement createAdjustmentMovement({
    String id = 'inv-mov-adjustment',
    int quantity = 5,
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.adjustment,
      reason: InventoryMovementReason.adjustment,
      quantity: quantity,
      notes: 'Stock count adjustment',
    );
  }

  /// Creates a transfer movement
  static InventoryMovement createTransferMovement({
    String id = 'inv-mov-transfer',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.transfer,
      reason: InventoryMovementReason.transfer,
      quantity: 15,
      warehouseId: 'warehouse-002',
      warehouseName: 'Secondary Warehouse',
    );
  }

  /// Creates a transfer-in movement
  static InventoryMovement createTransferInMovement({
    String id = 'inv-mov-transfer-in',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.transferIn,
      reason: InventoryMovementReason.transfer,
      quantity: 15,
      warehouseId: 'warehouse-001',
      warehouseName: 'Main Warehouse',
    );
  }

  /// Creates a transfer-out movement
  static InventoryMovement createTransferOutMovement({
    String id = 'inv-mov-transfer-out',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.transferOut,
      reason: InventoryMovementReason.transfer,
      quantity: 15,
      warehouseId: 'warehouse-002',
      warehouseName: 'Secondary Warehouse',
    );
  }

  /// Creates a pending movement
  static InventoryMovement createPendingMovement({
    String id = 'inv-mov-pending',
  }) {
    return createInventoryMovementEntity(
      id: id,
      status: InventoryMovementStatus.pending,
      notes: 'Awaiting approval',
    );
  }

  /// Creates a cancelled movement
  static InventoryMovement createCancelledMovement({
    String id = 'inv-mov-cancelled',
  }) {
    return createInventoryMovementEntity(
      id: id,
      status: InventoryMovementStatus.cancelled,
      notes: 'Cancelled due to error',
    );
  }

  /// Creates a movement with lot number
  static InventoryMovement createMovementWithLot({
    String id = 'inv-mov-lot',
    String lotNumber = 'LOT-2024-001',
  }) {
    return createInventoryMovementEntity(
      id: id,
      lotNumber: lotNumber,
      notes: 'Batch tracked item',
    );
  }

  /// Creates a movement with expiry date
  static InventoryMovement createMovementWithExpiry({
    String id = 'inv-mov-expiry',
    DateTime? expiryDate,
  }) {
    return createInventoryMovementEntity(
      id: id,
      lotNumber: 'LOT-2024-001',
      expiryDate: expiryDate ?? DateTime(2025, 12, 31),
      notes: 'Perishable item',
    );
  }

  /// Creates an expired movement
  static InventoryMovement createExpiredMovement({
    String id = 'inv-mov-expired',
  }) {
    return createInventoryMovementEntity(
      id: id,
      lotNumber: 'LOT-2023-001',
      expiryDate: DateTime.now().subtract(const Duration(days: 30)),
      reason: InventoryMovementReason.expiration,
      type: InventoryMovementType.adjustment,
      quantity: -5,
    );
  }

  /// Creates a movement for damaged goods
  static InventoryMovement createDamagedGoodsMovement({
    String id = 'inv-mov-damaged',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.adjustment,
      reason: InventoryMovementReason.damage,
      quantity: -3,
      notes: 'Items damaged during handling',
    );
  }

  /// Creates a movement for lost goods
  static InventoryMovement createLostGoodsMovement({
    String id = 'inv-mov-lost',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.adjustment,
      reason: InventoryMovementReason.loss,
      quantity: -2,
      notes: 'Items missing from inventory',
    );
  }

  /// Creates a movement for return
  static InventoryMovement createReturnMovement({
    String id = 'inv-mov-return',
  }) {
    return createInventoryMovementEntity(
      id: id,
      type: InventoryMovementType.inbound,
      reason: InventoryMovementReason.return_,
      quantity: 5,
      referenceId: 'inv-001',
      referenceType: 'invoice',
      notes: 'Customer return',
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of movements with different types
  static List<InventoryMovement> createMixedTypeMovements() {
    return [
      createInboundMovement(id: 'inv-mov-001'),
      createOutboundMovement(id: 'inv-mov-002'),
      createAdjustmentMovement(id: 'inv-mov-003'),
      createTransferMovement(id: 'inv-mov-004'),
    ];
  }

  /// Creates a mix of movements with different statuses
  static List<InventoryMovement> createMixedStatusMovements() {
    return [
      createInventoryMovementEntity(
        id: 'inv-mov-001',
        status: InventoryMovementStatus.confirmed,
      ),
      createInventoryMovementEntity(
        id: 'inv-mov-002',
        status: InventoryMovementStatus.confirmed,
      ),
      createPendingMovement(id: 'inv-mov-003'),
      createCancelledMovement(id: 'inv-mov-004'),
    ];
  }

  /// Creates movements by reason
  static List<InventoryMovement> createMovementsByReason() {
    return [
      createInventoryMovementEntity(
        id: 'inv-mov-001',
        reason: InventoryMovementReason.purchase,
        type: InventoryMovementType.inbound,
      ),
      createInventoryMovementEntity(
        id: 'inv-mov-002',
        reason: InventoryMovementReason.sale,
        type: InventoryMovementType.outbound,
      ),
      createInventoryMovementEntity(
        id: 'inv-mov-003',
        reason: InventoryMovementReason.adjustment,
        type: InventoryMovementType.adjustment,
      ),
      createDamagedGoodsMovement(id: 'inv-mov-004'),
      createLostGoodsMovement(id: 'inv-mov-005'),
      createReturnMovement(id: 'inv-mov-006'),
    ];
  }

  /// Creates movements with lot tracking
  static List<InventoryMovement> createMovementsWithLotTracking() {
    return [
      createMovementWithLot(id: 'inv-mov-001', lotNumber: 'LOT-2024-001'),
      createMovementWithLot(id: 'inv-mov-002', lotNumber: 'LOT-2024-002'),
      createMovementWithExpiry(
        id: 'inv-mov-003',
        expiryDate: DateTime(2025, 6, 30),
      ),
    ];
  }
}
