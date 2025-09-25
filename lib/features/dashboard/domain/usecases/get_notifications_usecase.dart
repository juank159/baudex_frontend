// lib/features/dashboard/domain/usecases/get_notifications_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../entities/notification.dart';
import '../repositories/dashboard_repository.dart';

class GetNotificationsUseCase implements UseCase<List<Notification>, GetNotificationsParams> {
  final DashboardRepository repository;

  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Notification>>> call(GetNotificationsParams params) async {
    return await repository.getNotifications(
      limit: params.limit,
      unreadOnly: params.unreadOnly,
    );
  }
}

class GetNotificationsParams {
  final int limit;
  final bool? unreadOnly;

  GetNotificationsParams({
    this.limit = 50,
    this.unreadOnly,
  });
}