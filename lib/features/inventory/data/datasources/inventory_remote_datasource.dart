// lib/features/inventory/data/datasources/inventory_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../models/inventory_movement_model.dart';
import '../models/inventory_balance_model.dart';
import '../models/inventory_stats_model.dart';
import '../models/kardex_report_model.dart';
import '../models/warehouse_model.dart';
import '../models/warehouse_stats_model.dart';
import '../../domain/repositories/inventory_repository.dart';

abstract class InventoryRemoteDataSource {
  Future<PaginatedResult<InventoryMovementModel>> getMovements(
    InventoryMovementQueryParams params,
  );
  
  Future<InventoryMovementModel> getMovementById(String id);
  
  Future<InventoryMovementModel> createMovement(
    CreateInventoryMovementRequest request,
  );
  
  Future<InventoryMovementModel> updateMovement(
    String id,
    UpdateInventoryMovementRequest request,
  );
  
  Future<void> deleteMovement(String id);
  
  Future<InventoryMovementModel> confirmMovement(String id);
  
  Future<InventoryMovementModel> cancelMovement(String id);
  
  Future<List<InventoryMovementModel>> searchMovements(
    SearchInventoryMovementsParams params,
  );

  Future<PaginatedResult<InventoryBalanceModel>> getBalances(
    InventoryBalanceQueryParams params,
  );
  
  Future<InventoryBalanceModel> getBalanceByProduct(
    String productId, {
    String? warehouseId,
  });
  
  Future<List<InventoryBalanceModel>> getBalancesByProducts(
    List<String> productIds, {
    String? warehouseId,
  });
  
  Future<List<InventoryBalanceModel>> getLowStockProducts({
    String? warehouseId,
  });
  
  Future<List<InventoryBalanceModel>> getOutOfStockProducts({
    String? warehouseId,
  });
  
  Future<List<InventoryBalanceModel>> getExpiredProducts({
    String? warehouseId,
  });
  
  Future<List<InventoryBalanceModel>> getNearExpiryProducts({
    String? warehouseId,
    int? daysThreshold,
  });

  Future<List<FifoConsumptionModel>> calculateFifoConsumption(
    String productId,
    int quantity, {
    String? warehouseId,
  });
  
  Future<InventoryMovementModel> processOutboundMovementFifo(
    Map<String, dynamic> request,
  );
  
  Future<List<InventoryMovementModel>> processBulkOutboundMovementFifo(
    List<Map<String, dynamic>> requestsList,
  );

  Future<InventoryMovementModel> createStockAdjustment(
    Map<String, dynamic> request,
  );
  
  Future<List<InventoryMovementModel>> createBulkStockAdjustments(
    List<Map<String, dynamic>> requestsList,
  );

  Future<InventoryMovementModel> createTransfer(
    Map<String, dynamic> request,
  );
  
  Future<InventoryMovementModel> confirmTransfer(String transferId);

  Future<InventoryStatsModel> getInventoryStats(
    InventoryStatsParams params,
  );
  
  Future<Map<String, double>> getInventoryValuation({
    String? warehouseId,
    DateTime? asOfDate,
  });

  Future<KardexReportModel> getKardexReport(
    KardexReportParams params,
  );
  
  Future<List<Map<String, dynamic>>> getInventoryAging({
    String? warehouseId,
  });

  Future<List<Map<String, dynamic>>> getBatches({
    String? productId,
    String? warehouseId,
    String? status,
    String? search,
    bool? activeOnly,
    bool? expiredOnly,
    bool? nearExpiryOnly,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  });

  Future<Map<String, dynamic>> getBatchById(String id);

