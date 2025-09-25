// lib/features/dashboard/data/models/recent_activity_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/recent_activity.dart';

part 'recent_activity_model.g.dart';

@JsonSerializable()
class RecentActivityModel extends RecentActivity {
  const RecentActivityModel({
    required String id,
    required ActivityType type,
    required String title,
    required String description,
    required DateTime timestamp,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) : super(
          id: id,
          type: type,
          title: title,
          description: description,
          timestamp: timestamp,
          relatedId: relatedId,
          metadata: metadata,
        );

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    // Temporalmente sin generación automática
    return RecentActivityModel(
      id: json['id'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ActivityType.invoice,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      relatedId: json['relatedId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    // Temporalmente sin generación automática
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'relatedId': relatedId,
      'metadata': metadata,
    };
  }
}