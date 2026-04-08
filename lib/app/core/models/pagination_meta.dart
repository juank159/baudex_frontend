// lib/app/core/models/pagination_meta.dart
import 'package:equatable/equatable.dart';

class PaginationMeta extends Equatable {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  // Aliases para compatibilidad con código existente
  int get total => totalItems;
  bool get hasNext => hasNextPage;
  bool get hasPrev => hasPreviousPage;
  int get currentPage => page;

  @override
  List<Object?> get props => [
    page,
    limit,
    totalItems,
    totalPages,
    hasNextPage,
    hasPreviousPage,
  ];

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: _parseIntSafe(json['page'], 1),
      limit: _parseIntSafe(json['limit'], 20),
      totalItems: _parseIntSafe(json['totalItems'], 0),
      totalPages: _parseIntSafe(json['totalPages'], 1),
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }

  /// Parsea un valor que puede venir como int, num o String del servidor
  static int _parseIntSafe(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'totalItems': totalItems,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  PaginationMeta copyWith({
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
    bool? hasNextPage,
    bool? hasPreviousPage,
  }) {
    return PaginationMeta(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
    );
  }

  factory PaginationMeta.empty() {
    return const PaginationMeta(
      page: 1,
      limit: 20,
      totalItems: 0,
      totalPages: 1,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
}

class PaginatedResult<T> extends Equatable {
  final List<T> data;
  final PaginationMeta meta;

  const PaginatedResult({required this.data, required this.meta});

  @override
  List<Object?> get props => [data, meta];

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResult(
      data:
          (json['data'] as List?)
              ?.map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList() ??
          [],
      meta: PaginationMeta.fromJson(json['meta'] ?? {}),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'data': data.map((item) => toJsonT(item)).toList(),
      'meta': meta.toJson(),
    };
  }

  PaginatedResult<T> copyWith({List<T>? data, PaginationMeta? meta}) {
    return PaginatedResult<T>(data: data ?? this.data, meta: meta ?? this.meta);
  }

  factory PaginatedResult.empty() {
    return PaginatedResult<T>(data: const [], meta: PaginationMeta.empty());
  }
}
