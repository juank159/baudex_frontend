// lib/features/products/data/datasources/product_local_datasource_isar.dart
import 'dart:convert';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../models/product_model.dart';
import '../models/product_stats_model.dart';
import '../models/product_price_model.dart';

import '../models/isar/isar_product.dart';
import '../models/isar/isar_product_price.dart';
import '../../domain/entities/product.dart';
import 'product_local_datasource.dart';
import 'package:isar/isar.dart';

/// Implementación ISAR del datasource local de productos
///
/// Almacenamiento persistente offline-first usando ISAR
class ProductLocalDataSourceIsar implements ProductLocalDataSource {
  final IIsarDatabase _database;

  ProductLocalDataSourceIsar(this._database);

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final Isar isar = _database.database as Isar;

      await isar.writeTxn(() async {
        // Procesar productos uno por uno para evitar violaciones de índice único
        for (final product in products) {
          // ✅ AUTOMATIZACIÓN: Buscar producto existente por serverId O por SKU
          // Esto maneja el caso donde un producto offline se sincronizó y ahora tiene un nuevo ID
          IsarProduct? existingProduct =
              await isar.isarProducts
                  .filter()
                  .serverIdEqualTo(product.id)
                  .findFirst();

          // Si no se encontró por serverId, buscar por SKU (producto offline que se sincronizó)
          if (existingProduct == null) {
            existingProduct =
                await isar.isarProducts
                    .filter()
                    .skuEqualTo(product.sku)
                    .findFirst();

            if (existingProduct != null) {
              print('🔄 Producto offline encontrado por SKU: ${product.sku}');
              print('   Actualizando serverId: ${existingProduct.serverId} → ${product.id}');
            }
          }

          IsarProduct isarProduct;

          if (existingProduct != null) {
            // Actualizar producto existente
            isarProduct =
                existingProduct
                  ..serverId = product.id // Actualizar serverId (importante para sync offline→online)
                  ..name = product.name
                  ..description = product.description
                  ..sku = product.sku
                  ..barcode = product.barcode
                  ..type = _mapToIsarProductType(product.type)
                  ..status = _mapToIsarProductStatus(product.status)
                  ..stock = product.stock
                  ..minStock = product.minStock
                  ..unit = product.unit
                  ..weight = product.weight
                  ..length = product.length
                  ..width = product.width
                  ..height = product.height
                  ..images = product.images ?? []
                  ..categoryId = product.categoryId
                  ..createdById = product.createdById
                  ..createdAt = product.createdAt
                  ..updatedAt = product.updatedAt
                  ..taxCategory = IsarProduct.mapTaxCategoryFromString(product.taxCategory)
                  ..taxRate = product.taxRate
                  ..isTaxable = product.isTaxable
                  ..hasRetention = product.hasRetention
                  ..isSynced = true
                  ..metadataJson = _serializeProductData(product)
                  ..prices = product.prices?.map((p) => IsarProductPrice.fromModel(p)).toList() ?? []
                  ..lastSyncAt = DateTime.now();
          } else {
            // Crear nuevo producto
            isarProduct =
                IsarProduct()
                  ..serverId = product.id
                  ..name = product.name
                  ..description = product.description
                  ..sku = product.sku
                  ..barcode = product.barcode
                  ..type = _mapToIsarProductType(product.type)
                  ..status = _mapToIsarProductStatus(product.status)
                  ..stock = product.stock
                  ..minStock = product.minStock
                  ..unit = product.unit
                  ..weight = product.weight
                  ..length = product.length
                  ..width = product.width
                  ..height = product.height
                  ..images = product.images ?? []
                  ..categoryId = product.categoryId
                  ..createdById = product.createdById
                  ..createdAt = product.createdAt
                  ..updatedAt = product.updatedAt
                  ..taxCategory = IsarProduct.mapTaxCategoryFromString(product.taxCategory)
                  ..taxRate = product.taxRate
                  ..isTaxable = product.isTaxable
                  ..hasRetention = product.hasRetention
                  ..isSynced = true
                  ..metadataJson = _serializeProductData(product)
                  ..prices = product.prices?.map((p) => IsarProductPrice.fromModel(p)).toList() ?? []
                  ..lastSyncAt = DateTime.now()
                  ..version = 1; // ✅ Campo requerido
          }

          // Guardar/actualizar el producto
          await isar.isarProducts.put(isarProduct);
        }
      });

