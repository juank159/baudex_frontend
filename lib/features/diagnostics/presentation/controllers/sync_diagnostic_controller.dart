// lib/features/diagnostics/presentation/controllers/sync_diagnostic_controller.dart
import 'dart:async';

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
import '../../../../features/bank_accounts/data/models/isar/isar_bank_account.dart';
import '../../../../features/categories/data/models/isar/isar_category.dart';
import '../../../../features/credit_notes/data/models/isar/isar_credit_note.dart';
import '../../../../features/customer_credits/data/models/isar/isar_customer_credit.dart';
import '../../../../features/customers/data/models/isar/isar_customer.dart';
import '../../../../features/expenses/data/models/isar/isar_expense.dart';
import '../../../../features/invoices/data/models/isar/isar_invoice.dart';
import '../../../../features/products/data/models/isar/isar_product.dart';
import '../../../../features/products/data/models/isar/isar_product_presentation.dart';
import '../../../../features/purchase_orders/data/models/isar/isar_purchase_order.dart';
import '../../../../features/suppliers/data/models/isar/isar_supplier.dart';

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

/// Registro local "huérfano" — existe en ISAR con `isSynced=false` y/o
/// id temporal pero NO tiene una operación activa en `SyncQueue`. Esto suele
/// pasar cuando una versión vieja del sync silenciaba errores HTTP 400 y
/// marcaba la operación como completed sin haber subido los datos al backend.
class OrphanedRecord {
  /// Tipo de entidad ('Customer', 'Invoice', 'Product', etc.) — coincide con
  /// los entityType que acepta `SyncQueue`.
  final String entityType;

  /// `serverId` actual en ISAR (típicamente un id temporal como
  /// `customer_offline_xxx`).
  final String entityId;

  /// Etiqueta legible para mostrar en la UI ("Ingrid Diaz", "INV-000123").
  final String label;

  /// Cuándo se creó el registro local. Útil para que el usuario decida si
  /// recuperarlo o descartarlo.
  final DateTime createdAt;

  /// Si es `true`, el controller sabe reconstruir el payload desde ISAR y
  /// puede re-encolar la operación automáticamente. Si es `false`, el
  /// usuario sólo puede eliminar el registro huérfano.
  final bool canAutoRequeue;

  const OrphanedRecord({
    required this.entityType,
    required this.entityId,
    required this.label,
    required this.createdAt,
    required this.canAutoRequeue,
  });
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
  final RxList<OrphanedRecord> orphanedRecords = <OrphanedRecord>[].obs;
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
      // Detección de huérfanos depende del estado del SyncQueue, así que se
      // ejecuta DESPUÉS de _refreshPendingQueue.
      await _refreshOrphanedRecords();
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

  // ==================== ORPHAN DETECTION & RECOVERY ====================

