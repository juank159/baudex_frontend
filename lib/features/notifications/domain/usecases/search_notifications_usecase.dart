// lib/features/notifications/domain/usecases/search_notifications_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../repositories/notification_repository.dart';

class SearchNotificationsUseCase
    implements UseCase<List<Notification>, SearchNotificationsParams> {
  final NotificationRepository repository;

  const SearchNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Notification>>> call(
    SearchNotificationsParams params,
  ) async {
    return await repository.searchNotifications(
      params.query,
      limit: params.limit,
    );
  }
}

class SearchNotificationsParams extends Equatable {
  final String query;
  final int limit;

  const SearchNotificationsParams({
    required this.query,
    this.limit = 10,
  });

  @override
  List<Object> get props => [query, limit];
}
