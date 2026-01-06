import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'isar_database.dart';
import 'sync_queue.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../core/errors/exceptions.dart';

// Products
import '../../../features/products/data/datasources/product_remote_datasource.dart';
import '../../../features/products/data/models/create_product_request_model.dart';
import '../../../features/products/data/models/update_product_request_model.dart';
import '../../../features/products/data/repositories/product_offline_repository.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../features/products/domain/entities/product_price.dart';
import '../../../features/products/domain/entities/tax_enums.dart';
import '../../../features/products/domain/repositories/product_repository.dart' show CreateProductPriceParams;

// Categories
import '../../../features/categories/data/datasources/category_remote_datasource.dart';
import '../../../features/categories/data/models/create_category_request_model.dart';
import '../../../features/categories/data/models/update_category_request_model.dart';
import '../../../features/categories/domain/entities/category.dart';

// Customers
import '../../../features/customers/data/datasources/customer_remote_datasource.dart';
import '../../../features/customers/data/models/create_customer_request_model.dart';
import '../../../features/customers/data/models/update_customer_request_model.dart';

// Suppliers
import '../../../features/suppliers/data/datasources/supplier_remote_datasource.dart';
import '../../../features/suppliers/data/models/create_supplier_request_model.dart';
import '../../../features/suppliers/data/models/update_supplier_request_model.dart';

// Expenses
import '../../../features/expenses/data/datasources/expense_remote_datasource.dart';
import '../../../features/expenses/data/models/create_expense_request_model.dart';
import '../../../features/expenses/data/models/update_expense_request_model.dart';
import '../../../features/expenses/domain/entities/expense.dart';

// Bank Accounts
import '../../../features/bank_accounts/data/datasources/bank_account_remote_datasource.dart';
import '../../../features/bank_accounts/data/models/bank_account_model.dart';

// Invoices
import '../../../features/invoices/data/datasources/invoice_remote_datasource.dart';
import '../../../features/invoices/data/models/create_invoice_request_model.dart';
import '../../../features/invoices/data/models/update_invoice_request_model.dart';
import '../../../features/invoices/data/models/invoice_item_model.dart';

// Purchase Orders
import '../../../features/purchase_orders/data/datasources/purchase_order_remote_datasource.dart';
import '../../../features/purchase_orders/domain/entities/purchase_order.dart';
import '../../../features/purchase_orders/domain/repositories/purchase_order_repository.dart';

// Inventory
import '../../../features/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../../features/inventory/data/models/inventory_movement_model.dart';

// Credit Notes
import '../../../features/credit_notes/data/datasources/credit_note_remote_datasource.dart';
import '../../../features/credit_notes/data/models/credit_note_model.dart';
import '../../../features/credit_notes/data/models/credit_note_item_model.dart';

// Customer Credits
import '../../../features/customer_credits/data/datasources/customer_credit_remote_datasource.dart';
import '../../../features/customer_credits/data/models/customer_credit_model.dart';

/// Estados de sincronización
enum SyncState {
  idle,        // Sin sincronización en progreso
  syncing,     // Sincronizando actualmente
  error,       // Error en sincronización
}

/// Servicio de sincronización offline-first
///
/// Responsabilidades:
/// - Detectar cambios de conectividad (WiFi, Mobile Data, None)
/// - Sincronizar automáticamente cuando vuelve internet
/// - Trackear estado de sincronización
/// - Proveer métodos para sincronización manual
class SyncService extends GetxService {
  final dynamic _isarDatabase; // Use dynamic to support both IsarDatabase and MockIsarDatabase
  final Connectivity _connectivity = Connectivity();

  // Estado de conectividad
  final Rx<bool> _isOnline = false.obs;
  bool get isOnline => _isOnline.value;

  // Estado de sincronización
  final Rx<SyncState> _syncState = SyncState.idle.obs;
  SyncState get syncState => _syncState.value;

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

  SyncService(this._isarDatabase);

  @override
  Future<void> onInit() async {
    super.onInit();
    print('🔄 Inicializando SyncService...');

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

    // Configurar sincronización periódica (cada 5 minutos si hay internet)
    _setupPeriodicSync();

    print('✅ SyncService inicializado');
    print('📡 Estado inicial: ${isOnline ? "Online" : "Offline"}');
    print('⏳ Operaciones pendientes: $pendingOperationsCount');
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
    super.onClose();
    print('🔄 SyncService cerrado');
  }

  /// Verificar conectividad actual
  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasOnline = _isOnline.value;
      _isOnline.value = _hasInternetConnection(results);

