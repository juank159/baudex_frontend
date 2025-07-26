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

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) =>
      _$RecentActivityModelFromJson(json);

  Map<String, dynamic> toJson() => _$RecentActivityModelToJson(this);
}