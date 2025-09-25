// lib/features/purchase_orders/data/datasources/purchase_order_remote_datasource.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../domain/repositories/purchase_order_repository.dart';
import '../models/purchase_order_model.dart';
import '../models/purchase_order_request_model.dart';
import '../models/purchase_order_response_model.dart';

abstract class PurchaseOrderRemoteDataSource {
  Future<PaginatedResult<PurchaseOrderModel>> getPurchaseOrders(
    PurchaseOrderQueryParams params,
  );

  Future<PurchaseOrderModel> getPurchaseOrderById(String id);

  Future<List<PurchaseOrderModel>> searchPurchaseOrders(
    SearchPurchaseOrdersParams params,
  );

  Future<PurchaseOrderStatsModel> getPurchaseOrderStats();

  Future<PurchaseOrderModel> createPurchaseOrder(
    CreatePurchaseOrderParams params,
  );

  Future<PurchaseOrderModel> updatePurchaseOrder(
    UpdatePurchaseOrderParams params,
  );

  Future<void> deletePurchaseOrder(String id);

  Future<PurchaseOrderModel> approvePurchaseOrder(
    String id,
    String? approvalNotes,
  );

  Future<PurchaseOrderModel> rejectPurchaseOrder(
    String id,
    String rejectionReason,
  );

  Future<PurchaseOrderModel> sendPurchaseOrder(String id, String? sendNotes);

  Future<PurchaseOrderModel> receivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  );

  Future<PurchaseOrderModel> cancelPurchaseOrder(
    String id,
    String cancellationReason,
  );

  Future<List<PurchaseOrderModel>> getPurchaseOrdersBySupplier(
    String supplierId,
  );

  Future<List<PurchaseOrderModel>> getOverduePurchaseOrders();

  Future<List<PurchaseOrderModel>> getPendingApprovalPurchaseOrders();

  Future<List<PurchaseOrderModel>> getRecentPurchaseOrders(int limit);
}

