// lib/features/dashboard/data/models/recent_activity_advanced_model.dart
import 'package:flutter/material.dart';
import '../../domain/entities/recent_activity_advanced.dart';

class RecentActivityAdvancedModel extends RecentActivityAdvanced {
  const RecentActivityAdvancedModel({
    required super.id,
    required super.type,
    required super.category,
    required super.priority,
    required super.title,
    required super.description,
    super.entityId,
    super.entityType,
    super.metadata,
    required super.icon,
    required super.color,
    super.isSystemGenerated = false,
    super.ipAddress,
    super.userAgent,
    required super.userId,
    required super.userName,
    required super.organizationId,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RecentActivityAdvancedModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityAdvancedModel(
      id: json['id'] as String,
      type: ActivityType.fromString(json['type'] as String),
      category: ActivityCategory.fromString(json['category'] as String),
      priority: ActivityPriority.fromString(json['priority'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      icon: json['icon'] as String,
      color: Color(int.parse(json['color'].toString().replaceFirst('#', '0xFF'))),
      isSystemGenerated: json['isSystemGenerated'] as bool? ?? false,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      userId: json['userId'] as String,
      userName: json['user'] != null 
          ? '${json['user']['firstName']} ${json['user']['lastName'] ?? ''}'.trim()
          : json['userName'] as String? ?? 'Usuario',
      organizationId: json['organizationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'category': category.value,
      'priority': priority.value,
      'title': title,
      'description': description,
      'entityId': entityId,
      'entityType': entityType,
      'metadata': metadata,
      'icon': icon,
      'color': '#${color.value.toRadixString(16).substring(2)}',
      'isSystemGenerated': isSystemGenerated,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'userId': userId,
      'userName': userName,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}