import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import '../../core/network/network_info.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import 'isar_database.dart';
import 'sync_queue.dart';
import 'sync_config.dart';
import 'sync_lock.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../core/errors/exceptions.dart';
import '../../core/services/idempotency_service.dart';
import '../../core/services/conflict_resolution_service.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/widgets/subscription_error_dialog.dart';

// Products
import '../../../features/products/data/datasources/product_remote_datasource.dart';
import '../../../features/products/data/models/create_product_request_model.dart';
import '../../../features/products/data/models/update_product_request_model.dart';
import '../../../features/products/data/repositories/product_offline_repository.dart';
import '../../../features/products/data/models/isar/isar_product.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../features/products/domain/entities/product_price.dart';
import '../../../features/products/domain/entities/tax_enums.dart';
import '../../../features/products/domain/repositories/product_repository.dart'
    show CreateProductPriceParams;

// Categories
import '../../../features/categories/data/datasources/category_remote_datasource.dart';
import '../../../features/categories/data/datasources/category_local_datasource.dart';
import '../../../features/categories/data/models/create_category_request_model.dart';
import '../../../features/categories/data/models/update_category_request_model.dart';
import '../../../features/categories/data/models/isar/isar_category.dart';
import '../../../features/categories/domain/entities/category.dart';
import '../../../features/categories/data/repositories/category_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Customers
import '../../../features/customers/data/datasources/customer_remote_datasource.dart';
import '../../../features/customers/data/models/create_customer_request_model.dart';
import '../../../features/customers/data/models/update_customer_request_model.dart';
import '../../../features/customers/data/models/isar/isar_customer.dart';
import '../../../features/customers/data/repositories/customer_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Suppliers
import '../../../features/suppliers/data/datasources/supplier_remote_datasource.dart';
import '../../../features/suppliers/data/models/create_supplier_request_model.dart';
import '../../../features/suppliers/data/models/update_supplier_request_model.dart';
import '../../../features/suppliers/data/models/isar/isar_supplier.dart';
import '../../../features/suppliers/data/repositories/supplier_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Expenses
import '../../../features/expenses/data/datasources/expense_remote_datasource.dart';
import '../../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../../../features/expenses/data/models/create_expense_request_model.dart';
import '../../../features/expenses/data/models/update_expense_request_model.dart';
import '../../../features/expenses/data/models/create_expense_category_request_model.dart';
import '../../../features/expenses/data/models/isar/isar_expense.dart';
import '../../../features/expenses/domain/entities/expense.dart';
import '../../../features/expenses/data/repositories/expense_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Bank Accounts
import '../../../features/bank_accounts/data/datasources/bank_account_remote_datasource.dart';
import '../../../features/bank_accounts/data/models/bank_account_model.dart';
import '../../../features/bank_accounts/data/models/isar/isar_bank_account.dart';
import '../../../features/bank_accounts/data/repositories/bank_account_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// User Preferences
import '../../../features/settings/presentation/controllers/user_preferences_controller.dart';

// Invoices
import '../../../features/invoices/data/datasources/invoice_remote_datasource.dart';
import '../../../features/invoices/data/models/add_payment_request_model.dart';
import '../../../features/invoices/data/models/create_invoice_request_model.dart';
import '../../../features/invoices/data/models/update_invoice_request_model.dart';
import '../../../features/invoices/data/models/invoice_item_model.dart';
import '../../../features/invoices/data/models/isar/isar_invoice.dart';
import '../../../features/invoices/domain/entities/invoice.dart' show InvoiceStatus;
import 'enums/isar_enums.dart' show IsarInvoiceStatus;
import '../../../features/invoices/data/repositories/invoice_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Purchase Orders
import '../../../features/purchase_orders/data/datasources/purchase_order_remote_datasource.dart';
import '../../../features/purchase_orders/domain/entities/purchase_order.dart';
import '../../../features/purchase_orders/domain/repositories/purchase_order_repository.dart';
import '../../../features/purchase_orders/data/models/isar/isar_purchase_order.dart';
import '../../../features/purchase_orders/data/models/isar/isar_purchase_order_item.dart';
// PurchaseOrderOfflineRepository ya no se usa aquí - lectura directa de ISAR en sync handler

// Inventory
import '../../../features/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../../features/inventory/data/models/inventory_movement_model.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_movement.dart';
import '../../../features/inventory/data/models/isar/isar_inventory_batch.dart';
import '../../../features/inventory/data/repositories/inventory_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Credit Notes
import '../../../features/credit_notes/data/datasources/credit_note_remote_datasource.dart';
import '../../../features/credit_notes/data/models/credit_note_model.dart';
import '../../../features/credit_notes/data/models/credit_note_item_model.dart';
import '../../../features/credit_notes/data/models/isar/isar_credit_note.dart';
import '../../../features/credit_notes/data/repositories/credit_note_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Customer Credits
import '../../../features/customer_credits/data/datasources/customer_credit_remote_datasource.dart';
import '../../../features/customer_credits/data/models/customer_credit_model.dart';
import '../../../features/customer_credits/data/models/isar/isar_customer_credit.dart';
import '../../../features/customer_credits/domain/entities/customer_credit.dart';
import '../../../features/customer_credits/data/repositories/customer_credit_offline_repository.dart'; // ⭐ FASE 1 - Problema 3

// Printer Settings
import '../../../features/settings/data/datasources/printer_settings_remote_datasource.dart';
import '../../../features/settings/data/models/printer_settings_model.dart';

// Settings/Organizations
import '../../../features/settings/data/datasources/organization_remote_datasource.dart';
import '../../../features/settings/data/repositories/organization_offline_repository.dart';

// Auth (User Profile)
import '../../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../features/auth/data/models/update_profile_request_model.dart';

// Notifications
import '../../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../../features/notifications/data/datasources/notification_local_datasource.dart';

// User Preferences
import '../../../features/settings/data/datasources/user_preferences_remote_datasource.dart';
import '../../../features/settings/data/datasources/user_preferences_local_datasource.dart';

// FASE 5: Pull automático al reconectar
import 'full_sync_service.dart';

/// Resultado de una operación de sync individual
enum _SyncOpResult { success, failure, skipped }

/// Estados de sincronización
enum SyncState {
  idle, // Sin sincronización en progreso
  syncing, // Sincronizando actualmente
  error, // Error en sincronización
}

/// Servicio de sincronización offline-first
///
/// Responsabilidades:
/// - Detectar cambios de conectividad (WiFi, Mobile Data, None)
/// - Sincronizar automáticamente cuando vuelve internet
/// - Trackear estado de sincronización
/// - Proveer métodos para sincronización manual
class SyncService extends GetxService {
  final dynamic
  _isarDatabase; // Use dynamic to support both IsarDatabase and MockIsarDatabase
  final Connectivity _connectivity = Connectivity();

  // Guard: pausar pull periódico cuando hay formularios activos
  static int _activeFormCount = 0;
  static void notifyFormOpened() => _activeFormCount++;
  static void notifyFormClosed() {
    if (_activeFormCount > 0) _activeFormCount--;
  }
  static bool get hasActiveForm => _activeFormCount > 0;

  // Mapeo temp→real IDs para resolver referencias entre sesiones
  static final Map<String, String> _tempToRealIdMap = {};
  static const String _tempIdMapPrefix = 'temp_id_map_';

  // Cuando el backend responde 403 por suscripción expirada, pausamos el sync
  // completo por un rato. Evita reintentar 10 veces cada operación offline
  // (productos, facturas, etc.) y spam al backend. Se re-arma automáticamente
  // al vencer el timeout. `resetSubscriptionBlock()` debe llamarse cuando el
  // usuario renueva su plan.
  static DateTime? _subscriptionBlockedUntil;
  static bool _subscriptionDialogShown = false;
  static const Duration _subscriptionBlockDuration = Duration(minutes: 30);

  /// Llamar cuando el usuario renueva su suscripción para reanudar sync
  /// inmediatamente (en vez de esperar los 30 min del bloqueo).
  static void resetSubscriptionBlock() {
    _subscriptionBlockedUntil = null;
    _subscriptionDialogShown = false;
  }

  /// True si el sync está bloqueado por error de suscripción en curso.
  static bool get isBlockedBySubscription {
    final until = _subscriptionBlockedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Registrar mapeo de temp ID → real ID (persistido en SharedPreferences)
  static Future<void> registerTempIdMapping(String tempId, String realId) async {
    _tempToRealIdMap[tempId] = realId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_tempIdMapPrefix$tempId', realId);
    } catch (_) {}
  }

