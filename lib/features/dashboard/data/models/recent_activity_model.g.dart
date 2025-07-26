// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecentActivityModel _$RecentActivityModelFromJson(Map<String, dynamic> json) =>
    RecentActivityModel(
      id: json['id'] as String,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      relatedId: json['relatedId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RecentActivityModelToJson(
        RecentActivityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'relatedId': instance.relatedId,
      'metadata': instance.metadata,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.invoice: 'invoice',
  ActivityType.payment: 'payment',
  ActivityType.product: 'product',
  ActivityType.customer: 'customer',
  ActivityType.expense: 'expense',
  ActivityType.sale: 'sale',
  ActivityType.order: 'order',
  ActivityType.user: 'user',
  ActivityType.system: 'system',
};
