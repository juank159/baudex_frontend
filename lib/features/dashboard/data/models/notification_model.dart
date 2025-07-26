// lib/features/dashboard/data/models/notification_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/notification.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel extends Notification {
  const NotificationModel({
    required String id,
    required NotificationType type,
    required String title,
    required String message,
    required DateTime timestamp,
    required bool isRead,
    required NotificationPriority priority,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) : super(
          id: id,
          type: type,
          title: title,
          message: message,
          timestamp: timestamp,
          isRead: isRead,
          priority: priority,
          relatedId: relatedId,
          actionData: actionData,
        );

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  @override
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationPriority? priority,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      relatedId: relatedId ?? this.relatedId,
      actionData: actionData ?? this.actionData,
    );
  }
}