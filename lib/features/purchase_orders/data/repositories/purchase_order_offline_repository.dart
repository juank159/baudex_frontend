// lib/features/purchase_orders/data/repositories/purchase_order_offline_repository.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart' hide PaginatedResult;
import '../../../../app/core/models/paginated_result.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../models/isar/isar_purchase_order.dart';
import '../models/isar/isar_purchase_order_item.dart';

/// Implementación offline del repositorio de órdenes de compra usando ISAR
class PurchaseOrderOfflineRepository implements PurchaseOrderRepository {
  final IsarDatabase _database;

  PurchaseOrderOfflineRepository({IsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<PurchaseOrder>>> getPurchaseOrders(
    PurchaseOrderQueryParams params,
  ) async {
    try {
      var query = _isar.isarPurchaseOrders.filter().deletedAtIsNull();

      // Apply search filter
      if (params.search != null && params.search!.isNotEmpty) {
        query = query.and().group((q) => q
            .orderNumberContains(params.search!, caseSensitive: false)
            .or()
            .supplierNameContains(params.search!, caseSensitive: false)
            .or()
            .notesContains(params.search!, caseSensitive: false));
      }

      // Apply status filter
      if (params.status != null) {
        final isarStatus = _mapPurchaseOrderStatus(params.status!);
        query = query.and().statusEqualTo(isarStatus);
      }

      // Apply priority filter
      if (params.priority != null) {
        final isarPriority = _mapPurchaseOrderPriority(params.priority!);
        query = query.and().priorityEqualTo(isarPriority);
      }

      // Apply supplier filter
      if (params.supplierId != null) {
        query = query.and().supplierIdEqualTo(params.supplierId);
      }

      // Apply createdBy filter
      if (params.createdBy != null) {
        query = query.and().createdByEqualTo(params.createdBy);
      }

      // Apply approvedBy filter
      if (params.approvedBy != null) {
        query = query.and().approvedByEqualTo(params.approvedBy);
      }

      // Apply date range filter (orderDate)
      if (params.startDate != null) {
        query = query.and().orderDateGreaterThan(params.startDate!);
      }
      if (params.endDate != null) {
        query = query.and().orderDateLessThan(params.endDate!);
      }

      // Apply expected delivery date range filter
      if (params.expectedDeliveryStartDate != null) {
        query = query.and().expectedDeliveryDateGreaterThan(params.expectedDeliveryStartDate!);
      }
      if (params.expectedDeliveryEndDate != null) {
        query = query.and().expectedDeliveryDateLessThan(params.expectedDeliveryEndDate!);
      }

      // Fetch all filtered results
      var isarPurchaseOrders = await query.findAll();

      // Apply in-memory filters
      if (params.minAmount != null) {
        isarPurchaseOrders = isarPurchaseOrders.where((po) => po.totalAmount >= params.minAmount!).toList();
      }
      if (params.maxAmount != null) {
        isarPurchaseOrders = isarPurchaseOrders.where((po) => po.totalAmount <= params.maxAmount!).toList();
      }

      // Apply isOverdue filter
      if (params.isOverdue == true) {
        final now = DateTime.now();
        isarPurchaseOrders = isarPurchaseOrders.where((po) {
          return po.expectedDeliveryDate != null &&
              po.expectedDeliveryDate!.isBefore(now) &&
              po.status != IsarPurchaseOrderStatus.received &&
              po.status != IsarPurchaseOrderStatus.partiallyReceived &&
              po.status != IsarPurchaseOrderStatus.cancelled;
        }).toList();
      }

      // Get total count after filters
      final totalItems = isarPurchaseOrders.length;

      // Sort in memory
      if (params.sortBy == 'orderNumber') {
        isarPurchaseOrders.sort((a, b) {
          final aNum = a.orderNumber ?? '';
          final bNum = b.orderNumber ?? '';
          return params.sortOrder == 'desc'
              ? bNum.compareTo(aNum)
              : aNum.compareTo(bNum);
        });
      } else if (params.sortBy == 'totalAmount') {
        isarPurchaseOrders.sort((a, b) => params.sortOrder == 'desc'
            ? b.totalAmount.compareTo(a.totalAmount)
            : a.totalAmount.compareTo(b.totalAmount));
      } else if (params.sortBy == 'expectedDeliveryDate') {
        isarPurchaseOrders.sort((a, b) {
          final aDate = a.expectedDeliveryDate ?? DateTime(2099);
          final bDate = b.expectedDeliveryDate ?? DateTime(2099);
          return params.sortOrder == 'desc'
              ? bDate.compareTo(aDate)
              : aDate.compareTo(bDate);
        });
      } else if (params.sortBy == 'createdAt') {
        isarPurchaseOrders.sort((a, b) => params.sortOrder == 'desc'
            ? b.createdAt.compareTo(a.createdAt)
            : a.createdAt.compareTo(b.createdAt));
      } else {
        // Default sort by orderDate descending
        isarPurchaseOrders.sort((a, b) {
          final aDate = a.orderDate ?? DateTime(1970);
          final bDate = b.orderDate ?? DateTime(1970);
          return params.sortOrder == 'desc'
              ? bDate.compareTo(aDate)
              : aDate.compareTo(bDate);
        });
      }

      // Paginate in memory
      final offset = (params.page - 1) * params.limit;
      final paginatedPurchaseOrders = isarPurchaseOrders.skip(offset).take(params.limit).toList();

      // Load items for each purchase order
      for (final po in paginatedPurchaseOrders) {
        await po.items.load();
      }

      // Convert to domain entities
      final purchaseOrders = paginatedPurchaseOrders.map((isar) => isar.toEntity()).toList();

      // Create pagination meta
      final totalPages = (totalItems / params.limit).ceil();
      final meta = PaginationMeta(
        page: params.page,
        limit: params.limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: params.page < totalPages,
        hasPreviousPage: params.page > 1,
      );

      return Right(PaginatedResult(data: purchaseOrders, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading purchase orders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> getPurchaseOrderById(String id) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      // CRITICAL: Load items from the relationship
      await isarPurchaseOrder.items.load();

      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading purchase order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> searchPurchaseOrders(
    SearchPurchaseOrdersParams params,
  ) async {
    try {
      var query = _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
              .orderNumberContains(params.searchTerm, caseSensitive: false)
              .or()
              .supplierNameContains(params.searchTerm, caseSensitive: false)
              .or()
              .notesContains(params.searchTerm, caseSensitive: false));

      // Apply status filter if provided
      if (params.statuses != null && params.statuses!.isNotEmpty) {
        final isarStatuses = params.statuses!.map((s) => _mapPurchaseOrderStatus(s)).toList();
        if (isarStatuses.length == 1) {
          query = query.and().statusEqualTo(isarStatuses.first);
        } else {
          query = query.and().group((q) {
            var subQuery = q.statusEqualTo(isarStatuses.first);
            for (var i = 1; i < isarStatuses.length; i++) {
              subQuery = subQuery.or().statusEqualTo(isarStatuses[i]);
            }
            return subQuery;
          });
        }
      }

      // Apply supplier filter if provided
      if (params.supplierId != null) {
        query = query.and().supplierIdEqualTo(params.supplierId);
      }

      final isarPurchaseOrders = await query.limit(params.limit).findAll();

      // Load items for each purchase order
      for (final po in isarPurchaseOrders) {
        await po.items.load();
      }

      final purchaseOrders = isarPurchaseOrders.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error searching purchase orders: ${e.toString()}'));
    }
  }

  Future<Either<Failure, PurchaseOrder>> getPurchaseOrderByNumber(String orderNumber) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .orderNumberEqualTo(orderNumber)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading purchase order by number: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPurchaseOrdersBySupplier(
    String supplierId,
  ) async {
    try {
      final isarPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .supplierIdEqualTo(supplierId)
          .and()
          .deletedAtIsNull()
          .sortByOrderDateDesc()
          .findAll();

      // Load items for each purchase order
      for (final po in isarPurchaseOrders) {
        await po.items.load();
      }

      final purchaseOrders = isarPurchaseOrders.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error loading purchase orders by supplier: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<PurchaseOrder>>> getPendingPurchaseOrders() async {
    try {
      final isarPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .statusEqualTo(IsarPurchaseOrderStatus.pending)
          .and()
          .deletedAtIsNull()
          .sortByOrderDateDesc()
          .findAll();

      for (final po in isarPurchaseOrders) {
        await po.items.load();
      }

      final purchaseOrders = isarPurchaseOrders.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error loading pending purchase orders: ${e.toString()}'));
    }
  }

  Future<Either<Failure, List<PurchaseOrder>>> getDraftPurchaseOrders() async {
    try {
      final isarPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .statusEqualTo(IsarPurchaseOrderStatus.draft)
          .and()
          .deletedAtIsNull()
          .sortByUpdatedAtDesc()
          .findAll();

      for (final po in isarPurchaseOrders) {
        await po.items.load();
      }

      final purchaseOrders = isarPurchaseOrders.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error loading draft purchase orders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getOverduePurchaseOrders() async {
    try {
      final now = DateTime.now();
      final allPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .and()
          .expectedDeliveryDateIsNotNull()
          .findAll();

      final overdue = allPurchaseOrders.where((po) {
        return po.expectedDeliveryDate!.isBefore(now) &&
            po.status != IsarPurchaseOrderStatus.received &&
            po.status != IsarPurchaseOrderStatus.partiallyReceived &&
            po.status != IsarPurchaseOrderStatus.cancelled;
      }).toList();

      for (final po in overdue) {
        await po.items.load();
      }

      final purchaseOrders = overdue.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error loading overdue purchase orders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPendingApprovalPurchaseOrders() async {
    try {
      final isarPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .statusEqualTo(IsarPurchaseOrderStatus.pending)
          .and()
          .deletedAtIsNull()
          .sortByOrderDateDesc()
          .findAll();

      for (final po in isarPurchaseOrders) {
        await po.items.load();
      }

      final purchaseOrders = isarPurchaseOrders.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error loading pending approval purchase orders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getRecentPurchaseOrders(int limit) async {
    try {
      final isarPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .sortByCreatedAtDesc()
          .limit(limit)
          .findAll();

      for (final po in isarPurchaseOrders) {
        await po.items.load();
      }

      final purchaseOrders = isarPurchaseOrders.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error loading recent purchase orders: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrderStats>> getPurchaseOrderStats() async {
    try {
      final allPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .findAll();

      // Load items for all purchase orders for complete stats
      for (final po in allPurchaseOrders) {
        await po.items.load();
      }

      final total = allPurchaseOrders.length;
      final pending = allPurchaseOrders.where((po) => po.status == IsarPurchaseOrderStatus.pending).length;
      final approved = allPurchaseOrders.where((po) => po.status == IsarPurchaseOrderStatus.approved).length;
      final sent = allPurchaseOrders.where((po) => po.status == IsarPurchaseOrderStatus.sent).length;
      final partiallyReceived = allPurchaseOrders.where((po) => po.status == IsarPurchaseOrderStatus.partiallyReceived).length;
      final received = allPurchaseOrders.where((po) => po.status == IsarPurchaseOrderStatus.received).length;
      final cancelled = allPurchaseOrders.where((po) => po.status == IsarPurchaseOrderStatus.cancelled).length;

      final now = DateTime.now();
      final overdue = allPurchaseOrders.where((po) {
        return po.expectedDeliveryDate != null &&
            po.expectedDeliveryDate!.isBefore(now) &&
            po.status != IsarPurchaseOrderStatus.received &&
            po.status != IsarPurchaseOrderStatus.partiallyReceived &&
            po.status != IsarPurchaseOrderStatus.cancelled;
      }).length;

      final totalValue = allPurchaseOrders.fold<double>(0.0, (sum, po) => sum + po.totalAmount);
      final cancellationRate = total > 0 ? (cancelled / total * 100) : 0.0;
      final averageOrderValue = total > 0 ? totalValue / total : 0.0;

      final totalPending = allPurchaseOrders
          .where((po) => po.status != IsarPurchaseOrderStatus.received && po.status != IsarPurchaseOrderStatus.cancelled)
          .fold<double>(0.0, (sum, po) => sum + po.totalAmount);

      final totalReceived = allPurchaseOrders
          .where((po) => po.status == IsarPurchaseOrderStatus.received || po.status == IsarPurchaseOrderStatus.partiallyReceived)
          .fold<double>(0.0, (sum, po) => sum + po.totalAmount);

      // Orders by supplier
      final Map<String, int> ordersBySupplier = {};
      final Map<String, double> valueBySupplier = {};
      for (final po in allPurchaseOrders) {
        final supplierName = po.supplierName ?? 'Sin proveedor';
        ordersBySupplier[supplierName] = (ordersBySupplier[supplierName] ?? 0) + 1;
        valueBySupplier[supplierName] = (valueBySupplier[supplierName] ?? 0.0) + po.totalAmount;
      }

      // Orders by month
      final Map<String, int> ordersByMonth = {};
      for (final po in allPurchaseOrders) {
        if (po.orderDate != null) {
          final monthKey = '${po.orderDate!.year}-${po.orderDate!.month.toString().padLeft(2, '0')}';
          ordersByMonth[monthKey] = (ordersByMonth[monthKey] ?? 0) + 1;
        }
      }

      // Top orders by value
      final sortedByValue = List<IsarPurchaseOrder>.from(allPurchaseOrders)
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      final topOrdersIsar = sortedByValue.take(5).toList();
      final topOrdersByValue = topOrdersIsar.map((po) => po.toEntity()).toList();

      // Recent activity
      final recentActivity = allPurchaseOrders
          .take(10)
          .map((po) => {
                'id': po.serverId,
                'orderNumber': po.orderNumber ?? 'Sin número',
                'action': _getActivityAction(po.status),
                'date': po.updatedAt.toIso8601String(),
              })
          .toList();

      // Convert all to entities for the stats
      final allEntities = allPurchaseOrders.map((po) => po.toEntity()).toList();

      final stats = PurchaseOrderStats(
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
        averageOrderValue: averageOrderValue,
        totalPending: totalPending,
        totalReceived: totalReceived,
        ordersBySupplier: ordersBySupplier,
        valueBySupplier: valueBySupplier,
        ordersByMonth: ordersByMonth,
        topOrdersByValue: topOrdersByValue,
        recentActivity: recentActivity,
        orders: allEntities,
      );

      return Right(stats);
    } catch (e) {
      return Left(CacheFailure('Error calculating purchase order stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPurchaseOrderSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final purchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .and()
          .orderDateBetween(startDate, endDate)
          .findAll();

      final totalOrders = purchaseOrders.length;
      final totalValue = purchaseOrders.fold<double>(0.0, (sum, po) => sum + po.totalAmount);
      final avgValue = totalOrders > 0 ? totalValue / totalOrders : 0.0;

      final summary = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalOrders': totalOrders,
        'totalValue': totalValue,
        'averageValue': avgValue,
      };

      return Right(summary);
    } catch (e) {
      return Left(CacheFailure('Error getting purchase order summary: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByStatus() async {
    try {
      final allPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .findAll();

      final statusGroups = <String, int>{};
      for (final po in allPurchaseOrders) {
        final statusName = po.status.name;
        statusGroups[statusName] = (statusGroups[statusName] ?? 0) + 1;
      }

      final result = statusGroups.entries.map((entry) => {
            'status': entry.key,
            'count': entry.value,
          }).toList();

      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Error getting purchase orders by status: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersStatsbySupplier() async {
    try {
      final allPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .findAll();

      final supplierStats = <String, Map<String, dynamic>>{};
      for (final po in allPurchaseOrders) {
        final supplierId = po.supplierId ?? 'unknown';
        if (!supplierStats.containsKey(supplierId)) {
          supplierStats[supplierId] = {
            'supplierId': supplierId,
            'supplierName': po.supplierName ?? 'Sin nombre',
            'totalOrders': 0,
            'totalValue': 0.0,
          };
        }
        supplierStats[supplierId]!['totalOrders'] = (supplierStats[supplierId]!['totalOrders'] as int) + 1;
        supplierStats[supplierId]!['totalValue'] = (supplierStats[supplierId]!['totalValue'] as double) + po.totalAmount;
      }

      return Right(supplierStats.values.toList());
    } catch (e) {
      return Left(CacheFailure('Error getting purchase orders stats by supplier: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseOrdersByMonth(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final purchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .deletedAtIsNull()
          .and()
          .orderDateBetween(startDate, endDate)
          .findAll();

      final monthlyStats = <int, Map<String, dynamic>>{};
      for (var i = 1; i <= 12; i++) {
        monthlyStats[i] = {
          'month': i,
          'count': 0,
          'totalValue': 0.0,
        };
      }

      for (final po in purchaseOrders) {
        if (po.orderDate != null) {
          final month = po.orderDate!.month;
          monthlyStats[month]!['count'] = (monthlyStats[month]!['count'] as int) + 1;
          monthlyStats[month]!['totalValue'] = (monthlyStats[month]!['totalValue'] as double) + po.totalAmount;
        }
      }

      return Right(monthlyStats.values.toList());
    } catch (e) {
      return Left(CacheFailure('Error getting purchase orders by month: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, PurchaseOrder>> createPurchaseOrder(
    CreatePurchaseOrderParams params,
  ) async {
    try {
      final now = DateTime.now();
      final serverId = 'po_${now.millisecondsSinceEpoch}_${params.supplierId.hashCode}';

      // Calculate totals
      double subtotal = 0.0;
      double taxAmount = 0.0;
      double discountAmount = 0.0;

      for (final item in params.items) {
        final itemSubtotal = item.quantity * item.unitPrice;
        final itemDiscount = itemSubtotal * (item.discountPercentage / 100);
        final itemTax = (itemSubtotal - itemDiscount) * (item.taxPercentage / 100);

        subtotal += itemSubtotal;
        discountAmount += itemDiscount;
        taxAmount += itemTax;
      }

      final totalAmount = subtotal - discountAmount + taxAmount;

      final isarPurchaseOrder = IsarPurchaseOrder.create(
        serverId: serverId,
        orderNumber: _generateOrderNumber(),
        supplierId: params.supplierId,
        supplierName: null, // Will be set from supplier data
        status: IsarPurchaseOrderStatus.draft,
        priority: _mapPurchaseOrderPriority(params.priority),
        orderDate: params.orderDate,
        expectedDeliveryDate: params.expectedDeliveryDate,
        deliveredDate: null,
        currency: params.currency,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
        notes: params.notes,
        internalNotes: params.internalNotes,
        deliveryAddress: params.deliveryAddress,
        contactPerson: params.contactPerson,
        contactPhone: params.contactPhone,
        contactEmail: params.contactEmail,
        attachmentsJson: params.attachments.isNotEmpty ? jsonEncode(params.attachments) : null,
        createdBy: 'offline', // TODO: Get from auth context
        approvedBy: null,
        approvedAt: null,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isSynced: false,
        lastSyncAt: null,
      );

      // CRITICAL: Save purchase order first, then add items via IsarLinks
      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);

        // Create and save items
        final isarItems = params.items.map((item) {
          final itemId = 'poi_${now.millisecondsSinceEpoch}_${item.productId.hashCode}';
          final itemSubtotal = item.quantity * item.unitPrice;
          final itemDiscount = itemSubtotal * (item.discountPercentage / 100);
          final itemTax = (itemSubtotal - itemDiscount) * (item.taxPercentage / 100);

          final isarItem = IsarPurchaseOrderItem.create(
            itemId: itemId,
            purchaseOrderServerId: serverId,
            productId: item.productId,
            productName: '', // Will be populated from product data
            productCode: null,
            productDescription: null,
            unit: 'UND', // Default unit
            quantity: item.quantity,
            receivedQuantity: null,
            damagedQuantity: null,
            missingQuantity: null,
            unitPrice: item.unitPrice,
            discountPercentage: item.discountPercentage,
            discountAmount: itemDiscount,
            subtotal: itemSubtotal,
            taxPercentage: item.taxPercentage,
            taxAmount: itemTax,
            totalAmount: itemSubtotal - itemDiscount + itemTax,
            notes: item.notes,
            createdAt: now,
            updatedAt: now,
          );
          return isarItem;
        }).toList();

        await _isar.isarPurchaseOrderItems.putAll(isarItems);
        isarPurchaseOrder.items.addAll(isarItems);
        await isarPurchaseOrder.items.save();
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'supplierId': params.supplierId,
            'priority': params.priority.name,
            'orderDate': params.orderDate.toIso8601String(),
            'expectedDeliveryDate': params.expectedDeliveryDate.toIso8601String(),
            'currency': params.currency,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      // Reload items and return
      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating purchase order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> updatePurchaseOrder(
    UpdatePurchaseOrderParams params,
  ) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(params.id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      // Update fields
      if (params.supplierId != null) isarPurchaseOrder.supplierId = params.supplierId;
      if (params.status != null) isarPurchaseOrder.status = _mapPurchaseOrderStatus(params.status!);
      if (params.priority != null) isarPurchaseOrder.priority = _mapPurchaseOrderPriority(params.priority!);
      if (params.orderDate != null) isarPurchaseOrder.orderDate = params.orderDate;
      if (params.expectedDeliveryDate != null) isarPurchaseOrder.expectedDeliveryDate = params.expectedDeliveryDate;
      if (params.deliveredDate != null) isarPurchaseOrder.deliveredDate = params.deliveredDate;
      if (params.currency != null) isarPurchaseOrder.currency = params.currency;
      if (params.notes != null) isarPurchaseOrder.notes = params.notes;
      if (params.internalNotes != null) isarPurchaseOrder.internalNotes = params.internalNotes;
      if (params.deliveryAddress != null) isarPurchaseOrder.deliveryAddress = params.deliveryAddress;
      if (params.contactPerson != null) isarPurchaseOrder.contactPerson = params.contactPerson;
      if (params.contactPhone != null) isarPurchaseOrder.contactPhone = params.contactPhone;
      if (params.contactEmail != null) isarPurchaseOrder.contactEmail = params.contactEmail;
      if (params.attachments != null) isarPurchaseOrder.attachmentsJson = jsonEncode(params.attachments);

      // Update items if provided
      if (params.items != null) {
        await _updatePurchaseOrderItems(isarPurchaseOrder, params.items!);
      }

      isarPurchaseOrder.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: params.id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating purchase order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchaseOrder(String id) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      isarPurchaseOrder.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error deleting purchase order: ${e.toString()}'));
    }
  }

  Future<Either<Failure, PurchaseOrder>> restorePurchaseOrder(String id) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      isarPurchaseOrder.deletedAt = null;
      isarPurchaseOrder.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error restoring purchase order: ${e.toString()}'));
    }
  }

  // ==================== STATUS OPERATIONS ====================

  @override
  Future<Either<Failure, PurchaseOrder>> approvePurchaseOrder(
    String id,
    String? approvalNotes,
  ) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      if (isarPurchaseOrder.status != IsarPurchaseOrderStatus.pending) {
        return Left(CacheFailure('Only pending purchase orders can be approved'));
      }

      isarPurchaseOrder.status = IsarPurchaseOrderStatus.approved;
      isarPurchaseOrder.approvedBy = 'offline'; // TODO: Get from auth context
      isarPurchaseOrder.approvedAt = DateTime.now();
      if (approvalNotes != null) {
        isarPurchaseOrder.internalNotes = approvalNotes;
      }
      isarPurchaseOrder.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'action': 'approve'},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error approving purchase order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> rejectPurchaseOrder(
    String id,
    String rejectionReason,
  ) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      if (isarPurchaseOrder.status != IsarPurchaseOrderStatus.pending) {
        return Left(CacheFailure('Only pending purchase orders can be rejected'));
      }

      isarPurchaseOrder.status = IsarPurchaseOrderStatus.rejected;
      isarPurchaseOrder.internalNotes = rejectionReason;
      isarPurchaseOrder.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'action': 'reject', 'reason': rejectionReason},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error rejecting purchase order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> sendPurchaseOrder(
    String id,
    String? sendNotes,
  ) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      if (isarPurchaseOrder.status != IsarPurchaseOrderStatus.approved) {
        return Left(CacheFailure('Only approved purchase orders can be sent'));
      }

      isarPurchaseOrder.status = IsarPurchaseOrderStatus.sent;
      if (sendNotes != null) {
        isarPurchaseOrder.notes = sendNotes;
      }
      isarPurchaseOrder.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'action': 'send'},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error sending purchase order: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> receivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  ) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(params.id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      // Load items
      await isarPurchaseOrder.items.load();

      // Update received quantities
      await _isar.writeTxn(() async {
        for (final receivedItem in params.items) {
          final item = await _isar.isarPurchaseOrderItems
              .filter()
              .itemIdEqualTo(receivedItem.itemId)
              .findFirst();

          if (item != null) {
            item.receivedQuantity = receivedItem.receivedQuantity;
            item.damagedQuantity = receivedItem.damagedQuantity;
            item.missingQuantity = receivedItem.missingQuantity;
            item.updatedAt = DateTime.now();
            await _isar.isarPurchaseOrderItems.put(item);
          }
        }

        // Check if fully received
        await isarPurchaseOrder.items.load();
        final allFullyReceived = isarPurchaseOrder.items.every(
          (item) => item.receivedQuantity != null && item.receivedQuantity! >= item.quantity,
        );

        if (allFullyReceived) {
          isarPurchaseOrder.status = IsarPurchaseOrderStatus.received;
          isarPurchaseOrder.deliveredDate = params.receivedDate ?? DateTime.now();
        } else {
          isarPurchaseOrder.status = IsarPurchaseOrderStatus.partiallyReceived;
        }

        if (params.notes != null) {
          isarPurchaseOrder.notes = params.notes;
        }

        isarPurchaseOrder.markAsUnsynced();
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: params.id,
          operationType: SyncOperationType.update,
          data: {
            'action': 'receive',
            'items': params.items.map((item) => {
              'purchaseOrderItemId': item.itemId,
              'receivedQuantity': item.receivedQuantity,
              if (item.damagedQuantity != null) 'damagedQuantity': item.damagedQuantity,
              if (item.missingQuantity != null) 'missingQuantity': item.missingQuantity,
              if (item.notes != null) 'notes': item.notes,
            }).toList(),
            if (params.receivedDate != null) 'receivedDate': params.receivedDate!.toIso8601String(),
            if (params.notes != null) 'notes': params.notes,
            if (params.warehouseId != null) 'warehouseId': params.warehouseId,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error receiving purchase order: ${e.toString()}'));
    }
  }

  Future<Either<Failure, PurchaseOrder>> partiallyReceivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  ) async {
    // Same implementation as receivePurchaseOrder - it handles partial receiving automatically
    return receivePurchaseOrder(params);
  }

  @override
  Future<Either<Failure, PurchaseOrder>> cancelPurchaseOrder(
    String id,
    String cancellationReason,
  ) async {
    try {
      final isarPurchaseOrder = await _isar.isarPurchaseOrders
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarPurchaseOrder == null) {
        return Left(CacheFailure('Purchase order not found'));
      }

      if (isarPurchaseOrder.status == IsarPurchaseOrderStatus.received ||
          isarPurchaseOrder.status == IsarPurchaseOrderStatus.cancelled) {
        return Left(CacheFailure('Cannot cancel a received or already cancelled purchase order'));
      }

      isarPurchaseOrder.status = IsarPurchaseOrderStatus.cancelled;
      isarPurchaseOrder.internalNotes = cancellationReason;
      isarPurchaseOrder.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'PurchaseOrder',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'action': 'cancel', 'reason': cancellationReason},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      await isarPurchaseOrder.items.load();
      return Right(isarPurchaseOrder.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error cancelling purchase order: ${e.toString()}'));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<PurchaseOrder>>> getUnsyncedPurchaseOrders() async {
    try {
      final isarPurchaseOrders = await _isar.isarPurchaseOrders
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      for (final po in isarPurchaseOrders) {
        await po.items.load();
      }

      final purchaseOrders = isarPurchaseOrders.map((isar) => isar.toEntity()).toList();
      return Right(purchaseOrders);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced purchase orders: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> markPurchaseOrdersAsSynced(List<String> purchaseOrderIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in purchaseOrderIds) {
          final isarPurchaseOrder = await _isar.isarPurchaseOrders
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarPurchaseOrder != null) {
            isarPurchaseOrder.markAsSynced();
            await _isar.isarPurchaseOrders.put(isarPurchaseOrder);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking purchase orders as synced: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> bulkInsertPurchaseOrders(List<PurchaseOrder> purchaseOrders) async {
    try {
      await _isar.writeTxn(() async {
        for (final purchaseOrder in purchaseOrders) {
          final isarPurchaseOrder = IsarPurchaseOrder.fromEntity(purchaseOrder);
          await _isar.isarPurchaseOrders.put(isarPurchaseOrder);

          // Insert items
          final isarItems = purchaseOrder.items.map((item) {
            final isarItem = IsarPurchaseOrderItem.fromEntity(item);
            isarItem.purchaseOrderServerId = purchaseOrder.id;
            return isarItem;
          }).toList();

          await _isar.isarPurchaseOrderItems.putAll(isarItems);
          isarPurchaseOrder.items.addAll(isarItems);
          await isarPurchaseOrder.items.save();
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting purchase orders: ${e.toString()}'));
    }
  }

  // ==================== HELPER METHODS ====================

  IsarPurchaseOrderStatus _mapPurchaseOrderStatus(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return IsarPurchaseOrderStatus.draft;
      case PurchaseOrderStatus.pending:
        return IsarPurchaseOrderStatus.pending;
      case PurchaseOrderStatus.approved:
        return IsarPurchaseOrderStatus.approved;
      case PurchaseOrderStatus.rejected:
        return IsarPurchaseOrderStatus.rejected;
      case PurchaseOrderStatus.sent:
        return IsarPurchaseOrderStatus.sent;
      case PurchaseOrderStatus.partiallyReceived:
        return IsarPurchaseOrderStatus.partiallyReceived;
      case PurchaseOrderStatus.received:
        return IsarPurchaseOrderStatus.received;
      case PurchaseOrderStatus.cancelled:
        return IsarPurchaseOrderStatus.cancelled;
    }
  }

  IsarPurchaseOrderPriority _mapPurchaseOrderPriority(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return IsarPurchaseOrderPriority.low;
      case PurchaseOrderPriority.medium:
        return IsarPurchaseOrderPriority.medium;
      case PurchaseOrderPriority.high:
        return IsarPurchaseOrderPriority.high;
      case PurchaseOrderPriority.urgent:
        return IsarPurchaseOrderPriority.urgent;
    }
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(5);
    return 'PO-$timestamp';
  }

  String _getActivityAction(IsarPurchaseOrderStatus status) {
    switch (status) {
      case IsarPurchaseOrderStatus.draft:
        return 'Creada como borrador';
      case IsarPurchaseOrderStatus.pending:
        return 'Enviada para aprobación';
      case IsarPurchaseOrderStatus.approved:
        return 'Aprobada';
      case IsarPurchaseOrderStatus.rejected:
        return 'Rechazada';
      case IsarPurchaseOrderStatus.sent:
        return 'Enviada al proveedor';
      case IsarPurchaseOrderStatus.partiallyReceived:
        return 'Parcialmente recibida';
      case IsarPurchaseOrderStatus.received:
        return 'Recibida completamente';
      case IsarPurchaseOrderStatus.cancelled:
        return 'Cancelada';
    }
  }

  Future<void> _updatePurchaseOrderItems(
    IsarPurchaseOrder purchaseOrder,
    List<UpdatePurchaseOrderItemParams> itemParams,
  ) async {
    await _isar.writeTxn(() async {
      // Eliminar items existentes de la colección (no solo los links)
      final oldItems = await _isar.isarPurchaseOrderItems
          .filter()
          .purchaseOrderServerIdEqualTo(purchaseOrder.serverId)
          .findAll();
      if (oldItems.isNotEmpty) {
        await _isar.isarPurchaseOrderItems
            .deleteAll(oldItems.map((i) => i.id).toList());
      }
      purchaseOrder.items.clear();
      await purchaseOrder.items.save();

      // Recalculate totals
      double subtotal = 0.0;
      double taxAmount = 0.0;
      double discountAmount = 0.0;

      final now = DateTime.now();
      final newItems = <IsarPurchaseOrderItem>[];

      for (final itemParam in itemParams) {
        final itemId = itemParam.id ?? 'poi_${now.millisecondsSinceEpoch}_${itemParam.productId.hashCode}';
        final itemSubtotal = itemParam.quantity * itemParam.unitPrice;
        final itemDiscount = itemSubtotal * (itemParam.discountPercentage / 100);
        final itemTax = (itemSubtotal - itemDiscount) * (itemParam.taxPercentage / 100);

        subtotal += itemSubtotal;
        discountAmount += itemDiscount;
        taxAmount += itemTax;

        final isarItem = IsarPurchaseOrderItem.create(
          itemId: itemId,
          purchaseOrderServerId: purchaseOrder.serverId,
          productId: itemParam.productId,
          productName: '', // Will be populated from product data
          productCode: null,
          productDescription: null,
          unit: 'UND',
          quantity: itemParam.quantity,
          receivedQuantity: itemParam.receivedQuantity,
          damagedQuantity: null,
          missingQuantity: null,
          unitPrice: itemParam.unitPrice,
          discountPercentage: itemParam.discountPercentage,
          discountAmount: itemDiscount,
          subtotal: itemSubtotal,
          taxPercentage: itemParam.taxPercentage,
          taxAmount: itemTax,
          totalAmount: itemSubtotal - itemDiscount + itemTax,
          notes: itemParam.notes,
          createdAt: now,
          updatedAt: now,
        );

        newItems.add(isarItem);
      }

      // Update totals
      purchaseOrder.subtotal = subtotal;
      purchaseOrder.taxAmount = taxAmount;
      purchaseOrder.discountAmount = discountAmount;
      purchaseOrder.totalAmount = subtotal - discountAmount + taxAmount;

      // Save items and link them
      await _isar.isarPurchaseOrderItems.putAll(newItems);
      purchaseOrder.items.addAll(newItems);
      await purchaseOrder.items.save();
    });
  }
}
