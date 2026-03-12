// lib/features/purchase_orders/data/repositories/purchase_order_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/isar/isar_purchase_order.dart';
import '../models/isar/isar_purchase_order_item.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../datasources/purchase_order_local_datasource.dart';
import '../datasources/purchase_order_remote_datasource.dart';
import '../models/purchase_order_model.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  final PurchaseOrderRemoteDataSource remoteDataSource;
  final PurchaseOrderLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const PurchaseOrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PaginatedResult<PurchaseOrder>>> getPurchaseOrders(
    PurchaseOrderQueryParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getPurchaseOrders(params);
        
        // FASE 3: Cachear TODAS las páginas a ISAR (upsert por serverId evita duplicados)
        try {
          await localDataSource.cachePurchaseOrders(remotePurchaseOrders.data);
        } catch (e) {
          print('Error al guardar en cache: $e');
          // No bloquear la aplicación por errores de cache
        }
        
        return Right(
          PaginatedResult<PurchaseOrder>(
            data: remotePurchaseOrders.data.map((model) => model.toEntity()).toList(),
            meta: remotePurchaseOrders.meta,
          ),
        );
      } on ServerException catch (_) {
        return _getPurchaseOrdersFromCache(params);
      } catch (_) {
        return _getPurchaseOrdersFromCache(params);
      }
    } else {
      return _getPurchaseOrdersFromCache(params);
    }
  }

  Future<Either<Failure, PaginatedResult<PurchaseOrder>>> _getPurchaseOrdersFromCache(
    PurchaseOrderQueryParams params,
  ) async {
    try {
      final cachedPurchaseOrders = await localDataSource.filterCachedPurchaseOrders(params);

      // Simular paginación offline
      final startIndex = (params.page - 1) * params.limit;
      final paginatedData = cachedPurchaseOrders.skip(startIndex).take(params.limit).toList();

      return Right(
        PaginatedResult<PurchaseOrder>(
          data: paginatedData.map((model) => model.toEntity()).toList(),
          meta: null,
        ),
      );
    } catch (_) {
      return Right(
        PaginatedResult<PurchaseOrder>(
          data: <PurchaseOrder>[],
          meta: null,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> getPurchaseOrderById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrder = await remoteDataSource.getPurchaseOrderById(id);
        
        // Actualizar cache con la orden obtenida
        try {
          await localDataSource.cachePurchaseOrder(remotePurchaseOrder);
        } catch (e) {
          print('Error al guardar en cache: $e');
          // No bloquear la aplicación por errores de cache
        }
        
        return Right(remotePurchaseOrder.toEntity());
      } on ServerException catch (_) {
        return _getPurchaseOrderByIdFromCache(id);
      } catch (_) {
        return _getPurchaseOrderByIdFromCache(id);
      }
    } else {
      return _getPurchaseOrderByIdFromCache(id);
    }
  }

  Future<Either<Failure, PurchaseOrder>> _getPurchaseOrderByIdFromCache(String id) async {
    try {
      final cachedPurchaseOrder = await localDataSource.getCachedPurchaseOrderById(id);
      if (cachedPurchaseOrder != null) {
        return Right(cachedPurchaseOrder.toEntity());
      }
    } catch (_) {}
    return Left(CacheFailure('Orden de compra no encontrada en cache'));
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> searchPurchaseOrders(
    SearchPurchaseOrdersParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.searchPurchaseOrders(params);
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (e) {
        print('⚠️ Error del servidor en searchPurchaseOrders: $e - intentando cache local...');
        return _searchPurchaseOrdersFromCache(params);
      }
    } else {
      return _searchPurchaseOrdersFromCache(params);
    }
  }

  Future<Either<Failure, List<PurchaseOrder>>> _searchPurchaseOrdersFromCache(
    SearchPurchaseOrdersParams params,
  ) async {
    try {
      final cachedPurchaseOrders = await localDataSource.searchCachedPurchaseOrders(
        params.searchTerm,
      );
      if (cachedPurchaseOrders.isNotEmpty) {
        print('✅ ${cachedPurchaseOrders.length} órdenes de compra encontradas en cache local');
      }
      return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (_) {
      return const Right(<PurchaseOrder>[]);
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderStats>> getPurchaseOrderStats() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteStats = await remoteDataSource.getPurchaseOrderStats();

        // Guardar estadísticas en cache
        await localDataSource.cacheStats(remoteStats);

        return Right(remoteStats.toEntity());
      } catch (e) {
        print('⚠️ Error del servidor en getPurchaseOrderStats: $e - intentando cache local...');
        return _getPurchaseOrderStatsFromCache();
      }
    } else {
      return _getPurchaseOrderStatsFromCache();
    }
  }

  Future<Either<Failure, PurchaseOrderStats>> _getPurchaseOrderStatsFromCache() async {
    try {
      final cachedStats = await localDataSource.getCachedStats();

      if (cachedStats != null) {
        print('✅ Estadísticas de órdenes de compra obtenidas desde cache local');
        return Right(cachedStats.toEntity());
      }
    } catch (_) {}

    // Calcular stats dinámicamente desde los POs en ISAR/cache
    try {
      final cachedOrders = await localDataSource.getCachedPurchaseOrders();
      if (cachedOrders.isNotEmpty) {
        final orders = cachedOrders.map((m) => m.toEntity()).toList();
        final now = DateTime.now();

        int pending = 0, approved = 0, sent = 0, partiallyReceived = 0, received = 0, cancelled = 0, overdue = 0;
        double totalValue = 0, totalPendingValue = 0, totalReceivedValue = 0;
        final ordersBySupplier = <String, int>{};
        final valueBySupplier = <String, double>{};
        final ordersByMonth = <String, int>{};

        for (final order in orders) {
          totalValue += order.totalAmount;

          // Conteo por status
          final status = order.status.toString().split('.').last.toLowerCase();
          switch (status) {
            case 'pending': case 'draft':
              pending++;
              totalPendingValue += order.totalAmount;
            case 'approved':
              approved++;
              totalPendingValue += order.totalAmount;
            case 'sent':
              sent++;
              totalPendingValue += order.totalAmount;
            case 'partially_received': case 'partiallyreceived':
              partiallyReceived++;
            case 'received':
              received++;
              totalReceivedValue += order.totalAmount;
            case 'cancelled':
              cancelled++;
          }

          // Overdue check
          if (order.expectedDeliveryDate != null &&
              order.expectedDeliveryDate!.isBefore(now) &&
              status != 'received' && status != 'cancelled') {
            overdue++;
          }

          // Agrupar por proveedor
          final supplierName = order.supplierName ?? 'Sin proveedor';
          ordersBySupplier[supplierName] = (ordersBySupplier[supplierName] ?? 0) + 1;
          valueBySupplier[supplierName] = (valueBySupplier[supplierName] ?? 0) + order.totalAmount;

          // Agrupar por mes
          if (order.orderDate != null) {
            final monthKey = '${order.orderDate!.year}-${order.orderDate!.month.toString().padLeft(2, '0')}';
            ordersByMonth[monthKey] = (ordersByMonth[monthKey] ?? 0) + 1;
          }
        }

        final total = orders.length;
        final cancellationRate = total > 0 ? (cancelled / total * 100) : 0.0;
        final avgValue = total > 0 ? totalValue / total : 0.0;

        // Top orders by value
        final sortedByValue = List<PurchaseOrder>.from(orders)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        print('✅ Stats de POs calculadas desde ${orders.length} órdenes en ISAR');
        return Right(PurchaseOrderStats(
          totalPurchaseOrders: total,
          pendingOrders: pending,
          approvedOrders: approved,
          sentOrders: sent,
          partiallyReceivedOrders: partiallyReceived,
          receivedOrders: received,
          cancelledOrders: cancelled,
          overdueOrders: overdue,
          totalValue: totalValue,
          cancellationRate: cancellationRate,
          averageOrderValue: avgValue,
          totalPending: totalPendingValue,
          totalReceived: totalReceivedValue,
          ordersBySupplier: ordersBySupplier,
          valueBySupplier: valueBySupplier,
          ordersByMonth: ordersByMonth,
          topOrdersByValue: sortedByValue.take(5).toList(),
          recentActivity: [],
          orders: orders,
        ));
      }
    } catch (e) {
      print('⚠️ Error calculando stats desde ISAR: $e');
    }

    return const Right(PurchaseOrderStats(
      totalPurchaseOrders: 0,
      pendingOrders: 0,
      approvedOrders: 0,
      sentOrders: 0,
      partiallyReceivedOrders: 0,
      receivedOrders: 0,
      cancelledOrders: 0,
      overdueOrders: 0,
      totalValue: 0,
      cancellationRate: 0,
      averageOrderValue: 0,
      totalPending: 0,
      totalReceived: 0,
      ordersBySupplier: {},
      valueBySupplier: {},
      ordersByMonth: {},
      topOrdersByValue: [],
      recentActivity: [],
    ));
  }

  @override
  Future<Either<Failure, PurchaseOrder>> createPurchaseOrder(
    CreatePurchaseOrderParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final createdPurchaseOrder = await remoteDataSource.createPurchaseOrder(params);

        // Intentar agregar al cache (no bloquear si falla)
        try {
          await localDataSource.cachePurchaseOrder(createdPurchaseOrder);
        } catch (e) {
          print('Error al guardar orden de compra en cache: $e');
          // No bloquear la aplicación por errores de cache
        }

        return Right(createdPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        print('⚠️ [PO_REPO] ServerException en create: ${e.message} - Fallback offline...');
        return _createPurchaseOrderOffline(params);
      } on ConnectionException catch (e) {
        print('⚠️ [PO_REPO] ConnectionException en create: ${e.message} - Fallback offline...');
        return _createPurchaseOrderOffline(params);
      } catch (e) {
        print('⚠️ [PO_REPO] Exception en create: $e - Fallback offline...');
        return _createPurchaseOrderOffline(params);
      }
    } else {
      return _createPurchaseOrderOffline(params);
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> updatePurchaseOrder(
    UpdatePurchaseOrderParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedPurchaseOrder = await remoteDataSource.updatePurchaseOrder(params);

        // Actualizar cache
        await localDataSource.cachePurchaseOrder(updatedPurchaseOrder);

        return Right(updatedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        print('⚠️ [PO_REPO] ServerException en update: ${e.message} - Fallback offline...');
        return _updatePurchaseOrderOffline(params);
      } on ConnectionException catch (e) {
        print('⚠️ [PO_REPO] ConnectionException en update: ${e.message} - Fallback offline...');
        return _updatePurchaseOrderOffline(params);
      } catch (e) {
        print('⚠️ [PO_REPO] Exception en update: $e - Fallback offline...');
        return _updatePurchaseOrderOffline(params);
      }
    } else {
      return _updatePurchaseOrderOffline(params);
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchaseOrder(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePurchaseOrder(id);

        // Eliminar del cache
        await localDataSource.removeCachedPurchaseOrder(id);

        return const Right(null);
      } on ServerException catch (e) {
        print('⚠️ [PO_REPO] ServerException en delete: ${e.message} - Fallback offline...');
        return _deletePurchaseOrderOffline(id);
      } on ConnectionException catch (e) {
        print('⚠️ [PO_REPO] ConnectionException en delete: ${e.message} - Fallback offline...');
        return _deletePurchaseOrderOffline(id);
      } catch (e) {
        print('⚠️ [PO_REPO] Exception en delete: $e - Fallback offline...');
        return _deletePurchaseOrderOffline(id);
      }
    } else {
      return _deletePurchaseOrderOffline(id);
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> approvePurchaseOrder(
    String id,
    String? approvalNotes,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final approvedPurchaseOrder = await remoteDataSource.approvePurchaseOrder(id, approvalNotes);
        await localDataSource.cachePurchaseOrder(approvedPurchaseOrder);
        return Right(approvedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return _changeStatusOffline(id, 'approved', 'approve', notes: approvalNotes);
      } catch (e) {
        return _changeStatusOffline(id, 'approved', 'approve', notes: approvalNotes);
      }
    } else {
      return _changeStatusOffline(id, 'approved', 'approve', notes: approvalNotes);
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> rejectPurchaseOrder(
    String id,
    String rejectionReason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final rejectedPurchaseOrder = await remoteDataSource.rejectPurchaseOrder(id, rejectionReason);
        await localDataSource.cachePurchaseOrder(rejectedPurchaseOrder);
        return Right(rejectedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return _changeStatusOffline(id, 'rejected', 'reject', reason: rejectionReason);
      } catch (e) {
        return _changeStatusOffline(id, 'rejected', 'reject', reason: rejectionReason);
      }
    } else {
      return _changeStatusOffline(id, 'rejected', 'reject', reason: rejectionReason);
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> sendPurchaseOrder(
    String id,
    String? sendNotes,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final sentPurchaseOrder = await remoteDataSource.sendPurchaseOrder(id, sendNotes);
        await localDataSource.cachePurchaseOrder(sentPurchaseOrder);
        return Right(sentPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return _changeStatusOffline(id, 'sent', 'send', notes: sendNotes);
      } catch (e) {
        return _changeStatusOffline(id, 'sent', 'send', notes: sendNotes);
      }
    } else {
      return _changeStatusOffline(id, 'sent', 'send', notes: sendNotes);
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> receivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final receivedPurchaseOrder = await remoteDataSource.receivePurchaseOrder(params);
        await localDataSource.cachePurchaseOrder(receivedPurchaseOrder);
        return Right(receivedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return _receiveOffline(params);
      } catch (e) {
        return _receiveOffline(params);
      }
    } else {
      return _receiveOffline(params);
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> cancelPurchaseOrder(
    String id,
    String cancellationReason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final cancelledPurchaseOrder = await remoteDataSource.cancelPurchaseOrder(id, cancellationReason);
        await localDataSource.cachePurchaseOrder(cancelledPurchaseOrder);
        return Right(cancelledPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return _changeStatusOffline(id, 'cancelled', 'cancel', reason: cancellationReason);
      } catch (e) {
        return _changeStatusOffline(id, 'cancelled', 'cancel', reason: cancellationReason);
      }
    } else {
      return _changeStatusOffline(id, 'cancelled', 'cancel', reason: cancellationReason);
    }
  }

  /// Cambiar status de una PO localmente y encolar para sync
  Future<Either<Failure, PurchaseOrder>> _changeStatusOffline(
    String id,
    String newStatus,
    String action, {
    String? notes,
    String? reason,
  }) async {
    try {
      // Obtener orden actual del cache
      final cachedOrder = await localDataSource.getCachedPurchaseOrderById(id);
      if (cachedOrder == null) {
        return Left(CacheFailure('Orden de compra no encontrada en cache local'));
      }

      // Actualizar status en el modelo
      final updatedJson = cachedOrder.toJson();
      updatedJson['status'] = newStatus;
      updatedJson['updatedAt'] = DateTime.now().toIso8601String();
      if (newStatus == 'approved') {
        updatedJson['approvedAt'] = DateTime.now().toIso8601String();
      }
      final updatedModel = PurchaseOrderModel.fromJson(updatedJson);

      // Guardar en cache (ISAR + SecureStorage)
      await localDataSource.cachePurchaseOrder(updatedModel);

      // Encolar operación para sincronización
      final syncData = <String, dynamic>{
        'action': action,
      };
      if (notes != null) syncData['notes'] = notes;
      if (reason != null) syncData['reason'] = reason;

      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: id,
          operationType: SyncOperationType.update,
          data: syncData,
        );
        print('✅ Cambio de estado PO encolado: $action para $id');
      } catch (e) {
        print('⚠️ Error encolando cambio de estado PO: $e');
      }

      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error al cambiar estado offline: $e'));
    }
  }

  /// Recibir PO offline (caso especial con items recibidos)
  Future<Either<Failure, PurchaseOrder>> _receiveOffline(
    ReceivePurchaseOrderParams params,
  ) async {
    try {
      final cachedOrder = await localDataSource.getCachedPurchaseOrderById(params.id);
      if (cachedOrder == null) {
        return Left(CacheFailure('Orden de compra no encontrada en cache local'));
      }

      // Actualizar status
      final updatedJson = cachedOrder.toJson();
      updatedJson['status'] = 'received';
      updatedJson['updatedAt'] = DateTime.now().toIso8601String();
      updatedJson['deliveredDate'] = (params.receivedDate ?? DateTime.now()).toIso8601String();

      // ✅ Actualizar receivedQuantity de cada item basado en params
      // Esto es CRÍTICO para que el UseCase pueda crear movimientos de inventario
      if (updatedJson['items'] != null) {
        final itemsList = updatedJson['items'] as List;
        // Convertir items a List<Map> si son PurchaseOrderItemModel
        final itemMaps = <Map<String, dynamic>>[];
        for (var i = 0; i < itemsList.length; i++) {
          Map<String, dynamic> itemJson;
          if (itemsList[i] is Map<String, dynamic>) {
            itemJson = itemsList[i] as Map<String, dynamic>;
          } else if (itemsList[i] is PurchaseOrderItemModel) {
            itemJson = (itemsList[i] as PurchaseOrderItemModel).toJson();
          } else {
            continue;
          }
          final itemId = itemJson['id'] as String?;
          final productId = itemJson['productId'] as String?;
          // Buscar el item correspondiente en los params de recepción
          final receiveParam = params.items.where(
            (p) => p.itemId == itemId || p.itemId == productId,
          ).firstOrNull;
          if (receiveParam != null) {
            itemJson['receivedQuantity'] = receiveParam.receivedQuantity.toString();
            if (receiveParam.damagedQuantity != null) {
              itemJson['damagedQuantity'] = receiveParam.damagedQuantity.toString();
            }
            if (receiveParam.missingQuantity != null) {
              itemJson['missingQuantity'] = receiveParam.missingQuantity.toString();
            }
          } else {
            // Si no hay param específico, asumir recepción completa (comportamiento Quick Receive)
            itemJson['receivedQuantity'] = itemJson['quantity'] ?? '0';
          }
          itemMaps.add(itemJson);
        }
        updatedJson['items'] = itemMaps;
      }

      final updatedModel = PurchaseOrderModel.fromJson(updatedJson);

      await localDataSource.cachePurchaseOrder(updatedModel);

      // ✅ Actualizar items en ISAR también (para que sync_service lea datos frescos)
      try {
        final isar = Get.find<IsarDatabase>().database;
        final isarPO = await isar.isarPurchaseOrders
            .filter()
            .serverIdEqualTo(params.id)
            .findFirst();
        if (isarPO != null) {
          await isarPO.items.load();
          for (final isarItem in isarPO.items) {
            final receiveParam = params.items.where(
              (p) => p.itemId == isarItem.itemId || p.itemId == isarItem.productId,
            ).firstOrNull;
            if (receiveParam != null) {
              isarItem.receivedQuantity = receiveParam.receivedQuantity;
              isarItem.damagedQuantity = receiveParam.damagedQuantity ?? 0;
              isarItem.missingQuantity = receiveParam.missingQuantity ?? 0;
            } else {
              isarItem.receivedQuantity = isarItem.quantity;
            }
          }
          isarPO.status = IsarPurchaseOrderStatus.received;
          isarPO.deliveredDate = params.receivedDate ?? DateTime.now();
          isarPO.updatedAt = DateTime.now();
          isarPO.markAsUnsynced();
          await isar.writeTxn(() async {
            await isar.isarPurchaseOrderItems.putAll(isarPO.items.toList());
            await isar.isarPurchaseOrders.put(isarPO);
          });
        }
      } catch (e) {
        print('⚠️ Error actualizando PO items en ISAR: $e');
      }

      // Encolar operación para sincronización
      final syncData = <String, dynamic>{
        'action': 'receive',
        'items': params.items.map((item) => item.toMap()).toList(),
        if (params.receivedDate != null) 'receivedDate': params.receivedDate!.toIso8601String(),
        if (params.notes != null) 'notes': params.notes,
        if (params.warehouseId != null) 'warehouseId': params.warehouseId,
      };

      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: params.id,
          operationType: SyncOperationType.update,
          data: syncData,
        );
        print('✅ Recepción de PO encolada offline: ${params.id}');
      } catch (e) {
        print('⚠️ Error encolando recepción de PO: $e');
      }

      return Right(updatedModel.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error al recibir orden offline: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPurchaseOrdersBySupplier(String supplierId) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getPurchaseOrdersBySupplier(supplierId);
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (e) {
        print('⚠️ Error del servidor en getPurchaseOrdersBySupplier: $e - intentando cache local...');
        return _getPurchaseOrdersBySupplierFromCache(supplierId);
      }
    } else {
      return _getPurchaseOrdersBySupplierFromCache(supplierId);
    }
  }

  Future<Either<Failure, List<PurchaseOrder>>> _getPurchaseOrdersBySupplierFromCache(String supplierId) async {
    try {
      final cachedPurchaseOrders = await localDataSource.getPurchaseOrdersBySupplier(supplierId);
      return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (_) {
      return const Right(<PurchaseOrder>[]);
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getOverduePurchaseOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getOverduePurchaseOrders();
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (e) {
        print('⚠️ Error del servidor en getOverduePurchaseOrders: $e - intentando cache local...');
        return _getOverduePurchaseOrdersFromCache();
      }
    } else {
      return _getOverduePurchaseOrdersFromCache();
    }
  }

  Future<Either<Failure, List<PurchaseOrder>>> _getOverduePurchaseOrdersFromCache() async {
    try {
      final cachedPurchaseOrders = await localDataSource.getOverduePurchaseOrders();
      return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (_) {
      return const Right(<PurchaseOrder>[]);
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPendingApprovalPurchaseOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getPendingApprovalPurchaseOrders();
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (_) {
        return _getPendingApprovalFromCache();
      }
    } else {
      return _getPendingApprovalFromCache();
    }
  }

  Future<Either<Failure, List<PurchaseOrder>>> _getPendingApprovalFromCache() async {
    try {
      final cachedPurchaseOrders = await localDataSource.getPendingApprovalPurchaseOrders();
      return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (_) {
      return const Right(<PurchaseOrder>[]);
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getRecentPurchaseOrders(int limit) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getRecentPurchaseOrders(limit);
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (_) {
        return _getRecentPurchaseOrdersFromCache();
      }
    } else {
      return _getRecentPurchaseOrdersFromCache();
    }
  }

  Future<Either<Failure, List<PurchaseOrder>>> _getRecentPurchaseOrdersFromCache() async {
    try {
      final cachedPurchaseOrders = await localDataSource.getRecentPurchaseOrders();
      return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (_) {
      return const Right(<PurchaseOrder>[]);
    }
  }

  // TODO: Implementar métodos de reportes cuando estén disponibles en el backend
  @override
  Future<Either<Failure, Map<String, dynamic>>> getPurchaseOrderSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByStatus() async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersStatsbySupplier() async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByMonth(int year) async {
    return Left(ServerFailure('Funcionalidad no implementada aún'));
  }

  // ==================== OFFLINE OPERATIONS ====================

  /// Create purchase order offline (used as fallback when server fails or no connection)
  Future<Either<Failure, PurchaseOrder>> _createPurchaseOrderOffline(
    CreatePurchaseOrderParams params,
  ) async {
    print('📱 PurchaseOrderRepository: Creating purchase order offline');
    try {
      final now = DateTime.now();
      final tempId = 'po_offline_${now.millisecondsSinceEpoch}_${params.supplierId.hashCode}';

      // Calculate totals from items (params doesn't have subtotal, taxAmount, discountAmount, totalAmount)
      double subtotal = 0.0;
      double totalTaxAmount = 0.0;
      double totalDiscountAmount = 0.0;

      // Transform CreatePurchaseOrderItemParams to PurchaseOrderItem entities
      final List<PurchaseOrderItem> purchaseOrderItems = params.items.map((itemParam) {
        // Calculate item amounts
        final itemSubtotal = itemParam.quantity * itemParam.unitPrice;
        final itemDiscountAmount = itemSubtotal * (itemParam.discountPercentage / 100);
        final itemAfterDiscount = itemSubtotal - itemDiscountAmount;
        final itemTaxAmount = itemAfterDiscount * (itemParam.taxPercentage / 100);
        final itemTotal = itemAfterDiscount + itemTaxAmount;

        subtotal += itemAfterDiscount;
        totalTaxAmount += itemTaxAmount;
        totalDiscountAmount += itemDiscountAmount;

        return PurchaseOrderItem(
          id: '',  // Will be filled when synced
          productId: itemParam.productId,
          productName: itemParam.productName ?? '',
          productCode: null,
          productDescription: null,
          unit: '',  // Will be filled when synced
          quantity: itemParam.quantity,
          receivedQuantity: null,
          damagedQuantity: null,
          missingQuantity: null,
          unitPrice: itemParam.unitPrice,
          discountPercentage: itemParam.discountPercentage,
          discountAmount: itemDiscountAmount,
          subtotal: itemAfterDiscount,
          taxPercentage: itemParam.taxPercentage,
          taxAmount: itemTaxAmount,
          totalAmount: itemTotal,
          notes: itemParam.notes,
          createdAt: now,
          updatedAt: now,
        );
      }).toList();

      final totalAmount = subtotal + totalTaxAmount;

      // Create temporary purchase order entity
      final tempPurchaseOrder = PurchaseOrder(
        id: tempId,
        orderNumber: 'TEMP-${now.millisecondsSinceEpoch}',
        supplierId: params.supplierId,
        supplierName: params.supplierName,
        status: PurchaseOrderStatus.draft,
        priority: params.priority,
        orderDate: params.orderDate,
        expectedDeliveryDate: params.expectedDeliveryDate,
        deliveredDate: null,
        currency: params.currency,
        subtotal: subtotal,
        taxAmount: totalTaxAmount,
        discountAmount: totalDiscountAmount,
        totalAmount: totalAmount,
        items: purchaseOrderItems,
        notes: params.notes,
        internalNotes: params.internalNotes,
        deliveryAddress: params.deliveryAddress,
        contactPerson: params.contactPerson,
        contactPhone: params.contactPhone,
        contactEmail: params.contactEmail,
        attachments: params.attachments,
        createdAt: now,
        updatedAt: now,
      );

      // Cache locally
      await localDataSource.cachePurchaseOrder(
        PurchaseOrderModel.fromEntity(tempPurchaseOrder),
      );

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: tempId,
          operationType: SyncOperationType.create,
          data: {
            'supplierId': params.supplierId,
            'priority': params.priority.name,
            'orderDate': params.orderDate.toIso8601String(),
            'expectedDeliveryDate': params.expectedDeliveryDate.toIso8601String(),
            'currency': params.currency,
            'notes': params.notes,
            'internalNotes': params.internalNotes,
            'deliveryAddress': params.deliveryAddress,
            'contactPerson': params.contactPerson,
            'contactPhone': params.contactPhone,
            'contactEmail': params.contactEmail,
            'attachments': params.attachments,
            'items': params.items.map((item) => {
              'productId': item.productId,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'discountPercentage': item.discountPercentage,
              'taxPercentage': item.taxPercentage,
              if (item.notes != null) 'notes': item.notes,
            }).toList(),
          },
          priority: 1,
        );
        print('📤 PurchaseOrderRepository: Operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Purchase order created offline successfully');
      return Right(tempPurchaseOrder);
    } catch (e) {
      print('❌ Error creating purchase order offline: $e');
      return Left(CacheFailure('Error al crear orden de compra offline: $e'));
    }
  }

  /// Update purchase order offline (used as fallback when server fails or no connection)
  Future<Either<Failure, PurchaseOrder>> _updatePurchaseOrderOffline(
    UpdatePurchaseOrderParams params,
  ) async {
    print('📱 PurchaseOrderRepository: Updating purchase order offline: ${params.id}');
    try {
      // Get cached purchase order
      final cachedPurchaseOrderModel = await localDataSource.getCachedPurchaseOrderById(params.id);
      if (cachedPurchaseOrderModel == null) {
        return Left(CacheFailure('Orden de compra no encontrada en cache: ${params.id}'));
      }
      final cachedPurchaseOrder = cachedPurchaseOrderModel.toEntity();

      // If items are being updated, recalculate totals
      List<PurchaseOrderItem>? updatedItems;
      double? newSubtotal;
      double? newTaxAmount;
      double? newDiscountAmount;
      double? newTotalAmount;

      if (params.items != null) {
        final now = DateTime.now();
        double subtotal = 0.0;
        double totalTaxAmount = 0.0;
        double totalDiscountAmount = 0.0;

        updatedItems = params.items!.map((itemParam) {
          // Calculate item amounts
          final itemSubtotal = itemParam.quantity * itemParam.unitPrice;
          final itemDiscountAmount = itemSubtotal * (itemParam.discountPercentage / 100);
          final itemAfterDiscount = itemSubtotal - itemDiscountAmount;
          final itemTaxAmount = itemAfterDiscount * (itemParam.taxPercentage / 100);
          final itemTotal = itemAfterDiscount + itemTaxAmount;

          subtotal += itemAfterDiscount;
          totalTaxAmount += itemTaxAmount;
          totalDiscountAmount += itemDiscountAmount;

          return PurchaseOrderItem(
            id: itemParam.id ?? '',
            productId: itemParam.productId,
            productName: '',  // Keep existing or will be filled when synced
            productCode: null,
            productDescription: null,
            unit: '',
            quantity: itemParam.quantity,
            receivedQuantity: itemParam.receivedQuantity,
            damagedQuantity: null,
            missingQuantity: null,
            unitPrice: itemParam.unitPrice,
            discountPercentage: itemParam.discountPercentage,
            discountAmount: itemDiscountAmount,
            subtotal: itemAfterDiscount,
            taxPercentage: itemParam.taxPercentage,
            taxAmount: itemTaxAmount,
            totalAmount: itemTotal,
            notes: itemParam.notes,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();

        newSubtotal = subtotal;
        newTaxAmount = totalTaxAmount;
        newDiscountAmount = totalDiscountAmount;
        newTotalAmount = subtotal + totalTaxAmount;
      }

      // Create updated purchase order entity (params doesn't have orderNumber, supplierName, subtotal, taxAmount, discountAmount, totalAmount)
      final updatedPurchaseOrder = PurchaseOrder(
        id: params.id,
        orderNumber: cachedPurchaseOrder.orderNumber,  // params doesn't have this
        supplierId: params.supplierId ?? cachedPurchaseOrder.supplierId,
        supplierName: cachedPurchaseOrder.supplierName,  // params doesn't have this
        status: params.status ?? cachedPurchaseOrder.status,
        priority: params.priority ?? cachedPurchaseOrder.priority,
        orderDate: params.orderDate ?? cachedPurchaseOrder.orderDate,
        expectedDeliveryDate: params.expectedDeliveryDate ?? cachedPurchaseOrder.expectedDeliveryDate,
        deliveredDate: params.deliveredDate ?? cachedPurchaseOrder.deliveredDate,
        currency: params.currency ?? cachedPurchaseOrder.currency,
        subtotal: newSubtotal ?? cachedPurchaseOrder.subtotal,  // Recalculated from items
        taxAmount: newTaxAmount ?? cachedPurchaseOrder.taxAmount,
        discountAmount: newDiscountAmount ?? cachedPurchaseOrder.discountAmount,
        totalAmount: newTotalAmount ?? cachedPurchaseOrder.totalAmount,
        items: updatedItems ?? cachedPurchaseOrder.items,
        notes: params.notes ?? cachedPurchaseOrder.notes,
        internalNotes: params.internalNotes ?? cachedPurchaseOrder.internalNotes,
        deliveryAddress: params.deliveryAddress ?? cachedPurchaseOrder.deliveryAddress,
        contactPerson: params.contactPerson ?? cachedPurchaseOrder.contactPerson,
        contactPhone: params.contactPhone ?? cachedPurchaseOrder.contactPhone,
        contactEmail: params.contactEmail ?? cachedPurchaseOrder.contactEmail,
        attachments: params.attachments ?? cachedPurchaseOrder.attachments,
        createdBy: cachedPurchaseOrder.createdBy,
        approvedBy: cachedPurchaseOrder.approvedBy,
        approvedAt: cachedPurchaseOrder.approvedAt,
        createdAt: cachedPurchaseOrder.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update cache
      await localDataSource.cachePurchaseOrder(
        PurchaseOrderModel.fromEntity(updatedPurchaseOrder),
      );

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: params.id,
          operationType: SyncOperationType.update,
          data: {
            if (params.supplierId != null) 'supplierId': params.supplierId,
            if (params.status != null) 'status': params.status!.name,
            if (params.priority != null) 'priority': params.priority!.name,
            if (params.orderDate != null) 'orderDate': params.orderDate!.toIso8601String(),
            if (params.expectedDeliveryDate != null) 'expectedDeliveryDate': params.expectedDeliveryDate!.toIso8601String(),
            if (params.deliveredDate != null) 'deliveredDate': params.deliveredDate!.toIso8601String(),
            if (params.currency != null) 'currency': params.currency,
            if (params.notes != null) 'notes': params.notes,
            if (params.internalNotes != null) 'internalNotes': params.internalNotes,
            if (params.deliveryAddress != null) 'deliveryAddress': params.deliveryAddress,
            if (params.contactPerson != null) 'contactPerson': params.contactPerson,
            if (params.contactPhone != null) 'contactPhone': params.contactPhone,
            if (params.contactEmail != null) 'contactEmail': params.contactEmail,
            if (params.attachments != null) 'attachments': params.attachments,
            if (params.items != null) 'items': params.items!.map((item) => {
              if (item.id != null) 'id': item.id,
              'productId': item.productId,
              'quantity': item.quantity,
              if (item.receivedQuantity != null) 'receivedQuantity': item.receivedQuantity,
              'unitPrice': item.unitPrice,
              'discountPercentage': item.discountPercentage,
              'taxPercentage': item.taxPercentage,
              if (item.notes != null) 'notes': item.notes,
            }).toList(),
          },
          priority: 1,
        );
        print('📤 Update operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Purchase order updated offline successfully');
      return Right(updatedPurchaseOrder);
    } catch (e) {
      print('❌ Error updating purchase order offline: $e');
      return Left(CacheFailure('Error al actualizar orden de compra offline: $e'));
    }
  }

  /// Delete purchase order offline (used as fallback when server fails or no connection)
  Future<Either<Failure, void>> _deletePurchaseOrderOffline(String id) async {
    print('📱 PurchaseOrderRepository: Deleting purchase order offline: $id');
    try {
      // Remove from cache
      await localDataSource.removeCachedPurchaseOrder(id);

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        print('📤 Delete operation added to sync queue');
      } catch (e) {
        print('⚠️ Error adding to sync queue: $e');
      }

      print('✅ Purchase order deleted offline successfully');
      return const Right(null);
    } catch (e) {
      print('❌ Error deleting purchase order offline: $e');
      return Left(CacheFailure('Error al eliminar orden de compra offline: $e'));
    }
  }
}