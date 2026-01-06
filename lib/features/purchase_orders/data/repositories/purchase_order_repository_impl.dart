// lib/features/purchase_orders/data/repositories/purchase_order_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/paginated_result.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
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
        
        // Cache solo la primera página para evitar problemas de sincronización
        if (params.page == 1) {
          try {
            await localDataSource.cachePurchaseOrders(remotePurchaseOrders.data);
          } catch (e) {
            print('Error al guardar en cache: $e');
            // No bloquear la aplicación por errores de cache
          }
        }
        
        return Right(
          PaginatedResult<PurchaseOrder>(
            data: remotePurchaseOrders.data.map((model) => model.toEntity()).toList(),
            meta: remotePurchaseOrders.meta,
          ),
        );
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.filterCachedPurchaseOrders(params);
        
        // Simular paginación offline
        final startIndex = (params.page - 1) * params.limit;
        final endIndex = startIndex + params.limit;
        final paginatedData = cachedPurchaseOrders.skip(startIndex).take(params.limit).toList();
        
        return Right(
          PaginatedResult<PurchaseOrder>(
            data: paginatedData.map((model) => model.toEntity()).toList(),
            meta: null, // Sin metadatos en modo offline
          ),
        );
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
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
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrder = await localDataSource.getCachedPurchaseOrderById(id);
        
        if (cachedPurchaseOrder != null) {
          return Right(cachedPurchaseOrder.toEntity());
        } else {
          return Left(CacheFailure('Orden de compra no encontrada en cache'));
        }
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> searchPurchaseOrders(
    SearchPurchaseOrdersParams params,
  ) async {
    try {
      final remotePurchaseOrders = await remoteDataSource.searchPurchaseOrders(params);
      return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (e) {
      print('⚠️ Error del servidor en searchPurchaseOrders: $e - intentando cache local...');
      try {
        final cachedPurchaseOrders = await localDataSource.searchCachedPurchaseOrders(
          params.searchTerm,
        );
        if (cachedPurchaseOrders.isNotEmpty) {
          print('✅ ${cachedPurchaseOrders.length} órdenes de compra encontradas en cache local');
        }
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (cacheError) {
        return Left(CacheFailure('Error al buscar en cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderStats>> getPurchaseOrderStats() async {
    try {
      final remoteStats = await remoteDataSource.getPurchaseOrderStats();

      // Guardar estadísticas en cache
      await localDataSource.cacheStats(remoteStats);

      return Right(remoteStats.toEntity());
    } catch (e) {
      print('⚠️ Error del servidor en getPurchaseOrderStats: $e - intentando cache local...');
      try {
        final cachedStats = await localDataSource.getCachedStats();

        if (cachedStats != null) {
          print('✅ Estadísticas de órdenes de compra obtenidas desde cache local');
          return Right(cachedStats.toEntity());
        } else {
          return Left(CacheFailure('Estadísticas no disponibles en cache'));
        }
      } catch (cacheError) {
        return Left(CacheFailure('Error al acceder a estadísticas en cache: $cacheError'));
      }
    }
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
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(approvedPurchaseOrder);
        
        return Right(approvedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede aprobar orden de compra sin conexión a internet'));
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
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(rejectedPurchaseOrder);
        
        return Right(rejectedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede rechazar orden de compra sin conexión a internet'));
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
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(sentPurchaseOrder);
        
        return Right(sentPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede enviar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> receivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final receivedPurchaseOrder = await remoteDataSource.receivePurchaseOrder(params);
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(receivedPurchaseOrder);
        
        return Right(receivedPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede recibir orden de compra sin conexión a internet'));
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
        
        // Actualizar cache
        await localDataSource.cachePurchaseOrder(cancelledPurchaseOrder);
        
        return Right(cancelledPurchaseOrder.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      return Left(ServerFailure('No se puede cancelar orden de compra sin conexión a internet'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPurchaseOrdersBySupplier(String supplierId) async {
    try {
      final remotePurchaseOrders = await remoteDataSource.getPurchaseOrdersBySupplier(supplierId);
      return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (e) {
      print('⚠️ Error del servidor en getPurchaseOrdersBySupplier: $e - intentando cache local...');
      try {
        final cachedPurchaseOrders = await localDataSource.getPurchaseOrdersBySupplier(supplierId);
        if (cachedPurchaseOrders.isNotEmpty) {
          print('✅ ${cachedPurchaseOrders.length} órdenes de compra del proveedor encontradas en cache');
        }
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (cacheError) {
        return Left(CacheFailure('Error al acceder al cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getOverduePurchaseOrders() async {
    try {
      final remotePurchaseOrders = await remoteDataSource.getOverduePurchaseOrders();
      return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
    } catch (e) {
      print('⚠️ Error del servidor en getOverduePurchaseOrders: $e - intentando cache local...');
      try {
        final cachedPurchaseOrders = await localDataSource.getOverduePurchaseOrders();
        if (cachedPurchaseOrders.isNotEmpty) {
          print('✅ ${cachedPurchaseOrders.length} órdenes de compra vencidas encontradas en cache');
        }
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } catch (cacheError) {
        return Left(CacheFailure('Error al acceder al cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPendingApprovalPurchaseOrders() async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getPendingApprovalPurchaseOrders();
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.getPendingApprovalPurchaseOrders();
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getRecentPurchaseOrders(int limit) async {
    if (await networkInfo.isConnected) {
      try {
        final remotePurchaseOrders = await remoteDataSource.getRecentPurchaseOrders(limit);
        return Right(remotePurchaseOrders.map((model) => model.toEntity()).toList());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('Error inesperado: $e'));
      }
    } else {
      try {
        final cachedPurchaseOrders = await localDataSource.getRecentPurchaseOrders();
        return Right(cachedPurchaseOrders.map((model) => model.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(CacheFailure('Error al acceder al cache: $e'));
      }
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
          productName: '',  // Will be filled when synced
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
        supplierName: null,  // Will be filled when synced
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