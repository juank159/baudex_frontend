// lib/features/notifications/domain/usecases/delete_notification_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../repositories/notification_repository.dart';

class DeleteNotificationUseCase
    implements UseCase<Unit, DeleteNotificationParams> {
  final NotificationRepository repository;

  const DeleteNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteNotificationParams params) async {
    return await repository.deleteNotification(params.id);
  }
}

class DeleteNotificationParams extends Equatable {
  final String id;

  const DeleteNotificationParams({required this.id});

  @override
  List<Object> get props => [id];
}
