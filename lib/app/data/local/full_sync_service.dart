// lib/app/data/local/full_sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'isar_database.dart';
import '../../../features/settings/presentation/controllers/organization_controller.dart';
import '../../core/network/network_info.dart';
import '../../core/network/dio_client.dart';

// Remote DataSources
import '../../../features/products/data/datasources/product_remote_datasource.dart';
import '../../../features/categories/data/datasources/category_remote_datasource.dart';
import '../../../features/customers/data/datasources/customer_remote_datasource.dart';
import '../../../features/invoices/data/datasources/invoice_remote_datasource.dart';
import '../../../features/expenses/data/datasources/expense_remote_datasource.dart';
import '../../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../../../features/suppliers/data/datasources/supplier_remote_datasource.dart';
import '../../../features/bank_accounts/data/datasources/bank_account_remote_datasource.dart';
import '../../../features/purchase_orders/data/datasources/purchase_order_remote_datasource.dart';
import '../../../features/credit_notes/data/datasources/credit_note_remote_datasource.dart';
import '../../../features/customer_credits/data/datasources/customer_credit_remote_datasource.dart';
import '../../../features/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../../features/inventory/data/datasources/inventory_local_datasource_isar.dart';
import '../../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../../features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import '../../../features/settings/data/datasources/organization_remote_datasource.dart';
import '../../../features/settings/data/datasources/printer_settings_remote_datasource.dart';
import '../../../features/settings/data/models/isar/isar_organization.dart';
import '../../../features/settings/data/models/printer_settings_model.dart';
import '../../../features/settings/data/repositories/organization_offline_repository.dart';

// Query Models
import '../../../features/products/data/models/product_query_model.dart';
import '../../../features/categories/data/models/category_query_model.dart';
import '../../../features/customers/data/models/customer_query_model.dart';
import '../../../features/invoices/domain/repositories/invoice_repository.dart';
import '../../../features/suppliers/domain/repositories/supplier_repository.dart';
import '../../../features/purchase_orders/domain/repositories/purchase_order_repository.dart';
import '../../../features/credit_notes/domain/repositories/credit_note_repository.dart';
import '../../../features/notifications/data/models/notification_query_model.dart';

// ISAR Models
import '../../../features/products/data/models/isar/isar_product.dart';
import '../../../features/categories/data/models/isar/isar_category.dart';
import '../../../features/customers/data/models/isar/isar_customer.dart';
import '../../../features/invoices/data/models/isar/isar_invoice.dart';
import '../../../features/expenses/data/models/isar/isar_expense.dart';
import '../../../features/suppliers/data/models/isar/isar_supplier.dart';
import '../../../features/bank_accounts/data/models/isar/isar_bank_account.dart';
import '../../../features/purchase_orders/data/models/isar/isar_purchase_order.dart';
import '../../../features/credit_notes/data/models/isar/isar_credit_note.dart';
import '../../../features/customer_credits/data/models/isar/isar_customer_credit.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_batch.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_movement.dart';
import '../../../features/notifications/data/models/isar/isar_notification.dart';
import '../../../features/purchase_orders/data/models/isar/isar_purchase_order_item.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_batch_movement.dart';
import '../../../features/settings/data/models/isar/isar_user_preferences.dart';
import '../../../features/settings/data/datasources/user_preferences_remote_datasource.dart';
import '../../../features/settings/data/datasources/user_preferences_local_datasource.dart';
import '../../../features/settings/presentation/controllers/user_preferences_controller.dart';
import '../../../features/subscriptions/data/models/isar/isar_subscription.dart';
import '../../../features/inventory/data/models/inventory_batch_model.dart';
import '../../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../../features/products/data/datasources/product_presentation_remote_datasource.dart';
import '../../../features/products/data/models/isar/isar_product_presentation.dart';
import 'sync_queue.dart';
import 'local_first.dart';
import 'sync_event_log.dart';
import 'sync_event_log_service.dart';
import 'sync_changes_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../../features/invoices/data/models/invoice_model.dart';
import '../../../features/products/data/models/product_model.dart';
import '../../../features/products/data/models/product_presentation_model.dart';
import '../../../features/customers/data/models/customer_model.dart';
import '../../../features/suppliers/data/models/supplier_model.dart';
import '../../../features/expenses/data/models/expense_model.dart';
import '../../../features/purchase_orders/data/models/purchase_order_model.dart';
import '../../../features/credit_notes/data/models/credit_note_model.dart';
import '../../../features/customer_credits/data/models/customer_credit_model.dart';
import '../../../features/customer_credits/data/datasources/customer_credit_local_datasource_isar.dart';
import '../../../features/inventory/data/models/inventory_movement_model.dart';
import '../../../features/notifications/data/models/notification_model.dart';

/// Resultado de un Full Sync
class FullSyncResult {
  final Map<String, int> syncedCounts;
  final Map<String, String> errors;
  final Duration duration;
  final bool wasAborted;

  const FullSyncResult({
    required this.syncedCounts,
    required this.errors,
    required this.duration,
    this.wasAborted = false,
  });

  int get totalSynced => syncedCounts.values.fold(0, (a, b) => a + b);
  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !hasErrors && !wasAborted;

