// lib/app/data/local/full_sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'isar_database.dart';
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
import '../../../features/subscriptions/data/models/isar/isar_subscription.dart';
import '../../../features/inventory/data/models/inventory_batch_model.dart';
import '../../../features/inventory/domain/repositories/inventory_repository.dart';

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

  // Tiers de sincronización paralela (por dependencias)
  // Tier 1: Entidades base sin dependencias
  // Tier 2: Entidades que dependen de categorías
  // Tier 3: Entidades transaccionales
  // Tier 4: Entidades derivadas + notificaciones
  static const List<List<String>> _syncTiers = [
    ['Organización', 'Categorías', 'Categorías de Gastos'],
    ['Productos', 'Clientes', 'Proveedores', 'Cuentas Bancarias', 'Almacenes', 'Impresoras'],
    ['Facturas', 'Gastos', 'Órdenes de Compra'],
    ['Notas de Crédito', 'Créditos de Clientes', 'Lotes de Inventario', 'Movimientos de Inventario', 'Notificaciones'],
  ];

  // Lista plana para progreso UI
  static List<String> get _syncOrder =>
      _syncTiers.expand((tier) => tier).toList();

  FullSyncService(this._database);

  /// Realiza un Full Sync completo con sincronización paralela por tiers
  Future<FullSyncResult> performFullSync() async {
    if (isSyncing.value) {
      print('⚠️ [FULL_SYNC] Ya hay un sync en progreso, ignorando...');
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

    // Inicializar progreso
    for (final entity in allEntities) {
      progress.add(SyncEntityProgress(entityName: entity));
    }

    print('🔄 [FULL_SYNC] Iniciando sincronización paralela por tiers...');

    try {
      // Verificar conectividad
      final networkInfo = Get.find<NetworkInfo>();
      if (!await networkInfo.isConnected) {
        print('📴 [FULL_SYNC] Sin conexión, abortando...');
        return FullSyncResult(
          syncedCounts: {},
          errors: {'general': 'Sin conexión a internet'},
          duration: stopwatch.elapsed,
          wasAborted: true,
        );
      }

      // Limpiar datos del tenant anterior SELECTIVAMENTE
      // NUNCA borrar: syncOperations, idempotencyRecords, printerSettings no sincronizados
      try {
        print('🧹 [FULL_SYNC] Limpiando datos del tenant anterior (selectivo)...');
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
          await _isar.isarPurchaseOrderItems.clear();
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
            print('🔒 [FULL_SYNC] ${unsyncedPrinters.length} impresora(s) no sincronizada(s) preservada(s)');
          }
          // NUNCA tocar: syncOperations ni isarIdempotencyRecords
        });
        print('✅ [FULL_SYNC] Datos anteriores limpiados (sync queue preservada)');
      } catch (e) {
        print('⚠️ [FULL_SYNC] Error limpiando ISAR (continuando sync): $e');
      }

      final syncFunctions = <String, Future<int> Function()>{
        'Organización': _syncOrganization,
        'Categorías': _syncCategories,
        'Categorías de Gastos': _syncExpenseCategories,
        'Productos': _syncProducts,
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

      int completedCount = 0;

      // Procesar tier por tier, dentro de cada tier en PARALELO
      for (int tierIdx = 0; tierIdx < _syncTiers.length; tierIdx++) {
        if (_abortRequested) {
          print('🛑 [FULL_SYNC] Sync abortado por el usuario');
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
        print('⚡ [FULL_SYNC] Tier ${tierIdx + 1}: sincronizando ${tier.join(", ")} en paralelo...');

        // Lanzar TODAS las entidades del tier en paralelo con timeout individual
        final futures = <Future<MapEntry<String, int?>>>[];
        for (final entityName in tier) {
          futures.add(
            _syncEntitySafe(entityName, syncFunctions[entityName]!)
                .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                print('⏱️ [FULL_SYNC] Timeout sincronizando $entityName (60s)');
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
                print('✅ [FULL_SYNC] ${result.key}: ${result.value} registros');
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
      }

      overallProgress.value = 1.0;
      _lastFullSyncAt = DateTime.now();

      // Limpiar registros huérfanos de TODAS las entidades (con timeout)
      currentEntity.value = 'Limpiando datos temporales...';
      try {
        await _cleanupOrphanedRecords().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('⏱️ [FULL_SYNC] Cleanup timeout (30s), continuando...');
          },
        );
      } catch (e) {
        print('⚠️ [FULL_SYNC] Error en cleanup (no crítico): $e');
      }

      stopwatch.stop();
      final result = FullSyncResult(
        syncedCounts: syncedCounts,
        errors: errors,
        duration: stopwatch.elapsed,
      );

      print('🏁 [FULL_SYNC] Sincronización completada en ${stopwatch.elapsed.inSeconds}s: $result');
      return result;
    } catch (e) {
      stopwatch.stop();
      print('💥 [FULL_SYNC] Error fatal: $e');
      return FullSyncResult(
        syncedCounts: syncedCounts,
        errors: {...errors, 'fatal': e.toString()},
        duration: stopwatch.elapsed,
      );
    } finally {
      isSyncing.value = false;
      currentEntity.value = '';
    }
  }

  /// Ejecuta sync de una entidad individual capturando errores
  Future<MapEntry<String, int?>> _syncEntitySafe(
    String entityName,
    Future<int> Function() syncFn,
  ) async {
    try {
      final count = await syncFn();
      return MapEntry(entityName, count);
    } catch (e) {
      print('❌ [FULL_SYNC] Error sincronizando $entityName: $e');
      return MapEntry(entityName, null);
    }
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
    await offlineRepo.cacheOrganization(orgModel);

    return 1;
  }

  /// Sincronizar categorías del server a ISAR
  Future<int> _syncCategories() async {
    final remoteDS = Get.find<CategoryRemoteDataSource>();
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
      final response = await remoteDS.getCategories(
        CategoryQueryModel(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarCategory.fromModel(model);
        }).toList();
        await _isar.isarCategorys.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar categorías de gastos del server a SecureStorage (vía ExpenseLocalDataSource)
  Future<int> _syncExpenseCategories() async {
    final remoteDS = Get.find<ExpenseRemoteDataSource>();
    final localDS = Get.find<ExpenseLocalDataSource>();
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;
    final allCategories = <dynamic>[];

    while (hasMore && !_abortRequested) {
      final response = await remoteDS.getExpenseCategories(
        page: page,
        limit: _pageSize,
      );

      if (response.data.isEmpty) break;

      allCategories.addAll(response.data);
      totalSynced += response.data.length;
      hasMore = response.meta?.hasNextPage ?? false;
      page++;
    }

    // Cachear todas las categorías de una vez
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
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
      final response = await remoteDS.getProducts(
        ProductQueryModel(page: page, limit: _pageSize, includePrices: true, includeCategory: true),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarProduct.fromModel(model);
        }).toList();
        await _isar.isarProducts.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar clientes del server a ISAR
  Future<int> _syncCustomers() async {
    final remoteDS = _getOrCreateDS<CustomerRemoteDataSource>(
      () => CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
      final response = await remoteDS.getCustomers(
        CustomerQueryModel(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarCustomer.fromModel(model);
        }).toList();
        await _isar.isarCustomers.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar proveedores del server a ISAR
  Future<int> _syncSuppliers() async {
    final remoteDS = _getOrCreateDS<SupplierRemoteDataSource>(
      () => SupplierRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
      final response = await remoteDS.getSuppliers(
        SupplierQueryParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarSupplier.fromModel(model);
        }).toList();
        await _isar.isarSuppliers.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar facturas del server a ISAR
  Future<int> _syncInvoices() async {
    final remoteDS = _getOrCreateDS<InvoiceRemoteDataSource>(
      () => InvoiceRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
      final response = await remoteDS.getInvoices(
        InvoiceQueryParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarInvoice.fromModel(model);
        }).toList();
        await _isar.isarInvoices.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar gastos del server a ISAR
  Future<int> _syncExpenses() async {
    final remoteDS = Get.find<ExpenseRemoteDataSource>();
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
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
        await _isar.isarExpenses.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      hasMore = response.meta.hasNextPage;
      page++;
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
      await _isar.isarBankAccounts.putAllByServerId(isarModels);
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
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
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
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar notas de crédito del server a ISAR
  Future<int> _syncCreditNotes() async {
    final remoteDS = _getOrCreateDS<CreditNoteRemoteDataSource>(
      () => CreditNoteRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
      final response = await remoteDS.getCreditNotes(
        QueryCreditNotesParams(page: page, limit: _pageSize),
      );

      if (response.data.isEmpty) break;

      await _isar.writeTxn(() async {
        final isarModels = response.data.map((model) {
          return IsarCreditNote.fromModel(model);
        }).toList();
        await _isar.isarCreditNotes.putAllByServerId(isarModels);
      });

      totalSynced += response.data.length;
      // CreditNotePaginatedResponseModel.meta es Map<String, dynamic>
      final totalPages = response.meta['totalPages'] as int? ?? 1;
      final hasNextPage = response.meta['hasNextPage'] as bool?;
      // Usar hasNextPage si disponible, sino calcular desde totalPages
      hasMore = hasNextPage ?? (page < totalPages);
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar créditos de clientes del server a ISAR (no paginado)
  Future<int> _syncCustomerCredits() async {
    final remoteDS = _getOrCreateDS<CustomerCreditRemoteDataSource>(
      () => CustomerCreditRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    // getCredits retorna List<CustomerCreditModel> sin paginación
    final credits = await remoteDS.getCredits(null);

    if (credits.isEmpty) return 0;

    await _isar.writeTxn(() async {
      final isarModels = credits.map((credit) {
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
      }).toList();
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
    int page = 1;

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
        op.entityType == 'purchase_order');

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
    while (!_abortRequested) {
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
      page++;
    }

    if (skippedUnsync > 0) {
      print('⚠️ [FULL_SYNC] Batches: $skippedUnsync omitidos (cambios locales sin sincronizar)');
    }

    return totalSynced;
  }

  /// Sincronizar movimientos de inventario del server a ISAR
  Future<int> _syncInventoryMovements() async {
    final remoteDS = _getOrCreateDS<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
    );
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
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
      page++;
    }

    return totalSynced;
  }

  /// Sincronizar notificaciones del server a ISAR
  Future<int> _syncNotifications() async {
    final remoteDS = _getOrCreateDS<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
    );
    int totalSynced = 0;
    int page = 1;
    bool hasMore = true;

    while (hasMore && !_abortRequested) {
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
      page++;
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
      print('⚠️ FullSync: SharedPreferences falló para warehouses (memory cache OK): $e');
    }

    return warehouseModels.length;
  }

  // ==================== CLEANUP ====================

  /// Limpia registros ISAR huérfanos con IDs temporales de TODAS las entidades.
  /// Estos son registros creados offline cuyo sync handler antiguo no actualizó
  /// el serverId con el ID real del servidor después de crear exitosamente.
  Future<void> _cleanupOrphanedRecords() async {
    try {
      print('🧹 [FULL_SYNC] Limpiando registros huérfanos...');
      final isarDb = IsarDatabase.instance;

      // Obtener TODAS las operaciones de sync pendientes para no borrar records activos
      final allPendingOps = await isarDb.getPendingSyncOperations();
      final pendingEntityIds = allPendingOps.map((op) => op.entityId).toSet();

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

      // Customer Credits: prefix 'customercredit_offline_'
      totalCleaned += await _cleanupEntity<IsarCustomerCredit>(
        collection: _isar.isarCustomerCredits,
        prefix: 'customercredit_offline_',
        pendingIds: pendingEntityIds,
        getServerId: (e) => e.serverId,
        getId: (e) => e.id,
      );

      if (totalCleaned > 0) {
        print('🧹 [FULL_SYNC] Total registros huérfanos limpiados: $totalCleaned');
      } else {
        print('✅ [FULL_SYNC] No hay registros huérfanos para limpiar');
      }
    } catch (e) {
      print('⚠️ [FULL_SYNC] Error en limpieza de huérfanos: $e');
    }
  }

  /// Limpia batches offline huérfanos con manejo especial para POs pendientes.
  /// No borra batches cuyo purchaseOrderId corresponda a un PO aún en cola de sync.
  Future<int> _cleanupBatchOfflineRecords(Set<String> pendingEntityIds) async {
    try {
      final allBatches = await _isar.isarInventoryBatchs.where().findAll();
      final offlineBatches = allBatches
          .where((b) => b.serverId.startsWith('batch_offline_'))
          .toList();

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

      print(
          '  🧹 IsarInventoryBatch: ${toDelete.length} batch_offline_ huérfanos eliminados');
      return toDelete.length;
    } catch (e) {
      print('  ⚠️ Error limpiando IsarInventoryBatch batch_offline_: $e');
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
      final allRecords = await collection.where().findAll();
      final orphaned = allRecords
          .where((r) => getServerId(r).startsWith(prefix))
          .where((r) => !pendingIds.contains(getServerId(r)))
          .toList();

      if (orphaned.isEmpty) return 0;

      await _isar.writeTxn(() async {
        await collection.deleteAll(orphaned.map(getId).toList());
      });

      print('  🧹 ${T.toString()}: ${orphaned.length} huérfanos eliminados');
      return orphaned.length;
    } catch (e) {
      print('  ⚠️ Error limpiando ${T.toString()}: $e');
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
