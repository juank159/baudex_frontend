// lib/features/products/data/datasources/product_local_datasource.dart
import 'dart:convert';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../models/product_model.dart';
import '../models/product_stats_model.dart'; // ✅ AGREGAR ESTE IMPORT

/// Contrato para el datasource local de productos
abstract class ProductLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  Future<void> cacheProduct(ProductModel product);
  Future<List<ProductModel>> getCachedProducts();
  Future<ProductModel?> getCachedProduct(String id);
  Future<ProductModel?> getCachedProductBySku(String sku);
  Future<ProductModel?> getCachedProductByBarcode(String barcode);
  Future<void> cacheProductStats(ProductStatsModel stats);
  Future<ProductStatsModel?> getCachedProductStats();
  Future<void> removeCachedProduct(String id);
  Future<void> clearProductCache();
}

/// Implementación del datasource local usando SecureStorage
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SecureStorageService storageService;

  // Claves para el cache
  static const String _productsListKey = 'products_cache';
  static const String _productDetailKey = 'product_detail_';
  static const String _productStatsKey = 'product_stats_cache';
  static const String _lastCacheTimeKey = 'products_last_cache_time';

  // Tiempo de vida del cache (en minutos)
  static const int _cacheExpirationMinutes = 30;

  const ProductLocalDataSourceImpl({required this.storageService});

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final productsJson = products.map((product) => product.toJson()).toList();
      final cacheData = {
        'products': productsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await storageService.write(_productsListKey, jsonEncode(cacheData));

      // Guardar timestamp del último cache
      await storageService.write(
        _lastCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      throw CacheException('Error al cachear productos: $e');
    }
  }

  @override
  Future<void> cacheProduct(ProductModel product) async {
    try {
      final productJson = product.toJson();
      final cacheData = {
        'product': productJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await storageService.write(
        '$_productDetailKey${product.id}',
        jsonEncode(cacheData),
      );
    } catch (e) {
      throw CacheException('Error al cachear producto individual: $e');
    }
  }

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    try {
      final cachedData = await storageService.read(_productsListKey);

      if (cachedData == null) {
        throw const CacheException('No hay productos en cache');
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      // Verificar si el cache ha expirado
      if (_isCacheExpired(timestamp)) {
        await storageService.delete(_productsListKey);
        throw const CacheException('Cache de productos expirado');
      }

      final productsJson = cacheMap['products'] as List;
      return productsJson
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Error al obtener productos del cache: $e');
    }
  }

  @override
  Future<ProductModel?> getCachedProduct(String id) async {
    try {
      final cachedData = await storageService.read('$_productDetailKey$id');

      if (cachedData == null) {
        return null;
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      // Verificar si el cache ha expirado
      if (_isCacheExpired(timestamp)) {
        await storageService.delete('$_productDetailKey$id');
        return null;
      }

      final productJson = cacheMap['product'] as Map<String, dynamic>;
      return ProductModel.fromJson(productJson);
    } catch (e) {
      throw CacheException('Error al obtener producto del cache: $e');
    }
  }

  @override
  Future<ProductModel?> getCachedProductBySku(String sku) async {
    try {
      // Buscar en la lista de productos cacheados
      final products = await getCachedProducts();

      for (final product in products) {
        if (product.sku == sku) {
          return product;
        }
      }

      return null;
    } catch (e) {
      // Si no hay productos en cache o está expirado, retornar null
      return null;
    }
  }

  @override
  Future<ProductModel?> getCachedProductByBarcode(String barcode) async {
    try {
      // Buscar en la lista de productos cacheados
      final products = await getCachedProducts();

      for (final product in products) {
        if (product.barcode == barcode) {
          return product;
        }
      }

      return null;
    } catch (e) {
      // Si no hay productos en cache o está expirado, retornar null
      return null;
    }
  }

  @override
  Future<void> cacheProductStats(ProductStatsModel stats) async {
    try {
      final statsJson = stats.toJson();
      final cacheData = {
        'stats': statsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await storageService.write(_productStatsKey, jsonEncode(cacheData));
    } catch (e) {
      throw CacheException('Error al cachear estadísticas: $e');
    }
  }

  @override
  Future<ProductStatsModel?> getCachedProductStats() async {
    try {
      final cachedData = await storageService.read(_productStatsKey);

      if (cachedData == null) {
        return null;
      }

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      // Verificar si el cache ha expirado
      if (_isCacheExpired(timestamp)) {
        await storageService.delete(_productStatsKey);
        return null;
      }

      final statsJson = cacheMap['stats'] as Map<String, dynamic>;
      return ProductStatsModel.fromJson(statsJson);
    } catch (e) {
      throw CacheException('Error al obtener estadísticas del cache: $e');
    }
  }

  @override
  Future<void> removeCachedProduct(String id) async {
    try {
      await storageService.delete('$_productDetailKey$id');

      // También remover de la lista si existe
      try {
        final products = await getCachedProducts();
        final filteredProducts = products.where((p) => p.id != id).toList();
        await cacheProducts(filteredProducts);
      } catch (e) {
        // Si no se puede actualizar la lista, no es crítico
        print(
          '⚠️ No se pudo actualizar la lista después de remover producto: $e',
        );
      }
    } catch (e) {
      throw CacheException('Error al remover producto del cache: $e');
    }
  }

  @override
  Future<void> clearProductCache() async {
    try {
      // Limpiar cache de lista de productos
      await storageService.delete(_productsListKey);

      // Limpiar cache de estadísticas
      await storageService.delete(_productStatsKey);

      // Limpiar timestamp
      await storageService.delete(_lastCacheTimeKey);

      // Nota: Los productos individuales se limpiarán automáticamente por expiración
      // o se puede implementar una limpieza más agresiva si es necesario
    } catch (e) {
      throw CacheException('Error al limpiar cache de productos: $e');
    }
  }

  /// Verificar si el cache ha expirado
  bool _isCacheExpired(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    final diffMinutes = diff / (1000 * 60);
    return diffMinutes > _cacheExpirationMinutes;
  }

  /// Obtener productos que coincidan con un término de búsqueda desde cache
  Future<List<ProductModel>> searchCachedProducts(String searchTerm) async {
    try {
      final products = await getCachedProducts();
      final term = searchTerm.toLowerCase();

      return products.where((product) {
        return product.name.toLowerCase().contains(term) ||
            product.sku.toLowerCase().contains(term) ||
            (product.description?.toLowerCase().contains(term) ?? false) ||
            (product.barcode?.toLowerCase().contains(term) ?? false);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener productos con stock bajo desde cache
  Future<List<ProductModel>> getCachedLowStockProducts() async {
    try {
      final products = await getCachedProducts();
      return products
          .where((product) => product.stock <= product.minStock)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener productos sin stock desde cache
  Future<List<ProductModel>> getCachedOutOfStockProducts() async {
    try {
      final products = await getCachedProducts();
      return products.where((product) => product.stock <= 0).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener información del último cache
  Future<DateTime?> getLastCacheTime() async {
    try {
      final timestampStr = await storageService.read(_lastCacheTimeKey);
      if (timestampStr != null) {
        final timestamp = int.parse(timestampStr);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verificar si hay datos en cache válidos
  Future<bool> hasCachedData() async {
    try {
      final cachedData = await storageService.read(_productsListKey);
      if (cachedData == null) return false;

      final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = cacheMap['timestamp'] as int;

      return !_isCacheExpired(timestamp);
    } catch (e) {
      return false;
    }
  }
}