  @override
  String toString() {
    final buffer = StringBuffer('FullSyncResult:\n');
    buffer.writeln('  Duration: ${duration.inSeconds}s');
    buffer.writeln('  Total synced: $totalSynced');
    for (final entry in syncedCounts.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    if (hasErrors) {
      buffer.writeln('  Errors:');
      for (final entry in errors.entries) {
        buffer.writeln('    ${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString();
  }
}

/// Progreso de sincronización de una entidad
class _RowCountCheck {
  final Future<int?> Function() server;
  final Future<int> Function() local;
  const _RowCountCheck({required this.server, required this.local});
}

class SyncEntityProgress {
  final String entityName;
  final int count;
  final bool isComplete;
  final bool hasError;
  final String? errorMessage;

  const SyncEntityProgress({
    required this.entityName,
    this.count = 0,
    this.isComplete = false,
    this.hasError = false,
    this.errorMessage,
  });
}

/// Servicio de descarga completa del servidor a ISAR.
/// Se ejecuta después del login exitoso y opcionalmente de forma periódica.
class FullSyncService extends GetxService {
  final IsarDatabase _database;
  Isar get _isar => _database.database;

  // Estado observable
  final RxBool isSyncing = false.obs;
  final RxString currentEntity = ''.obs;
  final RxList<SyncEntityProgress> progress = <SyncEntityProgress>[].obs;
  final RxDouble overallProgress = 0.0.obs;

  // Control de cancelación
  bool _abortRequested = false;

  // Última sincronización exitosa
  DateTime? _lastFullSyncAt;
  DateTime? get lastFullSyncAt => _lastFullSyncAt;

  static const int _pageSize = 100;

  /// Tiempo máximo que un módulo puede descargar en un pull periódico.
  /// Al agotarse, el módulo se detiene entre páginas y el siguiente pull
  /// sigue desde donde quedó. Sin este límite cada pull volvía a bajar
  /// catálogos completos (miles de productos, facturas, lotes…) en el
  /// hilo de la pantalla, y la app se trababa.
  static const Duration _periodicEntityBudget = Duration(seconds: 10);

  /// Módulos que se pueden descargar por tandas: solo guardan (upsert) lo
  /// que llega, así que una descarga parcial no borra nada. Los que
  /// reemplazan la lista completa al final (categorías de gastos,
  /// almacenes…) no están aquí y siempre se descargan completos.
  static const Set<String> _resumableEntities = {
    'Productos',
    'Presentaciones',
    'Clientes',
    'Proveedores',
    'Facturas',
    'Gastos',
    'Órdenes de Compra',
    'Notas de Crédito',
    'Créditos de Clientes',
    'Lotes de Inventario',
    'Movimientos de Inventario',
    'Notificaciones',
  };

  /// Página (o posición) donde quedó cada módulo cuando un pull periódico
  /// agotó su tiempo.
  final Map<String, int> _resumeCursor = {};

  // Tiers de sincronización paralela (por dependencias)
  // Tier 1: Entidades base sin dependencias
  // Tier 2: Entidades que dependen de categorías
  // Tier 3: Entidades transaccionales
  // Tier 4: Entidades derivadas + notificaciones
  static const List<List<String>> _syncTiers = [
    ['Organización', 'Suscripción', 'Categorías', 'Categorías de Gastos', 'Preferencias de Usuario'],
    ['Productos', 'Clientes', 'Proveedores', 'Cuentas Bancarias', 'Almacenes', 'Impresoras'],
    ['Presentaciones', 'Facturas', 'Gastos', 'Órdenes de Compra'],
    ['Notas de Crédito', 'Créditos de Clientes', 'Lotes de Inventario', 'Movimientos de Inventario', 'Notificaciones'],
  ];

  // Lista plana para progreso UI
  static List<String> get _syncOrder =>
      _syncTiers.expand((tier) => tier).toList();

  FullSyncService(this._database);

  /// Sincroniza todos los módulos desde el servidor (en paralelo por tiers).
  ///
  /// Los módulos grandes descargan solo lo que cambió desde la última vez.
  ///
  /// - [skipCleanup] = true: pull periódico / al volver la conexión. Con
  ///   tiempo límite por módulo.
  /// - [skipCleanup] = false (login, cambio de negocio): sin tiempo límite.
  ///   Los datos locales SOLO se borran si son de OTRO negocio; si es el
  ///   mismo, se sigue con la descarga incremental (nunca se vacía el caché
  ///   del negocio actual: lo creado sin conexión no desaparece de pantalla).
  /// - [forceFullDownload]: vuelve a bajar todo (sin borrar antes) y al final
  ///   quita lo que ya no exista en el servidor. Para reparar el caché.
  Future<FullSyncResult> performFullSync({
    bool skipCleanup = false,
    bool forceFullDownload = false,
  }) async {
    if (isSyncing.value) {

      return FullSyncResult(
        syncedCounts: {},
        errors: {'general': 'Sincronización ya en progreso'},
        duration: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();
    final syncedCounts = <String, int>{};
    final errors = <String, String>{};

    isSyncing.value = true;
    _abortRequested = false;
    progress.clear();

    final allEntities = _syncOrder;

    // Descargas de cada módulo, aunque ya se haya dejado de esperarlas por
    // el timeout. La sincronización no se da por terminada hasta que todas
    // acaben: así nunca corren dos descargas encima una de otra.
    final inFlight = <Future<void>>[];
    final entityDeadline =
        skipCleanup ? DateTime.now().add(_periodicEntityBudget) : null;

    // Inicializar progreso
    for (final entity in allEntities) {
      progress.add(SyncEntityProgress(entityName: entity));
    }

    try {
      // Verificar conectividad
      final networkInfo = Get.find<NetworkInfo>();
      if (!await networkInfo.isConnected) {

        return FullSyncResult(
          syncedCounts: {},
          errors: {'general': 'Sin conexión a internet'},
          duration: stopwatch.elapsed,
          wasAborted: true,
        );
      }

      // ✅ CRÍTICO: health-check al backend ANTES de hacer .clear() en ISAR.
      // Sin esto, si el backend está caído (502 Bad Gateway, timeout, etc.)
      // pero hay internet, el código antiguo borraba TODA la base de datos
      // ISAR y luego no podía repoblarla → usuario perdía cache offline.
      // Reportado por el usuario: "la app se queda sin datos en cache".
      if (!skipCleanup) {
        final reachable = await networkInfo.canReachServer(
          timeout: const Duration(seconds: 5),
        );
        if (!reachable) {
          return FullSyncResult(
            syncedCounts: {},
            errors: {'general': 'Servidor no alcanzable (cache preservado)'},
            duration: stopwatch.elapsed,
            wasAborted: true,
          );
        }
      }

      // Limpiar datos del tenant anterior SELECTIVAMENTE
      // NUNCA borrar: syncOperations, idempotencyRecords, printerSettings no sincronizados
      // skipCleanup=true para pulls periódicos: upsert by serverId es seguro sin limpiar
      final wipeLocalData = !skipCleanup && await _isDifferentBusiness();
      if (!wipeLocalData && forceFullDownload) {
        await _watermarks.clearAll();
        _changesProgress.clear();
      }
      if (wipeLocalData) {
        try {

          await _isar.writeTxn(() async {
            // Limpiar colecciones de entidades descargables del servidor
            await _isar.isarCategorys.clear();
            await _isar.isarCustomers.clear();
            await _isar.isarCustomerCredits.clear();
            await _isar.isarProducts.clear();
            await _isar.isarExpenses.clear();
            await _isar.isarInvoices.clear();
            await _isar.isarCreditNotes.clear();
            await _isar.isarNotifications.clear();
            await _isar.isarBankAccounts.clear();
            await _isar.isarSuppliers.clear();
            await _isar.isarPurchaseOrders.clear();
            // NO limpiar isarPurchaseOrderItems aquí: el list API no devuelve items,
            // así que _syncPurchaseOrders() no puede repoblarlos. Items huérfanos
            // (de otro tenant) se limpian en _cleanupOrphanedRecords().
            await _isar.isarInventoryMovements.clear();
            await _isar.isarInventoryBatchs.clear();
            await _isar.isarInventoryBatchMovements.clear();
            await _isar.isarOrganizations.clear();
            await _isar.isarUserPreferences.clear();
            await _isar.isarSubscriptions.clear();
            // Solo borrar impresoras ya sincronizadas (las del servidor se re-descargan)
            final unsyncedPrinters = await _isar.printerSettingsModels
                .filter()
                .isSyncedEqualTo(false)
                .findAll();
            await _isar.printerSettingsModels.clear();
            // Restaurar impresoras no sincronizadas
            if (unsyncedPrinters.isNotEmpty) {
              for (final p in unsyncedPrinters) {
                await _isar.printerSettingsModels.put(p);
              }

            }
            // NUNCA tocar: syncOperations ni isarIdempotencyRecords
          });
          // Datos locales borrados: la próxima descarga de cada módulo debe ser
          // completa, no "desde la última vez".
          resetLocalCollectionsReady();
          await _watermarks.clearAll();
          _changesProgress.clear();
          await _rememberBusiness();

        } catch (e) {

        }
      } else if (await localDataOrganization() == null) {
        // Primera descarga en este equipo: anotar de qué negocio son los
        // datos, para que al cambiar de usuario se sepa si es el mismo.
        await _rememberBusiness();
      }

      final legacySyncFunctions = <String, Future<int> Function()>{
        'Organización': _syncOrganization,
        'Suscripción': _syncSubscription,
        'Preferencias de Usuario': _syncUserPreferences,
        'Categorías': _syncCategories,
        'Categorías de Gastos': _syncExpenseCategories,
        'Productos': _syncProducts,
        'Presentaciones': _syncProductPresentations,
        'Clientes': _syncCustomers,
        'Proveedores': _syncSuppliers,
        'Almacenes': _syncWarehouses,
        'Facturas': _syncInvoices,
        'Gastos': _syncExpenses,
        'Cuentas Bancarias': _syncBankAccounts,
        'Impresoras': _syncPrinterSettings,
        'Órdenes de Compra': _syncPurchaseOrders,
        'Notas de Crédito': _syncCreditNotes,
        'Créditos de Clientes': _syncCustomerCredits,
        'Lotes de Inventario': _syncInventoryBatches,
        'Movimientos de Inventario': _syncInventoryMovements,
        'Notificaciones': _syncNotifications,
      };
      // Los módulos grandes descargan solo lo que cambió desde la última vez
      // (GET /sync/changes). Si el servidor aún no lo soporta, se usa la
      // descarga completa de siempre.
      final syncFunctions = <String, Future<int> Function()>{
        for (final entry in legacySyncFunctions.entries)
          entry.key: _incrementalOr(entry.key, entry.value),
      };

      int completedCount = 0;

      // Procesar tier por tier, dentro de cada tier en PARALELO
      for (int tierIdx = 0; tierIdx < _syncTiers.length; tierIdx++) {
        if (_abortRequested) {

          stopwatch.stop();
          return FullSyncResult(
            syncedCounts: syncedCounts,
            errors: errors,
            duration: stopwatch.elapsed,
            wasAborted: true,
          );
        }

        final tier = _syncTiers[tierIdx];
        currentEntity.value = tier.join(', ');

        // Lanzar TODAS las entidades del tier en paralelo con timeout individual.
        // 12s es suficiente para una respuesta normal del servidor (p99 < 3s).
        // Con 60s, una caída de red congelaba la UI por 1+ minuto antes de
        // abortar — con 12s el sistema detecta la caída rápidamente y cambia
        // a modo offline sin que el usuario lo note.
        final futures = <Future<MapEntry<String, int?>>>[];
        final tierDeadline = entityDeadline == null
            ? null
            : DateTime.now().add(_periodicEntityBudget);
        for (final entityName in tier) {
          final download = _syncEntitySafe(
            entityName,
            syncFunctions[entityName]!,
            deadline: tierDeadline,
          );
          inFlight.add(download);
          futures.add(
            download
                .timeout(
              const Duration(seconds: 12),
              onTimeout: () {
                // No es un error de datos: el módulo tardó más de 12 s (típico
                // en la primera descarga de catálogos grandes). Lo que ya
                // bajó queda guardado y el resto llega en el siguiente pull.
                debugPrint(
                  '[FULL_SYNC] $entityName tardó más de 12 s — se completará en la siguiente descarga',
                );
                return MapEntry(entityName, null);
              },
            )
                .then((result) {
              // Actualizar progreso inmediatamente cuando cada entidad termina
              final globalIdx = allEntities.indexOf(result.key);
              if (result.value != null) {
                syncedCounts[result.key] = result.value!;
                progress[globalIdx] = SyncEntityProgress(
                  entityName: result.key,
                  count: result.value!,
                  isComplete: true,
                );

              } else {
                errors[result.key] = 'Error en sincronización';
                progress[globalIdx] = SyncEntityProgress(
                  entityName: result.key,
                  hasError: true,
                  errorMessage: 'Error o timeout',
                );
              }
              completedCount++;
              overallProgress.value = completedCount / allEntities.length;

              // Actualizar texto del banner con las entidades que aún están pendientes
              final pendingInTier = tier.where((e) =>
                !progress[allEntities.indexOf(e)].isComplete &&
                !progress[allEntities.indexOf(e)].hasError
              ).toList();
              if (pendingInTier.isNotEmpty) {
                currentEntity.value = pendingInTier.join(', ');
              }

              return result;
            }),
          );
        }

        await Future.wait(futures);

        // Yield al event loop entre tiers. Sin esto, los 4 tiers se
        // ejecutan back-to-back sin dejar respirar al main isolate, y
        // si el usuario está navegando, sus frames de Flutter quedan
        // hambreados (la UI se siente "pegada"). Un `Future.delayed
        // (Duration.zero)` cede el turno al scheduler para que
        // pinten frames pendientes antes del siguiente tier.
        if (tierIdx < _syncTiers.length - 1) {
          await Future.delayed(Duration.zero);
        }

        // Early abort: si TODAS las entidades del tier fallaron, el servidor está caído
        // No tiene sentido continuar con los demás tiers (evita ~18 requests innecesarias)
        final tierErrors = tier.where((e) => errors.containsKey(e)).length;
        if (tierErrors == tier.length && tier.length > 1) {

          // Marcar entidades restantes como no sincronizadas (sin intentar)
          for (int remainingTier = tierIdx + 1; remainingTier < _syncTiers.length; remainingTier++) {
            for (final entityName in _syncTiers[remainingTier]) {
              final globalIdx = allEntities.indexOf(entityName);
              errors[entityName] = 'Omitido (servidor no disponible)';
              progress[globalIdx] = SyncEntityProgress(
                entityName: entityName,
                hasError: true,
                errorMessage: 'Servidor no disponible',
              );
              completedCount++;
            }
          }
          overallProgress.value = 1.0;
          // Marcar servidor como no alcanzable para evitar más intentos
          try {
            Get.find<NetworkInfo>().markServerUnreachable();
          } catch (_) {}
          break;
        }
      }

      overallProgress.value = 1.0;
      _lastFullSyncAt = DateTime.now();

      // Limpiar registros huérfanos de TODAS las entidades (con timeout)
      currentEntity.value = 'Limpiando datos temporales...';
      try {
        await _cleanupOrphanedRecords().timeout(
          const Duration(seconds: 30),
          onTimeout: () {

          },
        );
      } catch (e) {

      }

      stopwatch.stop();
      final result = FullSyncResult(
        syncedCounts: syncedCounts,
        errors: errors,
        duration: stopwatch.elapsed,
      );

      return result;
    } catch (e) {
      stopwatch.stop();

      return FullSyncResult(
        syncedCounts: syncedCounts,
        errors: {...errors, 'fatal': e.toString()},
        duration: stopwatch.elapsed,
      );
    } finally {
      if (inFlight.isNotEmpty) {
        await Future.wait(inFlight);
      }
      isSyncing.value = false;
      currentEntity.value = '';
    }
  }

  /// Ejecuta sync de una entidad individual capturando errores
  Future<MapEntry<String, int?>> _syncEntitySafe(
    String entityName,
    Future<int> Function() syncFn, {
    DateTime? deadline,
  }) async {
    final resumable = _resumableEntities.contains(entityName);
    final pass = _EntityPass(
      deadline: resumable ? deadline : null,
      resumeFrom: resumable && deadline != null
          ? _resumeCursor[entityName]
          : null,
    );
    try {
      final count = await runZoned(
        syncFn,
        zoneValues: {_EntityPass.zoneKey: pass},
      );
      // Si terminó por tiempo, el siguiente pull sigue desde ahí; si llegó
      // al final, el siguiente vuelve a empezar desde la primera página.
      if (pass.stoppedAt != null) {
        _resumeCursor[entityName] = pass.stoppedAt!;
      } else {
        _resumeCursor.remove(entityName);
      }
      _lastModuleError.remove(entityName);
      _lastModuleOkAt[entityName] = DateTime.now();
      return MapEntry(entityName, count);
    } catch (e, stack) {
      debugPrint('[FULL_SYNC] ERROR en $entityName: $e');
      _lastModuleError[entityName] = '$e';
      _lastModuleErrorAt[entityName] = DateTime.now();
      _recordDownloadError(entityName, e, stack);
      return MapEntry(entityName, null);
    }
  }

  // ==================== ESTADO PARA DIAGNÓSTICO ====================

  final Map<String, DateTime> _lastErrorRecordedAt = {};

  /// Deja el error de descarga guardado en el registro de Diagnóstico
  /// ("Eventos recientes"), con el detalle técnico, para poder rastrear en
  /// el propio equipo por qué un módulo no termina de bajar. Un mismo
  /// módulo se registra como máximo cada 2 minutos (no llenar el registro).
  void _recordDownloadError(String module, Object error, StackTrace stack) {
    final last = _lastErrorRecordedAt[module];
    final now = DateTime.now();
    if (last != null && now.difference(last) < const Duration(minutes: 2)) return;
    _lastErrorRecordedAt[module] = now;
    try {
      if (!Get.isRegistered<SyncEventLogService>()) return;
      final entity = _incrementalEntities[module];
      Get.find<SyncEventLogService>().log(
        severity: SyncEventSeverity.error,
        eventType: SyncEventType.fullSync,
        operation: 'Descarga de $module',
        message: 'No se pudo descargar $module: $error',
        entityType: entity ?? module,
        details: [
          'Tamaño de página: ${entity == null ? '-' : _effectivePageSize(entity)}',
          'Error: $error',
          'Traza:',
          ...stack.toString().split('\n').take(12),
        ].join('\n'),
      );
    } catch (_) {}
  }

  final Map<String, String> _lastModuleError = {};
  final Map<String, DateTime> _lastModuleErrorAt = {};
  final Map<String, DateTime> _lastModuleOkAt = {};

  /// Estado de la descarga de cada módulo (para la pantalla de Diagnóstico):
  /// si ya bajó completo, si va a medias, con qué tamaño de página y el
  /// último error. Así se ve en el equipo por qué algo no aparece.
  Future<List<ModuleDownloadStatus>> downloadStatus() async {
    final list = <ModuleDownloadStatus>[];
    for (final entry in _incrementalEntities.entries) {
      final entity = entry.value;
      list.add(ModuleDownloadStatus(
        label: entry.key,
        entity: entity,
        downloaded: await isModuleDownloaded(entity),
        pageSize: _effectivePageSize(entity),
        defaultPageSize: _changesPageSize[entity] ?? _lightChangesPageSize,
        lastError: _lastModuleError[entry.key],
        lastErrorAt: _lastModuleErrorAt[entry.key],
        lastOkAt: _lastModuleOkAt[entry.key],
      ));
    }
    return list;
  }

  // ==================== DESCARGA INCREMENTAL ====================

  /// Módulo (nombre en pantalla) → entidad del endpoint /sync/changes.
  static const Map<String, String> _incrementalEntities = {
    'Productos': 'products',
    'Presentaciones': 'product_presentations',
    'Clientes': 'customers',
    'Proveedores': 'suppliers',
    'Facturas': 'invoices',
    'Gastos': 'expenses',
    'Órdenes de Compra': 'purchase_orders',
    'Notas de Crédito': 'credit_notes',
    'Créditos de Clientes': 'customer_credits',
    'Lotes de Inventario': 'inventory_batches',
    'Movimientos de Inventario': 'inventory_movements',
    'Notificaciones': 'notifications',
  };

  /// El módulo baja solo lo que cambió (su conteo = registros nuevos o
  /// modificados). Los demás se bajan completos en cada descarga.
  static bool isIncrementalModule(String moduleName) =>
      _incrementalEntities.containsKey(moduleName);

  /// Registros por página. Los módulos con muchas relaciones (facturas con
  /// ítems y pagos, productos con precios…) van de a 200; los livianos de a
  /// 500 (máximo del servidor).
  static const Map<String, int> _changesPageSize = {
    'invoices': 200,
    'products': 200,
    'credit_notes': 200,
    'purchase_orders': 200,
    'expenses': 200,
  };
  static const int _lightChangesPageSize = 500;
  static const int _minChangesPageSize = 25;

  /// Tamaño reducido por módulo tras páginas que no alcanzaron a llegar
  /// (internet lento). Se mantiene mientras la app esté abierta.
  final Map<String, int> _adaptivePageSize = {};

  int _effectivePageSize(String entity) =>
      _adaptivePageSize[entity] ??
      (_changesPageSize[entity] ?? _lightChangesPageSize);

  /// Error de red por lentitud (tiempo de espera, conexión cortada a media
  /// respuesta): se puede reintentar con una página más pequeña.
  static bool _isSlowNetworkError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('timeout') ||
        text.contains('tiempo de espera') ||
        text.contains('timed out') ||
        text.contains('connection closed') ||
        text.contains('connection reset') ||
        text.contains('receive');
  }

  /// Ventana de "lo reciente" que se baja primero en una descarga completa.
  static const Duration _recentWindow = Duration(days: 3);

  /// ¿Hay algún módulo a medias de su descarga completa? Mientras tanto los
  /// pulls van más seguido para terminarla pronto.
  bool get hasPendingFullDownload =>
      _changesProgress.values.any((p) => p.isFullDownload);

  /// El módulo ya terminó su descarga completa en este equipo: tiene marca
  /// guardada y no hay una descarga completa en curso (ni en memoria ni
  /// guardada a medias). Mientras no, la base local puede tener solo una
  /// parte (p. ej. lo de los últimos días) y las pantallas deben usar el
  /// servidor.
  Future<bool> isModuleDownloaded(String entity) async {
    final inMemory = _changesProgress[entity];
    if (inMemory != null && inMemory.isFullDownload) return false;
    final organization = await _organizationKey();
    if (organization == null) return false;
    final saved = await _watermarks.getProgress(organization, entity);
    if (saved != null && saved['isFullDownload'] == true) return false;
    return await _watermarks.get(organization, entity) != null;
  }

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  final SyncWatermarkStore _watermarks = SyncWatermarkStore();
  SyncChangesClient? _changesClientInstance;
  SyncChangesClient get _changesClient =>
      _changesClientInstance ??= SyncChangesClient(Get.find<DioClient>());

  /// Solo para pruebas: cliente, manejadores y negocio de reemplazo.
  @visibleForTesting
  set debugChangesClient(SyncChangesClient client) =>
      _changesClientInstance = client;
  @visibleForTesting
  Map<String, Object>? debugChangeHandlers;
  @visibleForTesting
  String? debugOrganizationKey;

  /// Solo para pruebas: un manejador de entidad hecho de funciones sueltas.
  @visibleForTesting
  static Object debugHandler({
    required Future<Set<String>> Function(List<Map<String, dynamic>>) apply,
    required Future<int> Function(List<String>) delete,
    required Future<int> Function(Set<String>) sweep,
  }) =>
      _ChangeHandler(
        apply: apply,
        delete: delete,
        sweep: (seen, _) => sweep(seen),
      );

  /// Solo para pruebas: corre la descarga incremental de [entity] (pull
  /// periódico si se pasa [deadline]).
  @visibleForTesting
  Future<int?> debugPullChanges(String entity, {DateTime? deadline}) =>
      debugSyncEntity(
        _incrementalEntities.entries.firstWhere((e) => e.value == entity).key,
        () => _pullThenHeal(entity),
        deadline: deadline,
      );

  /// Solo para pruebas: reemplaza el conteo servidor/equipo de [entity].
  @visibleForTesting
  void debugSetCountCheck(String entity,
          {required Future<int?> Function() server,
          required Future<int> Function() local}) =>
      _countCheckOverrides[entity] = _RowCountCheck(server: server, local: local);
  final Map<String, _RowCountCheck> _countCheckOverrides = {};

  Future<int> _pullThenHeal(String entity) async {
    final applied = await _pullChanges(entity);
    await _healMissingRows(entity);
    return applied;
  }

  /// Descargas incrementales a medias (por tiempo agotado); el siguiente pull
  /// sigue desde aquí.
  final Map<String, _ChangesProgress> _changesProgress = {};

  /// Si el servidor no tiene /sync/changes, no se vuelve a intentar hasta
  /// esta hora (se usa la descarga completa mientras tanto).
  DateTime? _incrementalUnsupportedUntil;

  Future<int> Function() _incrementalOr(
    String entityName,
    Future<int> Function() legacy,
  ) {
    final entity = _incrementalEntities[entityName];
    if (entity == null) return legacy;
    return () async {
      final until = _incrementalUnsupportedUntil;
      if (until != null && DateTime.now().isBefore(until)) return legacy();
      try {
        return await _pullThenHeal(entity);
      } on SyncChangesUnsupportedException {
        _incrementalUnsupportedUntil =
            DateTime.now().add(const Duration(minutes: 30));
        debugPrint(
          '[FULL_SYNC] El servidor aún no tiene descarga incremental — se usa la descarga completa',
        );
        return legacy();
      }
    };
  }

  /// Cuántos registros tiene el servidor vs. el equipo, por módulo. Si el
  /// equipo perdió registros (versiones anteriores borraban clientes del
  /// equipo al crear o editar uno), la descarga "solo lo que cambió" nunca
  /// los devolvía: un empleado veía 15 clientes de 119.
  late final Map<String, _RowCountCheck> _countChecks = {
    'customers': _RowCountCheck(
      server: () async =>
          await _changesClient.count('customers') ??
          (await _getOrCreateDS<CustomerRemoteDataSource>(
            () => CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
          ).getCustomers(CustomerQueryModel(page: 1, limit: 1)))
              .meta
              .totalItems,
      local: () async => _countServerIds(await _isar.isarCustomers
          .filter()
          .deletedAtIsNull()
          .serverIdProperty()
          .findAll()),
    ),
    'customer_credits': _RowCountCheck(
      server: () => _changesClient.count('customer_credits'),
      local: () async => _countServerIds(await _isar.isarCustomerCredits
          .filter()
          .deletedAtIsNull()
          .serverIdProperty()
          .findAll()),
    ),
  };

  /// Solo los registros que ya existen en el servidor (no los temporales).
  static int _countServerIds(List<String> ids) =>
      ids.where(_uuidPattern.hasMatch).toSet().length;
  final Map<String, DateTime> _lastCountCheck = {};
  static const Duration _countCheckEvery = Duration(minutes: 15);

  /// Al terminar una descarga incremental: si el equipo tiene MENOS
  /// registros que el servidor, se olvida la marca y la siguiente descarga
  /// baja todo de nuevo (sin borrar nada del equipo). Se revisa al abrir la
  /// app y luego cada 15 minutos. Cualquier error se ignora.
  Future<void> _healMissingRows(String entity) async {
    final check = _countCheckOverrides[entity] ?? _countChecks[entity];
    if (check == null || _changesProgress.containsKey(entity)) return;
    final last = _lastCountCheck[entity];
    if (last != null && DateTime.now().difference(last) < _countCheckEvery) {
      return;
    }
    _lastCountCheck[entity] = DateTime.now();
    try {
      final server = await check.server();
      final local = await check.local();
      if (server == null || local >= server) return;
      final organization = await _organizationKey();
      if (organization == null) return;
      await _watermarks.remove(organization, entity);
      debugPrint(
        '[FULL_SYNC] $entity: el equipo tiene $local y el servidor $server — se descarga todo de nuevo',
      );
    } catch (_) {}
  }

  /// Identifica al negocio para guardar sus marcas por separado.
  Future<String?> _organizationKey() async {
    if (debugOrganizationKey != null) return debugOrganizationKey;
    try {
      final user = await Get.find<SecureStorageService>().getUserData();
      final id = user?['organizationId']?.toString();
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    try {
      final id = Get.find<OrganizationController>().currentOrganization?.id;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return null;
  }

  static const String _lastBusinessKey = 'full_sync_business_v1';

  /// Negocio al que pertenecen los datos guardados en este equipo (lo
  /// anota la descarga). `null` si todavía no se ha descargado nada.
  static Future<String?> localDataOrganization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_lastBusinessKey);
      return (value == null || value.isEmpty) ? null : value;
    } catch (_) {
      return null;
    }
  }

  /// ¿Los datos locales son de otro negocio (o no se sabe de cuál)? Solo en
  /// ese caso se borran antes de descargar.
  Future<bool> _isDifferentBusiness() async {
    final organization = await _organizationKey();
    // Sin saber el negocio actual no se borra nada "por si acaso": se
    // perdería el trabajo del equipo. La descarga espera a conocerlo.
    if (organization == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_lastBusinessKey);
    // Datos sin negocio anotado (equipo nuevo): no hay nada que proteger
    // de otro negocio; la descarga lo anota.
    if (stored == null || stored.isEmpty) return false;
    return stored != organization;
  }

  Future<void> _rememberBusiness() async {
    final organization = await _organizationKey();
    if (organization == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBusinessKey, organization);
  }

  /// ¿Le queda tiempo a este módulo en el pull actual?
  bool _hasTimeLeft() {
    if (_abortRequested) return false;
    final deadline = _currentPass?.deadline;
    return deadline == null || DateTime.now().isBefore(deadline);
  }

  /// Descarga incremental de una entidad: pide solo lo cambiado desde la
  /// última marca, aplica altas/cambios/borrados y guarda la nueva marca
  /// cuando termina. La primera vez (sin marca) descarga todo y al final
  /// quita los registros locales que ya no existen en el servidor.
  Future<int> _pullChanges(String entity) async {
    final organization = await _organizationKey();
    if (organization == null) {
      throw StateError('No se pudo identificar el negocio para sincronizar');
    }
    final handler =
        (debugChangeHandlers?[entity] as _ChangeHandler?) ?? _changeHandlers[entity]!;

    var progress = _changesProgress[entity];
    if (progress == null || progress.organization != organization) {
      // ¿Quedó una descarga a medias antes de cerrar la app? Se sigue desde
      // ahí en vez de empezar de nuevo.
      final saved = await _watermarks.getProgress(organization, entity);
      progress = saved == null ? null : _ChangesProgress.fromJson(saved);
      if (progress == null || progress.organization != organization) {
        final watermark = await _watermarks.get(organization, entity);
        progress = _ChangesProgress(
          organization: organization,
          since: watermark ?? SyncChangesClient.epoch,
        );
      }
      _changesProgress[entity] = progress;
    }
    Future<void> saveProgress() =>
        _watermarks.setProgress(organization, entity, progress!.toJson());
    final recent = _recentlyApplied(organization, entity);

    // Guarda los registros de una página y devuelve cuántos eran nuevos o
    // cambiados. El servidor repite los últimos minutos en cada descarga
    // (margen de seguridad); lo que ya se guardó con esa misma marca de
    // tiempo es idéntico, así que no se vuelve a escribir ni cuenta como
    // cambio. Antes cada descarga "traía cambios" y recargaba las pantallas
    // cada minuto sin que nada hubiera cambiado. Lo que no se guardó por
    // tener cambios locales sin subir no se recuerda: se reintenta.
    Future<int> applyFresh(SyncChangesPage page) async {
      final fresh = <Map<String, dynamic>>[];
      final freshStamps = <String?>[];
      for (var i = 0; i < page.items.length; i++) {
        final stamp = i < page.stamps.length ? page.stamps[i] : null;
        final id = page.items[i]['id']?.toString();
        if (id != null && stamp != null && recent[id] == stamp) continue;
        fresh.add(page.items[i]);
        freshStamps.add(stamp);
      }
      if (fresh.isEmpty) return 0;
      final skipped = await handler.apply(fresh);
      for (var i = 0; i < fresh.length; i++) {
        final id = fresh[i]['id']?.toString();
        final stamp = freshStamps[i];
        if (id == null || stamp == null) continue;
        if (skipped.contains(id)) {
          progress!.noteSkipped(stamp);
        } else {
          recent[id] = stamp;
        }
      }
      return fresh.length;
    }

    // Tamaño de página adaptable: con internet lento, una página grande
    // puede no alcanzar a llegar antes del tiempo de espera y la descarga
    // se quedaba repitiendo la misma página sin avanzar nunca.
    Future<SyncChangesPage> fetchPage(String since, String? afterId) async {
      while (true) {
        final size = _effectivePageSize(entity);
        try {
          return await _changesClient.fetch(
            entity,
            since: since,
            afterId: afterId,
            limit: size,
          );
        } catch (e) {
          if (!_isSlowNetworkError(e) || size <= _minChangesPageSize) rethrow;
          _adaptivePageSize[entity] = (size ~/ 2).clamp(_minChangesPageSize, size);
          debugPrint(
            '[FULL_SYNC] $entity: página de $size tardó demasiado — se reintenta de a ${_adaptivePageSize[entity]}',
          );
          if (!_hasTimeLeft()) rethrow;
        }
      }
    }
    var applied = 0;

    // Fase 1 de una descarga completa: lo de los últimos días primero.
    if (progress.isFullDownload && !progress.recentDone) {
      progress.recentSince ??= DateTime.now()
          .toUtc()
          .subtract(_recentWindow)
          .toIso8601String();
      while (true) {
        if (!_hasTimeLeft()) return applied;
        final page =
            await fetchPage(progress.recentSince!, progress.recentAfterId);
        if (page.items.isNotEmpty) {
          applied += await applyFresh(page);
        }
        if (!page.hasMore || page.nextSince == null) break;
        progress.recentSince = page.nextSince;
        progress.recentAfterId = page.nextAfterId;
        await saveProgress();
      }
      progress.recentDone = true;
      await saveProgress();
    }

    while (true) {
      if (!_hasTimeLeft()) {
        // Se sigue en el próximo pull; la marca no avanza hasta terminar.
        return applied;
      }
      final page = await fetchPage(progress!.since, progress.afterId);

      if (page.resetRequired) {
        // La marca es más vieja que el registro de borrados del servidor:
        // descarga completa y limpieza al final.
        await _watermarks.remove(organization, entity);
        await _watermarks.removeProgress(organization, entity);
        progress = _ChangesProgress(
          organization: organization,
          since: SyncChangesClient.epoch,
        );
        _changesProgress[entity] = progress;
        continue;
      }

      if (progress.afterId == null) {
        progress.watermark = page.watermark;
        if (page.deletedIds.isNotEmpty) {
          applied += await handler.delete(page.deletedIds);
        }
      }

      if (page.items.isNotEmpty) {
        if (progress.isFullDownload) {
          for (final item in page.items) {
            final id = item['id']?.toString();
            if (id != null) progress.seen.add(id);
          }
        }
        applied += await applyFresh(page);
      }

      if (!page.hasMore || page.nextSince == null) break;
      progress.since = page.nextSince!;
      progress.afterId = page.nextAfterId;
      await saveProgress();
    }

    if (progress.isFullDownload && progress.sweepValid) {
      // Corte: hora del SERVIDOR al empezar la descarga (ya trae 2 min de
      // margen). Lo creado o cambiado después no se toca aunque no haya
      // llegado en las páginas (p. ej. un cliente creado mientras se
      // descargaba). Sin marca: inicio en el equipo con 10 min de margen.
      final cutoff = DateTime.tryParse(progress.watermark ?? '') ??
          progress.startedAt.subtract(const Duration(minutes: 10));
      final removed = await handler.sweep(progress.seen, cutoff);
      if (removed > 0) {
        debugPrint(
          '[FULL_SYNC] $entity: $removed registro(s) local(es) ya no existen en el servidor — quitados',
        );
      }
    }
    final watermark = progress.watermark;
    if (watermark != null) {
      await _watermarks.set(
        organization,
        entity,
        SyncWatermarkStore.safeWatermark(watermark, progress.earliestSkipped),
      );
    }
    _changesProgress.remove(entity);
    await _watermarks.removeProgress(organization, entity);
    return applied;
  }

  // Registros guardados en las últimas descargas: id → marca de tiempo con
  // la que se guardaron. Solo en memoria; se olvidan pasados unos minutos
  // (más que el margen que repite el servidor).
  final Map<String, Map<String, String>> _appliedStamps = {};
  static const Duration _appliedStampsTtl = Duration(minutes: 10);

  Map<String, String> _recentlyApplied(String organization, String entity) {
    final stamps = _appliedStamps.putIfAbsent('$organization/$entity', () => {});
    // Tope de seguridad (p. ej. reloj del equipo desfasado): nunca crece sin
    // límite; olvidar solo significa volver a guardar algo idéntico.
    if (stamps.length > 5000) stamps.clear();
    final cutoff = DateTime.now().toUtc().subtract(_appliedStampsTtl);
    stamps.removeWhere((_, stamp) {
      final at = DateTime.tryParse(stamp);
      return at == null || at.isBefore(cutoff);
    });
    return stamps;
  }

  /// IDs con operaciones en la cola (pendientes o rechazadas): sus copias
  /// locales tienen cambios que el servidor aún no conoce.
  Future<Set<String>> _queuedEntityIds() async {
    final db = IsarDatabase.instance;
    final pending = await db.getPendingSyncOperations();
    final failed = await db.getFailedSyncOperations();
    return {
      for (final op in pending) op.entityId,
      for (final op in failed) op.entityId,
    };
  }

  /// Borra copias locales de registros borrados en el servidor, salvo las
  /// que tienen cambios locales sin subir.
  Future<int> _deleteServerRows(
    List<String> ids,
    Future<int> Function(List<String> ids) deleteAll,
  ) async {
    if (ids.isEmpty) return 0;
    final queued = await _queuedEntityIds();
    final safe = ids.where((id) => !queued.contains(id)).toList();
    if (safe.isEmpty) return 0;
    return _isar.writeTxn(() => deleteAll(safe));
  }

  /// Tras una descarga completa: quita las copias locales de registros del
  /// servidor que no llegaron (ya no existen). Nunca toca registros creados
  /// sin conexión (ID temporal) ni los que tienen cambios sin subir.
  Future<int> _sweepServerRows(
    Set<String> seen,
    DateTime cutoff,
    IsarCollection<dynamic> collection,
    Future<List<String>> Function() localServerIds,
    Future<int> Function(List<String> ids) deleteAll,
  ) async {
    final queued = await _queuedEntityIds();
    final candidates = (await localServerIds())
        .where((id) =>
            _uuidPattern.hasMatch(id) &&
            !seen.contains(id) &&
            !queued.contains(id))
        .toList();
    if (candidates.isEmpty) return 0;
    final stale = await _unchangedSince(collection, candidates, cutoff);
    if (stale.isEmpty) return 0;
    return _isar.writeTxn(() => deleteAll(stale));
  }

  /// De [serverIds], los que NO cambiaron desde [cutoff]. Lo creado o
  /// modificado durante la descarga se conserva. Ante cualquier duda (fecha
  /// ilegible, error), se conserva: nunca se borra algo sin certeza.
  /// Solo para pruebas.
  @visibleForTesting
  static Future<List<String>> debugUnchangedSince(
    IsarCollection<dynamic> collection,
    List<String> serverIds,
    DateTime cutoff,
  ) =>
      _unchangedSince(collection, serverIds, cutoff);

  static Future<List<String>> _unchangedSince(
    IsarCollection<dynamic> collection,
    List<String> serverIds,
    DateTime cutoff,
  ) async {
    try {
      final rows = await collection.getAllByIndex(
        'serverId',
        [for (final id in serverIds) [id]],
      );
      final result = <String>[];
      for (final dynamic row in rows) {
        if (row == null) continue;
        final DateTime? updatedAt = row.updatedAt as DateTime?;
        final DateTime? createdAt = row.createdAt as DateTime?;
        final last = [updatedAt, createdAt]
            .whereType<DateTime>()
            .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
        if (last != null && last.isBefore(cutoff)) {
          result.add(row.serverId as String);
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  Set<String> _skippedIds(Iterable<String> all, Iterable<String> kept) {
    final keptSet = kept.toSet();
    return all.where((id) => !keptSet.contains(id)).toSet();
  }

  IsarCustomerCredit _isarCreditFromModel(CustomerCreditModel credit) {
    return IsarCustomerCredit(
      serverId: credit.id,
      originalAmount: credit.originalAmount,
      paidAmount: credit.paidAmount,
      balanceDue: credit.balanceDue,
      status: _mapCreditStatus(credit.status),
      dueDate: credit.dueDate,
      description: credit.description,
      notes: credit.notes,
      customerId: credit.customerId,
      customerName: credit.customerName,
      invoiceId: credit.invoiceId,
      invoiceNumber: credit.invoiceNumber,
      organizationId: credit.organizationId,
      createdById: credit.createdById,
      createdByName: credit.createdByName,
      createdAt: credit.createdAt,
      updatedAt: credit.updatedAt,
      deletedAt: credit.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  late final Map<String, _ChangeHandler> _changeHandlers = {
    'invoices': _ChangeHandler(
      apply: (items) async {
        final rows = items
            .map((json) => IsarInvoice.fromModel(InvoiceModel.fromJson(json)))
            .toList();
        final safe = await _withoutQueuedLocalChanges(rows, (m) => m.serverId);
        await _isar.writeTxn(() => _isar.isarInvoices.putAllByServerId(safe));
        return _skippedIds(
            rows.map((m) => m.serverId), safe.map((m) => m.serverId));
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarInvoices.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarInvoices,
        () => _isar.isarInvoices.where().serverIdProperty().findAll(),
        _isar.isarInvoices.deleteAllByServerId,
      ),
    ),
    'products': _ChangeHandler(
      apply: (items) async {
        // Misma protección que la descarga completa: productos con stock
        // descontado sin conexión (aún sin subir) no se pisan.
        await _healStuckProducts();
        final unsynced =
            await _isar.isarProducts.filter().isSyncedEqualTo(false).findAll();
        final protected = unsynced
            .where((p) => !p.serverId.startsWith('product_offline_'))
            .map((p) => p.serverId)
            .toSet();
        final skipped = <String>{};
        final rows = <IsarProduct>[];
        for (final json in items) {
          final model = ProductModel.fromJson(json);
          if (protected.contains(model.id)) {
            skipped.add(model.id);
            continue;
          }
          rows.add(IsarProduct.fromModel(model));
        }
        await _isar.writeTxn(() async {
          for (final row in rows) {
            await _isar.isarProducts.putByServerId(row);
          }
        });
        return skipped;
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarProducts.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarProducts,
        () => _isar.isarProducts.where().serverIdProperty().findAll(),
        _isar.isarProducts.deleteAllByServerId,
      ),
    ),
    'product_presentations': _ChangeHandler(
      apply: (items) async {
        final unsynced = (await _isar.isarProductPresentations
                .filter()
                .isSyncedEqualTo(false)
                .findAll())
            .map((p) => p.serverId)
            .toSet();
        final skipped = <String>{};
        await _isar.writeTxn(() async {
          for (final json in items) {
            final model = ProductPresentationModel.fromJson(json);
            if (unsynced.contains(model.id)) {
              skipped.add(model.id);
              continue;
            }
            await _isar.isarProductPresentations
                .putByServerId(IsarProductPresentation.fromModel(model));
          }
        });
        return skipped;
      },
      delete: (ids) => _deleteServerRows(
          ids, _isar.isarProductPresentations.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarProductPresentations,
        () =>
            _isar.isarProductPresentations.where().serverIdProperty().findAll(),
        _isar.isarProductPresentations.deleteAllByServerId,
      ),
    ),
    'customers': _ChangeHandler(
      apply: (items) async {
        final rows = items
            .map((json) => IsarCustomer.fromModel(CustomerModel.fromJson(json)))
            .toList();
        final safe = await _withoutQueuedLocalChanges(rows, (m) => m.serverId);
        await _isar.writeTxn(() => _isar.isarCustomers.putAllByServerId(safe));
        return _skippedIds(
            rows.map((m) => m.serverId), safe.map((m) => m.serverId));
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarCustomers.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarCustomers,
        () => _isar.isarCustomers.where().serverIdProperty().findAll(),
        _isar.isarCustomers.deleteAllByServerId,
      ),
    ),
    'suppliers': _ChangeHandler(
      apply: (items) async {
        final rows = items
            .map((json) => IsarSupplier.fromModel(SupplierModel.fromJson(json)))
            .toList();
        final safe = await _withoutQueuedLocalChanges(rows, (m) => m.serverId);
        await _isar.writeTxn(() => _isar.isarSuppliers.putAllByServerId(safe));
        return _skippedIds(
            rows.map((m) => m.serverId), safe.map((m) => m.serverId));
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarSuppliers.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarSuppliers,
        () => _isar.isarSuppliers.where().serverIdProperty().findAll(),
        _isar.isarSuppliers.deleteAllByServerId,
      ),
    ),
    'expenses': _ChangeHandler(
      apply: (items) async {
        final rows = items
            .map((json) =>
                IsarExpense.fromEntity(ExpenseModel.fromJson(json).toEntity()))
            .toList();
        final safe = await _withoutQueuedLocalChanges(rows, (m) => m.serverId);
        await _isar.writeTxn(() => _isar.isarExpenses.putAllByServerId(safe));
        return _skippedIds(
            rows.map((m) => m.serverId), safe.map((m) => m.serverId));
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarExpenses.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarExpenses,
        () => _isar.isarExpenses.where().serverIdProperty().findAll(),
        _isar.isarExpenses.deleteAllByServerId,
      ),
    ),
    'purchase_orders': _ChangeHandler(
      apply: (items) async {
        final skipped = <String>{};
        await _isar.writeTxn(() async {
          for (final json in items) {
            final serverPO =
                IsarPurchaseOrder.fromModel(PurchaseOrderModel.fromJson(json));
            final existing = await _isar.isarPurchaseOrders
                .filter()
                .serverIdEqualTo(serverPO.serverId)
                .findFirst();
            if (existing != null && !existing.isSynced) {
              skipped.add(serverPO.serverId);
              continue;
            }
            await _isar.isarPurchaseOrders.putByServerId(serverPO);
          }
        });
        return skipped;
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarPurchaseOrders.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarPurchaseOrders,
        () => _isar.isarPurchaseOrders.where().serverIdProperty().findAll(),
        _isar.isarPurchaseOrders.deleteAllByServerId,
      ),
    ),
    'credit_notes': _ChangeHandler(
      apply: (items) async {
        final rows = items
            .map((json) =>
                IsarCreditNote.fromModel(CreditNoteModel.fromJson(json)))
            .toList();
        final safe = await _withoutQueuedLocalChanges(rows, (m) => m.serverId);
        await _isar.writeTxn(() => _isar.isarCreditNotes.putAllByServerId(safe));
        return _skippedIds(
            rows.map((m) => m.serverId), safe.map((m) => m.serverId));
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarCreditNotes.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarCreditNotes,
        () => _isar.isarCreditNotes.where().serverIdProperty().findAll(),
        _isar.isarCreditNotes.deleteAllByServerId,
      ),
    ),
    'customer_credits': _ChangeHandler(
      apply: (items) async {
        final queued = await _queuedEntityIds();
        final skipped = <String>{};
        final credits = <CustomerCreditModel>[];
        for (final json in items) {
          final credit = CustomerCreditModel.fromJson(json);
          if (queued.contains(credit.id)) {
            skipped.add(credit.id);
            continue;
          }
          credits.add(credit);
        }
        // Abonos (vienen con el crédito) e ítems de la factura ya guardados:
        // sin esto, cada descarga borraba el historial del crédito en el equipo.
        final existing = await _isar.isarCustomerCredits
            .getAllByServerId(credits.map((c) => c.id).toList());
        final rows = <IsarCustomerCredit>[];
        for (var i = 0; i < credits.length; i++) {
          rows.add(_isarCreditFromModel(credits[i])
            ..metadataJson = CustomerCreditLocalDataSourceIsar.serializeCreditMetadata(
              credits[i],
              existingMetadataJson: existing[i]?.metadataJson,
            ));
        }
        // Créditos provisionales creados en el equipo por una venta a crédito
        // sin conexión: cuando llega el crédito real de esa factura, el
        // provisional sobra (si no, la deuda aparecería dos veces). Se
        // conservan los que tienen abonos locales aún sin subir.
        final invoiceIds = credits
            .map((c) => c.invoiceId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet();
        final provisional = invoiceIds.isEmpty
            ? const <IsarCustomerCredit>[]
            : await _isar.isarCustomerCredits
                .filter()
                .serverIdStartsWith('credit_offline_')
                .findAll();
        final replaced = provisional
            .where((c) =>
                c.invoiceId != null &&
                invoiceIds.contains(c.invoiceId) &&
                !queued.contains(c.serverId))
            .map((c) => c.id)
            .toList();
        await _isar.writeTxn(() async {
          await _isar.isarCustomerCredits.putAllByServerId(rows);
          if (replaced.isNotEmpty) {
            await _isar.isarCustomerCredits.deleteAll(replaced);
          }
        });
        return skipped;
      },
      delete: (ids) => _deleteServerRows(
          ids, _isar.isarCustomerCredits.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarCustomerCredits,
        () => _isar.isarCustomerCredits.where().serverIdProperty().findAll(),
        _isar.isarCustomerCredits.deleteAllByServerId,
      ),
    ),
    'inventory_batches': _ChangeHandler(
      apply: (items) async {
        // Igual que la descarga completa: si hay ventas/movimientos sin
        // subir, los lotes modificados localmente no se pisan.
        final pendingOps = await IsarDatabase.instance.getPendingSyncOperations();
        final hasPendingInventoryOps = pendingOps.any((op) =>
            op.entityType == 'Invoice' ||
            op.entityType == 'invoice' ||
            op.entityType == 'inventory_movement_fifo' ||
            op.entityType == 'inventory_movement' ||
            op.entityType == 'InventoryMovement' ||
            op.entityType == 'PurchaseOrder' ||
            op.entityType == 'purchase_order' ||
            op.entityType == 'CreditNote' ||
            op.entityType == 'InventoryAdjustment' ||
            op.entityType == 'InventoryTransfer');
        final protected = hasPendingInventoryOps
            ? (await _isar.isarInventoryBatchs
                    .filter()
                    .isSyncedEqualTo(false)
                    .findAll())
                .map((b) => b.serverId)
                .toSet()
            : <String>{};
        final skipped = <String>{};
        final rows = <IsarInventoryBatch>[];
        for (final json in items) {
          final batch = IsarInventoryBatch.fromEntity(
              InventoryBatchModel.fromJson(json).toEntity());
          if (protected.contains(batch.serverId)) {
            skipped.add(batch.serverId);
            continue;
          }
          rows.add(batch);
        }
        if (rows.isNotEmpty) {
          await _isar.writeTxn(
              () => _isar.isarInventoryBatchs.putAllByServerId(rows));
        }
        return skipped;
      },
      delete: (ids) => _deleteServerRows(
          ids, _isar.isarInventoryBatchs.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarInventoryBatchs,
        () => _isar.isarInventoryBatchs.where().serverIdProperty().findAll(),
        _isar.isarInventoryBatchs.deleteAllByServerId,
      ),
    ),
    'inventory_movements': _ChangeHandler(
      apply: (items) async {
        final rows = items
            .map((json) => IsarInventoryMovement.fromModel(
                InventoryMovementModel.fromJson(json)))
            .toList();
        await _isar.writeTxn(
            () => _isar.isarInventoryMovements.putAllByServerId(rows));
        return <String>{};
      },
      delete: (ids) => _deleteServerRows(
          ids, _isar.isarInventoryMovements.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarInventoryMovements,
        () => _isar.isarInventoryMovements.where().serverIdProperty().findAll(),
        _isar.isarInventoryMovements.deleteAllByServerId,
      ),
    ),
    'notifications': _ChangeHandler(
      apply: (items) async {
        final rows = items
            .map((json) =>
                IsarNotification.fromEntity(NotificationModel.fromJson(json)))
            .toList();
        await _isar.writeTxn(
            () => _isar.isarNotifications.putAllByServerId(rows));
        return <String>{};
      },
      delete: (ids) =>
          _deleteServerRows(ids, _isar.isarNotifications.deleteAllByServerId),
      sweep: (seen, cutoff) => _sweepServerRows(
        seen,
        cutoff,
        _isar.isarNotifications,
        () => _isar.isarNotifications.where().serverIdProperty().findAll(),
        _isar.isarNotifications.deleteAllByServerId,
      ),
    ),
  };

  /// Solo para pruebas: corre [syncFn] como el módulo [entityName] de una
  /// sincronización (pull periódico si se pasa [deadline]).
  @visibleForTesting
  Future<int?> debugSyncEntity(
    String entityName,
    Future<int> Function() syncFn, {
    DateTime? deadline,
  }) async =>
      (await _syncEntitySafe(entityName, syncFn, deadline: deadline)).value;

  @visibleForTesting
  int debugStartPage() => _startPage();
  @visibleForTesting
  int debugNextPage(int page) => _nextPage(page);
  @visibleForTesting
  bool debugContinuePaging(int position) => _continuePaging(position);

  _EntityPass? get _currentPass =>
      Zone.current[_EntityPass.zoneKey] as _EntityPass?;

  /// Primera página a pedir. Siempre la 1: así lo más reciente se refresca
  /// en cada pull. Si el módulo había quedado a medias, después de la
  /// primera página [_nextPage] salta a donde quedó.
  int _startPage() => 1;

  /// Siguiente página: después de la primera, salta a donde quedó el pull
  /// anterior (si quedó a medias).
  int _nextPage(int page) {
    final pass = _currentPass;
    final resumeFrom = pass?.resumeFrom;
    if (pass != null && resumeFrom != null) {
      pass.resumeFrom = null;
      if (resumeFrom > page + 1) return resumeFrom;
    }
    return page + 1;
  }

  /// Posición inicial para módulos que recorren una lista local por tandas
  /// (presentaciones, una consulta por producto): sigue donde quedó.
  int _startIndex(int length) {
    final pass = _currentPass;
    final resumeFrom = pass?.resumeFrom;
    if (pass == null || resumeFrom == null) return 0;
    pass.resumeFrom = null;
    return resumeFrom < length ? resumeFrom : 0;
  }

  /// ¿Sigue la descarga del módulo? No, si se pidió abortar o si en un
  /// pull periódico se le acabó el tiempo; en ese caso anota la posición
  /// para continuar en el siguiente pull.
  bool _continuePaging(int position) {
    if (_abortRequested) return false;
    final pass = _currentPass;
    final deadline = pass?.deadline;
    if (pass != null &&
        deadline != null &&
        DateTime.now().isAfter(deadline)) {
      pass.stoppedAt = position;
      return false;
    }
    return true;
  }

  /// Abortar la sincronización en curso
  void abortSync() {
    _abortRequested = true;
  }

  // ==================== SYNC POR ENTIDAD ====================

  /// Sincronizar organización del server a ISAR (single record, not paginated)
  Future<int> _syncOrganization() async {
    final remoteDS = Get.find<OrganizationRemoteDataSource>();
    final offlineRepo = OrganizationOfflineRepository();

    final orgModel = await remoteDS.getCurrentOrganization();

    // Si el dueño cambió la configuración en este equipo y aún no sube (p. ej.
    // sin internet), lo del servidor es la versión VIEJA: no pisarla.
    if (await OrganizationController.hasPendingLocalChanges()) {
      debugPrint('[FULL_SYNC] Organización con cambios locales pendientes — no se sobrescribe');
      return 1;
    }
    await offlineRepo.cacheOrganization(orgModel);

    // Aplicar de inmediato en toda la app (tasas de cambio, monedas, zona
    // horaria...), sin esperar a que la descarga termine o "detecte cambios".
    try {
      if (Get.isRegistered<OrganizationController>()) {
        Get.find<OrganizationController>().applyOrganization(orgModel);
      }
    } catch (e) {
      debugPrint('[FULL_SYNC] No se pudo aplicar la organización en memoria: $e');
    }

    return 1;
  }

  /// Sincronizar suscripción del server a ISAR (single record)
  Future<int> _syncSubscription() async {
    final remoteDS = Get.isRegistered<SubscriptionRemoteDataSource>()
        ? Get.find<SubscriptionRemoteDataSource>()
        : SubscriptionRemoteDataSourceImpl(dioClient: Get.find<DioClient>());

    final subscriptionModel = await remoteDS.getCurrentSubscription();
    final entity = subscriptionModel.toEntity();
    final isarSub = IsarSubscription.fromEntity(entity);

    await _isar.writeTxn(() async {
      await _isar.isarSubscriptions.putByServerId(isarSub);
    });

    return 1;
  }

  /// Sincronizar preferencias del usuario del server a ISAR (single record)
  Future<int> _syncUserPreferences() async {
    try {
      final remoteDS = Get.find<UserPreferencesRemoteDataSource>();
      final localDS = Get.find<UserPreferencesLocalDataSource>();

      final prefsModel = await remoteDS.getUserPreferences();
      await localDS.cacheUserPreferences(prefsModel);

      // Actualizar controller en memoria si está registrado
      try {
        if (Get.isRegistered<UserPreferencesController>()) {
          Get.find<UserPreferencesController>().loadUserPreferences();
        }
      } catch (_) {}

      return 1;
    } catch (e) {

      return 0;
    }
  }

  /// Sincronizar categorías del server a ISAR
  Future<int> _syncCategories() async {
    final remoteDS = Get.find<CategoryRemoteDataSource>();
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getCategories(
        CategoryQueryModel(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarCategory.fromModel(model);
        }).toList();
        await _isar.isarCategorys.putAllByServerId(
          await _withoutQueuedLocalChanges(isarModels, (m) => m.serverId),
        );
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar categorías de gastos del server a SecureStorage (vía ExpenseLocalDataSource)
  Future<int> _syncExpenseCategories() async {
    final remoteDS = Get.find<ExpenseRemoteDataSource>();
    final localDS = Get.find<ExpenseLocalDataSource>();
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;
    final allCategories = <dynamic>[];

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getExpenseCategories(
        page: page,
        limit: _pageSize,
      );

      if (response.data.isEmpty) break;

      allCategories.addAll(response.data);
      totalSynced += response.data.length;
      hasMore = response.meta?.hasNextPage ?? false;
      page = _nextPage(page);
    }

    // Preservar categorías offline con sync pendiente
    try {
      final isarDb = IsarDatabase.instance;
      final pendingOps = await isarDb.getPendingSyncOperations();
      final pendingCategoryIds = pendingOps
          .where((op) => op.entityType == 'ExpenseCategory' || op.entityType == 'expense_category')
          .map((op) => op.entityId)
          .toSet();

      if (pendingCategoryIds.isNotEmpty) {
        final cachedCategories = await localDS.getCachedExpenseCategories();
        final offlineCategories = cachedCategories
            .where((c) => c.id.startsWith('expense_category_offline_') &&
                          pendingCategoryIds.contains(c.id))
            .toList();

        if (offlineCategories.isNotEmpty) {
          allCategories.addAll(offlineCategories);

        }
      }
    } catch (e) {

    }

    // Cachear todas las categorías (servidor + offline pendientes)
    if (allCategories.isNotEmpty) {
      await localDS.cacheExpenseCategories(
        allCategories.cast(),
      );
    }

    return totalSynced;
  }

  /// Sincronizar productos del server a ISAR
  Future<int> _syncProducts() async {
    final remoteDS = Get.find<ProductRemoteDataSource>();
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    // Antes de construir el set de protección, sanamos productos que quedaron
    // bloqueados como isSynced=false sin ninguna op pendiente que los justifique.
    // Esto corrige el bug donde facturas offline que ya sincronizaron fallaron
    // al resetear el flag, dejando los productos protegidos para siempre.
    await _healStuckProducts();

    // Proteger productos con cambios locales pendientes de PUSH (ej: stock
    // descontado por una factura offline o por una merma offline). Sin esta
    // protección, el PULL pisa los stocks locales con los del servidor y el
    // descuento offline "se deshace" en pantalla.
    //
    // IMPORTANTE: solo se protegen productos con `serverId` REAL (UUID).
    // Los productos creados offline (`product_offline_*`) NO entran a este
    // skip — esa fue la causa del bug del revert 367d638 (productos
    // offline desaparecían). Esos siguen el flujo normal de upsert: cuando
    // el handler de CREATE termina exitoso, su `serverId` ya es UUID real
    // y este skip empieza a protegerlos en el siguiente PULL.
    final unsyncedProducts = await _isar.isarProducts
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    final protectedServerIds = unsyncedProducts
        .where((p) => !p.serverId.startsWith('product_offline_'))
        .map((p) => p.serverId)
        .toSet();

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getProducts(
        ProductQueryModel(page: page, limit: _pageSize, includePrices: true, includeCategory: true),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        for (final model in response.data) {
          // Skip productos con cambios locales pendientes (UUID real + isSynced=false)
          if (protectedServerIds.contains(model.id)) continue;
          final isarModel = IsarProduct.fromModel(model);
          await _isar.isarProducts.putByServerId(isarModel);
        }
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sana productos que quedaron bloqueados como [isSynced=false] sin tener
  /// ninguna operación pendiente en SyncQueue que justifique esa protección.
  ///
  /// Esto ocurre cuando el handler de Invoice sync falla al resetear el flag
  /// después de sincronizar la factura. Sin este sanador, esos productos
  /// nunca se actualizan desde el servidor — el stock mostrado queda congelado.
  ///
  /// Criterio de liberación: UUID real (no `product_offline_`) + isSynced=false
  /// + sin ninguna op de tipo Invoice/CreditNote/inventory_movement_fifo que
  /// referencie ese productId en su payload.
  Future<int> _healStuckProducts() async {
    try {
      // Candidatos: productos con isSynced=false y serverId UUID real
      final unsyncedProducts = await _isar.isarProducts
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final candidates = unsyncedProducts
          .where((p) => !p.serverId.startsWith('product_offline_'))
          .toList();

      if (candidates.isEmpty) return 0;

      // Todas las ops NO completadas que pueden afectar stock
      final allOps = await _isar.syncOperations
          .filter()
          .not()
          .statusEqualTo(SyncStatus.completed)
          .findAll();
      final pendingStockOps = allOps.where((op) =>
          op.status != SyncStatus.completed &&
          (op.entityType == 'Invoice' ||
           op.entityType == 'CreditNote' ||
           op.entityType == 'inventory_movement_fifo' ||
           op.entityType == 'InventoryAdjustment' ||
           op.entityType == 'InventoryTransfer')).toList();

      // Extraer productIds activamente referenciados en esas ops
      final activeProductIds = <String>{};
      for (final op in pendingStockOps) {
        try {
          final payload = jsonDecode(op.payload) as Map<String, dynamic>;
          // Invoice / CreditNote: items[].productId
          if (payload['items'] is List) {
            for (final item in payload['items'] as List) {
              if (item is Map && item['productId'] is String) {
                activeProductIds.add(item['productId'] as String);
              }
            }
          }
          // inventory_movement_fifo: productId al nivel raíz
          if (payload['productId'] is String) {
            activeProductIds.add(payload['productId'] as String);
          }
        } catch (_) {}
      }

      // Liberar productos bloqueados sin justificación
      final stuck = candidates
          .where((p) => !activeProductIds.contains(p.serverId))
          .toList();

      if (stuck.isEmpty) return 0;

      await _isar.writeTxn(() async {
        for (final p in stuck) {
          p.isSynced = true;
          p.lastSyncAt = DateTime.now();
          await _isar.isarProducts.put(p);
        }
      });

      return stuck.length;
    } catch (e) {

      return 0;
    }
  }

  /// Sincronizar presentaciones de productos del server a ISAR.
  ///
  /// No hay endpoint global, así que iteramos por cada producto ya guardado en
  /// ISAR. Para no saturar el servidor procesamos en chunks de 20 en paralelo.
  /// Respetamos isSynced=false: las presentaciones con cambios pendientes de PUSH
  /// NO se sobreescriben con datos del servidor.
  Future<int> _syncProductPresentations() async {
    final remoteDS = _getOrCreateDS<ProductPresentationRemoteDataSource>(
      () => ProductPresentationRemoteDataSourceImpl(
        dioClient: Get.find<DioClient>(),
      ),
    );

    // Obtener todos los productos ya sincronizados (con serverId real = UUID).
    //
    // Excluimos:
    //  - product_offline_*  → todavía no llegan al server, no tienen presentaciones
    //  - cualquier serverId que NO sea UUID  → la colección isarProducts también
    //    contiene un registro especial con serverId='STATS_CACHE' que guarda
    //    metadata de estadísticas (ver product_local_datasource_isar.dart). El
    //    backend rechaza con 400 "Validation failed (uuid is expected)" si le
    //    pasamos ese ID al endpoint de presentaciones, contaminando los logs y
    //    desperdiciando una request en cada pull periódico.
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final allProducts = await _isar.isarProducts.where().findAll();
    final syncedProducts = allProducts
        .where((p) => uuidPattern.hasMatch(p.serverId))
        .toList();

    if (syncedProducts.isEmpty) return 0;

    // IDs de presentaciones con cambios pendientes de PUSH (no sobreescribir)
    final unsyncedPresentations = await _isar.isarProductPresentations
        .filter()
        .isSyncedEqualTo(false)
        .findAll();
    final unsyncedServerIds =
        unsyncedPresentations.map((p) => p.serverId).toSet();

    int totalSynced = 0;
    const int chunkSize = 20;

    for (int i = _startIndex(syncedProducts.length);
        i < syncedProducts.length && _continuePaging(i);
        i += chunkSize) {
      final chunk = syncedProducts.sublist(
        i,
        (i + chunkSize).clamp(0, syncedProducts.length),
      );

      final results = await Future.wait(
        chunk.map((product) async {
          try {
            final models = await remoteDS.getPresentations(product.serverId);
            if (models.isEmpty) return 0;

            await _isar.writeTxn(() async {
              for (final model in models) {
                // Skip local-pending-push records
                if (unsyncedServerIds.contains(model.id)) continue;

                final isarPresentation = IsarProductPresentation.fromModel(model);
                await _isar.isarProductPresentations
                    .putByServerId(isarPresentation);
              }
            });
            return models.length;
          } catch (e) {
            return 0;
          }
        }),
      );

      totalSynced += results.fold<int>(0, (sum, n) => sum + n);
    }

    return totalSynced;
  }

  /// Sincronizar clientes del server a ISAR
  Future<int> _syncCustomers() async {
    final remoteDS = _getOrCreateDS<CustomerRemoteDataSource>(
      () => CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getCustomers(
        CustomerQueryModel(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarCustomer.fromModel(model);
        }).toList();
        await _isar.isarCustomers.putAllByServerId(
          await _withoutQueuedLocalChanges(isarModels, (m) => m.serverId),
        );
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar proveedores del server a ISAR
  Future<int> _syncSuppliers() async {
    final remoteDS = _getOrCreateDS<SupplierRemoteDataSource>(
      () => SupplierRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getSuppliers(
        SupplierQueryParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarSupplier.fromModel(model);
        }).toList();
        await _isar.isarSuppliers.putAllByServerId(
          await _withoutQueuedLocalChanges(isarModels, (m) => m.serverId),
        );
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar facturas del server a ISAR
  Future<int> _syncInvoices() async {
    final remoteDS = _getOrCreateDS<InvoiceRemoteDataSource>(
      () => InvoiceRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getInvoices(
        InvoiceQueryParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarInvoice.fromModel(model);
        }).toList();
        await _isar.isarInvoices.putAllByServerId(
          await _withoutQueuedLocalChanges(isarModels, (m) => m.serverId),
        );
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar gastos del server a ISAR
  Future<int> _syncExpenses() async {
    final remoteDS = Get.find<ExpenseRemoteDataSource>();
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getExpenses(
        page: page,
        limit: _pageSize,
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        // ExpenseModel extends Expense, so we can pass it directly to fromEntity
        final isarModels = response.data.map((model) {
          return IsarExpense.fromEntity(model.toEntity());
        }).toList();
        await _isar.isarExpenses.putAllByServerId(
          await _withoutQueuedLocalChanges(isarModels, (m) => m.serverId),
        );
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar cuentas bancarias del server a ISAR (no paginado)
  Future<int> _syncBankAccounts() async {
    final remoteDS = Get.find<BankAccountRemoteDataSource>();

    final accounts = await remoteDS.getBankAccounts(includeInactive: true);

    if (accounts.isEmpty) return 0;

    await _isar.writeTxn(() async {
      // BankAccountModel extends BankAccount, so we can pass it to fromEntity
      final isarModels = accounts.map((model) {
        return IsarBankAccount.fromEntity(model.toEntity());
      }).toList();
      await _isar.isarBankAccounts.putAllByServerId(
          await _withoutQueuedLocalChanges(isarModels, (m) => m.serverId),
        );
    });

    return accounts.length;
  }

  /// Sincronizar impresoras del server a ISAR
  Future<int> _syncPrinterSettings() async {
    PrinterSettingsRemoteDataSource remoteDS;
    if (Get.isRegistered<PrinterSettingsRemoteDataSource>()) {
      remoteDS = Get.find<PrinterSettingsRemoteDataSource>();
    } else {
      remoteDS = PrinterSettingsRemoteDataSourceImpl(
        dioClient: Get.find<DioClient>(),
      );
    }

    final printers = await remoteDS.getAllPrinterSettings();

    if (printers.isEmpty) return 0;

    await _isar.writeTxn(() async {
      final isarModels = printers.map((entity) {
        return PrinterSettingsModel.fromEntity(entity);
      }).toList();
      await _isar.printerSettingsModels.putAllByServerId(isarModels);
    });

    return printers.length;
  }

  /// Sincronizar órdenes de compra del server a ISAR
  Future<int> _syncPurchaseOrders() async {
    final remoteDS = _getOrCreateDS<PurchaseOrderRemoteDataSource>(
      () => PurchaseOrderRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getPurchaseOrders(
        PurchaseOrderQueryParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        for (final model in response.data) {
          final serverPO = IsarPurchaseOrder.fromModel(model);
          // No sobreescribir POs locales que tienen cambios sin sincronizar
          final existing = await _isar.isarPurchaseOrders
              .filter()
              .serverIdEqualTo(serverPO.serverId)
              .findFirst();
          if (existing != null && !existing.isSynced) {
            // PO local tiene cambios pendientes - no sobreescribir
            continue;
          }
          await _isar.isarPurchaseOrders.putByServerId(serverPO);
        }
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar notas de crédito del server a ISAR
  Future<int> _syncCreditNotes() async {
    final remoteDS = _getOrCreateDS<CreditNoteRemoteDataSource>(
      () => CreditNoteRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getCreditNotes(
        QueryCreditNotesParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarCreditNote.fromModel(model);
        }).toList();
        await _isar.isarCreditNotes.putAllByServerId(
          await _withoutQueuedLocalChanges(isarModels, (m) => m.serverId),
        );
      });

      totalSynced += response.data.length;
      // CreditNotePaginatedResponseModel.meta es Map<String, dynamic>
      final totalPages = response.meta['totalPages'] as int? ?? 1;
      final hasNextPage = response.meta['hasNextPage'] as bool?;
      // Usar hasNextPage si disponible, sino calcular desde totalPages
      hasMore = hasNextPage ?? (page < totalPages);
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar créditos de clientes del server a ISAR (no paginado)
  /// Quita de [models] los registros que tienen operaciones en la cola de
  /// sincronización (cambios hechos en este dispositivo que el servidor
  /// todavía no conoce).
  ///
  /// La descarga del servidor NUNCA debe pisar un cambio local sin subir:
  /// haría que lo que el usuario acaba de registrar "desaparezca" de la
  /// pantalla hasta que suba. Esos registros se actualizan en el siguiente
  /// pull, cuando su cola ya esté vacía.
  Future<List<T>> _withoutQueuedLocalChanges<T>(
    List<T> models,
    String Function(T model) serverIdOf,
  ) async {
    if (models.isEmpty) return models;
    try {
      final queuedOps = await IsarDatabase.instance.getPendingSyncOperations();
      if (queuedOps.isEmpty) return models;
      final queuedIds = <String>{for (final op in queuedOps) op.entityId};
      final safe = models
          .where((model) => !queuedIds.contains(serverIdOf(model)))
          .toList();
      if (safe.length != models.length) {
        debugPrint(
          '[FULL_SYNC] ${models.length - safe.length} registro(s) con cambios locales pendientes — no se sobrescriben',
        );
      }
      return safe;
    } catch (e) {
      debugPrint('[FULL_SYNC] No se pudo consultar la cola para proteger cambios locales: $e');
      return models;
    }
  }

  Future<int> _syncCustomerCredits() async {
    final remoteDS = _getOrCreateDS<CustomerCreditRemoteDataSource>(
      () => CustomerCreditRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    // getCredits retorna List<CustomerCreditModel> sin paginación
    final credits = await remoteDS.getCredits(null);

    if (credits.isEmpty) return 0;

    // PROTEGER CAMBIOS LOCALES SIN SUBIR: si un crédito tiene operaciones en
    // la cola (abono, aumento de deuda... hechos sin conexión o aún no
    // confirmados), el servidor todavía no conoce ese cambio. Sobrescribirlo aquí haría "desaparecer" el abono
    // de la pantalla hasta que se suba. Se actualiza en el siguiente pull,
    // cuando su cola ya esté vacía.
    final queuedOps = await IsarDatabase.instance.getPendingSyncOperations();
    final protectedCreditIds = <String>{
      for (final op in queuedOps)
        if (op.entityType == 'CustomerCredit' ||
            op.entityType == 'customer_credit')
          op.entityId,
    };
    final creditsToWrite = credits
        .where((credit) => !protectedCreditIds.contains(credit.id))
        .toList();
    if (creditsToWrite.isEmpty) return credits.length;

    await _isar.writeTxn(() async {
      final isarModels = creditsToWrite.map(_isarCreditFromModel).toList();
      await _isar.isarCustomerCredits.putAllByServerId(isarModels);
    });

    return credits.length;
  }

  /// Sincronizar lotes de inventario del server a ISAR (no paginado por API, pero con params de paginación)
  Future<int> _syncInventoryBatches() async {
    // InventoryRemoteDataSourceImpl uses Dio directly (not DioClient)
    final remoteDS = _getOrCreateDS<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
    );
    return _syncInventoryBatchesWithDS(remoteDS);
  }

  Future<int> _syncInventoryBatchesWithDS(InventoryRemoteDataSource remoteDS) async {
    int totalSynced = 0;
    int skippedUnsync = 0;
    int page = _startPage();

    // Determinar si hay operaciones de inventario pendientes de sync.
    // Si hay Invoices/FIFO pendientes, las deducciones locales aún no se reflejan
    // en el servidor → NO sobrescribir batches modificados localmente.
    // Si no hay pendientes, el servidor ya tiene los valores correctos → seguro sobrescribir.
    final pendingOps = await IsarDatabase.instance.getPendingSyncOperations();
    final hasPendingInventoryOps = pendingOps.any((op) =>
        op.entityType == 'Invoice' ||
        op.entityType == 'invoice' ||
        op.entityType == 'inventory_movement_fifo' ||
        op.entityType == 'inventory_movement' ||
        op.entityType == 'InventoryMovement' ||
        op.entityType == 'PurchaseOrder' ||
        op.entityType == 'purchase_order' ||
        op.entityType == 'CreditNote' ||
        op.entityType == 'InventoryAdjustment' ||
        op.entityType == 'InventoryTransfer');

    Set<String> unsyncedServerIds = {};
    if (hasPendingInventoryOps) {
      // Hay ops pendientes que afectan inventario → proteger batches locales
      final unsyncedBatches = await _isar.isarInventoryBatchs
          .filter()
          .isSyncedEqualTo(false)
          .findAll();
      unsyncedServerIds = unsyncedBatches.map((b) => b.serverId).toSet();
    }

    // getBatches devuelve List<Map<String, dynamic>>
    // Paginar manualmente ya que el endpoint acepta page/limit
    while (_continuePaging(page)) {
      final batchMaps = await remoteDS.getBatches(
        page: page,
        limit: _pageSize,
      );

      if (batchMaps.isEmpty) break;

      // Separar batches seguros de sobrescribir vs protegidos
      final toUpsert = <IsarInventoryBatch>[];
      for (final map in batchMaps) {
        final entity = InventoryBatchModel.fromJson(map).toEntity();
        final serverBatch = IsarInventoryBatch.fromEntity(entity);

        if (unsyncedServerIds.contains(serverBatch.serverId)) {
          // Batch tiene cambios locales pendientes de sync → preservar
          skippedUnsync++;
          continue;
        }

        toUpsert.add(serverBatch);
      }

      if (toUpsert.isNotEmpty) {
        await _isar.writeTxn(() async {
          await _isar.isarInventoryBatchs.putAllByServerId(toUpsert);
        });
      }

      totalSynced += batchMaps.length;

      // Si recibimos menos de _pageSize, no hay más páginas.
      // Caso borde: si último lote tiene exactamente _pageSize items,
      // hará 1 request extra que retorna vacío → break en isEmpty check arriba.
      if (batchMaps.length < _pageSize) break;
      page = _nextPage(page);
    }

    if (skippedUnsync > 0) {

    }

    return totalSynced;
  }

  /// Sincronizar movimientos de inventario del server a ISAR
  Future<int> _syncInventoryMovements() async {
    final remoteDS = _getOrCreateDS<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
    );
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getMovements(
        InventoryMovementQueryParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarInventoryMovement.fromModel(model);
        }).toList();
        await _isar.isarInventoryMovements.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar notificaciones del server a ISAR
  Future<int> _syncNotifications() async {
    final remoteDS = _getOrCreateDS<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = _startPage();
    bool hasMore = true;

    while (hasMore && _continuePaging(page)) {
      final response = await remoteDS.getNotifications(
        NotificationQueryModel(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          // NotificationModel extends Notification (domain entity)
          return IsarNotification.fromEntity(model);
        }).toList();
        await _isar.isarNotifications.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page = _nextPage(page);
    }

    return totalSynced;
  }

  /// Sincronizar almacenes del server a SecureStorage + memory cache
  /// SecureStorage puede fallar en macOS (-34018), por eso también actualizamos
  /// el cache estático en memoria del datasource ISAR.
  Future<int> _syncWarehouses() async {
    final remoteDS = _getOrCreateDS<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
    );

    final warehouseModels = await remoteDS.getWarehouses();
    if (warehouseModels.isEmpty) return 0;

    // 1. Guardar en memory cache estático (siempre funciona, persiste dentro de la sesión)
    InventoryLocalDataSourceIsar.setWarehousesMemoryCache(warehouseModels);

    // 2. Persistir en SharedPreferences (confiable en macOS, a diferencia de SecureStorage)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': warehouseModels.map((w) => w.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('inventory_warehouses_cache', jsonEncode(cacheData));
    } catch (e) {

    }

    return warehouseModels.length;
  }

  // ==================== CLEANUP ====================

  /// Limpia registros ISAR huérfanos con IDs temporales de TODAS las entidades.
  /// Estos son registros creados offline cuyo sync handler antiguo no actualizó
  /// el serverId con el ID real del servidor después de crear exitosamente.
  Future<void> _cleanupOrphanedRecords() async {
    try {

      final isarDb = IsarDatabase.instance;

      // CRÍTICO: incluir tanto operaciones PENDING como FAILED. Sin esto,
      // si una factura offline tiene sync fallido (ej. backend rechazó
      // por validación de caja), su operación queda en estado `failed`
      // y NO aparece en `getPendingSyncOperations()`. El cleanup la
      // consideraba huérfana y la borraba → pérdida silenciosa de datos
      // del usuario. Ahora una factura offline con cualquier operación
      // en cola (pending o failed) se preserva.
      final pendingOps = await isarDb.getPendingSyncOperations();
      final failedOps = await isarDb.getFailedSyncOperations();
      final pendingEntityIds = <String>{
        ...pendingOps.map((op) => op.entityId),
        ...failedOps.map((op) => op.entityId),
      };

      int totalCleaned = 0;

      // Expenses: prefix 'expense_offline_'
      totalCleaned += await _cleanupEntity<IsarExpense>(
        collection: _isar.isarExpenses,
        prefix: 'expense_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Customers: prefix 'customer_'
      totalCleaned += await _cleanupEntity<IsarCustomer>(
        collection: _isar.isarCustomers,
        prefix: 'customer_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Suppliers: prefix 'supplier_'
      totalCleaned += await _cleanupEntity<IsarSupplier>(
        collection: _isar.isarSuppliers,
        prefix: 'supplier_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Categories: prefix 'category_offline_'
      totalCleaned += await _cleanupEntity<IsarCategory>(
        collection: _isar.isarCategorys,
        prefix: 'category_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Invoices: prefix 'invoice_offline_' (creado por invoice_offline_repository_simple)
      totalCleaned += await _cleanupEntity<IsarInvoice>(
        collection: _isar.isarInvoices,
        prefix: 'invoice_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );
      // Invoices: prefix legacy 'inv_' (por si existen registros con este prefijo)
      totalCleaned += await _cleanupEntity<IsarInvoice>(
        collection: _isar.isarInvoices,
        prefix: 'inv_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Bank Accounts: prefix 'bank_'
      totalCleaned += await _cleanupEntity<IsarBankAccount>(
        collection: _isar.isarBankAccounts,
        prefix: 'bank_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Purchase Orders: prefix 'po_offline_'
      totalCleaned += await _cleanupEntity<IsarPurchaseOrder>(
        collection: _isar.isarPurchaseOrders,
        prefix: 'po_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Credit Notes: prefix 'creditnote_offline_'
      totalCleaned += await _cleanupEntity<IsarCreditNote>(
        collection: _isar.isarCreditNotes,
        prefix: 'creditnote_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Inventory Movements: prefix 'movement_'
      totalCleaned += await _cleanupEntity<IsarInventoryMovement>(
        collection: _isar.isarInventoryMovements,
        prefix: 'movement_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Inventory Batches: prefix 'batch_offline_'
      // Manejo especial: no borrar si el PO relacionado aún está pendiente de sync
      totalCleaned += await _cleanupBatchOfflineRecords(pendingEntityIds);

      // Products: prefix 'product_offline_'
      totalCleaned += await _cleanupEntity<IsarProduct>(
        collection: _isar.isarProducts,
        prefix: 'product_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Product Presentations: prefix 'presentation_offline_'
      totalCleaned += await _cleanupEntity<IsarProductPresentation>(
        collection: _isar.isarProductPresentations,
        prefix: 'presentation_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // Customer Credits: prefix 'customercredit_offline_'
      totalCleaned += await _cleanupEntity<IsarCustomerCredit>(
        collection: _isar.isarCustomerCredits,
        prefix: 'customercredit_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      // PO Items huérfanos: items cuyo purchaseOrderServerId no corresponde
      // a ningún PO existente (ej. cambio de tenant)
      totalCleaned += await _cleanupOrphanedPOItems();

      if (totalCleaned > 0) {

      } else {

      }
    } catch (e) {

    }
  }

  /// Limpia batches offline huérfanos con manejo especial para POs pendientes.
  /// No borra batches cuyo purchaseOrderId corresponda a un PO aún en cola de sync.
  Future<int> _cleanupBatchOfflineRecords(Set<String> pendingEntityIds) async {
    try {
      final offlineBatches = await _isar.isarInventoryBatchs
          .filter()
          .serverIdStartsWith('batch_offline_')
          .findAll();

      if (offlineBatches.isEmpty) return 0;

      // Filtrar: preservar batches cuyo PO está pendiente de sync
      final toDelete = offlineBatches.where((b) {
        // Si el batch tiene un purchaseOrderId que está pendiente, preservar
        if (b.purchaseOrderId != null &&
            b.purchaseOrderId!.isNotEmpty &&
            pendingEntityIds.contains(b.purchaseOrderId)) {
          return false; // PO aún pendiente, no borrar
        }
        return true; // Seguro de borrar
      }).toList();

      if (toDelete.isEmpty) return 0;

      await _isar.writeTxn(() async {
        await _isar.isarInventoryBatchs
            .deleteAll(toDelete.map((b) => b.id).toList());
      });

      return toDelete.length;
    } catch (e) {

      return 0;
    }
  }

  /// Limpia PO items huérfanos: items cuyo purchaseOrderServerId no corresponde
  /// a ningún PO existente en ISAR. Esto ocurre tras cambio de tenant.
  Future<int> _cleanupOrphanedPOItems() async {
    try {
      final allItems = await _isar.isarPurchaseOrderItems.where().findAll();
      if (allItems.isEmpty) return 0;

      // Obtener todos los serverIds de POs existentes (solo ese campo)
      final existingPOIds = (await _isar.isarPurchaseOrders
              .where()
              .serverIdProperty()
              .findAll())
          .toSet();

      // Items cuyo PO padre ya no existe
      final orphaned = allItems.where((item) =>
        item.purchaseOrderServerId == null ||
        item.purchaseOrderServerId!.isEmpty ||
        !existingPOIds.contains(item.purchaseOrderServerId)
      ).toList();

      if (orphaned.isEmpty) return 0;

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrderItems
            .deleteAll(orphaned.map((i) => i.id).toList());
      });

      return orphaned.length;
    } catch (e) {

      return 0;
    }
  }

  /// Limpia registros huérfanos de una colección ISAR específica
  Future<int> _cleanupEntity<T>({
    required IsarCollection<T> collection,
    required String prefix,
    required Set<String> pendingIds,
    required String Function(T) getServerId,
    required int Function(T) getId,
  }) async {
    try {
      // La base filtra por dentro y solo devuelve los registros temporales.
      // Antes se cargaban TODOS los registros (facturas, movimientos…) en
      // cada descarga periódica para quedarse con unos pocos, y eso trababa
      // el equipo cada minuto.
      final candidates = await collection
          .buildQuery<T>(
            filter: FilterCondition.startsWith(
              property: 'serverId',
              value: prefix,
            ),
          )
          .findAll();
      final orphaned = candidates
          .where((r) => getServerId(r).startsWith(prefix))
          .where((r) => !pendingIds.contains(getServerId(r)))
          .toList();

      if (orphaned.isEmpty) return 0;

      await _isar.writeTxn(() async {
        await collection.deleteAll(orphaned.map(getId).toList());
      });

      return orphaned.length;
    } catch (e) {

      return 0;
    }
  }

  // ==================== HELPERS ====================

  /// Obtiene un remote datasource de GetX si está registrado, o lo crea con el factory
  T _getOrCreateDS<T>(T Function() factory) {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
    } catch (_) {}
    return factory();
  }

  /// Mapear CreditStatus a IsarCreditStatus
  IsarCreditStatus _mapCreditStatus(dynamic status) {
    final statusStr = status.toString().split('.').last.toLowerCase();
    switch (statusStr) {
      case 'pending':
        return IsarCreditStatus.pending;
      case 'partiallypaid':
        return IsarCreditStatus.partiallyPaid;
      case 'paid':
        return IsarCreditStatus.paid;
      case 'cancelled':
        return IsarCreditStatus.cancelled;
      case 'overdue':
        return IsarCreditStatus.overdue;
      default:
        return IsarCreditStatus.pending;
    }
  }
}

/// Estado de la descarga de un módulo dentro de una sincronización.
/// Viaja en la zona de la descarga para que los ciclos de paginación sepan
/// cuándo detenerse y desde dónde seguir.
class _EntityPass {
  static const Object zoneKey = #fullSyncEntityPass;

  /// Hasta cuándo puede descargar (solo pulls periódicos).
  final DateTime? deadline;

  /// Posición donde quedó el pull anterior, si quedó a medias.
  int? resumeFrom;

  /// Posición donde se detuvo por tiempo en este pull.
  int? stoppedAt;

  _EntityPass({this.deadline, this.resumeFrom});
}

/// Qué hacer con los registros de una entidad en la descarga incremental.
class _ChangeHandler {
  /// Guarda los registros recibidos; devuelve los IDs que NO se guardaron
  /// por tener cambios locales sin subir.
  final Future<Set<String>> Function(List<Map<String, dynamic>> items) apply;

  /// Quita las copias locales de registros borrados en el servidor.
  final Future<int> Function(List<String> ids) delete;

  /// Tras una descarga completa, quita las copias locales que no llegaron
  /// (y que no cambiaron desde [cutoff], el inicio de la descarga).
  final Future<int> Function(Set<String> seen, DateTime cutoff) sweep;

  const _ChangeHandler({
    required this.apply,
    required this.delete,
    required this.sweep,
  });
}

/// Estado de una descarga incremental en curso (puede repartirse en varios
/// pulls si se agota el tiempo).
class _ChangesProgress {
  final String organization;
  final bool isFullDownload;
  String since;
  String? afterId;

  /// Marca que entregó el servidor en la primera página.
  String? watermark;

  /// `updated_at` más antiguo de los registros que no se aplicaron.
  String? earliestSkipped;

  /// IDs recibidos (solo en descarga completa, para la limpieza final).
  final Set<String> seen = {};

  /// Descarga completa: antes del histórico (que va de lo más viejo a lo
  /// más nuevo) se bajan los últimos días, para que las ventas de hoy estén
  /// en pantalla de inmediato. Cursor propio de esa fase.
  bool recentDone = false;
  String? recentSince;
  String? recentAfterId;

  /// La limpieza final (quitar lo que no llegó) solo es válida si todos los
  /// IDs se vieron en esta misma ejecución. Si la descarga se reanudó tras
  /// reiniciar la app, no se tienen los IDs anteriores y no se limpia.
  bool sweepValid = true;

  /// Cuándo empezó esta descarga en el equipo (respaldo del corte de la
  /// limpieza si el servidor no entregó marca).
  final DateTime startedAt = DateTime.now();

  _ChangesProgress({
    required this.organization,
    required this.since,
    bool? isFullDownload,
  }) : isFullDownload = isFullDownload ?? since == SyncChangesClient.epoch;

  Map<String, dynamic> toJson() => {
        'organization': organization,
        'isFullDownload': isFullDownload,
        'since': since,
        'afterId': afterId,
        'watermark': watermark,
        'earliestSkipped': earliestSkipped,
        'recentDone': recentDone,
        'recentSince': recentSince,
        'recentAfterId': recentAfterId,
      };

  /// Avance guardado antes de cerrar la app. Los IDs vistos no se guardan
  /// (pueden ser decenas de miles), así que no habrá limpieza final.
  static _ChangesProgress? fromJson(Map<String, dynamic> json) {
    final organization = json['organization'] as String?;
    final since = json['since'] as String?;
    if (organization == null || since == null) return null;
    return _ChangesProgress(
      organization: organization,
      since: since,
      isFullDownload: json['isFullDownload'] == true,
    )
      ..afterId = json['afterId'] as String?
      ..watermark = json['watermark'] as String?
      ..earliestSkipped = json['earliestSkipped'] as String?
      ..recentDone = json['recentDone'] == true
      ..recentSince = json['recentSince'] as String?
      ..recentAfterId = json['recentAfterId'] as String?
      ..sweepValid = false;
  }

  void noteSkipped(String stamp) {
    final current = earliestSkipped;
    if (current == null) {
      earliestSkipped = stamp;
      return;
    }
    final a = DateTime.tryParse(stamp);
    final b = DateTime.tryParse(current);
    if (a != null && b != null && a.isBefore(b)) earliestSkipped = stamp;
  }
}

/// Estado de descarga de un módulo, para Diagnóstico.
class ModuleDownloadStatus {
  final String label;
  final String entity;
  final bool downloaded;
  final int pageSize;
  final int defaultPageSize;
  final String? lastError;
  final DateTime? lastErrorAt;
  final DateTime? lastOkAt;

  const ModuleDownloadStatus({
    required this.label,
    required this.entity,
    required this.downloaded,
    required this.pageSize,
    required this.defaultPageSize,
    this.lastError,
    this.lastErrorAt,
    this.lastOkAt,
  });

  bool get slowNetwork => pageSize < defaultPageSize;
}
