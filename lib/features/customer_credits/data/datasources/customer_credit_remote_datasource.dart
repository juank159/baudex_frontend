// lib/features/customer_credits/data/datasources/customer_credit_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/customer_credit_model.dart';

/// Contrato para el datasource remoto de créditos de clientes
abstract class CustomerCreditRemoteDataSource {
  /// Obtener todos los créditos con filtros
  Future<List<CustomerCreditModel>> getCredits(CustomerCreditQueryParams? query);

  /// Obtener un crédito por ID
  Future<CustomerCreditModel> getCreditById(String id);

  /// Obtener créditos de un cliente
  Future<List<CustomerCreditModel>> getCreditsByCustomer(String customerId);

  /// Obtener créditos pendientes de un cliente
  Future<List<CustomerCreditModel>> getPendingCreditsByCustomer(String customerId);

  /// Crear un nuevo crédito
  Future<CustomerCreditModel> createCredit(CreateCustomerCreditDto dto);

  /// Agregar un pago a un crédito
  Future<CustomerCreditModel> addPayment(String creditId, AddCreditPaymentDto dto);

  /// Obtener pagos de un crédito
  Future<List<CreditPaymentModel>> getCreditPayments(String creditId);

  /// Cancelar un crédito
  Future<CustomerCreditModel> cancelCredit(String creditId);

  /// Marcar créditos vencidos
  Future<int> markOverdueCredits();

  /// Obtener estadísticas de créditos
  Future<CreditStatsModel> getCreditStats();

  /// Eliminar un crédito (soft delete)
  Future<void> deleteCredit(String creditId);

  // ==================== CREDIT TRANSACTIONS ====================

  /// Obtener transacciones de un crédito
  Future<List<CreditTransactionModel>> getCreditTransactions(String creditId);

  /// Agregar monto a un crédito (aumentar deuda)
  Future<CustomerCreditModel> addAmountToCredit(String creditId, AddAmountToCreditDto dto);

  /// Aplicar saldo a favor a un crédito
  Future<CustomerCreditModel> applyBalanceToCredit(String creditId, ApplyBalanceToCreditDto dto);

  // ==================== CLIENT BALANCE ====================

  /// Obtener todos los saldos a favor
  Future<List<ClientBalanceModel>> getAllClientBalances();

  /// Obtener saldo de un cliente
  Future<ClientBalanceModel?> getClientBalance(String customerId);

  /// Obtener transacciones de saldo de un cliente
  Future<List<ClientBalanceTransactionModel>> getClientBalanceTransactions(String customerId);

  /// Depositar saldo a favor
  Future<ClientBalanceModel> depositBalance(DepositBalanceDto dto);

  /// Usar saldo a favor
  Future<ClientBalanceModel> useBalance(UseBalanceDto dto);

  /// Reembolsar saldo a favor
  Future<ClientBalanceModel> refundBalance(RefundBalanceDto dto);

  /// Ajustar saldo manualmente
  Future<ClientBalanceModel> adjustBalance(AdjustBalanceDto dto);

  // ==================== CUSTOMER ACCOUNT ====================

  /// Obtener cuenta corriente consolidada de un cliente
  Future<CustomerAccountModel> getCustomerAccount(String customerId);
}

/// Implementación del datasource remoto usando Dio
class CustomerCreditRemoteDataSourceImpl implements CustomerCreditRemoteDataSource {
  final DioClient dioClient;

  /// Endpoint base para créditos
  static const String _baseEndpoint = '/customer-credits';

  const CustomerCreditRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<CustomerCreditModel>> getCredits(CustomerCreditQueryParams? query) async {
    try {
      final queryParams = query?.toQueryMap() ?? {};

      final response = await dioClient.get(
        _baseEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => CustomerCreditModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener créditos: $e');
    }
  }

  @override
  Future<CustomerCreditModel> getCreditById(String id) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/$id');

      if (response.statusCode == 200) {
        // La respuesta viene con estructura {"success":true,"data":{...}}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CustomerCreditModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener crédito: $e');
    }
  }

