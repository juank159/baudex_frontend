// lib/features/products/data/datasources/product_remote_datasource.dart
import 'package:baudex_desktop/features/products/data/models/product_stats_model.dart';
import 'package:dio/dio.dart';

import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/product_model.dart';
import '../models/product_response_model.dart';
import '../models/product_query_model.dart';
import '../models/create_product_request_model.dart';
import '../models/update_product_request_model.dart';

/// Contrato para el datasource remoto de productos
abstract class ProductRemoteDataSource {
  Future<ProductResponseModel> getProducts(ProductQueryModel query);
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> getProductBySku(String sku);
  Future<ProductModel> getProductByBarcode(String barcode);
  Future<ProductModel> findBySkuOrBarcode(String code);
  Future<List<ProductModel>> searchProducts(String searchTerm, int limit);
  Future<List<ProductModel>> getLowStockProducts();
  Future<List<ProductModel>> getOutOfStockProducts();
  Future<List<ProductModel>> getProductsByCategory(String categoryId);
  Future<ProductStatsModel> getProductStats();
  Future<double> getInventoryValue();
  Future<ProductModel> createProduct(CreateProductRequestModel request);
  Future<ProductModel> updateProduct(
    String id,
    UpdateProductRequestModel request,
  );
  Future<ProductModel> updateProductStatus(String id, String status);
  Future<ProductModel> updateProductStock(
    String id,
    double quantity,
    String operation,
  );
  Future<void> deleteProduct(String id);
  Future<ProductModel> restoreProduct(String id);
  Future<bool> validateStockForSale(String productId, double quantity);
  Future<void> reduceStockForSale(String productId, double quantity);
}

