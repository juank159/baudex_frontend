// lib/features/bank_accounts/data/datasources/bank_account_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/bank_account_model.dart';

/// Contrato para el datasource remoto de cuentas bancarias
abstract class BankAccountRemoteDataSource {
  /// Obtener todas las cuentas bancarias
  Future<List<BankAccountModel>> getBankAccounts({
    String? type,
    bool? isActive,
    bool includeInactive,
  });

  /// Obtener cuentas activas
  Future<List<BankAccountModel>> getActiveBankAccounts();

  /// Obtener cuenta por ID
  Future<BankAccountModel> getBankAccountById(String id);

  /// Obtener cuenta predeterminada
  Future<BankAccountModel?> getDefaultBankAccount();

  /// Crear cuenta bancaria
  Future<BankAccountModel> createBankAccount(CreateBankAccountRequest request);

  /// Actualizar cuenta bancaria
  Future<BankAccountModel> updateBankAccount(
    String id,
    UpdateBankAccountRequest request,
  );

  /// Eliminar cuenta bancaria
  Future<void> deleteBankAccount(String id);

  /// Establecer cuenta como predeterminada
  Future<BankAccountModel> setDefaultBankAccount(String id);

  /// Activar/desactivar cuenta
  Future<BankAccountModel> toggleBankAccountActive(String id);
}

/// Implementación del datasource remoto usando Dio
class BankAccountRemoteDataSourceImpl implements BankAccountRemoteDataSource {
  final DioClient dioClient;

  const BankAccountRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<BankAccountModel>> getBankAccounts({
    String? type,
    bool? isActive,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (isActive != null) queryParams['isActive'] = isActive;
      if (includeInactive) queryParams['includeInactive'] = true;

      final response = await dioClient.get(
        ApiConstants.bankAccounts,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => BankAccountModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener cuentas bancarias: $e');
    }
  }

  @override
  Future<List<BankAccountModel>> getActiveBankAccounts() async {
    try {
      final response = await dioClient.get(ApiConstants.bankAccountsActive);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['data'] ?? response.data);
        return data.map((json) => BankAccountModel.fromJson(json)).toList();
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener cuentas activas: $e');
    }
  }

  @override
  Future<BankAccountModel> getBankAccountById(String id) async {
    try {
      final response =
          await dioClient.get(ApiConstants.bankAccountById(id));

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        return BankAccountModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al obtener cuenta bancaria: $e');
    }
  }

  @override
  Future<BankAccountModel?> getDefaultBankAccount() async {
    try {
      final response = await dioClient.get(ApiConstants.bankAccountsDefault);

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        if (data == null) return null;
        return BankAccountModel.fromJson(data);
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
      throw ServerException('Error al obtener cuenta predeterminada: $e');
    }
  }

  @override
  Future<BankAccountModel> createBankAccount(
    CreateBankAccountRequest request,
  ) async {
    try {
      final response = await dioClient.post(
        ApiConstants.bankAccounts,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = _extractData(response.data);
        return BankAccountModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al crear cuenta bancaria: $e');
    }
  }

  @override
  Future<BankAccountModel> updateBankAccount(
    String id,
    UpdateBankAccountRequest request,
  ) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.bankAccountById(id),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        return BankAccountModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al actualizar cuenta bancaria: $e');
    }
  }

  @override
  Future<void> deleteBankAccount(String id) async {
    try {
      final response =
          await dioClient.delete(ApiConstants.bankAccountById(id));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al eliminar cuenta bancaria: $e');
    }
  }

  @override
  Future<BankAccountModel> setDefaultBankAccount(String id) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.setDefaultBankAccount(id),
      );

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        return BankAccountModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al establecer cuenta predeterminada: $e');
    }
  }

  @override
  Future<BankAccountModel> toggleBankAccountActive(String id) async {
    try {
      final response = await dioClient.patch(
        ApiConstants.toggleBankAccountActive(id),
      );

      if (response.statusCode == 200) {
        final data = _extractData(response.data);
        return BankAccountModel.fromJson(data);
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Error al cambiar estado de cuenta: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Extrae los datos de la respuesta del servidor
  /// El servidor envuelve las respuestas en { success: true, data: {...} }
  dynamic _extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Si tiene el wrapper { success, data }, extraer data
      if (responseData.containsKey('data')) {
        return responseData['data'];
      }
    }
    // Si no tiene wrapper, devolver tal cual
    return responseData;
  }

  ServerException _handleErrorResponse(Response response) {
    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    String message = 'Error del servidor';
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? message;
    }

    return ServerException(message, statusCode: statusCode);
  }

  ServerException _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return ServerException('Tiempo de conexión agotado');
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return ServerException('Tiempo de respuesta agotado');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ServerException('Error de conexión al servidor');
    }
    if (e.response != null) {
      return _handleErrorResponse(e.response!);
    }
    return ServerException('Error de red: ${e.message}');
  }
}
