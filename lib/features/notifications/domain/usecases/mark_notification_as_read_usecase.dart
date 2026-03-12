// lib/features/notifications/domain/usecases/mark_notification_as_read_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationAsReadUseCase
    implements UseCase<Notification, MarkNotificationAsReadParams> {
  final NotificationRepository repository;

  const MarkNotificationAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, Notification>> call(
    MarkNotificationAsReadParams params,
  ) async {
    return await repository.markAsRead(params.id);
  }
}

class MarkNotificationAsReadParams extends Equatable {
  final String id;

  const MarkNotificationAsReadParams({required this.id});

  @override
  List<Object> get props => [id];
}
