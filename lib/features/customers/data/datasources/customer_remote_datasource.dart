// lib/features/customers/data/datasources/customer_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/customer_model.dart';
import '../models/customer_response_model.dart';
import '../models/create_customer_request_model.dart';
import '../models/update_customer_request_model.dart';
import '../models/customer_query_model.dart';
import '../models/customer_stats_model.dart';
import '../models/api_error_model.dart';

/// Contrato para el datasource remoto de clientes
abstract class CustomerRemoteDataSource {
  Future<CustomerResponseModel> getCustomers(CustomerQueryModel query);
  Future<CustomerModel> getCustomerById(String id);
  Future<CustomerModel> getCustomerByDocument(
    String documentType,
    String documentNumber,
  );
  Future<CustomerModel> getCustomerByEmail(String email);
  Future<CustomerStatsModel> getCustomerStats();
  Future<List<CustomerModel>> searchCustomers(String searchTerm, int limit);
  Future<CustomerModel> createCustomer(CreateCustomerRequestModel request);
  Future<CustomerModel> updateCustomer(
    String id,
    UpdateCustomerRequestModel request,
  );
  Future<CustomerModel> updateCustomerStatus(String id, String status);
  Future<void> deleteCustomer(String id);
  Future<CustomerModel> restoreCustomer(String id);
  Future<bool> isEmailAvailable(String email, String? excludeId);
  Future<bool> isDocumentAvailable(
    String documentType,
    String documentNumber,
    String? excludeId,
  );
  Future<List<CustomerModel>> getCustomersWithOverdueInvoices();
  Future<List<CustomerModel>> getTopCustomers(int limit);
  Future<Map<String, dynamic>> canMakePurchase(
    String customerId,
    double amount,
  );
  Future<Map<String, dynamic>> getCustomerFinancialSummary(String customerId);
}

/// Implementación del datasource remoto usando Dio
class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final DioClient dioClient;

  const CustomerRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<CustomerResponseModel> getCustomers(CustomerQueryModel query) async {
    try {
      final response = await dioClient.get(
        ApiConstants.customers,
        queryParameters: query.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        return CustomerResponseModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener clientes: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final response = await dioClient.get('${ApiConstants.customers}/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener cliente: $e');
    }
  }

  @override
  Future<CustomerModel> getCustomerByDocument(
    String documentType,
    String documentNumber,
  ) async {
    try {
      final response = await dioClient.get(
        ApiConstants.customerByDocument(documentType, documentNumber),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerModel.fromJson(responseData['data']);
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
        'Error inesperado al obtener cliente por documento: $e',
      );
    }
  }

  @override
  Future<CustomerModel> getCustomerByEmail(String email) async {
    try {
      final response = await dioClient.get(ApiConstants.customerByEmail(email));

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerModel.fromJson(responseData['data']);
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
        'Error inesperado al obtener cliente por email: $e',
      );
    }
  }

  @override
  Future<CustomerStatsModel> getCustomerStats() async {
    try {
      final response = await dioClient.get(ApiConstants.customersStats);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerStatsModel.fromJson(responseData['data']);
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
  Future<List<CustomerModel>> searchCustomers(
    String searchTerm,
    int limit,
  ) async {
    try {
      final response = await dioClient.get(
        ApiConstants.customersSearch,
        queryParameters: {'q': searchTerm, 'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => CustomerModel.fromJson(json as Map<String, dynamic>),
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
  Future<CustomerModel> createCustomer(
    CreateCustomerRequestModel request,
  ) async {
    try {
      final response = await dioClient.post(
        ApiConstants.customers,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al crear cliente: $e');
    }
  }

  @override
  Future<CustomerModel> updateCustomer(
    String id,
    UpdateCustomerRequestModel request,
  ) async {
    try {
      final response = await dioClient.patch(
        '${ApiConstants.customers}/$id',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al actualizar cliente: $e');
    }
  }

  @override
  Future<CustomerModel> updateCustomerStatus(String id, String status) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.updateCustomerStatus(id),
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerModel.fromJson(responseData['data']);
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
  Future<void> deleteCustomer(String id) async {
    try {
      final response = await dioClient.delete(ApiConstants.deleteCustomer(id));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al eliminar cliente: $e');
    }
  }

  @override
  Future<CustomerModel> restoreCustomer(String id) async {
    try {
      final response = await dioClient.patch(ApiConstants.restoreCustomer(id));

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return CustomerModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al restaurar cliente: $e');
    }
  }

  @override
  Future<bool> isEmailAvailable(String email, String? excludeId) async {
    try {
      final queryParams = <String, dynamic>{'email': email};
      if (excludeId != null) {
        queryParams['excludeId'] = excludeId;
      }

      print('🔍 [DATASOURCE] Checking email availability: "$email"');

      final response = await dioClient.get(
        ApiConstants.checkCustomerEmail,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // ✅ FIX: Extraer correctamente el valor 'available' del objeto anidado
        bool available = false;

        if (responseData['data'] != null &&
            responseData['data']['available'] != null) {
          available = responseData['data']['available'] as bool;
        } else if (responseData['available'] != null) {
          available = responseData['available'] as bool;
        }

        print(
          '✅ [DATASOURCE] Email "$email" is ${available ? "AVAILABLE" : "TAKEN"}',
        );
        return available;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al verificar email: $e');
    }
  }

  @override
  Future<bool> isDocumentAvailable(
    String documentType,
    String documentNumber,
    String? excludeId,
  ) async {
    try {
      final queryParams = <String, dynamic>{
        'documentType': documentType,
        'documentNumber': documentNumber,
      };
      if (excludeId != null) {
        queryParams['excludeId'] = excludeId;
      }

      print(
        '🔍 [DATASOURCE] Checking document availability: "$documentType:$documentNumber"',
      );

      final response = await dioClient.get(
        ApiConstants.checkCustomerDocument,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // ✅ FIX: Extraer correctamente el valor 'available' del objeto anidado
        bool available = false;

        if (responseData['data'] != null &&
            responseData['data']['available'] != null) {
          available = responseData['data']['available'] as bool;
        } else if (responseData['available'] != null) {
          available = responseData['available'] as bool;
        }

        print(
          '✅ [DATASOURCE] Document "$documentType:$documentNumber" is ${available ? "AVAILABLE" : "TAKEN"}',
        );
        return available;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al verificar documento: $e');
    }
  }

  @override
  Future<List<CustomerModel>> getCustomersWithOverdueInvoices() async {
    try {
      final response = await dioClient.get(ApiConstants.customersWithOverdue);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => CustomerModel.fromJson(json as Map<String, dynamic>),
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
        'Error inesperado al obtener clientes con facturas vencidas: $e',
      );
    }
  }

  @override
  Future<List<CustomerModel>> getTopCustomers(int limit) async {
    try {
      final response = await dioClient.get(
        ApiConstants.customersTopCustomers,
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => CustomerModel.fromJson(json as Map<String, dynamic>),
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
      throw ServerException('Error inesperado al obtener top clientes: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> canMakePurchase(
    String customerId,
    double amount,
  ) async {
    try {
      final response = await dioClient.post(
        ApiConstants.canMakePurchase(customerId),
        data: {'amount': amount},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
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
        'Error inesperado al verificar capacidad de compra: $e',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerFinancialSummary(
    String customerId,
  ) async {
    try {
      final response = await dioClient.get(
        ApiConstants.customerFinancialSummary(customerId),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
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
        'Error inesperado al obtener resumen financiero: $e',
      );
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
