// lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../models/dashboard_stats_model.dart';
import '../models/profitability_stats_model.dart';
import '../models/recent_activity_model.dart';
import '../models/notification_model.dart';
import '../../domain/entities/recent_activity.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<RecentActivityModel>> getRecentActivity({
    int limit = 20,
    List<ActivityType>? types,
  });

  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    bool? unreadOnly,
  });

  Future<NotificationModel> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<int> getUnreadNotificationsCount();

  // Nuevos métodos que coinciden con el backend
  Future<List<Map<String, dynamic>>> getTopProducts({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getTopCustomers({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getCategorySales({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getExpensesBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getCashFlow({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<Map<String, dynamic>>> getPaymentMethodStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Map<String, dynamic>> getFinancialKPIs({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<SalesStatsModel> getSalesStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<InvoiceStatsModel> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ProductStatsModel> getProductStats();

  Future<CustomerStatsModel> getCustomerStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ExpenseStatsModel> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ProfitabilityStatsModel> getProfitabilityStats({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? categoryId,
  });
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient dioClient;

  DashboardRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<DashboardStatsModel> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = AppFormatters.formatDateForApi(startDate);
      }
      if (endDate != null) {
        queryParams['endDate'] = AppFormatters.formatDateForApi(endDate);
      }

      final response = await dioClient.get(
        '/dashboard/summary',
        queryParameters: queryParams,
      );

      return DashboardStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas del dashboard',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas del dashboard: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<RecentActivityModel>> getRecentActivity({
    int limit = 20,
    List<ActivityType>? types,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (types != null && types.isNotEmpty) {
        queryParams['types'] = types.map((t) => t.name).join(',');
      }

      // TODO: Implementar endpoint de actividad reciente en el backend
      // Por ahora retornamos lista vacía
      return <RecentActivityModel>[];
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener actividad reciente',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener actividad reciente: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int limit = 50,
    bool? unreadOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (unreadOnly != null) {
        queryParams['unreadOnly'] = unreadOnly;
      }

      // TODO: Implementar endpoint de notificaciones en el backend
      // Por ahora retornamos lista vacía
      return <NotificationModel>[];
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener notificaciones',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener notificaciones: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<NotificationModel> markNotificationAsRead(String notificationId) async {
    try {
      // TODO: Implementar endpoint para marcar notificación como leída
      throw ServerException(
        'Funcionalidad de notificaciones no implementada en el backend',
        statusCode: 501,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al marcar notificación como leída',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al marcar notificación como leída: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> markAllNotificationsAsRead() async {
    try {
      // TODO: Implementar endpoint para marcar todas las notificaciones como leídas
      throw ServerException(
        'Funcionalidad de notificaciones no implementada en el backend',
        statusCode: 501,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al marcar todas las notificaciones como leídas',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al marcar todas las notificaciones como leídas: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      // TODO: Implementar endpoint para eliminar notificación
      throw ServerException(
        'Funcionalidad de notificaciones no implementada en el backend',
        statusCode: 501,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al eliminar notificación',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al eliminar notificación: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<int> getUnreadNotificationsCount() async {
    try {
      // TODO: Implementar endpoint para conteo de notificaciones no leídas
      return 0;
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener conteo de notificaciones',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener conteo de notificaciones: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<SalesStatsModel> getSalesStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/charts/sales',
        queryParameters: queryParams,
      );

      return SalesStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas de ventas',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas de ventas: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<InvoiceStatsModel> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      // TODO: Implementar endpoint específico para estadísticas de facturas
      // Por ahora obtenemos datos del resumen general
      final response = await dioClient.get(
        '/dashboard/summary',
        queryParameters: queryParams,
      );

      return InvoiceStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas de facturas',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas de facturas: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ProductStatsModel> getProductStats() async {
    try {
      // TODO: Implementar endpoint específico para estadísticas de productos
      // Por ahora obtenemos datos del resumen general
      final response = await dioClient.get(
        '/dashboard/summary',
      );

      return ProductStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas de productos',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas de productos: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<CustomerStatsModel> getCustomerStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      // TODO: Implementar endpoint específico para estadísticas de clientes
      // Por ahora obtenemos datos del top-customers
      final response = await dioClient.get(
        '/dashboard/top-customers',
        queryParameters: queryParams,
      );

      return CustomerStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas de clientes',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas de clientes: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseStatsModel> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/expenses-breakdown',
        queryParameters: queryParams,
      );

      return ExpenseStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas de gastos',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas de gastos: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTopProducts({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/top-products',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener productos más vendidos',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTopCustomers({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/top-customers',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener mejores clientes',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCategorySales({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/category-sales',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener ventas por categoría',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getExpensesBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/expenses-breakdown',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener desglose de gastos',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCashFlow({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/cash-flow',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener flujo de caja',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentMethodStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/payment-methods',
        queryParameters: queryParams,
      );

      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas de métodos de pago',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getFinancialKPIs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dioClient.get(
        '/dashboard/kpis',
        queryParameters: queryParams,
      );

      return Map<String, dynamic>.from(response.data['data'] ?? {});
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener KPIs financieros',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<ProfitabilityStatsModel> getProfitabilityStats({
    DateTime? startDate,
    DateTime? endDate,
    String? warehouseId,
    String? categoryId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (warehouseId != null) {
        queryParams['warehouseId'] = warehouseId;
      }
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
      }

      // ✅ USAR ENDPOINT CORRECTO CON FILTROS: /dashboard/profitability
      final response = await dioClient.get(
        '/dashboard/profitability',
        queryParameters: queryParams,
      );
      
      // Extraer datos de la respuesta del endpoint real
      // Backend envuelve la respuesta con {success: true, data: {...}, timestamp: "..."}
      final responseData = response.data['data'];
      print('🔍 PROFITABILITY DEBUG: Full response = ${response.data}');
      print('🔍 PROFITABILITY DEBUG: Data portion = ${responseData}');
      return ProfitabilityStatsModel.fromJson(responseData);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener métricas de rentabilidad',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener métricas de rentabilidad: $e',
        statusCode: 500,
      );
    }
  }
}