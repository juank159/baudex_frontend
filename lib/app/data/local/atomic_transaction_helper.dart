// lib/app/data/local/atomic_transaction_helper.dart
import 'package:isar/isar.dart';
import 'isar_database.dart';
import '../../core/utils/app_logger.dart';

/// Helper para ejecutar transacciones atómicas en ISAR
///
/// Garantiza que múltiples operaciones se ejecuten de forma atómica:
/// - Si una falla, todas se revierten
/// - Logs detallados de cada paso
/// - Soporte para rollback manual
class AtomicTransactionHelper {
  final IsarDatabase _database;

  AtomicTransactionHelper({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  /// Ejecuta una transacción atómica con múltiples operaciones
  ///
  /// [operations] Lista de funciones a ejecutar dentro de la transacción
  /// [description] Descripción para logging
  ///
  /// Retorna `true` si todas las operaciones fueron exitosas
  Future<bool> executeAtomic({
    required List<Future<void> Function()> operations,
    required String description,
  }) async {
    AppLogger.d('🔄 Iniciando transacción atómica: $description', tag: 'TX');

    try {
      await _isar.writeTxn(() async {
        for (int i = 0; i < operations.length; i++) {
          try {
            AppLogger.d('  ↳ Ejecutando operación ${i + 1}/${operations.length}', tag: 'TX');
            await operations[i]();
          } catch (e) {
            AppLogger.e('  ✖ Error en operación ${i + 1}: $e', tag: 'TX');
            rethrow; // Esto causará rollback automático
          }
        }
      });

      AppLogger.i('✅ Transacción completada: $description', tag: 'TX');
      return true;
    } catch (e) {
      AppLogger.e('❌ Transacción fallida (rollback automático): $description - $e', tag: 'TX');
      return false;
    }
  }

  /// Ejecuta una transacción con valor de retorno
  ///
  /// Útil cuando necesitas retornar datos creados en la transacción
  Future<T?> executeAtomicWithResult<T>({
    required Future<T> Function() operation,
    required String description,
  }) async {
    AppLogger.d('🔄 Iniciando transacción con resultado: $description', tag: 'TX');

    try {
      final result = await _isar.writeTxn(() async {
        return await operation();
      });

      AppLogger.i('✅ Transacción completada: $description', tag: 'TX');
      return result;
    } catch (e) {
      AppLogger.e('❌ Transacción fallida: $description - $e', tag: 'TX');
      return null;
    }
  }

  /// Crea una factura con sus ítems de forma atómica
  ///
  /// Ejemplo de uso de transacción atómica para operación compuesta
  Future<bool> createInvoiceWithItemsAtomic({
    required Future<void> Function() createInvoice,
    required List<Future<void> Function()> createItems,
    required Future<void> Function() updateInventory,
    String? invoiceNumber,
  }) async {
    final description = 'Crear factura ${invoiceNumber ?? "nueva"} con ${createItems.length} ítems';

    final operations = <Future<void> Function()>[
      createInvoice,
      ...createItems,
      updateInventory,
    ];

    return executeAtomic(
      operations: operations,
      description: description,
    );
  }

  /// Crea una orden de compra con sus ítems de forma atómica
  Future<bool> createPurchaseOrderWithItemsAtomic({
    required Future<void> Function() createOrder,
    required List<Future<void> Function()> createItems,
    String? orderNumber,
  }) async {
    final description = 'Crear orden de compra ${orderNumber ?? "nueva"} con ${createItems.length} ítems';

    final operations = <Future<void> Function()>[
      createOrder,
      ...createItems,
    ];

    return executeAtomic(
      operations: operations,
      description: description,
    );
  }

  /// Ejecuta un movimiento de inventario de forma atómica
  ///
  /// Incluye: crear movimiento, actualizar stock, actualizar lotes
  Future<bool> executeInventoryMovementAtomic({
    required Future<void> Function() createMovement,
    required Future<void> Function() updateProductStock,
    Future<void> Function()? updateBatch,
    String? movementType,
  }) async {
    final description = 'Movimiento de inventario: ${movementType ?? "general"}';

    final operations = <Future<void> Function()>[
      createMovement,
      updateProductStock,
      if (updateBatch != null) updateBatch,
    ];

    return executeAtomic(
      operations: operations,
      description: description,
    );
  }

  /// Aplica un crédito a una factura de forma atómica
  ///
  /// Incluye: crear crédito, actualizar factura, actualizar balance cliente
  Future<bool> applyCreditToInvoiceAtomic({
    required Future<void> Function() createCredit,
    required Future<void> Function() updateInvoice,
    required Future<void> Function() updateCustomerBalance,
    String? creditId,
  }) async {
    final description = 'Aplicar crédito ${creditId ?? "nuevo"} a factura';

    return executeAtomic(
      operations: [
        createCredit,
        updateInvoice,
        updateCustomerBalance,
      ],
      description: description,
    );
  }

  /// Crea una nota de crédito de forma atómica
  ///
  /// Incluye: crear nota, ajustar factura original, actualizar inventario
  Future<bool> createCreditNoteAtomic({
    required Future<void> Function() createNote,
    required Future<void> Function() adjustOriginalInvoice,
    Future<void> Function()? updateInventory,
    String? noteNumber,
  }) async {
    final description = 'Crear nota de crédito ${noteNumber ?? "nueva"}';

    final operations = <Future<void> Function()>[
      createNote,
      adjustOriginalInvoice,
      if (updateInventory != null) updateInventory,
    ];

    return executeAtomic(
      operations: operations,
      description: description,
    );
  }

  /// Sincroniza múltiples entidades de forma atómica
  ///
  /// Útil para sincronización por lotes desde el servidor
  Future<bool> syncBatchAtomic({
    required List<Future<void> Function()> syncOperations,
    required String entityType,
    int batchSize = 0,
  }) async {
    final description = 'Sincronizar ${batchSize > 0 ? batchSize : syncOperations.length} $entityType';

    return executeAtomic(
      operations: syncOperations,
      description: description,
    );
  }

  /// Elimina múltiples entidades de forma atómica (soft delete)
  Future<bool> softDeleteBatchAtomic({
    required List<Future<void> Function()> deleteOperations,
    required String entityType,
  }) async {
    final description = 'Eliminar ${deleteOperations.length} $entityType (soft delete)';

    return executeAtomic(
      operations: deleteOperations,
      description: description,
    );
  }

  /// Ejecuta una operación con retry automático
  ///
  /// [maxRetries] Número máximo de reintentos
  /// [delayBetweenRetries] Tiempo entre reintentos en millisegundos
  Future<bool> executeWithRetry({
    required Future<bool> Function() operation,
    required String description,
    int maxRetries = 3,
    int delayBetweenRetries = 100,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await operation();
        if (result) {
          if (attempt > 1) {
            AppLogger.i('✅ Operación exitosa después de $attempt intentos: $description', tag: 'TX');
          }
          return true;
        }
      } catch (e) {
        AppLogger.w('⚠️ Intento $attempt/$maxRetries falló: $description - $e', tag: 'TX');
      }

      if (attempt < maxRetries) {
        await Future.delayed(Duration(milliseconds: delayBetweenRetries * attempt));
      }
    }

    AppLogger.e('❌ Operación falló después de $maxRetries intentos: $description', tag: 'TX');
    return false;
  }
}
