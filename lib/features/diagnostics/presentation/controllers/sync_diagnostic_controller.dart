// lib/features/diagnostics/presentation/controllers/sync_diagnostic_controller.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/full_sync_service.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_config.dart';
import '../../../../app/data/local/sync_event_log.dart';
import '../../../../app/data/local/sync_event_log_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/sync_service.dart';
// Modelos Isar — necesarios para que los getters generados (isar.isarProducts,
// isar.isarCustomers, etc.) estén disponibles en este archivo.
import '../../../../features/categories/data/models/isar/isar_category.dart';
import '../../../../features/customers/data/models/isar/isar_customer.dart';
import '../../../../features/expenses/data/models/isar/isar_expense.dart';
import '../../../../features/invoices/data/models/isar/isar_invoice.dart';
import '../../../../features/products/data/models/isar/isar_product.dart';
import '../../../../features/products/data/models/isar/isar_product_presentation.dart';
import '../../../../features/purchase_orders/data/models/isar/isar_purchase_order.dart';

/// Resumen de conteos de una entidad para mostrar en la pantalla de
/// diagnóstico.
class EntityCount {
  final String name;
  final String label;
  final int total;
  final int unsynced;
  final int offline;

  const EntityCount({
    required this.name,
    required this.label,
    required this.total,
    required this.unsynced,
    required this.offline,
  });

  bool get hasIssues => unsynced > 0 || offline > 0;
}

/// Resumen de operaciones pendientes en SyncQueue agrupadas.
class PendingOpsBreakdown {
  final int total;
  final int pending;
  final int failed;
  final int inProgress;
  final Map<String, int> byEntityType; // {Product: 3, Invoice: 1, ...}

  const PendingOpsBreakdown({
    required this.total,
    required this.pending,
    required this.failed,
    required this.inProgress,
    required this.byEntityType,
  });

  static const empty = PendingOpsBreakdown(
    total: 0,
    pending: 0,
    failed: 0,
    inProgress: 0,
    byEntityType: {},
  );
}

/// Controller del módulo de diagnóstico. Recopila estado del sistema
/// offline-first y expone acciones de mantenimiento.
class SyncDiagnosticController extends GetxController {
  // ==================== STATE ====================

  final RxBool isLoading = false.obs;
  final RxBool isOnline = false.obs;
  final Rxn<DateTime> lastFullSyncAt = Rxn<DateTime>();
  final RxInt pendingQueueOps = 0.obs;

  final RxList<EntityCount> entityCounts = <EntityCount>[].obs;
  final Rx<PendingOpsBreakdown> pendingBreakdown =
      PendingOpsBreakdown.empty.obs;
  final RxList<IsarSyncEventLog> recentEvents = <IsarSyncEventLog>[].obs;
  final Rx<Map<SyncEventSeverity, int>> eventCountsBySeverity =
      Rx<Map<SyncEventSeverity, int>>({});

  /// Mensaje de la última acción ejecutada (forzar resync, limpiar logs, etc.)
  /// para mostrar feedback al usuario en la UI.
  final RxnString lastActionMessage = RxnString();

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  // ==================== ACTIONS ====================

