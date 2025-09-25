// lib/app/core/models/paginated_result.dart
import 'pagination_meta.dart';

class PaginatedResult<T> {
  final List<T> data;
  final PaginationMeta? meta;

  const PaginatedResult({
    required this.data,
    this.meta,
  });

  // Helper getters
  bool get hasNextPage => meta?.hasNext ?? false;
  bool get hasPreviousPage => meta?.hasPrev ?? false;
  int get totalItems => meta?.total ?? data.length;
  int get totalPages => meta?.totalPages ?? 1;
  int get currentPage => meta?.page ?? 1;

  // Factory constructor for creating an empty result
  factory PaginatedResult.empty() {
    return PaginatedResult<T>(
      data: [],
      meta: null,
    );
  }

  // Factory constructor for creating a result without pagination
  factory PaginatedResult.single(List<T> data) {
    return PaginatedResult<T>(
      data: data,
      meta: null,
    );
  }

  // Map function to transform data while preserving pagination
  PaginatedResult<R> map<R>(R Function(T) transform) {
    return PaginatedResult<R>(
      data: data.map(transform).toList(),
      meta: meta,
    );
  }

  @override
  String toString() {
    return 'PaginatedResult(data: ${data.length} items, meta: $meta)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PaginatedResult<T> &&
        other.data == data &&
        other.meta == meta;
  }

  @override
  int get hashCode => data.hashCode ^ meta.hashCode;
}