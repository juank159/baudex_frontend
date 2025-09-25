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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Temporalmente sin generación automática
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      isRead: json['isRead'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      relatedId: json['relatedId'],
      actionData: json['actionData'],
    );
  }

  Map<String, dynamic> toJson() {
    // Temporalmente sin generación automática
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
      'relatedId': relatedId,
      'actionData': actionData,
    };
  }

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