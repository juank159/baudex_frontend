// lib/features/invoices/data/datasources/invoice_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/repositories/invoice_repository.dart';

// Imports específicos para evitar conflictos
import '../models/invoice_model.dart';
import '../models/invoice_stats_model.dart';
import '../models/invoice_response_models.dart';
import '../models/create_invoice_request_model.dart';
import '../models/update_invoice_request_model.dart';
import '../models/add_payment_request_model.dart';
import '../models/invoice_query_models.dart';

/// Contrato para el datasource remoto de facturas
abstract class InvoiceRemoteDataSource {
  Future<InvoiceResponseModel> getInvoices(InvoiceQueryParams params);
  Future<InvoiceModel> getInvoiceById(String id);
  Future<InvoiceModel> getInvoiceByNumber(String number);
  Future<List<InvoiceModel>> getOverdueInvoices();
  Future<InvoiceStatsModel> getInvoiceStats();
  Future<List<InvoiceModel>> getInvoicesByCustomer(String customerId);
  Future<List<InvoiceModel>> searchInvoices(String searchTerm);
  Future<InvoiceModel> createInvoice(CreateInvoiceRequestModel request);
  Future<InvoiceModel> updateInvoice(
    String id,
    UpdateInvoiceRequestModel request,
  );
  Future<InvoiceModel> confirmInvoice(String id);
  Future<InvoiceModel> cancelInvoice(String id);
  Future<InvoiceModel> addPayment(String id, AddPaymentRequestModel request);
  Future<void> deleteInvoice(String id);
}

