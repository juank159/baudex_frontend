// lib/features/products/data/datasources/product_local_datasource.dart
import 'dart:convert';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../models/product_model.dart';
import '../models/product_stats_model.dart';
import '../../domain/entities/product.dart'; // ✅ NUEVO: Para manejar entidades offline
import '../../domain/entities/product_price.dart'; // ✅ NUEVO: Para precios

/// Contrato para el datasource local de productos
abstract class ProductLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  Future<void> cacheProduct(ProductModel product);
  Future<void> cacheProductForSync(Product product); // ✅ NUEVO: Para productos creados offline
  Future<List<ProductModel>> getCachedProducts();
  Future<ProductModel?> getCachedProduct(String id);
  Future<ProductModel?> getCachedProductBySku(String sku);
  Future<ProductModel?> getCachedProductByBarcode(String barcode);
  Future<void> cacheProductStats(ProductStatsModel stats);
  Future<ProductStatsModel?> getCachedProductStats();
  Future<void> removeCachedProduct(String id);
  Future<void> clearProductCache();
  Future<List<Product>> getUnsyncedProducts(); // ✅ NUEVO: Para obtener productos pendientes de sincronizar
  Future<void> markProductAsSynced(String tempId, String serverId); // ✅ NUEVO: Para marcar como sincronizado
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

  // ==================== ✅ NUEVOS MÉTODOS PARA SINCRONIZACIÓN OFFLINE ====================

  /// Guardar producto creado offline para posterior sincronización
  @override
  Future<void> cacheProductForSync(Product product) async {
    try {
      // Convertir Product entity a Map para guardar
      final productData = {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'sku': product.sku,
        'barcode': product.barcode,
        'type': product.type.name,
        'status': product.status.name,
        'stock': product.stock,
        'minStock': product.minStock,
        'unit': product.unit,
        'weight': product.weight,
        'length': product.length,
        'width': product.width,
        'height': product.height,
        'images': product.images,
        'metadata': product.metadata,
        'categoryId': product.categoryId,
        'createdById': product.createdById,
        'prices': product.prices?.map((price) => {
          'id': price.id,
          'productId': price.productId,
          'type': price.type.name,
          'amount': price.amount,
          'currency': price.currency,
          'status': price.status.name,
          'discountPercentage': price.discountPercentage,
          'minQuantity': price.minQuantity,
          'createdAt': price.createdAt.toIso8601String(),
          'updatedAt': price.updatedAt.toIso8601String(),
        }).toList() ?? [],
        'createdAt': product.createdAt.toIso8601String(),
        'updatedAt': product.updatedAt.toIso8601String(),
        'isSynced': false, // Siempre false para productos offline
      };

      // Guardar en una clave específica para productos no sincronizados
      final unsyncedKey = 'unsynced_product_${product.id}';
      await storageService.write(unsyncedKey, jsonEncode(productData));

      print('✅ ProductLocalDataSource: Product cached for sync: ${product.name}');
    } catch (e) {
      throw CacheException('Error caching product for sync: $e');
    }
  }

  /// Obtener todos los productos que faltan por sincronizar
  @override
  Future<List<Product>> getUnsyncedProducts() async {
    try {
      final allData = await storageService.readAll();
      final unsyncedProducts = <Product>[];

      for (final entry in allData.entries) {
        if (entry.key.startsWith('unsynced_product_')) {
          try {
            final productData = jsonDecode(entry.value) as Map<String, dynamic>;
            final product = _mapToProductEntity(productData);
            unsyncedProducts.add(product);
          } catch (e) {
            print('⚠️ Error parsing unsynced product ${entry.key}: $e');
          }
        }
      }

      print('📋 ProductLocalDataSource: Found ${unsyncedProducts.length} unsynced products');
      return unsyncedProducts;
    } catch (e) {
      throw CacheException('Error getting unsynced products: $e');
    }
  }

  /// Marcar producto como sincronizado y actualizar su ID
  @override
  Future<void> markProductAsSynced(String tempId, String serverId) async {
    try {
      // Remover de productos no sincronizados
      final unsyncedKey = 'unsynced_product_$tempId';
      await storageService.delete(unsyncedKey);

      print('✅ ProductLocalDataSource: Product marked as synced: $tempId -> $serverId');
    } catch (e) {
      throw CacheException('Error marking product as synced: $e');
    }
  }

  /// Mapear datos JSON a entidad Product
  Product _mapToProductEntity(Map<String, dynamic> data) {
    return Product(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      sku: data['sku'] as String,
      barcode: data['barcode'] as String?,
      type: ProductType.values.firstWhere((t) => t.name == data['type']),
      status: ProductStatus.values.firstWhere((s) => s.name == data['status']),
      stock: (data['stock'] as num?)?.toDouble() ?? 0.0,
      minStock: (data['minStock'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] as String? ?? 'pcs',
      weight: (data['weight'] as num?)?.toDouble(),
      length: (data['length'] as num?)?.toDouble(),
      width: (data['width'] as num?)?.toDouble(),
      height: (data['height'] as num?)?.toDouble(),
      images: List<String>.from(data['images'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      categoryId: data['categoryId'] as String,
      createdById: data['createdById'] as String? ?? '',
      category: null,
      prices: (data['prices'] as List?)?.map((priceData) => ProductPrice(
        id: priceData['id'] as String,
        productId: priceData['productId'] as String,
        type: PriceType.values.firstWhere((t) => t.name == priceData['type']),
        amount: (priceData['amount'] as num).toDouble(),
        currency: priceData['currency'] as String? ?? 'USD',
        status: PriceStatus.values.firstWhere((s) => s.name == (priceData['status'] ?? 'active')),
        discountPercentage: (priceData['discountPercentage'] as num?)?.toDouble() ?? 0.0,
        minQuantity: (priceData['minQuantity'] as num?)?.toDouble() ?? 1.0,
        createdAt: DateTime.parse(priceData['createdAt'] as String),
        updatedAt: DateTime.parse(priceData['updatedAt'] as String),
      )).toList() ?? [],
      createdBy: null,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
    );
  }
}