  /// Buscar ID real para un temp ID (en memoria primero, luego SharedPreferences)
  static Future<String?> lookupTempIdMapping(String tempId) async {
    // Primero buscar en memoria
    if (_tempToRealIdMap.containsKey(tempId)) {
      return _tempToRealIdMap[tempId];
    }
    // Luego en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final realId = prefs.getString('$_tempIdMapPrefix$tempId');
      if (realId != null) {
        _tempToRealIdMap[tempId] = realId; // Cache en memoria
      }
      return realId;
    } catch (_) {
      return null;
    }
  }

  // Estado de conectividad
  final Rx<bool> _isOnline = false.obs;
  bool get isOnline => _isOnline.value;

  // Estado de sincronización
  final Rx<SyncState> _syncState = SyncState.idle.obs;
  SyncState get syncState => _syncState.value;
  Rx<SyncState> get syncStateObs => _syncState;

  // Operaciones pendientes
  final RxInt _pendingOperationsCount = 0.obs;
  int get pendingOperationsCount => _pendingOperationsCount.value;

  // Stream subscription para connectivity
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Timer para sincronización periódica
  Timer? _periodicSyncTimer;

  // Última sincronización
  final Rx<DateTime?> _lastSyncTime = Rx<DateTime?>(null);
  DateTime? get lastSyncTime => _lastSyncTime.value;

  // FASE 5: Última descarga (pull) del servidor - throttle cada 5 minutos
  DateTime? _lastPullTime;

  // 🔒 Lock para prevenir sincronizaciones concurrentes
  final SyncServiceLock _lock = SyncServiceLock();

  // 📊 Estado de salud del sistema de sincronización (observable)
  final Rx<SyncHealthInfo> _healthInfo = Rx<SyncHealthInfo>(
    const SyncHealthInfo(
      status: SyncHealthStatus.healthy,
      pendingCount: 0,
      failedCount: 0,
      permanentlyFailedCount: 0,
      completedCount: 0,
      isOnline: false,
    ),
  );
  SyncHealthInfo get healthInfo => _healthInfo.value;

  // 🚨 Stream de problemas críticos que requieren atención del usuario
  final RxList<SyncIssue> _criticalIssues = <SyncIssue>[].obs;
  List<SyncIssue> get criticalIssues => _criticalIssues;
  bool get hasCriticalIssues => _criticalIssues.isNotEmpty;

  // 📈 Contadores de sesión para métricas
  int _sessionSyncSuccessCount = 0;
  int _sessionSyncFailureCount = 0;
  int _sessionSyncSkippedCount = 0;

  SyncService(this._isarDatabase);

  @override
  Future<void> onInit() async {
    super.onInit();
    AppLogger.i('Inicializando SyncService...', tag: 'SYNC');

    // Verificar conectividad inicial
    await _checkConnectivity();

    // Escuchar cambios de conectividad
    _listenToConnectivityChanges();

    // Actualizar conteo de operaciones pendientes
    await _updatePendingCount();

    // 🧹 LIMPIEZA AUTOMÁTICA: Detectar y eliminar operaciones con categorías offline que no existen
    await _cleanInvalidOfflineReferences();

    // 🗑️ LIMPIEZA ONE-TIME: Eliminar operación rota ID 9 (producto offline que ya fue creado)
    await _cleanupBrokenOperation9();

    // 🔔 LIMPIEZA: Eliminar operaciones de notificaciones dinámicas que no deben sincronizarse
    await _cleanupDynamicNotificationOperations();

    // 🔧 REPARACIÓN: Corregir movimientos de inventario con referenceId temporal
    await _repairMovementsWithTempReferenceId();

    // 🗑️ LIMPIEZA: Eliminar operaciones que excedieron máximo de reintentos
    await cleanPermanentlyFailedOperations();

    // 🔧 REPARACIÓN: Intentar reparar facturas con items vacíos
    await repairInvoiceOperationsWithMissingItems();

    // 🧹 LIMPIEZA: Eliminar batches/productos offline huérfanos que causan stock duplicado
    await _cleanupOrphanedOfflineInventoryRecords();

    // 🧹 LIMPIEZA: Eliminar ops FIFO huérfanas cuya Invoice ya se sincronizó
    await _cleanupOrphanedFifoOperations();

    // Configurar sincronización periódica (cada 5 minutos si hay internet)
    _setupPeriodicSync();

    AppLogger.i('SyncService inicializado', tag: 'SYNC');
    AppLogger.i(
      'Estado inicial: ${isOnline ? "Online" : "Offline"}',
      tag: 'SYNC',
    );
    AppLogger.i('Operaciones pendientes: $pendingOperationsCount', tag: 'SYNC');
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.onClose();
    AppLogger.i('SyncService cerrado', tag: 'SYNC');
  }

  /// Verificar conectividad actual
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline.value;
      _isOnline.value = _hasInternetConnection(results);

      // Si cambia de offline a online, sincronizar
      if (!wasOnline && _isOnline.value) {
        AppLogger.i('Conectividad restaurada', tag: 'SYNC');
        // Solo sincronizar si el usuario está autenticado
        if (await _isUserAuthenticated()) {
          await syncAll();
          await _pullServerChanges();
        } else {
          AppLogger.d('Sync omitido - usuario no autenticado', tag: 'SYNC');
        }
      } else if (wasOnline && !_isOnline.value) {
        AppLogger.i('Conectividad perdida', tag: 'SYNC');
      }
    } catch (e) {
      AppLogger.e('Error verificando conectividad: $e', tag: 'SYNC');
      _isOnline.value = false;
    }
  }

  /// Escuchar cambios de conectividad
  void _listenToConnectivityChanges() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasOnline = _isOnline.value;
        _isOnline.value = _hasInternetConnection(results);

        if (!wasOnline && _isOnline.value) {
          AppLogger.i('Conectividad restaurada: $results', tag: 'SYNC');
          // Solo sincronizar si el usuario está autenticado
          if (await _isUserAuthenticated()) {
            // Resetear cooldown de NetworkInfo para permitir reconexión inmediata
            try {
              final networkInfo = Get.find<NetworkInfo>();
              networkInfo.resetServerReachability();
              AppLogger.i('NetworkInfo cooldown reseteado por restauración de conectividad', tag: 'SYNC');
            } catch (_) {}
            await syncAll();
            await _pullServerChanges();
          } else {
            AppLogger.d('Sync omitido - usuario no autenticado', tag: 'SYNC');
          }
        } else if (wasOnline && !_isOnline.value) {
          AppLogger.i('Conectividad perdida: $results', tag: 'SYNC');
        }
      },
      onError: (error) {
        AppLogger.e('Error en stream de conectividad: $error', tag: 'SYNC');
      },
    );
  }

  /// Verificar si hay conexión a internet
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }

  /// Verificar si el usuario está autenticado (tiene token almacenado)
  Future<bool> _isUserAuthenticated() async {
    try {
      final storage = Get.find<SecureStorageService>();
      return await storage.hasToken();
    } catch (_) {
      return false;
    }
  }

  /// Configurar sincronización periódica optimizada
  /// - Verificación cada 10 segundos para sync ultra-rápido
  void _setupPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(
      const Duration(seconds: 10), // Verificar cada 10 segundos
      (timer) async {
        if (_isOnline.value && _pendingOperationsCount.value > 0) {
          // Si hay operaciones pendientes, verificar si NetworkInfo está en cooldown
          // y resetear si el servidor ya responde
          try {
            final networkInfo = Get.find<NetworkInfo>();
            if (!networkInfo.isServerReachable) {
              final reachable = await networkInfo.canReachServer(
                timeout: const Duration(seconds: 3),
              );
              if (reachable) {
                networkInfo.resetServerReachability();
                AppLogger.i('Servidor recuperado en verificación periódica', tag: 'SYNC');
              } else {
                // Servidor sigue inalcanzable, omitir silenciosamente
                return;
              }
            }
          } catch (_) {}

          AppLogger.d(
            'Sincronización automática iniciada (${_pendingOperationsCount.value} operaciones pendientes)',
            tag: 'SYNC',
          );
          await syncAll();
        }

        // Pull periódico cada ~60s para sincronización multi-usuario
        if (_isOnline.value && _shouldPeriodicPull()) {
          await _periodicPull();
        }
      },
    );
  }

  /// Verifica si es momento de hacer un pull periódico (cada 60s)
  bool _shouldPeriodicPull() {
    // No hacer pull si hay formularios abiertos (evita tráfico innecesario)
    if (hasActiveForm) return false;
    if (_lastPullTime == null) return true;
    return DateTime.now().difference(_lastPullTime!) > const Duration(seconds: 60);
  }

  /// Pull periódico: descarga cambios del servidor y notifica controllers si hay novedades
  Future<void> _periodicPull() async {
    try {
      if (!await _isUserAuthenticated()) return;
      if (!Get.isRegistered<FullSyncService>()) return;

      final fullSyncService = Get.find<FullSyncService>();
      if (fullSyncService.isSyncing.value) return;

      AppLogger.d('Pull periódico multi-usuario iniciado...', tag: 'SYNC');
      _lastPullTime = DateTime.now();

      final result = await fullSyncService.performFullSync(skipCleanup: true);

      if (result.totalSynced > 0) {
        AppLogger.i(
          'Pull periódico: ${result.totalSynced} registros nuevos - notificando controllers',
          tag: 'SYNC',
        );
        // Forzar transición syncing→idle para notificar SyncAutoRefreshMixin en todos los controllers
        _syncState.value = SyncState.syncing;
        await Future.delayed(const Duration(milliseconds: 100));
        _syncState.value = SyncState.idle;
      } else {
        AppLogger.d('Pull periódico: sin cambios del servidor', tag: 'SYNC');
      }
    } catch (e) {
      AppLogger.e('Error en pull periódico: $e', tag: 'SYNC');
    }
  }

  /// Actualizar conteo de operaciones pendientes
  Future<void> _updatePendingCount() async {
    try {
      final pending = await _isarDatabase.getPendingSyncOperations();
      _pendingOperationsCount.value = pending.length;
    } catch (e) {
      AppLogger.e('Error actualizando conteo pendientes: $e', tag: 'SYNC');
    }
  }

  /// 📊 Actualizar información de salud del sistema de sincronización
  Future<void> _updateHealthInfo() async {
    try {
      final stats = await _isarDatabase.getSyncOperationsCounts();
      final failedOperations = await _isarDatabase.getFailedSyncOperations();

      // Contar operaciones permanentemente fallidas
      int permanentlyFailed = 0;
      for (final op in failedOperations) {
        if (op.retryCount >= SyncConfig.maxRetries) {
          permanentlyFailed++;
        }
      }

      // Determinar estado de salud
      SyncHealthStatus status;
      final warnings = <String>[];
      final issues = <SyncIssue>[];

      if (!_isOnline.value) {
        status = SyncHealthStatus.offline;
      } else if (permanentlyFailed >= SyncConfig.criticalThresholdPermanentlyFailed) {
        status = SyncHealthStatus.critical;
        issues.add(SyncIssue(
          code: SyncErrorCodes.maxRetriesExceeded,
          message: '$permanentlyFailed operación(es) no pudieron sincronizarse después de múltiples intentos',
          severity: IssueSeverity.critical,
        ));
      } else if ((stats['failed'] ?? 0) >= SyncConfig.degradedThresholdFailedOps) {
        status = SyncHealthStatus.degraded;
        warnings.add('${stats['failed']} operaciones fallidas pendientes de reintento');
      } else if ((stats['pending'] ?? 0) >= SyncConfig.overloadedThresholdPendingOps) {
        status = SyncHealthStatus.overloaded;
        warnings.add('${stats['pending']} operaciones pendientes en cola');
      } else {
        status = SyncHealthStatus.healthy;
      }

      // Agregar issues existentes de _criticalIssues
      issues.addAll(_criticalIssues);

      _healthInfo.value = SyncHealthInfo(
        status: status,
        pendingCount: stats['pending'] ?? 0,
        failedCount: stats['failed'] ?? 0,
        permanentlyFailedCount: permanentlyFailed,
        completedCount: stats['completed'] ?? 0,
        lastSyncTime: _lastSyncTime.value,
        isOnline: _isOnline.value,
        warnings: warnings,
        issues: issues,
      );
    } catch (e) {
      AppLogger.e('Error actualizando health info: $e', tag: 'SYNC');
      _healthInfo.value = SyncHealthInfo(
        status: SyncHealthStatus.error,
        pendingCount: 0,
        failedCount: 0,
        permanentlyFailedCount: 0,
        completedCount: 0,
        isOnline: _isOnline.value,
        errorMessage: e.toString(),
        issues: const [],
      );
    }
  }

  /// 🚨 Agregar un problema crítico que requiere atención del usuario
  void _addCriticalIssue(SyncIssue issue) {
    // Evitar duplicados por código
    if (!_criticalIssues.any((i) => i.code == issue.code && i.entityId == issue.entityId)) {
      _criticalIssues.add(issue);
      AppLogger.w(
        'Problema crítico de sync: [${issue.code}] ${issue.message}',
        tag: 'SYNC',
      );
    }
  }

  /// 🧹 Limpiar problemas críticos resueltos
  void clearCriticalIssue(String code, {String? entityId}) {
    _criticalIssues.removeWhere(
      (i) => i.code == code && (entityId == null || i.entityId == entityId),
    );
  }

  /// 🧹 Limpiar todos los problemas críticos
  void clearAllCriticalIssues() {
    _criticalIssues.clear();
  }

  /// 📊 Obtener métricas de la sesión actual
  Map<String, int> getSessionMetrics() => {
        'successCount': _sessionSyncSuccessCount,
        'failureCount': _sessionSyncFailureCount,
        'skippedCount': _sessionSyncSkippedCount,
        'totalAttempts': _sessionSyncSuccessCount + _sessionSyncFailureCount,
      };

  /// Sincronizar todas las operaciones pendientes
  ///
  /// Este método usa un mutex para garantizar que solo una sincronización
  /// se ejecute a la vez, previniendo race conditions.
  Future<void> syncAll() async {
    if (!_isOnline.value) {
      AppLogger.w('Sin conexión, no se puede sincronizar', tag: 'SYNC');
      return;
    }

    // ✅ FAST CHECK: Si el servidor está marcado como inalcanzable, no intentar sync
    try {
      final networkInfo = Get.find<NetworkInfo>();
      if (!networkInfo.isServerReachable) {
        AppLogger.w('Servidor no alcanzable, omitiendo sincronización', tag: 'SYNC');
        return;
      }
    } catch (_) {}

    // 🔒 Si la suscripción está expirada, no machacamos el backend. Cuando el
    // usuario renueve, llamar SyncService.resetSubscriptionBlock() para
    // reanudar inmediatamente (o esperar que venza el timeout de 30 min).
    if (isBlockedBySubscription) {
      AppLogger.w(
        'Sync pausado: suscripción expirada. Bloqueado hasta ${_subscriptionBlockedUntil!.toIso8601String()}',
        tag: 'SYNC',
      );
      return;
    }

    // 🔒 Usar tryAcquire para verificación no bloqueante
    if (!_lock.syncAll.tryAcquire(holderInfo: 'syncAll')) {
      AppLogger.w('Sincronización ya en progreso (lock activo)', tag: 'SYNC');
      return;
    }

    try {
      _syncState.value = SyncState.syncing;
      AppLogger.i('Iniciando sincronización...', tag: 'SYNC');

      final operations = await _isarDatabase.getPendingSyncOperations();

      if (operations.isEmpty) {
        AppLogger.i('No hay operaciones pendientes', tag: 'SYNC');
        _syncState.value = SyncState.idle;
        return;
      }

      // ✅ LIMPIAR AUTOMÁTICAMENTE OPERACIONES DUPLICADAS
      // Elimina UPDATE si existe CREATE para la misma entidad
      await _cleanupDuplicateOperations(operations);

      // Recargar operaciones después de limpieza
      final cleanedOperations = await _isarDatabase.getPendingSyncOperations();

      if (cleanedOperations.isEmpty) {
        AppLogger.i(
          'No hay operaciones pendientes después de limpieza',
          tag: 'SYNC',
        );
        _syncState.value = SyncState.idle;
        return;
      }

      // ✅ ORDENAR OPERACIONES POR DEPENDENCIAS
      // Categories primero, luego Products, luego el resto
      final sortedOperations = _sortOperationsByDependencies(cleanedOperations);

      AppLogger.i(
        'Sincronizando ${sortedOperations.length} operaciones (procesamiento por lotes)...',
        tag: 'SYNC',
      );

      int successCount = 0;
      int failureCount = 0;
      int skippedCount = 0;

      // ⚡ AGRUPAR POR TIER DE DEPENDENCIA para procesamiento paralelo
      final tiers = _groupOperationsByTier(sortedOperations);

      for (final tier in tiers) {
        // Filtrar operaciones que excedieron reintentos
        final validOps = <SyncOperation>[];
        for (final op in tier) {
          if (op.retryCount >= SyncConfig.maxRetries) {
            AppLogger.w(
              'Omitiendo operación permanentemente fallida: ${op.entityType}:${op.entityId}',
              tag: 'SYNC',
            );
            skippedCount++;
          } else {
            validOps.add(op);
          }
        }

        if (validOps.isEmpty) continue;

        // ⚡ Agrupar por entityId para garantizar orden secuencial dentro de la misma entidad
        // (ej: PO UPDATE approve → send → receive deben ir en orden FIFO)
        // Diferentes entityIds se ejecutan en paralelo
        final groupedByEntity = <String, List<SyncOperation>>{};
        for (final op in validOps) {
          groupedByEntity.putIfAbsent(op.entityId, () => []).add(op);
        }
        // Ordenar cada grupo por id (FIFO - id autoincrementable de ISAR)
        for (final group in groupedByEntity.values) {
          group.sort((a, b) => a.id.compareTo(b.id));
        }

        // Crear cadenas secuenciales por entidad, ejecutar en paralelo entre entidades
        final entityIds = groupedByEntity.keys.toList();
        const maxConcurrency = 5;
        for (int i = 0; i < entityIds.length; i += maxConcurrency) {
          final batchIds = entityIds.skip(i).take(maxConcurrency).toList();
          final chainFutures = batchIds.map((entityId) async {
            final chainResults = <_SyncOpResult>[];
            for (final op in groupedByEntity[entityId]!) {
              chainResults.add(await _processSingleOperation(op));
            }
            return chainResults;
          }).toList();

          final allChainResults = await Future.wait(chainFutures);
          for (final chainResults in allChainResults) {
            for (final result in chainResults) {
              if (result == _SyncOpResult.success) {
                successCount++;
              } else if (result == _SyncOpResult.skipped) {
                skippedCount++;
              } else {
                failureCount++;
              }
            }
          }
        }
      }

      _lastSyncTime.value = DateTime.now();
      await _updatePendingCount();

      // 📊 Actualizar métricas de sesión
      _sessionSyncSuccessCount += successCount;
      _sessionSyncFailureCount += failureCount;
      _sessionSyncSkippedCount += skippedCount;

      if (successCount > 0 || failureCount > 0 || skippedCount > 0) {
        AppLogger.i(
          'Sincronización completada: $successCount exitosas, $failureCount fallidas${skippedCount > 0 ? ', $skippedCount omitidas (excedieron reintentos)' : ''}',
          tag: 'SYNC',
        );
      }

      _syncState.value = SyncState.idle;

      // 📊 Actualizar información de salud
      await _updateHealthInfo();
    } catch (e) {
      AppLogger.e('Error en sincronización: $e', tag: 'SYNC');
      _syncState.value = SyncState.error;
      await _updatePendingCount();

      // 🚨 Registrar problema crítico
      _addCriticalIssue(SyncIssue(
        code: SyncErrorCodes.unknownError,
        message: 'Error crítico en sincronización: ${e.toString().substring(0, e.toString().length.clamp(0, 200))}',
        severity: IssueSeverity.error,
      ));
    } finally {
      // 🔓 SIEMPRE liberar el lock
      _lock.syncAll.release();
    }
  }

  /// FASE 5: Pull automático - descarga cambios del servidor a ISAR
  ///
  /// Se ejecuta después del PUSH cuando se restaura la conectividad.
  /// Throttle: máximo una vez cada 5 minutos para evitar carga excesiva.
  Future<void> _pullServerChanges() async {
    // No hacer pull si el usuario no está autenticado
    if (!await _isUserAuthenticated()) {
      AppLogger.d('Pull omitido - usuario no autenticado', tag: 'SYNC');
      return;
    }

    // Throttle: no hacer pull si ya se hizo hace menos de 45 segundos
    if (_lastPullTime != null) {
      final elapsed = DateTime.now().difference(_lastPullTime!);
      if (elapsed.inSeconds < 45) {
        AppLogger.d(
          'Pull omitido - último pull hace ${elapsed.inSeconds}s (mínimo 45s)',
          tag: 'SYNC',
        );
        return;
      }
    }

    try {
      if (!Get.isRegistered<FullSyncService>()) {
        AppLogger.w('FullSyncService no registrado, omitiendo pull', tag: 'SYNC');
        return;
      }

      final fullSyncService = Get.find<FullSyncService>();

      // No hacer pull si ya hay un full sync en progreso
      if (fullSyncService.isSyncing.value) {
        AppLogger.d('Full sync ya en progreso, omitiendo pull', tag: 'SYNC');
        return;
      }

      // ✅ Resetear reachability antes del PULL: si el PUSH tuvo éxito,
      // el servidor está alcanzable pero puede estar marcado como inalcanzable
      // por errores previos o por el cooldown de 30s
      try {
        final networkInfo = Get.find<NetworkInfo>();
        networkInfo.resetServerReachability();
      } catch (_) {}

      AppLogger.i('Iniciando PULL de datos del servidor...', tag: 'SYNC');
      _lastPullTime = DateTime.now();

      final result = await fullSyncService.performFullSync();

      AppLogger.i(
        'PULL completado: ${result.totalSynced} registros descargados',
        tag: 'SYNC',
      );

      if (result.hasErrors) {
        AppLogger.w('PULL con errores: ${result.errors}', tag: 'SYNC');
      }

      // Notificar controllers si el pull trajo cambios nuevos
      if (result.totalSynced > 0) {
        _syncState.value = SyncState.syncing;
        await Future.delayed(const Duration(milliseconds: 100));
        _syncState.value = SyncState.idle;
      }
    } catch (e) {
      AppLogger.e('Error en PULL del servidor: $e', tag: 'SYNC');
    }
  }

  /// ✅ LIMPIAR OPERACIONES DUPLICADAS AUTOMÁTICAMENTE
  /// Elimina operaciones UPDATE si existe CREATE para la misma entidad
  /// Para PurchaseOrders: extrae warehouseId de transiciones antes de eliminar
  Future<void> _cleanupDuplicateOperations(
    List<SyncOperation> operations,
  ) async {
    try {
      final toDelete = <int>[];

      // Agrupar por entityId
      final byEntity = <String, List<SyncOperation>>{};
      for (final op in operations) {
        byEntity.putIfAbsent(op.entityId, () => []).add(op);
      }

      // Para cada entidad, si tiene CREATE y UPDATE, eliminar UPDATE
      for (final entry in byEntity.entries) {
        final entityOps = entry.value;
        final createOps = entityOps.where(
          (op) => op.operationType == SyncOperationType.create,
        );
        final createOp = createOps.isNotEmpty ? createOps.first : null;
        final updateOps =
            entityOps
                .where((op) => op.operationType == SyncOperationType.update)
                .toList();

        if (createOp != null && updateOps.isNotEmpty) {
          // Para PurchaseOrders: extraer datos de transiciones (warehouseId, receiveItems, finalStatus)
          // ANTES de eliminar las UPDATEs, para que el CREATE handler pueda usarlos
          if (createOp.entityType == 'PurchaseOrder' || createOp.entityType == 'purchase_order') {
            String? warehouseId;
            List<dynamic>? receiveItems;
            // Determinar el estado final basándose en las acciones de las UPDATEs
            // Prioridad: receive > send > approve
            String? finalStatus;

            for (final updateOp in updateOps) {
              try {
                final opData = jsonDecode(updateOp.payload);
                final action = opData['action'] as String?;
                if (action == 'receive') {
                  warehouseId = opData['warehouseId'] as String?;
                  receiveItems = opData['items'] as List?;
                  finalStatus = 'received'; // Mayor prioridad
                } else if (action == 'send' && finalStatus != 'received') {
                  finalStatus = 'sent';
                } else if (action == 'approve' && finalStatus == null) {
                  finalStatus = 'approved';
                }
              } catch (_) {}
            }

            // Inyectar datos de transición en el payload del CREATE
            if (warehouseId != null || receiveItems != null || finalStatus != null) {
              try {
                final createData = jsonDecode(createOp.payload);
                if (warehouseId != null) createData['_receiveWarehouseId'] = warehouseId;
                if (receiveItems != null) createData['_receiveItems'] = receiveItems;
                if (finalStatus != null) createData['_finalStatus'] = finalStatus;
                await _isarDatabase.updateSyncOperationPayload(createOp.id, jsonEncode(createData));
                AppLogger.d(
                  'PO CREATE payload enriquecido con datos de transición (finalStatus: $finalStatus, warehouseId: $warehouseId)',
                  tag: 'SYNC',
                );
              } catch (e) {
                AppLogger.w('Error inyectando datos de transición en CREATE: $e', tag: 'SYNC');
              }
            }
          }

          // Eliminar todas las operaciones UPDATE (el CREATE handler se encarga de las transiciones)
          for (final updateOp in updateOps) {
            toDelete.add(updateOp.id);
            AppLogger.d(
              'Limpiando operación UPDATE duplicada: ${updateOp.entityType} ${updateOp.entityId} (CREATE ya existe)',
              tag: 'SYNC',
            );
          }
        }
      }

      // Eliminar operaciones duplicadas usando el método de IsarDatabase
      if (toDelete.isNotEmpty) {
        for (final id in toDelete) {
          await _isarDatabase.deleteSyncOperation(id);
        }
        AppLogger.i(
          '${toDelete.length} operaciones duplicadas eliminadas automáticamente',
          tag: 'SYNC',
        );
      }
    } catch (e) {
      AppLogger.w('Error limpiando operaciones duplicadas: $e', tag: 'SYNC');
    }
  }

  /// ⚡ Agrupa operaciones ya ordenadas en tiers de dependencia para procesamiento paralelo
  List<List<SyncOperation>> _groupOperationsByTier(List<SyncOperation> sorted) {
    // Tiers: entidades del mismo nivel de prioridad pueden ejecutarse en paralelo
    final tierMap = <int, List<SyncOperation>>{};
    final priorityOrder = {
      'organization': 0, 'organization_profit_margin': 0, 'user_profile': 0,
      'Category': 1, 'category': 1, 'BankAccount': 1, 'bank_account': 1,
      'Product': 2, 'product': 2, 'Customer': 3, 'customer': 3,
      'Supplier': 3, 'supplier': 3,
      'Invoice': 4, 'invoice': 4, 'Expense': 4, 'expense': 4,
      'PurchaseOrder': 4, 'purchase_order': 4,
      'InventoryMovement': 5, 'inventory_movement': 5, 'inventory_movement_fifo': 5,
      'CreditNote': 5, 'credit_note': 5, 'CustomerCredit': 5, 'customer_credit': 5,
      'ClientBalance': 5, 'client_balance': 5,
      'notification': 6, 'user_preferences': 6,
    };

    for (final op in sorted) {
      final tier = priorityOrder[op.entityType] ?? 99;
      tierMap.putIfAbsent(tier, () => []).add(op);
    }

    final keys = tierMap.keys.toList()..sort();
    return keys.map((k) => tierMap[k]!).toList();
  }

  /// ⚡ Procesa una operación individual de sync (para ejecución paralela)
  Future<_SyncOpResult> _processSingleOperation(SyncOperation operation) async {
    try {
      // ✅ Verificar si la operación aún existe en DB
      // (puede haber sido eliminada por el handler de otra operación, ej: Invoice borra FIFO ops)
      final isar = IsarDatabase.instance.database;
      final stillExists = await isar.syncOperations.get(operation.id);
      if (stillExists == null) {
        AppLogger.i(
          'Operación ${operation.entityType}:${operation.entityId} ya fue eliminada por otro handler, omitiendo',
          tag: 'SYNC',
        );
        return _SyncOpResult.skipped;
      }

      // IDEMPOTENCIA: Verificar si ya fue procesada
      // Incluir operation.id para distinguir diferentes operaciones sobre la misma entidad
      // (ej: dos UPDATEs distintos al mismo PO deben tener claves diferentes)
      final idempotencyService = Get.find<IdempotencyService>();
      final idempotencyKey =
          '${operation.operationType.name}_${operation.entityType}_${operation.entityId}_${operation.id}';

      final alreadyProcessed = await idempotencyService.isOperationProcessed(idempotencyKey);
      if (alreadyProcessed) {
        await _isarDatabase.markSyncOperationCompleted(operation.id);
        return _SyncOpResult.success;
      }

      await idempotencyService.registerOperationWithKey(
        idempotencyKey: idempotencyKey,
        operationType: operation.operationType.name,
        entityType: operation.entityType,
        entityId: operation.entityId,
      );
      await idempotencyService.markAsProcessing(idempotencyKey);

      // Sincronizar según el tipo de entidad
      switch (operation.entityType) {
        case 'Product':
        case 'product':
          await _syncProductOperation(operation);
          break;
        case 'Category':
        case 'category':
          await _syncCategoryOperation(operation);
          break;
        case 'Customer':
        case 'customer':
          await _syncCustomerOperation(operation);
          break;
        case 'Supplier':
        case 'supplier':
          await _syncSupplierOperation(operation);
          break;
        case 'Expense':
        case 'expense':
          await _syncExpenseOperation(operation);
          break;
        case 'ExpenseCategory':
        case 'expense_category':
          await _syncExpenseCategoryOperation(operation);
          break;
        case 'BankAccount':
        case 'bank_account':
          await _syncBankAccountOperation(operation);
          break;
        case 'Invoice':
        case 'invoice':
          await _syncInvoiceOperation(operation);
          break;
        case 'PurchaseOrder':
        case 'purchase_order':
          await _syncPurchaseOrderOperation(operation);
          break;
        case 'InventoryMovement':
        case 'inventory_movement':
        case 'inventory_movement_fifo':
          await _syncInventoryMovementOperation(operation);
          break;
        case 'CreditNote':
        case 'credit_note':
          await _syncCreditNoteOperation(operation);
          break;
        case 'CustomerCredit':
        case 'customer_credit':
          await _syncCustomerCreditOperation(operation);
          break;
        case 'ClientBalance':
        case 'client_balance':
          await _syncClientBalanceOperation(operation);
          break;
        case 'organization':
        case 'organization_profit_margin':
          await _syncOrganizationOperation(operation);
          break;
        case 'user_profile':
          await _syncUserProfileOperation(operation);
          break;
        case 'notification':
          await _syncNotificationOperation(operation);
          break;
        case 'user_preferences':
          await _syncUserPreferencesOperation(operation);
          break;
        case 'PrinterSettings':
        case 'printer_settings':
          await _syncPrinterSettingsOperation(operation);
          break;
        default:
          throw Exception('Tipo de entidad no soportado: ${operation.entityType}');
      }

      await _isarDatabase.markSyncOperationCompleted(operation.id);
      await idempotencyService.markAsCompleted(idempotencyKey: idempotencyKey);

      AppLogger.i(
        'Sincronizada: ${operation.entityType} ${operation.operationType.name}',
        tag: 'SYNC',
      );
      return _SyncOpResult.success;
    } catch (e) {
      try {
        final idempotencyService = Get.find<IdempotencyService>();
        final idempotencyKey =
            '${operation.operationType.name}_${operation.entityType}_${operation.entityId}_${operation.id}';
        await idempotencyService.markAsFailed(
          idempotencyKey: idempotencyKey,
          errorMessage: e.toString(),
        );
      } catch (_) {}

      await _isarDatabase.markSyncOperationFailed(operation.id, e.toString());

      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('connection refused') ||
          errorMsg.contains('socketexception')) {
        AppLogger.d(
          '${operation.entityType} pendiente - backend no disponible',
          tag: 'SYNC',
        );
      }

      // 🔒 SUSCRIPCIÓN EXPIRADA (403) — no tiene sentido reintentar.
      // Pausamos todo el sync hasta que el usuario renueve. Detectamos por
      // code 403 o por textos que el backend retorna ("Su suscripción ha
      // expirado", "subscription expired", "subscription required").
      final isSubscriptionError =
          errorMsg.contains('suscripción ha expirado') ||
          errorMsg.contains('suscripcion ha expirado') ||
          errorMsg.contains('subscription has expired') ||
          errorMsg.contains('subscription expired') ||
          errorMsg.contains('actualice su plan') ||
          errorMsg.contains('statuscode: 403') ||
          errorMsg.contains('status code: 403');

      if (isSubscriptionError) {
        _subscriptionBlockedUntil = DateTime.now().add(_subscriptionBlockDuration);
        AppLogger.w(
          'Sync bloqueado por suscripción expirada. Pausando hasta ${_subscriptionBlockedUntil!.toIso8601String()}',
          tag: 'SYNC',
        );
        // Mostrar el diálogo una sola vez por sesión para no hostigar.
        if (!_subscriptionDialogShown) {
          _subscriptionDialogShown = true;
          _showSubscriptionExpiredDialog();
        }
        // No retry: marcamos la operación como completada. Los datos locales
        // permanecen en ISAR; cuando el usuario renueve puede recrear o se
        // expondrá un botón "Resincronizar" en settings (futuro).
        await _isarDatabase.markSyncOperationCompleted(operation.id);
        return _SyncOpResult.failure;
      }

      // Detectar errores de secuencia transitoria de inventario
      // (movementNumber/batchNumber duplicado por race condition - el backend generará nuevo número en retry)
      final isInventorySequenceError =
          (operation.entityType == 'InventoryMovement' ||
              operation.entityType == 'inventory_movement') &&
          (errorMsg.contains('duplicate key') ||
              errorMsg.contains('unique constraint') ||
              errorMsg.contains('violates unique'));

      // Errores de validación del backend (400) y conflictos no se deben reintentar
      // EXCEPTO errores de secuencia de inventario que son transitorios
      if (!isInventorySequenceError &&
          (errorMsg.contains('solicitud incorrecta') ||
              errorMsg.contains('bad request') ||
              errorMsg.contains('must be a valid') ||
              errorMsg.contains('debe ser un') ||
              errorMsg.contains('ya existe') ||
              errorMsg.contains('already exists') ||
              errorMsg.contains('duplicate key') ||
              errorMsg.contains('unique constraint') ||
              errorMsg.contains('violates unique') ||
              errorMsg.contains('violates not-null') ||
              errorMsg.contains('violates foreign key') ||
              errorMsg.contains('violates check constraint') ||
              errorMsg.contains('invalid input syntax') ||
              errorMsg.contains('cannot be modified'))) {
        AppLogger.w(
          '${operation.entityType}:${operation.entityId} error permanente - no reintentar: $e',
          tag: 'SYNC',
        );
        // Marcar como completada con error para que no se reintente más
        await _isarDatabase.markSyncOperationCompleted(operation.id);
      } else if (isInventorySequenceError) {
        AppLogger.w(
          '${operation.entityType}:${operation.entityId} error de secuencia transitorio - se reintentará: $e',
          tag: 'SYNC',
        );
      }
      return _SyncOpResult.failure;
    }
  }

  /// Muestra el diálogo de suscripción expirada de forma segura (post-frame).
  /// Llamado cuando el sync detecta un 403 por primera vez en la sesión.
  void _showSubscriptionExpiredDialog() {
    try {
      // Diferimos con microtask para no chocar con el build actual.
      Future.microtask(() {
        try {
          SubscriptionErrorDialog.showSubscriptionExpired(
            customMessage:
                'Algunas operaciones creadas sin internet (productos, '
                'facturas, etc.) no pudieron sincronizarse porque tu '
                'suscripción expiró. Renueva tu plan para continuar.',
            onUpgradePressed: () {
              Get.toNamed('/settings/subscription');
            },
          );
        } catch (e) {
          AppLogger.w('No se pudo mostrar diálogo de suscripción: $e', tag: 'SYNC');
        }
      });
    } catch (_) {}
  }

  /// ✅ ORDENAR OPERACIONES POR DEPENDENCIAS
  /// - Categories primero (CREATE antes que UPDATE/DELETE)
  /// - Products después (dependen de Categories)
  /// - Customers después
  /// - Otros tipos al final
  List<SyncOperation> _sortOperationsByDependencies(
    List<SyncOperation> operations,
  ) {
    // Definir orden de prioridad por tipo de entidad
    final priorityOrder = {
      'Category': 1, // Primero: Categories
      'Product': 2, // Segundo: Products (dependen de categories)
      'Customer': 3, // Tercero: Customers
      'Expense': 4, // Cuarto: Expenses
    };

    // Definir orden de prioridad por tipo de operación
    final operationOrder = {
      SyncOperationType.create: 1, // CREATE primero
      SyncOperationType.update: 2, // UPDATE segundo
      SyncOperationType.delete: 3, // DELETE al final
    };

    // Ordenar primero por tipo de entidad, luego por tipo de operación
    final sorted = List<SyncOperation>.from(operations);
    sorted.sort((a, b) {
      final aPriority = priorityOrder[a.entityType] ?? 999;
      final bPriority = priorityOrder[b.entityType] ?? 999;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      // Si mismo tipo de entidad, ordenar por tipo de operación
      final aOpPriority = operationOrder[a.operationType] ?? 999;
      final bOpPriority = operationOrder[b.operationType] ?? 999;

      return aOpPriority.compareTo(bOpPriority);
    });

    // Debug: Mostrar orden de sincronización
    if (sorted.isNotEmpty) {
      AppLogger.d(
        'Orden de sincronización: ${sorted.map((op) => '${op.entityType}:${op.operationType.name}').join(', ')}',
        tag: 'SYNC',
      );
    }

    return sorted;
  }

  /// Agregar operación a la cola de sincronización
  Future<void> addOperation({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    required String organizationId,
    int priority = 0,
  }) async {
    // ✅ VALIDACIONES DE DATOS
    // 1. Validar tipo de entidad
    if (!SyncConfig.isEntityTypeSupported(entityType)) {
      AppLogger.e(
        'Tipo de entidad no soportado: $entityType',
        tag: 'SYNC',
      );
      throw ArgumentError('Tipo de entidad no soportado: $entityType');
    }

    // 2. Validar entityId
    if (entityId.isEmpty) {
      AppLogger.e('entityId no puede estar vacío', tag: 'SYNC');
      throw ArgumentError('entityId no puede estar vacío');
    }
    if (entityId.length > SyncConfig.maxEntityIdLength) {
      AppLogger.e(
        'entityId excede longitud máxima: ${entityId.length} > ${SyncConfig.maxEntityIdLength}',
        tag: 'SYNC',
      );
      throw ArgumentError('entityId excede longitud máxima permitida');
    }

    // 3. Validar organizationId
    if (organizationId.isEmpty) {
      AppLogger.e('organizationId no puede estar vacío', tag: 'SYNC');
      throw ArgumentError('organizationId no puede estar vacío');
    }

    // 4. Validar tamaño del payload
    final payloadJson = jsonEncode(data);
    if (payloadJson.length > SyncConfig.maxPayloadSizeBytes) {
      AppLogger.e(
        'Payload excede tamaño máximo: ${payloadJson.length} bytes > ${SyncConfig.maxPayloadSizeBytes} bytes',
        tag: 'SYNC',
      );
      throw ArgumentError('Payload excede el tamaño máximo permitido');
    }

    // 5. Para Invoice: validar que tenga items
    if ((entityType == 'Invoice' || entityType == 'invoice') &&
        operationType == SyncOperationType.create) {
      final items = data['items'];
      if (items == null || (items is List && items.isEmpty)) {
        AppLogger.e(
          'Factura sin items no puede ser sincronizada: $entityId',
          tag: 'SYNC',
        );
        throw ArgumentError('Una factura debe tener al menos un item');
      }
    }

    try {
      final operation = SyncOperation.create(
        entityType: entityType,
        entityId: entityId,
        operationType: operationType,
        payload: payloadJson,
        organizationId: organizationId,
        priority: priority,
      );

      await _isarDatabase.addSyncOperation(operation);
      await _updatePendingCount();

      AppLogger.i(
        'Operación agregada a cola: $entityType ${operationType.name} (ID: $entityId)',
        tag: 'SYNC',
      );

      // Intentar sincronizar inmediatamente si hay conexión Y el servidor responde
      if (_isOnline.value) {
        try {
          final networkInfo = Get.find<NetworkInfo>();
          if (networkInfo.isServerReachable) {
            await syncAll();
          }
        } catch (_) {
          // Si no se puede obtener NetworkInfo, intentar sync de todos modos
          await syncAll();
        }
      }
    } catch (e) {
      AppLogger.e('Error agregando operación a cola: $e', tag: 'SYNC');
      rethrow;
    }
  }

  /// Agregar operación para el usuario actual autenticado
  ///
  /// Este método helper obtiene automáticamente el organizationId del usuario
  /// autenticado, evitando tener que pasarlo manualmente en cada llamada.
  ///
  /// Lanza excepción si no hay usuario autenticado.
  Future<void> addOperationForCurrentUser({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    try {
      // Obtener organizationId del usuario autenticado
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser;

      if (currentUser == null) {
        throw Exception(
          'No hay usuario autenticado para agregar operación de sincronización',
        );
      }

      final organizationId = currentUser.organizationId;

      // Llamar al método addOperation con el organizationId obtenido
      return addOperation(
        entityType: entityType,
        entityId: entityId,
        operationType: operationType,
        data: data,
        organizationId: organizationId,
        priority: priority,
      );
    } catch (e) {
      AppLogger.e(
        'Error agregando operación para usuario actual: $e',
        tag: 'SYNC',
      );
      rethrow;
    }
  }

  /// Forzar sincronización manual
  Future<void> forceSyncNow() async {
    AppLogger.i('Sincronización manual forzada', tag: 'SYNC');
    await syncAll();
  }

  /// Limpiar operaciones antiguas completadas
  Future<void> cleanOldOperations() async {
    try {
      await _isarDatabase.cleanOldSyncOperations();
      await _updatePendingCount();
    } catch (e) {
      AppLogger.e('Error limpiando operaciones antiguas: $e', tag: 'SYNC');
    }
  }

  /// Obtener estadísticas de sincronización
  Future<Map<String, int>> getSyncStats() async {
    return await _isarDatabase.getSyncOperationsCounts();
  }

  /// 📊 Obtener información de salud de la cola de sincronización
  ///
  /// Retorna un mapa con información útil para diagnóstico:
  /// - totalPending: operaciones pendientes
  /// - totalFailed: operaciones fallidas
  /// - permanentlyFailed: operaciones que excedieron reintentos (>= 10)
  /// - invoicesWithoutItems: facturas con items vacíos
  /// - hasIssues: true si hay problemas que requieren atención
  Future<Map<String, dynamic>> getSyncQueueHealth() async {
    try {
      final stats = await _isarDatabase.getSyncOperationsCounts();
      final failedOperations = await _isarDatabase.getFailedSyncOperations();
      final pendingOperations = await _isarDatabase.getPendingSyncOperations();

      // Contar operaciones permanentemente fallidas
      int permanentlyFailed = 0;
      int invoicesWithoutItems = 0;

      for (final op in failedOperations) {
        if (op.retryCount >= SyncConfig.maxRetries) {
          permanentlyFailed++;
        }
      }

      // Verificar facturas sin items en operaciones pendientes
      for (final op in pendingOperations.where((o) => o.entityType == 'Invoice')) {
        try {
          final data = jsonDecode(op.payload);
          final items = data['items'];
          if (items == null || (items is List && items.isEmpty)) {
            invoicesWithoutItems++;
          }
        } catch (_) {}
      }

      final hasIssues = permanentlyFailed > 0 || invoicesWithoutItems > 0;

      return {
        'totalPending': stats['pending'] ?? 0,
        'totalFailed': stats['failed'] ?? 0,
        'totalCompleted': stats['completed'] ?? 0,
        'permanentlyFailed': permanentlyFailed,
        'invoicesWithoutItems': invoicesWithoutItems,
        'hasIssues': hasIssues,
        'lastSyncTime': _lastSyncTime.value?.toIso8601String(),
        'isOnline': _isOnline.value,
        'syncState': _syncState.value.name,
      };
    } catch (e) {
      AppLogger.e('Error obteniendo salud de cola de sync: $e', tag: 'SYNC');
      return {
        'error': e.toString(),
        'hasIssues': true,
      };
    }
  }

  /// Reanudar sincronización de operaciones fallidas
  ///
  /// Este método:
  /// 1. Obtiene todas las operaciones con estado 'failed'
  /// 2. Las marca como 'pending' para reintentar
  /// 3. Aplica exponential backoff si han fallado múltiples veces
  /// 4. Llama a syncAll() para procesarlas
  Future<void> retryFailedOperations() async {
    if (!_isOnline.value) {
      AppLogger.w('Sin conexión, no se puede reintentar', tag: 'SYNC');
      return;
    }

    AppLogger.i('Reintentando operaciones fallidas...', tag: 'SYNC');

    try {
      // Obtener operaciones fallidas
      final failedOperations = await _isarDatabase.getFailedSyncOperations();

      if (failedOperations.isEmpty) {
        AppLogger.i('No hay operaciones fallidas para reintentar', tag: 'SYNC');
        return;
      }

      AppLogger.i(
        'Encontradas ${failedOperations.length} operaciones fallidas',
        tag: 'SYNC',
      );

      int retriedCount = 0;
      int skippedCount = 0;

      for (final operation in failedOperations) {
        // Verificar si ha excedido el máximo de reintentos (10)
        if (operation.retryCount >= SyncConfig.maxRetries) {
          AppLogger.d(
            'Operación ${operation.entityType}:${operation.entityId} excedió máximo de reintentos (${operation.retryCount})',
            tag: 'SYNC',
          );
          skippedCount++;
          continue;
        }

        // Aplicar exponential backoff
        final delay = _getRetryDelay(operation.retryCount);
        final lastAttempt = operation.updatedAt ?? operation.createdAt;
        final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);

        if (timeSinceLastAttempt < delay) {
          AppLogger.d(
            'Operación ${operation.entityType}:${operation.entityId} en backoff (esperar ${delay.inSeconds - timeSinceLastAttempt.inSeconds}s más)',
            tag: 'SYNC',
          );
          skippedCount++;
          continue;
        }

        // Marcar como pending para reintentar
        await _isarDatabase.markSyncOperationPending(operation.id);
        retriedCount++;
        AppLogger.d(
          'Operación ${operation.entityType}:${operation.entityId} marcada para reintento (#${operation.retryCount + 1})',
          tag: 'SYNC',
        );
      }

      await _updatePendingCount();

      if (retriedCount > 0) {
        AppLogger.i(
          'Reintentos: $retriedCount operaciones, $skippedCount omitidas',
          tag: 'SYNC',
        );
        await syncAll();
      } else {
        AppLogger.d(
          'Todas las operaciones están en período de backoff o excedieron reintentos',
          tag: 'SYNC',
        );
      }
    } catch (e) {
      AppLogger.e('Error reintentando operaciones fallidas: $e', tag: 'SYNC');
    }
  }

  /// Calcula el delay de reintento usando exponential backoff
  ///
  /// Fórmula: 2^retryCount segundos, máximo 5 minutos (300s)
  /// Ejemplo: retry 0 = 1s, retry 1 = 2s, retry 2 = 4s, retry 3 = 8s, etc.
  Duration _getRetryDelay(int retryCount) {
    final seconds = (1 << retryCount).clamp(1, 300); // 2^retryCount, max 300s
    return Duration(seconds: seconds);
  }

  // ==================== MÉTODOS DE DEBUGGING Y LIMPIEZA ====================

  /// Listar todas las operaciones de sync (para debugging)
  Future<void> listAllSyncOperations() async {
    await _isarDatabase.listAllSyncOperations();
  }

  /// Eliminar una operación de sync específica por ID
  Future<void> deleteSyncOperation(int operationId) async {
    try {
      await _isarDatabase.deleteSyncOperation(operationId);
      await _updatePendingCount();
      AppLogger.i('Operación de sync eliminada correctamente', tag: 'SYNC');
    } catch (e) {
      AppLogger.e('Error eliminando operación de sync: $e', tag: 'SYNC');
    }
  }

  /// Eliminar todas las operaciones de sync para un entityId específico
  Future<void> deleteSyncOperationsByEntityId(String entityId) async {
    try {
      await _isarDatabase.deleteSyncOperationsByEntityId(entityId);
      await _updatePendingCount();
      AppLogger.i(
        'Operaciones de sync eliminadas para entityId: $entityId',
        tag: 'SYNC',
      );
    } catch (e) {
      AppLogger.e('Error eliminando operaciones de sync: $e', tag: 'SYNC');
    }
  }

  /// 🗑️ Limpiar operaciones permanentemente fallidas (>10 reintentos)
  ///
  /// Repara operaciones de InventoryMovement que tienen referenceId temporal
  /// (po_offline_xxx) porque la PO ya fue sincronizada pero el referenceId
  /// no fue actualizado en el payload del movimiento.
  /// Resetea el retryCount y status para que se reintenten.
  Future<void> _repairMovementsWithTempReferenceId() async {
    try {
      // Reparar operaciones fallidas Y pendientes
      final allOps = await _isarDatabase.getPendingSyncOperations();
      int repairedCount = 0;

      // Mapeo de tipos frontend → backend
      const typeMapping = {
        'inbound': 'purchase',
        'outbound': 'sale',
        'transferIn': 'transfer_in',
        'transferOut': 'transfer_out',
      };

      for (final op in allOps) {
        if ((op.entityType == 'InventoryMovement' || op.entityType == 'inventory_movement') &&
            op.operationType == SyncOperationType.create) {
          try {
            final data = jsonDecode(op.payload);
            bool needsRepair = false;

            // Fix 1: Corregir type de frontend enum a backend value
            final currentType = data['type'] as String?;
            if (currentType != null && typeMapping.containsKey(currentType)) {
              data['type'] = typeMapping[currentType];
              needsRepair = true;
              AppLogger.d(
                'Corrigiendo type en InventoryMovement ${op.entityId}: $currentType → ${data['type']}',
                tag: 'SYNC',
              );
            }

            // Fix 2: Resolver referenceId temporal
            final refId = data['referenceId'] as String?;
            if (refId != null &&
                (refId.startsWith('po_offline_') || refId.startsWith('po_'))) {
              final isar = IsarDatabase.instance.database;
              final isarPO = await isar.isarPurchaseOrders
                  .filter()
                  .serverIdEqualTo(refId)
                  .findFirst();

              if (isarPO == null) {
                data['referenceId'] = null;
                needsRepair = true;
                AppLogger.d(
                  'Eliminando referenceId temporal en InventoryMovement ${op.entityId}: $refId',
                  tag: 'SYNC',
                );
              }
            }

            if (needsRepair) {
              await _isarDatabase.updateSyncOperationPayload(
                op.id,
                jsonEncode(data),
              );

              // Resetear retryCount si la operación estaba fallida
              if (op.retryCount > 0) {
                final isar = IsarDatabase.instance.database;
                await isar.writeTxn(() async {
                  final freshOp = await isar.syncOperations.get(op.id);
                  if (freshOp != null) {
                    freshOp.retryCount = 0;
                    freshOp.status = SyncStatus.pending;
                    freshOp.error = null;
                    freshOp.updatedAt = DateTime.now();
                    await isar.syncOperations.put(freshOp);
                  }
                });
              }

              repairedCount++;
              AppLogger.i(
                'Reparado InventoryMovement ${op.entityId}: payload corregido y reseteado para reintento',
                tag: 'SYNC',
              );
            }
          } catch (e) {
            AppLogger.w('Error reparando operación ${op.entityId}: $e', tag: 'SYNC');
          }
        }
      }

      if (repairedCount > 0) {
        await _updatePendingCount();
        AppLogger.i(
          'Reparadas $repairedCount operaciones de InventoryMovement',
          tag: 'SYNC',
        );
      }
    } catch (e) {
      AppLogger.w('Error en reparación de movimientos: $e', tag: 'SYNC');
    }
  }

  /// Este método elimina operaciones que han excedido el máximo de reintentos
  /// y ya no pueden sincronizarse. Útil para limpiar la cola de operaciones
  /// que nunca podrán completarse.
  ///
  /// Retorna el número de operaciones eliminadas.
  /// 🧹 Elimina operaciones inventory_movement_fifo huérfanas.
  ///
  /// Estas ops se crean cuando una venta offline descuenta inventario FIFO.
  /// El backend ya descuenta inventario automáticamente al crear la factura
  /// (invoices.service.ts → registerSale), así que enviar estas ops causaría
  /// DOBLE DEDUCCIÓN. Además, el endpoint process-outbound-fifo NO existe (404).
  ///
  /// Si la Invoice asociada ya se sincronizó (no está en pending ops),
  /// estas ops FIFO deben eliminarse.
  Future<void> _cleanupOrphanedFifoOperations() async {
    try {
      final isar = IsarDatabase.instance.database;
      final allOps = await isar.syncOperations
          .filter()
          .entityTypeEqualTo('inventory_movement_fifo')
          .findAll();

      if (allOps.isEmpty) return;

      // Obtener entityIds de Invoices pendientes de sync
      final pendingInvoiceIds = (await isar.syncOperations
          .filter()
          .group((q) => q
              .entityTypeEqualTo('Invoice')
              .or()
              .entityTypeEqualTo('invoice'))
          .and()
          .group((q) => q
              .statusEqualTo(SyncStatus.pending)
              .or()
              .statusEqualTo(SyncStatus.failed))
          .findAll())
          .map((op) => op.entityId)
          .toSet();

      int deleted = 0;
      for (final op in allOps) {
        try {
          final payload = jsonDecode(op.payload);
          final refId = payload['referenceId'] as String?;
          final refType = payload['referenceType'] as String?;

          // Si es una op FIFO de factura y la factura ya NO está pendiente → eliminar
          if (refType == 'invoice' && refId != null && !pendingInvoiceIds.contains(refId)) {
            // Invoice ya sincronizada → FIFO op no necesaria (backend ya descontó)
            await _isarDatabase.deleteSyncOperation(op.id);
            deleted++;
          } else if (refType != 'invoice') {
            // No es referencia a invoice → huérfana, eliminar
            await _isarDatabase.deleteSyncOperation(op.id);
            deleted++;
          }
        } catch (_) {
          // Payload corrupto → eliminar
          await _isarDatabase.deleteSyncOperation(op.id);
          deleted++;
        }
      }

      if (deleted > 0) {
        await _updatePendingCount();
        AppLogger.i(
          '🧹 Eliminadas $deleted ops inventory_movement_fifo huérfanas (backend ya maneja FIFO al crear factura)',
          tag: 'SYNC',
        );
      }
    } catch (e) {
      AppLogger.w('Error limpiando ops FIFO huérfanas: $e', tag: 'SYNC');
    }
  }

  /// 🧹 Limpia registros offline huérfanos de inventario que causan stock duplicado.
  ///
  /// Problema: Cuando un PO se recibe offline, se crean batches con serverId 'batch_offline_*'.
  /// Cuando el PO se sincroniza y FullSync trae los batches reales del servidor,
  /// los batch_offline_ no se eliminan → el stock se cuenta doble.
  ///
  /// Esta rutina elimina batch_offline_ cuyo PO ya no está pendiente de sync,
  /// y también elimina product_offline_ huérfanos.
  Future<void> _cleanupOrphanedOfflineInventoryRecords() async {
    try {
      final isar = IsarDatabase.instance.database;

      // Obtener IDs de entidades con operaciones pendientes de sync
      final pendingOps = await _isarDatabase.getPendingSyncOperations();
      final pendingEntityIds = pendingOps.map((op) => op.entityId).toSet();

      int totalCleaned = 0;

      // 1. Limpiar batches con prefijo batch_offline_
      final allBatches = await isar.isarInventoryBatchs.where().findAll();
      final offlineBatches = allBatches
          .where((b) => b.serverId.startsWith('batch_offline_'))
          .toList();

      if (offlineBatches.isNotEmpty) {
        // Solo borrar si el PO asociado ya NO está pendiente de sync
        final toDelete = offlineBatches.where((b) {
          if (b.purchaseOrderId != null &&
              b.purchaseOrderId!.isNotEmpty &&
              pendingEntityIds.contains(b.purchaseOrderId)) {
            return false; // PO aún pendiente, preservar batch
          }
          return true;
        }).toList();

        if (toDelete.isNotEmpty) {
          await isar.writeTxn(() async {
            await isar.isarInventoryBatchs
                .deleteAll(toDelete.map((b) => b.id).toList());
          });
          totalCleaned += toDelete.length;
          AppLogger.i(
            '🧹 Eliminados ${toDelete.length} batches batch_offline_ huérfanos',
            tag: 'SYNC',
          );
        }
      }

      // 2. Limpiar productos con prefijo product_offline_
      final allProducts = await isar.isarProducts.where().findAll();
      final offlineProducts = allProducts
          .where((p) => p.serverId.startsWith('product_offline_'))
          .where((p) => !pendingEntityIds.contains(p.serverId))
          .toList();

      if (offlineProducts.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.isarProducts
              .deleteAll(offlineProducts.map((p) => p.id).toList());
        });
        totalCleaned += offlineProducts.length;
        AppLogger.i(
          '🧹 Eliminados ${offlineProducts.length} productos product_offline_ huérfanos',
          tag: 'SYNC',
        );
      }

      if (totalCleaned > 0) {
        AppLogger.i(
          '🧹 Total registros de inventario huérfanos eliminados: $totalCleaned',
          tag: 'SYNC',
        );
      }
    } catch (e) {
      AppLogger.w('Error limpiando registros de inventario huérfanos: $e', tag: 'SYNC');
    }
  }

  Future<int> cleanPermanentlyFailedOperations() async {
    try {
      AppLogger.i('Limpiando operaciones permanentemente fallidas...', tag: 'SYNC');

      final failedOperations = await _isarDatabase.getFailedSyncOperations();
      int cleanedCount = 0;

      for (final operation in failedOperations) {
        if (operation.retryCount >= SyncConfig.maxRetries) {
          AppLogger.d(
            'Eliminando operación permanentemente fallida: ${operation.entityType}:${operation.entityId} (${operation.retryCount} reintentos)',
            tag: 'SYNC',
          );
          await _isarDatabase.deleteSyncOperation(operation.id);
          cleanedCount++;
        }
      }

      if (cleanedCount > 0) {
        await _updatePendingCount();
        AppLogger.i(
          '🗑️ Eliminadas $cleanedCount operaciones permanentemente fallidas',
          tag: 'SYNC',
        );
      } else {
        AppLogger.d('No hay operaciones permanentemente fallidas para eliminar', tag: 'SYNC');
      }

      return cleanedCount;
    } catch (e) {
      AppLogger.e('Error limpiando operaciones permanentemente fallidas: $e', tag: 'SYNC');
      return 0;
    }
  }

  /// 🔧 Reparar operaciones de facturas con items vacíos
  ///
  /// Este método busca operaciones de facturas en la cola que tienen items vacíos
  /// e intenta reconstruirlos desde ISAR. Útil para reparar operaciones
  /// que se crearon antes del fix de itemsJson.
  ///
  /// Retorna el número de operaciones reparadas.
  Future<int> repairInvoiceOperationsWithMissingItems() async {
    try {
      AppLogger.i('Reparando operaciones de facturas con items vacíos...', tag: 'SYNC');

      final operations = await _isarDatabase.getPendingSyncOperations();
      int repairedCount = 0;

      for (final operation in operations.where((op) => op.entityType == 'Invoice')) {
        try {
          final data = jsonDecode(operation.payload);
          final items = data['items'];

          // Verificar si los items están vacíos o son nulos
          if (items == null || (items is List && items.isEmpty)) {
            AppLogger.d(
              'Factura ${operation.entityId} tiene items vacíos - intentando reparar',
              tag: 'SYNC',
            );

            // Intentar obtener los items desde ISAR
            final offlineRepo = Get.find<InvoiceOfflineRepository>();
            final invoiceResult = await offlineRepo.getInvoiceById(operation.entityId);

            await invoiceResult.fold(
              (failure) async {
                AppLogger.w(
                  'No se pudo obtener factura ${operation.entityId} de ISAR: ${failure.toString()}',
                  tag: 'SYNC',
                );
              },
              (invoice) async {
                if (invoice.items.isNotEmpty) {
                  // Reconstruir items desde la factura en ISAR
                  final repairedItems = invoice.items.map((item) => {
                    'productId': item.productId,
                    'description': item.description,
                    'quantity': item.quantity,
                    'unitPrice': item.unitPrice,
                    'unit': item.unit,
                    'discountPercentage': item.discountPercentage,
                    'discountAmount': item.discountAmount,
                    'notes': item.notes,
                  }).toList();

                  // Actualizar el payload con los items reparados
                  data['items'] = repairedItems;
                  final updatedPayload = jsonEncode(data);

                  // Actualizar la operación en la base de datos
                  await _isarDatabase.updateSyncOperationPayload(
                    operation.id,
                    updatedPayload,
                  );

                  AppLogger.i(
                    '✅ Factura ${operation.entityId} reparada con ${repairedItems.length} items',
                    tag: 'SYNC',
                  );
                  repairedCount++;
                } else {
                  AppLogger.w(
                    'Factura ${operation.entityId} también tiene items vacíos en ISAR - no se puede reparar',
                    tag: 'SYNC',
                  );
                }
              },
            );
          }
        } catch (e) {
          AppLogger.w(
            'Error procesando operación ${operation.id}: $e',
            tag: 'SYNC',
          );
        }
      }

      if (repairedCount > 0) {
        AppLogger.i(
          '🔧 Reparadas $repairedCount operaciones de facturas',
          tag: 'SYNC',
        );
      } else {
        AppLogger.d('No hay operaciones de facturas para reparar', tag: 'SYNC');
      }

      return repairedCount;
    } catch (e) {
      AppLogger.e('Error reparando operaciones de facturas: $e', tag: 'SYNC');
      return 0;
    }
  }

  /// 🧹 Limpiar operaciones con referencias offline inválidas
  /// Este método detecta y elimina operaciones de productos que referencian
  /// categorías offline que no tienen operación de sync pendiente (huérfanas)
  Future<void> _cleanInvalidOfflineReferences() async {
    try {
      AppLogger.d('Verificando referencias offline inválidas...', tag: 'SYNC');

      final operations = await _isarDatabase.getPendingSyncOperations();

      // Obtener todas las operaciones de categorías pendientes
      final categoryOperations =
          operations
              .where((op) => op.entityType == 'Category')
              .map((op) => op.entityId)
              .toSet();

      int cleaned = 0;

      // Revisar operaciones de productos
      for (final operation in operations.where(
        (op) => op.entityType == 'Product',
      )) {
        try {
          final data = jsonDecode(operation.payload);
          final categoryId = data['categoryId'] as String?;

          // Si el producto referencia una categoría offline...
          if (categoryId != null &&
              categoryId.startsWith('category_offline_')) {
            // ...y esa categoría NO tiene operación de sync pendiente...
            if (!categoryOperations.contains(categoryId)) {
              AppLogger.d(
                'Eliminando producto huérfano: ${data['name']} (SKU: ${data['sku']}) - Categoría offline inexistente: $categoryId',
                tag: 'SYNC',
              );

              await _isarDatabase.deleteSyncOperation(operation.id);
              cleaned++;
            }
          }
        } catch (e) {
          AppLogger.w(
            'Error procesando operación ${operation.id}: $e',
            tag: 'SYNC',
          );
        }
      }

      if (cleaned > 0) {
        await _updatePendingCount();
        AppLogger.i(
          'Limpiadas $cleaned operaciones con referencias inválidas',
          tag: 'SYNC',
        );
      } else {
        AppLogger.d('No se encontraron referencias inválidas', tag: 'SYNC');
      }
    } catch (e) {
      AppLogger.e('Error en limpieza automática: $e', tag: 'SYNC');
    }
  }

  /// Limpieza one-time: Eliminar operación rota ID 9
  /// Esta operación intenta UPDATE de un producto offline que ya fue creado en el servidor
  Future<void> _cleanupBrokenOperation9() async {
    try {
      // Verificar que la base de datos esté inicializada correctamente
      if (!_isarDatabase.isInitialized) {
        AppLogger.d('ISAR no inicializado, saltando limpieza', tag: 'SYNC');
        return;
      }

      final operation = await _isarDatabase.database.syncOperations.get(9);

      if (operation != null) {
        AppLogger.d(
          'Operación rota encontrada: ${operation.entityType} (${operation.entityId}) - ${operation.operationType.name} - ${operation.status.name}',
          tag: 'SYNC',
        );

        // Verificar que es el producto offline específico que ya fue creado
        if (operation.entityId == 'product_offline_1766860497475_711632557' &&
            operation.operationType == SyncOperationType.update) {
          AppLogger.d(
            'Eliminando operación rota (producto ya fue creado en servidor)...',
            tag: 'SYNC',
          );
          await _isarDatabase.deleteSyncOperation(9);
          await _updatePendingCount();
          AppLogger.i('Operación ID 9 eliminada exitosamente', tag: 'SYNC');
        } else {
          AppLogger.w(
            'Operación ID 9 existe pero no coincide con el patrón esperado',
            tag: 'SYNC',
          );
        }
      }
      // Si operation es null, ya fue limpiada - no es necesario loggear
    } catch (e) {
      // Silenciar errores de schema mismatch - no son críticos
      if (e.toString().contains('syncOperations') ||
          e.toString().contains('NoSuchMethodError')) {
        // Schema mismatch - la base de datos necesita ser recreada
        // Esto se resuelve automáticamente al cerrar y reabrir la app
        return;
      }
      AppLogger.e('Error limpiando operación ID 9: $e', tag: 'SYNC');
    }
  }

  /// Limpieza automática: Eliminar operaciones de notificaciones dinámicas
  /// Las notificaciones dinámicas (stock_*, invoice_*, payment_*, etc.) son generadas
  /// por el dashboard y no existen como registros en la base de datos del servidor.
  /// No deben intentar sincronizarse.
  Future<void> _cleanupDynamicNotificationOperations() async {
    try {
      // Verificar que la base de datos esté inicializada correctamente
      if (!_isarDatabase.isInitialized) {
        AppLogger.d(
          'ISAR no inicializado, saltando limpieza de notificaciones dinámicas',
          tag: 'SYNC',
        );
        return;
      }

      final operations = await _isarDatabase.getPendingOperations();
      int cleaned = 0;

      // Buscar operaciones de notificaciones con IDs dinámicos
      for (final operation in operations.where(
        (op) => op.entityType == 'Notification',
      )) {
        if (_isDynamicNotification(operation.entityId)) {
          AppLogger.d(
            'Eliminando operación de notificación dinámica: ${operation.entityId}',
            tag: 'SYNC',
          );
          await _isarDatabase.deleteSyncOperation(operation.id);
          cleaned++;
        }
      }

      if (cleaned > 0) {
        await _updatePendingCount();
        AppLogger.i(
          'Limpiadas $cleaned operaciones de notificaciones dinámicas',
          tag: 'SYNC',
        );
      }
    } catch (e) {
      // Silenciar errores de schema mismatch
      if (e.toString().contains('syncOperations') ||
          e.toString().contains('NoSuchMethodError')) {
        return;
      }
      AppLogger.e(
        'Error limpiando operaciones de notificaciones dinámicas: $e',
        tag: 'SYNC',
      );
    }
  }

  // ==================== MÉTODOS DE SINCRONIZACIÓN POR ENTIDAD ====================

  /// Sincronizar operación de Product
  Future<void> _syncProductOperation(SyncOperation operation) async {
    try {
      // Importar dinámicamente el datasource de productos
      final ProductRemoteDataSource remoteDataSource =
          Get.find<ProductRemoteDataSource>();

      // Parsear payload como JSON
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d('Creando producto en servidor: ${data['name']}');

          // ✅ IMPORTANTE: Si es producto offline, leer datos ACTUALES de ISAR
          // Los datos del payload pueden estar desactualizados si el usuario editó el producto
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('product_offline_')) {
            AppLogger.d(
              'Producto offline detectado - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              // Obtener producto actual de ISAR usando el repositorio offline
              final offlineRepo = Get.find<ProductOfflineRepository>();
              final productResult = await offlineRepo.getProductById(
                operation.entityId,
              );

              productResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo producto offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (product) {
                  // Usar datos actuales del producto en lugar del payload
                  finalData = {
                    'name': product.name,
                    'description': product.description,
                    'sku': product.sku,
                    'barcode': product.barcode,
                    'type': product.type.name,
                    'status': product.status.name,
                    'stock': product.stock,
                    'minStock': product.minStock,
                    'unit': product.unit,
                    'weight': product.weight,
                    'length': product.length,
                    'width': product.width,
                    'height': product.height,
                    'images': product.images,
                    'metadata': product.metadata,
                    'categoryId': product.categoryId,
                    'prices':
                        product.prices
                            ?.map(
                              (p) => {
                                'type': p.type.name,
                                'name': p.name,
                                'amount': p.amount,
                                'currency': p.currency,
                                'discountPercentage': p.discountPercentage,
                                'discountAmount': p.discountAmount,
                                'minQuantity': p.minQuantity,
                                'notes': p.notes,
                              },
                            )
                            .toList(),
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR - ${product.prices?.length ?? 0} precios',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo producto de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          // Resolver categoryId temporal si es necesario
          String? resolvedCategoryId = finalData['categoryId'];
          if (resolvedCategoryId != null &&
              resolvedCategoryId.startsWith('category_offline_')) {
            AppLogger.d(
              'CategoryId temporal detectado: $resolvedCategoryId - buscando ID real en ISAR...',
              tag: 'SYNC',
            );
            try {
              final isar = IsarDatabase.instance.database;
              final isarCategory = await isar.isarCategorys
                  .filter()
                  .serverIdEqualTo(resolvedCategoryId)
                  .findFirst();
              if (isarCategory != null && !isarCategory.serverId.startsWith('category_offline_')) {
                resolvedCategoryId = isarCategory.serverId;
                AppLogger.d(
                  'CategoryId resuelto: $resolvedCategoryId',
                  tag: 'SYNC',
                );
              } else {
                AppLogger.w(
                  'CategoryId temporal no resuelto, enviando sin categoría',
                  tag: 'SYNC',
                );
                resolvedCategoryId = null;
              }
            } catch (e) {
              AppLogger.w(
                'Error resolviendo categoryId temporal: $e',
                tag: 'SYNC',
              );
              resolvedCategoryId = null;
            }
          }

          // Preparar request de creación
          final request = CreateProductRequestModel.fromParams(
            name: finalData['name'],
            description: finalData['description'],
            sku: finalData['sku'],
            barcode: finalData['barcode'],
            type:
                finalData['type'] != null
                    ? ProductType.values.firstWhere(
                      (e) => e.name == finalData['type'],
                    )
                    : null,
            status:
                finalData['status'] != null
                    ? ProductStatus.values.firstWhere(
                      (e) => e.name == finalData['status'],
                    )
                    : null,
            stock: finalData['stock']?.toDouble(),
            minStock: finalData['minStock']?.toDouble(),
            unit: finalData['unit'],
            weight: finalData['weight']?.toDouble(),
            length: finalData['length']?.toDouble(),
            width: finalData['width']?.toDouble(),
            height: finalData['height']?.toDouble(),
            images:
                finalData['images'] != null
                    ? List<String>.from(finalData['images'])
                    : null,
            metadata: finalData['metadata'],
            categoryId: resolvedCategoryId ?? finalData['categoryId'] ?? '',
            prices:
                finalData['prices'] != null
                    ? (finalData['prices'] as List)
                        .map<CreateProductPriceParams>(
                          (p) => CreateProductPriceParams(
                            type: PriceType.values.firstWhere(
                              (e) => e.name == p['type'],
                            ),
                            name: p['name'],
                            amount: (p['amount'] as num).toDouble(),
                            currency: p['currency'],
                            discountPercentage:
                                p['discountPercentage'] != null
                                    ? (p['discountPercentage'] as num)
                                        .toDouble()
                                    : null,
                            discountAmount:
                                p['discountAmount'] != null
                                    ? (p['discountAmount'] as num).toDouble()
                                    : null,
                            minQuantity:
                                p['minQuantity'] != null
                                    ? (p['minQuantity'] as num).toDouble()
                                    : null,
                            notes: p['notes'],
                          ),
                        )
                        .toList()
                    : null,
            taxCategory:
                finalData['taxCategory'] != null
                    ? TaxCategory.values.firstWhere(
                      (e) => e.name == finalData['taxCategory'],
                    )
                    : null,
            taxRate: finalData['taxRate']?.toDouble(),
            isTaxable: finalData['isTaxable'],
            taxDescription: finalData['taxDescription'],
            retentionCategory:
                finalData['retentionCategory'] != null
                    ? RetentionCategory.values.firstWhere(
                      (e) => e.name == finalData['retentionCategory'],
                    )
                    : null,
            retentionRate: finalData['retentionRate']?.toDouble(),
            hasRetention: finalData['hasRetention'],
          );

          final createdProduct = await remoteDataSource.createProduct(request);
          AppLogger.i(
            'Producto creado en servidor con ID: ${createdProduct.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar producto offline en ISAR con el nuevo ID del servidor
          if (operation.entityId.startsWith('product_offline_')) {
            try {
              final isar = IsarDatabase.instance.database;

              // 1. Actualizar serverId en ISAR con ID real del servidor
              final isarProduct = await isar.isarProducts
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarProduct != null) {
                isarProduct.serverId = createdProduct.id;
                isarProduct.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarProducts.put(isarProduct);
                });
                // Persistir mapeo temp→real para resolver referencias en futuras sesiones
                await registerTempIdMapping(operation.entityId, createdProduct.id);
                AppLogger.i(
                  'ISAR producto actualizado: ${operation.entityId} → ${createdProduct.id}',
                  tag: 'SYNC',
                );
              }

              // 2. Eliminar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                  AppLogger.d(
                    'Operación UPDATE obsoleta eliminada para ${operation.entityId}',
                    tag: 'SYNC',
                  );
                }
              }

              // 3. Actualizar productId en ops pendientes que referencian el temp ID
              final tempProductId = operation.entityId;
              final realProductId = createdProduct.id;
              for (final op in pendingOps) {
                // Actualizar en Invoice y PurchaseOrder (create + update)
                final isInvoice = op.entityType == 'Invoice' || op.entityType == 'invoice';
                final isPO = op.entityType == 'PurchaseOrder' || op.entityType == 'purchase_order';
                if (isInvoice || isPO) {
                  try {
                    final opPayload = jsonDecode(op.payload);
                    bool updated = false;

                    // Actualizar productId en items
                    if (opPayload['items'] != null) {
                      for (final item in opPayload['items']) {
                        if (item['productId'] == tempProductId) {
                          item['productId'] = realProductId;
                          updated = true;
                        }
                      }
                    }

                    if (updated) {
                      await _isarDatabase.updateSyncOperationPayload(
                        op.id,
                        jsonEncode(opPayload),
                      );
                      AppLogger.i(
                        'ProductId actualizado en ${op.entityType} pendiente: $tempProductId → $realProductId',
                        tag: 'SYNC',
                      );
                    }
                  } catch (e) {
                    AppLogger.w('Error actualizando productId en op ${op.id}: $e', tag: 'SYNC');
                  }
                }

                // Actualizar productId en InventoryMovement pendientes
                final isMovement = op.entityType == 'InventoryMovement' || op.entityType == 'inventory_movement';
                if (isMovement && op.operationType == SyncOperationType.create) {
                  try {
                    final opPayload = jsonDecode(op.payload);
                    if (opPayload['productId'] == tempProductId) {
                      opPayload['productId'] = realProductId;
                      await _isarDatabase.updateSyncOperationPayload(
                        op.id,
                        jsonEncode(opPayload),
                      );
                      AppLogger.i(
                        'ProductId actualizado en InventoryMovement pendiente ${op.entityId}: $tempProductId → $realProductId',
                        tag: 'SYNC',
                      );
                    }
                  } catch (e) {
                    AppLogger.w('Error actualizando productId en InventoryMovement op ${op.id}: $e', tag: 'SYNC');
                  }
                }
              }

              // 4. Actualizar productId en IsarPurchaseOrderItem que referencian el temp ID
              try {
                final isar = IsarDatabase.instance.database;
                final poItems = await isar.isarPurchaseOrderItems
                    .filter()
                    .productIdEqualTo(tempProductId)
                    .findAll();
                if (poItems.isNotEmpty) {
                  await isar.writeTxn(() async {
                    for (final poItem in poItems) {
                      poItem.productId = realProductId;
                    }
                    await isar.isarPurchaseOrderItems.putAll(poItems);
                  });
                  AppLogger.i(
                    'ProductId actualizado en ${poItems.length} IsarPurchaseOrderItems: $tempProductId → $realProductId',
                    tag: 'SYNC',
                  );
                }
              } catch (e) {
                AppLogger.w(
                  'Error actualizando productId en PO items ISAR: $e',
                  tag: 'SYNC',
                );
              }

              AppLogger.i(
                'Producto offline sincronizado: ${operation.entityId} → ${createdProduct.id}',
                tag: 'SYNC',
              );
            } catch (e) {
              AppLogger.w(
                'Error en post-sync de producto: $e',
                tag: 'SYNC',
              );
              // No hacer rethrow - la creación fue exitosa, este es solo cleanup
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando producto en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );

          // Resolver categoryId temporal en UPDATE también
          String? updateCategoryId = data['categoryId'];
          if (updateCategoryId != null &&
              updateCategoryId.startsWith('category_offline_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarCat = await isar.isarCategorys
                  .filter()
                  .serverIdEqualTo(updateCategoryId)
                  .findFirst();
              if (isarCat != null && !isarCat.serverId.startsWith('category_offline_')) {
                updateCategoryId = isarCat.serverId;
              } else {
                updateCategoryId = null;
              }
            } catch (_) {
              updateCategoryId = null;
            }
          }

          // Preparar request de actualización
          final updateRequest = UpdateProductRequestModel.fromParams(
            name: data['name'],
            description: data['description'],
            sku: data['sku'],
            barcode: data['barcode'],
            type:
                data['type'] != null
                    ? ProductType.values.firstWhere(
                      (e) => e.name == data['type'],
                    )
                    : null,
            status:
                data['status'] != null
                    ? ProductStatus.values.firstWhere(
                      (e) => e.name == data['status'],
                    )
                    : null,
            stock: data['stock']?.toDouble(),
            minStock: data['minStock']?.toDouble(),
            unit: data['unit'],
            weight: data['weight']?.toDouble(),
            length: data['length']?.toDouble(),
            width: data['width']?.toDouble(),
            height: data['height']?.toDouble(),
            images:
                data['images'] != null
                    ? List<String>.from(data['images'])
                    : null,
            metadata: data['metadata'],
            categoryId: updateCategoryId,
            prices:
                data['prices'] != null
                    ? (data['prices'] as List)
                        .map(
                          (p) => UpdateProductPriceRequestModel(
                            id: p['id'],
                            type: p['type'],
                            name: p['name'],
                            amount: p['amount'].toDouble(),
                            currency: p['currency'],
                            discountPercentage:
                                p['discountPercentage']?.toDouble(),
                            discountAmount: p['discountAmount']?.toDouble(),
                            minQuantity: p['minQuantity']?.toDouble(),
                            notes: p['notes'],
                          ),
                        )
                        .toList()
                    : null,
            taxCategory:
                data['taxCategory'] != null
                    ? TaxCategory.values.firstWhere(
                      (e) => e.name == data['taxCategory'],
                    )
                    : null,
            taxRate: data['taxRate']?.toDouble(),
            isTaxable: data['isTaxable'],
            taxDescription: data['taxDescription'],
            retentionCategory:
                data['retentionCategory'] != null
                    ? RetentionCategory.values.firstWhere(
                      (e) => e.name == data['retentionCategory'],
                    )
                    : null,
            retentionRate: data['retentionRate']?.toDouble(),
            hasRetention: data['hasRetention'],
          );

          await remoteDataSource.updateProduct(
            operation.entityId,
            updateRequest,
          );
          AppLogger.i(
            'Producto actualizado en servidor exitosamente',
            tag: 'SYNC',
          );
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando producto en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteProduct(operation.entityId);
          AppLogger.i(
            'Producto eliminado en servidor exitosamente',
            tag: 'SYNC',
          );
          break;

        default:
          throw Exception('Operación no soportada: ${operation.operationType}');
      }
    } catch (e) {
      // Detectar errores 409 (Conflict) - Item ya existe en servidor
      if (e is ServerException && e.statusCode == 409) {
        // NO hacer rethrow - esto marcará la operación como exitosa
        return;
      }

      // Solo mostrar stackTrace si NO es error de conexión
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection error') ||
          e.toString().contains('Error de conexión') ||
          e.toString().contains('SocketException')) {
        // Error de conexión esperado cuando backend está offline
        rethrow;
      } else {
        // Error inesperado que necesita debugging
        rethrow;
      }
    }
  }

  /// Sincronizar operación de Category
  Future<void> _syncCategoryOperation(SyncOperation operation) async {
    try {
      final CategoryRemoteDataSource remoteDataSource =
          Get.find<CategoryRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando categoría en servidor: ${data['name']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para categorías offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('category_offline_')) {
            AppLogger.d(
              'Categoría offline detectada - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<CategoryOfflineRepository>();
              final categoryResult = await offlineRepo.getCategoryById(
                operation.entityId,
              );

              categoryResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo categoría offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (category) {
                  // Usar datos actuales de la categoría en lugar del payload
                  finalData = {
                    'name': category.name,
                    'description': category.description,
                    'slug': category.slug,
                    'image': category.image,
                    'status': category.status.name,
                    'sortOrder': category.sortOrder,
                    'parentId': category.parentId,
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR para categoría: ${category.name}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo categoría de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          final request = CreateCategoryRequestModel.fromParams(
            name: finalData['name'],
            description: finalData['description'],
            slug: finalData['slug'],
            image: finalData['image'],
            status:
                finalData['status'] != null
                    ? CategoryStatus.values.firstWhere(
                      (e) => e.name == finalData['status'],
                    )
                    : null,
            sortOrder: finalData['sortOrder'],
            parentId: finalData['parentId'],
          );
          final createdCategory = await remoteDataSource.createCategory(request);
          AppLogger.i(
            'Categoría creada en servidor con ID: ${createdCategory.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('category_offline_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarCategory = await isar.isarCategorys
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarCategory != null) {
                isarCategory.serverId = createdCategory.id;
                isarCategory.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarCategorys.put(isarCategory);
                });
                AppLogger.i(
                  'ISAR categoría actualizada: ${operation.entityId} → ${createdCategory.id}',
                  tag: 'SYNC',
                );
              }

              // Cachear en SecureStorage
              try {
                final localDataSource = Get.find<CategoryLocalDataSource>();
                await localDataSource.cacheCategory(createdCategory);
              } catch (e) {
                AppLogger.w('Error cacheando categoría: $e', tag: 'SYNC');
              }

              // Limpiar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }

              // --- REFERENCE RESOLUTION: Actualizar productos que referencian esta categoría offline ---
              try {
                final oldCategoryId = operation.entityId;
                final newCategoryId = createdCategory.id;

                // 1. Actualizar IsarProducts en ISAR
                final productsWithOldCategory = await isar.isarProducts
                    .filter()
                    .categoryIdEqualTo(oldCategoryId)
                    .findAll();

                if (productsWithOldCategory.isNotEmpty) {
                  await isar.writeTxn(() async {
                    for (final product in productsWithOldCategory) {
                      product.categoryId = newCategoryId;
                      await isar.isarProducts.put(product);
                    }
                  });
                  AppLogger.i(
                    'Actualizados ${productsWithOldCategory.length} productos: categoryId $oldCategoryId → $newCategoryId',
                    tag: 'SYNC',
                  );
                }

                // 2. Actualizar payloads de SyncQueue pendientes de Product
                final allPendingOps = await _isarDatabase.getPendingSyncOperations();
                for (final op in allPendingOps) {
                  if (op.entityType == 'Product' || op.entityType == 'product') {
                    try {
                      final payload = jsonDecode(op.payload);
                      if (payload['categoryId'] == oldCategoryId) {
                        payload['categoryId'] = newCategoryId;
                        await _isarDatabase.updateSyncOperationPayload(
                          op.id,
                          jsonEncode(payload),
                        );
                        AppLogger.d(
                          'Payload actualizado para producto ${op.entityId}: categoryId → $newCategoryId',
                          tag: 'SYNC',
                        );
                      }
                    } catch (_) {}
                  }
                }
              } catch (e) {
                AppLogger.w('Error en reference resolution category→product: $e', tag: 'SYNC');
              }
            } catch (e) {
              AppLogger.w('Error actualizando categoría en ISAR: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando categoría en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          final updateRequest = UpdateCategoryRequestModel.fromParams(
            name: data['name'],
            description: data['description'],
            slug: data['slug'],
            image: data['image'],
            status:
                data['status'] != null
                    ? CategoryStatus.values.firstWhere(
                      (e) => e.name == data['status'],
                    )
                    : null,
            sortOrder: data['sortOrder'],
            parentId: data['parentId'],
          );
          await remoteDataSource.updateCategory(
            operation.entityId,
            updateRequest,
          );
          AppLogger.i('Categoría actualizada en servidor', tag: 'SYNC');
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando categoría en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteCategory(operation.entityId);
          AppLogger.i('Categoría eliminada en servidor', tag: 'SYNC');

          // Limpiar categoría de ISAR después de eliminar en servidor
          try {
            final isar = IsarDatabase.instance.database;
            final isarCategory = await isar.isarCategorys
                .filter()
                .serverIdEqualTo(operation.entityId)
                .findFirst();
            if (isarCategory != null) {
              await isar.writeTxn(() async {
                await isar.isarCategorys.delete(isarCategory.id);
              });
              AppLogger.d(
                'Categoría eliminada de ISAR: ${operation.entityId}',
                tag: 'SYNC',
              );
            }
          } catch (e) {
            AppLogger.w('Error limpiando categoría de ISAR: $e', tag: 'SYNC');
          }
          break;

        default:
          throw Exception('Operación no soportada: ${operation.operationType}');
      }
    } catch (e) {
      // Detectar errores 409 (Conflict) - Item ya existe en servidor
      if (e is ServerException && e.statusCode == 409) {
        // NO hacer rethrow - esto marcará la operación como exitosa
        return;
      }

      // Solo mostrar stackTrace si NO es error de conexión
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection error') ||
          e.toString().contains('Error de conexión') ||
          e.toString().contains('SocketException')) {
        // Error de conexión esperado cuando backend está offline
        rethrow;
      } else {
        // Error inesperado que necesita debugging
        rethrow;
      }
    }
  }

  /// Sincronizar operación de Customer
  Future<void> _syncCustomerOperation(SyncOperation operation) async {
    try {
      final CustomerRemoteDataSource remoteDataSource;
      if (Get.isRegistered<CustomerRemoteDataSource>()) {
        remoteDataSource = Get.find<CustomerRemoteDataSource>();
      } else {
        remoteDataSource = CustomerRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando cliente en servidor: ${data['firstName']} ${data['lastName']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para clientes offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('customer_offline_')) {
            AppLogger.d(
              'Cliente offline detectado - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<CustomerOfflineRepository>();
              final customerResult = await offlineRepo.getCustomerById(
                operation.entityId,
              );

              customerResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo cliente offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (customer) {
                  // Usar datos actuales del cliente en lugar del payload
                  finalData = {
                    'firstName': customer.firstName,
                    'lastName': customer.lastName,
                    'companyName': customer.companyName,
                    'email': customer.email,
                    'phone': customer.phone,
                    'mobile': customer.mobile,
                    'documentType': customer.documentType.name,
                    'documentNumber': customer.documentNumber,
                    'address': customer.address,
                    'city': customer.city,
                    'state': customer.state,
                    'zipCode': customer.zipCode,
                    'country': customer.country,
                    'creditLimit': customer.creditLimit,
                    'paymentTerms': customer.paymentTerms,
                    'notes': customer.notes,
                    'metadata': customer.metadata,
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR para cliente: ${customer.firstName} ${customer.lastName}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo cliente de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          // ✅ Usar constructor directo (no fromParams) porque finalData ya tiene strings
          // Normalizar teléfono al formato colombiano +57XXXXXXXXXX
          String? normalizedPhone = _normalizeColombianPhone(finalData['phone']);
          String? normalizedMobile = _normalizeColombianPhone(finalData['mobile']);

          final request = CreateCustomerRequestModel(
            firstName: finalData['firstName'],
            lastName: finalData['lastName'],
            companyName: finalData['companyName'],
            email: finalData['email'] ?? '',
            phone: normalizedPhone,
            mobile: normalizedMobile,
            documentType: finalData['documentType'] ?? 'cc',
            documentNumber: finalData['documentNumber'] ?? '',
            address: finalData['address'],
            city: finalData['city'],
            state: finalData['state'],
            zipCode: finalData['zipCode'],
            country: finalData['country'] ?? 'Colombia',
            status: 'active',
            creditLimit: finalData['creditLimit']?.toDouble() ?? 0,
            paymentTerms: finalData['paymentTerms'] ?? 30,
            notes: finalData['notes'],
            metadata: finalData['metadata'],
          );
          final createdCustomer = await remoteDataSource.createCustomer(request);
          AppLogger.i(
            'Cliente creado en servidor con ID: ${createdCustomer.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('customer_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarCustomer = await isar.isarCustomers
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarCustomer != null) {
                isarCustomer.serverId = createdCustomer.id;
                isarCustomer.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarCustomers.put(isarCustomer);
                });
                AppLogger.i(
                  'ISAR cliente actualizado: ${operation.entityId} → ${createdCustomer.id}',
                  tag: 'SYNC',
                );
              }

              // Limpiar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }

              // ✅ CRÍTICO: Actualizar customerId temporal en Invoice/CreditNote/CustomerCredit/ClientBalance pendientes
              final tempCustomerId = operation.entityId;
              final realCustomerId = createdCustomer.id;
              if (tempCustomerId != realCustomerId) {
                for (final op in pendingOps) {
                  if ((op.entityType == 'Invoice' || op.entityType == 'invoice' ||
                       op.entityType == 'CreditNote' || op.entityType == 'credit_note' ||
                       op.entityType == 'CustomerCredit' || op.entityType == 'customer_credit' ||
                       op.entityType == 'ClientBalance' || op.entityType == 'client_balance') &&
                      op.operationType == SyncOperationType.create) {
                    try {
                      final opPayload = jsonDecode(op.payload);
                      final opCustomerId = opPayload['customerId'] as String?;
                      if (opCustomerId == tempCustomerId) {
                        opPayload['customerId'] = realCustomerId;
                        await _isarDatabase.updateSyncOperationPayload(
                          op.id,
                          jsonEncode(opPayload),
                        );
                        AppLogger.i(
                          'Actualizado customerId en ${op.entityType}:${op.entityId}: $tempCustomerId → $realCustomerId',
                          tag: 'SYNC',
                        );
                      }
                    } catch (e) {
                      AppLogger.w('Error actualizando customerId en ${op.entityType}: $e', tag: 'SYNC');
                    }
                  }
                }
              }
            } catch (e) {
              AppLogger.w('Error actualizando cliente en ISAR: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando cliente en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          // ✅ Usar constructor directo (no fromParams) porque data ya tiene strings
          final updateRequest = UpdateCustomerRequestModel(
            firstName: data['firstName'],
            lastName: data['lastName'],
            companyName: data['companyName'],
            email: data['email'],
            phone: _normalizeColombianPhone(data['phone']),
            mobile: _normalizeColombianPhone(data['mobile']),
            documentType: data['documentType'],
            documentNumber: data['documentNumber'],
            address: data['address'],
            city: data['city'],
            state: data['state'],
            zipCode: data['zipCode'],
            country: data['country'],
            status: data['status'],
            creditLimit: data['creditLimit']?.toDouble(),
            paymentTerms: data['paymentTerms'],
            notes: data['notes'],
            metadata: data['metadata'] != null
                ? Map<String, dynamic>.from(data['metadata'])
                : null,
          );
          await remoteDataSource.updateCustomer(
            operation.entityId,
            updateRequest,
          );
          AppLogger.i('Cliente actualizado en servidor', tag: 'SYNC');

          // ✅ Marcar como synced en ISAR (patrón Supplier)
          try {
            final isar = IsarDatabase.instance.database;
            final isarCustomer = await isar.isarCustomers
                .filter()
                .serverIdEqualTo(operation.entityId)
                .findFirst();
            if (isarCustomer != null) {
              isarCustomer.markAsSynced();
              await isar.writeTxn(() => isar.isarCustomers.put(isarCustomer));
              AppLogger.d('Cliente marcado como synced en ISAR', tag: 'SYNC');
            }
          } catch (e) {
            AppLogger.w('Error marcando cliente como synced en ISAR: $e', tag: 'SYNC');
          }
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando cliente en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteCustomer(operation.entityId);
          AppLogger.i('Cliente eliminado en servidor', tag: 'SYNC');
          break;

        default:
          throw Exception('Operación no soportada: ${operation.operationType}');
      }
    } catch (e) {
      AppLogger.e(
        'Error en sync Customer ${operation.operationType}: $e (tipo: ${e.runtimeType})',
        tag: 'SYNC',
      );
      if (e is ServerException) {
        AppLogger.e(
          'ServerException statusCode=${e.statusCode}, message=${e.message}',
          tag: 'SYNC',
        );
        // 409 Conflict - cliente ya existe en servidor
        if (e.statusCode == 409) {
          AppLogger.w(
            'Cliente ya existe en servidor - marcando como completado',
            tag: 'SYNC',
          );
          return;
        }
        // 400/422 - errores de validación que no se resolverán con retries
        if (e.statusCode == 400 || e.statusCode == 422) {
          AppLogger.e(
            'Error de validación en sync Customer (${e.statusCode}): ${e.message} - marcando como completado para no bloquear cola',
            tag: 'SYNC',
          );
          return;
        }
      }
      rethrow;
    }
  }

  /// Sincronizar operación de Supplier
  Future<void> _syncSupplierOperation(SyncOperation operation) async {
    try {
      final SupplierRemoteDataSource remoteDataSource;
      if (Get.isRegistered<SupplierRemoteDataSource>()) {
        remoteDataSource = Get.find<SupplierRemoteDataSource>();
      } else {
        remoteDataSource = SupplierRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando proveedor en servidor: ${data['name']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para proveedores offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('supplier_offline_')) {
            AppLogger.d(
              'Proveedor offline detectado - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<SupplierOfflineRepository>();
              final supplierResult = await offlineRepo.getSupplierById(
                operation.entityId,
              );

              supplierResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo proveedor offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (supplier) {
                  finalData = {
                    'name': supplier.name,
                    'contactPerson': supplier.contactPerson,
                    'email': supplier.email,
                    'phone': supplier.phone,
                    'mobile': supplier.mobile,
                    'address': supplier.address,
                    'city': supplier.city,
                    'state': supplier.state,
                    'country': supplier.country,
                    'postalCode': supplier.postalCode,
                    'documentNumber': supplier.documentNumber,
                    'website': supplier.website,
                    'notes': supplier.notes,
                    'paymentTermsDays': supplier.paymentTermsDays,
                    'creditLimit': supplier.creditLimit,
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR para proveedor: ${supplier.name}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo proveedor de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          final request = CreateSupplierRequestModel.fromJson(finalData);
          final createdSupplier = await remoteDataSource.createSupplier(request);
          AppLogger.i(
            'Proveedor creado en servidor con ID: ${createdSupplier.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('supplier_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarSupplier = await isar.isarSuppliers
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarSupplier != null) {
                isarSupplier.serverId = createdSupplier.id;
                isarSupplier.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarSuppliers.put(isarSupplier);
                });
                AppLogger.i(
                  'ISAR proveedor actualizado: ${operation.entityId} → ${createdSupplier.id}',
                  tag: 'SYNC',
                );
              }

              // Limpiar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }

              // ✅ CRÍTICO: Actualizar supplierId temporal en PurchaseOrder pendientes
              // DRY: Replica patrón Customer CREATE → Invoice (L2705-2733)
              final tempSupplierId = operation.entityId;
              final realSupplierId = createdSupplier.id;
              if (tempSupplierId != realSupplierId) {
                for (final op in pendingOps) {
                  if ((op.entityType == 'PurchaseOrder' || op.entityType == 'purchase_order') &&
                      op.operationType == SyncOperationType.create) {
                    try {
                      final opPayload = jsonDecode(op.payload);
                      final opSupplierId = opPayload['supplierId'] as String?;
                      if (opSupplierId == tempSupplierId) {
                        opPayload['supplierId'] = realSupplierId;
                        await _isarDatabase.updateSyncOperationPayload(
                          op.id,
                          jsonEncode(opPayload),
                        );

                        // También actualizar en ISAR
                        final isarPO = await isar.isarPurchaseOrders
                            .filter()
                            .serverIdEqualTo(op.entityId)
                            .findFirst();
                        if (isarPO != null) {
                          isarPO.supplierId = realSupplierId;
                          await isar.writeTxn(() => isar.isarPurchaseOrders.put(isarPO));
                        }

                        AppLogger.i(
                          'Actualizado supplierId en PO:${op.entityId}: $tempSupplierId → $realSupplierId',
                          tag: 'SYNC',
                        );
                      }
                    } catch (e) {
                      AppLogger.w('Error actualizando supplierId en PO: $e', tag: 'SYNC');
                    }
                  }
                }
              }
            } catch (e) {
              AppLogger.w('Error actualizando proveedor en ISAR: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          final action = data['action'] as String?;
          AppLogger.d(
            'Actualizando proveedor en servidor: ${operation.entityId} (action: $action)',
            tag: 'SYNC',
          );

          if (action == 'updateStatus') {
            final status = data['status'] as String? ?? 'active';
            await remoteDataSource.updateSupplierStatus(
              operation.entityId,
              status,
            );
            AppLogger.i('Estado de proveedor actualizado en servidor: $status', tag: 'SYNC');
          } else if (action == 'restore') {
            await remoteDataSource.restoreSupplier(operation.entityId);
            AppLogger.i('Proveedor restaurado en servidor', tag: 'SYNC');
          } else {
            final updateRequest = UpdateSupplierRequestModel.fromJson(data);
            await remoteDataSource.updateSupplier(
              operation.entityId,
              updateRequest,
            );
            AppLogger.i('Proveedor actualizado en servidor', tag: 'SYNC');
          }

          // Marcar como synced en ISAR
          try {
            final isar = IsarDatabase.instance.database;
            final isarSupplier = await isar.isarSuppliers
                .filter()
                .serverIdEqualTo(operation.entityId)
                .findFirst();
            if (isarSupplier != null) {
              isarSupplier.markAsSynced();
              await isar.writeTxn(() => isar.isarSuppliers.put(isarSupplier));
            }
          } catch (_) {}
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando proveedor en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteSupplier(operation.entityId);
          AppLogger.i('Proveedor eliminado en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Proveedor ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de Expense
  Future<void> _syncExpenseOperation(SyncOperation operation) async {
    try {
      final ExpenseRemoteDataSource remoteDataSource =
          Get.find<ExpenseRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando gasto en servidor: ${data['description']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para gastos offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('expense_')) {
            AppLogger.d(
              'Gasto offline detectado - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<ExpenseOfflineRepository>();
              final expenseResult = await offlineRepo.getExpenseById(
                operation.entityId,
              );

              expenseResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo gasto offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (expense) {
                  finalData = {
                    'description': expense.description,
                    'amount': expense.amount,
                    'date': expense.date.toIso8601String(),
                    'categoryId': expense.categoryId,
                    'type': expense.type.name,
                    'paymentMethod': expense.paymentMethod.name,
                    'vendor': expense.vendor,
                    'invoiceNumber': expense.invoiceNumber,
                    'reference': expense.reference,
                    'notes': expense.notes,
                    'attachments': expense.attachments,
                    'tags': expense.tags,
                    'metadata': expense.metadata,
                    'status': expense.status.name,
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR para gasto: ${expense.description}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo gasto de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          final request = CreateExpenseRequestModel.fromParams(
            description: finalData['description'],
            amount: (finalData['amount'] as num).toDouble(),
            date:
                finalData['date'] is DateTime
                    ? finalData['date']
                    : DateTime.parse(finalData['date']),
            categoryId: finalData['categoryId'],
            type:
                finalData['type'] is ExpenseType
                    ? finalData['type']
                    : ExpenseType.values.firstWhere(
                      (e) => e.name == finalData['type'],
                    ),
            paymentMethod:
                finalData['paymentMethod'] is PaymentMethod
                    ? finalData['paymentMethod']
                    : PaymentMethod.values.firstWhere(
                      (e) => e.name == finalData['paymentMethod'],
                    ),
            vendor: finalData['vendor'],
            invoiceNumber: finalData['invoiceNumber'],
            reference: finalData['reference'],
            notes: finalData['notes'],
            attachments:
                finalData['attachments'] != null
                    ? List<String>.from(finalData['attachments'])
                    : null,
            tags:
                finalData['tags'] != null
                    ? List<String>.from(finalData['tags'])
                    : null,
            metadata: finalData['metadata'],
            status:
                finalData['status'] != null
                    ? (finalData['status'] is ExpenseStatus
                        ? finalData['status']
                        : ExpenseStatus.values.firstWhere(
                          (e) => e.name == finalData['status'],
                        ))
                    : null,
          );
          final createdExpense = await remoteDataSource.createExpense(request);
          AppLogger.i(
            'Gasto creado en servidor con ID: ${createdExpense.id}',
            tag: 'SYNC',
          );

          // ✅ CRÍTICO: Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('expense_offline_') ||
              operation.entityId.startsWith('expense_')) {
            try {
              final isar = IsarDatabase.instance.database;

              // Buscar el registro ISAR con el ID temporal
              final isarExpense = await isar.isarExpenses
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarExpense != null) {
                // Actualizar con el ID real del servidor
                isarExpense.serverId = createdExpense.id;
                isarExpense.markAsSynced();

                await isar.writeTxn(() async {
                  await isar.isarExpenses.put(isarExpense);
                });

                AppLogger.i(
                  'ISAR actualizado: ${operation.entityId} → ${createdExpense.id}',
                  tag: 'SYNC',
                );
              } else {
                AppLogger.w(
                  'No se encontró gasto en ISAR con serverId: ${operation.entityId}',
                  tag: 'SYNC',
                );
              }

              // Cachear en SecureStorage
              try {
                final localDataSource = Get.find<ExpenseLocalDataSource>();
                await localDataSource.cacheExpense(createdExpense);
                AppLogger.d(
                  'Gasto cacheado en SecureStorage: ${createdExpense.id}',
                  tag: 'SYNC',
                );
              } catch (e) {
                AppLogger.w(
                  'Error cacheando gasto en SecureStorage: $e',
                  tag: 'SYNC',
                );
              }

              // Eliminar operaciones UPDATE obsoletas para este gasto offline
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                  AppLogger.d(
                    'Operación UPDATE obsoleta eliminada para ${operation.entityId}',
                    tag: 'SYNC',
                  );
                }
              }
            } catch (e) {
              AppLogger.w(
                'Error actualizando gasto offline en ISAR: $e',
                tag: 'SYNC',
              );
              // No rethrow - la creación en servidor fue exitosa
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando gasto en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );

          // Verificar si es una acción de cambio de estado
          final action = data['action'] as String?;

          if (action != null) {
            // Operación de cambio de estado específica
            AppLogger.d(
              'Procesando acción de estado: $action para gasto ${operation.entityId}',
              tag: 'SYNC',
            );
            switch (action) {
              case 'expense_submit':
                await remoteDataSource.submitExpense(operation.entityId);
                AppLogger.i('Gasto enviado para aprobación en servidor', tag: 'SYNC');
                break;
              case 'expense_approve':
                await remoteDataSource.approveExpense(
                  operation.entityId,
                  data['notes'] as String?,
                );
                AppLogger.i('Gasto aprobado en servidor', tag: 'SYNC');
                break;
              case 'expense_reject':
                await remoteDataSource.rejectExpense(
                  operation.entityId,
                  data['reason'] as String? ?? '',
                );
                AppLogger.i('Gasto rechazado en servidor', tag: 'SYNC');
                break;
              case 'expense_paid':
                await remoteDataSource.markAsPaid(operation.entityId);
                AppLogger.i('Gasto marcado como pagado en servidor', tag: 'SYNC');
                break;
              default:
                AppLogger.w(
                  'Acción de gasto desconocida: $action - intentando update regular',
                  tag: 'SYNC',
                );
                await _performRegularExpenseUpdate(operation, data, remoteDataSource);
            }
          } else {
            // Update regular de campos del gasto
            await _performRegularExpenseUpdate(operation, data, remoteDataSource);
          }
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando gasto en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteExpense(operation.entityId);
          AppLogger.i('Gasto eliminado en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Gasto ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Realiza un update regular de campos de gasto (no cambio de estado)
  Future<void> _performRegularExpenseUpdate(
    SyncOperation operation,
    Map<String, dynamic> data,
    ExpenseRemoteDataSource remoteDataSource,
  ) async {
    final updateRequest = UpdateExpenseRequestModel.fromParams(
      description: data['description'],
      amount: data['amount'] != null
          ? (data['amount'] as num).toDouble()
          : null,
      date: data['date'] != null ? DateTime.parse(data['date']) : null,
      categoryId: data['categoryId'],
      type: data['type'] != null
          ? ExpenseType.values.firstWhere(
              (e) => e.name == data['type'],
            )
          : null,
      paymentMethod: data['paymentMethod'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == data['paymentMethod'],
            )
          : null,
      vendor: data['vendor'],
      invoiceNumber: data['invoiceNumber'],
      reference: data['reference'],
      notes: data['notes'],
      attachments: data['attachments'] != null
          ? List<String>.from(data['attachments'])
          : null,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      metadata: data['metadata'],
    );
    await remoteDataSource.updateExpense(
      operation.entityId,
      updateRequest,
    );
    AppLogger.i('Gasto actualizado en servidor', tag: 'SYNC');
  }

  /// Sincronizar operación de ExpenseCategory
  Future<void> _syncExpenseCategoryOperation(SyncOperation operation) async {
    try {
      final ExpenseRemoteDataSource remoteDataSource =
          Get.find<ExpenseRemoteDataSource>();
      final ExpenseLocalDataSource localDataSource =
          Get.find<ExpenseLocalDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando categoría de gasto en servidor: ${data['name']}',
            tag: 'SYNC',
          );

          final request = CreateExpenseCategoryRequestModel.fromParams(
            name: data['name'],
            description: data['description'],
            color: data['color'],
            monthlyBudget: data['monthlyBudget'] != null
                ? (data['monthlyBudget'] as num).toDouble()
                : null,
            sortOrder: data['sortOrder'] != null
                ? (data['sortOrder'] as num).toInt()
                : null,
          );

          final createdCategory = await remoteDataSource.createExpenseCategory(request);
          AppLogger.i(
            'Categoría de gasto creada en servidor: ${createdCategory.id}',
            tag: 'SYNC',
          );

          // Actualizar cache local con ID real
          if (operation.entityId.startsWith('expense_category_offline_')) {
            try {
              // Eliminar la categoría temporal del cache
              await localDataSource.removeCachedExpenseCategory(operation.entityId);
              // Guardar con ID real
              await localDataSource.cacheExpenseCategory(createdCategory);

              // Actualizar referencias en operaciones pendientes de Expense que usen este categoryId temporal
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityType == 'Expense' || op.entityType == 'expense') {
                  final opData = jsonDecode(op.payload);
                  if (opData['categoryId'] == operation.entityId) {
                    opData['categoryId'] = createdCategory.id;
                    await _isarDatabase.updateSyncOperationPayload(
                      op.id,
                      jsonEncode(opData),
                    );
                    AppLogger.d(
                      'Referencia de categoryId actualizada en Expense pendiente: ${op.entityId}',
                      tag: 'SYNC',
                    );
                  }
                }
              }

              // Actualizar categoryId en IsarExpenses que usen el ID temporal
              try {
                final isar = IsarDatabase.instance.database;
                final expensesWithTempCat = await isar.isarExpenses
                    .filter()
                    .categoryIdEqualTo(operation.entityId)
                    .findAll();

                if (expensesWithTempCat.isNotEmpty) {
                  await isar.writeTxn(() async {
                    for (final expense in expensesWithTempCat) {
                      expense.categoryId = createdCategory.id;
                      await isar.isarExpenses.put(expense);
                    }
                  });
                  AppLogger.d(
                    'Actualizados ${expensesWithTempCat.length} gastos con nuevo categoryId',
                    tag: 'SYNC',
                  );
                }
              } catch (e) {
                AppLogger.w('Error actualizando categoryId en ISAR expenses: $e', tag: 'SYNC');
              }

              // Eliminar operaciones UPDATE obsoletas
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }

              AppLogger.i(
                'Cache actualizado: ${operation.entityId} → ${createdCategory.id}',
                tag: 'SYNC',
              );
            } catch (e) {
              AppLogger.w('Error actualizando cache de categoría: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando categoría de gasto: ${operation.entityId}',
            tag: 'SYNC',
          );

          final request = CreateExpenseCategoryRequestModel.fromParams(
            name: data['name'] ?? '',
            description: data['description'],
            color: data['color'],
            monthlyBudget: data['monthlyBudget'] != null
                ? (data['monthlyBudget'] as num).toDouble()
                : null,
            sortOrder: data['sortOrder'] != null
                ? (data['sortOrder'] as num).toInt()
                : null,
          );

          final updatedCategory = await remoteDataSource.updateExpenseCategory(
            operation.entityId,
            request,
          );
          await localDataSource.cacheExpenseCategory(updatedCategory);
          AppLogger.i('Categoría de gasto actualizada en servidor', tag: 'SYNC');
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando categoría de gasto: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteExpenseCategory(operation.entityId);
          AppLogger.i('Categoría de gasto eliminada en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Categoría de gasto ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de BankAccount
  Future<void> _syncBankAccountOperation(SyncOperation operation) async {
    try {
      final BankAccountRemoteDataSource remoteDataSource =
          Get.find<BankAccountRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando cuenta bancaria en servidor: ${data['name']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para cuentas bancarias offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('bankaccount_offline_')) {
            AppLogger.d(
              'Cuenta bancaria offline detectada - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<BankAccountOfflineRepository>();
              final accountResult = await offlineRepo.getBankAccountById(
                operation.entityId,
              );

              accountResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo cuenta bancaria offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (account) {
                  finalData = {
                    'name': account.name,
                    'type': account.type.name,
                    'bankName': account.bankName,
                    'accountNumber': account.accountNumber,
                    'holderName': account.holderName,
                    'icon': account.icon,
                    'isActive': account.isActive,
                    'isDefault': account.isDefault,
                    'sortOrder': account.sortOrder,
                    'description': account.description,
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR para cuenta bancaria: ${account.name}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo cuenta bancaria de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          final request = CreateBankAccountRequest(
            name: finalData['name'],
            type: finalData['type'],
            bankName: finalData['bankName'],
            accountNumber: finalData['accountNumber'],
            holderName: finalData['holderName'],
            icon: finalData['icon'],
            isActive: finalData['isActive'] ?? true,
            isDefault: finalData['isDefault'] ?? false,
            sortOrder: finalData['sortOrder'] ?? 0,
            description: finalData['description'],
          );
          final createdBankAccount = await remoteDataSource.createBankAccount(request);
          AppLogger.i(
            'Cuenta bancaria creada en servidor con ID: ${createdBankAccount.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('bank_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarBankAccount = await isar.isarBankAccounts
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarBankAccount != null) {
                isarBankAccount.serverId = createdBankAccount.id;
                isarBankAccount.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarBankAccounts.put(isarBankAccount);
                });
                AppLogger.i(
                  'ISAR cuenta bancaria actualizada: ${operation.entityId} → ${createdBankAccount.id}',
                  tag: 'SYNC',
                );
              }

              // Limpiar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }
            } catch (e) {
              AppLogger.w('Error actualizando cuenta bancaria en ISAR: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando cuenta bancaria en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          final updateRequest = UpdateBankAccountRequest(
            name: data['name'],
            type: data['type'],
            bankName: data['bankName'],
            accountNumber: data['accountNumber'],
            holderName: data['holderName'],
            icon: data['icon'],
            isActive: data['isActive'],
            isDefault: data['isDefault'],
            sortOrder: data['sortOrder'],
            description: data['description'],
          );
          await remoteDataSource.updateBankAccount(
            operation.entityId,
            updateRequest,
          );
          AppLogger.i('Cuenta bancaria actualizada en servidor', tag: 'SYNC');
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando cuenta bancaria en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteBankAccount(operation.entityId);
          AppLogger.i('Cuenta bancaria eliminada en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Cuenta bancaria ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de Invoice
  Future<void> _syncInvoiceOperation(SyncOperation operation) async {
    try {
      final InvoiceRemoteDataSource remoteDataSource;
      if (Get.isRegistered<InvoiceRemoteDataSource>()) {
        remoteDataSource = Get.find<InvoiceRemoteDataSource>();
      } else {
        remoteDataSource = InvoiceRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          // ✅ DEBUG: Verificar items en payload original
          final payloadItems = data['items'];
          AppLogger.d(
            'Creando factura en servidor: ${data['customerId']} - Items en payload: ${payloadItems is List ? payloadItems.length : "null/inválido"}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para facturas offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('invoice_offline_')) {
            AppLogger.d(
              'Factura offline detectada - verificando datos de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<InvoiceOfflineRepository>();
              final invoiceResult = await offlineRepo.getInvoiceById(
                operation.entityId,
              );

              invoiceResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo factura offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (invoice) {
                  // ✅ CRÍTICO: Verificar si ISAR tiene items
                  // Si ISAR no tiene items, MANTENER los items del payload original
                  final hasItemsInIsar = invoice.items.isNotEmpty;
                  final hasItemsInPayload = data['items'] != null &&
                      (data['items'] as List).isNotEmpty;

                  AppLogger.d(
                    'Items en ISAR: ${invoice.items.length}, Items en payload: ${hasItemsInPayload ? (data['items'] as List).length : 0}',
                    tag: 'SYNC',
                  );

                  // Usar items de ISAR si existen, sino mantener del payload
                  final itemsToUse = hasItemsInIsar
                      ? invoice.items
                          .map(
                            (item) => {
                              'productId': item.productId,
                              'description': item.description,
                              'quantity': item.quantity,
                              'unitPrice': item.unitPrice,
                              'unit': item.unit,
                              'discountPercentage': item.discountPercentage,
                              'discountAmount': item.discountAmount,
                              'notes': item.notes,
                            },
                          )
                          .toList()
                      : data['items']; // Mantener items del payload original

                  // Actualizar finalData con datos de ISAR pero preservando items si es necesario
                  finalData = {
                    'customerId': invoice.customerId,
                    'number': invoice.number,
                    'date': invoice.date.toIso8601String(),
                    'dueDate': invoice.dueDate.toIso8601String(),
                    'paymentMethod': invoice.paymentMethod.value, // .value para snake_case (credit_card, bank_transfer)
                    'status': invoice.status.value, // .value para snake_case (partially_paid)
                    'taxPercentage': invoice.taxPercentage,
                    'discountPercentage': invoice.discountPercentage,
                    'discountAmount': invoice.discountAmount,
                    'notes': invoice.notes,
                    'terms': invoice.terms,
                    'metadata': invoice.metadata,
                    'bankAccountId': data['bankAccountId'], // Preservar del payload original
                    'items': itemsToUse,
                  };

                  AppLogger.d(
                    'Datos preparados para sincronización - factura: ${invoice.number}, items: ${(itemsToUse as List?)?.length ?? 0}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo factura de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          // ✅ CRÍTICO: Resolver customerId temporal antes de enviar al servidor
          String resolvedCustomerId = finalData['customerId'] ?? '';
          if (resolvedCustomerId.startsWith('customer_offline_') ||
              (resolvedCustomerId.startsWith('customer_') && !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(resolvedCustomerId))) {
            // El customerId es temporal - buscar si ya fue sincronizado
            try {
              final isar = IsarDatabase.instance.database;
              final isarCustomer = await isar.isarCustomers
                  .filter()
                  .serverIdEqualTo(resolvedCustomerId)
                  .findFirst();

              if (isarCustomer != null) {
                // Customer encontrado con temp serverId → verificar si hay sync pendiente
                final pendingCustomerOps = await _isarDatabase.getPendingSyncOperationsByType('Customer');
                final hasCustomerSync = pendingCustomerOps.any((op) {
                  try {
                    final opData = jsonDecode(op.payload);
                    final opId = opData['id'] ?? opData['tempId'] ?? '';
                    return opId == resolvedCustomerId || op.payload.contains(resolvedCustomerId);
                  } catch (_) {
                    return false;
                  }
                });

                if (hasCustomerSync) {
                  // Hay sync pendiente → esperar a que se resuelva
                  throw Exception(
                    'Customer $resolvedCustomerId aún no sincronizado - se reintentará',
                  );
                }

                // NO hay sync pendiente → buscar customer con mismo nombre pero UUID real
                final customerName = isarCustomer.fullName;
                if (customerName.isNotEmpty) {
                  // Buscar todos los customers con mismo firstName
                  final allCustomers = await isar.isarCustomers
                      .filter()
                      .firstNameEqualTo(isarCustomer.firstName)
                      .and()
                      .lastNameEqualTo(isarCustomer.lastName)
                      .findAll();
                  final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
                  final realCustomer = allCustomers.where((c) => c.serverId != null && uuidRegex.hasMatch(c.serverId!)).firstOrNull;

                  if (realCustomer != null) {
                    resolvedCustomerId = realCustomer.serverId!;
                    AppLogger.i(
                      'Customer temp ID resuelto por nombre "$customerName" → ${realCustomer.serverId}',
                      tag: 'SYNC',
                    );
                  } else {
                    // No hay sync pendiente ni customer real → error permanente
                    AppLogger.e(
                      'Customer $resolvedCustomerId no tiene UUID real y no hay sync pendiente - marcando como fallido',
                      tag: 'SYNC',
                    );
                    throw Exception(
                      'PERMANENT: Customer $resolvedCustomerId no tiene UUID real y no hay operación de sync pendiente',
                    );
                  }
                } else {
                  AppLogger.e(
                    'Customer $resolvedCustomerId sin nombre - no se puede resolver',
                    tag: 'SYNC',
                  );
                  throw Exception(
                    'PERMANENT: Customer $resolvedCustomerId sin nombre para resolución alternativa',
                  );
                }
              } else {
                // Customer no encontrado con temp ID → ya sincronizado y serverId cambió
                // El payload ya debería tener el UUID real (actualizado por Customer handler)
                AppLogger.w(
                  'Customer temp ID $resolvedCustomerId no encontrado en ISAR - puede haber sido actualizado en payload',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              if (e.toString().contains('aún no sincronizado')) rethrow;
              if (e.toString().contains('PERMANENT:')) {
                // Error permanente - marcar operación como fallida definitivamente
                AppLogger.e('Error permanente resolviendo customerId: $e', tag: 'SYNC');
                await _isarDatabase.markSyncOperationFailed(operation.id, e.toString());
                return;
              }
              AppLogger.w('Error resolviendo customerId temporal: $e', tag: 'SYNC');
            }
          }
          finalData['customerId'] = resolvedCustomerId;

          // Parsear items
          final items =
              (finalData['items'] as List)
                  .map(
                    (item) => CreateInvoiceItemRequestModel(
                      productId: item['productId'],
                      description: item['description'],
                      quantity: (item['quantity'] as num).toDouble(),
                      unitPrice: (item['unitPrice'] as num).toDouble(),
                      unit: item['unit'] ?? 'und',
                      discountPercentage:
                          item['discountPercentage'] != null
                              ? (item['discountPercentage'] as num).toDouble()
                              : 0,
                      discountAmount:
                          item['discountAmount'] != null
                              ? (item['discountAmount'] as num).toDouble()
                              : 0,
                      notes: item['notes'],
                    ),
                  )
                  .toList();

          // ✅ No enviar número TEMP al servidor - dejar que el backend genere uno real
          final invoiceNumber = finalData['number'] as String?;
          final effectiveNumber = (invoiceNumber != null && invoiceNumber.startsWith('TEMP-'))
              ? null
              : invoiceNumber;

          // Determinar si se debe saltar la validación de stock
          bool skipStock = false;
          try {
            final prefsCtrl = Get.find<UserPreferencesController>();
            skipStock = !prefsCtrl.validateStockBeforeInvoice || prefsCtrl.allowOverselling;
          } catch (_) {}

          final request = CreateInvoiceRequestModel(
            customerId: finalData['customerId'],
            items: items,
            number: effectiveNumber,
            date: finalData['date'],
            dueDate: finalData['dueDate'],
            paymentMethod: finalData['paymentMethod'] ?? 'cash',
            status: finalData['status'],
            taxPercentage:
                finalData['taxPercentage'] != null
                    ? (finalData['taxPercentage'] as num).toDouble()
                    : 19,
            discountPercentage:
                finalData['discountPercentage'] != null
                    ? (finalData['discountPercentage'] as num).toDouble()
                    : 0,
            discountAmount:
                finalData['discountAmount'] != null
                    ? (finalData['discountAmount'] as num).toDouble()
                    : 0,
            notes: finalData['notes'],
            terms: finalData['terms'],
            metadata: finalData['metadata'],
            bankAccountId: finalData['bankAccountId'],
            skipStockValidation: skipStock,
          );

          final createdInvoice = await remoteDataSource.createInvoice(request);
          AppLogger.i(
            'Factura creada en servidor con ID: ${createdInvoice.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('inv_') ||
              operation.entityId.startsWith('invoice_offline_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarInvoice = await isar.isarInvoices
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarInvoice != null) {
                isarInvoice.serverId = createdInvoice.id;
                // ✅ Actualizar número de factura con el real del servidor
                if (createdInvoice.number.isNotEmpty &&
                    !createdInvoice.number.startsWith('TEMP-')) {
                  isarInvoice.number = createdInvoice.number;
                  AppLogger.d(
                    'Número de factura actualizado: ${isarInvoice.number} → ${createdInvoice.number}',
                    tag: 'SYNC',
                  );
                }
                isarInvoice.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarInvoices.put(isarInvoice);
                });
                AppLogger.i(
                  'ISAR factura actualizada: ${operation.entityId} → ${createdInvoice.id} (num: ${createdInvoice.number})',
                  tag: 'SYNC',
                );
              }

              // Limpiar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }

              // ✅ CRÍTICO: Eliminar movimientos FIFO pendientes de esta factura.
              // El backend ya descuenta inventario FIFO automáticamente al crear la factura
              // (invoices.service.ts → applyBusinessLogicByStatus → registerSale).
              // Si dejamos las ops inventory_movement_fifo, se produce DOBLE DEDUCCIÓN.
              final tempInvoiceId = operation.entityId;
              int fifoDeleted = 0;
              for (final op in pendingOps) {
                if ((op.entityType == 'inventory_movement_fifo' ||
                     op.entityType == 'InventoryMovement' ||
                     op.entityType == 'inventory_movement') &&
                    op.operationType == SyncOperationType.create) {
                  try {
                    final movData = jsonDecode(op.payload);
                    final refId = movData['referenceId'] as String?;
                    final refType = movData['referenceType'] as String?;
                    if (refType == 'invoice' &&
                        (refId == tempInvoiceId || refId == createdInvoice.id)) {
                      await _isarDatabase.deleteSyncOperation(op.id);
                      fifoDeleted++;
                    }
                  } catch (_) {}
                }
              }
              if (fifoDeleted > 0) {
                AppLogger.i(
                  'Eliminadas $fifoDeleted ops FIFO de factura $tempInvoiceId (backend ya descontó inventario)',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w('Error actualizando factura en ISAR: $e', tag: 'SYNC');
            }
          }

          // ✅ Para facturas a crédito puro: crear CustomerCredit en el servidor
          // El crédito fue creado localmente en ISAR durante la creación offline,
          // pero el backend NO genera créditos automáticamente para este caso.
          final invoiceMetadata = finalData['metadata'];
          if (invoiceMetadata != null &&
              invoiceMetadata is Map &&
              invoiceMetadata['isPureCreditInvoice'] == true) {
            try {
              final CustomerCreditRemoteDataSource creditRemoteDs;
              if (Get.isRegistered<CustomerCreditRemoteDataSource>()) {
                creditRemoteDs = Get.find<CustomerCreditRemoteDataSource>();
              } else {
                creditRemoteDs = CustomerCreditRemoteDataSourceImpl(
                  dioClient: Get.find<DioClient>(),
                );
              }

              final creditDto = CreateCustomerCreditDto(
                customerId: createdInvoice.customerId,
                originalAmount: createdInvoice.total,
                dueDate: createdInvoice.dueDate.toIso8601String().split('T').first,
                description: 'Crédito por venta a crédito - Factura ${createdInvoice.number}',
                invoiceId: createdInvoice.id,
              );

              final serverCredit = await creditRemoteDs.createCredit(creditDto);
              AppLogger.i(
                'Crédito creado en servidor para factura a crédito: ${serverCredit.id}',
                tag: 'SYNC',
              );

              // Actualizar crédito local en ISAR con ID real del servidor
              try {
                final isar = IsarDatabase.instance.database;
                final localCredit = await isar.isarCustomerCredits
                    .filter()
                    .invoiceIdEqualTo(operation.entityId) // temp invoice ID
                    .findFirst();

                if (localCredit != null) {
                  localCredit.serverId = serverCredit.id;
                  localCredit.invoiceId = createdInvoice.id;
                  localCredit.invoiceNumber = createdInvoice.number;
                  localCredit.isSynced = true;
                  localCredit.lastSyncAt = DateTime.now();
                  await isar.writeTxn(() async {
                    await isar.isarCustomerCredits.put(localCredit);
                  });
                  AppLogger.i(
                    'ISAR crédito actualizado: serverId=${serverCredit.id}, invoiceId=${createdInvoice.id}',
                    tag: 'SYNC',
                  );
                }
              } catch (isarError) {
                AppLogger.w(
                  'Error actualizando crédito en ISAR: $isarError',
                  tag: 'SYNC',
                );
              }
            } catch (creditError) {
              if (creditError is ServerException && creditError.statusCode == 409) {
                AppLogger.w(
                  'Crédito ya existe en servidor - ignorando',
                  tag: 'SYNC',
                );
              } else {
                AppLogger.w(
                  'Error creando crédito para factura a crédito: $creditError',
                  tag: 'SYNC',
                );
              }
            }
          } else {
            // ✅ Para facturas con crédito por saldo restante (multiplePayments):
            // Actualizar invoiceId del crédito asociado con el UUID real
            try {
              final isar = IsarDatabase.instance.database;
              final localCredit = await isar.isarCustomerCredits
                  .filter()
                  .invoiceIdEqualTo(operation.entityId) // temp ID
                  .findFirst();
              if (localCredit != null) {
                localCredit.invoiceId = createdInvoice.id;
                localCredit.invoiceNumber = createdInvoice.number;
                await isar.writeTxn(() async {
                  await isar.isarCustomerCredits.put(localCredit);
                });
                AppLogger.d(
                  'Crédito asociado: invoiceId actualizado ${operation.entityId} → ${createdInvoice.id}',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w('Error actualizando invoiceId en crédito: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          final invoiceAction = data['action'] as String?;

          if (invoiceAction == 'addPayment') {
            // ✅ Sync de pago offline a factura
            AppLogger.d(
              'Sincronizando addPayment para factura: ${operation.entityId}',
              tag: 'SYNC',
            );

            // Resolver temp ID si es necesario
            String invoiceId = operation.entityId;
            if (invoiceId.startsWith('invoice_offline_') || invoiceId.startsWith('inv_')) {
              final isar = IsarDatabase.instance.database;
              final isarInv = await isar.isarInvoices
                  .filter()
                  .serverIdEqualTo(invoiceId)
                  .findFirst();
              if (isarInv != null &&
                  !isarInv.serverId.startsWith('invoice_offline_') &&
                  !isarInv.serverId.startsWith('inv_')) {
                invoiceId = isarInv.serverId;
                AppLogger.d(
                  'Temp invoice ID resuelto: ${operation.entityId} → $invoiceId',
                  tag: 'SYNC',
                );
              } else {
                throw Exception(
                  'Invoice ${operation.entityId} aún no sincronizada - reintentando después',
                );
              }
            }

            final paymentRequest = AddPaymentRequestModel(
              amount: (data['amount'] as num).toDouble(),
              paymentMethod: data['paymentMethod'] ?? 'cash',
              bankAccountId: data['bankAccountId'],
              paymentDate: data['paymentDate'],
              reference: data['reference'],
              notes: data['notes'],
              paymentCurrency: data['paymentCurrency'],
              paymentCurrencyAmount: data['paymentCurrencyAmount'] != null
                  ? (data['paymentCurrencyAmount'] as num).toDouble()
                  : null,
              exchangeRate: data['exchangeRate'] != null
                  ? (data['exchangeRate'] as num).toDouble()
                  : null,
              idempotencyKey: data['idempotencyKey'] as String?,
            );

            final updatedInvoice = await remoteDataSource.addPayment(
              invoiceId,
              paymentRequest,
            );
            AppLogger.i(
              'Pago a factura sincronizado: $invoiceId → paidAmount=${updatedInvoice.paidAmount}',
              tag: 'SYNC',
            );

            // Actualizar ISAR con respuesta del servidor
            try {
              final isar = IsarDatabase.instance.database;
              final isarInv = await isar.isarInvoices
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();
              if (isarInv != null) {
                isarInv.paidAmount = updatedInvoice.paidAmount;
                isarInv.balanceDue = updatedInvoice.balanceDue;
                isarInv.status = _mapInvoiceStatusToIsar(updatedInvoice.status);
                isarInv.paymentsJson = IsarInvoice.encodePayments(updatedInvoice.payments);
                isarInv.isSynced = true;
                isarInv.lastSyncAt = DateTime.now();
                await isar.writeTxn(() async {
                  await isar.isarInvoices.put(isarInv);
                });
                AppLogger.d(
                  'ISAR factura actualizada tras sync payment: paidAmount=${updatedInvoice.paidAmount}',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w('Error actualizando factura en ISAR tras sync payment: $e', tag: 'SYNC');
            }
          } else {
            // Lógica existente de UPDATE completo
            AppLogger.d(
              'Actualizando factura en servidor: ${operation.entityId}',
              tag: 'SYNC',
            );

            // Parsear items si existen
            List<CreateInvoiceItemRequestModel>? items;
            if (data['items'] != null) {
              items =
                  (data['items'] as List)
                      .map(
                        (item) => CreateInvoiceItemRequestModel(
                          productId: item['productId'],
                          description: item['description'],
                          quantity: (item['quantity'] as num).toDouble(),
                          unitPrice: (item['unitPrice'] as num).toDouble(),
                          unit: item['unit'] ?? 'und',
                          discountPercentage:
                              item['discountPercentage'] != null
                                  ? (item['discountPercentage'] as num).toDouble()
                                  : 0,
                          discountAmount:
                              item['discountAmount'] != null
                                  ? (item['discountAmount'] as num).toDouble()
                                  : 0,
                          notes: item['notes'],
                        ),
                      )
                      .toList();
            }

            final updateRequest = UpdateInvoiceRequestModel(
              number: data['number'],
              date: data['date'],
              dueDate: data['dueDate'],
              paymentMethod: data['paymentMethod'],
              status: data['status'],
              taxPercentage:
                  data['taxPercentage'] != null
                      ? (data['taxPercentage'] as num).toDouble()
                      : null,
              discountPercentage:
                  data['discountPercentage'] != null
                      ? (data['discountPercentage'] as num).toDouble()
                      : null,
              discountAmount:
                  data['discountAmount'] != null
                      ? (data['discountAmount'] as num).toDouble()
                      : null,
              notes: data['notes'],
              terms: data['terms'],
              metadata: data['metadata'],
              customerId: data['customerId'],
              items: items,
            );

            await remoteDataSource.updateInvoice(
              operation.entityId,
              updateRequest,
            );
            AppLogger.i('Factura actualizada en servidor', tag: 'SYNC');
          }
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando factura en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteInvoice(operation.entityId);
          AppLogger.i('Factura eliminada en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Factura ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de PurchaseOrder
  Future<void> _syncPurchaseOrderOperation(SyncOperation operation) async {
    try {
      final PurchaseOrderRemoteDataSource remoteDataSource;
      if (Get.isRegistered<PurchaseOrderRemoteDataSource>()) {
        remoteDataSource = Get.find<PurchaseOrderRemoteDataSource>();
      } else {
        remoteDataSource = PurchaseOrderRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando orden de compra en servidor: ${data['supplierId']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para órdenes de compra offline
          Map<String, dynamic> finalData = data;
          PurchaseOrderStatus? isarFinalStatus;
          String? isarWarehouseId;
          List<PurchaseOrderItem>? isarItems;

          if (operation.entityId.startsWith('po_offline_') || operation.entityId.startsWith('po_')) {
            AppLogger.d(
              'Orden de compra offline detectada - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );

            // Leer warehouseId inyectado por _cleanupDuplicateOperations
            isarWarehouseId = data['_receiveWarehouseId'] as String?;

            // Lectura directa de ISAR (más confiable que usar PurchaseOrderOfflineRepository)
            try {
              final isar = IsarDatabase.instance.database;
              final isarPO = await isar.isarPurchaseOrders
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarPO != null) {
                // Usar query directa (más confiable que IsarLinks)
                final directItems = await isar.isarPurchaseOrderItems
                    .filter()
                    .purchaseOrderServerIdEqualTo(operation.entityId)
                    .findAll();
                final order = isarPO.toEntityWithItems(directItems);
                finalData = {
                  'supplierId': order.supplierId,
                  'priority': order.priority.name,
                  'orderDate': order.orderDate?.toIso8601String(),
                  'expectedDeliveryDate':
                      order.expectedDeliveryDate?.toIso8601String(),
                  'currency': order.currency,
                  'notes': order.notes,
                  'internalNotes': order.internalNotes,
                  'deliveryAddress': order.deliveryAddress,
                  'contactPerson': order.contactPerson,
                  'contactPhone': order.contactPhone,
                  'contactEmail': order.contactEmail,
                  'attachments': order.attachments,
                  'items':
                      order.items
                          .map(
                            (item) => {
                              'productId': item.productId,
                              'productName': item.productName,
                              'quantity': item.quantity,
                              'unitCost': item.unitPrice,
                              'discountPercentage': item.discountPercentage,
                              'taxPercentage': item.taxPercentage,
                              'notes': item.notes,
                            },
                          )
                          .toList(),
                };
                isarFinalStatus = order.status;
                isarItems = order.items;
                AppLogger.i(
                  'Datos de ISAR obtenidos para PO offline: ${order.orderNumber} (status: ${order.status.name})',
                  tag: 'SYNC',
                );
              } else {
                AppLogger.w(
                  'PO offline no encontrada en ISAR por serverId=${operation.entityId} - usando fallback del payload',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w(
                'Error leyendo PO de ISAR: $e - usando fallback del payload',
                tag: 'SYNC',
              );
            }

            // ✅ FALLBACK DEFINITIVO: Si ISAR no encontró la PO, usar _finalStatus inyectado por _cleanupDuplicateOperations
            if (isarFinalStatus == null && data['_finalStatus'] != null) {
              final statusStr = data['_finalStatus'] as String;
              try {
                isarFinalStatus = PurchaseOrderStatus.values.firstWhere(
                  (e) => e.name == statusStr,
                );
                AppLogger.i(
                  'Estado final obtenido del payload inyectado: $statusStr (${isarFinalStatus!.name})',
                  tag: 'SYNC',
                );
              } catch (e) {
                AppLogger.w('No se pudo parsear _finalStatus "$statusStr": $e', tag: 'SYNC');
              }
            }

            // ✅ FALLBACK: Si no hay receiveItems de ISAR, usar los inyectados por cleanup
            if (isarItems == null && data['_receiveItems'] != null) {
              try {
                final rawItems = data['_receiveItems'] as List;
                isarItems = rawItems.map((item) {
                  final m = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
                  return PurchaseOrderItem(
                    id: m['id'] as String? ?? '',
                    productId: m['productId'] as String? ?? '',
                    productName: m['productName'] as String? ?? '',
                    unit: m['unit'] as String? ?? '',
                    quantity: (m['quantity'] as num?)?.toInt() ?? 0,
                    unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
                    discountPercentage: (m['discountPercentage'] as num?)?.toDouble() ?? 0,
                    discountAmount: (m['discountAmount'] as num?)?.toDouble() ?? 0,
                    subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
                    taxPercentage: (m['taxPercentage'] as num?)?.toDouble() ?? 0,
                    taxAmount: (m['taxAmount'] as num?)?.toDouble() ?? 0,
                    totalAmount: (m['totalAmount'] as num?)?.toDouble() ?? 0,
                    receivedQuantity: (m['receivedQuantity'] as num?)?.toInt() ?? (m['quantity'] as num?)?.toInt() ?? 0,
                    notes: m['notes'] as String?,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                }).toList();
                AppLogger.d('Items de recepción obtenidos del payload inyectado: ${isarItems!.length} items', tag: 'SYNC');
              } catch (e) {
                AppLogger.w('Error parseando _receiveItems del payload: $e', tag: 'SYNC');
              }
            }
          }

          // ✅ Validar supplierId antes de enviar (DRY: patrón Invoice CREATE con customerId)
          String resolvedSupplierId = finalData['supplierId'] ?? '';
          final supplierUuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
          if (resolvedSupplierId.startsWith('supplier_offline_') ||
              (resolvedSupplierId.startsWith('supplier_') && !supplierUuidRegex.hasMatch(resolvedSupplierId))) {
            // El supplierId es temporal — buscar si ya fue sincronizado
            try {
              final isar = IsarDatabase.instance.database;

              // Verificar si hay sync pendiente de este Supplier
              final pendingSupplierOps = await _isarDatabase.getPendingSyncOperationsByType('Supplier');
              final hasSupplierSync = pendingSupplierOps.any((op) =>
                op.entityId == resolvedSupplierId &&
                op.operationType == SyncOperationType.create);

              if (hasSupplierSync) {
                // Supplier aún no sincronizado — reintentar después
                AppLogger.w(
                  'PO tiene supplierId temporal: $resolvedSupplierId - Supplier aún pendiente de sync',
                  tag: 'SYNC',
                );
                throw ServerException('Supplier pendiente de sincronización');
              }

              // No hay sync pendiente → buscar supplier con mismo nombre pero UUID real
              final isarSupplier = await isar.isarSuppliers
                  .filter()
                  .serverIdEqualTo(resolvedSupplierId)
                  .findFirst();
              if (isarSupplier != null) {
                // Encontrado por tempId → buscar otro con UUID real por nombre
                final allSuppliers = await isar.isarSuppliers
                    .filter()
                    .nameEqualTo(isarSupplier.name)
                    .findAll();
                final realSupplier = allSuppliers.where(
                  (s) => s.serverId != null && supplierUuidRegex.hasMatch(s.serverId!),
                ).firstOrNull;
                if (realSupplier != null) {
                  resolvedSupplierId = realSupplier.serverId!;
                  AppLogger.i(
                    'supplierId resuelto por nombre "${isarSupplier.name}": ${finalData['supplierId']} → $resolvedSupplierId',
                    tag: 'SYNC',
                  );
                } else {
                  throw ServerException('Supplier no encontrado con UUID real');
                }
              } else {
                throw ServerException('Supplier $resolvedSupplierId no encontrado en ISAR');
              }
            } catch (e) {
              if (e is ServerException) rethrow;
              AppLogger.w('Error resolviendo supplierId temporal: $e', tag: 'SYNC');
              throw ServerException('Supplier pendiente de sincronización');
            }
          }
          finalData['supplierId'] = resolvedSupplierId;

          // ✅ Resolver productIds temporales (product_offline_*) antes de enviar
          if (finalData['items'] != null) {
            final isar = IsarDatabase.instance.database;
            for (final item in (finalData['items'] as List)) {
              final pid = item['productId'] as String?;
              if (pid != null && pid.startsWith('product_offline_')) {
                final isarProduct = await isar.isarProducts
                    .filter()
                    .serverIdEqualTo(pid)
                    .findFirst();
                if (isarProduct != null && !isarProduct.serverId.startsWith('product_offline_')) {
                  AppLogger.i(
                    'PO CREATE: productId resuelto via ISAR $pid → ${isarProduct.serverId}',
                    tag: 'SYNC',
                  );
                  item['productId'] = isarProduct.serverId;
                } else {
                  final mappedId = await lookupTempIdMapping(pid);
                  if (mappedId != null) {
                    AppLogger.i(
                      'PO CREATE: productId resuelto via mapeo $pid → $mappedId',
                      tag: 'SYNC',
                    );
                    item['productId'] = mappedId;
                  } else {
                    // 3. Last resort: buscar nombre vía IsarPurchaseOrderItem → luego producto por nombre
                    String? productName = item['productName'] as String?;
                    if (productName == null || productName.isEmpty) {
                      final poItem = await isar.isarPurchaseOrderItems
                          .filter()
                          .productIdEqualTo(pid)
                          .findFirst();
                      productName = poItem?.productName;
                    }
                    if (productName != null && productName.isNotEmpty) {
                      final productByName = await isar.isarProducts
                          .filter()
                          .nameEqualTo(productName)
                          .findFirst();
                      if (productByName != null &&
                          !productByName.serverId.startsWith('product_offline_')) {
                        AppLogger.i(
                          'PO CREATE: productId resuelto via nombre "$productName" $pid → ${productByName.serverId}',
                          tag: 'SYNC',
                        );
                        item['productId'] = productByName.serverId;
                        await registerTempIdMapping(pid, productByName.serverId);
                      } else {
                        AppLogger.w(
                          'PO CREATE: productId temporal no resuelto: $pid — producto "$productName" no encontrado',
                          tag: 'SYNC',
                        );
                      }
                    } else {
                      AppLogger.w(
                        'PO CREATE: productId temporal no resuelto: $pid — sin nombre para búsqueda',
                        tag: 'SYNC',
                      );
                    }
                  }
                }
              }
            }
          }

          // Parsear items
          final itemParams =
              (finalData['items'] as List)
                  .map(
                    (item) => CreatePurchaseOrderItemParams(
                      productId: item['productId'],
                      lineNumber: item['lineNumber'],
                      quantity:
                          item['quantity'] is int
                              ? item['quantity']
                              : (item['quantity'] as num).toInt(),
                      unitPrice:
                          (item['unitCost'] as num? ?? item['unitPrice'] as num)
                              .toDouble(),
                      discountPercentage:
                          item['discountPercentage'] != null
                              ? (item['discountPercentage'] as num).toDouble()
                              : 0,
                      taxPercentage:
                          item['taxPercentage'] != null
                              ? (item['taxPercentage'] as num).toDouble()
                              : 0,
                      notes: item['notes'],
                    ),
                  )
                  .toList();

          final createParams = CreatePurchaseOrderParams(
            supplierId: finalData['supplierId'],
            priority:
                finalData['priority'] != null
                    ? PurchaseOrderPriority.values.firstWhere(
                      (e) => e.name == finalData['priority'],
                      orElse: () => PurchaseOrderPriority.medium,
                    )
                    : PurchaseOrderPriority.medium,
            orderDate:
                finalData['orderDate'] != null
                    ? DateTime.parse(finalData['orderDate'])
                    : DateTime.now(),
            expectedDeliveryDate: DateTime.parse(
              finalData['expectedDeliveryDate'],
            ),
            currency: finalData['currency'] ?? 'COP',
            items: itemParams,
            notes: finalData['notes'],
            internalNotes: finalData['internalNotes'],
            deliveryAddress: finalData['deliveryAddress'],
            contactPerson: finalData['contactPerson'],
            contactPhone: finalData['contactPhone'],
            contactEmail: finalData['contactEmail'],
            attachments:
                finalData['attachments'] != null
                    ? List<String>.from(finalData['attachments'])
                    : [],
            // Multi-moneda: propagar al backend si la compra offline se
            // registró con moneda foránea.
            purchaseCurrency: finalData['purchaseCurrency'] as String?,
            purchaseCurrencyAmount:
                (finalData['purchaseCurrencyAmount'] as num?)?.toDouble(),
            exchangeRate: (finalData['exchangeRate'] as num?)?.toDouble(),
          );

          final createdPO = await remoteDataSource.createPurchaseOrder(createParams);
          AppLogger.i(
            'Orden de compra creada en servidor con ID: ${createdPO.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('po_')) {
            // Paso 1: Actualizar ISAR PO con el ID real
            try {
              final isar = IsarDatabase.instance.database;
              final isarPO = await isar.isarPurchaseOrders
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarPO != null) {
                final oldTempPOId = operation.entityId;
                isarPO.serverId = createdPO.id;
                isarPO.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarPurchaseOrders.put(isarPO);

                  // Reemplazar items locales (IDs temporales) con items del servidor (IDs reales)
                  final serverPOEntity = createdPO.toEntity();
                  if (serverPOEntity.items.isNotEmpty) {
                    // Solo borrar items locales si tenemos items del servidor para reemplazarlos
                    final oldItems = await isar.isarPurchaseOrderItems
                        .filter()
                        .purchaseOrderServerIdEqualTo(oldTempPOId)
                        .findAll();
                    if (oldItems.isNotEmpty) {
                      await isar.isarPurchaseOrderItems
                          .deleteAll(oldItems.map((i) => i.id).toList());
                    }

                    final newIsarItems = serverPOEntity.items.map((item) {
                      final isarItem = IsarPurchaseOrderItem.fromEntity(item);
                      isarItem.purchaseOrderServerId = createdPO.id;
                      return isarItem;
                    }).toList();
                    await isar.isarPurchaseOrderItems.putAll(newIsarItems);
                    AppLogger.d(
                      '${newIsarItems.length} PO items reemplazados con IDs del servidor (PO ${createdPO.id})',
                      tag: 'SYNC',
                    );
                  } else {
                    // Servidor no devolvió items: solo actualizar purchaseOrderServerId
                    final localItems = await isar.isarPurchaseOrderItems
                        .filter()
                        .purchaseOrderServerIdEqualTo(oldTempPOId)
                        .findAll();
                    if (localItems.isNotEmpty) {
                      for (final item in localItems) {
                        item.purchaseOrderServerId = createdPO.id;
                      }
                      await isar.isarPurchaseOrderItems.putAll(localItems);
                      AppLogger.w(
                        'Servidor no devolvió items - ${localItems.length} items locales actualizados con FK ${createdPO.id}',
                        tag: 'SYNC',
                      );
                    }
                  }
                });
                AppLogger.i(
                  'ISAR orden de compra actualizada: ${operation.entityId} → ${createdPO.id}',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w('Error actualizando PO en ISAR: $e', tag: 'SYNC');
            }

            // Paso 2: Actualizar referenceIds en InventoryMovement y limpiar ops UPDATE residuales
            // (en bloque separado para que se ejecute aunque el paso 1 falle)
            try {
              final pendingOps = await _isarDatabase.getPendingSyncOperations();

              // Extraer warehouseId de operación receive pendiente (fallback si no fue inyectado por cleanup)
              if (isarWarehouseId == null) {
                for (final op in pendingOps) {
                  if (op.entityId == operation.entityId &&
                      op.operationType == SyncOperationType.update) {
                    try {
                      final opData = jsonDecode(op.payload);
                      if (opData['action'] == 'receive' && opData['warehouseId'] != null) {
                        isarWarehouseId = opData['warehouseId'] as String;
                        AppLogger.d(
                          'warehouseId extraído de operación receive pendiente: $isarWarehouseId',
                          tag: 'SYNC',
                        );
                      }
                    } catch (_) {}
                  }
                }
              }

              // Actualizar referenceId en operaciones de InventoryMovement pendientes
              // que referencian el ID temporal de esta PO
              final oldTempId = operation.entityId;
              final newRealId = createdPO.id;
              for (final op in pendingOps) {
                if ((op.entityType == 'InventoryMovement' || op.entityType == 'inventory_movement') &&
                    op.operationType == SyncOperationType.create) {
                  try {
                    final opData = jsonDecode(op.payload);
                    if (opData['referenceId'] == oldTempId && opData['referenceType'] == 'purchase_order') {
                      opData['referenceId'] = newRealId;
                      await _isarDatabase.updateSyncOperationPayload(op.id, jsonEncode(opData));
                      AppLogger.i(
                        'referenceId actualizado en InventoryMovement op ${op.entityId}: $oldTempId → $newRealId',
                        tag: 'SYNC',
                      );
                    }
                  } catch (e) {
                    AppLogger.w('Error actualizando referenceId en op ${op.entityId}: $e', tag: 'SYNC');
                  }
                }
              }

              // Limpiar operaciones UPDATE residuales de PO (ya procesadas por cleanup, pero por seguridad)
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }
            } catch (e) {
              AppLogger.w('Error en post-procesamiento de sync PO: $e', tag: 'SYNC');
            }
          }

          // ✅ Aplicar transiciones de estado si la PO offline avanzó más allá de draft
          if (isarFinalStatus != null && isarFinalStatus != PurchaseOrderStatus.draft) {
            final realId = createdPO.id;
            AppLogger.d(
              'PO offline tiene estado final: ${isarFinalStatus!.name} - aplicando transiciones al servidor',
              tag: 'SYNC',
            );

            try {
              // El backend requiere transiciones secuenciales:
              // draft → pending (automático al crear) → approved → sent → received
              final statusOrder = [
                PurchaseOrderStatus.pending,
                PurchaseOrderStatus.approved,
                PurchaseOrderStatus.sent,
                PurchaseOrderStatus.received,
              ];

              final targetIndex = statusOrder.indexOf(isarFinalStatus!);

              // Aprobar si necesario (pending → approved)
              if (targetIndex >= 1) {
                // approved o más allá
                await remoteDataSource.approvePurchaseOrder(realId, null);
                AppLogger.i('PO $realId aprobada en servidor (transición offline)', tag: 'SYNC');
              }

              // Enviar si necesario (approved → sent)
              if (targetIndex >= 2) {
                // sent o más allá
                await remoteDataSource.sendPurchaseOrder(realId, null);
                AppLogger.i('PO $realId enviada en servidor (transición offline)', tag: 'SYNC');
              }

              // Recibir si necesario (sent → received) - ESTO ALIMENTA EL INVENTARIO
              if (targetIndex >= 3) {
                // received
                // Obtener PO actualizada del servidor para tener los itemIds reales
                final serverPO = await remoteDataSource.getPurchaseOrderById(realId);
                final serverItems = serverPO.items ?? [];

                // Construir items para recepción con IDs del servidor
                final receiveItems = serverItems.map((serverItem) {
                  // Buscar la cantidad correspondiente en los items de ISAR
                  final isarItem = (isarItems ?? []).firstWhere(
                    (i) => i.productId == serverItem.productId,
                    orElse: () => PurchaseOrderItem(
                      id: '', productId: serverItem.productId ?? '', productName: '',
                      unit: '', quantity: double.tryParse(serverItem.quantity ?? '0')?.toInt() ?? 0,
                      unitPrice: 0, discountPercentage: 0, discountAmount: 0,
                      subtotal: 0, taxPercentage: 0, taxAmount: 0, totalAmount: 0,
                      createdAt: DateTime.now(), updatedAt: DateTime.now(),
                    ),
                  );

                  return ReceivePurchaseOrderItemParams(
                    itemId: serverItem.id ?? '',
                    receivedQuantity: (isarItem.receivedQuantity ?? 0) > 0
                        ? isarItem.receivedQuantity!
                        : isarItem.quantity,
                    notes: isarItem.notes,
                  );
                }).toList();

                await remoteDataSource.receivePurchaseOrder(
                  ReceivePurchaseOrderParams(
                    id: realId,
                    items: receiveItems,
                    receivedDate: DateTime.now(),
                    notes: finalData['notes'] as String?,
                    warehouseId: isarWarehouseId,
                  ),
                );
                AppLogger.i('PO $realId recibida en servidor (transición offline) - inventario actualizado por backend', tag: 'SYNC');

                // ✅ CRÍTICO: El backend receive ya creó batches+movimientos de inventario.
                // Debemos ELIMINAR las InventoryMovement ops pendientes de esta PO
                // para evitar duplicación de inventario.
                try {
                  final allPendingOps = await _isarDatabase.getPendingSyncOperations();
                  int deletedMovements = 0;
                  for (final movOp in allPendingOps) {
                    if ((movOp.entityType == 'InventoryMovement' || movOp.entityType == 'inventory_movement') &&
                        movOp.operationType == SyncOperationType.create) {
                      try {
                        final movData = jsonDecode(movOp.payload);
                        final refId = movData['referenceId'] as String?;
                        final refType = movData['referenceType'] as String?;
                        // Eliminar si referencia esta PO (por ID real o temp)
                        if (refType == 'purchase_order' &&
                            (refId == realId || refId == operation.entityId)) {
                          await _isarDatabase.deleteSyncOperation(movOp.id);
                          deletedMovements++;
                          AppLogger.d(
                            'InventoryMovement op eliminada (backend receive ya la creó): ${movOp.entityId}',
                            tag: 'SYNC',
                          );
                        }
                      } catch (_) {}
                    }
                  }
                  if (deletedMovements > 0) {
                    AppLogger.i(
                      '$deletedMovements InventoryMovement ops eliminadas (ya creadas por backend receive)',
                      tag: 'SYNC',
                    );
                  }
                } catch (e) {
                  AppLogger.w('Error limpiando InventoryMovement ops duplicadas: $e', tag: 'SYNC');
                }
              }
            } catch (e) {
              AppLogger.w(
                'Error aplicando transiciones de estado offline para PO: $e',
                tag: 'SYNC',
              );
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando orden de compra en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );

          // Verificar si es una acción de cambio de estado
          final action = data['action'] as String?;

          if (action != null) {
            // Operación de cambio de estado específica
            AppLogger.d(
              'Procesando acción de estado PO: $action para ${operation.entityId}',
              tag: 'SYNC',
            );
            switch (action) {
              case 'approve':
                await remoteDataSource.approvePurchaseOrder(
                  operation.entityId,
                  data['notes'] as String?,
                );
                AppLogger.i('Orden de compra aprobada en servidor', tag: 'SYNC');
                break;
              case 'reject':
                await remoteDataSource.rejectPurchaseOrder(
                  operation.entityId,
                  data['reason'] as String? ?? '',
                );
                AppLogger.i('Orden de compra rechazada en servidor', tag: 'SYNC');
                break;
              case 'send':
                await remoteDataSource.sendPurchaseOrder(
                  operation.entityId,
                  data['notes'] as String?,
                );
                AppLogger.i('Orden de compra enviada en servidor', tag: 'SYNC');
                break;
              case 'receive':
                final receiveItems = (data['items'] as List?)?.map((item) {
                  return ReceivePurchaseOrderItemParams(
                    itemId: (item['itemId'] ?? item['purchaseOrderItemId']) as String,
                    receivedQuantity: (item['receivedQuantity'] as num).toInt(),
                    notes: item['notes'] as String?,
                  );
                }).toList() ?? [];
                await remoteDataSource.receivePurchaseOrder(
                  ReceivePurchaseOrderParams(
                    id: operation.entityId,
                    items: receiveItems,
                    receivedDate: data['receivedDate'] != null
                        ? DateTime.parse(data['receivedDate'])
                        : null,
                    notes: data['notes'] as String?,
                    warehouseId: data['warehouseId'] as String?,
                  ),
                );
                AppLogger.i('Orden de compra recibida en servidor', tag: 'SYNC');

                // ✅ CRÍTICO: El backend receive ya creó batches+movimientos.
                // Eliminar InventoryMovement ops pendientes de esta PO para evitar duplicación.
                try {
                  final allPendingOps = await _isarDatabase.getPendingSyncOperations();
                  int deletedMovements = 0;
                  for (final movOp in allPendingOps) {
                    if ((movOp.entityType == 'InventoryMovement' || movOp.entityType == 'inventory_movement') &&
                        movOp.operationType == SyncOperationType.create) {
                      try {
                        final movData = jsonDecode(movOp.payload);
                        final refId = movData['referenceId'] as String?;
                        final refType = movData['referenceType'] as String?;
                        if (refType == 'purchase_order' &&
                            (refId == operation.entityId)) {
                          await _isarDatabase.deleteSyncOperation(movOp.id);
                          deletedMovements++;
                        }
                      } catch (_) {}
                    }
                  }
                  if (deletedMovements > 0) {
                    AppLogger.i(
                      '$deletedMovements InventoryMovement ops eliminadas (ya creadas por backend receive) para PO UPDATE',
                      tag: 'SYNC',
                    );
                  }
                } catch (e) {
                  AppLogger.w('Error limpiando InventoryMovement ops en UPDATE receive: $e', tag: 'SYNC');
                }
                break;
              case 'cancel':
                await remoteDataSource.cancelPurchaseOrder(
                  operation.entityId,
                  data['reason'] as String? ?? '',
                );
                AppLogger.i('Orden de compra cancelada en servidor', tag: 'SYNC');
                break;
              default:
                AppLogger.w('Acción PO desconocida: $action', tag: 'SYNC');
            }
          } else {
            // Actualización normal de campos

            // ✅ Resolver productIds temporales (product_offline_*) antes de enviar
            if (data['items'] != null) {
              final isar = IsarDatabase.instance.database;
              for (final item in (data['items'] as List)) {
                final pid = item['productId'] as String?;
                if (pid != null && pid.startsWith('product_offline_')) {
                  // 1. Buscar por serverId en ISAR (funciona si producto aún no sincronizado)
                  final isarProduct = await isar.isarProducts
                      .filter()
                      .serverIdEqualTo(pid)
                      .findFirst();
                  if (isarProduct != null && !isarProduct.serverId.startsWith('product_offline_')) {
                    AppLogger.i(
                      'PO UPDATE: productId resuelto via ISAR $pid → ${isarProduct.serverId}',
                      tag: 'SYNC',
                    );
                    item['productId'] = isarProduct.serverId;
                  } else {
                    // 2. Fallback: buscar en mapeo persistido (producto ya sincronizado en sesión anterior)
                    final mappedId = await lookupTempIdMapping(pid);
                    if (mappedId != null) {
                      AppLogger.i(
                        'PO UPDATE: productId resuelto via mapeo $pid → $mappedId',
                        tag: 'SYNC',
                      );
                      item['productId'] = mappedId;
                    } else {
                      // 3. Last resort: buscar nombre vía IsarPurchaseOrderItem → luego producto por nombre
                      String? productName = item['productName'] as String?;
                      if (productName == null || productName.isEmpty) {
                        // El payload no tiene productName, buscarlo en IsarPurchaseOrderItem
                        final poItem = await isar.isarPurchaseOrderItems
                            .filter()
                            .productIdEqualTo(pid)
                            .findFirst();
                        productName = poItem?.productName;
                      }
                      if (productName != null && productName.isNotEmpty) {
                        final productByName = await isar.isarProducts
                            .filter()
                            .nameEqualTo(productName)
                            .findFirst();
                        if (productByName != null &&
                            !productByName.serverId.startsWith('product_offline_')) {
                          AppLogger.i(
                            'PO UPDATE: productId resuelto via nombre "$productName" $pid → ${productByName.serverId}',
                            tag: 'SYNC',
                          );
                          item['productId'] = productByName.serverId;
                          await registerTempIdMapping(pid, productByName.serverId);
                        } else {
                          AppLogger.w(
                            'PO UPDATE: productId temporal no resuelto: $pid — producto "$productName" no encontrado',
                            tag: 'SYNC',
                          );
                        }
                      } else {
                        AppLogger.w(
                          'PO UPDATE: productId temporal no resuelto: $pid — sin nombre para búsqueda',
                          tag: 'SYNC',
                        );
                      }
                    }
                  }
                }
              }
            }

            List<UpdatePurchaseOrderItemParams>? updateItemParams;
            if (data['items'] != null) {
              updateItemParams =
                  (data['items'] as List)
                      .map(
                        (item) => UpdatePurchaseOrderItemParams(
                          id: item['id'],
                          productId: item['productId'],
                          quantity:
                              item['quantity'] is int
                                  ? item['quantity']
                                  : (item['quantity'] as num).toInt(),
                          receivedQuantity:
                              item['receivedQuantity'] is int
                                  ? item['receivedQuantity']
                                  : (item['receivedQuantity'] as num?)?.toInt(),
                          unitPrice:
                              (item['unitCost'] as num? ??
                                      item['unitPrice'] as num)
                                  .toDouble(),
                          discountPercentage:
                              item['discountPercentage'] != null
                                  ? (item['discountPercentage'] as num).toDouble()
                                  : 0,
                          taxPercentage:
                              item['taxPercentage'] != null
                                  ? (item['taxPercentage'] as num).toDouble()
                                  : 0,
                          notes: item['notes'],
                        ),
                      )
                      .toList();
            }

            final updateParams = UpdatePurchaseOrderParams(
              id: operation.entityId,
              supplierId: data['supplierId'],
              status:
                  data['status'] != null
                      ? PurchaseOrderStatus.values.firstWhere(
                        (e) => e.name == data['status'],
                      )
                      : null,
              priority:
                  data['priority'] != null
                      ? PurchaseOrderPriority.values.firstWhere(
                        (e) => e.name == data['priority'],
                      )
                      : null,
              orderDate:
                  data['orderDate'] != null
                      ? DateTime.parse(data['orderDate'])
                      : null,
              expectedDeliveryDate:
                  data['expectedDeliveryDate'] != null
                      ? DateTime.parse(data['expectedDeliveryDate'])
                      : null,
              deliveredDate:
                  data['deliveredDate'] != null
                      ? DateTime.parse(data['deliveredDate'])
                      : null,
              currency: data['currency'],
              items: updateItemParams,
              notes: data['notes'],
              internalNotes: data['internalNotes'],
              deliveryAddress: data['deliveryAddress'],
              contactPerson: data['contactPerson'],
              contactPhone: data['contactPhone'],
              contactEmail: data['contactEmail'],
              attachments:
                  data['attachments'] != null
                      ? List<String>.from(data['attachments'])
                      : null,
            );

            // Diagnóstico: imprimir payload antes de enviar
            AppLogger.d('PO UPDATE → id=${updateParams.id}, items=${updateParams.items?.length ?? 0}', tag: 'SYNC');
            if (updateParams.items != null) {
              for (int i = 0; i < updateParams.items!.length; i++) {
                final it = updateParams.items![i];
                AppLogger.d('  Item[$i]: id=${it.id}, productId=${it.productId}, qty=${it.quantity}, unitPrice=${it.unitPrice}', tag: 'SYNC');
              }
            }

            final updatedPO = await remoteDataSource.updatePurchaseOrder(updateParams);
            AppLogger.i('Orden de compra actualizada en servidor', tag: 'SYNC');

            // ✅ Marcar PO como sincronizada en ISAR y actualizar items con IDs del servidor
            try {
              final isar = IsarDatabase.instance.database;
              final isarPO = await isar.isarPurchaseOrders
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();
              if (isarPO != null) {
                isarPO.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarPurchaseOrders.put(isarPO);

                  // Actualizar items en ISAR con IDs asignados por el servidor
                  // (evita duplicación si el usuario edita la PO otra vez offline)
                  final serverPOEntity = updatedPO.toEntity();
                  if (serverPOEntity.items.isNotEmpty) {
                    // Eliminar items locales (pueden tener IDs temporales)
                    final oldItems = await isar.isarPurchaseOrderItems
                        .filter()
                        .purchaseOrderServerIdEqualTo(operation.entityId)
                        .findAll();
                    if (oldItems.isNotEmpty) {
                      await isar.isarPurchaseOrderItems
                          .deleteAll(oldItems.map((i) => i.id).toList());
                    }

                    // Insertar items del servidor con IDs reales
                    final newIsarItems = serverPOEntity.items.map((item) {
                      final isarItem = IsarPurchaseOrderItem.fromEntity(item);
                      isarItem.purchaseOrderServerId = operation.entityId;
                      return isarItem;
                    }).toList();
                    await isar.isarPurchaseOrderItems.putAll(newIsarItems);
                    AppLogger.d(
                      '${newIsarItems.length} items ISAR actualizados con IDs del servidor para PO ${operation.entityId}',
                      tag: 'SYNC',
                    );
                  }
                });
                AppLogger.d(
                  'PO ${operation.entityId} marcada como sincronizada en ISAR',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w('Error marcando PO como sincronizada: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando orden de compra en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deletePurchaseOrder(operation.entityId);
          AppLogger.i('Orden de compra eliminada en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Orden de compra ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de InventoryMovement
  Future<void> _syncInventoryMovementOperation(SyncOperation operation) async {
    try {
      final InventoryRemoteDataSource remoteDataSource;
      if (Get.isRegistered<InventoryRemoteDataSource>()) {
        remoteDataSource = Get.find<InventoryRemoteDataSource>();
      } else {
        remoteDataSource = InventoryRemoteDataSourceImpl(
          dio: Get.find<DioClient>().dio,
        );
      }
      final data = jsonDecode(operation.payload);

      // ✅ Resolver referenceId temporal → ID real del servidor
      // Esto es necesario cuando la PO se sincronizó en un ciclo anterior
      // y el referenceId no fue actualizado en el payload de este movimiento
      final refId = data['referenceId'] as String?;
      final refType = data['referenceType'] as String?;
      if (refId != null &&
          refType == 'purchase_order' &&
          (refId.startsWith('po_offline_') || refId.startsWith('po_'))) {
        try {
          final isar = IsarDatabase.instance.database;
          // Intentar encontrar la PO por su temp ID en ISAR
          final isarPO = await isar.isarPurchaseOrders
              .filter()
              .serverIdEqualTo(refId)
              .findFirst();

          if (isarPO != null) {
            // PO encontrada con el temp ID - aún no sincronizada
            // Los movimientos deberían esperar a que la PO se sincronice primero
            AppLogger.w(
              'InventoryMovement referencia PO con ID temporal: $refId (PO aún no sincronizada)',
              tag: 'SYNC',
            );
          } else {
            // PO no encontrada con temp ID → ya fue sincronizada y su serverId cambió al real
            // Enviar sin referenceId para evitar error 500 del backend
            AppLogger.w(
              'PO con temp ID $refId ya fue sincronizada. Eliminando referenceId temporal del movimiento.',
              tag: 'SYNC',
            );
            data['referenceId'] = null;
            // Actualizar el payload en la operación para que no falle en reintentos
            try {
              await _isarDatabase.updateSyncOperationPayload(
                operation.id,
                jsonEncode(data),
              );
            } catch (_) {}
          }
        } catch (e) {
          AppLogger.w('Error resolviendo referenceId temporal: $e', tag: 'SYNC');
          // En caso de error, quitar el referenceId temporal para evitar 500
          data['referenceId'] = null;
        }
      }

      switch (operation.operationType) {
        case SyncOperationType.create:
          // FIFO: usar endpoint específico /process-outbound-fifo
          if (operation.entityType == 'inventory_movement_fifo') {
            AppLogger.d(
              'Procesando movimiento FIFO en servidor: ${data['productId']}',
              tag: 'SYNC',
            );
            final fifoRequest = {
              'productId': data['productId'],
              'quantity': data['quantity'] is int
                  ? data['quantity']
                  : (data['quantity'] as num).toInt(),
              'reason': data['reason'],
              'warehouseId': data['warehouseId'],
              'referenceId': data['referenceId'],
              'referenceType': data['referenceType'],
              'notes': data['notes'],
              'movementDate': data['movementDate'],
            };
            final createdFifo = await remoteDataSource.processOutboundMovementFifo(fifoRequest);
            AppLogger.i(
              'Movimiento FIFO procesado en servidor con ID: ${createdFifo.id}',
              tag: 'SYNC',
            );

            // ✅ Actualizar ISAR con el ID real del servidor
            if (operation.entityId.startsWith('movement_')) {
              try {
                final isar = IsarDatabase.instance.database;
                final isarMovement = await isar.isarInventoryMovements
                    .filter()
                    .serverIdEqualTo(operation.entityId)
                    .findFirst();

                if (isarMovement != null) {
                  isarMovement.serverId = createdFifo.id;
                  isarMovement.markAsSynced();
                  await isar.writeTxn(() async {
                    await isar.isarInventoryMovements.put(isarMovement);
                  });
                  AppLogger.i(
                    'ISAR movimiento FIFO actualizado: ${operation.entityId} → ${createdFifo.id}',
                    tag: 'SYNC',
                  );
                }
              } catch (e) {
                AppLogger.w('Error actualizando movimiento FIFO en ISAR: $e', tag: 'SYNC');
              }
            }
          } else {
            // Movimiento regular
            // ✅ Convertir type de frontend enum (.name) a backend value si es necesario
            // Operaciones encoladas antes del fix guardaban 'inbound'/'outbound' en vez de 'purchase'/'sale'
            String movementType = data['type'] as String? ?? 'purchase';
            const typeMapping = {
              'inbound': 'purchase',
              'outbound': 'sale',
              'transferIn': 'transfer_in',
              'transferOut': 'transfer_out',
            };
            if (typeMapping.containsKey(movementType)) {
              AppLogger.d(
                'Convirtiendo type de movimiento: $movementType → ${typeMapping[movementType]}',
                tag: 'SYNC',
              );
              movementType = typeMapping[movementType]!;
            }

            AppLogger.d(
              'Creando movimiento de inventario en servidor: ${data['productId']} (type: $movementType)',
              tag: 'SYNC',
            );
            final request = CreateInventoryMovementRequest(
              productId: data['productId'],
              type: movementType,
              reason: data['reason'],
              quantity:
                  data['quantity'] is int
                      ? data['quantity']
                      : (data['quantity'] as num).toInt(),
              unitCost: (data['unitCost'] as num).toDouble(),
              lotNumber: data['lotNumber'],
              expiryDate:
                  data['expiryDate'] != null
                      ? DateTime.parse(data['expiryDate'])
                      : null,
              warehouseId: data['warehouseId'],
              referenceId: data['referenceId'],
              referenceType: data['referenceType'],
              notes: data['notes'],
              movementDate:
                  data['movementDate'] != null
                      ? DateTime.parse(data['movementDate'])
                      : null,
            );
            final createdMovement = await remoteDataSource.createMovement(request);
            AppLogger.i(
              'Movimiento de inventario creado en servidor con ID: ${createdMovement.id}',
              tag: 'SYNC',
            );

            // ✅ Actualizar ISAR con el ID real del servidor
            if (operation.entityId.startsWith('movement_')) {
              try {
                final isar = IsarDatabase.instance.database;
                final isarMovement = await isar.isarInventoryMovements
                    .filter()
                    .serverIdEqualTo(operation.entityId)
                    .findFirst();

                if (isarMovement != null) {
                  isarMovement.serverId = createdMovement.id;
                  isarMovement.markAsSynced();
                  await isar.writeTxn(() async {
                    await isar.isarInventoryMovements.put(isarMovement);
                  });
                  AppLogger.i(
                    'ISAR movimiento actualizado: ${operation.entityId} → ${createdMovement.id}',
                    tag: 'SYNC',
                  );
                }
              } catch (e) {
                AppLogger.w('Error actualizando movimiento en ISAR: $e', tag: 'SYNC');
              }
            }
          }

          // Limpiar operaciones UPDATE obsoletas para movimientos
          if (operation.entityId.startsWith('movement_')) {
            try {
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }
            } catch (e) {
              AppLogger.w('Error limpiando ops obsoletas de movimiento: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando movimiento de inventario en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          final updateRequest = UpdateInventoryMovementRequest(
            type: data['type'],
            reason: data['reason'],
            quantity:
                data['quantity'] != null
                    ? (data['quantity'] is int
                        ? data['quantity']
                        : (data['quantity'] as num).toInt())
                    : null,
            unitCost:
                data['unitCost'] != null
                    ? (data['unitCost'] as num).toDouble()
                    : null,
            lotNumber: data['lotNumber'],
            expiryDate:
                data['expiryDate'] != null
                    ? DateTime.parse(data['expiryDate'])
                    : null,
            warehouseId: data['warehouseId'],
            referenceId: data['referenceId'],
            referenceType: data['referenceType'],
            notes: data['notes'],
            movementDate:
                data['movementDate'] != null
                    ? DateTime.parse(data['movementDate'])
                    : null,
          );
          await remoteDataSource.updateMovement(
            operation.entityId,
            updateRequest,
          );
          AppLogger.i(
            'Movimiento de inventario actualizado en servidor',
            tag: 'SYNC',
          );
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando movimiento de inventario en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteMovement(operation.entityId);
          AppLogger.i(
            'Movimiento de inventario eliminado en servidor',
            tag: 'SYNC',
          );
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Movimiento de inventario ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de CreditNote
  Future<void> _syncCreditNoteOperation(SyncOperation operation) async {
    try {
      final CreditNoteRemoteDataSource remoteDataSource;
      if (Get.isRegistered<CreditNoteRemoteDataSource>()) {
        remoteDataSource = Get.find<CreditNoteRemoteDataSource>();
      } else {
        remoteDataSource = CreditNoteRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando nota de crédito en servidor: ${data['invoiceId']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para notas de crédito offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('creditnote_offline_')) {
            AppLogger.d(
              'Nota de crédito offline detectada - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<CreditNoteOfflineRepository>();
              final creditNoteResult = await offlineRepo.getCreditNoteById(
                operation.entityId,
              );

              creditNoteResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo nota de crédito offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (creditNote) {
                  finalData = {
                    'invoiceId': creditNote.invoiceId,
                    'type': creditNote.type.value,
                    'reason': creditNote.reason.value,
                    'reasonDescription': creditNote.reasonDescription,
                    'restoreInventory': creditNote.restoreInventory,
                    'notes': creditNote.notes,
                    'terms': creditNote.terms,
                    'items':
                        creditNote.items
                            .map(
                              (item) => {
                                'invoiceItemId': item.invoiceItemId,
                                'quantity': item.quantity,
                                'unitPrice': item.unitPrice,
                                'description': item.description,
                                'notes': item.notes,
                              },
                            )
                            .toList(),
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR para nota de crédito: ${creditNote.number}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo nota de crédito de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          // Parsear items
          final items =
              (finalData['items'] as List)
                  .map(
                    (item) => CreateCreditNoteItemRequestModel(
                      invoiceItemId: item['invoiceItemId'],
                      quantity: (item['quantity'] as num).toDouble(),
                      unitPrice: (item['unitPrice'] as num).toDouble(),
                      description: item['description'] ?? '',
                      notes: item['notes'],
                    ),
                  )
                  .toList();

          final request = CreateCreditNoteRequestModel(
            invoiceId: finalData['invoiceId'],
            type: finalData['type'],
            reason: finalData['reason'],
            reasonDescription: finalData['reasonDescription'],
            items: items,
            restoreInventory: finalData['restoreInventory'] ?? true,
            notes: finalData['notes'],
            terms: finalData['terms'],
          );

          final createdCreditNote = await remoteDataSource.createCreditNote(request);
          AppLogger.i(
            'Nota de crédito creada en servidor con ID: ${createdCreditNote.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('creditnote_offline_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarCN = await isar.isarCreditNotes
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarCN != null) {
                isarCN.serverId = createdCreditNote.id;
                isarCN.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.isarCreditNotes.put(isarCN);
                });
                AppLogger.i(
                  'ISAR nota de crédito actualizada: ${operation.entityId} → ${createdCreditNote.id}',
                  tag: 'SYNC',
                );
              }

              // Limpiar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }
            } catch (e) {
              AppLogger.w('Error actualizando nota de crédito en ISAR: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando nota de crédito en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          final updateRequest = UpdateCreditNoteRequestModel(
            reason: data['reason'],
            reasonDescription: data['reasonDescription'],
            restoreInventory: data['restoreInventory'],
            notes: data['notes'],
            terms: data['terms'],
          );
          await remoteDataSource.updateCreditNote(
            operation.entityId,
            updateRequest,
          );
          AppLogger.i('Nota de crédito actualizada en servidor', tag: 'SYNC');
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando nota de crédito en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteCreditNote(operation.entityId);
          AppLogger.i('Nota de crédito eliminada en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Nota de crédito ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de CustomerCredit
  Future<void> _syncCustomerCreditOperation(SyncOperation operation) async {
    try {
      final CustomerCreditRemoteDataSource remoteDataSource;
      if (Get.isRegistered<CustomerCreditRemoteDataSource>()) {
        remoteDataSource = Get.find<CustomerCreditRemoteDataSource>();
      } else {
        remoteDataSource = CustomerCreditRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando crédito de cliente en servidor: ${data['customerId']}',
            tag: 'SYNC',
          );

          // ✅ FASE 1 - PROBLEMA 3: Leer datos frescos de ISAR para créditos de cliente offline
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('customercredit_offline_')) {
            AppLogger.d(
              'Crédito de cliente offline detectado - leyendo datos actuales de ISAR',
              tag: 'SYNC',
            );
            try {
              final offlineRepo = Get.find<CustomerCreditOfflineRepository>();
              final creditResult = await offlineRepo.getCreditById(
                operation.entityId,
              );

              creditResult.fold(
                (failure) {
                  AppLogger.w(
                    'Error obteniendo crédito de cliente offline: ${failure.toString()} - usando datos del payload',
                    tag: 'SYNC',
                  );
                },
                (credit) {
                  finalData = {
                    'customerId': credit.customerId,
                    'originalAmount': credit.originalAmount,
                    'dueDate': credit.dueDate?.toIso8601String(),
                    'description': credit.description,
                    'notes': credit.notes,
                    'invoiceId': credit.invoiceId,
                  };
                  AppLogger.d(
                    'Datos actuales obtenidos de ISAR para crédito de cliente: ${credit.id}',
                    tag: 'SYNC',
                  );
                },
              );
            } catch (e) {
              AppLogger.w(
                'Error leyendo crédito de cliente de ISAR: $e - usando datos del payload',
                tag: 'SYNC',
              );
            }
          }

          final request = CreateCustomerCreditDto(
            customerId: finalData['customerId'],
            originalAmount: (finalData['originalAmount'] as num).toDouble(),
            dueDate: finalData['dueDate'],
            description: finalData['description'],
            notes: finalData['notes'],
            invoiceId: finalData['invoiceId'],
            useClientBalance: finalData['useClientBalance'],
            skipAutoBalance: finalData['skipAutoBalance'],
          );
          final createdCredit = await remoteDataSource.createCredit(request);
          AppLogger.i(
            'Crédito de cliente creado en servidor con ID: ${createdCredit.id}',
            tag: 'SYNC',
          );

          // ✅ Actualizar ISAR con el ID real del servidor
          if (operation.entityId.startsWith('customercredit_offline_')) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarCredit = await isar.isarCustomerCredits
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarCredit != null) {
                isarCredit.serverId = createdCredit.id;
                isarCredit.isSynced = true;
                isarCredit.lastSyncAt = DateTime.now();
                await isar.writeTxn(() async {
                  await isar.isarCustomerCredits.put(isarCredit);
                });
                AppLogger.i(
                  'ISAR crédito de cliente actualizado: ${operation.entityId} → ${createdCredit.id}',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w('Error actualizando crédito en ISAR: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          final action = data['action'] as String?;
          if (action == 'addPayment') {
            AppLogger.d(
              'Procesando addPayment offline para crédito: ${operation.entityId}',
              tag: 'SYNC',
            );

            // Resolver temp ID si es necesario
            String creditId = operation.entityId;
            if (creditId.startsWith('customercredit_offline_') ||
                creditId.startsWith('credit_offline_')) {
              final isar = IsarDatabase.instance.database;
              final isarCredit = await isar.isarCustomerCredits
                  .filter()
                  .serverIdEqualTo(creditId)
                  .findFirst();
              if (isarCredit != null &&
                  !isarCredit.serverId.startsWith('customercredit_offline_') &&
                  !isarCredit.serverId.startsWith('credit_offline_')) {
                creditId = isarCredit.serverId;
                AppLogger.d(
                  'Temp credit ID resuelto: ${operation.entityId} → $creditId',
                  tag: 'SYNC',
                );
              } else {
                throw Exception(
                  'Credit ${operation.entityId} aún no sincronizado - reintentando después',
                );
              }
            }

            final dto = AddCreditPaymentDto(
              amount: (data['amount'] as num).toDouble(),
              paymentMethod: data['paymentMethod'] ?? 'cash',
              paymentDate: data['paymentDate'],
              reference: data['reference'],
              notes: data['notes'],
              bankAccountId: data['bankAccountId'],
            );
            final updatedCredit = await remoteDataSource.addPayment(creditId, dto);
            AppLogger.i(
              'Pago a crédito sincronizado exitosamente: $creditId',
              tag: 'SYNC',
            );

            // Actualizar ISAR con respuesta del servidor
            try {
              final isar = IsarDatabase.instance.database;
              final isarCredit = await isar.isarCustomerCredits
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();
              if (isarCredit != null && updatedCredit is CustomerCreditModel) {
                isarCredit.paidAmount = updatedCredit.paidAmount;
                isarCredit.balanceDue = updatedCredit.balanceDue;
                isarCredit.status = _mapCreditStatusForSync(updatedCredit.status);
                isarCredit.isSynced = true;
                isarCredit.lastSyncAt = DateTime.now();
                await isar.writeTxn(() async {
                  await isar.isarCustomerCredits.put(isarCredit);
                });
                AppLogger.d(
                  'ISAR crédito actualizado tras sync: paidAmount=${updatedCredit.paidAmount}',
                  tag: 'SYNC',
                );
              }
            } catch (e) {
              AppLogger.w('Error actualizando crédito en ISAR tras sync: $e', tag: 'SYNC');
            }
          } else {
            AppLogger.w(
              'UPDATE action desconocida para CustomerCredit: $action',
              tag: 'SYNC',
            );
          }
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando crédito de cliente en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deleteCredit(operation.entityId);
          AppLogger.i('Crédito de cliente eliminado en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Crédito de cliente ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de ClientBalance (deposit, use, refund, adjust)
  Future<void> _syncClientBalanceOperation(SyncOperation operation) async {
    try {
      final CustomerCreditRemoteDataSource remoteDataSource;
      if (Get.isRegistered<CustomerCreditRemoteDataSource>()) {
        remoteDataSource = Get.find<CustomerCreditRemoteDataSource>();
      } else {
        remoteDataSource = CustomerCreditRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);
      final action = data['action'] as String? ?? 'use';

      AppLogger.d(
        'Sincronizando ClientBalance [$action]: cliente=${data['clientId']}',
        tag: 'SYNC',
      );

      switch (action) {
        case 'deposit':
          await remoteDataSource.depositBalance(DepositBalanceDto(
            customerId: data['customerId'] ?? data['clientId'],
            amount: (data['amount'] as num).toDouble(),
            description: data['description'] ?? '',
            relatedCreditId: data['relatedCreditId'],
          ));
          break;
        case 'use':
          await remoteDataSource.useBalance(UseBalanceDto(
            clientId: data['clientId'],
            amount: (data['amount'] as num).toDouble(),
            description: data['description'] ?? '',
            relatedCreditId: data['relatedCreditId'],
          ));
          break;
        case 'refund':
          await remoteDataSource.refundBalance(RefundBalanceDto(
            clientId: data['clientId'],
            amount: (data['amount'] as num).toDouble(),
            description: data['description'] ?? '',
            paymentMethod: data['paymentMethod'] ?? 'cash',
          ));
          break;
        case 'adjust':
          await remoteDataSource.adjustBalance(AdjustBalanceDto(
            clientId: data['clientId'],
            amount: (data['amount'] as num).toDouble(),
            description: data['description'] ?? '',
          ));
          break;
        default:
          AppLogger.w(
            'Acción de ClientBalance no reconocida: $action',
            tag: 'SYNC',
          );
          throw Exception('Acción de ClientBalance no soportada: $action');
      }

      AppLogger.i(
        'ClientBalance [$action] sincronizado exitosamente',
        tag: 'SYNC',
      );
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Operación de ClientBalance ya procesada en servidor - marcando como completada',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  // ==================== CONFLICT RESOLUTION ====================

  /// Maneja un conflicto 409 de forma centralizada usando el ConflictResolutionService
  Future<bool> _handleConflict409({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localData,
    required Future<Map<String, dynamic>> Function() fetchServerData,
    required Future<void> Function(Map<String, dynamic> resolvedData)
    applyResolution,
  }) async {
    try {
      final conflictService = Get.find<ConflictResolutionService>();

      // Obtener datos del servidor
      final serverData = await fetchServerData();

      // Resolver el conflicto
      final result = conflictService.resolveConflict(
        entityType: entityType,
        localData: localData,
        serverData: serverData,
      );

      if (!result.resolved || result.mergedData == null) {
        AppLogger.w(
          'Conflicto no resuelto para $entityType:$entityId: ${result.error}',
          tag: 'CONFLICT',
        );
        return false;
      }

      // Aplicar la resolución
      await applyResolution(result.mergedData!);

      // Log del conflicto
      conflictService.logConflict(
        entityType: entityType,
        entityId: entityId,
        localData: localData,
        serverData: serverData,
        result: result,
      );

      AppLogger.i(
        'Conflicto resuelto automáticamente para $entityType:$entityId',
        tag: 'CONFLICT',
      );
      return true;
    } catch (e) {
      AppLogger.e('Error manejando conflicto 409: $e', tag: 'CONFLICT');
      return false;
    }
  }

  // ==================== ORGANIZATION SYNC ====================

  /// Sincronizar operación de organización
  Future<void> _syncOrganizationOperation(SyncOperation operation) async {
    try {
      final OrganizationRemoteDataSource remoteDataSource;
      if (Get.isRegistered<OrganizationRemoteDataSource>()) {
        remoteDataSource = Get.find<OrganizationRemoteDataSource>();
      } else {
        remoteDataSource = OrganizationRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.update:
          if (operation.entityType == 'organization_profit_margin') {
            // Actualizar solo margen de ganancia
            AppLogger.d(
              'Sincronizando margen de ganancia: ${data['defaultProfitMarginPercentage']}%',
              tag: 'SYNC',
            );
            final marginPercentage =
                (data['defaultProfitMarginPercentage'] as num).toDouble();
            await remoteDataSource.updateProfitMargin(marginPercentage);
            AppLogger.i(
              'Margen de ganancia sincronizado: $marginPercentage%',
              tag: 'SYNC',
            );
          } else {
            // Actualizar organización completa
            AppLogger.d(
              'Sincronizando actualización de organización: ${operation.entityId}',
              tag: 'SYNC',
            );
            await remoteDataSource.updateCurrentOrganization(data);
            AppLogger.i('Organización actualizada en servidor', tag: 'SYNC');
          }

          // Marcar como sincronizado en ISAR
          try {
            final offlineRepo = Get.find<OrganizationOfflineRepository>();
            await offlineRepo.markOrganizationAsSynced(operation.entityId);
          } catch (e) {
            AppLogger.w(
              'Error marcando organización como sincronizada: $e',
              tag: 'SYNC',
            );
          }
          break;

        case SyncOperationType.create:
          AppLogger.w(
            'CREATE no está soportado para Organization - solo UPDATE',
            tag: 'SYNC',
          );
          break;

        case SyncOperationType.delete:
          AppLogger.w(
            'DELETE no está soportado para Organization',
            tag: 'SYNC',
          );
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Conflicto al sincronizar organización - servidor tiene versión más reciente',
          tag: 'SYNC',
        );
        // En caso de conflicto, sincronizar datos del servidor a local
        try {
          final OrganizationRemoteDataSource conflictRemoteDs;
          if (Get.isRegistered<OrganizationRemoteDataSource>()) {
            conflictRemoteDs = Get.find<OrganizationRemoteDataSource>();
          } else {
            conflictRemoteDs = OrganizationRemoteDataSourceImpl(
              dioClient: Get.find<DioClient>(),
            );
          }
          final offlineRepo = Get.find<OrganizationOfflineRepository>();
          final serverOrg = await conflictRemoteDs.getCurrentOrganization();
          await offlineRepo.cacheOrganization(serverOrg);
          AppLogger.i(
            'Organización sincronizada desde servidor después de conflicto',
            tag: 'SYNC',
          );
        } catch (syncError) {
          AppLogger.w(
            'Error sincronizando desde servidor: $syncError',
            tag: 'SYNC',
          );
        }
        return;
      }
      rethrow;
    }
  }

  // ==================== USER PROFILE SYNC ====================

  /// Sincronizar operación de perfil de usuario
  Future<void> _syncUserProfileOperation(SyncOperation operation) async {
    try {
      final AuthRemoteDataSource remoteDataSource;
      if (Get.isRegistered<AuthRemoteDataSource>()) {
        remoteDataSource = Get.find<AuthRemoteDataSource>();
      } else {
        remoteDataSource = AuthRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final AuthLocalDataSource localDataSource;
      if (Get.isRegistered<AuthLocalDataSource>()) {
        localDataSource = Get.find<AuthLocalDataSource>();
      } else {
        localDataSource = AuthLocalDataSourceImpl(
          storageService: Get.find<SecureStorageService>(),
        );
      }
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.update:
          AppLogger.d(
            'Sincronizando actualización de perfil de usuario: ${operation.entityId}',
            tag: 'SYNC',
          );

          // Crear request model desde los datos del payload
          final request = UpdateProfileRequestModel(
            firstName: data['firstName'] as String?,
            lastName: data['lastName'] as String?,
            phone: data['phone'] as String?,
            avatar: data['avatar'] as String?,
          );

          // Solo sincronizar si hay datos para actualizar
          if (request.hasUpdates) {
            // Enviar al servidor
            final updatedUser = await remoteDataSource.updateProfile(request);
            AppLogger.i(
              'Perfil de usuario sincronizado: ${updatedUser.email}',
              tag: 'SYNC',
            );

            // Actualizar datos locales con la respuesta del servidor
            try {
              await localDataSource.saveUser(updatedUser);
              AppLogger.d(
                'Datos de usuario actualizados localmente después de sync',
                tag: 'SYNC',
              );
            } catch (e) {
              AppLogger.w(
                'Error actualizando usuario local después de sync: $e',
                tag: 'SYNC',
              );
            }
          } else {
            AppLogger.w(
              'No hay datos para actualizar en perfil de usuario',
              tag: 'SYNC',
            );
          }
          break;

        case SyncOperationType.create:
          AppLogger.w(
            'CREATE no está soportado para user_profile - solo UPDATE',
            tag: 'SYNC',
          );
          break;

        case SyncOperationType.delete:
          AppLogger.w(
            'DELETE no está soportado para user_profile',
            tag: 'SYNC',
          );
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Conflicto al sincronizar perfil - servidor tiene versión más reciente',
          tag: 'SYNC',
        );
        // En caso de conflicto, obtener datos frescos del servidor
        try {
          final AuthRemoteDataSource conflictRemoteDs;
          if (Get.isRegistered<AuthRemoteDataSource>()) {
            conflictRemoteDs = Get.find<AuthRemoteDataSource>();
          } else {
            conflictRemoteDs = AuthRemoteDataSourceImpl(
              dioClient: Get.find<DioClient>(),
            );
          }
          final AuthLocalDataSource conflictLocalDs;
          if (Get.isRegistered<AuthLocalDataSource>()) {
            conflictLocalDs = Get.find<AuthLocalDataSource>();
          } else {
            conflictLocalDs = AuthLocalDataSourceImpl(
              storageService: Get.find<SecureStorageService>(),
            );
          }
          final serverProfile = await conflictRemoteDs.getProfile();
          await conflictLocalDs.saveUser(serverProfile.user);
          AppLogger.i(
            'Perfil sincronizado desde servidor después de conflicto',
            tag: 'SYNC',
          );
        } catch (syncError) {
          AppLogger.w(
            'Error sincronizando perfil desde servidor: $syncError',
            tag: 'SYNC',
          );
        }
        return;
      }
      rethrow;
    }
  }

  // ==================== NOTIFICATION SYNC ====================

  /// Verificar si es una notificación dinámica (generada por el dashboard)
  /// Las notificaciones dinámicas tienen prefijos como: stock_, invoice_, payment_, etc.
  bool _isDynamicNotification(String id) {
    final dynamicPrefixes = [
      'stock_',
      'invoice_',
      'payment_',
      'customer_',
      'system_',
      'report_',
      'backup_',
      'security_',
    ];
    return dynamicPrefixes.any((prefix) => id.startsWith(prefix));
  }

  /// Sincronizar operación de notificación
  Future<void> _syncNotificationOperation(SyncOperation operation) async {
    try {
      // Las notificaciones dinámicas (stock_*, invoice_*, etc.) no existen en el backend
      // Se manejan solo localmente y no requieren sincronización
      if (_isDynamicNotification(operation.entityId)) {
        AppLogger.i(
          'Notificación dinámica detectada - operación solo local: ${operation.entityId}',
          tag: 'SYNC',
        );
        // Para notificaciones dinámicas, solo actualizar el cache local si es necesario
        if (Get.isRegistered<NotificationLocalDataSource>()) {
          try {
            final localDataSource = Get.find<NotificationLocalDataSource>();
            final data = jsonDecode(operation.payload);
            final cachedNotification = await localDataSource
                .getCachedNotification(operation.entityId);
            if (cachedNotification != null && data['isRead'] != null) {
              final updated = cachedNotification.copyWith(
                isRead: data['isRead'] as bool,
              );
              await localDataSource.cacheNotification(updated);
              AppLogger.d(
                'Notificación dinámica actualizada localmente',
                tag: 'SYNC',
              );
            }
          } catch (e) {
            AppLogger.w(
              'Error actualizando notificación dinámica localmente: $e',
              tag: 'SYNC',
            );
          }
        }
        return; // No sincronizar con el servidor
      }

      // Para notificaciones normales, verificar que los datasources estén disponibles
      if (!Get.isRegistered<NotificationRemoteDataSource>()) {
        AppLogger.w(
          'NotificationRemoteDataSource no registrado - saltando sincronización',
          tag: 'SYNC',
        );
        return;
      }

      final NotificationRemoteDataSource remoteDataSource =
          Get.find<NotificationRemoteDataSource>();
      final NotificationLocalDataSource localDataSource =
          Get.find<NotificationLocalDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.update:
          AppLogger.d(
            'Sincronizando actualización de notificación: ${operation.entityId}',
            tag: 'SYNC',
          );

          // Verificar si es operación de marcar como leída
          final isRead = data['isRead'] as bool?;
          if (isRead == true) {
            // Marcar como leída en el servidor
            final updatedNotification = await remoteDataSource.markAsRead(
              operation.entityId,
            );
            AppLogger.i(
              'Notificación marcada como leída en servidor: ${operation.entityId}',
              tag: 'SYNC',
            );

            // Actualizar cache local con la respuesta del servidor
            try {
              await localDataSource.cacheNotification(updatedNotification);
              AppLogger.d(
                'Cache local de notificación actualizado después de sync',
                tag: 'SYNC',
              );
            } catch (e) {
              AppLogger.w(
                'Error actualizando cache de notificación después de sync: $e',
                tag: 'SYNC',
              );
            }
          } else if (isRead == false) {
            // Marcar como no leída en el servidor
            final updatedNotification = await remoteDataSource.markAsUnread(
              operation.entityId,
            );
            AppLogger.i(
              'Notificación marcada como no leída en servidor: ${operation.entityId}',
              tag: 'SYNC',
            );

            // Actualizar cache local
            try {
              await localDataSource.cacheNotification(updatedNotification);
              AppLogger.d(
                'Cache local de notificación actualizado después de sync',
                tag: 'SYNC',
              );
            } catch (e) {
              AppLogger.w(
                'Error actualizando cache de notificación después de sync: $e',
                tag: 'SYNC',
              );
            }
          } else {
            AppLogger.w(
              'Operación UPDATE de notificación sin datos válidos',
              tag: 'SYNC',
            );
          }
          break;

        case SyncOperationType.create:
          AppLogger.w(
            'CREATE no está soportado para notification en sync_service',
            tag: 'SYNC',
          );
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Sincronizando eliminación de notificación: ${operation.entityId}',
            tag: 'SYNC',
          );
          // Eliminar notificación en el servidor
          await remoteDataSource.deleteNotification(operation.entityId);
          AppLogger.i(
            'Notificación eliminada en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );

          // Eliminar del cache local
          try {
            await localDataSource.removeCachedNotification(operation.entityId);
            AppLogger.d('Notificación eliminada del cache local', tag: 'SYNC');
          } catch (e) {
            AppLogger.w(
              'Error eliminando notificación del cache local: $e',
              tag: 'SYNC',
            );
          }
          break;
      }
    } catch (e) {
      if (e is ServerException) {
        if (e.statusCode == 404) {
          // La notificación no existe en el servidor (ya fue eliminada o nunca existió)
          AppLogger.w(
            'Notificación no encontrada en servidor (404), limpiando operación',
            tag: 'SYNC',
          );
          // Limpiar del cache local si existe
          try {
            if (Get.isRegistered<NotificationLocalDataSource>()) {
              final localDs = Get.find<NotificationLocalDataSource>();
              await localDs.removeCachedNotification(operation.entityId);
            }
          } catch (_) {}
          return; // No propagar el error, la operación ya no es relevante
        }
        if (e.statusCode == 409) {
          AppLogger.w(
            'Conflicto al sincronizar notificación - servidor tiene versión más reciente',
            tag: 'SYNC',
          );
          // En caso de conflicto, obtener datos frescos del servidor
          try {
            if (!Get.isRegistered<NotificationRemoteDataSource>()) return;
            final remoteDataSource = Get.find<NotificationRemoteDataSource>();
            final localDataSource = Get.find<NotificationLocalDataSource>();
            final serverNotification = await remoteDataSource
                .getNotificationById(operation.entityId);
            await localDataSource.cacheNotification(serverNotification);
            AppLogger.i(
              'Notificación sincronizada desde servidor después de conflicto',
              tag: 'SYNC',
            );
          } catch (syncError) {
            AppLogger.w(
              'Error sincronizando notificación desde servidor: $syncError',
              tag: 'SYNC',
            );
          }
          return; // No propagar el error de conflicto
        }
      }
      rethrow;
    }
  }

  // ==================== USER PREFERENCES SYNC ====================

  /// Sincronizar operación de preferencias de usuario
  Future<void> _syncUserPreferencesOperation(SyncOperation operation) async {
    try {
      final UserPreferencesRemoteDataSource remoteDataSource;
      if (Get.isRegistered<UserPreferencesRemoteDataSource>()) {
        remoteDataSource = Get.find<UserPreferencesRemoteDataSource>();
      } else {
        remoteDataSource = UserPreferencesRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final UserPreferencesLocalDataSource localDataSource;
      if (Get.isRegistered<UserPreferencesLocalDataSource>()) {
        localDataSource = Get.find<UserPreferencesLocalDataSource>();
      } else {
        localDataSource = UserPreferencesLocalDataSourceImpl();
      }
      final data = jsonDecode(operation.payload) as Map<String, dynamic>;

      switch (operation.operationType) {
        case SyncOperationType.update:
          AppLogger.d(
            'Sincronizando actualización de preferencias de usuario: ${operation.entityId}',
            tag: 'SYNC',
          );

          // Enviar preferencias al servidor
          final updatedPreferences = await remoteDataSource
              .updateUserPreferences(data);
          AppLogger.i(
            'Preferencias de usuario sincronizadas exitosamente',
            tag: 'SYNC',
          );

          // Actualizar cache local con la respuesta del servidor
          // UserPreferencesModel extends UserPreferences, so it can be used directly
          try {
            await localDataSource.cacheUserPreferences(updatedPreferences);

            // Marcar como sincronizado
            await localDataSource.markAsSynced(operation.entityId);
            AppLogger.d(
              'Cache local de preferencias actualizado después de sync',
              tag: 'SYNC',
            );
          } catch (e) {
            AppLogger.w(
              'Error actualizando cache de preferencias después de sync: $e',
              tag: 'SYNC',
            );
          }
          break;

        case SyncOperationType.create:
          AppLogger.w(
            'CREATE no está soportado para user_preferences - solo UPDATE',
            tag: 'SYNC',
          );
          break;

        case SyncOperationType.delete:
          AppLogger.w(
            'DELETE no está soportado para user_preferences',
            tag: 'SYNC',
          );
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Conflicto al sincronizar preferencias - servidor tiene versión más reciente',
          tag: 'SYNC',
        );
        // En caso de conflicto, obtener datos frescos del servidor
        try {
          final UserPreferencesRemoteDataSource conflictRemoteDs;
          if (Get.isRegistered<UserPreferencesRemoteDataSource>()) {
            conflictRemoteDs = Get.find<UserPreferencesRemoteDataSource>();
          } else {
            conflictRemoteDs = UserPreferencesRemoteDataSourceImpl(
              dioClient: Get.find<DioClient>(),
            );
          }
          final UserPreferencesLocalDataSource conflictLocalDs;
          if (Get.isRegistered<UserPreferencesLocalDataSource>()) {
            conflictLocalDs = Get.find<UserPreferencesLocalDataSource>();
          } else {
            conflictLocalDs = UserPreferencesLocalDataSourceImpl();
          }
          final serverPreferences = await conflictRemoteDs.getUserPreferences();

          // UserPreferencesModel extends UserPreferences, so it can be used directly
          await conflictLocalDs.cacheUserPreferences(serverPreferences);
          AppLogger.i(
            'Preferencias sincronizadas desde servidor después de conflicto',
            tag: 'SYNC',
          );
        } catch (syncError) {
          AppLogger.w(
            'Error sincronizando preferencias desde servidor: $syncError',
            tag: 'SYNC',
          );
        }
        return; // No propagar el error de conflicto
      }
      rethrow;
    }
  }

  /// Mapear InvoiceStatus a IsarInvoiceStatus para actualizaciones tras sync
  IsarInvoiceStatus _mapInvoiceStatusToIsar(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return IsarInvoiceStatus.draft;
      case InvoiceStatus.pending:
        return IsarInvoiceStatus.pending;
      case InvoiceStatus.paid:
        return IsarInvoiceStatus.paid;
      case InvoiceStatus.overdue:
        return IsarInvoiceStatus.overdue;
      case InvoiceStatus.cancelled:
        return IsarInvoiceStatus.cancelled;
      case InvoiceStatus.partiallyPaid:
        return IsarInvoiceStatus.partiallyPaid;
      case InvoiceStatus.credited:
        return IsarInvoiceStatus.credited;
      case InvoiceStatus.partiallyCredited:
        return IsarInvoiceStatus.partiallyCredited;
    }
  }

  /// Mapear CreditStatus (entity) a IsarCreditStatus para actualizaciones tras sync
  IsarCreditStatus _mapCreditStatusForSync(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return IsarCreditStatus.pending;
      case CreditStatus.partiallyPaid:
        return IsarCreditStatus.partiallyPaid;
      case CreditStatus.paid:
        return IsarCreditStatus.paid;
      case CreditStatus.cancelled:
        return IsarCreditStatus.cancelled;
      case CreditStatus.overdue:
        return IsarCreditStatus.overdue;
    }
  }

  /// Sincronizar operación de PrinterSettings
  Future<void> _syncPrinterSettingsOperation(SyncOperation operation) async {
    try {
      PrinterSettingsRemoteDataSource remoteDataSource;
      if (Get.isRegistered<PrinterSettingsRemoteDataSource>()) {
        remoteDataSource = Get.find<PrinterSettingsRemoteDataSource>();
      } else {
        remoteDataSource = PrinterSettingsRemoteDataSourceImpl(
          dioClient: Get.find<DioClient>(),
        );
      }
      final data = jsonDecode(operation.payload);

      // Limpiar campos que el backend no acepta
      data.remove('isActive');

      switch (operation.operationType) {
        case SyncOperationType.create:
          AppLogger.d(
            'Creando impresora en servidor: ${data['name']}',
            tag: 'SYNC',
          );

          final createdPrinter = await remoteDataSource.createPrinterSetting(data);
          AppLogger.i(
            'Impresora creada en servidor con ID: ${createdPrinter.id}',
            tag: 'SYNC',
          );

          // Actualizar ISAR con el ID real del servidor
          final _uuidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
          if (!_uuidPattern.hasMatch(operation.entityId)) {
            try {
              final isar = IsarDatabase.instance.database;
              final isarPrinter = await isar.printerSettingsModels
                  .filter()
                  .serverIdEqualTo(operation.entityId)
                  .findFirst();

              if (isarPrinter != null) {
                isarPrinter.serverId = createdPrinter.id;
                isarPrinter.markAsSynced();
                await isar.writeTxn(() async {
                  await isar.printerSettingsModels.put(isarPrinter);
                });
                AppLogger.i(
                  'ISAR impresora actualizada: ${operation.entityId} -> ${createdPrinter.id}',
                  tag: 'SYNC',
                );
              }

              // Limpiar operaciones UPDATE obsoletas
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId &&
                    op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                }
              }
            } catch (e) {
              AppLogger.w('Error actualizando impresora en ISAR: $e', tag: 'SYNC');
            }
          }
          break;

        case SyncOperationType.update:
          AppLogger.d(
            'Actualizando impresora en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.updatePrinterSetting(operation.entityId, data);
          AppLogger.i('Impresora actualizada en servidor', tag: 'SYNC');
          break;

        case SyncOperationType.delete:
          AppLogger.d(
            'Eliminando impresora en servidor: ${operation.entityId}',
            tag: 'SYNC',
          );
          await remoteDataSource.deletePrinterSetting(operation.entityId);
          AppLogger.i('Impresora eliminada en servidor', tag: 'SYNC');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        AppLogger.w(
          'Impresora ya existe en servidor - marcando como completado',
          tag: 'SYNC',
        );
        return;
      }
      rethrow;
    }
  }

  /// Normaliza un teléfono al formato colombiano +57XXXXXXXXXX
  String? _normalizeColombianPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final cleaned = phone.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleaned.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return phone.trim();
    if (cleaned.startsWith('57') && cleaned.length == 12) {
      return '+$cleaned';
    }
    if (cleaned.length == 10) {
      return '+57$cleaned';
    }
    return phone.trim();
  }
}
