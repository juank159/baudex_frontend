// lib/features/categories/data/repositories/category_offline_repository.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/entities/category_stats.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/isar/isar_category.dart';

/// Implementación offline del repositorio de categorías usando ISAR
///
/// Proporciona todas las operaciones CRUD para categorías de forma offline-first
class CategoryOfflineRepository implements CategoryRepository {
  final IsarDatabase _database;

  CategoryOfflineRepository({IsarDatabase? database})
    : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database;

  // ==================== READ OPERATIONS ====================

  @override
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
  }) async {
    try {
      final collection = _isar.isarCategorys;

      // Build base query builder for filtering
      QueryBuilder<IsarCategory, IsarCategory, QAfterFilterCondition> filterQuery;

      // Start with a base filter (soft delete filter)
      filterQuery = collection.filter().deletedAtIsNull();

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        filterQuery = filterQuery.and().nameContains(search, caseSensitive: false);
      }

      // Apply status filter
      if (status != null) {
        final isarStatus =
            status == CategoryStatus.active
                ? IsarCategoryStatus.active
                : IsarCategoryStatus.inactive;
        filterQuery = filterQuery.and().statusEqualTo(isarStatus);
      }

      // Apply parent filter
      if (parentId != null) {
        filterQuery = filterQuery.and().parentIdEqualTo(parentId);
      } else if (onlyParents == true) {
        filterQuery = filterQuery.and().parentIdIsNull();
      }

      // Get total count for pagination
      final totalItems = await filterQuery.count();

      // Apply sorting and pagination
      final offset = (page - 1) * limit;
      List<IsarCategory> isarCategories;
      
      switch (sortBy) {
        case 'name':
          isarCategories = sortOrder == 'desc' 
              ? await filterQuery.sortByNameDesc().offset(offset).limit(limit).findAll()
              : await filterQuery.sortByName().offset(offset).limit(limit).findAll();
          break;
        case 'created_at':
          isarCategories = sortOrder == 'desc'
              ? await filterQuery.sortByCreatedAtDesc().offset(offset).limit(limit).findAll()
              : await filterQuery.sortByCreatedAt().offset(offset).limit(limit).findAll();
          break;
        case 'sort_order':
          isarCategories = sortOrder == 'desc'
              ? await filterQuery.sortBySortOrderDesc().offset(offset).limit(limit).findAll()
              : await filterQuery.sortBySortOrder().offset(offset).limit(limit).findAll();
          break;
        default:
          isarCategories = await filterQuery.sortBySortOrder().offset(offset).limit(limit).findAll();
      }

      // Convert to domain entities
      final categories = isarCategories.map((isar) => isar.toEntity()).toList();

      // If includeChildren is true, load children for each category
      if (includeChildren == true) {
        // Note: This would require modifying the Category entity to include children
        // For now, children are loaded separately via getCategoryTree()
        // Future enhancement: Load children and attach to category entities
      }

      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(PaginatedResult(data: categories, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading categories: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    try {
      final isarCategory =
          await _isar.isarCategorys
              .filter()
              .serverIdEqualTo(id)
              .and()
              .deletedAtIsNull()
              .findFirst();

      if (isarCategory == null) {
        return Left(CacheFailure('Category not found'));
      }

      return Right(isarCategory.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryBySlug(String slug) async {
    try {
      final isarCategory =
          await _isar.isarCategorys
              .filter()
              .slugEqualTo(slug)
              .and()
              .deletedAtIsNull()
              .findFirst();

      if (isarCategory == null) {
        return Left(CacheFailure('Category not found'));
      }

      return Right(isarCategory.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryTree>>> getCategoryTree() async {
    try {
      // Get all root categories (no parent)
      final rootCategories =
          await _isar.isarCategorys
              .filter()
              .parentIdIsNull()
              .and()
              .deletedAtIsNull()
              .sortBySortOrder()
              .findAll();

      final tree = <CategoryTree>[];

      for (final root in rootCategories) {
        final children = await _loadCategoryChildren(root.serverId);
        final rootEntity = root.toEntity();
        tree.add(
          CategoryTree(
            id: rootEntity.id,
            name: rootEntity.name,
            slug: rootEntity.slug,
            image: rootEntity.image,
            sortOrder: rootEntity.sortOrder,
            children: children,
            productsCount: rootEntity.productsCount,
            level: 0,
            hasChildren: children.isNotEmpty,
          ),
        );
      }

      return Right(tree);
    } catch (e) {
      return Left(CacheFailure('Error loading category tree: ${e.toString()}'));
    }
  }

  Future<List<CategoryTree>> _loadCategoryChildren(
    String parentId, {
    int level = 1,
  }) async {
    final children =
        await _isar.isarCategorys
            .filter()
            .parentIdEqualTo(parentId)
            .and()
            .deletedAtIsNull()
            .sortBySortOrder()
            .findAll();

    final childTree = <CategoryTree>[];

    for (final child in children) {
      final grandChildren = await _loadCategoryChildren(
        child.serverId,
        level: level + 1,
      );
      final childEntity = child.toEntity();
      childTree.add(
        CategoryTree(
          id: childEntity.id,
          name: childEntity.name,
          slug: childEntity.slug,
          image: childEntity.image,
          sortOrder: childEntity.sortOrder,
          children: grandChildren,
          productsCount: childEntity.productsCount,
          level: level,
          hasChildren: grandChildren.isNotEmpty,
        ),
      );
    }

    return childTree;
  }

  @override
  Future<Either<Failure, CategoryStats>> getCategoryStats() async {
    try {
      final collection = _isar.isarCategorys;

      final total = await collection.filter().deletedAtIsNull().count();
      final active =
          await collection
              .filter()
              .statusEqualTo(IsarCategoryStatus.active)
              .and()
              .deletedAtIsNull()
              .count();
      final inactive =
          await collection
              .filter()
              .statusEqualTo(IsarCategoryStatus.inactive)
              .and()
              .deletedAtIsNull()
              .count();
      final parents =
          await collection.filter().parentIdIsNull().and().deletedAtIsNull().count();
      final children =
          await collection
              .filter()
              .parentIdIsNotNull()
              .and()
              .deletedAtIsNull()
              .count();
      final deleted = await collection.filter().deletedAtIsNotNull().count();

      // Calculate total products across all categories
      final categoriesWithProducts =
          await collection.filter().deletedAtIsNull().findAll();

      final totalProducts = categoriesWithProducts.fold<int>(
        0,
        (sum, cat) => sum + (cat.productsCount ?? 0),
      );

      final averageProductsPerCategory =
          total > 0 ? totalProducts / total : 0.0;

      final stats = CategoryStats(
        total: total,
        active: active,
        inactive: inactive,
        parents: parents,
        children: children,
        deleted: deleted,
        totalProducts: totalProducts,
        averageProductsPerCategory: averageProductsPerCategory,
      );

      return Right(stats);
    } catch (e) {
      return Left(
        CacheFailure('Error loading category stats: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> searchCategories(
    String searchTerm, {
    int limit = 10,
  }) async {
    try {
      final isarCategories =
          await _isar.isarCategorys
              .filter()
              .group((q) => q
                  .nameContains(searchTerm, caseSensitive: false)
                  .or()
                  .descriptionContains(searchTerm, caseSensitive: false))
              .and()
              .deletedAtIsNull()
              .sortByName()
              .limit(limit)
              .findAll();

      final categories = isarCategories.map((isar) => isar.toEntity()).toList();
      return Right(categories);
    } catch (e) {
      return Left(CacheFailure('Error searching categories: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Category>> createCategory({
    required String name,
    String? description,
    required String slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
  }) async {
    try {
      final now = DateTime.now();
      final serverId = 'cat_${now.millisecondsSinceEpoch}_${name.hashCode}';

      final isarCategory = IsarCategory.create(
        serverId: serverId,
        name: name,
        description: description,
        slug: slug,
        image: image,
        status:
            status == CategoryStatus.active
                ? IsarCategoryStatus.active
                : IsarCategoryStatus.inactive,
        sortOrder: sortOrder ?? 0,
        parentId: parentId,
        productsCount: 0,
        createdAt: now,
        updatedAt: now,
        isSynced: false, // Mark as unsynced for later upload
      );

      await _isar.writeTxn(() async {
        await _isar.isarCategorys.put(isarCategory);
      });

      return Right(isarCategory.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory({
    required String id,
    String? name,
    String? description,
    String? slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
  }) async {
    try {
      final isarCategory =
          await _isar.isarCategorys.filter().serverIdEqualTo(id).findFirst();

      if (isarCategory == null) {
        return Left(CacheFailure('Category not found'));
      }

      // Update fields
      if (name != null) isarCategory.name = name;
      if (description != null) isarCategory.description = description;
      if (slug != null) isarCategory.slug = slug;
      if (image != null) isarCategory.image = image;
      if (status != null) {
        isarCategory.status =
            status == CategoryStatus.active
                ? IsarCategoryStatus.active
                : IsarCategoryStatus.inactive;
      }
      if (sortOrder != null) isarCategory.sortOrder = sortOrder;
      if (parentId != null) isarCategory.parentId = parentId;

      isarCategory.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarCategorys.put(isarCategory);
      });

      return Right(isarCategory.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategoryStatus({
    required String id,
    required CategoryStatus status,
  }) async {
    return updateCategory(id: id, status: status);
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    try {
      final isarCategory =
          await _isar.isarCategorys.filter().serverIdEqualTo(id).findFirst();

      if (isarCategory == null) {
        return Left(CacheFailure('Category not found'));
      }

      // Soft delete
      isarCategory.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarCategorys.put(isarCategory);
      });

      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error deleting category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Category>> restoreCategory(String id) async {
    try {
      final isarCategory =
          await _isar.isarCategorys.filter().serverIdEqualTo(id).findFirst();

      if (isarCategory == null) {
        return Left(CacheFailure('Category not found'));
      }

      // Restore by removing deleted timestamp
      isarCategory.deletedAt = null;
      isarCategory.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarCategorys.put(isarCategory);
      });

      return Right(isarCategory.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error restoring category: ${e.toString()}'));
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> isSlugAvailable(
    String slug, {
    String? excludeId,
  }) async {
    try {
      var query =
          _isar.isarCategorys.filter().slugEqualTo(slug).and().deletedAtIsNull();

      if (excludeId != null) {
        final existing = await query.findAll();
        final isAvailable = !existing.any((cat) => cat.serverId != excludeId);
        return Right(isAvailable);
      } else {
        final existing = await query.findFirst();
        return Right(existing == null);
      }
    } catch (e) {
      return Left(
        CacheFailure('Error checking slug availability: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> generateUniqueSlug(String name) async {
    try {
      // Generate base slug
      String baseSlug =
          name
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
              .replaceAll(RegExp(r'\s+'), '-')
              .replaceAll(RegExp(r'-+'), '-')
              .trim();

      if (baseSlug.isEmpty) baseSlug = 'category';

      // Check if base slug is available
      final isAvailable = await isSlugAvailable(baseSlug);
      if (isAvailable.isRight() && isAvailable.getOrElse(() => false)) {
        return Right(baseSlug);
      }

      // Generate unique slug with number suffix
      int counter = 1;
      String uniqueSlug;
      bool available = false;

      do {
        uniqueSlug = '$baseSlug-$counter';
        final result = await isSlugAvailable(uniqueSlug);
        available = result.getOrElse(() => false);
        counter++;
      } while (!available && counter < 100); // Prevent infinite loop

      return Right(uniqueSlug);
    } catch (e) {
      return Left(
        CacheFailure('Error generating unique slug: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> reorderCategories(
    List<CategoryReorder> reorders,
  ) async {
    try {
      await _isar.writeTxn(() async {
        for (final reorder in reorders) {
          final isarCategory =
              await _isar.isarCategorys
                  .filter()
                  .serverIdEqualTo(reorder.id)
                  .findFirst();

          if (isarCategory != null) {
            isarCategory.sortOrder = reorder.sortOrder;
            isarCategory.markAsUnsynced();
            await _isar.isarCategorys.put(isarCategory);
          }
        }
      });

      return Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error reordering categories: ${e.toString()}'));
    }
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Category>>> getCachedCategories() async {
    try {
      final isarCategories =
          await _isar.isarCategorys
              .filter()
              .deletedAtIsNull()
              .sortBySortOrder()
              .findAll();

      final categories = isarCategories.map((isar) => isar.toEntity()).toList();
      return Right(categories);
    } catch (e) {
      return Left(
        CacheFailure('Error loading cached categories: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCategoryCache() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.isarCategorys.clear();
      });

      return Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error clearing category cache: ${e.toString()}'),
      );
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Get categories that need to be synced with the server
  Future<Either<Failure, List<Category>>> getUnsyncedCategories() async {
    try {
      final isarCategories =
          await _isar.isarCategorys.filter().isSyncedEqualTo(false).findAll();

      final categories = isarCategories.map((isar) => isar.toEntity()).toList();
      return Right(categories);
    } catch (e) {
      return Left(
        CacheFailure('Error loading unsynced categories: ${e.toString()}'),
      );
    }
  }

  /// Mark categories as synced after successful server sync
  Future<Either<Failure, Unit>> markCategoriesAsSynced(
    List<String> categoryIds,
  ) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in categoryIds) {
          final isarCategory =
              await _isar.isarCategorys.filter().serverIdEqualTo(id).findFirst();

          if (isarCategory != null) {
            isarCategory.markAsSynced();
            await _isar.isarCategorys.put(isarCategory);
          }
        }
      });

      return Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error marking categories as synced: ${e.toString()}'),
      );
    }
  }

  /// Bulk insert categories from server
  Future<Either<Failure, Unit>> bulkInsertCategories(
    List<Category> categories,
  ) async {
    try {
      final isarCategories =
          categories.map((cat) => IsarCategory.fromEntity(cat)).toList();

      await _isar.writeTxn(() async {
        await _isar.isarCategorys.putAll(isarCategories);
      });

      return Right(unit);
    } catch (e) {
      return Left(
        CacheFailure('Error bulk inserting categories: ${e.toString()}'),
      );
    }
  }
}
