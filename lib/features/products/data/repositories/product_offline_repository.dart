// lib/features/products/data/repositories/product_offline_repository.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';
import '../../domain/entities/product_stats.dart';
import '../../domain/entities/tax_enums.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/isar/isar_product.dart';
import '../models/isar/isar_product_price.dart';

/// Implementación offline del repositorio de productos usando ISAR
class ProductOfflineRepository implements ProductRepository {
  final IIsarDatabase _database;

  ProductOfflineRepository({IIsarDatabase? database})
      : _database = database ?? IsarDatabase.instance;

  Isar get _isar => _database.database as Isar;

  // ==================== READ OPERATIONS ====================

  @override
  Future<Either<Failure, PaginatedResult<Product>>> getProducts({
    int page = 1,
    int limit = 10,
    String? search,
    ProductStatus? status,
    ProductType? type,
    String? categoryId,
    String? createdById,
    bool? inStock,
    bool? lowStock,
    double? minPrice,
    double? maxPrice,
    PriceType? priceType,
    bool? includePrices,
    bool? includeCategory,
    bool? includeCreatedBy,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      var query = _isar.isarProducts.filter().deletedAtIsNull();

      // Apply filters
      if (search != null && search.isNotEmpty) {
        query = query.and().group((q) => q
            .nameContains(search, caseSensitive: false)
            .or()
            .skuContains(search, caseSensitive: false)
            .or()
            .barcodeContains(search, caseSensitive: false));
      }

      if (status != null) {
        final isarStatus = _mapProductStatus(status);
        query = query.and().statusEqualTo(isarStatus);
      }

      if (type != null) {
        final isarType = _mapProductType(type);
        query = query.and().typeEqualTo(isarType);
      }

      if (categoryId != null) {
        query = query.and().categoryIdEqualTo(categoryId);
      }

      if (createdById != null) {
        query = query.and().createdByIdEqualTo(createdById);
      }

      if (inStock == true) {
        query = query.and().stockGreaterThan(0.0);
      }

      // ✅ OPTIMIZACIÓN: Usar paginación nativa de ISAR cuando es posible
      // Solo necesitamos cargar todo en memoria si hay filtro lowStock
      // (porque requiere comparación cross-field: stock <= minStock)

      final offset = (page - 1) * limit;
      List<IsarProduct> paginatedProducts;
      int totalItems;

      if (lowStock == true) {
        // Fallback a paginación en memoria para filtro lowStock
        List<IsarProduct> allProducts = await query.findAll();
        allProducts = allProducts.where((p) => p.stock <= p.minStock).toList();
        totalItems = allProducts.length;

        // Sort in memory
        _sortProductsInMemory(allProducts, sortBy, sortOrder);

        // Paginate in memory
        paginatedProducts = allProducts.skip(offset).take(limit).toList();
      } else {
        // ✅ USAR PAGINACIÓN NATIVA DE ISAR (más eficiente)
        totalItems = await query.count();

        // Apply sorting and pagination using ISAR native methods
        if (sortBy == 'name') {
          paginatedProducts = sortOrder == 'desc'
              ? await query.sortByNameDesc().offset(offset).limit(limit).findAll()
              : await query.sortByName().offset(offset).limit(limit).findAll();
        } else if (sortBy == 'stock') {
          paginatedProducts = sortOrder == 'desc'
              ? await query.sortByStockDesc().offset(offset).limit(limit).findAll()
              : await query.sortByStock().offset(offset).limit(limit).findAll();
        } else if (sortBy == 'createdAt') {
          paginatedProducts = sortOrder == 'desc'
              ? await query.sortByCreatedAtDesc().offset(offset).limit(limit).findAll()
              : await query.sortByCreatedAt().offset(offset).limit(limit).findAll();
        } else {
          // Default sort by name descending
          paginatedProducts = await query.sortByNameDesc().offset(offset).limit(limit).findAll();
        }
      }

      // Convert to domain entities (only paginated products)
      final products = paginatedProducts.map((isar) => isar.toEntity()).toList();

      // Create pagination meta
      final totalPages = (totalItems / limit).ceil();
      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(PaginatedResult(data: products, meta: meta));
    } catch (e) {
      return Left(CacheFailure('Error loading products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .serverIdEqualTo(id)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading product: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductBySku(String sku) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .skuEqualTo(sku)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading product by SKU: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .barcodeEqualTo(barcode)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error loading product by barcode: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> findBySkuOrBarcode(String code) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .group((q) => q.skuEqualTo(code).or().barcodeEqualTo(code))
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error finding product: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(
    String searchTerm, {
    int limit = 10,
  }) async {
    try {
      final List<IsarProduct> isarProducts = await _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .and()
          .group((q) => q
              .nameContains(searchTerm, caseSensitive: false)
              .or()
              .skuContains(searchTerm, caseSensitive: false)
              .or()
              .barcodeContains(searchTerm, caseSensitive: false)
              .or()
              .descriptionContains(searchTerm, caseSensitive: false))
          .limit(limit)
          .findAll();

      final products = isarProducts.map((isar) => isar.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure('Error searching products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getLowStockProducts() async {
    try {
      // Get all products and filter in memory since Isar doesn't support cross-field comparisons
      final List<IsarProduct> allProducts = await _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .and()
          .statusEqualTo(IsarProductStatus.active)
          .findAll();

      final lowStockProducts = allProducts
          .where((p) => p.stock <= p.minStock)
          .map((p) => p.toEntity())
          .toList();

      return Right(lowStockProducts);
    } catch (e) {
      return Left(CacheFailure('Error loading low stock products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getOutOfStockProducts() async {
    try {
      final isarProducts = await _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .and()
          .stockEqualTo(0)
          .findAll();

      final products = isarProducts.map((isar) => isar.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure('Error loading out of stock products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      final isarProducts = await _isar.isarProducts
          .filter()
          .categoryIdEqualTo(categoryId)
          .and()
          .deletedAtIsNull()
          .findAll();

      final products = isarProducts.map((isar) => isar.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure('Error loading products by category: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ProductStats>> getProductStats() async {
    try {
      final List<IsarProduct> allProducts = await _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .findAll();

      final total = allProducts.length;
      final active = allProducts.where((p) => p.status == IsarProductStatus.active).length;
      final inactive = allProducts.where((p) => p.status == IsarProductStatus.inactive).length;
      final outOfStock = allProducts.where((p) => p.stock == 0).length;
      final lowStock = allProducts.where((p) => p.stock <= p.minStock && p.stock > 0).length;

      // Calculate total value (stock * cost price)
      double totalValue = 0.0;
      double totalPriceSum = 0.0;
      int productsWithPrice = 0;

      for (final product in allProducts) {
        final costPrice = product.prices
            .where((p) => p.type == IsarPriceType.cost && p.isActive)
            .firstOrNull;

        if (costPrice != null) {
          totalValue += product.stock * costPrice.finalAmount;
          totalPriceSum += costPrice.finalAmount;
          productsWithPrice++;
        }
      }

      final averagePrice = productsWithPrice > 0 ? totalPriceSum / productsWithPrice : 0.0;
      final activePercentage = total > 0 ? (active / total) * 100 : 0.0;

      final stats = ProductStats(
        total: total,
        active: active,
        inactive: inactive,
        outOfStock: outOfStock,
        lowStock: lowStock,
        activePercentage: activePercentage,
        totalValue: totalValue,
        averagePrice: averagePrice,
      );

      return Right(stats);
    } catch (e) {
      return Left(CacheFailure('Error calculating product stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getInventoryValue() async {
    try {
      final List<IsarProduct> allProducts = await _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .findAll();

      double totalValue = 0.0;

      for (final product in allProducts) {
        final costPrice = product.prices
            .where((p) => p.type == IsarPriceType.cost && p.isActive)
            .firstOrNull;

        if (costPrice != null) {
          totalValue += product.stock * costPrice.finalAmount;
        }
      }

      return Right(totalValue);
    } catch (e) {
      return Left(CacheFailure('Error calculating inventory value: ${e.toString()}'));
    }
  }

  // ==================== WRITE OPERATIONS ====================

  @override
  Future<Either<Failure, Product>> createProduct({
    required String name,
    String? description,
    required String sku,
    String? barcode,
    ProductType? type,
    ProductStatus? status,
    double? stock,
    double? minStock,
    String? unit,
    double? weight,
    double? length,
    double? width,
    double? height,
    List<String>? images,
    Map<String, dynamic>? metadata,
    required String categoryId,
    List<CreateProductPriceParams>? prices,
    TaxCategory? taxCategory,
    double? taxRate,
    bool? isTaxable,
    String? taxDescription,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool? hasRetention,
  }) async {
    try {
      final now = DateTime.now();
      final serverId = 'product_offline_${now.millisecondsSinceEpoch}_${sku.hashCode}';

      // Convert price params to IsarProductPrice
      final isarPrices = prices?.map((p) {
        final priceId = 'price_${now.millisecondsSinceEpoch}_${p.type.name.hashCode}';
        return IsarProductPrice.create(
          serverId: priceId,
          type: _mapPriceType(p.type),
          name: p.name,
          amount: p.amount,
          currency: p.currency ?? 'COP',
          status: IsarPriceStatus.active,
          discountPercentage: p.discountPercentage ?? 0,
          discountAmount: p.discountAmount,
          minQuantity: p.minQuantity ?? 1,
          notes: p.notes,
          createdAt: now,
          updatedAt: now,
        );
      }).toList() ?? [];

      final isarProduct = IsarProduct.create(
        serverId: serverId,
        name: name,
        description: description,
        sku: sku,
        barcode: barcode,
        type: _mapProductType(type ?? ProductType.product),
        status: _mapProductStatus(status ?? ProductStatus.active),
        stock: stock ?? 0,
        minStock: minStock ?? 0,
        unit: unit,
        weight: weight,
        length: length,
        width: width,
        height: height,
        images: images,
        metadataJson: metadata != null ? jsonEncode(metadata) : null,
        categoryId: categoryId,
        createdById: 'offline', // TODO: Get from auth context
        createdAt: now,
        updatedAt: now,
        isSynced: false,
        prices: isarPrices,
      );

      await _isar.writeTxn(() async {
        await _isar.isarProducts.put(isarProduct);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Product',
          entityId: serverId,
          operationType: SyncOperationType.create,
          data: {
            'name': name,
            'description': description,
            'sku': sku,
            'barcode': barcode,
            'type': type?.name,
            'status': status?.name,
            'stock': stock,
            'minStock': minStock,
            'categoryId': categoryId,
            // Add other fields as needed
          },
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error creating product: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct({
    required String id,
    String? name,
    String? description,
    String? sku,
    String? barcode,
    ProductType? type,
    ProductStatus? status,
    double? stock,
    double? minStock,
    String? unit,
    double? weight,
    double? length,
    double? width,
    double? height,
    List<String>? images,
    Map<String, dynamic>? metadata,
    String? categoryId,
    List<CreateProductPriceParams>? prices,
    TaxCategory? taxCategory,
    double? taxRate,
    bool? isTaxable,
    String? taxDescription,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool? hasRetention,
  }) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      // Update fields
      if (name != null) isarProduct.name = name;
      if (description != null) isarProduct.description = description;
      if (sku != null) isarProduct.sku = sku;
      if (barcode != null) isarProduct.barcode = barcode;
      if (type != null) isarProduct.type = _mapProductType(type);
      if (status != null) isarProduct.status = _mapProductStatus(status);
      if (stock != null) isarProduct.stock = stock;
      if (minStock != null) isarProduct.minStock = minStock;
      if (unit != null) isarProduct.unit = unit;
      if (weight != null) isarProduct.weight = weight;
      if (length != null) isarProduct.length = length;
      if (width != null) isarProduct.width = width;
      if (height != null) isarProduct.height = height;
      if (images != null) isarProduct.images = images;
      if (metadata != null) isarProduct.metadataJson = jsonEncode(metadata);
      if (categoryId != null) isarProduct.categoryId = categoryId;

      // Update prices if provided
      if (prices != null) {
        final now = DateTime.now();
        final isarPrices = prices.map((p) {
          final priceId = 'price_${now.millisecondsSinceEpoch}_${p.type.name.hashCode}';
          return IsarProductPrice.create(
            serverId: priceId,
            type: _mapPriceType(p.type),
            name: p.name,
            amount: p.amount,
            currency: p.currency ?? 'COP',
            status: IsarPriceStatus.active,
            discountPercentage: p.discountPercentage ?? 0,
            discountAmount: p.discountAmount,
            minQuantity: p.minQuantity ?? 1,
            notes: p.notes,
            createdAt: now,
            updatedAt: now,
          );
        }).toList();
        isarProduct.prices = isarPrices;
      }

      isarProduct.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarProducts.put(isarProduct);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Product',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {'updated': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating product: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProductStatus({
    required String id,
    required ProductStatus status,
  }) async {
    return updateProduct(id: id, status: status);
  }

  @override
  Future<Either<Failure, Product>> updateProductStock({
    required String id,
    required double quantity,
    String operation = 'subtract',
  }) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      if (operation == 'subtract') {
        isarProduct.stock = (isarProduct.stock - quantity).clamp(0, double.infinity);
      } else if (operation == 'add') {
        isarProduct.stock += quantity;
      }

      isarProduct.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarProducts.put(isarProduct);
      });

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error updating product stock: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct(String id) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      isarProduct.softDelete();

      await _isar.writeTxn(() async {
        await _isar.isarProducts.put(isarProduct);
      });

      // Add to sync queue
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Product',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'deleted': true},
        );
      } catch (e) {
        print('Warning: Could not add to sync queue: $e');
      }

      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Error deleting product: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> restoreProduct(String id) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarProduct == null) {
        return Left(CacheFailure('Product not found'));
      }

      isarProduct.deletedAt = null;
      isarProduct.markAsUnsynced();

      await _isar.writeTxn(() async {
        await _isar.isarProducts.put(isarProduct);
      });

      return Right(isarProduct.toEntity());
    } catch (e) {
      return Left(CacheFailure('Error restoring product: ${e.toString()}'));
    }
  }

  // ==================== STOCK OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> validateStockForSale({
    required String productId,
    required double quantity,
  }) async {
    try {
      final isarProduct = await _isar.isarProducts
          .filter()
          .serverIdEqualTo(productId)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (isarProduct == null) {
        return const Right(false);
      }

      return Right(isarProduct.stock >= quantity);
    } catch (e) {
      return Left(CacheFailure('Error validating stock: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> reduceStockForSale({
    required String productId,
    required double quantity,
  }) async {
    final result = await updateProductStock(
      id: productId,
      quantity: quantity,
      operation: 'subtract',
    );

    return result.fold(
      (failure) => Left(failure),
      (_) => const Right(unit),
    );
  }

  // ==================== PRICE OPERATIONS ====================

  @override
  Future<Either<Failure, Product>> getProductWithPrice({
    required String productId,
    PriceType priceType = PriceType.price1,
  }) async {
    // For offline, just return the product with all its prices
    return getProductById(productId);
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Product>>> getCachedProducts() async {
    try {
      final isarProducts = await _isar.isarProducts
          .filter()
          .deletedAtIsNull()
          .findAll();

      final products = isarProducts.map((isar) => isar.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure('Error loading cached products: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearProductCache() async {
    // For offline implementation, we don't clear the cache
    // The cache IS the primary storage
    return const Right(unit);
  }

  // ==================== HELPER METHODS ====================

  IsarProductType _mapProductType(ProductType type) {
    switch (type) {
      case ProductType.product:
        return IsarProductType.product;
      case ProductType.service:
        return IsarProductType.service;
    }
  }

  IsarProductStatus _mapProductStatus(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return IsarProductStatus.active;
      case ProductStatus.inactive:
        return IsarProductStatus.inactive;
      case ProductStatus.outOfStock:
        return IsarProductStatus.outOfStock;
    }
  }

  IsarPriceType _mapPriceType(PriceType type) {
    switch (type) {
      case PriceType.price1:
        return IsarPriceType.price1;
      case PriceType.price2:
        return IsarPriceType.price2;
      case PriceType.price3:
        return IsarPriceType.price3;
      case PriceType.special:
        return IsarPriceType.special;
      case PriceType.cost:
        return IsarPriceType.cost;
    }
  }

  /// Helper para ordenar productos en memoria (usado cuando hay filtro lowStock)
  void _sortProductsInMemory(List<IsarProduct> products, String? sortBy, String? sortOrder) {
    if (sortBy == 'name') {
      products.sort((a, b) => sortOrder == 'desc'
          ? b.name.compareTo(a.name)
          : a.name.compareTo(b.name));
    } else if (sortBy == 'stock') {
      products.sort((a, b) => sortOrder == 'desc'
          ? b.stock.compareTo(a.stock)
          : a.stock.compareTo(b.stock));
    } else if (sortBy == 'createdAt') {
      products.sort((a, b) => sortOrder == 'desc'
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt));
    } else {
      // Default sort by name descending
      products.sort((a, b) => b.name.compareTo(a.name));
    }
  }

  // ==================== SYNC OPERATIONS ====================

  Future<Either<Failure, List<Product>>> getUnsyncedProducts() async {
    try {
      final isarProducts = await _isar.isarProducts
          .filter()
          .isSyncedEqualTo(false)
          .findAll();

      final products = isarProducts.map((isar) => isar.toEntity()).toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure('Error loading unsynced products: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> markProductsAsSynced(List<String> productIds) async {
    try {
      await _isar.writeTxn(() async {
        for (final id in productIds) {
          final isarProduct = await _isar.isarProducts
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarProduct != null) {
            isarProduct.markAsSynced();
            await _isar.isarProducts.put(isarProduct);
          }
        }
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error marking products as synced: ${e.toString()}'));
    }
  }

  Future<Either<Failure, void>> bulkInsertProducts(List<Product> products) async {
    try {
      final isarProducts = products
          .map((product) => IsarProduct.fromEntity(product))
          .toList();

      await _isar.writeTxn(() async {
        await _isar.isarProducts.putAll(isarProducts);
      });

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Error bulk inserting products: ${e.toString()}'));
    }
  }

  // ==================== VALIDATION OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> existsByName(String name, {String? excludeId}) async {
    try {
      final nameLower = name.trim().toLowerCase();
      final List<IsarProduct> allProducts = await _isar.isarProducts.where().findAll();

      print('🔍 ProductOfflineRepository.existsByName: Verificando nombre "$name"');
      print('   excludeId: $excludeId');
      print('   Total productos en ISAR: ${allProducts.length}');

      for (final product in allProducts) {
        if (excludeId != null && product.serverId == excludeId) {
          print('   ⏭️ Excluyendo producto actual: ${product.name} (${product.serverId})');
          continue;
        }

        if (product.name.trim().toLowerCase() == nameLower) {
          print('   ❌ Nombre duplicado encontrado: ${product.name} (${product.serverId})');
          return const Right(true);
        }
      }

      print('   ✅ Nombre único, no se encontraron duplicados');
      return const Right(false);
    } catch (e) {
      return Left(CacheFailure('Error checking name existence: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> existsBySku(String sku, {String? excludeId}) async {
    try {
      final skuLower = sku.trim().toLowerCase();
      final List<IsarProduct> allProducts = await _isar.isarProducts.where().findAll();

      print('🔍 ProductOfflineRepository.existsBySku: Verificando SKU "$sku"');
      print('   excludeId: $excludeId');
      print('   Total productos en ISAR: ${allProducts.length}');

      for (final product in allProducts) {
        if (excludeId != null && product.serverId == excludeId) {
          print('   ⏭️ Excluyendo producto actual: ${product.name} (${product.serverId})');
          continue;
        }

        if (product.sku.trim().toLowerCase() == skuLower) {
          print('   ❌ SKU duplicado encontrado: ${product.name} (${product.serverId}) tiene SKU ${product.sku}');
          return const Right(true);
        }
      }

      print('   ✅ SKU único, no se encontraron duplicados');
      return const Right(false);
    } catch (e) {
      return Left(CacheFailure('Error checking SKU existence: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> existsByBarcode(String barcode, {String? excludeId}) async {
    try {
      if (barcode.isEmpty) {
        return const Right(false);
      }

      final barcodeLower = barcode.trim().toLowerCase();
      final List<IsarProduct> allProducts = await _isar.isarProducts.where().findAll();

      for (final product in allProducts) {
        if (excludeId != null && product.serverId == excludeId) {
          continue;
        }

        final productBarcode = product.barcode?.trim().toLowerCase();
        if (productBarcode == barcodeLower) {
          return const Right(true);
        }
      }

      return const Right(false);
    } catch (e) {
      return Left(CacheFailure('Error checking barcode existence: ${e.toString()}'));
    }
  }
}
