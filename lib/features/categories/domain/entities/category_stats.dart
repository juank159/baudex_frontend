// lib/features/categories/domain/entities/category_stats.dart
import 'package:equatable/equatable.dart';

class CategoryStats extends Equatable {
  final int total;
  final int active;
  final int inactive;
  final int parents;
  final int children;
  final int deleted;

  const CategoryStats({
    required this.total,
    required this.active,
    required this.inactive,
    required this.parents,
    required this.children,
    required this.deleted,
  });

  // Propiedades calculadas
  double get activePercentage => total > 0 ? (active / total) * 100 : 0;
  double get inactivePercentage => total > 0 ? (inactive / total) * 100 : 0;
  double get parentsPercentage => total > 0 ? (parents / total) * 100 : 0;
  double get childrenPercentage => total > 0 ? (children / total) * 100 : 0;

  @override
  List<Object?> get props => [
    total,
    active,
    inactive,
    parents,
    children,
    deleted,
  ];

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      total: json['total'] ?? 0,
      active: json['active'] ?? 0,
      inactive: json['inactive'] ?? 0,
      parents: json['parents'] ?? 0,
      children: json['children'] ?? 0,
      deleted: json['deleted'] ?? 0,
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

  CategoryStats copyWith({
    int? total,
    int? active,
    int? inactive,
    int? parents,
    int? children,
    int? deleted,
  }) {
    return CategoryStats(
      total: total ?? this.total,
      active: active ?? this.active,
      inactive: inactive ?? this.inactive,
      parents: parents ?? this.parents,
      children: children ?? this.children,
      deleted: deleted ?? this.deleted,
    );
  }

  factory CategoryStats.empty() {
    return const CategoryStats(
      total: 0,
      active: 0,
      inactive: 0,
      parents: 0,
      children: 0,
      deleted: 0,
    );
  }
}
