// lib/features/purchase_orders/data/datasources/purchase_order_local_datasource.dart
import 'dart:convert';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../models/purchase_order_model.dart';

abstract class PurchaseOrderLocalDataSource {
  Future<List<PurchaseOrderModel>> getCachedPurchaseOrders();
  
  Future<void> cachePurchaseOrders(List<PurchaseOrderModel> purchaseOrders);
  
  Future<PurchaseOrderModel?> getCachedPurchaseOrderById(String id);
  
  Future<void> cachePurchaseOrder(PurchaseOrderModel purchaseOrder);
  
  Future<List<PurchaseOrderModel>> searchCachedPurchaseOrders(String query);
  
  Future<List<PurchaseOrderModel>> filterCachedPurchaseOrders(
    PurchaseOrderQueryParams params,
  );
  
  Future<PurchaseOrderStatsModel?> getCachedStats();
  
  Future<void> cacheStats(PurchaseOrderStatsModel stats);
  
  Future<void> removeCachedPurchaseOrder(String id);
  
  Future<void> clearCache();
  
  // Métodos adicionales requeridos por el repository
  Future<List<PurchaseOrderModel>> getPurchaseOrdersBySupplier(String supplierId);
  Future<List<PurchaseOrderModel>> getOverduePurchaseOrders();
  Future<List<PurchaseOrderModel>> getPendingApprovalPurchaseOrders();
  Future<List<PurchaseOrderModel>> getRecentPurchaseOrders();
  
  Future<DateTime?> getLastCacheUpdate();
  
  Future<bool> isCacheValid();
}

class PurchaseOrderLocalDataSourceImpl implements PurchaseOrderLocalDataSource {
  final SecureStorageService secureStorageService;

  // Cache duration: 30 minutes
  static const int cacheValidityDuration = 30;

  const PurchaseOrderLocalDataSourceImpl({required this.secureStorageService});

  @override
  Future<List<PurchaseOrderModel>> getCachedPurchaseOrders() async {
    try {
      final cachedData = await secureStorageService.read(
        ApiConstants.purchaseOrdersCacheKey,
      );
      
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList
            .map((json) => PurchaseOrderModel.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw CacheException('Error al obtener órdenes de compra del cache: $e');
    }
  }

  @override
  Future<void> cachePurchaseOrders(List<PurchaseOrderModel> purchaseOrders) async {
    try {
      final jsonList = purchaseOrders.map((order) => order.toJson()).toList();
      await secureStorageService.write(
        ApiConstants.purchaseOrdersCacheKey,
        json.encode(jsonList),
      );
      
      // Guardar timestamp del cache
      await secureStorageService.write(
        '${ApiConstants.purchaseOrdersCacheKey}_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw CacheException('Error al guardar órdenes de compra en cache: $e');
    }
  }

  @override
  Future<PurchaseOrderModel?> getCachedPurchaseOrderById(String id) async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      
      for (final order in cachedOrders) {
        if (order.id == id) {
          return order;
        }
      }
      
      return null;
    } catch (e) {
      throw CacheException('Error al buscar orden de compra en cache: $e');
    }
  }

  @override
  Future<void> cachePurchaseOrder(PurchaseOrderModel purchaseOrder) async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      
      // Buscar si ya existe la orden y actualizarla, si no agregarla
      final existingIndex = cachedOrders.indexWhere(
        (order) => order.id == purchaseOrder.id,
      );
      
      if (existingIndex != -1) {
        cachedOrders[existingIndex] = purchaseOrder;
      } else {
        cachedOrders.add(purchaseOrder);
      }
      
