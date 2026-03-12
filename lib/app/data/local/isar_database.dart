// lib/app/data/local/isar_database.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/app_logger.dart';

// Import ISAR models
import 'sync_queue.dart';
import 'models/isar_idempotency_record.dart'; // ⭐ FASE 1: Idempotencia
import '../../../features/categories/data/models/isar/isar_category.dart';
import '../../../features/customers/data/models/isar/isar_customer.dart';
import '../../../features/customer_credits/data/models/isar/isar_customer_credit.dart';
import '../../../features/products/data/models/isar/isar_product.dart';
import '../../../features/expenses/data/models/isar/isar_expense.dart';
import '../../../features/invoices/data/models/isar/isar_invoice.dart';
import '../../../features/credit_notes/data/models/isar/isar_credit_note.dart';
import '../../../features/notifications/data/models/isar/isar_notification.dart';
import '../../../features/bank_accounts/data/models/isar/isar_bank_account.dart';
import '../../../features/suppliers/data/models/isar/isar_supplier.dart';
import '../../../features/purchase_orders/data/models/isar/isar_purchase_order.dart';
import '../../../features/purchase_orders/data/models/isar/isar_purchase_order_item.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_movement.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_batch.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_batch_movement.dart';
import '../../../features/settings/data/models/isar/isar_organization.dart';
import '../../../features/settings/data/models/isar/isar_user_preferences.dart';
import '../../../features/subscriptions/data/models/isar/isar_subscription.dart';
import '../../../features/settings/data/models/printer_settings_model.dart';

/// Interfaz abstracta para acceso a base de datos ISAR
///
/// Permite usar tanto la implementación real como mocks en tests
abstract class IIsarDatabase {
  /// Getter para la instancia de la base de datos
  /// Retorna dynamic para permitir tanto Isar real como MockIsar
  dynamic get database;
}

/// Singleton para manejar la base de datos ISAR
///
/// Maneja todas las colecciones de ISAR para datos offline-first
class IsarDatabase implements IIsarDatabase {
  static IsarDatabase? _instance;
  static Isar? _isar;

  IsarDatabase._();

  static IsarDatabase get instance {
    _instance ??= IsarDatabase._();
    return _instance!;
  }

  /// Getter para la instancia de ISAR
  @override
  Isar get database {
    if (_isar == null) {
      throw Exception(
        'ISAR database not initialized. Call initialize() first.',
      );
    }
    return _isar!;
  }

  /// Inicializar la base de datos ISAR
  Future<void> initialize() async {
    if (_isar != null) {
      print('💾 ISAR database already initialized');
      return;
    }

    try {
      print('💾 Inicializando base de datos ISAR...');

      // Obtener el directorio para la base de datos
      final dir = await getApplicationDocumentsDirectory();

      // Inicializar ISAR con todas las colecciones
      _isar = await Isar.open(
        [
          SyncOperationSchema,
          IsarIdempotencyRecordSchema, // ⭐ FASE 1: Idempotencia
          IsarCategorySchema,
          IsarCustomerSchema,
          IsarCustomerCreditSchema,
          IsarProductSchema,
          IsarExpenseSchema,
          IsarInvoiceSchema,
          IsarCreditNoteSchema,
          IsarNotificationSchema,
          IsarBankAccountSchema,
          IsarSupplierSchema,
          IsarPurchaseOrderSchema,
          IsarPurchaseOrderItemSchema,
          IsarInventoryMovementSchema,
          IsarInventoryBatchSchema,
          IsarInventoryBatchMovementSchema,
          IsarOrganizationSchema,
          IsarUserPreferencesSchema,
          IsarSubscriptionSchema,
          PrinterSettingsModelSchema,
        ],
        directory: dir.path,
        name: 'baudex_offline',
      );

      print('✅ Base de datos ISAR inicializada exitosamente');
      print('📍 Ubicación: ${dir.path}/baudex_business.isar');

      // Mostrar estadísticas iniciales
      final stats = await getStats();
      print('📊 Estadísticas iniciales: $stats');
    } catch (e) {
      print('❌ Error inicializando ISAR database: $e');
      rethrow;
    }
  }