  /// Recarga TODOS los indicadores. Llamado desde onInit y desde el
  /// botón "Refrescar" de la pantalla.
  Future<void> refreshAll() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await Future.wait([
        _refreshConnectionState(),
        _refreshEntityCounts(),
        _refreshPendingQueue(),
        _refreshRecentEvents(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  /// Forzar una resincronización completa contra el servidor (PULL).
  /// Solo tiene sentido si hay conexión.
  Future<void> forceFullSync() async {
    if (!Get.isRegistered<FullSyncService>()) {
      lastActionMessage.value =
          'Servicio de sincronización no disponible';
      return;
    }
    if (!isOnline.value) {
      lastActionMessage.value =
          'Sin conexión — no se puede forzar sync ahora';
      return;
    }
    isLoading.value = true;
    try {
      final fullSync = Get.find<FullSyncService>();
      final result = await fullSync.performFullSync();
      lastActionMessage.value =
          'Sincronización completa terminada en ${result.duration.inSeconds}s';
      await refreshAll();
    } catch (e) {
      lastActionMessage.value = 'Error en sincronización: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Borra operaciones del SyncQueue marcadas como `failed` con más de
  /// `maxRetries` intentos. Útil para que el usuario destrabe ops que
  /// nunca van a recuperarse (ej: una entidad relacionada borrada).
  Future<int> cleanFailedOperations() async {
    try {
      final isar = IsarDatabase.instance.database;
      final failedOps = await isar.syncOperations
          .filter()
          .statusEqualTo(SyncStatus.failed)
          .retryCountGreaterThan(SyncConfig.maxRetries - 1)
          .findAll();
      if (failedOps.isEmpty) {
        lastActionMessage.value = 'No hay operaciones fallidas para limpiar';
        return 0;
      }
      await isar.writeTxn(() async {
        await isar.syncOperations
            .deleteAll(failedOps.map((o) => o.id).toList());
      });
      lastActionMessage.value =
          'Se eliminaron ${failedOps.length} operaciones fallidas';
      await refreshAll();
      return failedOps.length;
    } catch (e) {
      lastActionMessage.value = 'Error limpiando fallidas: $e';
      return 0;
    }
  }

  /// Reintenta inmediatamente todas las operaciones marcadas como `failed`.
  /// Útil cuando el usuario sabe que ya volvió la red y no quiere esperar
  /// al backoff exponencial.
  Future<void> retryFailedOperations() async {
    try {
      final isar = IsarDatabase.instance.database;
      final failedOps = await isar.syncOperations
          .filter()
          .statusEqualTo(SyncStatus.failed)
          .findAll();
      if (failedOps.isEmpty) {
        lastActionMessage.value = 'No hay operaciones fallidas para reintentar';
        return;
      }
      await isar.writeTxn(() async {
        for (final op in failedOps) {
          op.status = SyncStatus.pending;
          op.retryCount = 0;
          op.error = null;
          op.updatedAt = DateTime.now();
          await isar.syncOperations.put(op);
        }
      });
      lastActionMessage.value =
          '${failedOps.length} operaciones reencoladas para reintento';

      // Disparar sync si hay red
      if (isOnline.value && Get.isRegistered<SyncService>()) {
        unawaited(Get.find<SyncService>().forceSyncNow());
      }
      await refreshAll();
    } catch (e) {
      lastActionMessage.value = 'Error reintentando fallidas: $e';
    }
  }

  /// Borra eventos del log más viejos que `days` días.
  Future<int> pruneOldEvents({int days = 30}) async {
    try {
      if (!Get.isRegistered<SyncEventLogService>()) return 0;
      final svc = Get.find<SyncEventLogService>();
      final cutoff = DateTime.now()
          .toUtc()
          .subtract(Duration(days: days));
      final pruned = await svc.pruneOlderThan(cutoff);
      lastActionMessage.value =
          'Se eliminaron $pruned eventos antiguos del log';
      await _refreshRecentEvents();
      return pruned;
    } catch (e) {
      lastActionMessage.value = 'Error limpiando logs: $e';
      return 0;
    }
  }

  /// Genera un texto exportable del estado del sistema para soporte.
  String exportDiagnosticReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Reporte de diagnóstico Baudex ===');
    buffer.writeln('Generado: ${DateTime.now().toUtc().toIso8601String()}');
    buffer.writeln('Conectividad: ${isOnline.value ? "ONLINE" : "OFFLINE"}');
    buffer.writeln('Operaciones en cola: ${pendingQueueOps.value}');
    buffer.writeln('  - pending:    ${pendingBreakdown.value.pending}');
    buffer.writeln('  - failed:     ${pendingBreakdown.value.failed}');
    buffer.writeln('  - inProgress: ${pendingBreakdown.value.inProgress}');
    buffer.writeln();
    buffer.writeln('Por entityType:');
    pendingBreakdown.value.byEntityType.forEach((type, count) {
      buffer.writeln('  $type: $count');
    });
    buffer.writeln();
    buffer.writeln('Conteos locales por entidad:');
    for (final ec in entityCounts) {
      buffer.write('  ${ec.label}: ${ec.total}');
      if (ec.unsynced > 0) buffer.write(' (sin sync: ${ec.unsynced})');
      if (ec.offline > 0) buffer.write(' (con id temp: ${ec.offline})');
      buffer.writeln();
    }
    buffer.writeln();
    buffer.writeln('Eventos recientes (últimos ${recentEvents.length}):');
    for (final ev in recentEvents) {
      buffer.writeln(
        '  [${ev.timestamp.toIso8601String()}] '
        '${ev.severity.name.toUpperCase()} '
        '${ev.eventType.name} ${ev.entityType} '
        '${ev.operation} — ${ev.message}'
        '${ev.details != null ? "\n    detalle: ${ev.details}" : ""}',
      );
    }
    return buffer.toString();
  }

  // ==================== INTERNALS ====================

  Future<void> _refreshConnectionState() async {
    try {
      if (Get.isRegistered<SyncService>()) {
        isOnline.value = Get.find<SyncService>().isOnline;
      }
    } catch (_) {}
  }

  Future<void> _refreshEntityCounts() async {
    try {
      final isar = IsarDatabase.instance.database;
      final results = <EntityCount>[];

      // Productos
      final productsTotal = await isar.isarProducts.count();
      final productsUnsynced =
          await isar.isarProducts.filter().isSyncedEqualTo(false).count();
      final productsOffline = await isar.isarProducts
          .filter()
          .serverIdStartsWith('product_offline_')
          .count();
      results.add(EntityCount(
        name: 'product',
        label: 'Productos',
        total: productsTotal,
        unsynced: productsUnsynced,
        offline: productsOffline,
      ));

      // Clientes
      final customersTotal = await isar.isarCustomers.count();
      final customersOffline = await isar.isarCustomers
          .filter()
          .serverIdStartsWith('customer_')
          .count();
      results.add(EntityCount(
        name: 'customer',
        label: 'Clientes',
        total: customersTotal,
        unsynced: 0,
        offline: customersOffline,
      ));

      // Categorías
      final categoriesTotal = await isar.isarCategorys.count();
      final categoriesOffline = await isar.isarCategorys
          .filter()
          .serverIdStartsWith('category_offline_')
          .count();
      results.add(EntityCount(
        name: 'category',
        label: 'Categorías',
        total: categoriesTotal,
        unsynced: 0,
        offline: categoriesOffline,
      ));

      // Facturas
      final invoicesTotal = await isar.isarInvoices.count();
      final invoicesOffline = await isar.isarInvoices
          .filter()
          .serverIdStartsWith('invoice_offline_')
          .or()
          .serverIdStartsWith('inv_')
          .count();
      results.add(EntityCount(
        name: 'invoice',
        label: 'Facturas',
        total: invoicesTotal,
        unsynced: 0,
        offline: invoicesOffline,
      ));

      // Gastos
      final expensesTotal = await isar.isarExpenses.count();
      final expensesOffline = await isar.isarExpenses
          .filter()
          .serverIdStartsWith('expense_offline_')
          .count();
      results.add(EntityCount(
        name: 'expense',
        label: 'Gastos',
        total: expensesTotal,
        unsynced: 0,
        offline: expensesOffline,
      ));

      // Órdenes de compra
      final posTotal = await isar.isarPurchaseOrders.count();
      final posOffline = await isar.isarPurchaseOrders
          .filter()
          .serverIdStartsWith('po_offline_')
          .count();
      results.add(EntityCount(
        name: 'purchase_order',
        label: 'Órdenes de compra',
        total: posTotal,
        unsynced: 0,
        offline: posOffline,
      ));

      // Presentaciones
      final presentTotal = await isar.isarProductPresentations.count();
      final presentUnsynced = await isar.isarProductPresentations
          .filter()
          .isSyncedEqualTo(false)
          .count();
      final presentOffline = await isar.isarProductPresentations
          .filter()
          .serverIdStartsWith('presentation_offline_')
          .count();
      results.add(EntityCount(
        name: 'presentation',
        label: 'Presentaciones',
        total: presentTotal,
        unsynced: presentUnsynced,
        offline: presentOffline,
      ));

      entityCounts.value = results;
    } catch (e) {
      AppLogger.w('Error contando entidades: $e', tag: 'DIAGNOSTIC');
    }
  }

  Future<void> _refreshPendingQueue() async {
    try {
      final isar = IsarDatabase.instance.database;
      final allOps = await isar.syncOperations.where().findAll();

      int pending = 0;
      int failed = 0;
      int inProgress = 0;
      final byEntityType = <String, int>{};

      for (final op in allOps) {
        switch (op.status) {
          case SyncStatus.pending:
            pending++;
            break;
          case SyncStatus.failed:
            failed++;
            break;
          case SyncStatus.inProgress:
            inProgress++;
            break;
          case SyncStatus.completed:
            continue; // no contar completed
        }
        byEntityType[op.entityType] =
            (byEntityType[op.entityType] ?? 0) + 1;
      }

      pendingQueueOps.value = pending + failed + inProgress;
      pendingBreakdown.value = PendingOpsBreakdown(
        total: pending + failed + inProgress,
        pending: pending,
        failed: failed,
        inProgress: inProgress,
        byEntityType: byEntityType,
      );
    } catch (e) {
      AppLogger.w('Error leyendo SyncQueue: $e', tag: 'DIAGNOSTIC');
    }
  }

  Future<void> _refreshRecentEvents() async {
    try {
      if (!Get.isRegistered<SyncEventLogService>()) return;
      final svc = Get.find<SyncEventLogService>();
      final events = await svc.getRecent(limit: 100);
      recentEvents.value = events;
      eventCountsBySeverity.value = await svc.countBySeverity();
    } catch (e) {
      AppLogger.w('Error leyendo logs de diagnóstico: $e', tag: 'DIAGNOSTIC');
    }
  }
}

void unawaited(Future<void> future) {
  // ignore: avoid_returning_null_for_void
}