  /// Escanea ISAR buscando registros con `serverId` temporal (creados offline)
  /// que NO tienen una operación activa en `SyncQueue`. Estos son huérfanos
  /// que deberían sincronizarse pero la operación se perdió (típicamente por
  /// el bug de validación silenciosa anterior).
  Future<void> _refreshOrphanedRecords() async {
    try {
      final isar = IsarDatabase.instance.database;

      // 1. Indexar todas las ops activas (no completed) por (entityType, entityId)
      //    para chequeo O(1).
      final allOps = await isar.syncOperations.where().findAll();
      final activeOps = <String>{};
      for (final op in allOps) {
        if (op.status == SyncStatus.completed) continue;
        activeOps.add('${op.entityType}::${op.entityId}');
      }

      final orphans = <OrphanedRecord>[];

      // 2. Customers con id temporal sin op activa → recuperables
      final customers = await isar.isarCustomers
          .filter()
          .serverIdStartsWith('customer_')
          .findAll();
      for (final c in customers) {
        if (activeOps.contains('Customer::${c.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'Customer',
          entityId: c.serverId,
          label: '${c.firstName} ${c.lastName}'.trim(),
          createdAt: c.createdAt,
          canAutoRequeue: true,
        ));
      }

      // 3. Invoices con id temporal sin op activa → NO recuperables
      //    (el payload completo con items + payments + metadata es complejo
      //    de reconstruir desde ISAR). El usuario las puede eliminar.
      final invoices = await isar.isarInvoices
          .filter()
          .serverIdStartsWith('invoice_offline_')
          .or()
          .serverIdStartsWith('inv_')
          .findAll();
      for (final inv in invoices) {
        if (activeOps.contains('Invoice::${inv.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'Invoice',
          entityId: inv.serverId,
          label: 'Factura ${inv.number}',
          createdAt: inv.createdAt,
          canAutoRequeue: false,
        ));
      }

      // 4. Productos offline sin op activa → recuperables
      final products = await isar.isarProducts
          .filter()
          .serverIdStartsWith('product_offline_')
          .findAll();
      for (final p in products) {
        if (activeOps.contains('Product::${p.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'Product',
          entityId: p.serverId,
          label: p.name,
          createdAt: p.createdAt,
          canAutoRequeue: true,
        ));
      }

      // 5. Categorías offline sin op activa → recuperables
      final categories = await isar.isarCategorys
          .filter()
          .serverIdStartsWith('category_offline_')
          .findAll();
      for (final cat in categories) {
        if (activeOps.contains('Category::${cat.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'Category',
          entityId: cat.serverId,
          label: cat.name,
          createdAt: cat.createdAt,
          canAutoRequeue: true,
        ));
      }

      // 6. Suppliers offline sin op activa → recuperables
      final suppliers = await isar.isarSuppliers
          .filter()
          .serverIdStartsWith('supplier_')
          .findAll();
      for (final s in suppliers) {
        if (activeOps.contains('Supplier::${s.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'Supplier',
          entityId: s.serverId,
          label: s.name,
          createdAt: s.createdAt,
          canAutoRequeue: true,
        ));
      }

      // 7. Expenses offline sin op activa → recuperables
      final expenses = await isar.isarExpenses
          .filter()
          .serverIdStartsWith('expense_offline_')
          .findAll();
      for (final ex in expenses) {
        if (activeOps.contains('Expense::${ex.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'Expense',
          entityId: ex.serverId,
          label: '${ex.description} (\$${ex.amount.toStringAsFixed(0)})',
          createdAt: ex.createdAt,
          canAutoRequeue: true,
        ));
      }

      // 8. Bank accounts offline sin op activa → recuperables
      final banks = await isar.isarBankAccounts
          .filter()
          .serverIdStartsWith('bank_')
          .findAll();
      for (final b in banks) {
        if (activeOps.contains('BankAccount::${b.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'BankAccount',
          entityId: b.serverId,
          label: b.name,
          createdAt: b.createdAt,
          canAutoRequeue: true,
        ));
      }

      // 9. Customer credits offline sin op activa → recuperables (parcial)
      final credits = await isar.isarCustomerCredits
          .filter()
          .serverIdStartsWith('customercredit_offline_')
          .findAll();
      for (final cr in credits) {
        if (activeOps.contains('CustomerCredit::${cr.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'CustomerCredit',
          entityId: cr.serverId,
          label:
              'Crédito \$${cr.originalAmount.toStringAsFixed(0)} (${cr.customerName ?? "cliente"})',
          createdAt: cr.createdAt,
          canAutoRequeue: true,
        ));
      }

      // 10. Purchase orders offline sin op activa → solo eliminación
      final pos = await isar.isarPurchaseOrders
          .filter()
          .serverIdStartsWith('po_offline_')
          .findAll();
      for (final po in pos) {
        if (activeOps.contains('PurchaseOrder::${po.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'PurchaseOrder',
          entityId: po.serverId,
          label: 'OC ${po.orderNumber ?? po.serverId}',
          createdAt: po.orderDate ?? DateTime.now(),
          canAutoRequeue: false,
        ));
      }

      // 11. Credit notes offline sin op activa → solo eliminación
      final cnotes = await isar.isarCreditNotes
          .filter()
          .serverIdStartsWith('creditnote_offline_')
          .findAll();
      for (final cn in cnotes) {
        if (activeOps.contains('CreditNote::${cn.serverId}')) continue;
        orphans.add(OrphanedRecord(
          entityType: 'CreditNote',
          entityId: cn.serverId,
          label: 'NC ${cn.number}',
          createdAt: cn.date,
          canAutoRequeue: false,
        ));
      }

      // Ordenar por fecha desc (más recientes primero)
      orphans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      orphanedRecords.value = orphans;
    } catch (e) {
      AppLogger.w('Error detectando huérfanos: $e', tag: 'DIAGNOSTIC');
    }
  }

  /// Re-encola UN huérfano específico reconstruyendo el payload desde ISAR.
  /// Devuelve true si se logró, false si el tipo no soporta auto-recuperación.
  Future<bool> requeueOrphan(OrphanedRecord orphan) async {
    if (!orphan.canAutoRequeue) {
      lastActionMessage.value =
          '${orphan.entityType} no soporta recuperación automática — eliminar manualmente';
      return false;
    }
    if (!Get.isRegistered<SyncService>()) {
      lastActionMessage.value = 'SyncService no disponible';
      return false;
    }
    try {
      final ok = await _requeueByType(orphan);
      if (ok) {
        lastActionMessage.value =
            'Huérfano reencolado: ${orphan.label} (${orphan.entityType})';
        await refreshAll();
      } else {
        lastActionMessage.value =
            'No se pudo reencolar ${orphan.label} — registro no encontrado';
      }
      return ok;
    } catch (e) {
      lastActionMessage.value = 'Error reencolando ${orphan.label}: $e';
      return false;
    }
  }

