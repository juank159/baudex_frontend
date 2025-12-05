// lib/features/dashboard/data/models/smart_notification_model.dart
import 'package:flutter/material.dart';
import '../../domain/entities/smart_notification.dart';

class SmartNotificationModel extends SmartNotification {
  const SmartNotificationModel({
    required super.id,
    required super.type,
    required super.priority,
    required super.status,
    required super.channels,
    required super.title,
    required super.message,
    super.richContent,
    super.entityId,
    super.entityType,
    super.actionUrl,
    super.actionLabel,
    super.metadata,
    required super.icon,
    required super.color,
    super.scheduledFor,
    super.expiresAt,
    super.retryCount = 0,
    super.maxRetries = 3,
    super.sentAt,
    super.deliveredAt,
    super.readAt,
    super.archivedAt,
    super.isGrouped = false,
    super.groupKey,
    required super.userId,
    required super.organizationId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SmartNotificationModel.fromJson(Map<String, dynamic> json) {
    return SmartNotificationModel(
      id: json['id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      priority: NotificationPriority.fromString(json['priority'] as String),
      status: NotificationStatus.fromString(json['status'] as String),
      channels:
          (json['channels'] as List<dynamic>)
              .map(
                (channel) => NotificationChannel.fromString(channel as String),
              )
              .toList(),
      title: json['title'] as String,
      message: json['message'] as String,
      richContent: json['richContent'] as String?,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      actionUrl: json['actionUrl'] as String?,
      actionLabel: json['actionLabel'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      icon: json['icon'] as String,
      color: Color(
        int.parse(json['color'].toString().replaceFirst('#', '0xFF')),
      ),
      scheduledFor:
          json['scheduledFor'] != null
              ? DateTime.parse(json['scheduledFor'] as String)
              : null,
      expiresAt:
          json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      retryCount: json['retryCount'] as int? ?? 0,
      maxRetries: json['maxRetries'] as int? ?? 3,
      sentAt:
          json['sentAt'] != null
              ? DateTime.parse(json['sentAt'] as String)
              : null,
      deliveredAt:
          json['deliveredAt'] != null
              ? DateTime.parse(json['deliveredAt'] as String)
              : null,
      readAt:
          json['readAt'] != null
              ? DateTime.parse(json['readAt'] as String)
              : null,
      archivedAt:
          json['archivedAt'] != null
              ? DateTime.parse(json['archivedAt'] as String)
              : null,
      isGrouped: json['isGrouped'] as bool? ?? false,
      groupKey: json['groupKey'] as String?,
      userId: json['userId'] as String,
      organizationId: json['organizationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'priority': priority.value,
      'status': status.value,
      'channels': channels.map((channel) => channel.value).toList(),
      'title': title,
      'message': message,
      'richContent': richContent,
      'entityId': entityId,
      'entityType': entityType,
      'actionUrl': actionUrl,
      'actionLabel': actionLabel,
      'metadata': metadata,
      'icon': icon,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'scheduledFor': scheduledFor?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'sentAt': sentAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'isGrouped': isGrouped,
      'groupKey': groupKey,
      'userId': userId,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
