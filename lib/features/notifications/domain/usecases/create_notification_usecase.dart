// lib/features/notifications/domain/usecases/create_notification_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../dashboard/domain/entities/notification.dart';
import '../repositories/notification_repository.dart';

class CreateNotificationUseCase
    implements UseCase<Notification, CreateNotificationParams> {
  final NotificationRepository repository;

  const CreateNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, Notification>> call(
    CreateNotificationParams params,
  ) async {
    return await repository.createNotification(
      type: params.type,
      title: params.title,
      message: params.message,
      priority: params.priority,
      relatedId: params.relatedId,
      actionData: params.actionData,
    );
  }
}

class CreateNotificationParams extends Equatable {
  final NotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final String? relatedId;
  final Map<String, dynamic>? actionData;

  const CreateNotificationParams({
    required this.type,
    required this.title,
    required this.message,
    this.priority = NotificationPriority.medium,
    this.relatedId,
    this.actionData,
  });

  @override
  List<Object?> get props => [
    type,
    title,
    message,
    priority,
    relatedId,
    actionData,
  ];

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'title': title,
    'message': message,
    'priority': priority.name,
    if (relatedId != null) 'relatedId': relatedId,
    if (actionData != null) 'actionData': actionData,
  };
}