  /// Re-encola TODOS los huérfanos recuperables. Útil cuando el usuario
  /// quiere recuperar todo de una sola vez.
  Future<int> requeueAllOrphans() async {
    if (!Get.isRegistered<SyncService>()) {
      lastActionMessage.value = 'SyncService no disponible';
      return 0;
    }
    int recovered = 0;
    int skipped = 0;
    for (final orphan in List<OrphanedRecord>.from(orphanedRecords)) {
      if (!orphan.canAutoRequeue) {
        skipped++;
        continue;
      }
      try {
        final ok = await _requeueByType(orphan);
        if (ok) recovered++;
      } catch (e) {
        AppLogger.w(
          'Error reencolando ${orphan.entityType}/${orphan.entityId}: $e',
          tag: 'DIAGNOSTIC',
        );
      }
    }
    final parts = <String>[];
    parts.add('$recovered registros reencolados');
    if (skipped > 0) parts.add('$skipped requieren acción manual');
    lastActionMessage.value = parts.join(' · ');
    await refreshAll();
    if (recovered > 0 && isOnline.value) {
      unawaited(Get.find<SyncService>().forceSyncNow());
    }
    return recovered;
  }

  /// Elimina un huérfano de ISAR sin intentar sincronizarlo. Solo para
  /// registros que el usuario sabe que ya no necesita.
  Future<bool> deleteOrphan(OrphanedRecord orphan) async {
    try {
      final isar = IsarDatabase.instance.database;
      bool deleted = false;
      await isar.writeTxn(() async {
        switch (orphan.entityType) {
          case 'Customer':
            final c = await isar.isarCustomers
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (c != null) {
              deleted = await isar.isarCustomers.delete(c.id);
            }
            break;
          case 'Invoice':
            final inv = await isar.isarInvoices
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (inv != null) {
              deleted = await isar.isarInvoices.delete(inv.id);
            }
            break;
          case 'Product':
            final p = await isar.isarProducts
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (p != null) {
              deleted = await isar.isarProducts.delete(p.id);
            }
            break;
          case 'Category':
            final cat = await isar.isarCategorys
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (cat != null) {
              deleted = await isar.isarCategorys.delete(cat.id);
            }
            break;
          case 'Supplier':
            final s = await isar.isarSuppliers
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (s != null) {
              deleted = await isar.isarSuppliers.delete(s.id);
            }
            break;
          case 'Expense':
            final ex = await isar.isarExpenses
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (ex != null) {
              deleted = await isar.isarExpenses.delete(ex.id);
            }
            break;
          case 'BankAccount':
            final b = await isar.isarBankAccounts
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (b != null) {
              deleted = await isar.isarBankAccounts.delete(b.id);
            }
            break;
          case 'CustomerCredit':
            final cr = await isar.isarCustomerCredits
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (cr != null) {
              deleted = await isar.isarCustomerCredits.delete(cr.id);
            }
            break;
          case 'PurchaseOrder':
            final po = await isar.isarPurchaseOrders
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (po != null) {
              deleted = await isar.isarPurchaseOrders.delete(po.id);
            }
            break;
          case 'CreditNote':
            final cn = await isar.isarCreditNotes
                .filter()
                .serverIdEqualTo(orphan.entityId)
                .findFirst();
            if (cn != null) {
              deleted = await isar.isarCreditNotes.delete(cn.id);
            }
            break;
        }
      });
      if (deleted) {
        lastActionMessage.value = 'Eliminado: ${orphan.label}';
        await refreshAll();
      } else {
        lastActionMessage.value = 'No encontrado: ${orphan.label}';
      }
      return deleted;
    } catch (e) {
      lastActionMessage.value = 'Error eliminando ${orphan.label}: $e';
      return false;
    }
  }

