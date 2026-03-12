// lib/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/notification.dart';
import '../repositories/dashboard_repository.dart';

class MarkDashboardNotificationAsReadUseCase implements UseCase<Notification, MarkDashboardNotificationAsReadParams> {
  final DashboardRepository repository;

  MarkDashboardNotificationAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, Notification>> call(MarkDashboardNotificationAsReadParams params) async {
    return await repository.markNotificationAsRead(params.notificationId);
  }
}

class MarkDashboardNotificationAsReadParams {
  final String notificationId;

  MarkDashboardNotificationAsReadParams({required this.notificationId});
}