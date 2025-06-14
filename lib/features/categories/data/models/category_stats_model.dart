// lib/features/categories/data/models/category_stats_model.dart
import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';

import '../../domain/repositories/category_repository.dart';

class CategoryStatsModel extends CategoryStats {
  const CategoryStatsModel({
    required super.total,
    required super.active,
    required super.inactive,
    required super.parents,
    required super.children,
    required super.deleted,
  });

  factory CategoryStatsModel.fromJson(Map<String, dynamic> json) {
    return CategoryStatsModel(
      total: json['total'] as int? ?? 0,
      active: json['active'] as int? ?? 0,
      inactive: json['inactive'] as int? ?? 0,
      parents: json['parents'] as int? ?? 0,
      children: json['children'] as int? ?? 0,
      deleted: json['deleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active': active,
      'inactive': inactive,
      'parents': parents,
      'children': children,
      'deleted': deleted,
    };
  }

  CategoryStats toEntity() {
    return CategoryStats(
      total: total,
      active: active,
      inactive: inactive,
      parents: parents,
      children: children,
      deleted: deleted,
    );
  }

  factory CategoryStatsModel.fromEntity(CategoryStats stats) {
    return CategoryStatsModel(
      total: stats.total,
      active: stats.active,
      inactive: stats.inactive,
      parents: stats.parents,
      children: stats.children,
      deleted: stats.deleted,
    );
  }

  @override
  String toString() =>
      'CategoryStatsModel(total: $total, active: $active, inactive: $inactive)';
}