  /// Reconstruye el payload de cada tipo soportado y lo agrega a SyncQueue.
  Future<bool> _requeueByType(OrphanedRecord orphan) async {
    final isar = IsarDatabase.instance.database;
    final sync = Get.find<SyncService>();

    switch (orphan.entityType) {
      case 'Customer':
        final c = await isar.isarCustomers
            .filter()
            .serverIdEqualTo(orphan.entityId)
            .findFirst();
        if (c == null) return false;
        await sync.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: c.serverId,
          operationType: SyncOperationType.create,
          data: {
            'firstName': c.firstName,
            'lastName': c.lastName,
            'companyName': c.companyName,
            'email': c.email,
            'phone': c.phone,
            'mobile': c.mobile,
            'documentType': c.documentType.name,
            'documentNumber': c.documentNumber,
            'address': c.address,
            'city': c.city,
            'state': c.state,
            'zipCode': c.zipCode,
            'country': c.country,
            'status': c.status.name,
            'creditLimit': c.creditLimit,
            'paymentTerms': c.paymentTerms,
            'birthDate': c.birthDate?.toIso8601String(),
            'notes': c.notes,
          },
          priority: 1,
        );
        return true;

      case 'Product':
        final p = await isar.isarProducts
            .filter()
            .serverIdEqualTo(orphan.entityId)
            .findFirst();
        if (p == null) return false;
        await sync.addOperationForCurrentUser(
          entityType: 'Product',
          entityId: p.serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': p.name,
            'description': p.description,
            'sku': p.sku,
            'barcode': p.barcode,
            'type': p.type.name,
            'status': p.status.name,
            'stock': p.stock,
            'minStock': p.minStock,
            'unit': p.unit,
            'categoryId': p.categoryId,
          },
          priority: 1,
        );
        return true;

      case 'Category':
        final cat = await isar.isarCategorys
            .filter()
            .serverIdEqualTo(orphan.entityId)
            .findFirst();
        if (cat == null) return false;
        await sync.addOperationForCurrentUser(
          entityType: 'Category',
          entityId: cat.serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': cat.name,
            'description': cat.description,
            'slug': cat.slug,
            'parentId': cat.parentId,
            'status': cat.status.name,
            'sortOrder': cat.sortOrder,
          },
          priority: 1,
        );
        return true;

      case 'Supplier':
        final s = await isar.isarSuppliers
            .filter()
            .serverIdEqualTo(orphan.entityId)
            .findFirst();
        if (s == null) return false;
        await sync.addOperationForCurrentUser(
          entityType: 'Supplier',
          entityId: s.serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': s.name,
            'code': s.code,
            'documentType': s.documentType.name,
            'documentNumber': s.documentNumber,
            'contactPerson': s.contactPerson,
            'email': s.email,
            'phone': s.phone,
            'status': s.status.name,
            'currency': s.currency,
          },
          priority: 1,
        );
        return true;

      case 'Expense':
        final ex = await isar.isarExpenses
            .filter()
            .serverIdEqualTo(orphan.entityId)
            .findFirst();
        if (ex == null) return false;
        // Formato YYYY-MM-DD para coincidir con el handler que envía la fecha
        // como string a backend.
        final d = ex.date;
        final dateStr =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        await sync.addOperationForCurrentUser(
          entityType: 'Expense',
          entityId: ex.serverId,
          operationType: SyncOperationType.create,
          data: {
            'description': ex.description,
            'amount': ex.amount,
            'date': dateStr,
            'categoryId': ex.categoryId,
            'type': ex.type.name,
            'paymentMethod': ex.paymentMethod.name,
            'status': ex.status.name,
          },
          priority: 1,
        );
        return true;

      case 'BankAccount':
        final b = await isar.isarBankAccounts
            .filter()
            .serverIdEqualTo(orphan.entityId)
            .findFirst();
        if (b == null) return false;
        await sync.addOperationForCurrentUser(
          entityType: 'BankAccount',
          entityId: b.serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': b.name,
            'type': b.type.name,
            'bankName': b.bankName,
            'accountNumber': b.accountNumber,
            'holderName': b.holderName,
            'icon': b.icon,
            'isActive': b.isActive,
            'isDefault': b.isDefault,
            'sortOrder': b.sortOrder,
            'description': b.description,
          },
          priority: 1,
        );
        return true;

      case 'CustomerCredit':
        final cr = await isar.isarCustomerCredits
            .filter()
            .serverIdEqualTo(orphan.entityId)
            .findFirst();
        if (cr == null) return false;
        // El customerId del crédito puede ser un id temporal si el cliente
        // todavía no se sincronizó: en ese caso el handler de sync detecta
        // y reintenta cuando el cliente tenga UUID real.
        await sync.addOperationForCurrentUser(
          entityType: 'CustomerCredit',
          entityId: cr.serverId,
          operationType: SyncOperationType.create,
          data: {
            'customerId': cr.customerId,
            'originalAmount': cr.originalAmount,
            'paidAmount': cr.paidAmount,
            'balanceDue': cr.balanceDue,
            'status': cr.status.name,
            'dueDate': cr.dueDate?.toIso8601String(),
            'description': cr.description,
            'notes': cr.notes,
            'invoiceId': cr.invoiceId,
            'invoiceNumber': cr.invoiceNumber,
          },
          priority: 1,
        );
        return true;
    }
    return false;
  }
}

