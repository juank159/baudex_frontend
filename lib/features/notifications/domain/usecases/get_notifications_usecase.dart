// lib/features/notifications/domain/usecases/get_notifications_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase
    implements UseCase<PaginatedResult<Notification>, GetNotificationsParams> {
  final NotificationRepository repository;

  const GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, PaginatedResult<Notification>>> call(
    GetNotificationsParams params,
  ) async {
    return await repository.getNotifications(
      page: params.page,
      limit: params.limit,
      unreadOnly: params.unreadOnly,
      type: params.type,
      priority: params.priority,
      startDate: params.startDate,
      endDate: params.endDate,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}

class GetNotificationsParams extends Equatable {
  final int page;
  final int limit;
  final bool? unreadOnly;
  final NotificationType? type;
  final NotificationPriority? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? sortBy;
  final String? sortOrder;

  const GetNotificationsParams({
    this.page = 1,
    this.limit = 20,
    this.unreadOnly,
    this.type,
    this.priority,
    this.startDate,
    this.endDate,
    this.sortBy = 'timestamp',
    this.sortOrder = 'DESC',
  });

  @override
  List<Object?> get props => [
    page,
    limit,
    unreadOnly,
    type,
    priority,
    startDate,
    endDate,
    sortBy,
    sortOrder,
  ];

  GetNotificationsParams copyWith({
    int? page,
    int? limit,
    bool? unreadOnly,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) {
    return GetNotificationsParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
