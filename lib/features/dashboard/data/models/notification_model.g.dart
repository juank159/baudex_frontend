// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool,
      priority: $enumDecode(_$NotificationPriorityEnumMap, json['priority']),
      relatedId: json['relatedId'] as String?,
      actionData: json['actionData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'isRead': instance.isRead,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'relatedId': instance.relatedId,
      'actionData': instance.actionData,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.system: 'system',
  NotificationType.payment: 'payment',
  NotificationType.invoice: 'invoice',
  NotificationType.lowStock: 'lowStock',
  NotificationType.expense: 'expense',
  NotificationType.sale: 'sale',
  NotificationType.user: 'user',
  NotificationType.reminder: 'reminder',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.medium: 'medium',
  NotificationPriority.high: 'high',
  NotificationPriority.urgent: 'urgent',
};
