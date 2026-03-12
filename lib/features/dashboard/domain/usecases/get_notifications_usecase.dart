// lib/features/dashboard/domain/usecases/get_notifications_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/notification.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardNotificationsUseCase implements UseCase<List<Notification>, GetDashboardNotificationsParams> {
  final DashboardRepository repository;

  GetDashboardNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Notification>>> call(GetDashboardNotificationsParams params) async {
    return await repository.getNotifications(
      limit: params.limit,
      unreadOnly: params.unreadOnly,
    );
  }
}

class GetDashboardNotificationsParams {
  final int limit;
  final bool? unreadOnly;

  GetDashboardNotificationsParams({
    this.limit = 50,
    this.unreadOnly,
  });
}