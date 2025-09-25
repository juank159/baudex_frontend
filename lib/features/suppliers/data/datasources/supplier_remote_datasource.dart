// lib/features/suppliers/data/datasources/supplier_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../models/supplier_model.dart';
import '../models/supplier_response_model.dart';
import '../models/supplier_stats_model.dart';
import '../models/create_supplier_request_model.dart';
import '../models/update_supplier_request_model.dart';
import '../../domain/repositories/supplier_repository.dart';

abstract class SupplierRemoteDataSource {
  Future<PaginatedResult<SupplierModel>> getSuppliers(SupplierQueryParams params);
  Future<SupplierModel> getSupplierById(String id);
  Future<List<SupplierModel>> searchSuppliers(String searchTerm, {int limit = 10});
  Future<List<SupplierModel>> getActiveSuppliers();
  Future<SupplierStatsModel> getSupplierStats();
  Future<SupplierModel> createSupplier(CreateSupplierRequestModel request);
  Future<SupplierModel> updateSupplier(String id, UpdateSupplierRequestModel request);
  Future<SupplierModel> updateSupplierStatus(String id, String status);
  Future<void> deleteSupplier(String id);
  Future<SupplierModel> restoreSupplier(String id);
  Future<bool> validateDocument(String documentType, String documentNumber, {String? excludeId});
  Future<bool> validateCode(String code, {String? excludeId});
  Future<bool> validateEmail(String email, {String? excludeId});
  Future<bool> checkDocumentUniqueness(String documentType, String documentNumber, {String? excludeId});
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  final DioClient dioClient;

  SupplierRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PaginatedResult<SupplierModel>> getSuppliers(SupplierQueryParams params) async {
    try {
      final response = await dioClient.get(
        ApiConstants.suppliers,
        queryParameters: params.toJson(),
      );

      final responseModel = SuppliersListResponseModel.fromJson(response.data);

      if (responseModel.success) {
        return PaginatedResult<SupplierModel>(
          data: responseModel.data,
          meta: responseModel.meta ?? PaginationMeta(
            page: params.page,
            limit: params.limit,
            totalItems: responseModel.data.length,
            totalPages: 1,
            hasNextPage: false,
            hasPreviousPage: false,
          ),
        );
      } else {
        throw ServerException(responseModel.message ?? 'Error al obtener proveedores');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<SupplierModel> getSupplierById(String id) async {
    try {
      final response = await dioClient.get(ApiConstants.supplierById(id));
      final responseModel = SupplierResponseModel.fromJson(response.data);

      if (responseModel.success && responseModel.data != null) {
        return responseModel.data!;
      } else {
        throw ServerException(responseModel.message ?? 'Proveedor no encontrado');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<SupplierModel>> searchSuppliers(String searchTerm, {int limit = 10}) async {
    try {
      final response = await dioClient.get(
        ApiConstants.suppliersSearch,
        queryParameters: {
          'search': searchTerm,
          'limit': limit,
        },
      );

      final responseModel = SuppliersListResponseModel.fromJson(response.data);

      if (responseModel.success) {
        return responseModel.data;
      } else {
        throw ServerException(responseModel.message ?? 'Error en búsqueda de proveedores');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<SupplierModel>> getActiveSuppliers() async {
    try {
      final response = await dioClient.get(ApiConstants.suppliersActive);
      final responseModel = SuppliersListResponseModel.fromJson(response.data);

      if (responseModel.success) {
        return responseModel.data;
      } else {
        throw ServerException(responseModel.message ?? 'Error al obtener proveedores activos');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<SupplierStatsModel> getSupplierStats() async {
    try {
      final response = await dioClient.get(ApiConstants.suppliersStats);
      final responseModel = SupplierStatsResponseModel.fromJson(response.data);

      if (responseModel.success) {
        return responseModel.data;
      } else {
        throw ServerException(responseModel.message ?? 'Error al obtener estadísticas');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<SupplierModel> createSupplier(CreateSupplierRequestModel request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.suppliers,
        data: request.toJson(),
      );

      final responseModel = SupplierResponseModel.fromJson(response.data);

      if (responseModel.success && responseModel.data != null) {
        return responseModel.data!;
      } else {
        throw ServerException(responseModel.message ?? 'Error al crear proveedor');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<SupplierModel> updateSupplier(String id, UpdateSupplierRequestModel request) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.supplierById(id),
        data: request.toJson(),
      );

      final responseModel = SupplierResponseModel.fromJson(response.data);

      if (responseModel.success && responseModel.data != null) {
        return responseModel.data!;
      } else {
        throw ServerException(responseModel.message ?? 'Error al actualizar proveedor');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<SupplierModel> updateSupplierStatus(String id, String status) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.updateSupplierStatus(id),
        data: {'status': status},
      );

      final responseModel = SupplierResponseModel.fromJson(response.data);

      if (responseModel.success && responseModel.data != null) {
        return responseModel.data!;
      } else {
        throw ServerException(responseModel.message ?? 'Error al actualizar estado');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<void> deleteSupplier(String id) async {
    try {
      await dioClient.delete(ApiConstants.deleteSupplier(id));
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<SupplierModel> restoreSupplier(String id) async {
    try {
      final response = await dioClient.post(ApiConstants.restoreSupplier(id));
      final responseModel = SupplierResponseModel.fromJson(response.data);

      if (responseModel.success && responseModel.data != null) {
        return responseModel.data!;
      } else {
        throw ServerException(responseModel.message ?? 'Error al restaurar proveedor');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<bool> validateDocument(String documentType, String documentNumber, {String? excludeId}) async {
    try {
      final response = await dioClient.post(
        ApiConstants.validateSupplierDocument,
        data: {
          'documentType': documentType,
          'documentNumber': documentNumber,
          if (excludeId != null) 'excludeId': excludeId,
        },
      );

      return response.data['isAvailable'] ?? false;
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<bool> validateCode(String code, {String? excludeId}) async {
    try {
      final response = await dioClient.post(
        ApiConstants.validateSupplierCode,
        data: {
          'code': code,
          if (excludeId != null) 'excludeId': excludeId,
        },
      );

      return response.data['isAvailable'] ?? false;
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<bool> validateEmail(String email, {String? excludeId}) async {
    try {
      final response = await dioClient.post(
        ApiConstants.validateSupplierEmail,
        data: {
          'email': email,
          if (excludeId != null) 'excludeId': excludeId,
        },
      );

      return response.data['isAvailable'] ?? false;
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<bool> checkDocumentUniqueness(String documentType, String documentNumber, {String? excludeId}) async {
    try {
      final response = await dioClient.post(
        ApiConstants.checkDocumentUniqueness,
        data: {
          'documentType': documentType,
          'documentNumber': documentNumber,
          if (excludeId != null) 'excludeId': excludeId,
        },
      );

      // La API responde con: {"success":true,"data":{"isUnique":true}}
      return response.data['data']['isUnique'] ?? false;
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de respuesta agotado';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Error del servidor';
        return '[$statusCode] $message';
      case DioExceptionType.cancel:
        return 'Petición cancelada';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifique su conexión a internet';
      default:
        return 'Error de red: ${e.message}';
    }
  }
}