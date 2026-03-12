// lib/features/notifications/domain/usecases/get_notification_by_id_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationByIdUseCase
    implements UseCase<Notification, GetNotificationByIdParams> {
  final NotificationRepository repository;

  const GetNotificationByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Notification>> call(
    GetNotificationByIdParams params,
  ) async {
    return await repository.getNotificationById(params.id);
  }
}

class GetNotificationByIdParams extends Equatable {
  final String id;

  const GetNotificationByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}
