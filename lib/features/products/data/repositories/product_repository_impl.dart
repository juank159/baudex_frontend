// lib/features/products/data/repositories/product_repository_impl.dart
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../../app/core/services/conflict_resolver.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';
import '../../domain/entities/product_stats.dart';
import '../../domain/entities/tax_enums.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_model.dart';
import '../models/product_query_model.dart';
import '../models/create_product_request_model.dart';
import '../models/update_product_request_model.dart';
import '../models/isar/isar_product.dart';
import '../models/isar/isar_product_price.dart';

/// Implementación del repositorio de productos
///
/// Esta clase maneja la lógica de datos combinando fuentes remotas y locales,
/// implementando estrategias de cache y manejo de errores robusto.
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final dynamic _database;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    dynamic database,
  }) : _database = database ?? IsarDatabase.instance;

  // Getter para acceder a la base de datos ISAR
  dynamic get _isar => _database.database;

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
    print('🚀🚀🚀 PRODUCT REPOSITORY GET PRODUCTS LLAMADO!!! 🚀🚀🚀');
    print('🚀🚀🚀 SI VES ESTE LOG, EL CÓDIGO NUEVO SE ESTÁ EJECUTANDO 🚀🚀🚀');
    print('   📄 Params: page=$page, limit=$limit, search=$search');

    // Verificar conexión a internet
    print('🔍 ProductRepository: Verificando conexión a internet...');
    try {
      final isConnected = await networkInfo.isConnected;
      print('🌐 ProductRepository: networkInfo.isConnected retornó = $isConnected');

      if (isConnected) {
        print('✅ ProductRepository: HAY CONEXIÓN - Intentando llamar al backend...');
        try {
        // Crear query model con todos los parámetros
        final query = ProductQueryModel(
          page: page,
          limit: limit,
          search: search,
          status: status,
          type: type,
          categoryId: categoryId,
          createdById: createdById,
          inStock: inStock,
          lowStock: lowStock,
          minPrice: minPrice,
          maxPrice: maxPrice,
          priceType: priceType,
          includePrices: includePrices,
          includeCategory: includeCategory,
          includeCreatedBy: includeCreatedBy,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );

        // Realizar llamada remota
        print('📡 ProductRepository: Llamando a remoteDataSource.getProducts()...');
        final response = await remoteDataSource.getProducts(query);
        print('📦 ProductRepository: Respuesta recibida del backend con ${response.data.length} productos');

        // Cache solo resultados de la primera página sin filtros específicos
        // para tener datos base disponibles offline
        if (_shouldCacheResult(page, search, status, type, categoryId)) {
          try {
            await localDataSource.cacheProducts(response.data);
          } catch (e) {
            // Log del error pero no fallar la operación principal
            print('⚠️ Error al cachear productos: $e');
          }
        }

        // Convertir respuesta a entidades del dominio
        final paginatedResult = response.toPaginatedResult();

        return Right(
          PaginatedResult<Product>(
            data:
                paginatedResult.data.map((model) => model.toEntity()).toList(),
            meta: paginatedResult.meta,
          ),
        );
      } on ServerException catch (e) {
        print('⚠️ ServerException: ${e.message} - Intentando cache como fallback...');
        return _getProductsFromCache();
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException: ${e.message} - Intentando cache como fallback...');
        return _getProductsFromCache();
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e, stackTrace) {
        print('❌ ProductRepository: Error inesperado en rama ONLINE: $e');
        print('📚 StackTrace: $stackTrace');
        print('🔄 Intentando cache como fallback...');
        return _getProductsFromCache();
      }
    } else {
      print('⚠️ ProductRepository: SIN CONEXIÓN - Usando caché local');
      // Sin conexión, intentar obtener desde cache
      final cacheResult = await _getProductsFromCache();
      cacheResult.fold(
        (failure) => print('❌ Cache falló: ${failure.message}'),
        (data) => print('✅ Cache retornó ${data.data.length} productos'),
      );
      return cacheResult;
    }
    } catch (e, stackTrace) {
      print('💥 ProductRepository: ERROR FATAL en networkInfo.isConnected: $e');
      print('📚 StackTrace: $stackTrace');
      // Si falla la verificación de red, intentar desde caché como fallback
      print('🔄 Intentando caché como fallback...');
      return _getProductsFromCache();
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        // Intentar obtener desde el servidor
        final response = await remoteDataSource.getProductById(id);

        // ⭐ FASE 1: Resolución de conflictos con ConflictResolver
        Product finalProduct = response.toEntity();
        try {
          // Obtener versión local de ISAR para acceder a campos de versionamiento
          final localIsarProduct = await localDataSource.getIsarProduct(id);

          if (localIsarProduct != null && !localIsarProduct.isSynced) {
            // Hay una versión local no sincronizada, verificar conflictos
            print('🔍 Versión local de producto no sincronizada encontrada, verificando conflictos...');

            // Crear versión ISAR del servidor para comparar
            final serverIsarProduct = IsarProduct.fromModel(response);

            // Usar ConflictResolver para detectar y resolver
            final resolver = Get.find<ConflictResolver>();
            final resolution = resolver.resolveConflict<IsarProduct>(
              localData: localIsarProduct,
              serverData: serverIsarProduct,
              strategy: ConflictResolutionStrategy.newerWins,
              hasConflictWith: (local, server) => local.hasConflictWith(server),
              getVersion: (data) => data.version,
              getLastModifiedAt: (data) => data.lastModifiedAt,
            );

            if (resolution.hadConflict) {
              print('⚠️ CONFLICTO DETECTADO Y RESUELTO: ${resolution.message}');
              print('   Estrategia usada: ${resolution.strategy.name}');
              finalProduct = resolution.resolvedData.toEntity();
            } else {
              print('✅ No hay conflicto, usando datos del servidor');
            }
          } else if (localIsarProduct == null) {
            print('   📝 No hay versión local, usando datos del servidor');
          } else {
            print('   ✅ Versión local ya sincronizada, usando datos del servidor');
          }
        } catch (e) {
          print('⚠️ Error al verificar conflictos: $e');
        }

        // Cache el producto final (resuelto) para uso offline
        try {
          await localDataSource.cacheProduct(ProductModel.fromEntity(finalProduct));
        } catch (e) {
          print('⚠️ Error al cachear producto individual: $e');
        }

        return Right(finalProduct);
      } on ServerException catch (e) {
        // Si falla el servidor, intentar desde cache como fallback
        final cacheResult = await _getProductFromCache(id);
        return cacheResult.fold(
          (failure) => Left(
            _mapServerExceptionToFailure(e),
          ), // Error original del servidor
          (product) => Right(product), // Éxito desde cache
        );
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        // Para otros errores, intentar cache como fallback
        return _getProductFromCache(id);
      }
    } else {
      // Sin conexión, ir directo al cache
      return _getProductFromCache(id);
    }
  }

  @override
  Future<Either<Failure, Product>> getProductBySku(String sku) async {
    try {
      final response = await remoteDataSource.getProductBySku(sku);

      // Cache el producto encontrado
      try {
        await localDataSource.cacheProduct(response);
      } catch (e) {
        print('⚠️ Error al cachear producto por SKU: $e');
      }

      return Right(response.toEntity());
    } catch (e) {
      print('⚠️ Error del servidor en getProductBySku: $e - intentando cache local...');
      try {
        final cached = await localDataSource.getCachedProductBySku(sku);
        if (cached != null) {
          print('✅ Producto obtenido desde cache local por SKU');
          return Right(cached.toEntity());
        }
        return Left(CacheFailure('No hay producto con SKU $sku en cache local'));
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final response = await remoteDataSource.getProductByBarcode(barcode);

      // Cache el producto encontrado
      try {
        await localDataSource.cacheProduct(response);
      } catch (e) {
        print('⚠️ Error al cachear producto por código de barras: $e');
      }

      return Right(response.toEntity());
    } catch (e) {
      print('⚠️ Error del servidor en getProductByBarcode: $e - intentando cache local...');
      try {
        final cached = await localDataSource.getCachedProductByBarcode(barcode);
        if (cached != null) {
          print('✅ Producto obtenido desde cache local por código de barras');
          return Right(cached.toEntity());
        }
        return Left(CacheFailure('No hay producto con barcode $barcode en cache local'));
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, Product>> findBySkuOrBarcode(String code) async {
    try {
      final response = await remoteDataSource.findBySkuOrBarcode(code);

      // Cache el producto encontrado
      try {
        await localDataSource.cacheProduct(response);
      } catch (e) {
        print('⚠️ Error al cachear producto encontrado: $e');
      }

      return Right(response.toEntity());
    } catch (e) {
      print('⚠️ Error del servidor en findBySkuOrBarcode: $e - intentando cache local...');
      try {
        // Intentar buscar por SKU primero
        final cachedBySku = await localDataSource.getCachedProductBySku(code);
        if (cachedBySku != null) {
          print('✅ Producto obtenido desde cache local por SKU');
          return Right(cachedBySku.toEntity());
        }
        // Si no se encuentra por SKU, intentar por barcode
        final cachedByBarcode = await localDataSource.getCachedProductByBarcode(code);
        if (cachedByBarcode != null) {
          print('✅ Producto obtenido desde cache local por barcode');
          return Right(cachedByBarcode.toEntity());
        }
        return Left(CacheFailure('No hay producto con código $code en cache local'));
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(
    String searchTerm, {
    int limit = 10,
  }) async {
    try {
      final response = await remoteDataSource.searchProducts(
        searchTerm,
        limit,
      );

      // Convertir a entidades del dominio
      final products = response.map((model) => model.toEntity()).toList();
      return Right(products);
    } catch (e) {
      print('⚠️ Error del servidor en searchProducts: $e - intentando cache local...');
      try {
        final cached = await localDataSource.searchCachedProducts(searchTerm);
        final limitedResults = limit != null && limit > 0 ? cached.take(limit).toList() : cached;
        if (limitedResults.isNotEmpty) {
          print('✅ ${limitedResults.length} productos encontrados en cache local');
          return Right(limitedResults.map((model) => model.toEntity()).toList());
        }
        return const Right([]);
      } catch (cacheError) {
        return Left(CacheFailure('Error al buscar en cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getLowStockProducts() async {
    try {
      final response = await remoteDataSource.getLowStockProducts();
      final products = response.map((model) => model.toEntity()).toList();
      return Right(products);
    } catch (e) {
      print('⚠️ Error del servidor en getLowStockProducts: $e - intentando cache local...');
      try {
        final cached = await localDataSource.getCachedProducts();
        final lowStockProducts = cached.where((p) => p.stock <= p.minStock).toList();
        if (lowStockProducts.isNotEmpty) {
          print('✅ ${lowStockProducts.length} productos con stock bajo encontrados en cache');
          return Right(lowStockProducts.map((model) => model.toEntity()).toList());
        }
        return const Right([]);
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getOutOfStockProducts() async {
    try {
      final response = await remoteDataSource.getOutOfStockProducts();
      final products = response.map((model) => model.toEntity()).toList();
      return Right(products);
    } catch (e) {
      print('⚠️ Error del servidor en getOutOfStockProducts: $e - intentando cache local...');
      try {
        final cached = await localDataSource.getCachedProducts();
        final outOfStockProducts = cached.where((p) => p.stock <= 0).toList();
        if (outOfStockProducts.isNotEmpty) {
          print('✅ ${outOfStockProducts.length} productos sin stock encontrados en cache');
          return Right(outOfStockProducts.map((model) => model.toEntity()).toList());
        }
        return const Right([]);
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  ) async {
    try {
      final response = await remoteDataSource.getProductsByCategory(
        categoryId,
      );
      final products = response.map((model) => model.toEntity()).toList();
      return Right(products);
    } catch (e) {
      print('⚠️ Error del servidor en getProductsByCategory: $e - intentando cache local...');
      try {
        final cached = await localDataSource.getCachedProducts();
        final categoryProducts = cached.where((p) => p.categoryId == categoryId).toList();
        if (categoryProducts.isNotEmpty) {
          print('✅ ${categoryProducts.length} productos de categoría encontrados en cache');
          return Right(categoryProducts.map((model) => model.toEntity()).toList());
        }
        return const Right([]);
      } catch (cacheError) {
        return Left(CacheFailure('Error al obtener del cache: $cacheError'));
      }
    }
  }

  @override
  Future<Either<Failure, ProductStats>> getProductStats() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getProductStats();

        // Cache las estadísticas (ahora debería funcionar sin conflicto)
        try {
          await localDataSource.cacheProductStats(response);
        } catch (e) {
          print('⚠️ Error al cachear estadísticas: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException en stats: ${e.message} - Usando cache...');
        return _getProductStatsFromCache();
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en stats: ${e.message} - Usando cache...');
        return _getProductStatsFromCache();
      } catch (e) {
        print('❌ Error inesperado en stats: $e - Usando cache...');
        return _getProductStatsFromCache();
      }
    } else {
      // Sin conexión, intentar desde cache
      return _getProductStatsFromCache();
    }
  }

  @override
  Future<Either<Failure, double>> getInventoryValue() async {
    try {
      final response = await remoteDataSource.getInventoryValue();
      return Right(response);
    } catch (e) {
      print('⚠️ Error del servidor en getInventoryValue: $e - calculando desde cache local...');
      try {
        final cached = await localDataSource.getCachedProducts();
        double totalValue = 0.0;
        for (final product in cached) {
          if (product.prices != null && product.prices!.isNotEmpty) {
            final price = product.prices!.first.finalAmount;
            totalValue += price * product.stock;
          }
        }
        print('✅ Valor de inventario calculado desde cache: \$$totalValue');
        return Right(totalValue);
      } catch (cacheError) {
        return Left(CacheFailure('Error al calcular del cache: $cacheError'));
      }
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
    // Campos de facturación electrónica
    TaxCategory? taxCategory,
    double? taxRate,
    bool? isTaxable,
    String? taxDescription,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool? hasRetention,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Crear request model
        final request = CreateProductRequestModel.fromParams(
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: prices,
          // Campos de facturación electrónica
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );

        // Crear producto en el servidor
        final response = await remoteDataSource.createProduct(request);

        // Actualizar cache después de crear
        try {
          await localDataSource.cacheProduct(response);
          // Note: No need to invalidate cache after caching a single product
          // await _invalidateListCache(); // This would delete the product we just cached!
        } catch (e) {
          print('⚠️ Error al actualizar cache después de crear: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException al crear producto: ${e.message} - Creando offline...');
        return _createProductOffline(
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: prices,
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al crear producto: ${e.message} - Creando offline...');
        return _createProductOffline(
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: prices,
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );
      } catch (e, stackTrace) {
        print('❌ Error inesperado al crear producto: $e');
        print('📚 StackTrace: $stackTrace');
        print('🔄 Intentando crear offline como fallback...');
        return _createProductOffline(
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: prices,
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );
      }
    } else {
      // Sin conexión, crear producto offline para sincronizar después
      return _createProductOffline(
        name: name,
        description: description,
        sku: sku,
        barcode: barcode,
        type: type,
        status: status,
        stock: stock,
        minStock: minStock,
        unit: unit,
        weight: weight,
        length: length,
        width: width,
        height: height,
        images: images,
        metadata: metadata,
        categoryId: categoryId,
        prices: prices,
        taxCategory: taxCategory,
        taxRate: taxRate,
        isTaxable: isTaxable,
        taxDescription: taxDescription,
        retentionCategory: retentionCategory,
        retentionRate: retentionRate,
        hasRetention: hasRetention,
      );
    }
  }

  Future<Either<Failure, Product>> _createProductOffline({
    required String name,
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
      print('📱 ProductRepository: Creating product offline: $name');
      try {
        // Generar un ID temporal único para el producto offline
        final now = DateTime.now();
        final tempId = 'product_offline_${now.millisecondsSinceEpoch}_${name.hashCode}';
        
        // Crear producto con ID temporal
        final tempProduct = Product(
          id: tempId,
          name: name,
          description: description ?? '',
          sku: sku ?? '',
          barcode: barcode,
          type: type ?? ProductType.product,
          status: status ?? ProductStatus.active,
          stock: stock ?? 0.0,
          minStock: minStock ?? 0.0,
          unit: unit ?? 'pcs',
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images ?? [],
          metadata: metadata ?? {},
          categoryId: categoryId,
          createdById: '', // Will be set from authentication when syncing
          category: null, // Will be resolved when syncing
          prices: prices?.map((priceParam) => ProductPrice(
            id: 'price_${tempId}_${priceParam.type.name}',
            productId: tempId,
            type: priceParam.type,
            amount: priceParam.amount,
            currency: priceParam.currency ?? 'COP', // Default currency
            status: PriceStatus.active, // Default to active for new products
            discountPercentage: priceParam.discountPercentage ?? 0.0,
            minQuantity: priceParam.minQuantity ?? 1.0,
            createdAt: now,
            updatedAt: now,
          )).toList(),
          createdBy: null, // Will be set from authentication when syncing
          createdAt: now,
          updatedAt: now,
        );

        // Cache el producto localmente
        await localDataSource.cacheProductForSync(tempProduct);

        // Agregar a la cola de sincronización
        try {
          final syncService = Get.find<SyncService>();
          await syncService.addOperationForCurrentUser(
            entityType: 'Product',
            entityId: tempId,
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
              'unit': unit,
              'weight': weight,
              'length': length,
              'width': width,
              'height': height,
              'images': images,
              'metadata': metadata,
              'categoryId': categoryId,
              'prices': prices?.map((p) => {
                'type': p.type.name,
                'name': p.name,
                'amount': p.amount,
                'currency': p.currency,
                'discountPercentage': p.discountPercentage,
                'discountAmount': p.discountAmount,
                'minQuantity': p.minQuantity,
                'notes': p.notes,
              }).toList(),
              'taxCategory': taxCategory?.name,
              'taxRate': taxRate,
              'isTaxable': isTaxable,
              'taxDescription': taxDescription,
              'retentionCategory': retentionCategory?.name,
              'retentionRate': retentionRate,
              'hasRetention': hasRetention,
            },
            priority: 1, // Alta prioridad para creación
          );
          print('📤 ProductRepository: Operación agregada a cola de sincronización');
        } catch (e) {
          print('⚠️ ProductRepository: Error agregando a cola de sync: $e');
        }

        print('✅ ProductRepository: Product created offline successfully');
        return Right(tempProduct);
      } catch (e) {
        print('❌ ProductRepository: Error creating product offline: $e');
        return Left(CacheFailure('Error al crear producto offline: $e'));
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
    // Campos de facturación electrónica
    TaxCategory? taxCategory,
    double? taxRate,
    bool? isTaxable,
    String? taxDescription,
    RetentionCategory? retentionCategory,
    double? retentionRate,
    bool? hasRetention,
  }) async {
    // ✅ IMPORTANTE: Si es producto offline, actualizar solo en local, NO enviar al servidor
    if (id.startsWith('product_offline_')) {
      print('📱 ProductRepository: Producto offline detectado - actualizando solo en local');
      return _updateProductOffline(
        id: id,
        name: name,
        description: description,
        sku: sku,
        barcode: barcode,
        type: type,
        status: status,
        stock: stock,
        minStock: minStock,
        unit: unit,
        weight: weight,
        length: length,
        width: width,
        height: height,
        images: images,
        metadata: metadata,
        categoryId: categoryId,
        prices: prices,
        taxCategory: taxCategory,
        taxRate: taxRate,
        isTaxable: isTaxable,
        taxDescription: taxDescription,
        retentionCategory: retentionCategory,
        retentionRate: retentionRate,
        hasRetention: hasRetention,
      );
    }

    if (await networkInfo.isConnected) {
      try {
        // Preparar precios para actualización si existen
        List<UpdateProductPriceRequestModel>? updatePrices;
        if (prices != null && prices.isNotEmpty) {
          updatePrices = prices.map((price) {
            // Extraer ID de las notas si existe (formato: "ID:uuid")
            String? priceId;
            String? cleanNotes = price.notes;
            
            if (price.notes != null && price.notes!.startsWith('ID:')) {
              priceId = price.notes!.substring(3); // Remover "ID:"
              cleanNotes = null; // Limpiar las notas
            }
            
            return UpdateProductPriceRequestModel(
              id: priceId, // ID extraído o null para crear nuevo
              type: price.type.name,
              name: price.name,
              amount: price.amount,
              currency: price.currency,
              discountPercentage: price.discountPercentage,
              discountAmount: price.discountAmount,
              minQuantity: price.minQuantity,
              notes: cleanNotes,
            );
          }).toList();
          
          print('🏷️ ProductRepository: Construidos ${updatePrices.length} precios para actualización');
          for (final price in updatePrices) {
            print('   - Tipo: ${price.type}, ID: ${price.id ?? "NUEVO"}, Cantidad: ${price.amount}');
          }
        }

        // Crear request model con precios procesados
        final request = UpdateProductRequestModel.fromParams(
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: updatePrices, // Incluir precios procesados
          // Campos de facturación electrónica
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );

        // Validar que hay cambios para actualizar
        if (!request.hasUpdates) {
          return Left(ValidationFailure(['No hay cambios para actualizar']));
        }

        // Actualizar en el servidor
        final response = await remoteDataSource.updateProduct(id, request);

        // Actualizar cache
        try {
          await localDataSource.cacheProduct(response);
          // await _invalidateListCache(); // This would delete the product we just cached!
        } catch (e) {
          print('⚠️ Error al actualizar cache después de modificar: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException al actualizar producto: ${e.message} - Actualizando offline...');
        return _updateProductOffline(
          id: id,
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: prices,
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al actualizar producto: ${e.message} - Actualizando offline...');
        return _updateProductOffline(
          id: id,
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: prices,
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );
      } catch (e, stackTrace) {
        print('❌ Error inesperado al actualizar producto: $e');
        print('📚 StackTrace: $stackTrace');
        print('🔄 Intentando actualizar offline como fallback...');
        return _updateProductOffline(
          id: id,
          name: name,
          description: description,
          sku: sku,
          barcode: barcode,
          type: type,
          status: status,
          stock: stock,
          minStock: minStock,
          unit: unit,
          weight: weight,
          length: length,
          width: width,
          height: height,
          images: images,
          metadata: metadata,
          categoryId: categoryId,
          prices: prices,
          taxCategory: taxCategory,
          taxRate: taxRate,
          isTaxable: isTaxable,
          taxDescription: taxDescription,
          retentionCategory: retentionCategory,
          retentionRate: retentionRate,
          hasRetention: hasRetention,
        );
      }
    } else {
      // Sin conexión, actualizar producto offline para sincronizar después
      return _updateProductOffline(
        id: id,
        name: name,
        description: description,
        sku: sku,
        barcode: barcode,
        type: type,
        status: status,
        stock: stock,
        minStock: minStock,
        unit: unit,
        weight: weight,
        length: length,
        width: width,
        height: height,
        images: images,
        metadata: metadata,
        categoryId: categoryId,
        prices: prices,
        taxCategory: taxCategory,
        taxRate: taxRate,
        isTaxable: isTaxable,
        taxDescription: taxDescription,
        retentionCategory: retentionCategory,
        retentionRate: retentionRate,
        hasRetention: hasRetention,
      );
    }
  }

  Future<Either<Failure, Product>> _updateProductOffline({
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
      print('📱 ProductRepository: Updating product offline: $id');

      // ✅ DETECTAR SI ES PRODUCTO OFFLINE (creado offline) O SERVER (del servidor pero editando offline)
      final isOfflineProduct = id.startsWith('product_offline_');

      if (isOfflineProduct) {
        // ============ PRODUCTO OFFLINE: Actualizar en ISAR ============
        print('🗄️ ProductRepository: Producto offline detectado - actualizando en ISAR');
        try {
          final isar = _isar;

          // Buscar producto en ISAR por serverId
          final isarProduct = await isar.isarProducts
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarProduct == null) {
            print('❌ ProductRepository: Producto offline no encontrado en ISAR: $id');
            return Left(CacheFailure('Producto no encontrado en ISAR: $id'));
          }

          // Actualizar campos en ISAR
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

          // Actualizar precios si se proporcionaron
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

          // Verificar si el producto ya estaba sincronizado ANTES de marcarlo como no sincronizado
          final wasAlreadySynced = isarProduct.isSynced;

          // Marcar como no sincronizado
          isarProduct.markAsUnsynced();

          // Guardar en ISAR
          await isar.writeTxn(() async {
            await isar.isarProducts.put(isarProduct);
          });

          // ✅ LÓGICA DE SINCRONIZACIÓN:
          // - Si el producto YA estaba sincronizado: agregar operación UPDATE (producto existe en servidor)
          // - Si el producto NO estaba sincronizado: NO agregar operación (ya tiene CREATE pendiente)

          if (wasAlreadySynced) {
            // Producto ya existe en el servidor → agregar UPDATE
            try {
              final syncService = Get.find<SyncService>();
              await syncService.addOperationForCurrentUser(
                entityType: 'Product',
                entityId: id,
                operationType: SyncOperationType.update,
                data: {
                  'name': isarProduct.name,
                  'description': isarProduct.description,
                  'sku': isarProduct.sku,
                  'barcode': isarProduct.barcode,
                  'type': isarProduct.type.name.replaceAll('IsarProductType.', ''),
                  'status': isarProduct.status.name.replaceAll('IsarProductStatus.', ''),
                  'stock': isarProduct.stock,
                  'minStock': isarProduct.minStock,
                  'unit': isarProduct.unit,
                  'weight': isarProduct.weight,
                  'length': isarProduct.length,
                  'width': isarProduct.width,
                  'height': isarProduct.height,
                  'images': isarProduct.images,
                  'metadata': isarProduct.metadataJson != null ? jsonDecode(isarProduct.metadataJson!) : null,
                  'categoryId': isarProduct.categoryId,
                  'prices': isarProduct.prices.map((p) => {
                    'id': p.serverId,
                    'type': p.type.name.replaceAll('IsarPriceType.', ''),
                    'name': p.name,
                    'amount': p.amount,
                    'currency': p.currency,
                    'discountPercentage': p.discountPercentage,
                    'discountAmount': p.discountAmount,
                    'minQuantity': p.minQuantity,
                    'notes': p.notes,
                  }).toList(),
                },
                priority: 1,
              );
              print('📤 ProductRepository: Producto ya sincronizado - agregada operación UPDATE a cola');
            } catch (e) {
              print('⚠️ ProductRepository: Error agregando UPDATE a cola: $e');
            }
          } else {
            // Producto aún no existe en el servidor → NO agregar UPDATE
            print('✅ ProductRepository: Producto offline actualizado en ISAR');
            print('   📝 Producto aún no sincronizado - NO se agrega UPDATE');
            print('   La operación CREATE pendiente debe actualizarse para usar datos de ISAR');
          }

          print('✅ ProductRepository: Producto offline actualizado en ISAR exitosamente');
          return Right(isarProduct.toEntity());

        } catch (e) {
          print('❌ ProductRepository: Error actualizando producto offline en ISAR: $e');
          return Left(CacheFailure('Error al actualizar producto offline en ISAR: $e'));
        }

      } else {
        // ============ PRODUCTO SERVER: Actualizar en ISAR Y SecureStorage ============
        print('💾 ProductRepository: Producto del servidor - actualizando en ISAR y cache');
        try {
          // ✅ PASO 1: Actualizar en ISAR primero
          final isar = _isar;
          final isarProduct = await isar.isarProducts
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarProduct == null) {
            return Left(CacheFailure('Producto no encontrado en ISAR: $id'));
          }

          // Actualizar campos en ISAR
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

          // Actualizar precios si se proporcionaron
          if (prices != null) {
            final now = DateTime.now();
            final isarPrices = prices.map((p) {
              // Buscar precio existente por tipo
              IsarProductPrice? existingPrice;
              try {
                existingPrice = isarProduct.prices.firstWhere(
                  (price) => price.type.name.replaceAll('IsarPriceType.', '') == p.type.name,
                );
              } catch (e) {
                existingPrice = null;
              }

              final priceId = existingPrice?.serverId ??
                  'price_${now.millisecondsSinceEpoch}_${p.type.name.hashCode}';

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

          // Marcar como no sincronizado
          isarProduct.markAsUnsynced();

          // Guardar en ISAR
          await isar.writeTxn(() async {
            await isar.isarProducts.put(isarProduct);
          });
          print('✅ ProductRepository: Producto actualizado en ISAR');

          // ✅ PASO 2: Obtener el producto actual del cache para SecureStorage
          final cachedProductModel = await localDataSource.getCachedProduct(id);
          if (cachedProductModel == null) {
            return Left(CacheFailure('Producto no encontrado en cache: $id'));
          }
          final cachedProduct = cachedProductModel.toEntity();

          // Crear producto actualizado
          final updatedProduct = Product(
            id: id,
            name: name ?? cachedProduct.name,
            description: description ?? cachedProduct.description,
            sku: sku ?? cachedProduct.sku,
            barcode: barcode ?? cachedProduct.barcode,
            type: type ?? cachedProduct.type,
            status: status ?? cachedProduct.status,
            stock: stock ?? cachedProduct.stock,
            minStock: minStock ?? cachedProduct.minStock,
            unit: unit ?? cachedProduct.unit,
            weight: weight ?? cachedProduct.weight,
            length: length ?? cachedProduct.length,
            width: width ?? cachedProduct.width,
            height: height ?? cachedProduct.height,
            images: images ?? cachedProduct.images,
            metadata: metadata ?? cachedProduct.metadata,
            categoryId: categoryId ?? cachedProduct.categoryId,
            createdById: cachedProduct.createdById,
            category: cachedProduct.category,
            prices: prices != null ? prices.map((priceParam) {
              // Buscar precio existente por tipo
              ProductPrice? existingPrice;
              final existingPrices = cachedProduct.prices ?? [];
              if (existingPrices.isNotEmpty) {
                try {
                  existingPrice = existingPrices.firstWhere(
                    (p) => p.type == priceParam.type,
                  );
                } catch (e) {
                  // No existe precio de este tipo
                  existingPrice = null;
                }
              }

              return ProductPrice(
                id: existingPrice?.id ?? 'price_${id}_${priceParam.type.name}',
                productId: id,
                type: priceParam.type,
                amount: priceParam.amount,
                currency: priceParam.currency ?? existingPrice?.currency ?? 'COP',
                status: PriceStatus.active,
                discountPercentage: priceParam.discountPercentage ?? 0.0,
                minQuantity: priceParam.minQuantity ?? 1.0,
                createdAt: existingPrice?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }).toList() : cachedProduct.prices,
            createdBy: cachedProduct.createdBy,
            createdAt: cachedProduct.createdAt,
            updatedAt: DateTime.now(),
          );

          // NOTA: En modo offline, NO actualizamos SecureStorage para evitar sobrescribir
          // el flag isSynced. Solo actualizamos ISAR (que ya se hizo arriba en línea 1265).
          // El SecureStorage se sincronizará cuando volvamos online.

          // await localDataSource.cacheProduct(
          //   ProductModel.fromEntity(updatedProduct),
          // );

          // Agregar a la cola de sincronización
          try {
            final syncService = Get.find<SyncService>();
            await syncService.addOperationForCurrentUser(
              entityType: 'Product',
              entityId: id,
              operationType: SyncOperationType.update,
              data: {
                'name': name,
                'description': description,
                'sku': sku,
                'barcode': barcode,
                'type': type?.name,
                'status': status?.name,
                'stock': stock,
                'minStock': minStock,
                'unit': unit,
                'weight': weight,
                'length': length,
                'width': width,
                'height': height,
                'images': images,
                'metadata': metadata,
                'categoryId': categoryId,
                'prices': prices?.map((p) => {
                  'type': p.type.name,
                  'name': p.name,
                  'amount': p.amount,
                  'currency': p.currency,
                  'discountPercentage': p.discountPercentage,
                  'discountAmount': p.discountAmount,
                  'minQuantity': p.minQuantity,
                  'notes': p.notes,
                }).toList(),
                'taxCategory': taxCategory?.name,
                'taxRate': taxRate,
                'isTaxable': isTaxable,
                'taxDescription': taxDescription,
                'retentionCategory': retentionCategory?.name,
                'retentionRate': retentionRate,
                'hasRetention': hasRetention,
              },
              priority: 1,
            );
            print('📤 ProductRepository: Actualización agregada a cola de sincronización');
          } catch (e) {
            print('⚠️ ProductRepository: Error agregando actualización a cola: $e');
          }

          print('✅ ProductRepository: Producto del servidor actualizado en cache exitosamente');
          return Right(updatedProduct);
        } catch (e) {
          print('❌ ProductRepository: Error actualizando producto del servidor en cache: $e');
          return Left(CacheFailure('Error al actualizar producto del servidor en cache: $e'));
        }
      }
  }

  @override
  Future<Either<Failure, Product>> updateProductStatus({
    required String id,
    required ProductStatus status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateProductStatus(
          id,
          status.name,
        );

        // Actualizar cache
        try {
          await localDataSource.cacheProduct(response);
        } catch (e) {
          print('⚠️ Error al actualizar cache después de cambiar estado: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al actualizar estado: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Product>> updateProductStock({
    required String id,
    required double quantity,
    String operation = 'subtract',
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateProductStock(
          id,
          quantity,
          operation,
        );

        // Actualizar cache
        try {
          await localDataSource.cacheProduct(response);
        } catch (e) {
          print('⚠️ Error al actualizar cache después de cambiar stock: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al actualizar stock: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteProduct(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isar = _isar;
          final isarProduct = await isar.isarProducts
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarProduct != null) {
            isarProduct.softDelete();
            await isar.writeTxn(() async {
              await isar.isarProducts.put(isarProduct);
            });
            print('✅ Product marcado como eliminado en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        // Remover del cache
        try {
          await localDataSource.removeCachedProduct(id);
          // await _invalidateListCache(); // Not needed, already removed the specific product
        } catch (e) {
          print('⚠️ Error al actualizar cache después de eliminar: $e');
        }

        return const Right(unit);
      } on ServerException catch (e) {
        print('⚠️ ServerException al eliminar producto: ${e.message} - Eliminando offline...');
        return _deleteProductOffline(id);
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al eliminar producto: ${e.message} - Eliminando offline...');
        return _deleteProductOffline(id);
      } catch (e, stackTrace) {
        print('❌ Error inesperado al eliminar producto: $e');
        print('📚 StackTrace: $stackTrace');
        print('🔄 Intentando eliminar offline como fallback...');
        return _deleteProductOffline(id);
      }
    } else {
      // Sin conexión, marcar para eliminación offline y sincronizar después
      return _deleteProductOffline(id);
    }
  }

  Future<Either<Failure, Unit>> _deleteProductOffline(String id) async {
    print('📱 ProductRepository: Deleting product offline: $id');
    try {
      // Soft delete en ISAR
      try {
        final isar = _isar;
        final isarProduct = await isar.isarProducts
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarProduct != null) {
          isarProduct.softDelete();
          await isar.writeTxn(() async {
            await isar.isarProducts.put(isarProduct);
          });
          print('✅ Product marcado como eliminado en ISAR: $id');
        }
      } catch (e) {
        print('⚠️ Error actualizando ISAR durante delete offline: $e');
      }

      // Marcar como eliminado en cache local (soft delete)
      await localDataSource.removeCachedProduct(id);

      // Agregar a la cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Product',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        print('📤 ProductRepository: Eliminación agregada a cola de sincronización');
      } catch (e) {
        print('⚠️ ProductRepository: Error agregando eliminación a cola: $e');
      }

      print('✅ ProductRepository: Product deleted offline successfully');
      return const Right(unit);
    } catch (e) {
      print('❌ ProductRepository: Error deleting product offline: $e');
      return Left(CacheFailure('Error al eliminar producto offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Product>> restoreProduct(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.restoreProduct(id);

        // Cache el producto restaurado
        try {
          await localDataSource.cacheProduct(response);
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de restaurar: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al restaurar producto: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // ==================== STOCK OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> validateStockForSale({
    required String productId,
    required double quantity,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isValid = await remoteDataSource.validateStockForSale(
          productId,
          quantity,
        );
        return Right(isValid);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al validar stock: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Unit>> reduceStockForSale({
    required String productId,
    required double quantity,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.reduceStockForSale(productId, quantity);

        // Invalidar cache para reflejar el nuevo stock
        try {
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al invalidar cache después de reducir stock: $e');
        }

        return const Right(unit);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al reducir stock: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // ==================== PRICE OPERATIONS ====================

  @override
  Future<Either<Failure, Product>> getProductWithPrice({
    required String productId,
    PriceType priceType = PriceType.price1,
  }) async {
    // Reutilizar el método getProductById ya que incluye precios
    return getProductById(productId);
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Product>>> getCachedProducts() async {
    try {
      final products = await localDataSource.getCachedProducts();
      return Right(products.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado al obtener cache: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearProductCache() async {
    try {
      await localDataSource.clearProductCache();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado al limpiar cache: $e'));
    }
  }

  // ==================== VALIDATION OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> existsByName(String name, {String? excludeId}) async {
    try {
      // Primero verificar en cache local
      final existsLocally = await localDataSource.existsByName(name, excludeId: excludeId);
      if (existsLocally) {
        return const Right(true);
      }

      // Si hay conexión, verificar también en el servidor
      if (await networkInfo.isConnected) {
        try {
          final existsRemotely = await remoteDataSource.existsByName(name, excludeId: excludeId);
          return Right(existsRemotely);
        } catch (e) {
          // Si falla la verificación remota, confiar en la local
          return const Right(false);
        }
      }

      return const Right(false);
    } catch (e) {
      return Left(UnknownFailure('Error al verificar nombre: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> existsBySku(String sku, {String? excludeId}) async {
    try {
      // Primero verificar en cache local
      final existsLocally = await localDataSource.existsBySku(sku, excludeId: excludeId);
      if (existsLocally) {
        return const Right(true);
      }

      // Si hay conexión, verificar también en el servidor
      if (await networkInfo.isConnected) {
        try {
          final existsRemotely = await remoteDataSource.existsBySku(sku, excludeId: excludeId);
          return Right(existsRemotely);
        } catch (e) {
          // Si falla la verificación remota, confiar en la local
          return const Right(false);
        }
      }

      return const Right(false);
    } catch (e) {
      return Left(UnknownFailure('Error al verificar SKU: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> existsByBarcode(String barcode, {String? excludeId}) async {
    try {
      // Buscar en cache local usando método existente
      final cachedProduct = await localDataSource.getCachedProductByBarcode(barcode);
      if (cachedProduct != null && cachedProduct.id != excludeId) {
        return const Right(true);
      }

      // Verificar en productos no sincronizados
      final unsyncedProducts = await localDataSource.getUnsyncedProducts();
      for (final product in unsyncedProducts) {
        if (product.barcode == barcode && product.id != excludeId) {
          return const Right(true);
        }
      }

      // Si hay conexión, verificar también en el servidor
      if (await networkInfo.isConnected) {
        try {
          final existsRemotely = await remoteDataSource.existsByBarcode(barcode, excludeId: excludeId);
          return Right(existsRemotely);
        } catch (e) {
          // Si falla la verificación remota, confiar en la local
          return const Right(false);
        }
      }

      return const Right(false);
    } catch (e) {
      return Left(UnknownFailure('Error al verificar código de barras: $e'));
    }
  }

  // ==================== ✅ SYNC OPERATIONS ====================

  /// Sincronizar productos creados offline con el servidor
  Future<Either<Failure, List<Product>>> syncOfflineProducts() async {
    if (!await networkInfo.isConnected) {
      return const Left(ConnectionFailure.noInternet);
    }

    try {
      print('🔄 ProductRepository: Starting offline products sync...');
      
      // Obtener productos no sincronizados
      final unsyncedProducts = await localDataSource.getUnsyncedProducts();
      
      if (unsyncedProducts.isEmpty) {
        print('✅ ProductRepository: No products to sync');
        return const Right([]);
      }

      print('📤 ProductRepository: Syncing ${unsyncedProducts.length} offline products...');
      final syncedProducts = <Product>[];
      final failures = <String>[];

      for (final product in unsyncedProducts) {
        try {
          // Crear request model para el servidor
          final request = CreateProductRequestModel.fromParams(
            name: product.name,
            description: product.description?.isNotEmpty == true ? product.description : null,
            sku: product.sku,
            barcode: product.barcode,
            type: product.type,
            status: product.status,
            stock: product.stock,
            minStock: product.minStock,
            unit: product.unit,
            weight: product.weight,
            length: product.length,
            width: product.width,
            height: product.height,
            images: product.images?.isNotEmpty == true ? product.images : null,
            metadata: product.metadata?.isNotEmpty == true ? product.metadata : null,
            categoryId: product.categoryId,
            prices: product.prices?.map((price) => CreateProductPriceParams(
              type: price.type,
              amount: price.amount,
              currency: price.currency,
              discountPercentage: price.discountPercentage,
              minQuantity: price.minQuantity,
            )).toList() ?? [],
          );

          // Enviar al servidor
          final serverProduct = await remoteDataSource.createProduct(request);
          
          // Marcar como sincronizado localmente
          await localDataSource.markProductAsSynced(product.id, serverProduct.id);
          
          // Cache el producto del servidor
          await localDataSource.cacheProduct(serverProduct);
          
          syncedProducts.add(serverProduct.toEntity());
          print('✅ ProductRepository: Synced product: ${product.name} -> ${serverProduct.id}');
          
        } catch (e) {
          print('❌ ProductRepository: Failed to sync product ${product.name}: $e');
          failures.add('${product.name}: $e');
        }
      }

      print('🎯 ProductRepository: Sync completed. Success: ${syncedProducts.length}, Failures: ${failures.length}');
      
      if (failures.isNotEmpty) {
        print('⚠️ ProductRepository: Sync failures:\n${failures.join('\n')}');
      }

      return Right(syncedProducts);
    } catch (e) {
      print('💥 ProductRepository: Error during offline products sync: $e');
      return Left(UnknownFailure('Error al sincronizar productos offline: $e'));
    }
  }

  /// Obtener productos que faltan por sincronizar
  Future<Either<Failure, List<Product>>> getUnsyncedProducts() async {
    try {
      final unsyncedProducts = await localDataSource.getUnsyncedProducts();
      return Right(unsyncedProducts);
    } catch (e) {
      return Left(CacheFailure('Error al obtener productos no sincronizados: $e'));
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Determinar si se debe cachear el resultado
  bool _shouldCacheResult(
    int page,
    String? search,
    ProductStatus? status,
    ProductType? type,
    String? categoryId,
  ) {
    return page == 1 &&
        search == null &&
        status == null &&
        type == null &&
        categoryId == null;
  }

  /// Invalidar cache de listados para reflejar cambios
  Future<void> _invalidateListCache() async {
    try {
      await localDataSource.clearProductCache();
    } catch (e) {
      print('⚠️ Error al invalidar cache de listados: $e');
    }
  }

  /// Obtener productos desde cache local
  Future<Either<Failure, PaginatedResult<Product>>>
  _getProductsFromCache() async {
    print('💾 _getProductsFromCache(): Intentando obtener productos desde caché local...');
    try {
      final products = await localDataSource.getCachedProducts();
      print('💾 Cache local retornó ${products.length} productos');

      // Crear meta de paginación básica para cache
      final meta = PaginationMeta(
        page: 1,
        limit: products.length,
        totalItems: products.length,
        totalPages: 1,
        hasNextPage: false,
        hasPreviousPage: false,
      );

      final result = PaginatedResult<Product>(
        data: products.map((model) => model.toEntity()).toList(),
        meta: meta,
      );

      print('✅ _getProductsFromCache(): Retornando ${result.data.length} productos desde caché');
      return Right(result);
    } on CacheException catch (e) {
      print('❌ _getProductsFromCache(): CacheException: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e, stackTrace) {
      print('❌ _getProductsFromCache(): Error inesperado: $e');
      print('📚 StackTrace: $stackTrace');
      return Left(UnknownFailure('Error al obtener productos desde cache: $e'));
    }
  }

  /// Obtener producto individual desde cache local
  Future<Either<Failure, Product>> _getProductFromCache(String id) async {
    try {
      final product = await localDataSource.getCachedProduct(id);
      if (product != null) {
        return Right(product.toEntity());
      } else {
        return const Left(CacheFailure('Datos no encontrados en cache'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener producto desde cache: $e'));
    }
  }

  /// Obtener estadísticas desde cache
  Future<Either<Failure, ProductStats>> _getProductStatsFromCache() async {
    try {
      // Primero intentar obtener estadísticas cacheadas
      final cachedStats = await localDataSource.getCachedProductStats();
      if (cachedStats != null) {
        print('📊 ISAR: Estadísticas encontradas en cache');
        return Right(cachedStats.toEntity());
      }
      
      print('📊 ISAR: No hay estadísticas en cache, calculando desde productos locales...');
      
      // Si no hay estadísticas cacheadas, calcularlas desde los productos locales
      try {
        final products = await localDataSource.getCachedProducts();
        
        // Calcular estadísticas desde los productos
        int total = products.length;
        int active = 0;
        int inactive = 0;
        int outOfStock = 0;
        int lowStock = 0;
        double totalValue = 0.0;
        double totalPrices = 0.0;
        int productsWithPrices = 0;
        
        for (final product in products) {
          // Contar estados
          if (product.status == 'active') {
            active++;
          } else {
            inactive++;
          }
          
          // Contar stock
          if (product.stock <= 0) {
            outOfStock++;
          } else if (product.stock <= product.minStock) {
            lowStock++;
          }
          
          // Calcular valores (usar primer precio si existe)
          if (product.prices != null && product.prices!.isNotEmpty) {
            final firstPrice = product.prices!.first;
            final price = firstPrice.finalAmount;
            totalValue += price * product.stock;
            totalPrices += price;
            productsWithPrices++;
          }
        }
        
        final activePercentage = total > 0 ? (active / total) * 100 : 0.0;
        final averagePrice = productsWithPrices > 0 ? totalPrices / productsWithPrices : 0.0;
        
        final calculatedStats = ProductStats(
          total: total,
          active: active,
          inactive: inactive,
          outOfStock: outOfStock,
          lowStock: lowStock,
          activePercentage: activePercentage,
          totalValue: totalValue,
          averagePrice: averagePrice,
        );
        
        print('✅ Estadísticas calculadas desde productos locales: $total productos');
        return Right(calculatedStats);
        
      } on CacheException {
        // Si no hay productos en cache, devolver estadísticas vacías
        print('📊 No hay productos en cache, devolviendo estadísticas vacías');
        return const Right(ProductStats(
          total: 0,
          active: 0,
          inactive: 0,
          outOfStock: 0,
          lowStock: 0,
          activePercentage: 0.0,
          totalValue: 0.0,
          averagePrice: 0.0,
        ));
      }
      
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Error al obtener estadísticas desde cache: $e'),
      );
    }
  }

  /// Mapear ServerException a Failure específico
  Failure _mapServerExceptionToFailure(ServerException exception) {
    if (exception.statusCode != null) {
      return ServerFailure.fromStatusCode(
        exception.statusCode!,
        exception.message,
      );
    } else {
      return ServerFailure(exception.message);
    }
  }

  // ==================== MAPPER HELPERS ====================

  /// Mapear ProductType a IsarProductType
  IsarProductType _mapProductType(ProductType type) {
    switch (type) {
      case ProductType.product:
        return IsarProductType.product;
      case ProductType.service:
        return IsarProductType.service;
    }
  }

  /// Mapear ProductStatus a IsarProductStatus
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

  /// Mapear PriceType a IsarPriceType
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
}
