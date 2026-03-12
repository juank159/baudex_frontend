// lib/features/categories/data/datasources/category_local_datasource_isar.dart
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/category_model.dart';
import '../models/category_stats_model.dart';
import '../models/isar/isar_category.dart';
import 'category_local_datasource.dart';

/// Implementación del datasource local usando ISAR
class CategoryLocalDataSourceIsar implements CategoryLocalDataSource {
  /// In-memory cache for stats (transient data)
  CategoryStatsModel? _cachedStats;

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    try {
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        final isarCategories = categories.map((category) {
          return IsarCategory.fromModel(category);
        }).toList();

        await isar.isarCategorys.putAllByServerId(isarCategories);
      });
    } catch (e) {
      throw CacheException('Error al guardar categorías en ISAR: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarCategories = await isar.isarCategorys
          .filter()
          .deletedAtIsNull()
          .sortBySortOrder()
          .findAll();

      if (isarCategories.isEmpty) {
        throw CacheException.notFound;
      }

      return isarCategories.map((isarCategory) {
        final entity = isarCategory.toEntity();
        return CategoryModel.fromEntity(entity);
      }).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener categorías de ISAR: $e');
    }
  }

  @override
  Future<void> cacheCategoryTree(List<CategoryModel> tree) async {
    try {
      // For tree, we store the same data as categories
      // The tree structure is determined by parent-child relationships
      await cacheCategories(tree);
    } catch (e) {
      throw CacheException('Error al guardar árbol de categorías en ISAR: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCachedCategoryTree() async {
    try {
      // Return all categories sorted by sortOrder
      // The controller/use case will build the tree structure
      return await getCachedCategories();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener árbol de categorías de ISAR: $e');
    }
  }

  @override
  Future<void> cacheCategoryStats(CategoryStatsModel stats) async {
    try {
      // Store stats in-memory since they are transient and can be recalculated
      _cachedStats = stats;
    } catch (e) {
      throw CacheException('Error al guardar estadísticas en cache: $e');
    }
  }

  @override
  Future<CategoryStatsModel?> getCachedCategoryStats() async {
    try {
      return _cachedStats;
    } catch (e) {
      throw CacheException('Error al obtener estadísticas del cache: $e');
    }
  }

  @override
  Future<void> cacheCategory(CategoryModel category) async {
    try {
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        var isarCategory = await isar.isarCategorys
            .filter()
            .serverIdEqualTo(category.id)
            .findFirst();

        if (isarCategory != null) {
          // Update existing
          isarCategory.updateFromModel(category);
        } else {
          // Create new
          isarCategory = IsarCategory.fromModel(category);
        }

        await isar.isarCategorys.put(isarCategory);
      });
    } catch (e) {
      throw CacheException('Error al guardar categoría en ISAR: $e');
    }
  }

  @override
  Future<CategoryModel?> getCachedCategory(String id) async {
    try {
      final isar = IsarDatabase.instance.database;
      final isarCategory = await isar.isarCategorys
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCategory == null) {
        return null;
      }

      final entity = isarCategory.toEntity();
      return CategoryModel.fromEntity(entity);
    } catch (e) {
      throw CacheException('Error al obtener categoría de ISAR: $e');
    }
  }

  @override
  Future<void> removeCachedCategory(String id) async {
    try {
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        final isarCategory = await isar.isarCategorys
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarCategory != null) {
          // Perform soft delete by setting deletedAt
          isarCategory.softDelete();
          await isar.isarCategorys.put(isarCategory);
        }
      });
    } catch (e) {
      throw CacheException('Error al eliminar categoría de ISAR: $e');
    }
  }

  @override
  Future<void> clearCategoryCache() async {
    try {
      final isar = IsarDatabase.instance.database;
      await isar.writeTxn(() async {
        await isar.isarCategorys.clear();
      });

      // Clear in-memory stats
      _cachedStats = null;
    } catch (e) {
      throw CacheException('Error al limpiar cache de categorías en ISAR: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    // ISAR data persists indefinitely, so cache is always valid
    return true;
  }

  @override
  Future<bool> existsByName(String name, String? excludeId) async {
    try {
      final isar = IsarDatabase.instance.database;
      final nameLower = name.trim().toLowerCase();

      // Get all non-deleted categories with matching name (case-insensitive)
      final categories = await isar.isarCategorys
          .filter()
          .deletedAtIsNull()
          .findAll();

      for (final category in categories) {
        // Exclude the category with excludeId if provided
        if (excludeId != null && category.serverId == excludeId) {
          continue;
        }

        // Compare names case-insensitively
        if (category.name.trim().toLowerCase() == nameLower) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw CacheException('Error verificando nombre de categoría en ISAR: $e');
    }
  }
}
