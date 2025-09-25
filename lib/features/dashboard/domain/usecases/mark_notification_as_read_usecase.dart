// lib/features/dashboard/domain/usecases/mark_notification_as_read_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/notification.dart';
import '../repositories/dashboard_repository.dart';

class MarkNotificationAsReadUseCase implements UseCase<Notification, MarkNotificationAsReadParams> {
  final DashboardRepository repository;

  MarkNotificationAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, Notification>> call(MarkNotificationAsReadParams params) async {
    return await repository.markNotificationAsRead(params.notificationId);
  }
}

class MarkNotificationAsReadParams {
  final String notificationId;

  MarkNotificationAsReadParams({required this.notificationId});
}