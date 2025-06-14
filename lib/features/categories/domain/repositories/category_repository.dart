// // lib/features/categories/domain/repositories/category_repository.dart
// import 'package:dartz/dartz.dart';
// import '../../../../app/core/errors/failures.dart';
// import '../entities/category.dart';
// import '../entities/category_tree.dart';

// abstract class CategoryRepository {
//   // Read operations
//   Future<Either<Failure, PaginatedResult<Category>>> getCategories({
//     int page = 1,
//     int limit = 10,
//     String? search,
//     CategoryStatus? status,
//     String? parentId,
//     bool? onlyParents,
//     bool? includeChildren,
//     String? sortBy,
//     String? sortOrder,
//   });

//   Future<Either<Failure, Category>> getCategoryById(String id);
//   Future<Either<Failure, Category>> getCategoryBySlug(String slug);
//   Future<Either<Failure, List<CategoryTree>>> getCategoryTree();
//   Future<Either<Failure, CategoryStats>> getCategoryStats();
//   Future<Either<Failure, List<Category>>> searchCategories(
//     String searchTerm, {
//     int limit = 10,
//   });

//   // Write operations
//   Future<Either<Failure, Category>> createCategory({
//     required String name,
//     String? description,
//     required String slug,
//     String? image,
//     CategoryStatus? status,
//     int? sortOrder,
//     String? parentId,
//   });

//   Future<Either<Failure, Category>> updateCategory({
//     required String id,
//     String? name,
//     String? description,
//     String? slug,
//     String? image,
//     CategoryStatus? status,
//     int? sortOrder,
//     String? parentId,
//   });

//   Future<Either<Failure, Category>> updateCategoryStatus({
//     required String id,
//     required CategoryStatus status,
//   });

//   Future<Either<Failure, Unit>> deleteCategory(String id);
//   Future<Either<Failure, Category>> restoreCategory(String id);

//   // Utility operations
//   Future<Either<Failure, bool>> isSlugAvailable(
//     String slug, {
//     String? excludeId,
//   });

//   Future<Either<Failure, String>> generateUniqueSlug(String name);

//   Future<Either<Failure, Unit>> reorderCategories(
//     List<CategoryReorder> reorders,
//   );

//   // Cache operations
//   Future<Either<Failure, List<Category>>> getCachedCategories();
//   Future<Either<Failure, Unit>> clearCategoryCache();
// }

// // Helper classes
// class PaginatedResult<T> {
//   final List<T> data;
//   final PaginationMeta meta;

//   const PaginatedResult({required this.data, required this.meta});
// }

// class PaginationMeta {
//   final int page;
//   final int limit;
//   final int totalItems;
//   final int totalPages;
//   final bool hasNextPage;
//   final bool hasPreviousPage;

//   const PaginationMeta({
//     required this.page,
//     required this.limit,
//     required this.totalItems,
//     required this.totalPages,
//     required this.hasNextPage,
//     required this.hasPreviousPage,
//   });
// }

// class CategoryStats {
//   final int total;
//   final int active;
//   final int inactive;
//   final int parents;
//   final int children;
//   final int deleted;

//   const CategoryStats({
//     required this.total,
//     required this.active,
//     required this.inactive,
//     required this.parents,
//     required this.children,
//     required this.deleted,
//   });
// }

// class CategoryReorder {
//   final String id;
//   final int sortOrder;

//   const CategoryReorder({required this.id, required this.sortOrder});
// }

// lib/features/categories/domain/repositories/category_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/category.dart';
import '../entities/category_tree.dart';
import '../entities/category_stats.dart';

abstract class CategoryRepository {
  // Read operations
  Future<Either<Failure, PaginatedResult<Category>>> getCategories({
    int page = 1,
    int limit = 10,
    String? search,
    CategoryStatus? status,
    String? parentId,
    bool? onlyParents,
    bool? includeChildren,
    String? sortBy,
    String? sortOrder,
  });

  Future<Either<Failure, Category>> getCategoryById(String id);
  Future<Either<Failure, Category>> getCategoryBySlug(String slug);
  Future<Either<Failure, List<CategoryTree>>> getCategoryTree();
  Future<Either<Failure, CategoryStats>> getCategoryStats();
  Future<Either<Failure, List<Category>>> searchCategories(
    String searchTerm, {
    int limit = 10,
  });

  // Write operations
  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? description,
    required String slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
  });

  Future<Either<Failure, Category>> updateCategory({
    required String id,
    String? name,
    String? description,
    String? slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
  });

  Future<Either<Failure, Category>> updateCategoryStatus({
    required String id,
    required CategoryStatus status,
  });

  Future<Either<Failure, Unit>> deleteCategory(String id);
  Future<Either<Failure, Category>> restoreCategory(String id);

  // Utility operations
  Future<Either<Failure, bool>> isSlugAvailable(
    String slug, {
    String? excludeId,
  });

  Future<Either<Failure, String>> generateUniqueSlug(String name);

  Future<Either<Failure, Unit>> reorderCategories(
    List<CategoryReorder> reorders,
  );

  // Cache operations
  Future<Either<Failure, List<Category>>> getCachedCategories();
  Future<Either<Failure, Unit>> clearCategoryCache();
}

// Helper class específica de categorías
class CategoryReorder {
  final String id;
  final int sortOrder;

  const CategoryReorder({required this.id, required this.sortOrder});
}