class PurchaseOrderRemoteDataSourceImpl
    implements PurchaseOrderRemoteDataSource {
  final DioClient dioClient;

  const PurchaseOrderRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<PaginatedResult<PurchaseOrderModel>> getPurchaseOrders(
    PurchaseOrderQueryParams params,
  ) async {
    try {
      final response = await dioClient.get(
        ApiConstants.purchaseOrders,
        queryParameters: params.toMap(),
      );

      if (response.statusCode == 200) {
        final responseModel = PurchaseOrderListResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return PaginatedResult<PurchaseOrderModel>(
            data: responseModel.data!.data,
            meta: PaginationMeta(
              page: params.page,
              limit: params.limit,
              totalItems: responseModel.data!.total,
              totalPages: (responseModel.data!.total / params.limit).ceil(),
              hasNextPage: params.page < (responseModel.data!.total / params.limit).ceil(),
              hasPreviousPage: params.page > 1,
            ),
          );
        } else {
          throw ServerException(
            responseModel.error ?? 'Error desconocido del servidor',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> getPurchaseOrderById(String id) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.purchaseOrders}/$id',
      );

      if (response.statusCode == 200) {
        print('🔍 Raw response data: ${response.data}');
        
        try {
          final responseModel = PurchaseOrderResponseModel.fromJson(
            response.data,
          );

          if (responseModel.success && responseModel.data != null) {
            print('✅ Response model created successfully');
            print('🔍 Purchase order data: ${responseModel.data!.toJson()}');
            return responseModel.data!;
          } else {
            throw ServerException(
              responseModel.error ?? 'Orden de compra no encontrada',
            );
          }
        } catch (e) {
          print('❌ Error al deserializar JSON: $e');
          print('📋 Data original: ${response.data}');
          throw ServerException('Error de deserialización: $e');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> searchPurchaseOrders(
    SearchPurchaseOrdersParams params,
  ) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.purchaseOrders}/search',
        queryParameters: params.toMap(),
      );

      if (response.statusCode == 200) {
        final responseModel = PurchaseOrderListResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!.data;
        } else {
          throw ServerException(responseModel.error ?? 'Error en la búsqueda');
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderStatsModel> getPurchaseOrderStats() async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.purchaseOrders}/stats',
      );

      if (response.statusCode == 200) {
        final responseModel = PurchaseOrderStatsResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al obtener estadísticas',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> createPurchaseOrder(
    CreatePurchaseOrderParams params,
  ) async {
    try {
      print('🌐 PurchaseOrderRemoteDataSource: Iniciando creación de orden');
      final requestModel = CreatePurchaseOrderRequestModel.fromParams(params);

      print('📤 Enviando POST a: ${ApiConstants.purchaseOrders}');
      print('🔗 URL completa esperada: [Using DioClient]');
      final requestJson = requestModel.toJson();
      print('📋 Request data: $requestJson');
      print('📋 Items count: ${requestJson['items'].length}');
      if (requestJson['items'].isNotEmpty) {
        print('📋 First item: ${requestJson['items'][0]}');
      }

      final response = await dioClient.post(
        ApiConstants.purchaseOrders,
        data: requestModel.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('🔍 Raw response data from create: ${response.data}');
        final responseModel = PurchaseOrderResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          print('✅ Respuesta exitosa del servidor');
          print('🔍 Created purchase order data: ${responseModel.data!.toJson()}');
          return responseModel.data!;
        } else {
          print('❌ Error en respuesta del servidor: ${responseModel.error}');
          throw ServerException(
            responseModel.error ?? 'Error al crear la orden de compra',
          );
        }
      } else {
        print('❌ Status code incorrecto: ${response.statusCode}');
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ DioException en createPurchaseOrder: ${e.message}');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Response data: ${e.response?.data}');
      throw ServerException(_handleDioError(e));
    } catch (e) {
      print('❌ Error inesperado en createPurchaseOrder: $e');
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> updatePurchaseOrder(
    UpdatePurchaseOrderParams params,
  ) async {
    try {
      final requestModel = UpdatePurchaseOrderRequestModel.fromParams(params);

      final response = await dioClient.patch(
        '${ApiConstants.purchaseOrders}/${params.id}',
        data: requestModel.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseModel = PurchaseOrderResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al actualizar la orden de compra',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<void> deletePurchaseOrder(String id) async {
    try {
      final response = await dioClient.delete(
        '${ApiConstants.purchaseOrders}/$id',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> approvePurchaseOrder(
    String id,
    String? approvalNotes,
  ) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.purchaseOrders}/$id/approve',
        data: {if (approvalNotes != null) 'approval_notes': approvalNotes},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseModel = PurchaseOrderResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al aprobar la orden de compra',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> rejectPurchaseOrder(
    String id,
    String rejectionReason,
  ) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.purchaseOrders}/$id/reject',
        data: {'rejection_reason': rejectionReason},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseModel = PurchaseOrderResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al rechazar la orden de compra',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> sendPurchaseOrder(
    String id,
    String? sendNotes,
  ) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.purchaseOrders}/$id/send',
        data: {if (sendNotes != null) 'send_notes': sendNotes},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseModel = PurchaseOrderResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al enviar la orden de compra',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> receivePurchaseOrder(
    ReceivePurchaseOrderParams params,
  ) async {
    try {
      final requestModel = ReceivePurchaseOrderRequestModel.fromParams(params);

      final response = await dioClient.post(
        '${ApiConstants.purchaseOrders}/${params.id}/receive',
        data: requestModel.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseModel = PurchaseOrderResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al recibir la orden de compra',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<PurchaseOrderModel> cancelPurchaseOrder(
    String id,
    String cancellationReason,
  ) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.purchaseOrders}/$id/cancel',
        data: {'cancellation_reason': cancellationReason},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseModel = PurchaseOrderResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al cancelar la orden de compra',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> getPurchaseOrdersBySupplier(
    String supplierId,
  ) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.purchaseOrders}/supplier/$supplierId',
      );

      if (response.statusCode == 200) {
        final responseModel = PurchaseOrderListResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!.data;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al obtener órdenes por proveedor',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> getOverduePurchaseOrders() async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.purchaseOrders}/overdue',
      );

      if (response.statusCode == 200) {
        final responseModel = PurchaseOrderListResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!.data;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al obtener órdenes vencidas',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> getPendingApprovalPurchaseOrders() async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.purchaseOrders}/pending-approval',
      );

      if (response.statusCode == 200) {
        final responseModel = PurchaseOrderListResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!.data;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al obtener órdenes pendientes',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  @override
  Future<List<PurchaseOrderModel>> getRecentPurchaseOrders(int limit) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.purchaseOrders}/recent',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final responseModel = PurchaseOrderListResponseModel.fromJson(
          response.data,
        );

        if (responseModel.success && responseModel.data != null) {
          return responseModel.data!.data;
        } else {
          throw ServerException(
            responseModel.error ?? 'Error al obtener órdenes recientes',
          );
        }
      } else {
        throw ServerException('Error del servidor: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException(_handleDioError(e));
    } catch (e) {
      throw ServerException('Error inesperado: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Verifica tu conexión a internet.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 404) {
          return 'Orden de compra no encontrada';
        } else if (e.response?.statusCode == 401) {
          return 'No autorizado. Inicia sesión nuevamente.';
        } else if (e.response?.statusCode == 403) {
          return 'No tienes permisos para realizar esta acción';
        } else if (e.response?.statusCode == 422) {
          return 'Datos inválidos. Verifica la información proporcionada.';
        } else if (e.response?.statusCode == 500) {
          return 'Error interno del servidor. Intenta más tarde.';
        }
        return 'Error del servidor: ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'Error de conexión. Verifica tu conexión a internet.';
      case DioExceptionType.badCertificate:
        return 'Error de certificado de seguridad';
      default:
        return 'Error de red: ${e.message}';
    }
  }
}
