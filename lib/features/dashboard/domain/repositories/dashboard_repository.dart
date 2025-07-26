// lib/features/dashboard/domain/repositories/dashboard_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/dashboard_stats.dart';
import '../entities/recent_activity.dart';
import '../entities/notification.dart';

abstract class DashboardRepository {
  /// Obtiene las estadísticas del dashboard
  Future<Either<Failure, DashboardStats>> getDashboardStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Obtiene la actividad reciente
  Future<Either<Failure, List<RecentActivity>>> getRecentActivity({
    int limit = 20,
    List<ActivityType>? types,
  });

  /// Obtiene las notificaciones del usuario
  Future<Either<Failure, List<Notification>>> getNotifications({
    int limit = 50,
    bool? unreadOnly,
  });

  /// Marca una notificación como leída
  Future<Either<Failure, Notification>> markNotificationAsRead(String notificationId);

  /// Marca todas las notificaciones como leídas
  Future<Either<Failure, void>> markAllNotificationsAsRead();

  /// Elimina una notificación
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Obtiene el conteo de notificaciones no leídas
  Future<Either<Failure, int>> getUnreadNotificationsCount();

  /// Obtiene estadísticas específicas por módulo
  Future<Either<Failure, SalesStats>> getSalesStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, InvoiceStats>> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, ProductStats>> getProductStats();

  Future<Either<Failure, CustomerStats>> getCustomerStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, ExpenseStats>> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  });
}