/// Implementación del datasource remoto usando Dio
class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final DioClient dioClient;

  const InvoiceRemoteDataSourceImpl({required this.dioClient});

  // ==================== READ OPERATIONS ====================

  @override
  Future<InvoiceResponseModel> getInvoices(InvoiceQueryParams params) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Obteniendo facturas...');

      final queryParams = InvoiceQueryParamsModel.fromDomainParams(
        page: params.page,
        limit: params.limit,
        search: params.search,
        status: params.status,
        paymentMethod: params.paymentMethod,
        customerId: params.customerId,
        createdById: params.createdById,
        startDate: params.startDate,
        endDate: params.endDate,
        minAmount: params.minAmount,
        maxAmount: params.maxAmount,
        sortBy: params.sortBy,
        sortOrder: params.sortOrder,
      );

      print('📋 Parámetros: ${queryParams.toQueryParameters()}');

      final response = await dioClient.get(
        '/invoices',
        queryParameters: queryParams.toQueryParameters(),
      );

      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return InvoiceResponseModel.fromJson({
            'data': responseData['data'],
            'meta': responseData['meta'] ?? {},
          });
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      print('❌ Error inesperado en getInvoices: $e');
      throw ServerException('Error inesperado al obtener facturas: $e');
    }
  }

  @override
  Future<InvoiceModel> getInvoiceById(String id) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Obteniendo factura por ID: $id');

      final response = await dioClient.get('/invoices/$id');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return InvoiceModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al obtener factura: $e');
    }
  }

  @override
  Future<InvoiceModel> getInvoiceByNumber(String number) async {
    try {
      print(
        '🌐 InvoiceRemoteDataSource: Obteniendo factura por número: $number',
      );

      final response = await dioClient.get('/invoices/number/$number');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return InvoiceModel.fromJson(responseData['data']);
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
        'Error inesperado al obtener factura por número: $e',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> getOverdueInvoices() async {
    try {
      print('🌐 InvoiceRemoteDataSource: Obteniendo facturas vencidas...');

      final response = await dioClient.get('/invoices/overdue');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
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
        'Error inesperado al obtener facturas vencidas: $e',
      );
    }
  }

  @override
  Future<InvoiceStatsModel> getInvoiceStats() async {
    try {
      print(
        '🌐 InvoiceRemoteDataSource: Obteniendo estadísticas de facturas...',
      );

      final response = await dioClient.get('/invoices/stats');

      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData != null && responseData is Map<String, dynamic>) {
          if (responseData['success'] == true && responseData['data'] != null) {
            var statsData = responseData['data'];

            // Manejar posible doble wrapping del backend
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

            final model = InvoiceStatsModel.fromJson(statsData);

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
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      print('❌ Error inesperado en getInvoiceStats: $e');
      throw ServerException('Error inesperado al obtener estadísticas: $e');
    }
  }

  @override
  Future<List<InvoiceModel>> getInvoicesByCustomer(String customerId) async {
    try {
      print(
        '🌐 InvoiceRemoteDataSource: Obteniendo facturas del cliente: $customerId',
      );

      final response = await dioClient.get(
        '/invoices',
        queryParameters: {
          'customerId': customerId,
          'limit': 100, // Obtener más facturas para el cliente
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
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
        'Error inesperado al obtener facturas del cliente: $e',
      );
    }
  }

  @override
  Future<List<InvoiceModel>> searchInvoices(String searchTerm) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Buscando facturas: $searchTerm');

      final searchParams = InvoiceSearchParamsModel(searchTerm: searchTerm);

      final response = await dioClient.get(
        '/invoices',
        queryParameters: searchParams.toQueryParameters(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return (responseData['data'] as List)
              .map(
                (json) => InvoiceModel.fromJson(json as Map<String, dynamic>),
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
      throw ServerException('Error inesperado al buscar facturas: $e');
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<InvoiceModel> createInvoice(CreateInvoiceRequestModel request) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Creando factura...');
      print('📋 Request data: ${request.toJson()}');

      // Validar request antes de enviar
      if (!request.isValid) {
        throw ServerException('Datos de factura inválidos');
      }

      final response = await dioClient.post(
        '/invoices',
        data: request.toJson(),
      );

      print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          // Enriquecer datos si es necesario
          final invoiceData = responseData['data'] as Map<String, dynamic>;
          final enrichedData = _enrichInvoiceData(invoiceData);

          return InvoiceModel.fromJson(enrichedData);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al crear factura: $e');
    }
  }

  @override
  Future<InvoiceModel> updateInvoice(
    String id,
    UpdateInvoiceRequestModel request,
  ) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Actualizando factura: $id');

      // Validar que hay algo que actualizar
      if (!request.hasUpdates) {
        throw ServerException('No hay datos para actualizar');
      }

      if (!request.isValid) {
        throw ServerException('Datos de actualización inválidos');
      }

      final response = await dioClient.patch(
        '/invoices/$id',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return InvoiceModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al actualizar factura: $e');
    }
  }

  @override
  Future<InvoiceModel> confirmInvoice(String id) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Confirmando factura: $id');

      final response = await dioClient.post('/invoices/$id/confirm');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return InvoiceModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al confirmar factura: $e');
    }
  }

  @override
  Future<InvoiceModel> cancelInvoice(String id) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Cancelando factura: $id');

      final response = await dioClient.post('/invoices/$id/cancel');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return InvoiceModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al cancelar factura: $e');
    }
  }

  @override
  Future<InvoiceModel> addPayment(
    String id,
    AddPaymentRequestModel request,
  ) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Agregando pago a factura: $id');

      // Validar request de pago
      if (!request.isValid) {
        throw ServerException('Datos de pago inválidos');
      }

      final response = await dioClient.post(
        '/invoices/$id/payments',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return InvoiceModel.fromJson(responseData['data']);
        } else {
          throw ServerException('Respuesta inválida del servidor');
        }
      } else {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al agregar pago: $e');
    }
  }

  @override
  Future<void> deleteInvoice(String id) async {
    try {
      print('🌐 InvoiceRemoteDataSource: Eliminando factura: $id');

      final response = await dioClient.delete('/invoices/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw ServerException('Error inesperado al eliminar factura: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Enriquecer datos de factura si faltan campos requeridos
  Map<String, dynamic> _enrichInvoiceData(Map<String, dynamic> invoiceData) {
    final enrichedData = Map<String, dynamic>.from(invoiceData);

    // Asegurar campos de fecha
    if (!enrichedData.containsKey('createdAt') ||
        enrichedData['createdAt'] == null) {
      enrichedData['createdAt'] = DateTime.now().toIso8601String();
    }
    if (!enrichedData.containsKey('updatedAt') ||
        enrichedData['updatedAt'] == null) {
      enrichedData['updatedAt'] = DateTime.now().toIso8601String();
    }

    // Enriquecer items si es necesario
    if (enrichedData['items'] != null && enrichedData['items'] is List) {
      final items = enrichedData['items'] as List;
      for (int i = 0; i < items.length; i++) {
        if (items[i] is Map<String, dynamic>) {
          final itemMap = items[i] as Map<String, dynamic>;
          if (!itemMap.containsKey('invoiceId') ||
              itemMap['invoiceId'] == null) {
            itemMap['invoiceId'] = enrichedData['id'];
          }
          if (!itemMap.containsKey('createdAt') ||
              itemMap['createdAt'] == null) {
            itemMap['createdAt'] = DateTime.now().toIso8601String();
          }
          if (!itemMap.containsKey('updatedAt') ||
              itemMap['updatedAt'] == null) {
            itemMap['updatedAt'] = DateTime.now().toIso8601String();
          }
        }
      }
    }

    return enrichedData;
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
