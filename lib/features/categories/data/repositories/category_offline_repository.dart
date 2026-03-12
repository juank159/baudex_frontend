// lib/features/categories/data/repositories/category_offline_repository.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/entities/category_stats.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/isar/isar_category.dart';

/// Implementación offline del repositorio de categorías usando ISAR
///
/// Proporciona todas las operaciones CRUD para categorías de forma offline-first
class CategoryOfflineRepository implements CategoryRepository {
  final IIsarDatabase _database;

  CategoryOfflineRepository({IIsarDatabase? database})
    : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database as Isar;

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
      // Using dynamic to support both production ISAR and MockIsar in tests
      dynamic filterQuery;

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

      // Obtener todos los resultados (ordenar y paginar en Dart)
      final allResults = await filterQuery.findAll() as List<IsarCategory>;
      final totalItems = allResults.length;

      // Ordenar en Dart
      allResults.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'created_at':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'sort_order':
          default:
            comparison = a.sortOrder.compareTo(b.sortOrder);
        }
        return sortOrder == 'desc' ? -comparison : comparison;
      });

      // Paginar manualmente
      final offset = (page - 1) * limit;
      final start = offset.clamp(0, allResults.length);
      final end = (start + limit).clamp(0, allResults.length);
      final isarCategories = allResults.sublist(start, end);

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
              .findAll() as List<IsarCategory>;

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
            .findAll() as List<IsarCategory>;

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
          await collection.filter().deletedAtIsNull().findAll() as List<IsarCategory>;

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
              .findAll() as List<IsarCategory>;

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
        status: (status ?? CategoryStatus.active) == CategoryStatus.active
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

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Category',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': name,
            'description': description,
            'slug': slug,
            'image': image,
            'status': status?.name,
            'sortOrder': sortOrder,
            'parentId': parentId,
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

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

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Category',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

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

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Category',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

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
        // Get all categories with this slug (excluding deleted)
        final existing = await query.findAll() as List<IsarCategory>;
        // Slug is available if no category has this slug, or only the excluded category has it
        final isAvailable = existing.isEmpty || existing.every((cat) => cat.serverId == excludeId);
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
      final isAvailableResult = await isSlugAvailable(baseSlug);
      final isAvailable = isAvailableResult.fold(
        (failure) => false,
        (available) => available,
      );

      if (isAvailable) {
        return Right(baseSlug);
      }

      // Generate unique slug with number suffix
      int counter = 1;
      String uniqueSlug = baseSlug;

      while (counter < 100) { // Prevent infinite loop
        uniqueSlug = '$baseSlug-$counter';
        final result = await isSlugAvailable(uniqueSlug);
        final available = result.fold(
          (failure) => false,
          (isAvail) => isAvail,
        );

        if (available) {
          return Right(uniqueSlug);
        }
        counter++;
      }

      // If we couldn't find a unique slug after 100 tries, return error
      return Left(
        CacheFailure('Could not generate unique slug after 100 attempts'),
      );
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
              .findAll() as List<IsarCategory>;

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
          await _isar.isarCategorys.filter().isSyncedEqualTo(false).findAll() as List<IsarCategory>;

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

  // ==================== VALIDATION OPERATIONS ====================

  /// Verifica si ya existe una categoría con el nombre dado
  ///
  /// [name]: Nombre a verificar
  /// [excludeId]: ID de categoría a excluir (útil al editar)
  ///
  /// Returns: Right(true) si existe, Right(false) si no existe, Left(Failure) en caso de error
  Future<Either<Failure, bool>> existsByName(String name, {String? excludeId}) async {
    try {
      final nameLower = name.trim().toLowerCase();
      final allCategories = await _isar.isarCategorys
          .filter()
          .deletedAtIsNull()
          .findAll() as List<IsarCategory>;

      for (final category in allCategories) {
        // Excluir la categoría actual si estamos editando
        if (excludeId != null && category.serverId == excludeId) {
          continue;
        }

        // Comparar nombres sin importar mayúsculas/minúsculas
        if (category.name.trim().toLowerCase() == nameLower) {
          return const Right(true);
        }
      }

      return const Right(false);
    } catch (e) {
      return Left(CacheFailure('Error checking category name: $e'));
    }
  }
}