  /// Cerrar la base de datos
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      print('💾 Base de datos ISAR cerrada exitosamente');
    }
    _instance = null;
  }

  /// Limpiar toda la base de datos
  Future<void> clear() async {
    if (_isar == null) return;

    await _isar!.writeTxn(() async {
      await _isar!.clear();
    });

    print('💾 Base de datos ISAR limpiada exitosamente');
  }

  /// Verificar si la base de datos está inicializada
  bool get isInitialized => _isar != null;

  /// Obtener estadísticas de la base de datos
  Future<Map<String, int>> getStats() async {
    if (_isar == null) {
      return {
        'syncOperations': 0,
        'categories': 0,
        'customers': 0,
        'products': 0,
        'expenses': 0,
        'invoices': 0,
        'creditNotes': 0,
        'notifications': 0,
        'bankAccounts': 0,
        'suppliers': 0,
        'inventoryMovements': 0,
        'inventoryBatches': 0,
        'inventoryBatchMovements': 0,
      };
    }

    try {
      return {
        'syncOperations': await _isar!.syncOperations.count(),
        'categories': await _isar!.isarCategorys.count(),
        'customers': await _isar!.isarCustomers.count(),
        'customerCredits': await _isar!.isarCustomerCredits.count(),
        'products': await _isar!.isarProducts.count(),
        'expenses': await _isar!.isarExpenses.count(),
        'invoices': await _isar!.isarInvoices.count(),
        'creditNotes': await _isar!.isarCreditNotes.count(),
        'notifications': await _isar!.isarNotifications.count(),
        'bankAccounts': await _isar!.isarBankAccounts.count(),
        'suppliers': await _isar!.isarSuppliers.count(),
        'purchaseOrders': await _isar!.isarPurchaseOrders.count(),
        'purchaseOrderItems': await _isar!.isarPurchaseOrderItems.count(),
        'inventoryMovements': await _isar!.isarInventoryMovements.count(),
        'inventoryBatches': await _isar!.isarInventoryBatchs.count(),
        'inventoryBatchMovements': await _isar!.isarInventoryBatchMovements.count(),
        'organizations': await _isar!.isarOrganizations.count(),
        'userPreferences': await _isar!.isarUserPreferences.count(),
        'subscriptions': await _isar!.isarSubscriptions.count(),
        'printerSettings': await _isar!.printerSettingsModels.count(),
      };
    } catch (e) {
      // Schema mismatch - return empty stats
      print('⚠️ Error obteniendo stats de ISAR (posible schema mismatch): $e');
      return {'error': -1};
    }
  }

  /// Backup de la base de datos
  Future<void> backup(String path) async {
    if (_isar == null) return;

    await _isar!.copyToFile(path);
    print('💾 Backup creado en: $path');
  }

  /// Obtener el tamaño de la base de datos en bytes
  Future<int> getDatabaseSize() async {
    if (_isar == null) return 0;

    return await _isar!.getSize();
  }

  /// Compactar la base de datos
  Future<void> compact() async {
    if (_isar == null) return;

    final sizeBefore = await getDatabaseSize();
    // ISAR auto-compacts, but we can trigger a manual compact by closing and reopening
    await close();
    await initialize();
    final sizeAfter = await getDatabaseSize();

    print('💾 Base de datos compactada: ${sizeBefore}B -> ${sizeAfter}B');
  }

  /// Verificar la integridad de la base de datos
  Future<bool> verifyIntegrity() async {
    if (_isar == null) return false;

    try {
      // Verificar que podemos leer de cada colección
      await _isar!.syncOperations.count();
      await _isar!.isarCategorys.count();
      await _isar!.isarCustomers.count();
      await _isar!.isarProducts.count();
      await _isar!.isarExpenses.count();
      await _isar!.isarInvoices.count();
      await _isar!.isarCreditNotes.count();
      await _isar!.isarNotifications.count();
      await _isar!.isarBankAccounts.count();
      await _isar!.isarSuppliers.count();
      await _isar!.isarPurchaseOrders.count();
      await _isar!.isarPurchaseOrderItems.count();
      await _isar!.isarInventoryMovements.count();
      await _isar!.isarInventoryBatchs.count();
      await _isar!.isarInventoryBatchMovements.count();
      await _isar!.isarOrganizations.count();
      await _isar!.isarUserPreferences.count();
      await _isar!.isarSubscriptions.count();
      await _isar!.printerSettingsModels.count();

      print('✅ Integridad de base de datos verificada');
      return true;
    } catch (e) {
      print('❌ Error en verificación de integridad: $e');
      return false;
    }
  }

  // ==================== SYNC QUEUE HELPERS ====================

  /// Obtener todas las operaciones pendientes
  Future<List<SyncOperation>> getPendingSyncOperations() async {
    if (_isar == null) return [];

    try {
      // Incluir TANTO operaciones pending COMO failed para reintentarlas
      return await _isar!.syncOperations
          .filter()
          .group((q) => q
              .statusEqualTo(SyncStatus.pending)
              .or()
              .statusEqualTo(SyncStatus.failed))
          .sortByPriority() // Mayor prioridad primero
          .thenByCreatedAt() // Luego por antigüedad
          .findAll();
    } catch (e) {
      // Schema mismatch - return empty list
      return [];
    }
  }

  /// Obtener operaciones pendientes por tipo de entidad
  Future<List<SyncOperation>> getPendingSyncOperationsByType(
    String entityType,
  ) async {
    if (_isar == null) return [];

    try {
      return await _isar!.syncOperations
          .filter()
          .entityTypeEqualTo(entityType)
          .and()
          .statusEqualTo(SyncStatus.pending)
          .sortByCreatedAt()
          .findAll();
    } catch (e) {
      return [];
    }
  }

  /// Agregar una operación a la cola de sincronización
  Future<void> addSyncOperation(SyncOperation operation) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        await _isar!.syncOperations.put(operation);
      });
      print('🔄 Operación agregada a cola: ${operation.entityType} ${operation.operationType.name}');
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
      print('⚠️ No se pudo agregar operación a cola sync: $e');
    }
  }

  /// Marcar una operación como completada
  Future<void> markSyncOperationCompleted(int operationId) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        final operation = await _isar!.syncOperations.get(operationId);
        if (operation != null) {
          operation.status = SyncStatus.completed;
          operation.syncedAt = DateTime.now();
          await _isar!.syncOperations.put(operation);
        }
      });
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
    }
  }

  /// Marcar una operación como fallida
  Future<void> markSyncOperationFailed(int operationId, String error) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        final operation = await _isar!.syncOperations.get(operationId);
        if (operation != null) {
          operation.status = SyncStatus.failed;
          operation.error = error;
          operation.retryCount++;
          await _isar!.syncOperations.put(operation);
        }
      });

      // NO imprimir errores de conexión NI errores 409 (son esperados)
      if (!error.contains('Connection refused') &&
          !error.contains('Connection error') &&
          !error.contains('Error de conexión') &&
          !error.contains('SocketException') &&
          !error.contains('Conflicto:') &&
          !error.contains('409')) {
        print('❌ Operación falló: ID $operationId, Error: $error');
      }
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
    }
  }

  /// Limpiar operaciones completadas antiguas (más de 7 días)
  Future<void> cleanOldSyncOperations() async {
    if (_isar == null) return;

    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      await _isar!.writeTxn(() async {
        final oldOperations = await _isar!.syncOperations
            .filter()
            .statusEqualTo(SyncStatus.completed)
            .and()
            .syncedAtLessThan(sevenDaysAgo)
            .findAll();

        final ids = oldOperations.map((op) => op.id).toList();
        await _isar!.syncOperations.deleteAll(ids);

        if (ids.isNotEmpty) {
          print('🧹 Limpiadas ${ids.length} operaciones antiguas');
        }
      });
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
    }
  }

  /// Eliminar una operación de sync específica por ID
  Future<void> deleteSyncOperation(int operationId) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        final deleted = await _isar!.syncOperations.delete(operationId);
        if (deleted) {
          print('🗑️ Operación de sync eliminada: ID $operationId');
        }
      });
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
    }
  }

  /// Eliminar operaciones de sync por entityId
  Future<void> deleteSyncOperationsByEntityId(String entityId) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        final operations = await _isar!.syncOperations
            .filter()
            .entityIdEqualTo(entityId)
            .findAll();

        final ids = operations.map((op) => op.id).toList();
        await _isar!.syncOperations.deleteAll(ids);

        if (ids.isNotEmpty) {
          print('🗑️ Eliminadas ${ids.length} operaciones de sync para entityId: $entityId');
        }
      });
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
    }
  }

  /// Actualizar el payload de una operación de sync
  Future<void> updateSyncOperationPayload(int operationId, String newPayload) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        final operation = await _isar!.syncOperations.get(operationId);
        if (operation != null) {
          operation.payload = newPayload;
          operation.updatedAt = DateTime.now();
          await _isar!.syncOperations.put(operation);
          print('✏️ Payload actualizado para operación ID $operationId');
        }
      });
    } catch (e) {
      print('⚠️ Error actualizando payload de operación $operationId: $e');
    }
  }

  /// Listar todas las operaciones de sync con detalles (para debugging)
  Future<void> listAllSyncOperations() async {
    if (_isar == null) return;

    try {
      final operations = await _isar!.syncOperations.where().findAll();

      print('📋 ==================== OPERACIONES DE SYNC ====================');
      print('📊 Total: ${operations.length}');
      print('');

      for (final op in operations) {
        print('🔄 ID: ${op.id}');
        print('   Entity: ${op.entityType} (${op.entityId})');
        print('   Operation: ${op.operationType.name}');
        print('   Status: ${op.status.name}');
        print('   Retries: ${op.retryCount}');
        if (op.error != null) {
          print('   Error: ${op.error}');
        }
        print('   Created: ${op.createdAt}');
        print('');
      }
      print('📋 ==================== FIN ====================');
    } catch (e) {
      print('⚠️ No se pudo listar operaciones sync: schema mismatch');
    }
  }

  /// Obtener conteo de operaciones por estado
  Future<Map<String, int>> getSyncOperationsCounts() async {
    if (_isar == null) {
      return {
        'pending': 0,
        'inProgress': 0,
        'completed': 0,
        'failed': 0,
      };
    }

    try {
      return {
        'pending': await _isar!.syncOperations
            .filter()
            .statusEqualTo(SyncStatus.pending)
            .count(),
        'inProgress': await _isar!.syncOperations
            .filter()
            .statusEqualTo(SyncStatus.inProgress)
            .count(),
        'completed': await _isar!.syncOperations
            .filter()
            .statusEqualTo(SyncStatus.completed)
            .count(),
        'failed': await _isar!.syncOperations
            .filter()
            .statusEqualTo(SyncStatus.failed)
            .count(),
      };
    } catch (e) {
      return {
        'pending': 0,
        'inProgress': 0,
        'completed': 0,
        'failed': 0,
      };
    }
  }

  /// Obtener operaciones fallidas para reintentar
  ///
  /// Retorna todas las operaciones con estado 'failed' ordenadas por
  /// antigüedad (las más antiguas primero)
  Future<List<SyncOperation>> getFailedSyncOperations() async {
    if (_isar == null) return [];

    try {
      return await _isar!.syncOperations
          .filter()
          .statusEqualTo(SyncStatus.failed)
          .sortByCreatedAt()
          .findAll();
    } catch (e) {
      return [];
    }
  }

  /// Marcar una operación como pending (para reintentar)
  ///
  /// Incrementa el contador de reintentos y actualiza el timestamp
  Future<void> markSyncOperationPending(int operationId) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        final operation = await _isar!.syncOperations.get(operationId);
        if (operation != null) {
          operation.status = SyncStatus.pending;
          operation.updatedAt = DateTime.now();
          operation.retryCount++;
          await _isar!.syncOperations.put(operation);
        }
      });
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
    }
  }

  /// Marcar una operación como en conflicto
  ///
  /// Útil para tracking de conflictos 409 del servidor
  Future<void> markSyncOperationConflict(int operationId, String conflictDetails) async {
    if (_isar == null) return;

    try {
      await _isar!.writeTxn(() async {
        final operation = await _isar!.syncOperations.get(operationId);
        if (operation != null) {
          operation.status = SyncStatus.failed;
          operation.error = 'CONFLICT_409: $conflictDetails';
          operation.updatedAt = DateTime.now();
          await _isar!.syncOperations.put(operation);
        }
      });

      print('⚠️ Operación marcada como conflicto: ID $operationId - $conflictDetails');
    } catch (e) {
      // Registrar error pero no propagar (puede ser schema mismatch temporal)
      AppLogger.w('Error en operación ISAR: $e', tag: 'ISAR');
    }
  }
}
