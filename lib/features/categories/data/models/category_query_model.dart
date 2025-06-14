// // lib/features/categories/data/models/category_query_model.dart
// import '../../domain/entities/category.dart';

// class CategoryQueryModel {
//   final int page;
//   final int limit;
//   final String? search;
//   final CategoryStatus? status;
//   final String? parentId;
//   final bool? onlyParents;
//   final bool? includeChildren;
//   final String? sortBy;
//   final String? sortOrder;

//   const CategoryQueryModel({
//     this.page = 1,
//     this.limit = 10,
//     this.search,
//     this.status,
//     this.parentId,
//     this.onlyParents,
//     this.includeChildren,
//     this.sortBy,
//     this.sortOrder,
//   });

//   Map<String, dynamic> toQueryParameters() {
//     final params = <String, dynamic>{'page': page, 'limit': limit};

//     if (search != null && search!.isNotEmpty) {
//       params['search'] = search;
//     }
//     if (status != null) {
//       params['status'] = status!.name;
//     }
//     if (parentId != null) {
//       params['parentId'] = parentId;
//     }
//     if (onlyParents != null) {
//       params['onlyParents'] = onlyParents.toString();
//     }
//     if (includeChildren != null) {
//       params['includeChildren'] = includeChildren.toString();
//     }
//     if (sortBy != null) {
//       params['sortBy'] = sortBy;
//     }
//     if (sortOrder != null) {
//       params['sortOrder'] = sortOrder;
//     }

//     return params;
//   }

//   CategoryQueryModel copyWith({
//     int? page,
//     int? limit,
//     String? search,
//     CategoryStatus? status,
//     String? parentId,
//     bool? onlyParents,
//     bool? includeChildren,
//     String? sortBy,
//     String? sortOrder,
//   }) {
//     return CategoryQueryModel(
//       page: page ?? this.page,
//       limit: limit ?? this.limit,
//       search: search ?? this.search,
//       status: status ?? this.status,
//       parentId: parentId ?? this.parentId,
//       onlyParents: onlyParents ?? this.onlyParents,
//       includeChildren: includeChildren ?? this.includeChildren,
//       sortBy: sortBy ?? this.sortBy,
//       sortOrder: sortOrder ?? this.sortOrder,
//     );
//   }

//   @override
//   String toString() =>
//       'CategoryQueryModel(page: $page, limit: $limit, search: $search)';
// }

// lib/features/categories/data/models/category_query_model.dart
import '../../domain/entities/category.dart';

class CategoryQueryModel {
  final int page;
  final int limit;
  final String? search;
  final CategoryStatus? status;
  final String? parentId;
  final bool? onlyParents;
  final bool? includeChildren;
  final String? sortBy;
  final String? sortOrder;

  const CategoryQueryModel({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.parentId,
    this.onlyParents,
    this.includeChildren,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{'page': page, 'limit': limit};

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (status != null) {
      params['status'] = status!.name;
    }

    // ✅ CORRECCIÓN CRÍTICA: Usar onlyParents en lugar de parentId=parents_only
    if (onlyParents == true) {
      params['onlyParents'] = 'true';
    } else if (parentId != null) {
      // Solo usar parentId si no es el valor especial y onlyParents no está activo
      params['parentId'] = parentId;
    }

    if (includeChildren != null) {
      params['includeChildren'] = includeChildren.toString();
    }
    if (sortBy != null) {
      params['sortBy'] = sortBy;
    }
    if (sortOrder != null) {
      params['sortOrder'] = sortOrder;
    }

    print('🔧 Query parameters being sent: $params'); // ✅ Log para debugging

    return params;
  }

  CategoryQueryModel copyWith({
    int? page,
    int? limit,
    String? search,
    CategoryStatus? status,
    String? parentId,
    bool? onlyParents,
    bool? includeChildren,
    String? sortBy,
    String? sortOrder,
  }) {
    return CategoryQueryModel(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      status: status ?? this.status,
      parentId: parentId ?? this.parentId,
      onlyParents: onlyParents ?? this.onlyParents,
      includeChildren: includeChildren ?? this.includeChildren,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() =>
      'CategoryQueryModel(page: $page, limit: $limit, search: $search, onlyParents: $onlyParents)';
}