      // Si cambia de offline a online, sincronizar
      if (!wasOnline && _isOnline.value) {
        print('🌐 Conectividad restaurada');
        await syncAll();
      } else if (wasOnline && !_isOnline.value) {
        print('📡 Conectividad perdida');
      }
    } catch (e) {
      print('❌ Error verificando conectividad: $e');
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
          print('🌐 Conectividad restaurada: $results');
          await syncAll();
        } else if (wasOnline && !_isOnline.value) {
          print('📡 Conectividad perdida: $results');
        }
      },
      onError: (error) {
        print('❌ Error en stream de conectividad: $error');
      },
    );
  }

  /// Verificar si hay conexión a internet
  bool _hasInternetConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
  }

  /// Configurar sincronización periódica
  /// - Si hay operaciones pendientes: cada 30 segundos (agresivo)
  /// - Si NO hay operaciones pendientes: cada 5 minutos (normal)
  void _setupPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(
      const Duration(seconds: 30), // Verificar cada 30 segundos
      (timer) async {
        if (_isOnline.value && _pendingOperationsCount.value > 0) {
          print('⏰ Sincronización automática iniciada (${_pendingOperationsCount.value} operaciones pendientes)');
          await syncAll();
        }
      },
    );
  }

  /// Actualizar conteo de operaciones pendientes
  Future<void> _updatePendingCount() async {
    try {
      final pending = await _isarDatabase.getPendingSyncOperations();
      _pendingOperationsCount.value = pending.length;
    } catch (e) {
      print('❌ Error actualizando conteo pendientes: $e');
    }
  }

  /// Sincronizar todas las operaciones pendientes
  Future<void> syncAll() async {
    if (!_isOnline.value) {
      print('⚠️ Sin conexión, no se puede sincronizar');
      return;
    }

    if (_syncState.value == SyncState.syncing) {
      print('⚠️ Sincronización ya en progreso');
      return;
    }

    try {
      _syncState.value = SyncState.syncing;
      print('🔄 Iniciando sincronización...');

      final operations = await _isarDatabase.getPendingSyncOperations();

      if (operations.isEmpty) {
        print('✅ No hay operaciones pendientes');
        _syncState.value = SyncState.idle;
        return;
      }

      // ✅ LIMPIAR AUTOMÁTICAMENTE OPERACIONES DUPLICADAS
      // Elimina UPDATE si existe CREATE para la misma entidad
      await _cleanupDuplicateOperations(operations);

      // Recargar operaciones después de limpieza
      final cleanedOperations = await _isarDatabase.getPendingSyncOperations();

      if (cleanedOperations.isEmpty) {
        print('✅ No hay operaciones pendientes después de limpieza');
        _syncState.value = SyncState.idle;
        return;
      }

      // ✅ ORDENAR OPERACIONES POR DEPENDENCIAS
      // Categories primero, luego Products, luego el resto
      final sortedOperations = _sortOperationsByDependencies(cleanedOperations);

      print('📤 Sincronizando ${sortedOperations.length} operaciones (ordenadas por dependencias)...');

      int successCount = 0;
      int failureCount = 0;

      for (final operation in sortedOperations) {
        try {
          print('🔄 Sincronizando: ${operation.entityType} ${operation.operationType.name} (ID: ${operation.entityId})');

          // Sincronizar según el tipo de entidad
          switch (operation.entityType) {
            case 'Product':
              await _syncProductOperation(operation);
              break;
            case 'Category':
              await _syncCategoryOperation(operation);
              break;
            case 'Customer':
              await _syncCustomerOperation(operation);
              break;
            case 'Supplier':
              await _syncSupplierOperation(operation);
              break;
            case 'Expense':
              await _syncExpenseOperation(operation);
              break;
            case 'BankAccount':
              await _syncBankAccountOperation(operation);
              break;
            case 'Invoice':
              await _syncInvoiceOperation(operation);
              break;
            case 'PurchaseOrder':
              await _syncPurchaseOrderOperation(operation);
              break;
            case 'InventoryMovement':
              await _syncInventoryMovementOperation(operation);
              break;
            case 'CreditNote':
              await _syncCreditNoteOperation(operation);
              break;
            case 'CustomerCredit':
              await _syncCustomerCreditOperation(operation);
              break;
            default:
              print('⚠️ Tipo de entidad no soportado para sync: ${operation.entityType}');
              throw Exception('Tipo de entidad no soportado: ${operation.entityType}');
          }

          await _isarDatabase.markSyncOperationCompleted(operation.id);
          successCount++;

          print('✅ Sincronizada: ${operation.entityType} ${operation.operationType.name}');
        } catch (e) {
          await _isarDatabase.markSyncOperationFailed(
            operation.id,
            e.toString(),
          );
          failureCount++;

          // Solo mostrar mensaje limpio si es error de conexión
          if (e.toString().contains('Connection refused') ||
              e.toString().contains('Connection error') ||
              e.toString().contains('Error de conexión') ||
              e.toString().contains('SocketException')) {
            print('⏸️ ${operation.entityType} pendiente - backend no disponible');
          }
        }
      }

      _lastSyncTime.value = DateTime.now();
      await _updatePendingCount();

      if (successCount > 0 || failureCount > 0) {
        print('📊 Sincronización completada:');
        if (successCount > 0) {
          print('   ✅ Sincronizadas: $successCount');
        }
        if (failureCount > 0) {
          print('   ⏸️ Pendientes: $failureCount (se reintentarán cuando el backend esté disponible)');
        }
      }

      _syncState.value = SyncState.idle;
    } catch (e) {
      print('❌ Error en sincronización: $e');
      _syncState.value = SyncState.error;
      await _updatePendingCount();
    }
  }

  /// ✅ LIMPIAR OPERACIONES DUPLICADAS AUTOMÁTICAMENTE
  /// Elimina operaciones UPDATE si existe CREATE para la misma entidad
  Future<void> _cleanupDuplicateOperations(List<SyncOperation> operations) async {
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
        final hasCreate = entityOps.any((op) => op.operationType == SyncOperationType.create);
        final updateOps = entityOps.where((op) => op.operationType == SyncOperationType.update).toList();

        if (hasCreate && updateOps.isNotEmpty) {
          // Hay CREATE pendiente, eliminar todas las operaciones UPDATE
          for (final updateOp in updateOps) {
            toDelete.add(updateOp.id);
            print('🧹 Limpiando operación UPDATE duplicada: ${updateOp.entityType} ${updateOp.entityId} (CREATE ya existe)');
          }
        }
      }

      // Eliminar operaciones duplicadas usando el método de IsarDatabase
      if (toDelete.isNotEmpty) {
        for (final id in toDelete) {
          await _isarDatabase.deleteSyncOperation(id);
        }
        print('✅ ${toDelete.length} operaciones duplicadas eliminadas automáticamente');
      }
    } catch (e) {
      print('⚠️ Error limpiando operaciones duplicadas: $e');
    }
  }

  /// ✅ ORDENAR OPERACIONES POR DEPENDENCIAS
  /// - Categories primero (CREATE antes que UPDATE/DELETE)
  /// - Products después (dependen de Categories)
  /// - Customers después
  /// - Otros tipos al final
  List<SyncOperation> _sortOperationsByDependencies(List<SyncOperation> operations) {
    // Definir orden de prioridad por tipo de entidad
    final priorityOrder = {
      'Category': 1,    // Primero: Categories
      'Product': 2,     // Segundo: Products (dependen de categories)
      'Customer': 3,    // Tercero: Customers
      'Expense': 4,     // Cuarto: Expenses
    };

    // Definir orden de prioridad por tipo de operación
    final operationOrder = {
      SyncOperationType.create: 1,  // CREATE primero
      SyncOperationType.update: 2,  // UPDATE segundo
      SyncOperationType.delete: 3,  // DELETE al final
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
      print('🔄 Orden de sincronización:');
      for (var i = 0; i < sorted.length; i++) {
        print('   ${i + 1}. ${sorted[i].entityType} ${sorted[i].operationType.name} (ID: ${sorted[i].entityId})');
      }
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
    try {
      final operation = SyncOperation.create(
        entityType: entityType,
        entityId: entityId,
        operationType: operationType,
        payload: jsonEncode(data), // Serializar correctamente a JSON
        organizationId: organizationId,
        priority: priority,
      );

      await _isarDatabase.addSyncOperation(operation);
      await _updatePendingCount();

      print('➕ Operación agregada a cola: $entityType ${operationType.name}');

      // Intentar sincronizar inmediatamente (de forma silenciosa)
      // Si falla, quedará en la cola para reintentarse
      syncAll();
    } catch (e) {
      print('❌ Error agregando operación a cola: $e');
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
        throw Exception('No hay usuario autenticado para agregar operación de sincronización');
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
      print('❌ Error agregando operación para usuario actual: $e');
      rethrow;
    }
  }

  /// Forzar sincronización manual
  Future<void> forceSyncNow() async {
    print('🔄 Sincronización manual forzada');
    await syncAll();
  }

  /// Limpiar operaciones antiguas completadas
  Future<void> cleanOldOperations() async {
    try {
      await _isarDatabase.cleanOldSyncOperations();
      await _updatePendingCount();
    } catch (e) {
      print('❌ Error limpiando operaciones antiguas: $e');
    }
  }

  /// Obtener estadísticas de sincronización
  Future<Map<String, int>> getSyncStats() async {
    return await _isarDatabase.getSyncOperationsCounts();
  }

  /// Reanudar sincronización de operaciones fallidas
  Future<void> retryFailedOperations() async {
    if (!_isOnline.value) {
      print('⚠️ Sin conexión, no se puede reintentar');
      return;
    }

    print('🔄 Reintentando operaciones fallidas...');

    // TODO: Implementar lógica para marcar operaciones fallidas como pending
    // y luego llamar a syncAll()

    await syncAll();
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
      print('✅ Operación de sync eliminada correctamente');
    } catch (e) {
      print('❌ Error eliminando operación de sync: $e');
    }
  }

  /// Eliminar todas las operaciones de sync para un entityId específico
  Future<void> deleteSyncOperationsByEntityId(String entityId) async {
    try {
      await _isarDatabase.deleteSyncOperationsByEntityId(entityId);
      await _updatePendingCount();
      print('✅ Operaciones de sync eliminadas correctamente para entityId: $entityId');
    } catch (e) {
      print('❌ Error eliminando operaciones de sync: $e');
    }
  }

  /// 🧹 Limpiar operaciones con referencias offline inválidas
  /// Este método detecta y elimina operaciones de productos que referencian
  /// categorías offline que no tienen operación de sync pendiente (huérfanas)
  Future<void> _cleanInvalidOfflineReferences() async {
    try {
      print('🧹 Verificando referencias offline inválidas...');

      final operations = await _isarDatabase.getPendingSyncOperations();

      // Obtener todas las operaciones de categorías pendientes
      final categoryOperations = operations
          .where((op) => op.entityType == 'Category')
          .map((op) => op.entityId)
          .toSet();

      int cleaned = 0;

      // Revisar operaciones de productos
      for (final operation in operations.where((op) => op.entityType == 'Product')) {
        try {
          final data = jsonDecode(operation.payload);
          final categoryId = data['categoryId'] as String?;

          // Si el producto referencia una categoría offline...
          if (categoryId != null && categoryId.startsWith('category_offline_')) {
            // ...y esa categoría NO tiene operación de sync pendiente...
            if (!categoryOperations.contains(categoryId)) {
              print('🗑️ Eliminando producto huérfano: ${data['name']} (SKU: ${data['sku']})');
              print('   └─ Categoría offline inexistente: $categoryId');

              await _isarDatabase.deleteSyncOperation(operation.id);
              cleaned++;
            }
          }
        } catch (e) {
          print('⚠️ Error procesando operación ${operation.id}: $e');
        }
      }

      if (cleaned > 0) {
        await _updatePendingCount();
        print('✅ Limpiadas $cleaned operaciones con referencias inválidas');
      } else {
        print('✅ No se encontraron referencias inválidas');
      }
    } catch (e) {
      print('❌ Error en limpieza automática: $e');
    }
  }

  /// Limpieza one-time: Eliminar operación rota ID 9
  /// Esta operación intenta UPDATE de un producto offline que ya fue creado en el servidor
  Future<void> _cleanupBrokenOperation9() async {
    try {
      print('🗑️ Verificando operación ID 9...');

      final operation = await _isarDatabase.database.syncOperations.get(9);

      if (operation != null) {
        print('⚠️ Operación rota encontrada:');
        print('   Entity: ${operation.entityType} (${operation.entityId})');
        print('   Operation: ${operation.operationType.name}');
        print('   Status: ${operation.status.name}');

        // Verificar que es el producto offline específico que ya fue creado
        if (operation.entityId == 'product_offline_1766860497475_711632557' &&
            operation.operationType == SyncOperationType.update) {
          print('🗑️ Eliminando operación rota (producto ya fue creado en servidor)...');
          await _isarDatabase.deleteSyncOperation(9);
          await _updatePendingCount();
          print('✅ Operación ID 9 eliminada exitosamente');
        } else {
          print('⚠️ Operación ID 9 existe pero no coincide con el patrón esperado');
        }
      } else {
        print('✅ Operación ID 9 no existe (ya fue limpiada o no hay nada que limpiar)');
      }
    } catch (e) {
      print('❌ Error limpiando operación ID 9: $e');
    }
  }

  // ==================== MÉTODOS DE SINCRONIZACIÓN POR ENTIDAD ====================

  /// Sincronizar operación de Product
  Future<void> _syncProductOperation(SyncOperation operation) async {
    try {
      // Importar dinámicamente el datasource de productos
      final ProductRemoteDataSource remoteDataSource = Get.find<ProductRemoteDataSource>();

      // Parsear payload como JSON
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando producto en servidor: ${data['name']}');

          // ✅ IMPORTANTE: Si es producto offline, leer datos ACTUALES de ISAR
          // Los datos del payload pueden estar desactualizados si el usuario editó el producto
          Map<String, dynamic> finalData = data;

          if (operation.entityId.startsWith('product_offline_')) {
            print('🔄 Producto offline detectado - leyendo datos actuales de ISAR');
            try {
              // Obtener producto actual de ISAR usando el repositorio offline
              final offlineRepo = Get.find<ProductOfflineRepository>();
              final productResult = await offlineRepo.getProductById(operation.entityId);

              productResult.fold(
                (failure) {
                  print('⚠️ Error obteniendo producto offline: ${failure.toString()} - usando datos del payload');
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
                    'prices': product.prices?.map((p) => {
                      'type': p.type.name,
                      'name': p.name,
                      'amount': p.amount,
                      'currency': p.currency,
                      'discountPercentage': p.discountPercentage,
                      'discountAmount': p.discountAmount,
                      'minQuantity': p.minQuantity,
                      'notes': p.notes,
                    }).toList(),
                  };
                  print('✅ Datos actuales obtenidos de ISAR - ${product.prices?.length ?? 0} precios');
                },
              );
            } catch (e) {
              print('⚠️ Error leyendo producto de ISAR: $e - usando datos del payload');
            }
          }

          // Preparar request de creación
          final request = CreateProductRequestModel.fromParams(
            name: finalData['name'],
            description: finalData['description'],
            sku: finalData['sku'],
            barcode: finalData['barcode'],
            type: finalData['type'] != null ? ProductType.values.firstWhere((e) => e.name == finalData['type']) : null,
            status: finalData['status'] != null ? ProductStatus.values.firstWhere((e) => e.name == finalData['status']) : null,
            stock: finalData['stock']?.toDouble(),
            minStock: finalData['minStock']?.toDouble(),
            unit: finalData['unit'],
            weight: finalData['weight']?.toDouble(),
            length: finalData['length']?.toDouble(),
            width: finalData['width']?.toDouble(),
            height: finalData['height']?.toDouble(),
            images: finalData['images'] != null ? List<String>.from(finalData['images']) : null,
            metadata: finalData['metadata'],
            categoryId: finalData['categoryId'],
            prices: finalData['prices'] != null
              ? (finalData['prices'] as List).map<CreateProductPriceParams>((p) => CreateProductPriceParams(
                  type: PriceType.values.firstWhere((e) => e.name == p['type']),
                  name: p['name'],
                  amount: (p['amount'] as num).toDouble(),
                  currency: p['currency'],
                  discountPercentage: p['discountPercentage'] != null ? (p['discountPercentage'] as num).toDouble() : null,
                  discountAmount: p['discountAmount'] != null ? (p['discountAmount'] as num).toDouble() : null,
                  minQuantity: p['minQuantity'] != null ? (p['minQuantity'] as num).toDouble() : null,
                  notes: p['notes'],
                )).toList()
              : null,
            taxCategory: finalData['taxCategory'] != null ? TaxCategory.values.firstWhere((e) => e.name == finalData['taxCategory']) : null,
            taxRate: finalData['taxRate']?.toDouble(),
            isTaxable: finalData['isTaxable'],
            taxDescription: finalData['taxDescription'],
            retentionCategory: finalData['retentionCategory'] != null ? RetentionCategory.values.firstWhere((e) => e.name == finalData['retentionCategory']) : null,
            retentionRate: finalData['retentionRate']?.toDouble(),
            hasRetention: finalData['hasRetention'],
          );

          final createdProduct = await remoteDataSource.createProduct(request);
          print('✅ Producto creado en servidor exitosamente con ID: ${createdProduct.id}');

          // ✅ AUTOMATIZACIÓN: Actualizar producto offline en ISAR con el nuevo ID del servidor
          if (operation.entityId.startsWith('product_offline_')) {
            try {
              print('🔄 Actualizando producto offline en ISAR con nuevo ID del servidor...');

              // Eliminar operaciones UPDATE obsoletas para este producto offline
              final pendingOps = await _isarDatabase.getPendingSyncOperations();
              for (final op in pendingOps) {
                if (op.entityId == operation.entityId && op.operationType == SyncOperationType.update) {
                  await _isarDatabase.deleteSyncOperation(op.id);
                  print('✅ Operación UPDATE obsoleta eliminada para ${operation.entityId}');
                }
              }

              print('✅ Producto offline sincronizado: ${operation.entityId} → ${createdProduct.id}');
              print('   El producto será actualizado automáticamente en ISAR cuando se cachee del servidor');
            } catch (e) {
              print('⚠️ Error limpiando operaciones obsoletas: $e');
              // No hacer rethrow - la creación fue exitosa, este es solo cleanup
            }
          }
          break;

        case SyncOperationType.update:
          print('📤 Actualizando producto en servidor: ${operation.entityId}');

          // Preparar request de actualización
          final updateRequest = UpdateProductRequestModel.fromParams(
            name: data['name'],
            description: data['description'],
            sku: data['sku'],
            barcode: data['barcode'],
            type: data['type'] != null ? ProductType.values.firstWhere((e) => e.name == data['type']) : null,
            status: data['status'] != null ? ProductStatus.values.firstWhere((e) => e.name == data['status']) : null,
            stock: data['stock']?.toDouble(),
            minStock: data['minStock']?.toDouble(),
            unit: data['unit'],
            weight: data['weight']?.toDouble(),
            length: data['length']?.toDouble(),
            width: data['width']?.toDouble(),
            height: data['height']?.toDouble(),
            images: data['images'] != null ? List<String>.from(data['images']) : null,
            metadata: data['metadata'],
            categoryId: data['categoryId'],
            prices: data['prices'] != null
              ? (data['prices'] as List).map((p) => UpdateProductPriceRequestModel(
                  id: p['id'],
                  type: p['type'],
                  name: p['name'],
                  amount: p['amount'].toDouble(),
                  currency: p['currency'],
                  discountPercentage: p['discountPercentage']?.toDouble(),
                  discountAmount: p['discountAmount']?.toDouble(),
                  minQuantity: p['minQuantity']?.toDouble(),
                  notes: p['notes'],
                )).toList()
              : null,
            taxCategory: data['taxCategory'] != null ? TaxCategory.values.firstWhere((e) => e.name == data['taxCategory']) : null,
            taxRate: data['taxRate']?.toDouble(),
            isTaxable: data['isTaxable'],
            taxDescription: data['taxDescription'],
            retentionCategory: data['retentionCategory'] != null ? RetentionCategory.values.firstWhere((e) => e.name == data['retentionCategory']) : null,
            retentionRate: data['retentionRate']?.toDouble(),
            hasRetention: data['hasRetention'],
          );

          await remoteDataSource.updateProduct(operation.entityId, updateRequest);
          print('✅ Producto actualizado en servidor exitosamente');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando producto en servidor: ${operation.entityId}');
          await remoteDataSource.deleteProduct(operation.entityId);
          print('✅ Producto eliminado en servidor exitosamente');
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
      final CategoryRemoteDataSource remoteDataSource = Get.find<CategoryRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando categoría en servidor: ${data['name']}');
          final request = CreateCategoryRequestModel.fromParams(
            name: data['name'],
            description: data['description'],
            slug: data['slug'],
            image: data['image'],
            status: data['status'] != null ? CategoryStatus.values.firstWhere((e) => e.name == data['status']) : null,
            sortOrder: data['sortOrder'],
            parentId: data['parentId'],
          );
          await remoteDataSource.createCategory(request);
          print('✅ Categoría creada en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando categoría en servidor: ${operation.entityId}');
          final updateRequest = UpdateCategoryRequestModel.fromParams(
            name: data['name'],
            description: data['description'],
            slug: data['slug'],
            image: data['image'],
            status: data['status'] != null ? CategoryStatus.values.firstWhere((e) => e.name == data['status']) : null,
            sortOrder: data['sortOrder'],
            parentId: data['parentId'],
          );
          await remoteDataSource.updateCategory(operation.entityId, updateRequest);
          print('✅ Categoría actualizada en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando categoría en servidor: ${operation.entityId}');
          await remoteDataSource.deleteCategory(operation.entityId);
          print('✅ Categoría eliminada en servidor');
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
      final CustomerRemoteDataSource remoteDataSource = Get.find<CustomerRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando cliente en servidor: ${data['firstName']} ${data['lastName']}');
          final request = CreateCustomerRequestModel.fromParams(
            firstName: data['firstName'],
            lastName: data['lastName'],
            companyName: data['companyName'],
            email: data['email'],
            phone: data['phone'],
            mobile: data['mobile'],
            documentType: data['documentType'],
            documentNumber: data['documentNumber'],
            address: data['address'],
            city: data['city'],
            state: data['state'],
            zipCode: data['zipCode'],
            country: data['country'],
            creditLimit: data['creditLimit']?.toDouble(),
            paymentTerms: data['paymentTerms'],
            notes: data['notes'],
            metadata: data['metadata'],
          );
          await remoteDataSource.createCustomer(request);
          print('✅ Cliente creado en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando cliente en servidor: ${operation.entityId}');
          final updateRequest = UpdateCustomerRequestModel.fromParams(
            firstName: data['firstName'],
            lastName: data['lastName'],
            companyName: data['companyName'],
            email: data['email'],
            phone: data['phone'],
            mobile: data['mobile'],
            documentType: data['documentType'],
            documentNumber: data['documentNumber'],
            address: data['address'],
            city: data['city'],
            state: data['state'],
            zipCode: data['zipCode'],
            country: data['country'],
            creditLimit: data['creditLimit']?.toDouble(),
            paymentTerms: data['paymentTerms'],
            notes: data['notes'],
            metadata: data['metadata'],
          );
          await remoteDataSource.updateCustomer(operation.entityId, updateRequest);
          print('✅ Cliente actualizado en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando cliente en servidor: ${operation.entityId}');
          await remoteDataSource.deleteCustomer(operation.entityId);
          print('✅ Cliente eliminado en servidor');
          break;

        default:
          throw Exception('Operación no soportada: ${operation.operationType}');
      }
    } catch (e) {
      // Detectar errores 409 (Conflict) - Item ya existe en servidor
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Cliente ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de Supplier
  Future<void> _syncSupplierOperation(SyncOperation operation) async {
    try {
      final SupplierRemoteDataSource remoteDataSource = Get.find<SupplierRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando proveedor en servidor: ${data['name']}');
          final request = CreateSupplierRequestModel.fromJson(data);
          await remoteDataSource.createSupplier(request);
          print('✅ Proveedor creado en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando proveedor en servidor: ${operation.entityId}');
          final updateRequest = UpdateSupplierRequestModel.fromJson(data);
          await remoteDataSource.updateSupplier(operation.entityId, updateRequest);
          print('✅ Proveedor actualizado en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando proveedor en servidor: ${operation.entityId}');
          await remoteDataSource.deleteSupplier(operation.entityId);
          print('✅ Proveedor eliminado en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Proveedor ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de Expense
  Future<void> _syncExpenseOperation(SyncOperation operation) async {
    try {
      final ExpenseRemoteDataSource remoteDataSource = Get.find<ExpenseRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando gasto en servidor: ${data['description']}');
          final request = CreateExpenseRequestModel.fromParams(
            description: data['description'],
            amount: (data['amount'] as num).toDouble(),
            date: DateTime.parse(data['date']),
            categoryId: data['categoryId'],
            type: ExpenseType.values.firstWhere((e) => e.name == data['type']),
            paymentMethod: PaymentMethod.values.firstWhere((e) => e.name == data['paymentMethod']),
            vendor: data['vendor'],
            invoiceNumber: data['invoiceNumber'],
            reference: data['reference'],
            notes: data['notes'],
            attachments: data['attachments'] != null ? List<String>.from(data['attachments']) : null,
            tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
            metadata: data['metadata'],
            status: data['status'] != null ? ExpenseStatus.values.firstWhere((e) => e.name == data['status']) : null,
          );
          await remoteDataSource.createExpense(request);
          print('✅ Gasto creado en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando gasto en servidor: ${operation.entityId}');
          final updateRequest = UpdateExpenseRequestModel.fromParams(
            description: data['description'],
            amount: data['amount'] != null ? (data['amount'] as num).toDouble() : null,
            date: data['date'] != null ? DateTime.parse(data['date']) : null,
            categoryId: data['categoryId'],
            type: data['type'] != null ? ExpenseType.values.firstWhere((e) => e.name == data['type']) : null,
            paymentMethod: data['paymentMethod'] != null ? PaymentMethod.values.firstWhere((e) => e.name == data['paymentMethod']) : null,
            vendor: data['vendor'],
            invoiceNumber: data['invoiceNumber'],
            reference: data['reference'],
            notes: data['notes'],
            attachments: data['attachments'] != null ? List<String>.from(data['attachments']) : null,
            tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
            metadata: data['metadata'],
          );
          await remoteDataSource.updateExpense(operation.entityId, updateRequest);
          print('✅ Gasto actualizado en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando gasto en servidor: ${operation.entityId}');
          await remoteDataSource.deleteExpense(operation.entityId);
          print('✅ Gasto eliminado en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Gasto ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de BankAccount
  Future<void> _syncBankAccountOperation(SyncOperation operation) async {
    try {
      final BankAccountRemoteDataSource remoteDataSource = Get.find<BankAccountRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando cuenta bancaria en servidor: ${data['name']}');
          final request = CreateBankAccountRequest(
            name: data['name'],
            type: data['type'],
            bankName: data['bankName'],
            accountNumber: data['accountNumber'],
            holderName: data['holderName'],
            icon: data['icon'],
            isActive: data['isActive'] ?? true,
            isDefault: data['isDefault'] ?? false,
            sortOrder: data['sortOrder'] ?? 0,
            description: data['description'],
          );
          await remoteDataSource.createBankAccount(request);
          print('✅ Cuenta bancaria creada en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando cuenta bancaria en servidor: ${operation.entityId}');
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
          await remoteDataSource.updateBankAccount(operation.entityId, updateRequest);
          print('✅ Cuenta bancaria actualizada en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando cuenta bancaria en servidor: ${operation.entityId}');
          await remoteDataSource.deleteBankAccount(operation.entityId);
          print('✅ Cuenta bancaria eliminada en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Cuenta bancaria ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de Invoice
  Future<void> _syncInvoiceOperation(SyncOperation operation) async {
    try {
      final InvoiceRemoteDataSource remoteDataSource = Get.find<InvoiceRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando factura en servidor: ${data['customerId']}');

          // Parsear items
          final items = (data['items'] as List).map((item) => CreateInvoiceItemRequestModel(
            productId: item['productId'],
            description: item['description'],
            quantity: (item['quantity'] as num).toDouble(),
            unitPrice: (item['unitPrice'] as num).toDouble(),
            unit: item['unit'] ?? 'und',
            discountPercentage: item['discountPercentage'] != null ? (item['discountPercentage'] as num).toDouble() : 0,
            discountAmount: item['discountAmount'] != null ? (item['discountAmount'] as num).toDouble() : 0,
            notes: item['notes'],
          )).toList();

          final request = CreateInvoiceRequestModel(
            customerId: data['customerId'],
            items: items,
            number: data['number'],
            date: data['date'],
            dueDate: data['dueDate'],
            paymentMethod: data['paymentMethod'] ?? 'cash',
            status: data['status'],
            taxPercentage: data['taxPercentage'] != null ? (data['taxPercentage'] as num).toDouble() : 19,
            discountPercentage: data['discountPercentage'] != null ? (data['discountPercentage'] as num).toDouble() : 0,
            discountAmount: data['discountAmount'] != null ? (data['discountAmount'] as num).toDouble() : 0,
            notes: data['notes'],
            terms: data['terms'],
            metadata: data['metadata'],
            bankAccountId: data['bankAccountId'],
          );

          await remoteDataSource.createInvoice(request);
          print('✅ Factura creada en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando factura en servidor: ${operation.entityId}');

          // Parsear items si existen
          List<CreateInvoiceItemRequestModel>? items;
          if (data['items'] != null) {
            items = (data['items'] as List).map((item) => CreateInvoiceItemRequestModel(
              productId: item['productId'],
              description: item['description'],
              quantity: (item['quantity'] as num).toDouble(),
              unitPrice: (item['unitPrice'] as num).toDouble(),
              unit: item['unit'] ?? 'und',
              discountPercentage: item['discountPercentage'] != null ? (item['discountPercentage'] as num).toDouble() : 0,
              discountAmount: item['discountAmount'] != null ? (item['discountAmount'] as num).toDouble() : 0,
              notes: item['notes'],
            )).toList();
          }

          final updateRequest = UpdateInvoiceRequestModel(
            number: data['number'],
            date: data['date'],
            dueDate: data['dueDate'],
            paymentMethod: data['paymentMethod'],
            status: data['status'],
            taxPercentage: data['taxPercentage'] != null ? (data['taxPercentage'] as num).toDouble() : null,
            discountPercentage: data['discountPercentage'] != null ? (data['discountPercentage'] as num).toDouble() : null,
            discountAmount: data['discountAmount'] != null ? (data['discountAmount'] as num).toDouble() : null,
            notes: data['notes'],
            terms: data['terms'],
            metadata: data['metadata'],
            customerId: data['customerId'],
            items: items,
          );

          await remoteDataSource.updateInvoice(operation.entityId, updateRequest);
          print('✅ Factura actualizada en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando factura en servidor: ${operation.entityId}');
          await remoteDataSource.deleteInvoice(operation.entityId);
          print('✅ Factura eliminada en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Factura ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de PurchaseOrder
  Future<void> _syncPurchaseOrderOperation(SyncOperation operation) async {
    try {
      final PurchaseOrderRemoteDataSource remoteDataSource = Get.find<PurchaseOrderRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando orden de compra en servidor: ${data['supplierId']}');

          // Parsear items
          final itemParams = (data['items'] as List).map((item) => CreatePurchaseOrderItemParams(
            productId: item['productId'],
            lineNumber: item['lineNumber'],
            quantity: item['quantity'] is int ? item['quantity'] : (item['quantity'] as num).toInt(),
            unitPrice: (item['unitCost'] as num? ?? item['unitPrice'] as num).toDouble(),
            discountPercentage: item['discountPercentage'] != null ? (item['discountPercentage'] as num).toDouble() : 0,
            taxPercentage: item['taxPercentage'] != null ? (item['taxPercentage'] as num).toDouble() : 0,
            notes: item['notes'],
          )).toList();

          final createParams = CreatePurchaseOrderParams(
            supplierId: data['supplierId'],
            priority: data['priority'] != null ? PurchaseOrderPriority.values.firstWhere((e) => e.name == data['priority'], orElse: () => PurchaseOrderPriority.medium) : PurchaseOrderPriority.medium,
            orderDate: data['orderDate'] != null ? DateTime.parse(data['orderDate']) : DateTime.now(),
            expectedDeliveryDate: DateTime.parse(data['expectedDeliveryDate']),
            currency: data['currency'] ?? 'COP',
            items: itemParams,
            notes: data['notes'],
            internalNotes: data['internalNotes'],
            deliveryAddress: data['deliveryAddress'],
            contactPerson: data['contactPerson'],
            contactPhone: data['contactPhone'],
            contactEmail: data['contactEmail'],
            attachments: data['attachments'] != null ? List<String>.from(data['attachments']) : [],
          );

          await remoteDataSource.createPurchaseOrder(createParams);
          print('✅ Orden de compra creada en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando orden de compra en servidor: ${operation.entityId}');

          // Parsear items si existen
          List<UpdatePurchaseOrderItemParams>? updateItemParams;
          if (data['items'] != null) {
            updateItemParams = (data['items'] as List).map((item) => UpdatePurchaseOrderItemParams(
              id: item['id'],
              productId: item['productId'],
              quantity: item['quantity'] is int ? item['quantity'] : (item['quantity'] as num).toInt(),
              receivedQuantity: item['receivedQuantity'] is int ? item['receivedQuantity'] : (item['receivedQuantity'] as num?)?.toInt(),
              unitPrice: (item['unitCost'] as num? ?? item['unitPrice'] as num).toDouble(),
              discountPercentage: item['discountPercentage'] != null ? (item['discountPercentage'] as num).toDouble() : 0,
              taxPercentage: item['taxPercentage'] != null ? (item['taxPercentage'] as num).toDouble() : 0,
              notes: item['notes'],
            )).toList();
          }

          final updateParams = UpdatePurchaseOrderParams(
            id: operation.entityId,
            supplierId: data['supplierId'],
            status: data['status'] != null ? PurchaseOrderStatus.values.firstWhere((e) => e.name == data['status']) : null,
            priority: data['priority'] != null ? PurchaseOrderPriority.values.firstWhere((e) => e.name == data['priority']) : null,
            orderDate: data['orderDate'] != null ? DateTime.parse(data['orderDate']) : null,
            expectedDeliveryDate: data['expectedDeliveryDate'] != null ? DateTime.parse(data['expectedDeliveryDate']) : null,
            deliveredDate: data['deliveredDate'] != null ? DateTime.parse(data['deliveredDate']) : null,
            currency: data['currency'],
            items: updateItemParams,
            notes: data['notes'],
            internalNotes: data['internalNotes'],
            deliveryAddress: data['deliveryAddress'],
            contactPerson: data['contactPerson'],
            contactPhone: data['contactPhone'],
            contactEmail: data['contactEmail'],
            attachments: data['attachments'] != null ? List<String>.from(data['attachments']) : null,
          );

          await remoteDataSource.updatePurchaseOrder(updateParams);
          print('✅ Orden de compra actualizada en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando orden de compra en servidor: ${operation.entityId}');
          await remoteDataSource.deletePurchaseOrder(operation.entityId);
          print('✅ Orden de compra eliminada en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Orden de compra ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de InventoryMovement
  Future<void> _syncInventoryMovementOperation(SyncOperation operation) async {
    try {
      final InventoryRemoteDataSource remoteDataSource = Get.find<InventoryRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando movimiento de inventario en servidor: ${data['productId']}');
          final request = CreateInventoryMovementRequest(
            productId: data['productId'],
            type: data['type'],
            reason: data['reason'],
            quantity: data['quantity'] is int ? data['quantity'] : (data['quantity'] as num).toInt(),
            unitCost: (data['unitCost'] as num).toDouble(),
            lotNumber: data['lotNumber'],
            expiryDate: data['expiryDate'] != null ? DateTime.parse(data['expiryDate']) : null,
            warehouseId: data['warehouseId'],
            referenceId: data['referenceId'],
            referenceType: data['referenceType'],
            notes: data['notes'],
            movementDate: data['movementDate'] != null ? DateTime.parse(data['movementDate']) : null,
          );
          await remoteDataSource.createMovement(request);
          print('✅ Movimiento de inventario creado en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando movimiento de inventario en servidor: ${operation.entityId}');
          final updateRequest = UpdateInventoryMovementRequest(
            type: data['type'],
            reason: data['reason'],
            quantity: data['quantity'] != null ? (data['quantity'] is int ? data['quantity'] : (data['quantity'] as num).toInt()) : null,
            unitCost: data['unitCost'] != null ? (data['unitCost'] as num).toDouble() : null,
            lotNumber: data['lotNumber'],
            expiryDate: data['expiryDate'] != null ? DateTime.parse(data['expiryDate']) : null,
            warehouseId: data['warehouseId'],
            referenceId: data['referenceId'],
            referenceType: data['referenceType'],
            notes: data['notes'],
            movementDate: data['movementDate'] != null ? DateTime.parse(data['movementDate']) : null,
          );
          await remoteDataSource.updateMovement(operation.entityId, updateRequest);
          print('✅ Movimiento de inventario actualizado en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando movimiento de inventario en servidor: ${operation.entityId}');
          await remoteDataSource.deleteMovement(operation.entityId);
          print('✅ Movimiento de inventario eliminado en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Movimiento de inventario ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de CreditNote
  Future<void> _syncCreditNoteOperation(SyncOperation operation) async {
    try {
      final CreditNoteRemoteDataSource remoteDataSource = Get.find<CreditNoteRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando nota de crédito en servidor: ${data['invoiceId']}');

          // Parsear items
          final items = (data['items'] as List).map((item) => CreateCreditNoteItemRequestModel(
            invoiceItemId: item['invoiceItemId'],
            quantity: (item['quantity'] as num).toDouble(),
            unitPrice: (item['unitPrice'] as num).toDouble(),
            description: item['description'] ?? '',
            notes: item['notes'],
          )).toList();

          final request = CreateCreditNoteRequestModel(
            invoiceId: data['invoiceId'],
            type: data['type'],
            reason: data['reason'],
            reasonDescription: data['reasonDescription'],
            items: items,
            restoreInventory: data['restoreInventory'] ?? true,
            notes: data['notes'],
            terms: data['terms'],
          );

          await remoteDataSource.createCreditNote(request);
          print('✅ Nota de crédito creada en servidor');
          break;

        case SyncOperationType.update:
          print('📤 Actualizando nota de crédito en servidor: ${operation.entityId}');
          final updateRequest = UpdateCreditNoteRequestModel(
            reason: data['reason'],
            reasonDescription: data['reasonDescription'],
            restoreInventory: data['restoreInventory'],
            notes: data['notes'],
            terms: data['terms'],
          );
          await remoteDataSource.updateCreditNote(operation.entityId, updateRequest);
          print('✅ Nota de crédito actualizada en servidor');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando nota de crédito en servidor: ${operation.entityId}');
          await remoteDataSource.deleteCreditNote(operation.entityId);
          print('✅ Nota de crédito eliminada en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Nota de crédito ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }

  /// Sincronizar operación de CustomerCredit
  Future<void> _syncCustomerCreditOperation(SyncOperation operation) async {
    try {
      final CustomerCreditRemoteDataSource remoteDataSource = Get.find<CustomerCreditRemoteDataSource>();
      final data = jsonDecode(operation.payload);

      switch (operation.operationType) {
        case SyncOperationType.create:
          print('📤 Creando crédito de cliente en servidor: ${data['customerId']}');
          final request = CreateCustomerCreditDto(
            customerId: data['customerId'],
            originalAmount: (data['originalAmount'] as num).toDouble(),
            dueDate: data['dueDate'],
            description: data['description'],
            notes: data['notes'],
            invoiceId: data['invoiceId'],
            useClientBalance: data['useClientBalance'],
            skipAutoBalance: data['skipAutoBalance'],
          );
          await remoteDataSource.createCredit(request);
          print('✅ Crédito de cliente creado en servidor');
          break;

        case SyncOperationType.update:
          print('⚠️ UPDATE no está soportado para CustomerCredit - solo CREATE/DELETE');
          break;

        case SyncOperationType.delete:
          print('📤 Eliminando crédito de cliente en servidor: ${operation.entityId}');
          await remoteDataSource.deleteCredit(operation.entityId);
          print('✅ Crédito de cliente eliminado en servidor');
          break;
      }
    } catch (e) {
      if (e is ServerException && e.statusCode == 409) {
        print('⚠️ Crédito de cliente ya existe en servidor - marcando como completado');
        return;
      }
      rethrow;
    }
  }
}
