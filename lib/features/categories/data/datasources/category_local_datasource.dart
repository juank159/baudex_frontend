// lib/features/categories/data/datasources/category_local_datasource.dart
import 'dart:convert';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/category_model.dart';
import '../models/category_stats_model.dart';

/// Contrato para el datasource local de categorías
abstract class CategoryLocalDataSource {
  Future<void> cacheCategories(List<CategoryModel> categories);
  Future<List<CategoryModel>> getCachedCategories();
  Future<void> cacheCategoryTree(List<CategoryModel> tree);
  Future<List<CategoryModel>> getCachedCategoryTree();
  Future<void> cacheCategoryStats(CategoryStatsModel stats);
  Future<CategoryStatsModel?> getCachedCategoryStats();
  Future<void> cacheCategory(CategoryModel category);
  Future<CategoryModel?> getCachedCategory(String id);
  Future<void> removeCachedCategory(String id);
  Future<void> clearCategoryCache();
  Future<bool> isCacheValid();
}

/// Implementación del datasource local usando SecureStorage
class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final SecureStorageService storageService;

  // Keys para el almacenamiento
  static const String _categoriesKey = 'cached_categories';
  static const String _categoryTreeKey = 'cached_category_tree';
  static const String _categoryStatsKey = 'cached_category_stats';
  static const String _categoryKeyPrefix = 'cached_category_';
  static const String _cacheTimestampKey = 'categories_cache_timestamp';

  // Cache válido por 30 minutos
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  const CategoryLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> cacheCategories(List<CategoryModel> categories) async {
    try {
      final categoriesJson =
          categories.map((category) => category.toJson()).toList();
      await storageService.write(_categoriesKey, json.encode(categoriesJson));
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar categorías en cache: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCachedCategories() async {
    try {
      final categoriesData = await storageService.read(_categoriesKey);
      if (categoriesData == null) {
        throw CacheException.notFound;
      }

      final categoriesJson = json.decode(categoriesData) as List;
      return categoriesJson
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener categorías del cache: $e');
    }
  }

  @override
  Future<void> cacheCategoryTree(List<CategoryModel> tree) async {
    try {
      final treeJson = tree.map((category) => category.toJson()).toList();
      await storageService.write(_categoryTreeKey, json.encode(treeJson));
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar árbol de categorías en cache: $e');
    }
  }

  @override
  Future<List<CategoryModel>> getCachedCategoryTree() async {
    try {
      final treeData = await storageService.read(_categoryTreeKey);
      if (treeData == null) {
        throw CacheException.notFound;
      }

      final treeJson = json.decode(treeData) as List;
      return treeJson
          .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(
        'Error al obtener árbol de categorías del cache: $e',
      );
    }
  }

  @override
  Future<void> cacheCategoryStats(CategoryStatsModel stats) async {
    try {
      await storageService.write(
        _categoryStatsKey,
        json.encode(stats.toJson()),
      );
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar estadísticas en cache: $e');
    }
  }

  @override
  Future<CategoryStatsModel?> getCachedCategoryStats() async {
    try {
      final statsData = await storageService.read(_categoryStatsKey);
      if (statsData == null) {
        return null;
      }

      final statsJson = json.decode(statsData) as Map<String, dynamic>;
      return CategoryStatsModel.fromJson(statsJson);
    } catch (e) {
      throw CacheException('Error al obtener estadísticas del cache: $e');
    }
  }

  @override
  Future<void> cacheCategory(CategoryModel category) async {
    try {
      final categoryKey = '$_categoryKeyPrefix${category.id}';
      await storageService.write(categoryKey, json.encode(category.toJson()));
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar categoría en cache: $e');
    }
  }

  @override
  Future<CategoryModel?> getCachedCategory(String id) async {
    try {
      final categoryKey = '$_categoryKeyPrefix$id';
      final categoryData = await storageService.read(categoryKey);

      if (categoryData == null) {
        return null;
      }

      final categoryJson = json.decode(categoryData) as Map<String, dynamic>;
      return CategoryModel.fromJson(categoryJson);
    } catch (e) {
      throw CacheException('Error al obtener categoría del cache: $e');
    }
  }

  @override
  Future<void> removeCachedCategory(String id) async {
    try {
      final categoryKey = '$_categoryKeyPrefix$id';
      await storageService.delete(categoryKey);
    } catch (e) {
      throw CacheException('Error al eliminar categoría del cache: $e');
    }
  }

  @override
  Future<void> clearCategoryCache() async {
    try {
      // Limpiar cache general
      await storageService.delete(_categoriesKey);
      await storageService.delete(_categoryTreeKey);
      await storageService.delete(_categoryStatsKey);
      await storageService.delete(_cacheTimestampKey);

      // Limpiar categorías individuales
      // Obtener todas las claves y filtrar las que empiecen con el prefijo
      final allData = await storageService.readAll();
      for (final key in allData.keys) {
        if (key.startsWith(_categoryKeyPrefix)) {
          await storageService.delete(key);
        }
      }
    } catch (e) {
      throw CacheException('Error al limpiar cache de categorías: $e');
    }
  }

  @override
  Future<bool> isCacheValid() async {
    try {
      final timestampData = await storageService.read(_cacheTimestampKey);
      if (timestampData == null) {
        return false;
      }

      final timestamp = DateTime.parse(timestampData);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      return difference <= _cacheValidDuration;
    } catch (e) {
      // Si hay error, asumir que el cache no es válido
      return false;
    }
  }

  /// Actualizar timestamp del cache
  Future<void> _updateCacheTimestamp() async {
    try {
      final now = DateTime.now().toIso8601String();
      await storageService.write(_cacheTimestampKey, now);
    } catch (e) {
      // No lanzar excepción si falla guardar timestamp
      print('Error al actualizar timestamp del cache: $e');
    }
  }

  /// Verificar si existe cache de categorías
  Future<bool> hasCachedCategories() async {
    try {
      return await storageService.containsKey(_categoriesKey);
    } catch (e) {
      return false;
    }
  }

  /// Verificar si existe cache del árbol
  Future<bool> hasCachedCategoryTree() async {
    try {
      return await storageService.containsKey(_categoryTreeKey);
    } catch (e) {
      return false;
    }
  }

  /// Obtener información del cache
  Future<CacheInfo> getCacheInfo() async {
    try {
      final hasCategories = await hasCachedCategories();
      final hasTree = await hasCachedCategoryTree();
      final isValid = await isCacheValid();

      DateTime? lastUpdate;
      final timestampData = await storageService.read(_cacheTimestampKey);
      if (timestampData != null) {
        lastUpdate = DateTime.parse(timestampData);
      }

      return CacheInfo(
        hasCategories: hasCategories,
        hasTree: hasTree,
        isValid: isValid,
        lastUpdate: lastUpdate,
      );
    } catch (e) {
      return const CacheInfo(
        hasCategories: false,
        hasTree: false,
        isValid: false,
        lastUpdate: null,
      );
    }
  }
}

/// Información del cache
class CacheInfo {
  final bool hasCategories;
  final bool hasTree;
  final bool isValid;
  final DateTime? lastUpdate;

  const CacheInfo({
    required this.hasCategories,
    required this.hasTree,
    required this.isValid,
    this.lastUpdate,
  });

  @override
  String toString() =>
      'CacheInfo(hasCategories: $hasCategories, hasTree: $hasTree, isValid: $isValid)';
}
