// lib/features/products/data/datasources/product_presentation_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/product_presentation_model.dart';
import '../models/create_product_presentation_request_model.dart';
import '../models/update_product_presentation_request_model.dart';

abstract class ProductPresentationRemoteDataSource {
  Future<List<ProductPresentationModel>> getPresentations(String productId);
  Future<ProductPresentationModel> getPresentationById(
    String productId,
    String id,
  );
  Future<ProductPresentationModel> createPresentation(
    String productId,
    CreateProductPresentationRequestModel request,
  );
  Future<ProductPresentationModel> updatePresentation(
    String productId,
    String id,
    UpdateProductPresentationRequestModel request,
  );
  Future<void> deletePresentation(String productId, String id);
  Future<ProductPresentationModel> restorePresentation(
    String productId,
    String id,
  );
}

class ProductPresentationRemoteDataSourceImpl
    implements ProductPresentationRemoteDataSource {
  final DioClient dioClient;

  const ProductPresentationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ProductPresentationModel>> getPresentations(
    String productId,
  ) async {
    try {
      final response = await dioClient.get(
        '/products/$productId/presentations',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final list = _extractList(data);
        return list
            .map(
              (json) => ProductPresentationModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      }
      throw _handleErrorResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado al obtener presentaciones: $e');
    }
  }

  @override
  Future<ProductPresentationModel> getPresentationById(
    String productId,
    String id,
  ) async {
    try {
      final response = await dioClient.get(
        '/products/$productId/presentations/$id',
      );
      if (response.statusCode == 200) {
        return ProductPresentationModel.fromJson(
          _extractData(response.data),
        );
      }
      throw _handleErrorResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado al obtener presentación: $e');
    }
  }

  @override
  Future<ProductPresentationModel> createPresentation(
    String productId,
    CreateProductPresentationRequestModel request,
  ) async {
    try {
      final response = await dioClient.post(
        '/products/$productId/presentations',
        data: request.toJson(),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ProductPresentationModel.fromJson(
          _extractData(response.data),
        );
      }
      throw _handleErrorResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado al crear presentación: $e');
    }
  }

  @override
  Future<ProductPresentationModel> updatePresentation(
    String productId,
    String id,
    UpdateProductPresentationRequestModel request,
  ) async {
    try {
      final response = await dioClient.patch(
        '/products/$productId/presentations/$id',
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return ProductPresentationModel.fromJson(
          _extractData(response.data),
        );
      }
      throw _handleErrorResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado al actualizar presentación: $e');
    }
  }

  @override
  Future<void> deletePresentation(String productId, String id) async {
    try {
      final response = await dioClient.delete(
        '/products/$productId/presentations/$id',
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado al eliminar presentación: $e');
    }
  }

  @override
  Future<ProductPresentationModel> restorePresentation(
    String productId,
    String id,
  ) async {
    try {
      final response = await dioClient.post(
        '/products/$productId/presentations/$id/restore',
      );
      if (response.statusCode == 200) {
        return ProductPresentationModel.fromJson(
          _extractData(response.data),
        );
      }
      throw _handleErrorResponse(response);
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error inesperado al restaurar presentación: $e');
    }
  }

  // ==================== HELPERS ====================

  Map<String, dynamic> _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData['success'] == true && responseData['data'] != null) {
        return responseData['data'] as Map<String, dynamic>;
      }
      // Backend may return the object directly
      if (responseData.containsKey('id')) {
        return responseData;
      }
    }
    throw const ServerException('Respuesta inválida del servidor');
  }

  List _extractList(dynamic responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map<String, dynamic>) {
      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'];
        if (data is List) return data;
        // paginated response
        if (data is Map<String, dynamic> && data['items'] is List) {
          return data['items'] as List;
        }
      }
    }
    return [];
  }

  ServerException _handleErrorResponse(Response response) {
    try {
      final errorData = response.data;
      final message = errorData is Map ? errorData['message'] ?? 'Error del servidor' : 'Error del servidor';
      return ServerException(message.toString(), statusCode: response.statusCode);
    } catch (_) {
      return ServerException(
        'Error del servidor: ${response.statusMessage}',
        statusCode: response.statusCode,
      );
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ConnectionException('Tiempo de conexión agotado');
      case DioExceptionType.badResponse:
        if (e.response != null) return _handleErrorResponse(e.response!);
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