      await cachePurchaseOrders(cachedOrders);
    } catch (e) {
      throw CacheException('Error al guardar orden de compra en cache: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> searchCachedPurchaseOrders(String query) async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      
      if (query.isEmpty) {
        return cachedOrders;
      }
      
      final lowerQuery = query.toLowerCase();
      return cachedOrders.where((order) {
        return (order.orderNumber?.toLowerCase().contains(lowerQuery) ?? false) ||
               (order.supplierName?.toLowerCase().contains(lowerQuery) ?? false) ||
               (order.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
               (order.contactPerson?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw CacheException('Error al buscar órdenes de compra en cache: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> filterCachedPurchaseOrders(
    PurchaseOrderQueryParams params,
  ) async {
    try {
      List<PurchaseOrderModel> orders = await getCachedPurchaseOrders();

      // Aplicar filtros
      if (params.status != null) {
        orders = orders.where((order) => 
          (order.status?.toLowerCase() ?? '') == params.status!.name.toLowerCase()
        ).toList();
      }

      if (params.priority != null) {
        orders = orders.where((order) => 
          (order.priority?.toLowerCase() ?? '') == params.priority!.name.toLowerCase()
        ).toList();
      }

      if (params.supplierId != null) {
        orders = orders.where((order) => 
          order.supplierId == params.supplierId
        ).toList();
      }

      if (params.startDate != null) {
        orders = orders.where((order) => 
          order.orderDate != null && DateTime.parse(order.orderDate!).isAfter(params.startDate!)
        ).toList();
      }

      if (params.endDate != null) {
        orders = orders.where((order) => 
          order.orderDate != null && DateTime.parse(order.orderDate!).isBefore(params.endDate!)
        ).toList();
      }

      if (params.minAmount != null) {
        orders = orders.where((order) => 
          order.totalAmount >= params.minAmount!
        ).toList();
      }

      if (params.maxAmount != null) {
        orders = orders.where((order) => 
          order.totalAmount <= params.maxAmount!
        ).toList();
      }

      if (params.createdBy != null) {
        orders = orders.where((order) => 
          order.createdBy == params.createdBy
        ).toList();
      }

      if (params.isOverdue == true) {
        final now = DateTime.now();
        orders = orders.where((order) => 
          order.expectedDeliveryDate != null && DateTime.parse(order.expectedDeliveryDate!).isBefore(now) &&
          order.status != 'received' &&
          order.status != 'cancelled'
        ).toList();
      }

      // Búsqueda por texto
      if (params.search != null && params.search!.isNotEmpty) {
        final query = params.search!.toLowerCase();
        orders = orders.where((order) =>
          (order.orderNumber?.toLowerCase().contains(query) ?? false) ||
          (order.supplierName?.toLowerCase().contains(query) ?? false) ||
          (order.notes?.toLowerCase().contains(query) ?? false)
        ).toList();
      }

      // Ordenamiento
      orders.sort((a, b) {
        int comparison = 0;
        
        switch (params.sortBy) {
          case 'orderNumber':
            comparison = (a.orderNumber ?? '').compareTo(b.orderNumber ?? '');
            break;
          case 'supplierName':
            comparison = (a.supplierName ?? '').compareTo(b.supplierName ?? '');
            break;
          case 'status':
            comparison = (a.status ?? '').compareTo(b.status ?? '');
            break;
          case 'priority':
            comparison = (a.priority ?? '').compareTo(b.priority ?? '');
            break;
          case 'totalAmount':
            comparison = a.totalAmount.compareTo(b.totalAmount);
            break;
          case 'expectedDeliveryDate':
            comparison = DateTime.parse(a.expectedDeliveryDate ?? DateTime.now().toIso8601String())
                .compareTo(DateTime.parse(b.expectedDeliveryDate ?? DateTime.now().toIso8601String()));
            break;
          case 'createdAt':
            comparison = DateTime.parse(a.createdAt ?? DateTime.now().toIso8601String())
                .compareTo(DateTime.parse(b.createdAt ?? DateTime.now().toIso8601String()));
            break;
          case 'orderDate':
          default:
            comparison = DateTime.parse(a.orderDate ?? DateTime.now().toIso8601String())
                .compareTo(DateTime.parse(b.orderDate ?? DateTime.now().toIso8601String()));
            break;
        }

        return params.sortOrder == 'desc' ? -comparison : comparison;
      });

      return orders;
    } catch (e) {
      throw CacheException('Error al filtrar órdenes de compra en cache: $e');
    }
  }

  @override
  Future<PurchaseOrderStatsModel?> getCachedStats() async {
    try {
      final cachedData = await secureStorageService.read(
        ApiConstants.purchaseOrderStatsCacheKey,
      );
      
      if (cachedData != null) {
        return PurchaseOrderStatsModel.fromJson(json.decode(cachedData));
      }
      
      return null;
    } catch (e) {
      throw CacheException('Error al obtener estadísticas del cache: $e');
    }
  }

  @override
  Future<void> cacheStats(PurchaseOrderStatsModel stats) async {
    try {
      await secureStorageService.write(
        ApiConstants.purchaseOrderStatsCacheKey,
        json.encode(stats.toJson()),
      );
      
      // Guardar timestamp del cache de estadísticas
      await secureStorageService.write(
        '${ApiConstants.purchaseOrderStatsCacheKey}_timestamp',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw CacheException('Error al guardar estadísticas en cache: $e');
    }
  }

  @override
  Future<void> removeCachedPurchaseOrder(String id) async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      final updatedOrders = cachedOrders.where((order) => order.id != id).toList();
      await cachePurchaseOrders(updatedOrders);
    } catch (e) {
      throw CacheException('Error al eliminar orden de compra del cache: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await secureStorageService.delete(ApiConstants.purchaseOrdersCacheKey);
      await secureStorageService.delete('${ApiConstants.purchaseOrdersCacheKey}_timestamp');
      await secureStorageService.delete(ApiConstants.purchaseOrderStatsCacheKey);
      await secureStorageService.delete('${ApiConstants.purchaseOrderStatsCacheKey}_timestamp');
    } catch (e) {
      throw CacheException('Error al limpiar cache: $e');
    }
  }

  @override
  Future<DateTime?> getLastCacheUpdate() async {
    try {
      final timestampStr = await secureStorageService.read(
        '${ApiConstants.purchaseOrdersCacheKey}_timestamp',
      );
      
      if (timestampStr != null) {
        return DateTime.parse(timestampStr);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final lastUpdate = await getLastCacheUpdate();
      
      if (lastUpdate == null) {
        return false;
      }
      
      final now = DateTime.now();
      final difference = now.difference(lastUpdate).inMinutes;
      
      return difference < cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  // Métodos auxiliares para filtros específicos
  @override
  Future<List<PurchaseOrderModel>> getOverduePurchaseOrders() async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      final now = DateTime.now();
      
      return cachedOrders.where((order) =>
        order.expectedDeliveryDate != null && DateTime.parse(order.expectedDeliveryDate!).isBefore(now) &&
        order.status != 'received' &&
        order.status != 'cancelled'
      ).toList();
    } catch (e) {
      throw CacheException('Error al obtener órdenes vencidas del cache: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> getPendingApprovalPurchaseOrders() async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      
      return cachedOrders.where((order) =>
        order.status == 'pending'
      ).toList();
    } catch (e) {
      throw CacheException('Error al obtener órdenes pendientes del cache: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> getRecentPurchaseOrders() async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      
      // Ordenar por fecha de creación descendente
      cachedOrders.sort((a, b) => 
        DateTime.parse(b.createdAt ?? DateTime.now().toIso8601String()).compareTo(DateTime.parse(a.createdAt ?? DateTime.now().toIso8601String()))
      );
      
      return cachedOrders.take(10).toList(); // Default limit
    } catch (e) {
      throw CacheException('Error al obtener órdenes recientes del cache: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> getPurchaseOrdersBySupplier(String supplierId) async {
    try {
      final cachedOrders = await getCachedPurchaseOrders();
      
      return cachedOrders.where((order) =>
        order.supplierId == supplierId
      ).toList();
    } catch (e) {
      throw CacheException('Error al obtener órdenes por proveedor del cache: $e');
    }
  }
}