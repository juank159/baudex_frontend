// lib/features/categories/data/datasources/category_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../models/category_response_model.dart';
import '../models/create_category_request_model.dart';
import '../models/update_category_request_model.dart';
import '../models/category_query_model.dart';
import '../models/category_stats_model.dart';
import '../models/api_error_model.dart';

/// Contrato para el datasource remoto de categorías
abstract class CategoryRemoteDataSource {
  Future<CategoryResponseModel> getCategories(CategoryQueryModel query);
  Future<CategoryModel> getCategoryById(String id);
  Future<CategoryModel> getCategoryBySlug(String slug);
  Future<List<CategoryModel>> getCategoryTree();
  Future<CategoryStatsModel> getCategoryStats();
  Future<List<CategoryModel>> searchCategories(String searchTerm, int limit);
  Future<CategoryModel> createCategory(CreateCategoryRequestModel request);
  Future<CategoryModel> updateCategory(
    String id,
    UpdateCategoryRequestModel request,
  );
  Future<CategoryModel> updateCategoryStatus(String id, String status);
  Future<void> deleteCategory(String id);
  Future<CategoryModel> restoreCategory(String id);
  Future<bool> isSlugAvailable(String slug, String? excludeId);
  Future<String> generateUniqueSlug(String name);
  Future<void> reorderCategories(List<Map<String, dynamic>> reorders);
}

/// Implementación del datasource remoto usando Dio
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final DioClient dioClient;

  const CategoryRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<CategoryResponseModel> getCategories(CategoryQueryModel query) async {
    try {
      final response = await dioClient.get(
        ApiConstants.categories,
        queryParameters: query.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        return CategoryResponseModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener categorías: $e');
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await dioClient.get('${ApiConstants.categories}/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CategoryModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener categoría: $e');
    }
  }

  @override
  Future<CategoryModel> getCategoryBySlug(String slug) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.categories}/slug/$slug',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CategoryModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener categoría: $e');
    }
  }

  // @override
  // Future<List<CategoryModel>> getCategoryTree() async {
  //   try {
  //     final response = await dioClient.get('${ApiConstants.categories}/tree');

  //     if (response.statusCode == 200) {
  //       final responseData = response.data;
  //       if (responseData['success'] == true && responseData['data'] != null) {
  //         return (responseData['data'] as List)
  //             .map(
  //               (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
  //             )
  //             .toList();
  //       } else {
  //         throw ServerException('Respuesta inválida del servidor');
  //       }
  //     } else {
  //       throw _handleErrorResponse(response);
  //     }
  //   } on DioException catch (e) {
  //     throw _handleDioException(e);
  //   } catch (e) {
  //     throw ServerException(
  //       'Error inesperado al obtener árbol de categorías: $e',
  //     );
  //   }
  // }

  @override
  Future<List<CategoryModel>> getCategoryTree() async {
    try {
      final response = await dioClient.get('${ApiConstants.categories}/tree');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          final dataList = responseData['data'] as List;
          return dataList.map((json) {
            return CategoryModel.fromJson(json as Map<String, dynamic>);
          }).toList();
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      // 🔒 CRITICAL: Preservar statusCode original si es ServerException
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(
        'Error inesperado al obtener árbol de categorías: $e',
      );
    }
  }

  @override
  Future<CategoryStatsModel> getCategoryStats() async {
    try {
      final response = await dioClient.get('${ApiConstants.categories}/stats');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CategoryStatsModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener estadísticas: $e');
    }
  }

  @override
  Future<List<CategoryModel>> searchCategories(
    String searchTerm,
    int limit,
  ) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.categories}/search',
        queryParameters: {'q': searchTerm, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
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
  Future<CategoryModel> createCategory(
    CreateCategoryRequestModel request,
  ) async {
    try {
      final response = await dioClient.post(
        ApiConstants.categories,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CategoryModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      // 🔒 CRITICAL: Preservar statusCode original si es ServerException
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException('Error inesperado al crear categoría: $e');
    }
  }

  @override
  Future<CategoryModel> updateCategory(
    String id,
    UpdateCategoryRequestModel request,
  ) async {
    try {
      final response = await dioClient.patch(
        '${ApiConstants.categories}/$id',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CategoryModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al actualizar categoría: $e');
    }
  }

  @override
  Future<CategoryModel> updateCategoryStatus(String id, String status) async {
    try {
      final response = await dioClient.patch(
        '${ApiConstants.categories}/$id/status',
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CategoryModel.fromJson(responseData['data']);
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
  Future<void> deleteCategory(String id) async {
    try {
      final response = await dioClient.delete('${ApiConstants.categories}/$id');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al eliminar categoría: $e');
    }
  }

  @override
  Future<CategoryModel> restoreCategory(String id) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.categories}/$id/restore',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CategoryModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al restaurar categoría: $e');
    }
  }

  @override
  Future<bool> isSlugAvailable(String slug, String? excludeId) async {
    try {
      final queryParams = <String, dynamic>{};
      if (excludeId != null) {
        queryParams['excludeId'] = excludeId;
      }

      final response = await dioClient.get(
        '${ApiConstants.categories}/slug/$slug/available',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['available'] as bool? ?? false;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al verificar slug: $e');
    }
  }

  @override
  Future<String> generateUniqueSlug(String name) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.categoriesAdmin}/generate-slug',
        data: {'name': name},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['slug'] as String;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al generar slug: $e');
    }
  }

  @override
  Future<void> reorderCategories(List<Map<String, dynamic>> reorders) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.categories}/reorder',
        data: {'categoryOrders': reorders},
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al reordenar categorías: $e');
    }
  }

  /// Manejar errores de respuesta HTTP
  ServerException _handleErrorResponse(Response response) {
    try {
      final errorModel = ApiErrorModel.fromJson(response.data);
      return ServerException(
        errorModel.primaryMessage,
        statusCode: response.statusCode,
      );
    } catch (e) {
      // Si no se puede parsear el error, usar mensaje genérico
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