  @override
  Future<List<CustomerCreditModel>> getCreditsByCustomer(String customerId) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/customer/$customerId');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => CustomerCreditModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener créditos del cliente: $e');
    }
  }

  @override
  Future<List<CustomerCreditModel>> getPendingCreditsByCustomer(String customerId) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/customer/$customerId/pending');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => CustomerCreditModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener créditos pendientes: $e');
    }
  }

  @override
  Future<CustomerCreditModel> createCredit(CreateCustomerCreditDto dto) async {
    try {
      final response = await dioClient.post(
        _baseEndpoint,
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // La respuesta viene con estructura {"success":true,"data":{...}}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CustomerCreditModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al crear crédito: $e');
    }
  }

  @override
  Future<CustomerCreditModel> addPayment(String creditId, AddCreditPaymentDto dto) async {
    try {
      final response = await dioClient.post(
        '$_baseEndpoint/$creditId/payments',
        data: dto.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // La respuesta viene con estructura {"success":true,"data":{credit:..., payment:...}}
        final responseData = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        // El backend retorna { credit: ..., payment: ... }
        final creditData = responseData is Map && responseData.containsKey('credit')
            ? responseData['credit']
            : responseData;
        return CustomerCreditModel.fromJson(creditData);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al agregar pago: $e');
    }
  }

  @override
  Future<List<CreditPaymentModel>> getCreditPayments(String creditId) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/$creditId/payments');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => CreditPaymentModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener pagos del crédito: $e');
    }
  }

  @override
  Future<CustomerCreditModel> cancelCredit(String creditId) async {
    try {
      final response = await dioClient.post('$_baseEndpoint/$creditId/cancel');

      if (response.statusCode == 200) {
        // La respuesta viene con estructura {"success":true,"data":{...}}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CustomerCreditModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al cancelar crédito: $e');
    }
  }

  @override
  Future<int> markOverdueCredits() async {
    try {
      final response = await dioClient.post('$_baseEndpoint/mark-overdue');

      if (response.statusCode == 200) {
        // La respuesta viene con estructura {"success":true,"data":count}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return data as int? ?? 0;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al marcar créditos vencidos: $e');
    }
  }

  @override
  Future<CreditStatsModel> getCreditStats() async {
    try {
      final response = await dioClient.get('$_baseEndpoint/stats');

      if (response.statusCode == 200) {
        // La respuesta viene con estructura {"success":true,"data":{...}}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CreditStatsModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener estadísticas: $e');
    }
  }

  @override
  Future<void> deleteCredit(String creditId) async {
    try {
      final response = await dioClient.delete('$_baseEndpoint/$creditId');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al eliminar crédito: $e');
    }
  }

  // ==================== CREDIT TRANSACTIONS ====================

  @override
  Future<List<CreditTransactionModel>> getCreditTransactions(String creditId) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/$creditId/transactions');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => CreditTransactionModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener transacciones del crédito: $e');
    }
  }

  @override
  Future<CustomerCreditModel> addAmountToCredit(String creditId, AddAmountToCreditDto dto) async {
    try {
      final response = await dioClient.post(
        '$_baseEndpoint/$creditId/add-amount',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        // La respuesta viene con estructura {"success":true,"data":{...}}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CustomerCreditModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al agregar monto al crédito: $e');
    }
  }

  @override
  Future<CustomerCreditModel> applyBalanceToCredit(String creditId, ApplyBalanceToCreditDto dto) async {
    try {
      final response = await dioClient.post(
        '$_baseEndpoint/$creditId/apply-balance',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        // La respuesta viene con estructura {"success":true,"data":{...}}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CustomerCreditModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al aplicar saldo a favor: $e');
    }
  }

  // ==================== CLIENT BALANCE ====================

  static const String _balanceEndpoint = '/client-balance';

  @override
  Future<List<ClientBalanceModel>> getAllClientBalances() async {
    try {
      final response = await dioClient.get(_balanceEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => ClientBalanceModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener saldos a favor: $e');
    }
  }

  @override
  Future<ClientBalanceModel?> getClientBalance(String customerId) async {
    try {
      final response = await dioClient.get('$_balanceEndpoint/customer/$customerId');

      if (response.statusCode == 200) {
        if (response.data == null) return null;
        // La respuesta viene con estructura {"success":true,"data":{...}}
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        if (data == null) return null;
        return ClientBalanceModel.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener saldo del cliente: $e');
    }
  }

  @override
  Future<List<ClientBalanceTransactionModel>> getClientBalanceTransactions(String customerId) async {
    try {
      final response = await dioClient.get('$_balanceEndpoint/customer/$customerId/transactions');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => ClientBalanceTransactionModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener transacciones de saldo: $e');
    }
  }

  @override
  Future<ClientBalanceModel> depositBalance(DepositBalanceDto dto) async {
    try {
      final response = await dioClient.post(
        '$_balanceEndpoint/deposit',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return ClientBalanceModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al depositar saldo: $e');
    }
  }

  @override
  Future<ClientBalanceModel> useBalance(UseBalanceDto dto) async {
    try {
      final response = await dioClient.post(
        '$_balanceEndpoint/use',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return ClientBalanceModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al usar saldo a favor: $e');
    }
  }

  @override
  Future<ClientBalanceModel> refundBalance(RefundBalanceDto dto) async {
    try {
      final response = await dioClient.post(
        '$_balanceEndpoint/refund',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return ClientBalanceModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al reembolsar saldo: $e');
    }
  }

  @override
  Future<ClientBalanceModel> adjustBalance(AdjustBalanceDto dto) async {
    try {
      final response = await dioClient.post(
        '$_balanceEndpoint/adjust',
        data: dto.toJson(),
      );

      if (response.statusCode == 200) {
        return ClientBalanceModel.fromJson(response.data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al ajustar saldo: $e');
    }
  }

  // ==================== CUSTOMER ACCOUNT ====================

  @override
  Future<CustomerAccountModel> getCustomerAccount(String customerId) async {
    try {
      final response = await dioClient.get('$_baseEndpoint/customer/$customerId/account');

      if (response.statusCode == 200) {
        // Extraer el campo 'data' de la respuesta si existe
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return CustomerAccountModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener cuenta corriente: $e');
    }
  }

  /// Maneja respuestas de error del servidor
  ServerException _handleErrorResponse(Response response) {
    final message = response.data?['message'] ?? 'Error en la solicitud';
    return ServerException(message);
  }

  /// Maneja excepciones de Dio
  ServerException _handleDioException(DioException e) {
    if (e.response != null) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Error de conexión';
      return ServerException(message);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return ServerException('Tiempo de conexión agotado');
      case DioExceptionType.sendTimeout:
        return ServerException('Tiempo de envío agotado');
      case DioExceptionType.receiveTimeout:
        return ServerException('Tiempo de respuesta agotado');
      case DioExceptionType.connectionError:
        return ServerException('Error de conexión con el servidor');
      default:
        return ServerException('Error de red: ${e.message}');
    }
  }
}