      print('📦 ISAR: ${products.length} productos cacheados exitosamente');
    } catch (e) {
      print('❌ Error al cachear productos en ISAR: $e');
      throw CacheException('Error al cachear productos en ISAR: $e');
    }
  }

  @override
  Future<void> cacheProduct(ProductModel product) async {
    try {
      final Isar isar = _database.database as Isar;

      await isar.writeTxn(() async {
        // ✅ AUTOMATIZACIÓN: Buscar producto existente por serverId O por SKU
        IsarProduct? existingProduct =
            await isar.isarProducts
                .filter()
                .serverIdEqualTo(product.id)
                .findFirst();

        // Si no se encontró por serverId, buscar por SKU
        if (existingProduct == null) {
          existingProduct =
              await isar.isarProducts
                  .filter()
                  .skuEqualTo(product.sku)
                  .findFirst();

          if (existingProduct != null) {
            print('🔄 Producto offline encontrado por SKU: ${product.sku}');
            print('   Actualizando serverId: ${existingProduct.serverId} → ${product.id}');
          }
        }

        IsarProduct isarProduct;

        if (existingProduct != null) {
          // Actualizar producto existente
          isarProduct =
              existingProduct
                ..serverId = product.id // Actualizar con el ID real del servidor
                ..name = product.name
                ..description = product.description
                ..sku = product.sku
                ..barcode = product.barcode
                ..type = _mapToIsarProductType(product.type)
                ..status = _mapToIsarProductStatus(product.status)
                ..stock = product.stock
                ..minStock = product.minStock
                ..unit = product.unit
                ..weight = product.weight
                ..length = product.length
                ..width = product.width
                ..height = product.height
                ..images = product.images ?? []
                ..categoryId = product.categoryId
                ..createdById = product.createdById
                ..createdAt = product.createdAt
                ..updatedAt = product.updatedAt
                ..taxCategory = IsarProduct.mapTaxCategoryFromString(product.taxCategory)
                ..taxRate = product.taxRate
                ..isTaxable = product.isTaxable
                ..hasRetention = product.hasRetention
                ..isSynced = true
                ..metadataJson = _serializeProductData(product)
                ..prices = product.prices?.map((p) => IsarProductPrice.fromModel(p)).toList() ?? []
                ..lastSyncAt = DateTime.now();
        } else {
          // Crear nuevo producto
          isarProduct =
              IsarProduct()
                ..serverId = product.id
                ..name = product.name
                ..description = product.description
                ..sku = product.sku
                ..barcode = product.barcode
                ..type = _mapToIsarProductType(product.type)
                ..status = _mapToIsarProductStatus(product.status)
                ..stock = product.stock
                ..minStock = product.minStock
                ..unit = product.unit
                ..weight = product.weight
                ..length = product.length
                ..width = product.width
                ..height = product.height
                ..images = product.images ?? []
                ..categoryId = product.categoryId
                ..createdById = product.createdById
                ..createdAt = product.createdAt
                ..updatedAt = product.updatedAt
                ..taxCategory = IsarProduct.mapTaxCategoryFromString(product.taxCategory)
                ..taxRate = product.taxRate
                ..isTaxable = product.isTaxable
                ..hasRetention = product.hasRetention
                ..isSynced = true
                ..metadataJson = _serializeProductData(product)
                ..prices = product.prices?.map((p) => IsarProductPrice.fromModel(p)).toList() ?? []
                ..lastSyncAt = DateTime.now()
                ..version = 1; // ✅ Campo requerido
        }

        await isar.isarProducts.put(isarProduct);
      });

      print('📦 ISAR: Producto ${product.name} cacheado exitosamente');
    } catch (e) {
      print('❌ Error al cachear producto en ISAR: $e');
      throw CacheException('Error al cachear producto en ISAR: $e');
    }
  }

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    try {
      final Isar isar = _database.database as Isar;

      // Obtener productos no eliminados ordenados por fecha de creación
      // Excluir registro STATS_CACHE (se usa para guardar estadísticas, no es un producto real)
      final List<IsarProduct> isarProducts =
          await isar.isarProducts
              .filter()
              .deletedAtIsNull()
              .and()
              .not()
              .serverIdEqualTo('STATS_CACHE')
              .sortByCreatedAtDesc()
              .findAll();

      if (isarProducts.isEmpty) {
        print('📦 ISAR: No hay productos en cache local');
        throw const CacheException('No hay productos en cache local');
      }

      // Convertir IsarProduct a ProductModel
      final products =
          isarProducts
              .map((isarProduct) => _convertToProductModel(isarProduct))
              .toList();

      print('📦 ISAR: ${products.length} productos obtenidos del cache local');
      return products;
    } catch (e) {
      if (e is CacheException) rethrow;
      print('❌ Error al obtener productos de ISAR: $e');
      throw CacheException('Error al obtener productos de ISAR: $e');
    }
  }

  @override
  Future<ProductModel?> getCachedProduct(String id) async {
    try {
      final Isar isar = _database.database as Isar;

      // Buscar producto por serverId
      final isarProduct =
          await isar.isarProducts
              .filter()
              .serverIdEqualTo(id)
              .and()
              .deletedAtIsNull()
              .findFirst();

      if (isarProduct == null) {
        print('📦 ISAR: Producto con ID $id no encontrado en cache');
        return null;
      }

      return _convertToProductModel(isarProduct);
    } catch (e) {
      print('❌ Error al obtener producto de ISAR: $e');
      throw CacheException('Error al obtener producto de ISAR: $e');
    }
  }

  @override
  Future<ProductModel?> getCachedProductBySku(String sku) async {
    try {
      final Isar isar = _database.database as Isar;

      final isarProduct =
          await isar.isarProducts
              .filter()
              .skuEqualTo(sku)
              .and()
              .deletedAtIsNull()
              .findFirst();

      if (isarProduct == null) {
        print('📦 ISAR: Producto con SKU $sku no encontrado en cache');
        return null;
      }

      return _convertToProductModel(isarProduct);
    } catch (e) {
      print('❌ Error al obtener producto por SKU de ISAR: $e');
      return null;
    }
  }

  @override
  Future<ProductModel?> getCachedProductByBarcode(String barcode) async {
    try {
      final Isar isar = _database.database as Isar;

      final isarProduct =
          await isar.isarProducts
              .filter()
              .barcodeEqualTo(barcode)
              .and()
              .deletedAtIsNull()
              .findFirst();

      if (isarProduct == null) {
        print('📦 ISAR: Producto con código $barcode no encontrado en cache');
        return null;
      }

      return _convertToProductModel(isarProduct);
    } catch (e) {
      print('❌ Error al obtener producto por código de ISAR: $e');
      return null;
    }
  }

  @override
  Future<void> cacheProductStats(ProductStatsModel stats) async {
    try {
      final Isar isar = _database.database as Isar;

      // Usar clave especial para estadísticas
      await isar.writeTxn(() async {
        final statsProduct =
            IsarProduct()
              ..serverId = 'STATS_CACHE'
              ..name = 'Product Statistics Cache'
              ..sku = 'STATS'
              ..type = IsarProductType.product
              ..status = IsarProductStatus.active
              ..stock = 0
              ..minStock = 0
              ..categoryId = 'stats'
              ..isSynced = true
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now()
              ..lastSyncAt = DateTime.now()
              ..version = 1 // ✅ Campo requerido
              // Serializar estadísticas como JSON string
              ..metadataJson = jsonEncode(stats.toJson());

        await isar.isarProducts.putByServerId(statsProduct);
      });

      print('📊 ISAR: Estadísticas de productos cacheadas');
    } catch (e) {
      print('❌ Error al cachear estadísticas en ISAR: $e');
      throw CacheException('Error al cachear estadísticas en ISAR: $e');
    }
  }

  @override
  Future<ProductStatsModel?> getCachedProductStats() async {
    try {
      final Isar isar = _database.database as Isar;

      final statsCache =
          await isar.isarProducts
              .filter()
              .serverIdEqualTo('STATS_CACHE')
              .findFirst();

      if (statsCache == null || statsCache.metadataJson == null) {
        print('📊 ISAR: No hay estadísticas en cache');
        return null;
      }

      // Deserializar estadísticas desde JSON
      final statsJson = statsCache.metadataJson!;
      print('📊 ISAR: Deserializando estadísticas desde cache: $statsJson');

      try {
        // Parsear el JSON string de forma segura
        final Map<String, dynamic> jsonMap = _parseJsonString(statsJson);
        final stats = ProductStatsModel.fromJson(jsonMap);

        print('✅ ISAR: Estadísticas deserializadas exitosamente');
        return stats;
      } catch (parseError) {
        print('❌ Error al parsear estadísticas JSON: $parseError');
        print('📋 JSON problemático: $statsJson');

        // Retornar estadísticas vacías en lugar de null para evitar errores en la UI
        return const ProductStatsModel(
          total: 0,
          active: 0,
          inactive: 0,
          outOfStock: 0,
          lowStock: 0,
          activePercentage: 0.0,
          totalValue: 0.0,
          averagePrice: 0.0,
        );
      }
    } catch (e) {
      print('❌ Error al obtener estadísticas de ISAR: $e');
      return null;
    }
  }

  @override
  Future<void> removeCachedProduct(String id) async {
    try {
      final Isar isar = _database.database as Isar;

      await isar.writeTxn(() async {
        // Buscar producto por serverId
        final product =
            await isar.isarProducts.filter().serverIdEqualTo(id).findFirst();

        if (product == null) {
          throw CacheException('Producto no encontrado en cache: $id');
        }

        // Eliminar físicamente del cache
        await isar.isarProducts.delete(product.id);
      });

      print('🗑️ ISAR: Producto $id eliminado del cache');
    } catch (e) {
      print('❌ Error al remover producto de ISAR: $e');
      throw CacheException('Error al remover producto de ISAR: $e');
    }
  }

  @override
  Future<void> clearProductCache() async {
    try {
      final Isar isar = _database.database as Isar;

      await isar.writeTxn(() async {
        // Limpiar todos los productos
        await isar.isarProducts.clear();
      });

      print('🧹 ISAR: Cache de productos limpiado');
    } catch (e) {
      print('❌ Error al limpiar cache de ISAR: $e');
      throw CacheException('Error al limpiar cache de ISAR: $e');
    }
  }

  /// Convertir IsarProduct a ProductModel
  ProductModel _convertToProductModel(IsarProduct isarProduct) {
    // Deserializar datos del producto desde cache offline
    final deserializedData = _deserializeProductData(isarProduct.metadataJson);

    // ✅ CORRECCIÓN: Usar precios del campo `prices` de IsarProduct primero,
    // con fallback a los del metadataJson para compatibilidad con datos antiguos
    List<ProductPriceModel>? prices;
    if (isarProduct.prices.isNotEmpty) {
      // Usar precios directamente de ISAR (nuevo formato)
      prices = isarProduct.prices
          .map((p) => ProductPriceModel.fromEntity(p.toEntity()))
          .toList();
      print('📦 ISAR: Producto ${isarProduct.name} - ${prices.length} precios cargados desde campo prices');
    } else {
      // Fallback a metadataJson (formato antiguo)
      prices = deserializedData['prices'];
      if (prices != null && prices.isNotEmpty) {
        print('📦 ISAR: Producto ${isarProduct.name} - ${prices.length} precios cargados desde metadataJson');
      }
    }

    return ProductModel(
      id: isarProduct.serverId,
      name: isarProduct.name,
      description: isarProduct.description,
      sku: isarProduct.sku,
      barcode: isarProduct.barcode,
      type: _mapFromIsarProductType(isarProduct.type).name,
      status: _mapFromIsarProductStatus(isarProduct.status).name,
      stock: isarProduct.stock,
      minStock: isarProduct.minStock,
      unit: isarProduct.unit,
      weight: isarProduct.weight,
      length: isarProduct.length,
      width: isarProduct.width,
      height: isarProduct.height,
      images: isarProduct.images,
      categoryId: isarProduct.categoryId,
      createdById: isarProduct.createdById ?? '',
      createdAt: isarProduct.createdAt,
      updatedAt: isarProduct.updatedAt,
      // ✅ Usar precios del campo prices o fallback a metadataJson
      prices: prices,
      category: deserializedData['category'],
      createdBy: deserializedData['createdBy'],
      metadata: deserializedData['metadata'],
      taxCategory: IsarProduct.mapIsarTaxCategoryToString(isarProduct.taxCategory),
      taxRate: isarProduct.taxRate,
      isTaxable: isarProduct.isTaxable,
      hasRetention: isarProduct.hasRetention,
    );
  }

  /// Método adicional: Verificar si hay datos offline
  Future<bool> hasOfflineData() async {
    try {
      final Isar isar = _database.database as Isar;
      final count =
          await isar.isarProducts
              .filter()
              .deletedAtIsNull()
              .and()
              .not()
              .serverIdEqualTo('STATS_CACHE')
              .count();

      print('📦 ISAR: $count productos disponibles offline');
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Método adicional: Obtener timestamp de última sincronización
  Future<DateTime?> getLastSyncTime() async {
    try {
      final Isar isar = _database.database as Isar;
      final product =
          await isar.isarProducts
              .filter()
              .lastSyncAtIsNotNull()
              .sortByLastSyncAtDesc()
              .findFirst();

      return product?.lastSyncAt;
    } catch (e) {
      return null;
    }
  }

  /// Helper methods para conversión de enums (desde ProductModel strings)
  IsarProductType _mapToIsarProductType(String? type) {
    if (type == null) return IsarProductType.product;
    switch (type.toLowerCase()) {
      case 'product':
        return IsarProductType.product;
      case 'service':
        return IsarProductType.service;
      default:
        return IsarProductType.product;
    }
  }

  ProductType _mapFromIsarProductType(IsarProductType type) {
    switch (type) {
      case IsarProductType.product:
        return ProductType.product;
      case IsarProductType.service:
        return ProductType.service;
    }
  }

  IsarProductStatus _mapToIsarProductStatus(String? status) {
    if (status == null) return IsarProductStatus.active;
    switch (status.toLowerCase()) {
      case 'active':
        return IsarProductStatus.active;
      case 'inactive':
        return IsarProductStatus.inactive;
      case 'out_of_stock':
      case 'outofstock':
        return IsarProductStatus.outOfStock;
      default:
        return IsarProductStatus.active;
    }
  }

  ProductStatus _mapFromIsarProductStatus(IsarProductStatus status) {
    switch (status) {
      case IsarProductStatus.active:
        return ProductStatus.active;
      case IsarProductStatus.inactive:
        return ProductStatus.inactive;
      case IsarProductStatus.outOfStock:
        return ProductStatus.outOfStock;
    }
  }

  // ==================== MÉTODOS HELPER PARA SERIALIZACIÓN ====================

  /// Serializar datos completos del producto (precios, categoría, createdBy) a JSON string
  String _serializeProductData(ProductModel product) {
    try {
      final Map<String, dynamic> productData = {
        'prices': product.prices?.map((price) => price.toJson()).toList(),
        'category': product.category?.toJson(),
        'createdBy': product.createdBy?.toJson(),
      };
      return jsonEncode(productData);
    } catch (e) {
      print('❌ Error al serializar datos del producto: $e');
      return '{}'; // Retornar objeto vacío en caso de error
    }
  }

  /// Serializar lista de precios a JSON string para almacenar en ISAR (método legacy)
  String _serializePrices(List<ProductPriceModel> prices) {
    try {
      final pricesJson = prices.map((price) => price.toJson()).toList();
      return jsonEncode(pricesJson);
    } catch (e) {
      print('❌ Error al serializar precios: $e');
      return '[]'; // Retornar array vacío en caso de error
    }
  }

  /// Deserializar datos completos del producto desde JSON string
  Map<String, dynamic> _deserializeProductData(String? metadataJson) {
    try {
      if (metadataJson == null ||
          metadataJson.isEmpty ||
          metadataJson == 'null') {
        return {
          'prices': null,
          'category': null,
          'createdBy': null,
          'metadata': null,
        };
      }

      final productData = jsonDecode(metadataJson);

      // Si es el formato antiguo (solo precios como array)
      if (productData is List) {
        return {
          'prices': _deserializePricesFromList(productData),
          'category': null,
          'createdBy': null,
          'metadata': null,
        };
      }

      // Si es el formato nuevo (objeto con precios, categoría, etc.)
      if (productData is Map<String, dynamic>) {
        return {
          'prices':
              productData['prices'] != null
                  ? _deserializePricesFromList(productData['prices'])
                  : null,
          'category':
              productData['category'] != null
                  ? _deserializeCategoryFromJson(productData['category'])
                  : null,
          'createdBy':
              productData['createdBy'] != null
                  ? _deserializeCreatedByFromJson(productData['createdBy'])
                  : null,
          'metadata': null,
        };
      }

      return {
        'prices': null,
        'category': null,
        'createdBy': null,
        'metadata': null,
      };
    } catch (e) {
      print('❌ Error al deserializar datos del producto: $e');
      print('📋 JSON problemático: $metadataJson');
      return {
        'prices': null,
        'category': null,
        'createdBy': null,
        'metadata': null,
      };
    }
  }

  /// Deserializar precios desde JSON string almacenado en ISAR
  List<ProductPriceModel>? _deserializePrices(String pricesJsonString) {
    try {
      if (pricesJsonString.isEmpty || pricesJsonString == 'null') {
        return null;
      }

      final pricesJson = jsonDecode(pricesJsonString);
      if (pricesJson is List) {
        return pricesJson
            .map((priceJson) => ProductPriceModel.fromJson(priceJson))
            .toList();
      } else {
        print(
          '⚠️ Formato de precios JSON inesperado: ${pricesJson.runtimeType}',
        );
        return null;
      }
    } catch (e) {
      print('❌ Error al deserializar precios: $e');
      print('📋 JSON problemático: $pricesJsonString');
      return null;
    }
  }

  /// Deserializar lista de precios desde List (helper)
  List<ProductPriceModel>? _deserializePricesFromList(dynamic pricesList) {
    try {
      if (pricesList == null || pricesList is! List) {
        return null;
      }

      return pricesList
          .map((priceJson) => ProductPriceModel.fromJson(priceJson))
          .toList();
    } catch (e) {
      print('❌ Error al deserializar lista de precios: $e');
      return null;
    }
  }

  /// Deserializar categoría desde JSON
  ProductCategoryModel? _deserializeCategoryFromJson(dynamic categoryJson) {
    try {
      if (categoryJson == null || categoryJson is! Map<String, dynamic>) {
        return null;
      }

      return ProductCategoryModel.fromJson(categoryJson);
    } catch (e) {
      print('❌ Error al deserializar categoría: $e');
      return null;
    }
  }

  /// Deserializar createdBy desde JSON
  ProductCreatorModel? _deserializeCreatedByFromJson(dynamic createdByJson) {
    try {
      if (createdByJson == null || createdByJson is! Map<String, dynamic>) {
        return null;
      }

      return ProductCreatorModel.fromJson(createdByJson);
    } catch (e) {
      print('❌ Error al deserializar createdBy: $e');
      return null;
    }
  }

  /// Parsear string JSON a Map de forma segura
  Map<String, dynamic> _parseJsonString(String jsonString) {
    try {
      if (jsonString.isEmpty || jsonString == 'null') {
        return {};
      }

      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is Map) {
        // Convertir Map genérico a Map<String, dynamic>
        return Map<String, dynamic>.from(decoded);
      } else {
        print('⚠️ JSON no es un objeto válido: ${decoded.runtimeType}');
        return {};
      }
    } catch (e) {
      print('❌ Error al parsear JSON string: $e');
      print('📋 JSON problemático: $jsonString');
      return {};
    }
  }

  // ==================== ✅ IMPLEMENTACIONES DE MÉTODOS FALTANTES ====================

  @override
  Future<void> cacheProductForSync(Product product) async {
    try {
      final Isar isar = _database.database as Isar;

      // Crear IsarProduct para el producto offline
      final isarProduct =
          IsarProduct()
            ..serverId = product.id
            ..name = product.name
            ..description = product.description
            ..sku = product.sku
            ..barcode = product.barcode
            ..type = _mapToIsarProductType(product.type.name)
            ..status = _mapToIsarProductStatus(product.status.name)
            ..stock = product.stock
            ..minStock = product.minStock
            ..unit = product.unit
            ..weight = product.weight
            ..length = product.length
            ..width = product.width
            ..height = product.height
            ..categoryId = product.categoryId
            ..createdById = product.createdBy?.id ?? ''
            ..createdAt = product.createdAt
            ..updatedAt = product.updatedAt
            ..isSynced = false // Marcar como no sincronizado
            ..version = 1; // ✅ Campo requerido

      // Serializar datos adicionales (metadata, precios, etc.)
      final productModel = ProductModel.fromEntity(product);
      final productData = _serializeProductData(productModel);
      isarProduct.metadataJson = productData;

      // ✅ CORRECCIÓN: También guardar precios en el campo prices
      isarProduct.prices = productModel.prices?.map((p) => IsarProductPrice.fromModel(p)).toList() ?? [];

      await isar.writeTxn(() async {
        await isar.isarProducts.put(isarProduct);
      });

      print(
        '✅ ProductLocalDataSourceIsar: Product cached for sync: ${product.name}',
      );
    } catch (e) {
      throw CacheException('Error caching product for sync in ISAR: $e');
    }
  }

  @override
  Future<List<Product>> getUnsyncedProducts() async {
    try {
      final Isar isar = _database.database as Isar;

      // Buscar productos no sincronizados
      final List<IsarProduct> unsyncedIsarProducts =
          await isar.isarProducts.filter().isSyncedEqualTo(false).findAll();

      final unsyncedProducts = <Product>[];

      for (final isarProduct in unsyncedIsarProducts) {
        try {
          // Convertir IsarProduct a ProductModel y luego a Product entity
          final productModel = _isarProductToModel(isarProduct);
          final productEntity = productModel.toEntity();
          unsyncedProducts.add(productEntity);
        } catch (e) {
          print(
            '⚠️ Error converting unsynced product ${isarProduct.serverId}: $e',
          );
        }
      }

      print(
        '📋 ProductLocalDataSourceIsar: Found ${unsyncedProducts.length} unsynced products',
      );
      return unsyncedProducts;
    } catch (e) {
      throw CacheException('Error getting unsynced products from ISAR: $e');
    }
  }

  @override
  Future<void> markProductAsSynced(String tempId, String serverId) async {
    try {
      final Isar isar = _database.database as Isar;

      await isar.writeTxn(() async {
        // Buscar el producto temporal
        final tempProduct =
            await isar.isarProducts
                .filter()
                .serverIdEqualTo(tempId)
                .findFirst();

        if (tempProduct != null) {
          // Actualizar con el ID del servidor y marcar como sincronizado
          tempProduct.serverId = serverId;
          tempProduct.isSynced = true;
          tempProduct.updatedAt = DateTime.now();

          await isar.isarProducts.put(tempProduct);
        }
      });

      print(
        '✅ ProductLocalDataSourceIsar: Product marked as synced: $tempId -> $serverId',
      );
    } catch (e) {
      throw CacheException('Error marking product as synced in ISAR: $e');
    }
  }

  /// Convertir IsarProduct a ProductModel (método auxiliar)
  ProductModel _isarProductToModel(IsarProduct isarProduct) {
    // Deserializar datos adicionales
    final deserializedData = _deserializeProductData(isarProduct.metadataJson);

    return ProductModel(
      id: isarProduct.serverId,
      name: isarProduct.name,
      description: isarProduct.description ?? '',
      sku: isarProduct.sku,
      barcode: isarProduct.barcode,
      type: _mapFromIsarProductType(isarProduct.type).name,
      status: _mapFromIsarProductStatus(isarProduct.status).name,
      stock: isarProduct.stock ?? 0.0,
      minStock: isarProduct.minStock ?? 0.0,
      unit: isarProduct.unit ?? 'pcs',
      weight: isarProduct.weight,
      length: isarProduct.length,
      width: isarProduct.width,
      height: isarProduct.height,
      images: deserializedData['images'] as List<String>? ?? [],
      metadata: deserializedData['metadata'] as Map<String, dynamic>? ?? {},
      categoryId: isarProduct.categoryId,
      createdById: isarProduct.createdById ?? '',
      category: deserializedData['category'] as ProductCategoryModel?,
      prices: deserializedData['prices'] as List<ProductPriceModel>? ?? [],
      createdBy: deserializedData['createdBy'] as ProductCreatorModel?,
      createdAt: isarProduct.createdAt,
      updatedAt: isarProduct.updatedAt,
      taxCategory: IsarProduct.mapIsarTaxCategoryToString(isarProduct.taxCategory),
      taxRate: isarProduct.taxRate,
      isTaxable: isarProduct.isTaxable,
      hasRetention: isarProduct.hasRetention,
    );
  }

  // ==================== ✅ VALIDACIÓN DE DUPLICADOS ====================

  /// Verificar si existe un producto con el mismo nombre
  @override
  Future<bool> existsByName(String name, {String? excludeId}) async {
    try {
      final Isar isar = _database.database as Isar;
      final nameLower = name.trim().toLowerCase();

      // Obtener todos los productos
      final List<IsarProduct> allProducts = await isar.isarProducts.where().findAll();

      for (final product in allProducts) {
        // Excluir el producto que estamos editando
        if (excludeId != null && product.serverId == excludeId) {
          continue;
        }

        if (product.name.trim().toLowerCase() == nameLower) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // Si hay error, asumir que no existe
      return false;
    }
  }

  /// Verificar si existe un producto con el mismo SKU
  @override
  Future<bool> existsBySku(String sku, {String? excludeId}) async {
    try {
      final Isar isar = _database.database as Isar;
      final skuLower = sku.trim().toLowerCase();

      // Obtener todos los productos
      final List<IsarProduct> allProducts = await isar.isarProducts.where().findAll();

      for (final product in allProducts) {
        // Excluir el producto que estamos editando
        if (excludeId != null && product.serverId == excludeId) {
          continue;
        }

        if (product.sku.trim().toLowerCase() == skuLower) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // Si hay error, asumir que no existe
      return false;
    }
  }

  /// Buscar productos en cache por término de búsqueda
  @override
  Future<List<ProductModel>> searchCachedProducts(String searchTerm) async {
    try {
      final Isar isar = _database.database as Isar;
      final term = searchTerm.toLowerCase();

      // Obtener todos los productos y filtrar localmente
      // Excluir registro STATS_CACHE
      final List<IsarProduct> allProducts = await isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .and()
          .not()
          .serverIdEqualTo('STATS_CACHE')
          .findAll();

      final matchingProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(term) ||
            product.sku.toLowerCase().contains(term) ||
            (product.description?.toLowerCase().contains(term) ?? false) ||
            (product.barcode?.toLowerCase().contains(term) ?? false);
      }).toList();

      return matchingProducts
          .map((isarProduct) => _convertToProductModel(isarProduct))
          .toList();
    } catch (e) {
      print('❌ Error al buscar productos en ISAR: $e');
      return [];
    }
  }

  // ⭐ FASE 1: Obtener IsarProduct directamente para acceder a campos de versionamiento
  @override
  Future<IsarProduct?> getIsarProduct(String id) async {
    try {
      final Isar isar = _database.database as Isar;
      final isarProduct = await isar.isarProducts
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      return isarProduct;
    } catch (e) {
      print('⚠️ Error al obtener IsarProduct: $e');
      return null;
    }
  }
}