  Future<List<WarehouseModel>> getWarehouses();
  Future<WarehouseModel> createWarehouse(CreateWarehouseParams params);
  Future<WarehouseModel> updateWarehouse(String id, UpdateWarehouseParams params);
  Future<bool> deleteWarehouse(String id);
  Future<WarehouseModel> getWarehouseById(String id);
  Future<bool> checkWarehouseCodeExists(String code, {String? excludeId});
  Future<bool> checkWarehouseHasMovements(String warehouseId);
  Future<PaginatedResult<InventoryMovementModel>> getWarehouseMovements(String warehouseId, InventoryMovementQueryParams params);
  Future<int> getActiveWarehousesCount();
  Future<WarehouseStatsModel> getWarehouseStats(String warehouseId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final Dio dio;

  InventoryRemoteDataSourceImpl({required this.dio});

  @override
  Future<PaginatedResult<InventoryMovementModel>> getMovements(
    InventoryMovementQueryParams params,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'page': params.page,
        'limit': params.limit,
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };

      if (params.search != null && params.search!.isNotEmpty) {
        queryParams['search'] = params.search;
      }
      if (params.productId != null) queryParams['productId'] = params.productId;
      if (params.type != null) queryParams['type'] = params.type!.backendValue;
      if (params.status != null) queryParams['status'] = params.status!.name;
      if (params.reason != null) queryParams['reason'] = params.reason!.name;
      // Note: warehouseId filter not supported by general movements endpoint - use getWarehouseMovements instead
      // if (params.warehouseId != null) queryParams['warehouseId'] = params.warehouseId;
      if (params.startDate != null) queryParams['startDate'] = params.startDate!.toIso8601String();
      if (params.endDate != null) queryParams['endDate'] = params.endDate!.toIso8601String();
      if (params.referenceId != null) queryParams['referenceId'] = params.referenceId;
      if (params.referenceType != null) queryParams['referenceType'] = params.referenceType;

      final response = await dio.get(
        ApiConstants.inventoryMovements,
        queryParameters: queryParams,
      );

      // El backend devuelve: {success: true, data: {movements: [...], total: number}, timestamp: ...}
      final responseData = response.data['data'];
      final data = responseData['movements'] as List? ?? [];
      final movements = data.map((json) => InventoryMovementModel.fromJson(json)).toList();

      final total = responseData['total'] ?? 0;
      final totalPages = responseData['totalPages'] ?? 1;
      final currentPage = responseData['page'] ?? params.page;

      final meta = PaginationMeta(
        totalItems: total,
        page: currentPage,
        limit: params.limit,
        totalPages: totalPages,
        hasNextPage: currentPage < totalPages,
        hasPreviousPage: currentPage > 1,
      );

      return PaginatedResult(data: movements, meta: meta);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener movimientos: $e');
    }
  }

  @override
  Future<InventoryMovementModel> getMovementById(String id) async {
    try {
      final response = await dio.get('${ApiConstants.inventoryMovements}/$id');
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener movimiento: $e');
    }
  }

  @override
  Future<InventoryMovementModel> createMovement(
    CreateInventoryMovementRequest request,
  ) async {
    try {
      final response = await dio.post(
        ApiConstants.inventoryMovements,
        data: request.toJson(),
      );
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al crear movimiento: $e');
    }
  }

  @override
  Future<InventoryMovementModel> updateMovement(
    String id,
    UpdateInventoryMovementRequest request,
  ) async {
    try {
      final response = await dio.put(
        '${ApiConstants.inventoryMovements}/$id',
        data: request.toJson(),
      );
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al actualizar movimiento: $e');
    }
  }

  @override
  Future<void> deleteMovement(String id) async {
    try {
      await dio.delete('${ApiConstants.inventoryMovements}/$id');
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al eliminar movimiento: $e');
    }
  }

  @override
  Future<InventoryMovementModel> confirmMovement(String id) async {
    try {
      final response = await dio.post(
        '${ApiConstants.inventoryMovements}/$id/confirm',
      );
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al confirmar movimiento: $e');
    }
  }

  @override
  Future<InventoryMovementModel> cancelMovement(String id) async {
    try {
      final response = await dio.post(
        '${ApiConstants.inventoryMovements}/$id/cancel',
      );
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al cancelar movimiento: $e');
    }
  }

  @override
  Future<List<InventoryMovementModel>> searchMovements(
    SearchInventoryMovementsParams params,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'q': params.searchTerm,
        'limit': params.limit,
      };

      if (params.type != null) queryParams['type'] = params.type!.backendValue;
      if (params.warehouseId != null) queryParams['warehouseId'] = params.warehouseId;

      final response = await dio.get(
        '${ApiConstants.inventoryMovements}/search',
        queryParameters: queryParams,
      );

      final data = response.data as List;
      return data.map((json) => InventoryMovementModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado en búsqueda de movimientos: $e');
    }
  }

  @override
  Future<PaginatedResult<InventoryBalanceModel>> getBalances(
    InventoryBalanceQueryParams params,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'page': params.page,
        'limit': params.limit,
        'sortBy': params.sortBy,
        'sortOrder': params.sortOrder,
      };

      if (params.search != null && params.search!.isNotEmpty) {
        queryParams['search'] = params.search;
      }
      if (params.categoryId != null) queryParams['categoryId'] = params.categoryId;
      if (params.warehouseId != null) queryParams['warehouseId'] = params.warehouseId;
      if (params.lowStock != null) queryParams['lowStock'] = params.lowStock;
      if (params.outOfStock != null) queryParams['outOfStock'] = params.outOfStock;
      if (params.nearExpiry != null) queryParams['nearExpiry'] = params.nearExpiry;
      if (params.expired != null) queryParams['expired'] = params.expired;

      final response = await dio.get(
        ApiConstants.inventoryBalances,
        queryParameters: queryParams,
      );

      // El backend devuelve: {success: true, data: {data: [...], total: number}, timestamp: ...}
      final responseData = response.data['data'];
      final data = responseData['data'] as List? ?? [];
      final balances = data.map((json) => InventoryBalanceModel.fromJson(json)).toList();

      final total = responseData['total'] ?? 0;
      final totalPages = responseData['totalPages'] ?? 1;
      final currentPage = responseData['page'] ?? params.page;

      final meta = PaginationMeta(
        totalItems: total,
        page: currentPage,
        limit: params.limit,
        totalPages: totalPages,
        hasNextPage: currentPage < totalPages,
        hasPreviousPage: currentPage > 1,
      );

      return PaginatedResult(data: balances, meta: meta);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener balances: $e');
    }
  }

  @override
  Future<InventoryBalanceModel> getBalanceByProduct(
    String productId, {
    String? warehouseId,
  }) async {
    try {
      // ✅ Usar endpoint de balances que sí filtra por warehouse
      final baseEndpoint = ApiConstants.inventoryBalances;
      final queryParams = <String, dynamic>{
        'productId': productId,
        'page': 1,
        'limit': 1, // Solo necesitamos un resultado
      };
      
      if (warehouseId != null && warehouseId.isNotEmpty) {
        queryParams['warehouseId'] = warehouseId;
      }
      
      // 🔍 DEBUG: Mostrar exactamente qué URL se está llamando
      final fullUrl = '$baseEndpoint?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      
      print('🌐 CALLING INVENTORY BALANCES API:');
      print('   📍 URL: $fullUrl');
      print('   🏬 WarehouseId: ${warehouseId ?? "NULL (getting ALL warehouses)"}');
      print('   📦 ProductId: $productId');
      
      final response = await dio.get(
        baseEndpoint,
        queryParameters: queryParams,
      );
      
      print('📦 INVENTORY BALANCES API RESPONSE:');
      print('   💾 Raw Response: ${response.data}');
      
      // ✅ El endpoint /inventory/balances puede devolver formato paginado: {success: true, data: {data: [array], meta: {...}}}
      // O formato directo: {success: true, data: [array of balances]}
      final responseData = response.data['data'];
      
      List<dynamic> balances;
      if (responseData is Map && responseData.containsKey('data')) {
        // Formato paginado
        balances = responseData['data'] as List<dynamic>;
      } else if (responseData is List) {
        // Formato directo
        balances = responseData;
      } else {
        balances = [];
      }
      
      if (balances.isNotEmpty) {
        // Filtrar balance específico para el producto Y almacén solicitados
        final specificBalance = balances.firstWhere(
          (balance) => balance['productId'] == productId,
          orElse: () => null,
        );
        
        if (specificBalance != null) {
          print('   🏷️  Balance found for product: ${specificBalance['productId']}');
          print('   📊 Available Quantity: ${specificBalance['availableQuantity'] ?? specificBalance['totalQuantity']}');
          print('   🏬 For warehouse: ${warehouseId ?? "ALL_WAREHOUSES"}');
          print('   ✅ Product ${productId} has ${specificBalance['totalQuantity']} units in warehouse ${warehouseId}');
          
          return InventoryBalanceModel.fromJson(specificBalance);
        } else {
          print('   ⚠️ Product $productId NOT FOUND in warehouse $warehouseId balances');
          print('   📋 Available products in response: ${balances.map((b) => b['productId']).toList()}');
          // Crear balance vacío para producto no encontrado en almacén específico
          final emptyBalance = {
            'productId': productId,
            'productName': 'Producto',
            'productSku': '',
            'categoryName': '',
            'totalQuantity': 0,
            'availableQuantity': 0,
            'reservedQuantity': 0,
            'expiredQuantity': 0,
            'nearExpiryQuantity': 0,
            'minStock': 0,
            'averageCost': 0.0,
            'totalValue': 0.0,
            'isLowStock': false,
            'isOutOfStock': true,
            'lastUpdated': DateTime.now().toIso8601String(),
            'fifoLots': [],
          };
          
          return InventoryBalanceModel.fromJson(emptyBalance);
        }
      } else {
        // No hay balance para este producto en este almacén
        print('   ⚠️ No balance found for product $productId in warehouse ${warehouseId ?? "ALL"}');
        
        // Crear un balance vacío
        final emptyBalance = {
          'productId': productId,
          'productName': 'Producto',
          'productSku': '',
          'categoryName': '',
          'totalQuantity': 0,
          'availableQuantity': 0,
          'reservedQuantity': 0,
          'expiredQuantity': 0,
          'nearExpiryQuantity': 0,
          'minStock': 0,
          'averageCost': 0.0,
          'totalValue': 0.0,
          'isLowStock': false,
          'isOutOfStock': true,
          'lastUpdated': DateTime.now().toIso8601String(),
          'fifoLots': [], // Default
        };
        
        return InventoryBalanceModel.fromJson(emptyBalance);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener balance del producto: $e');
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getLowStockProducts({
    String? warehouseId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;

      final response = await dio.get(
        '${ApiConstants.inventoryBalances}/low-stock',
        queryParameters: queryParams,
      );

      final data = response.data as List;
      return data.map((json) => InventoryBalanceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener productos con stock bajo: $e');
    }
  }

  @override
  Future<List<FifoConsumptionModel>> calculateFifoConsumption(
    String productId,
    int quantity, {
    String? warehouseId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'quantity': quantity,
      };
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;

      final response = await dio.get(
        '${ApiConstants.inventoryBalances}/product/$productId/fifo-consumption',
        queryParameters: queryParams,
      );

      final data = response.data as List;
      return data.map((json) => FifoConsumptionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al calcular consumo FIFO: $e');
    }
  }

  @override
  Future<InventoryStatsModel> getInventoryStats(
    InventoryStatsParams params,
  ) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (params.startDate != null) {
        queryParams['startDate'] = params.startDate!.toIso8601String();
      }
      if (params.endDate != null) {
        queryParams['endDate'] = params.endDate!.toIso8601String();
      }
      if (params.warehouseId != null) {
        queryParams['warehouseId'] = params.warehouseId;
      }
      if (params.categoryId != null) {
        queryParams['categoryId'] = params.categoryId;
      }

      print('🔍 DEBUG: About to call dio.get with URL: ${ApiConstants.inventoryStats}');
      print('🔍 DEBUG: queryParams: $queryParams');
      print('🔍 DEBUG: dio instance: ${dio.runtimeType}');
      print('🔍 DEBUG: dio base url: ${dio.options.baseUrl}');
      
      final response;
      try {
        response = await dio.get(
          ApiConstants.inventoryStats,
          queryParameters: queryParams,
        );
        print('🔍 DEBUG: dio.get completed with status: ${response.statusCode}');
      } catch (dioError) {
        print('❌ DEBUG: dio.get failed with error: $dioError');
        print('❌ DEBUG: dio error type: ${dioError.runtimeType}');
        rethrow;
      }

      print('🔍 DEBUG getInventoryStats response:');
      print('   Response status: ${response.statusCode}');
      print('   Response data: ${response.data}');
      print('   Response data type: ${response.data.runtimeType}');
      if (response.data is Map) {
        print('   Response keys: ${(response.data as Map).keys.toList()}');
        print('   data field: ${response.data['data']}');
        print('   data field type: ${response.data['data'].runtimeType}');
      }

      // El backend devuelve: {success: true, data: {...}, timestamp: ...}
      final dataField = response.data['data'];
      if (dataField == null) {
        throw Exception('Backend returned null data field');
      }
      
      print('🔍 DEBUG: About to parse dataField: $dataField');
      print('🔍 DEBUG: dataField type: ${dataField.runtimeType}');
      
      try {
        final model = InventoryStatsModel.fromJson(dataField);
        print('✅ DEBUG: InventoryStatsModel parsed successfully: $model');
        return model;
      } catch (parseError) {
        print('❌ DEBUG: InventoryStatsModel.fromJson failed: $parseError');
        print('❌ DEBUG: Parse error type: ${parseError.runtimeType}');
        rethrow;
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener estadísticas de inventario: $e');
    }
  }

  // Implement other methods...
  @override
  Future<List<InventoryBalanceModel>> getBalancesByProducts(
    List<String> productIds, {
    String? warehouseId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'productIds': productIds.join(','),
      };
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;

      final response = await dio.get(
        '${ApiConstants.inventoryBalances}/products',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List;
      return data.map((json) => InventoryBalanceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener balances de productos: $e');
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getOutOfStockProducts({
    String? warehouseId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;

      final response = await dio.get(
        '${ApiConstants.inventoryBalances}/out-of-stock',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List;
      return data.map((json) => InventoryBalanceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener productos sin stock: $e');
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getExpiredProducts({
    String? warehouseId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;

      final response = await dio.get(
        '${ApiConstants.inventoryBalances}/expired',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List;
      return data.map((json) => InventoryBalanceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener productos vencidos: $e');
    }
  }

  @override
  Future<List<InventoryBalanceModel>> getNearExpiryProducts({
    String? warehouseId,
    int? daysThreshold,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;
      if (daysThreshold != null) queryParams['daysThreshold'] = daysThreshold;

      final response = await dio.get(
        '${ApiConstants.inventoryBalances}/near-expiry',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List;
      return data.map((json) => InventoryBalanceModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener productos próximos a vencer: $e');
    }
  }

  @override
  Future<InventoryMovementModel> processOutboundMovementFifo(
    Map<String, dynamic> request,
  ) async {
    try {
      final response = await dio.post(
        '${ApiConstants.inventoryMovements}/process-outbound-fifo',
        data: request,
      );
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al procesar movimiento FIFO: $e');
    }
  }

  @override
  Future<List<InventoryMovementModel>> processBulkOutboundMovementFifo(
    List<Map<String, dynamic>> requestsList,
  ) async {
    try {
      final response = await dio.post(
        '${ApiConstants.inventoryMovements}/process-bulk-outbound-fifo',
        data: {'movements': requestsList},
      );
      final data = response.data['data'] as List;
      return data.map((json) => InventoryMovementModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al procesar movimientos FIFO en lote: $e');
    }
  }

  @override
  Future<InventoryMovementModel> createStockAdjustment(
    Map<String, dynamic> request,
  ) async {
    try {
      print('📝 Ajuste individual - Datos enviados: $request');
      
      // ✅ USANDO EL MISMO ENDPOINT QUE AJUSTES MASIVOS
      final response = await dio.post(
        ApiConstants.createStockAdjustment, // /inventory/adjustments/relative
        data: request,
      );
      
      print('📊 Ajuste individual - Respuesta: ${response.data}');
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al crear ajuste de stock: $e');
    }
  }

  @override
  Future<List<InventoryMovementModel>> createBulkStockAdjustments(
    List<Map<String, dynamic>> requestsList,
  ) async {
    try {
      print('🔧 Iniciando ajustes masivos: ${requestsList.length} ajustes');
      
      final List<InventoryMovementModel> results = [];
      
      // Hacer llamadas individuales para cada ajuste usando el endpoint correcto
      for (int i = 0; i < requestsList.length; i++) {
        final request = requestsList[i];
        
        print('🔄 Procesando ajuste ${i + 1}/${requestsList.length}: ${request['productId']}');
        
        // Mapear los parámetros al formato esperado por /inventory/adjustments/relative
        final adjustmentData = {
          'productId': request['productId'],
          'adjustmentQuantity': request['adjustmentQuantity'],
          'warehouseId': request['warehouseId'],
          'notes': request['notes'],
          'movementDate': request['movementDate'], // Ya viene como String ISO desde el repositorio
          'unitCost': request['unitCost'] ?? 0.0, // Ya viene calculado desde el controlador
        };
        
        print('📝 Datos del ajuste a enviar: $adjustmentData');
        
        try {
          final response = await dio.post(
            ApiConstants.createStockAdjustment,
            data: adjustmentData,
          );
          
          print('✅ Ajuste ${i + 1} completado para producto ${request['productId']}');
          print('📊 Respuesta del backend: ${response.data}');
          
          // El endpoint /adjustments/relative devuelve el movimiento creado
          final movementData = response.data['data'];
          print('📋 Datos del movimiento: $movementData');
          
          final movement = InventoryMovementModel.fromJson(movementData);
          print('🎯 Movimiento creado - Estado: ${movement.statusString}, Cantidad: ${movement.quantity}');
          
          results.add(movement);
          
        } catch (e) {
          print('❌ Error en ajuste ${i + 1} para producto ${request['productId']}: $e');
          // Si un ajuste falla, continuar con los demás pero loggear el error
          rethrow; // Re-lanzar para detener el proceso completo si hay error
        }
      }
      
      print('🎉 Ajustes masivos completados: ${results.length} exitosos');
      return results;
      
    } on DioException catch (e) {
      print('❌ Error DIO en ajustes masivos: ${e.message}');
      throw _handleDioException(e);
    } catch (e) {
      print('❌ Error inesperado en ajustes masivos: $e');
      throw Exception('Error inesperado al crear ajustes de stock en lote: $e');
    }
  }

  @override
  Future<InventoryMovementModel> createTransfer(
    Map<String, dynamic> request,
  ) async {
    try {
      final items = request['items'] as List<Map<String, dynamic>>;
      
      print('🚀 Creating transfer with ${items.length} items: $items');
      
      // For now, handle multiple products by creating separate transfers
      // TODO: Check if backend supports multiple products in single transfer
      InventoryMovementModel? mainTransfer;
      
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        
        final transferRequest = {
          'productId': item['productId'],
          'quantity': item['quantity'],
          'fromWarehouseId': request['fromWarehouseId'],
          'toWarehouseId': request['toWarehouseId'],
          'notes': items.length > 1 
            ? 'Transfer between warehouses (${i + 1}/${items.length})'
            : 'Transfer between warehouses',
        };
        
        print('🔄 Creating transfer ${i + 1}/${items.length}: $transferRequest');
        
        final response = await dio.post(
          ApiConstants.inventoryTransfers,
          data: transferRequest,
        );
        
        print('✅ Transfer ${i + 1}/${items.length} created successfully');
        
        // Return the first transfer as the main response
        if (i == 0) {
          mainTransfer = InventoryMovementModel.fromJson(response.data['transferOut']);
        }
      }
      
      print('✅ All ${items.length} transfers created successfully');
      return mainTransfer!;
      
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al crear transferencia: $e');
    }
  }

  @override
  Future<InventoryMovementModel> confirmTransfer(String transferId) async {
    try {
      final response = await dio.post(
        '${ApiConstants.inventoryMovements}/transfer/$transferId/confirm',
      );
      return InventoryMovementModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al confirmar transferencia: $e');
    }
  }

  @override
  Future<Map<String, double>> getInventoryValuation({
    String? warehouseId,
    DateTime? asOfDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;
      if (asOfDate != null) queryParams['asOfDate'] = asOfDate.toIso8601String();

      final response = await dio.get(
        '${ApiConstants.inventoryBalances}/valuation',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>;
      return Map<String, double>.from(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener valoración de inventario: $e');
    }
  }

  @override
  Future<KardexReportModel> getKardexReport(
    KardexReportParams params,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'startDate': params.startDate.toIso8601String().split('T')[0],
        'endDate': params.endDate.toIso8601String().split('T')[0],
        'includeBatchDetails': true,
      };
      
      if (params.warehouseId != null) {
        queryParams['warehouseId'] = params.warehouseId;
      }

      final response = await dio.get(
        '/reports/kardex/product/${params.productId}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          final kardexData = data['data'];
          return KardexReportModel.fromJson(kardexData);
        } else {
          throw Exception('API response indicates failure: ${data?['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener reporte kardex: $e');
    }
  }


  @override
  Future<List<Map<String, dynamic>>> getInventoryAging({
    String? warehouseId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;

      final response = await dio.get(
        '/reports/inventory-aging',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener reporte de antigüedad: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBatches({
    String? productId,
    String? warehouseId,
    String? status,
    String? search,
    bool? activeOnly,
    bool? expiredOnly,
    bool? nearExpiryOnly,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (productId != null) queryParams['productId'] = productId;
      if (warehouseId != null) queryParams['warehouseId'] = warehouseId;
      if (status != null) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (activeOnly == true) queryParams['activeOnly'] = true;
      if (expiredOnly == true) queryParams['expiredOnly'] = true;
      if (nearExpiryOnly == true) queryParams['nearExpiryOnly'] = true;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      
      print('🔍 DATASOURCE DEBUG: Enviando queryParams: $queryParams');
      
      final response = await dio.get(
        '/inventory/batches',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        throw Exception('Error al obtener lotes: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener lotes: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getBatchById(String id) async {
    try {
      final response = await dio.get('/inventory/batches/$id');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        }
        throw Exception('Lote no encontrado');
      } else {
        throw Exception('Error al obtener lote: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error inesperado al obtener lote: $e');
    }
  }

  // Helper method to handle Dio exceptions
  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Tiempo de espera agotado. Verifica tu conexión.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error del servidor';
        return Exception('Error $statusCode: $message');
      case DioExceptionType.cancel:
        return Exception('Operación cancelada');
      case DioExceptionType.connectionError:
        return Exception('Error de conexión. Verifica tu conexión a internet.');
      default:
        return Exception('Error inesperado: ${e.message}');
    }
  }

  @override
  Future<List<WarehouseModel>> getWarehouses() async {
    try {
      final response = await dio.get('/warehouses');
      
      // El backend ahora devuelve: {"data": {"warehouses": [...], "total": 3}}
      final responseData = response.data['data'];
      final List<dynamic> data;
      
      if (responseData is Map && responseData.containsKey('warehouses')) {
        // Formato nuevo: {"data": {"warehouses": [...], "total": 3}}
        data = responseData['warehouses'] as List<dynamic>;
      } else if (responseData is List) {
        // Formato antiguo: {"data": [...]}
        data = responseData;
      } else {
        // Fallback
        data = response.data is List ? response.data : [];
      }
      
      return data.map((json) => WarehouseModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al obtener almacenes: $e');
    }
  }

  @override
  Future<WarehouseModel> createWarehouse(CreateWarehouseParams params) async {
    try {
      final response = await dio.post('/warehouses', data: params.toJson());
      final data = response.data['data'] ?? response.data;
      
      return WarehouseModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al crear almacén: $e');
    }
  }

  @override
  Future<WarehouseModel> updateWarehouse(String id, UpdateWarehouseParams params) async {
    try {
      final response = await dio.patch('/warehouses/$id', data: params.toJson());
      final data = response.data['data'] ?? response.data;
      
      return WarehouseModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al actualizar almacén: $e');
    }
  }

  @override
  Future<bool> deleteWarehouse(String id) async {
    try {
      await dio.delete('/warehouses/$id');
      return true;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al eliminar almacén: $e');
    }
  }

  @override
  Future<WarehouseModel> getWarehouseById(String id) async {
    try {
      final response = await dio.get('/warehouses/$id');
      final data = response.data['data'] ?? response.data;
      
      return WarehouseModel.fromJson(data);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al obtener almacén: $e');
    }
  }

  @override
  Future<bool> checkWarehouseCodeExists(String code, {String? excludeId}) async {
    try {
      final queryParams = <String, dynamic>{'code': code};
      if (excludeId != null) {
        queryParams['excludeId'] = excludeId;
      }
      
      final response = await dio.get('/warehouses/check-code', queryParameters: queryParams);
      
      return response.data['data']['exists'] as bool;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al verificar código de almacén: $e');
    }
  }

  @override
  Future<bool> checkWarehouseHasMovements(String warehouseId) async {
    try {
      final response = await dio.get('/warehouses/$warehouseId/has-movements');
      
      return response.data['data']['hasMovements'] as bool;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al verificar movimientos del almacén: $e');
    }
  }

  @override
  Future<PaginatedResult<InventoryMovementModel>> getWarehouseMovements(
    String warehouseId, 
    InventoryMovementQueryParams params,
  ) async {
    try {
      // First try the specific warehouse endpoint
      return await _tryWarehouseSpecificEndpoint(warehouseId, params);
    } on DioException catch (e) {
      // If 404, fallback to general endpoint with warehouseId filter
      if (e.response?.statusCode == 404) {
        print('🔄 Warehouse-specific endpoint not available, falling back to general endpoint with filter');
        return await _fallbackToGeneralEndpoint(warehouseId, params);
      }
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al obtener movimientos del almacén: $e');
    }
  }

  Future<PaginatedResult<InventoryMovementModel>> _tryWarehouseSpecificEndpoint(
    String warehouseId, 
    InventoryMovementQueryParams params,
  ) async {
    final queryParams = <String, dynamic>{
      'page': params.page,
      'limit': params.limit,
      'sortBy': params.sortBy,
      'sortOrder': params.sortOrder,
    };

    if (params.search != null && params.search!.isNotEmpty) {
      queryParams['search'] = params.search;
    }
    if (params.productId != null) queryParams['productId'] = params.productId;
    if (params.type != null) queryParams['type'] = params.type!.name;
    if (params.status != null) queryParams['status'] = params.status!.name;
    if (params.reason != null) queryParams['reason'] = params.reason!.name;
    if (params.startDate != null) queryParams['startDate'] = params.startDate!.toIso8601String();
    if (params.endDate != null) queryParams['endDate'] = params.endDate!.toIso8601String();
    if (params.referenceId != null) queryParams['referenceId'] = params.referenceId;
    if (params.referenceType != null) queryParams['referenceType'] = params.referenceType;

    final response = await dio.get('/warehouses/$warehouseId/movements', queryParameters: queryParams);
    
    // El backend devuelve: {success: true, data: {movements: [...], total: number}, timestamp: ...}
    final responseData = response.data['data'];
    final data = responseData['movements'] as List? ?? responseData as List? ?? [];
    final movements = data.map((json) => InventoryMovementModel.fromJson(json)).toList();

    final total = responseData['total'] ?? movements.length;
    final totalPages = responseData['totalPages'] ?? 1;
    final currentPage = responseData['page'] ?? params.page;

    final meta = PaginationMeta(
      totalItems: total,
      page: currentPage,
      limit: params.limit,
      totalPages: totalPages,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );

    return PaginatedResult(data: movements, meta: meta);
  }

  Future<PaginatedResult<InventoryMovementModel>> _fallbackToGeneralEndpoint(
    String warehouseId, 
    InventoryMovementQueryParams params,
  ) async {
    final queryParams = <String, dynamic>{
      'page': params.page,
      'limit': params.limit,
      'sortBy': params.sortBy,
      'sortOrder': params.sortOrder,
      'warehouseId': warehouseId, // Add warehouseId as filter
    };

    if (params.search != null && params.search!.isNotEmpty) {
      queryParams['search'] = params.search;
    }
    if (params.productId != null) queryParams['productId'] = params.productId;
    if (params.type != null) queryParams['type'] = params.type!.name;
    if (params.status != null) queryParams['status'] = params.status!.name;
    if (params.reason != null) queryParams['reason'] = params.reason!.name;
    if (params.startDate != null) queryParams['startDate'] = params.startDate!.toIso8601String();
    if (params.endDate != null) queryParams['endDate'] = params.endDate!.toIso8601String();
    if (params.referenceId != null) queryParams['referenceId'] = params.referenceId;
    if (params.referenceType != null) queryParams['referenceType'] = params.referenceType;

    final response = await dio.get(
      ApiConstants.inventoryMovements,
      queryParameters: queryParams,
    );

    // El backend devuelve: {success: true, data: {movements: [...], total: number}, timestamp: ...}
    final responseData = response.data['data'];
    final data = responseData['movements'] as List? ?? [];
    final movements = data.map((json) => InventoryMovementModel.fromJson(json)).toList();

    final total = responseData['total'] ?? 0;
    final totalPages = responseData['totalPages'] ?? 1;
    final currentPage = responseData['page'] ?? params.page;

    final meta = PaginationMeta(
      totalItems: total,
      page: currentPage,
      limit: params.limit,
      totalPages: totalPages,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
    );

    return PaginatedResult(data: movements, meta: meta);
  }

  @override
  Future<int> getActiveWarehousesCount() async {
    try {
      final response = await dio.get('/warehouses/count/active');
      
      return response.data['data']['count'] as int;
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al contar almacenes activos: $e');
    }
  }

  @override
  Future<WarehouseStatsModel> getWarehouseStats(String warehouseId) async {
    try {
      final response = await dio.get('/warehouses/$warehouseId/stats');
      
      return WarehouseStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error al obtener estadísticas del almacén: $e');
    }
  }
}