/// Implementación del datasource remoto usando Dio
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final DioClient dioClient;

  const ProductRemoteDataSourceImpl({required this.dioClient});

  // ==================== READ OPERATIONS ====================

  @override
  Future<ProductResponseModel> getProducts(ProductQueryModel query) async {
    try {
      final response = await dioClient.get(
        '/products',
        queryParameters: query.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        return ProductResponseModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener productos: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await dioClient.get('/products/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener producto: $e');
    }
  }

  @override
  Future<ProductModel> getProductBySku(String sku) async {
    try {
      final response = await dioClient.get('/products/sku/$sku');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener producto por SKU: $e');
    }
  }

  @override
  Future<ProductModel> getProductByBarcode(String barcode) async {
    try {
      final response = await dioClient.get('/products/barcode/$barcode');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener producto por código de barras: $e',
      );
    }
  }

  @override
  Future<ProductModel> findBySkuOrBarcode(String code) async {
    try {
      // Nota: Ajusta esta ruta según tu backend - podría ser diferente
      final response = await dioClient.get('/products/find/$code');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al buscar producto: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(
    String searchTerm,
    int limit,
  ) async {
    try {
      final response = await dioClient.get(
        '/products/search',
        queryParameters: {'term': searchTerm, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => ProductModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado en búsqueda: $e');
    }
  }

  @override
  Future<List<ProductModel>> getLowStockProducts() async {
    try {
      final response = await dioClient.get('/products/low-stock');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => ProductModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener productos con stock bajo: $e',
      );
    }
  }

  @override
  Future<List<ProductModel>> getOutOfStockProducts() async {
    try {
      final response = await dioClient.get('/products/out-of-stock');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => ProductModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener productos sin stock: $e',
      );
    }
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await dioClient.get('/products/category/$categoryId');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => ProductModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener productos por categoría: $e',
      );
    }
  }

  @override
  Future<ProductStatsModel> getProductStats() async {
    try {
      print('🌐 ProductRemoteDataSource: Solicitando estadísticas...');

      final response = await dioClient.get('/products/stats');
      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData != null && responseData is Map<String, dynamic>) {
          if (responseData['success'] == true && responseData['data'] != null) {
            var statsData = responseData['data'];

            // ✅ MANEJO DEL DOBLE WRAPPING (como ya tienes)
            if (statsData is Map<String, dynamic> &&
                statsData.containsKey('success') &&
                statsData.containsKey('data') &&
                statsData['data'] is Map<String, dynamic>) {
              print(
                '🔧 Detectado doble wrapping, extrayendo datos anidados...',
              );
              statsData = statsData['data'] as Map<String, dynamic>;
            }

            print('📊 Stats data final: $statsData');

            final model = ProductStatsModel.fromJson(statsData);

            // ✅ VALIDACIÓN ADICIONAL
            if (!model.isValid) {
              throw ServerException('Datos de estadísticas inválidos');
            }

            return model;
          }
        }

        throw ServerException('Respuesta inválida del servidor');
      } else {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      print('❌ Error en getProductStats: $e');
      rethrow;
    }
  }

  @override
  Future<double> getInventoryValue() async {
    try {
      final response = await dioClient.get('/products/inventory/value');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data']['value'] as num).toDouble();
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener valor del inventario: $e',
      );
    }
  }

  @override
  Future<ProductModel> createProduct(CreateProductRequestModel request) async {
    try {
      print('🌐 Enviando petición CREATE PRODUCT...');
      print('📋 Request data: ${request.toJson()}');

      final response = await dioClient.post(
        '/products',
        data: request.toJson(),
      );

      print('✅ Response status: ${response.statusCode}');
      print('📋 Response data keys: ${response.data?.keys?.toList()}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;

        // ✅ CORRECCIÓN: Verificación más robusta de la respuesta
        if (responseData != null && responseData is Map<String, dynamic>) {
          if (responseData['success'] == true && responseData['data'] != null) {
            print('🔍 Procesando data del producto...');
            final productData = responseData['data'] as Map<String, dynamic>;

            // ✅ CORRECCIÓN: Añadir logs para debug
            print('📋 Product data keys: ${productData.keys.toList()}');

            // ✅ CORRECCIÓN: Enriquecer datos si faltan campos requeridos
            final enrichedProductData = Map<String, dynamic>.from(productData);

            // Asegurar que los campos de fecha existan
            if (!enrichedProductData.containsKey('createdAt') ||
                enrichedProductData['createdAt'] == null) {
              enrichedProductData['createdAt'] =
                  DateTime.now().toIso8601String();
            }
            if (!enrichedProductData.containsKey('updatedAt') ||
                enrichedProductData['updatedAt'] == null) {
              enrichedProductData['updatedAt'] =
                  DateTime.now().toIso8601String();
            }

            // Enriquecer precios con productId si no lo tienen
            if (enrichedProductData['prices'] != null &&
                enrichedProductData['prices'] is List) {
              final prices = enrichedProductData['prices'] as List;
              for (int i = 0; i < prices.length; i++) {
                if (prices[i] is Map<String, dynamic>) {
                  final priceMap = prices[i] as Map<String, dynamic>;
                  if (!priceMap.containsKey('productId') ||
                      priceMap['productId'] == null) {
                    priceMap['productId'] = enrichedProductData['id'];
                  }
                  if (!priceMap.containsKey('createdAt') ||
                      priceMap['createdAt'] == null) {
                    priceMap['createdAt'] = DateTime.now().toIso8601String();
                  }
                  if (!priceMap.containsKey('updatedAt') ||
                      priceMap['updatedAt'] == null) {
                    priceMap['updatedAt'] = DateTime.now().toIso8601String();
                  }
                }
              }
            }

            print('✅ Creando ProductModel...');
            return ProductModel.fromJson(enrichedProductData);
          } else {
            print(
              '❌ Respuesta inválida: success=${responseData['success']}, data=${responseData['data']}',
            );
            throw ServerException(
              'Respuesta inválida del servidor: estructura incorrecta',
            );
          }
        } else {
          print('❌ Response data es null o no es Map');
          throw ServerException(
            'Respuesta inválida del servidor: data es null',
          );
        }
      } else {
        print('❌ Status code inesperado: ${response.statusCode}');
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      print('❌ DioException en createProduct: $e');
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      print('❌ Error inesperado en createProduct: $e');
      print('🔍 StackTrace: $stackTrace');
      // 🔒 CRITICAL FIX: Check if it's a ServerException and preserve statusCode
      if (e is ServerException) {
        rethrow; // Re-throw with original statusCode
      }
      throw ServerException('Error inesperado al crear producto: $e');
    }
  }

  // @override
  // Future<ProductModel> updateProduct(
  //   String id,
  //   UpdateProductRequestModel request,
  // ) async {
  //   try {
  //     print('🌐 Enviando petición UPDATE PRODUCT (PUT)...');
  //     print('📋 Request data: ${request.toJson()}');

  //     final response = await dioClient.put(
  //       '/products/$id',
  //       data: request.toJson(),
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = response.data;
  //       if (responseData['success'] == true && responseData['data'] != null) {
  //         return ProductModel.fromJson(responseData['data']);
  //       } else {
  //         throw ServerException('Respuesta inválida del servidor');
  //       }
  //     } else {
  //       throw _handleErrorResponse(response);
  //     }
  //   } on DioException catch (e) {
  //     throw _handleDioException(e);
  //   } catch (e) {
  //     throw ServerException('Error inesperado al actualizar producto: $e');
  //   }
  // }

  // ==================== CORRECCIÓN EN product_remote_datasource.dart ====================

  // En tu product_remote_datasource.dart, reemplaza el método updateProduct:

  @override
  Future<ProductModel> updateProduct(
    String id,
    UpdateProductRequestModel request,
  ) async {
    try {
      print('🌐 Enviando petición UPDATE PRODUCT...');
      print('📋 Request ID: $id');
      print('📋 Request data: ${request.toJson()}');

      // ✅ VERIFICAR QUE LOS PRECIOS SE INCLUYAN
      final requestData = request.toJson();
      if (requestData.containsKey('prices') && requestData['prices'] != null) {
        print(
          '🏷️ Precios incluidos en la petición: ${requestData['prices'].length}',
        );
        for (int i = 0; i < requestData['prices'].length; i++) {
          final price = requestData['prices'][i];
          print(
            '   Precio $i: ${price['type']} - \$${price['amount']} ${price['currency']} - ID: ${price['id'] ?? "NUEVO"}',
          );
        }
      } else {
        print('⚠️ NO SE ENCONTRARON PRECIOS EN LA PETICIÓN');
      }

      // ✅ USAR PUT en lugar de PATCH para enviar datos completos
      final response = await dioClient.put('/products/$id', data: requestData);

      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // ✅ VERIFICACIÓN MEJORADA DE LA RESPUESTA
        if (responseData != null &&
            responseData['success'] == true &&
            responseData['data'] != null) {
          final productData = responseData['data'];
          print('📋 Response data keys: ${productData.keys?.toList()}');

          // ✅ VERIFICAR QUE LA RESPUESTA INCLUYA PRECIOS ACTUALIZADOS
          if (productData['prices'] != null && productData['prices'] is List) {
            final prices = productData['prices'] as List;
            print('✅ Respuesta incluye ${prices.length} precios:');
            for (var price in prices) {
              print(
                '   - ${price['type']}: \$${price['amount']} ${price['currency']} (ID: ${price['id']})',
              );
            }
          } else {
            print('⚠️ Respuesta NO incluye precios o no es una lista');
          }

          return ProductModel.fromJson(productData);
        } else {
          print('❌ Estructura de respuesta inválida');
          print('   success: ${responseData?['success']}');
          print(
            '   data: ${responseData?['data'] != null ? 'presente' : 'null'}',
          );
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        print('❌ Status code inesperado: ${response.statusCode}');
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      print('❌ DioException en updateProduct: $e');
      print('   Response data: ${e.response?.data}');
      print('   Status code: ${e.response?.statusCode}');
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      print('❌ Error inesperado en updateProduct: $e');
      print('🔍 StackTrace: $stackTrace');
      // 🔒 CRITICAL FIX: Check if it's a ServerException and preserve statusCode
      if (e is ServerException) {
        rethrow; // Re-throw with original statusCode
      }
      throw ServerException('Error inesperado al actualizar producto: $e');
    }
  }

  @override
  Future<ProductModel> updateProductStatus(String id, String status) async {
    try {
      final response = await dioClient.patch(
        '/products/$id/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al actualizar estado: $e');
    }
  }

  @override
  Future<ProductModel> updateProductStock(
    String id,
    double quantity,
    String operation,
  ) async {
    try {
      final response = await dioClient.patch(
        '/products/$id/stock',
        data: {'quantity': quantity, 'operation': operation},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al actualizar stock: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final response = await dioClient.delete('/products/$id');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al eliminar producto: $e');
    }
  }

  @override
  Future<ProductModel> restoreProduct(String id) async {
    try {
      final response = await dioClient.post('/products/$id/restore');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ProductModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al restaurar producto: $e');
    }
  }

  // ==================== STOCK OPERATIONS ====================

  @override
  Future<bool> validateStockForSale(String productId, double quantity) async {
    try {
      final response = await dioClient.post(
        '/products/$productId/validate-stock',
        data: {'quantity': quantity},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['valid'] as bool? ?? false;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al validar stock: $e');
    }
  }

  @override
  Future<void> reduceStockForSale(String productId, double quantity) async {
    try {
      final response = await dioClient.post(
        '/products/$productId/reduce-stock',
        data: {'quantity': quantity},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al reducir stock: $e');
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Manejar errores de respuesta HTTP
  ServerException _handleErrorResponse(Response response) {
    try {
      final errorData = response.data;
      final message = errorData['message'] ?? 'Error del servidor';
      return ServerException(message, statusCode: response.statusCode);
    } catch (e) {
      return ServerException(
        'Error del servidor: ${response.statusMessage}',
        statusCode: response.statusCode,
      );
    }
  }

  /// Manejar excepciones de Dio
  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectionException('Tiempo de conexión agotado');

      case DioExceptionType.badResponse:
        if (e.response != null) {
          return _handleErrorResponse(e.response!);
        }
        return const ServerException('Respuesta inválida del servidor');

      case DioExceptionType.cancel:
        return const ServerException('Solicitud cancelada');

      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          return const ConnectionException('Sin conexión a internet');
        }
        return ServerException('Error de conexión: ${e.message}');

      default:
        return ServerException('Error desconocido: ${e.message}');
    }
  }
}
