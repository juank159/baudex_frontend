// lib/features/products/data/repositories/product_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';
import '../../domain/entities/product_stats.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';
import '../datasources/product_local_datasource.dart';
import '../models/product_query_model.dart';
import '../models/create_product_request_model.dart';
import '../models/update_product_request_model.dart';

/// Implementación del repositorio de productos
///
/// Esta clase maneja la lógica de datos combinando fuentes remotas y locales,
/// implementando estrategias de cache y manejo de errores robusto.
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

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
    // Verificar conexión a internet
    if (await networkInfo.isConnected) {
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
        final response = await remoteDataSource.getProducts(query);

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
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener productos: $e'),
        );
      }
    } else {
      // Sin conexión, intentar obtener desde cache
      return _getProductsFromCache();
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        // Intentar obtener desde el servidor
        final response = await remoteDataSource.getProductById(id);

        // Cache la producto individual para uso offline
        try {
          await localDataSource.cacheProduct(response);
        } catch (e) {
          print('⚠️ Error al cachear producto individual: $e');
        }

        return Right(response.toEntity());
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
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getProductBySku(sku);

        // Cache el producto encontrado
        try {
          await localDataSource.cacheProduct(response);
        } catch (e) {
          print('⚠️ Error al cachear producto por SKU: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener producto por SKU: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getProductByBarcode(barcode);

        // Cache el producto encontrado
        try {
          await localDataSource.cacheProduct(response);
        } catch (e) {
          print('⚠️ Error al cachear producto por código de barras: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al obtener producto por código de barras: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, Product>> findBySkuOrBarcode(String code) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.findBySkuOrBarcode(code);

        // Cache el producto encontrado
        try {
          await localDataSource.cacheProduct(response);
        } catch (e) {
          print('⚠️ Error al cachear producto encontrado: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al buscar producto: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(
    String searchTerm, {
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.searchProducts(
          searchTerm,
          limit,
        );

        // Convertir a entidades del dominio
        final products = response.map((model) => model.toEntity()).toList();
        return Right(products);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado en búsqueda: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getLowStockProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getLowStockProducts();
        final products = response.map((model) => model.toEntity()).toList();
        return Right(products);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al obtener productos con stock bajo: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getOutOfStockProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getOutOfStockProducts();
        final products = response.map((model) => model.toEntity()).toList();
        return Right(products);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener productos sin stock: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getProductsByCategory(
          categoryId,
        );
        final products = response.map((model) => model.toEntity()).toList();
        return Right(products);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al obtener productos por categoría: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener estadísticas: $e'),
        );
      }
    } else {
      // Sin conexión, intentar desde cache
      return _getProductStatsFromCache();
    }
  }

  @override
  Future<Either<Failure, double>> getInventoryValue() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getInventoryValue();
        return Right(response);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure(
            'Error inesperado al obtener valor del inventario: $e',
          ),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
        );

        // Crear producto en el servidor
        final response = await remoteDataSource.createProduct(request);

        // Actualizar cache después de crear
        try {
          await localDataSource.cacheProduct(response);
          // Invalidar cache general para reflejar los cambios en listados
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de crear: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al crear producto: $e'));
      }
    } else {
      // Sin conexión, crear producto offline para sincronizar después
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
          sku: sku,
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
            currency: priceParam.currency ?? 'USD', // Default currency
            status: PriceStatus.active, // Default to active for new products
            discountPercentage: priceParam.discountPercentage ?? 0.0,
            minQuantity: priceParam.minQuantity ?? 1.0,
            createdAt: now,
            updatedAt: now,
          )).toList() ?? [],
          createdBy: null, // Will be set from authentication when syncing
          createdAt: now,
          updatedAt: now,
        );

        // Cache el producto localmente
        await localDataSource.cacheProductForSync(tempProduct);
        
        print('✅ ProductRepository: Product created offline successfully');
        return Right(tempProduct);
      } catch (e) {
        print('❌ ProductRepository: Error creating product offline: $e');
        return Left(CacheFailure('Error al crear producto offline: $e'));
      }
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
  }) async {
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
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de modificar: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al actualizar producto: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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

        // Remover del cache
        try {
          await localDataSource.removeCachedProduct(id);
          await _invalidateListCache();
        } catch (e) {
          print('⚠️ Error al actualizar cache después de eliminar: $e');
        }

        return const Right(unit);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al eliminar producto: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
    try {
      final products = await localDataSource.getCachedProducts();

      // Crear meta de paginación básica para cache
      final meta = PaginationMeta(
        page: 1,
        limit: products.length,
        totalItems: products.length,
        totalPages: 1,
        hasNextPage: false,
        hasPreviousPage: false,
      );

      return Right(
        PaginatedResult<Product>(
          data: products.map((model) => model.toEntity()).toList(),
          meta: meta,
        ),
      );
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
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
}
