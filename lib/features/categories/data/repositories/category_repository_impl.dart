// lib/features/categories/data/repositories/category_repository_impl.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';
import '../models/category_query_model.dart';
import '../models/create_category_request_model.dart';
import '../models/update_category_request_model.dart';
import '../models/isar/isar_category.dart';

/// Implementación del repositorio de categorías
///
/// Esta clase maneja la lógica de datos combinando fuentes remotas y locales,
/// implementando estrategias de cache y manejo de errores robusto.
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final IIsarDatabase database;

  const CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.database,
  });

  // Helper getter for ISAR access
  Isar get isar => database.database as Isar;

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
    // Verificar conexión a internet
    if (await networkInfo.isConnected) {
      try {
        // Crear query model con todos los parámetros
        final query = CategoryQueryModel(
          page: page,
          limit: limit,
          search: search,
          status: status,
          parentId: parentId,
          onlyParents: onlyParents,
          includeChildren: includeChildren,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );

        // Realizar llamada remota
        final response = await remoteDataSource.getCategories(query);

        // ✅ Resetear estado de conectividad si el servidor respondió
        networkInfo.resetServerReachability();

        // Cache solo resultados de la primera página sin filtros específicos
        // para tener datos base disponibles offline
        if (_shouldCacheResult(page, search, status, parentId)) {
          try {
            await localDataSource.cacheCategories(response.data);
          } catch (e) {
            // Log del error pero no fallar la operación principal
            print('⚠️ Error al cachear categorías: $e');
          }
        }

        // Convertir respuesta a entidades del dominio
        final paginatedResult = response.toPaginatedResult();

        return Right(
          PaginatedResult<Category>(
            data:
                paginatedResult.data.map((model) => model.toEntity()).toList(),
            meta: paginatedResult.meta,
          ),
        );
      } on ServerException catch (e) {
        print('⚠️ ServerException en categorías: ${e.message} - Usando cache...');
        // ✅ Marcar servidor como no alcanzable si es error de conexión/timeout
        if (e.message.contains('timeout') || e.message.contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getCategoriesFromCache(
          page: page,
          limit: limit,
          search: search,
          status: status,
          parentId: parentId,
          onlyParents: onlyParents,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en categorías: ${e.message} - Usando cache...');
        // ✅ Marcar servidor como no alcanzable para evitar timeouts repetidos
        networkInfo.markServerUnreachable();
        return _getCategoriesFromCache(
          page: page,
          limit: limit,
          search: search,
          status: status,
          parentId: parentId,
          onlyParents: onlyParents,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        print('❌ Error inesperado en categorías: $e - Usando cache...');
        // ✅ Marcar servidor como no alcanzable si es error de conexión
        if (e.toString().contains('timeout') ||
            e.toString().contains('SocketException') ||
            e.toString().contains('conexión')) {
          networkInfo.markServerUnreachable();
        }
        return _getCategoriesFromCache(
          page: page,
          limit: limit,
          search: search,
          status: status,
          parentId: parentId,
          onlyParents: onlyParents,
          sortBy: sortBy,
          sortOrder: sortOrder,
        );
      }
    } else {
      // Sin conexión, intentar obtener desde cache
      return _getCategoriesFromCache(
        page: page,
        limit: limit,
        search: search,
        status: status,
        parentId: parentId,
        onlyParents: onlyParents,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        // Intentar obtener desde el servidor
        final response = await remoteDataSource.getCategoryById(id);

        // Cache la categoría individual para uso offline
        try {
          await localDataSource.cacheCategory(response);
        } catch (e) {
          print('⚠️ Error al cachear categoría individual: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        // Si falla el servidor, intentar desde cache como fallback
        final cacheResult = await _getCategoryFromCache(id);
        return cacheResult.fold(
          (failure) => Left(
            _mapServerExceptionToFailure(e),
          ), // Error original del servidor
          (category) => Right(category), // Éxito desde cache
        );
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        // Para otros errores, intentar cache como fallback
        return _getCategoryFromCache(id);
      }
    } else {
      // Sin conexión, ir directo al cache
      return _getCategoryFromCache(id);
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryBySlug(String slug) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCategoryBySlug(slug);

        // Cache la categoría encontrada
        try {
          await localDataSource.cacheCategory(response);
        } catch (e) {
          print('⚠️ Error al cachear categoría por slug: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener categoría por slug: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // @override
  // Future<Either<Failure, List<CategoryTree>>> getCategoryTree() async {
  //   if (await networkInfo.isConnected) {
  //     try {
  //       final response = await remoteDataSource.getCategoryTree();

  //       // Cache el árbol completo para uso offline
  //       try {
  //         await localDataSource.cacheCategoryTree(response);
  //       } catch (e) {
  //         print('⚠️ Error al cachear árbol de categorías: $e');
  //       }

  //       // Convertir a CategoryTree entities
  //       final categoryTrees =
  //           response
  //               .map((model) => CategoryTree.fromCategory(model.toEntity()))
  //               .toList();

  //       return Right(categoryTrees);
  //     } on ServerException catch (e) {
  //       return Left(_mapServerExceptionToFailure(e));
  //     } on ConnectionException catch (e) {
  //       return Left(ConnectionFailure(e.message));
  //     } catch (e) {
  //       return Left(
  //         UnknownFailure('Error inesperado al obtener árbol de categorías: $e'),
  //       );
  //     }
  //   } else {
  //     // Sin conexión, intentar desde cache
  //     return _getCategoryTreeFromCache();
  //   }
  // }

  @override
  Future<Either<Failure, List<CategoryTree>>> getCategoryTree() async {
    if (await networkInfo.isConnected) {
      try {
        // ✅ CORRECCIÓN: Obtener respuesta JSON directamente
        final response = await remoteDataSource.getCategoryTree();

        print(
          '🌳 CategoryRepository: Processing ${response.length} categories from remote',
        );

        // Cache el árbol completo para uso offline
        try {
          await localDataSource.cacheCategoryTree(response);
        } catch (e) {
          print('⚠️ Error al cachear árbol de categorías: $e');
        }

        // ✅ CORRECCIÓN CRÍTICA: Convertir CategoryModel a CategoryTree directamente
        // El problema estaba en usar fromCategory cuando necesitamos fromJson
        final categoryTrees =
            response.map((categoryModel) {
              try {
                // Convertir CategoryModel a JSON y luego a CategoryTree
                final jsonData = categoryModel.toJson();

                // Asegurar campos obligatorios para CategoryTree
                if (jsonData['level'] == null) {
                  jsonData['level'] = categoryModel.level;
                }
                if (jsonData['hasChildren'] == null) {
                  jsonData['hasChildren'] = categoryModel.isParent;
                }

                print(
                  '🏗️ Converting CategoryModel to CategoryTree: ${categoryModel.name}',
                );
                return CategoryTree.fromJson(jsonData);
              } catch (e) {
                print('❌ Error converting CategoryModel to CategoryTree: $e');
                print('   CategoryModel: ${categoryModel.name}');
                rethrow;
              }
            }).toList();

        print(
          '✅ CategoryRepository: Successfully converted ${categoryTrees.length} CategoryTrees',
        );
        return Right(categoryTrees);
      } on ServerException catch (e) {
        print('⚠️ ServerException en getCategoryTree - Usando cache...');
        return _getCategoryTreeFromCache();
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en getCategoryTree - Usando cache...');
        return _getCategoryTreeFromCache();
      } catch (e, stackTrace) {
        print('❌ Error inesperado en getCategoryTree - Usando cache...');
        return _getCategoryTreeFromCache();
      }
    } else {
      // Sin conexión, intentar desde cache
      return _getCategoryTreeFromCache();
    }
  }

  @override
  Future<Either<Failure, CategoryStats>> getCategoryStats() async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getCategoryStats();

        // Cache las estadísticas
        try {
          await localDataSource.cacheCategoryStats(response);
        } catch (e) {
          print('⚠️ Error al cachear estadísticas: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException en stats de categorías: ${e.message} - Usando cache...');
        return _getCategoryStatsFromCache();
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException en stats de categorías: ${e.message} - Usando cache...');
        return _getCategoryStatsFromCache();
      } catch (e) {
        print('❌ Error inesperado en stats de categorías: $e - Usando cache...');
        return _getCategoryStatsFromCache();
      }
    } else {
      // Sin conexión, intentar desde cache
      return _getCategoryStatsFromCache();
    }
  }

  @override
  Future<Either<Failure, List<Category>>> searchCategories(
    String searchTerm, {
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.searchCategories(
          searchTerm,
          limit,
        );

        // Convertir a entidades del dominio
        final categories = response.map((model) => model.toEntity()).toList();
        return Right(categories);
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
    if (await networkInfo.isConnected) {
      try {
        // Crear request model
        final request = CreateCategoryRequestModel.fromParams(
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );

        // Crear categoría en el servidor
        final response = await remoteDataSource.createCategory(request);

        // Actualizar cache después de crear
        try {
          await localDataSource.cacheCategory(response);
          // Invalidar cache general para reflejar los cambios en listados
          // await _invalidateListCache(); // This would delete the category we just cached!
        } catch (e) {
          print('⚠️ Error al actualizar cache después de crear: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException al crear categoría: ${e.message} - Creando offline...');
        return _createCategoryOffline(
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al crear categoría: ${e.message} - Creando offline...');
        return _createCategoryOffline(
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );
      } catch (e) {
        print('❌ Error inesperado al crear categoría: $e - Creando offline...');
        return _createCategoryOffline(
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );
      }
    } else {
      // Sin conexión, crear categoría offline
      return _createCategoryOffline(
        name: name,
        description: description,
        slug: slug,
        image: image,
        status: status,
        sortOrder: sortOrder,
        parentId: parentId,
      );
    }
  }

  /// Crear categoría offline (usado como fallback cuando falla el servidor o no hay conexión)
  Future<Either<Failure, Category>> _createCategoryOffline({
    required String name,
    String? description,
    required String slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
  }) async {
    print('📱 CategoryRepository: Creating category offline: $name');
    try {
      final now = DateTime.now();
      final tempId = 'category_offline_${now.millisecondsSinceEpoch}_${name.hashCode}';

      final tempCategory = Category(
        id: tempId,
        name: name,
        description: description ?? '',
        slug: slug,
        image: image,
        status: status ?? CategoryStatus.active,
        sortOrder: sortOrder ?? 0,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      );

      // Cache localmente
      await localDataSource.cacheCategory(CategoryModel.fromEntity(tempCategory));

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Category',
          entityId: tempId,
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
          priority: 1,
        );
        print('📤 CategoryRepository: Operación agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Category created offline successfully');
      return Right(tempCategory);
    } catch (e) {
      print('❌ Error creating category offline: $e');
      return Left(CacheFailure('Error al crear categoría offline: $e'));
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
    if (await networkInfo.isConnected) {
      try {
        // Crear request model
        final request = UpdateCategoryRequestModel.fromParams(
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );

        // Validar que hay cambios para actualizar
        if (!request.hasUpdates) {
          return Left(ValidationFailure(['No hay cambios para actualizar']));
        }

        // Actualizar en el servidor
        final response = await remoteDataSource.updateCategory(id, request);

        // Actualizar cache
        try {
          await localDataSource.cacheCategory(response);
          // await _invalidateListCache(); // This would delete the category we just cached!
        } catch (e) {
          print('⚠️ Error al actualizar cache después de modificar: $e');
        }

        return Right(response.toEntity());
      } on ServerException catch (e) {
        print('⚠️ ServerException al actualizar categoría: ${e.message} - Actualizando offline...');
        return _updateCategoryOffline(
          id: id,
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );
      } on ConnectionException catch (e) {
        print('⚠️ ConnectionException al actualizar categoría: ${e.message} - Actualizando offline...');
        return _updateCategoryOffline(
          id: id,
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );
      } catch (e) {
        print('❌ Error inesperado al actualizar categoría: $e - Actualizando offline...');
        return _updateCategoryOffline(
          id: id,
          name: name,
          description: description,
          slug: slug,
          image: image,
          status: status,
          sortOrder: sortOrder,
          parentId: parentId,
        );
      }
    } else {
      // Sin conexión, actualizar offline
      return _updateCategoryOffline(
        id: id,
        name: name,
        description: description,
        slug: slug,
        image: image,
        status: status,
        sortOrder: sortOrder,
        parentId: parentId,
      );
    }
  }

  /// Actualizar categoría offline (usado como fallback cuando falla el servidor o no hay conexión)
  Future<Either<Failure, Category>> _updateCategoryOffline({
    required String id,
    String? name,
    String? description,
    String? slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
  }) async {
    print('📱 CategoryRepository: Updating category offline: $id');
    try {
      // Actualizar en ISAR
      final isarCategory = await isar.isarCategorys
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (isarCategory == null) {
        return Left(CacheFailure('Categoría no encontrada en ISAR: $id'));
      }

      // Actualizar campos en ISAR
      if (name != null) isarCategory.name = name;
      if (description != null) isarCategory.description = description;
      if (slug != null) isarCategory.slug = slug;
      if (image != null) isarCategory.image = image;
      if (status != null) {
        isarCategory.status = status == CategoryStatus.active
            ? IsarCategoryStatus.active
            : IsarCategoryStatus.inactive;
      }
      if (sortOrder != null) isarCategory.sortOrder = sortOrder;
      if (parentId != null) isarCategory.parentId = parentId;

      // Marcar como no sincronizado
      isarCategory.markAsUnsynced();

      // Guardar en ISAR
      await isar.writeTxn(() async {
        await isar.isarCategorys.put(isarCategory);
      });

      final updatedCategory = isarCategory.toEntity();

      // Guardar en cache también
      await localDataSource.cacheCategory(CategoryModel.fromEntity(updatedCategory));

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Category',
          entityId: id,
          operationType: SyncOperationType.update,
          data: {
            'name': name,
            'description': description,
            'slug': slug,
            'image': image,
            'status': status?.name,
            'sortOrder': sortOrder,
            'parentId': parentId,
          },
          priority: 1,
        );
        print('📤 Actualización agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Category updated offline successfully');
      return Right(updatedCategory);
    } catch (e) {
      print('❌ Error updating category offline: $e');
      return Left(CacheFailure('Error al actualizar categoría offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategoryStatus({
    required String id,
    required CategoryStatus status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateCategoryStatus(
          id,
          status.name,
        );

        // Actualizar cache
        try {
          await localDataSource.cacheCategory(response);
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
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCategory(id);

        // Soft delete en ISAR después de eliminar en servidor
        try {
          final isar = IsarDatabase.instance.database;
          final isarCategory = await isar.isarCategorys
              .filter()
              .serverIdEqualTo(id)
              .findFirst();

          if (isarCategory != null) {
            isarCategory.softDelete();
            await isar.writeTxn(() async {
              await isar.isarCategorys.put(isarCategory);
            });
            print('✅ Category marcada como eliminada en ISAR: $id');
          }
        } catch (e) {
          print('⚠️ Error actualizando ISAR (no crítico): $e');
        }

        // Remover del cache
        try {
          await localDataSource.removeCachedCategory(id);
          // await _invalidateListCache(); // This would delete the category we just cached!
        } catch (e) {
          print('⚠️ Error al actualizar cache después de eliminar: $e');
        }

        return const Right(unit);
      } on ServerException catch (e) {
        print('⚠️ [CATEGORY_REPO] ServerException al eliminar: ${e.message} - Fallback offline...');
        return _deleteCategoryOffline(id);
      } on ConnectionException catch (e) {
        print('⚠️ [CATEGORY_REPO] ConnectionException al eliminar: ${e.message} - Fallback offline...');
        return _deleteCategoryOffline(id);
      } catch (e) {
        print('⚠️ [CATEGORY_REPO] Exception al eliminar: $e - Fallback offline...');
        return _deleteCategoryOffline(id);
      }
    } else {
      // Sin conexión, eliminar offline
      return _deleteCategoryOffline(id);
    }
  }

  Future<Either<Failure, Unit>> _deleteCategoryOffline(String id) async {
    print('📱 CategoryRepository: Deleting category offline: $id');
    try {
      // Soft delete en ISAR
      try {
        final isar = IsarDatabase.instance.database;
        final isarCategory = await isar.isarCategorys
            .filter()
            .serverIdEqualTo(id)
            .findFirst();

        if (isarCategory != null) {
          isarCategory.softDelete();
          await isar.writeTxn(() async {
            await isar.isarCategorys.put(isarCategory);
          });
          print('✅ Category marcada como eliminada en ISAR (offline): $id');
        }
      } catch (e) {
        print('⚠️ Error actualizando ISAR (no crítico): $e');
      }

      // Remover del cache
      await localDataSource.removeCachedCategory(id);

      // Agregar a cola de sincronización
      try {
        final syncService = Get.find<SyncService>();
        await syncService.addOperationForCurrentUser(
          entityType: 'Category',
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {'id': id},
          priority: 1,
        );
        print('📤 Eliminación agregada a cola');
      } catch (e) {
        print('⚠️ Error agregando a cola: $e');
      }

      print('✅ Category deleted offline successfully');
      return const Right(unit);
    } catch (e) {
      print('❌ Error deleting category offline: $e');
      return Left(CacheFailure('Error al eliminar categoría offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Category>> restoreCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.restoreCategory(id);

        // Cache la categoría restaurada
        try {
          await localDataSource.cacheCategory(response);
          // await _invalidateListCache(); // This would delete the category we just cached!
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
          UnknownFailure('Error inesperado al restaurar categoría: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // ==================== UTILITY OPERATIONS ====================

  @override
  Future<Either<Failure, bool>> isSlugAvailable(
    String slug, {
    String? excludeId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isAvailable = await remoteDataSource.isSlugAvailable(
          slug,
          excludeId,
        );
        return Right(isAvailable);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al verificar slug: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, String>> generateUniqueSlug(String name) async {
    if (await networkInfo.isConnected) {
      try {
        final slug = await remoteDataSource.generateUniqueSlug(name);
        return Right(slug);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(UnknownFailure('Error inesperado al generar slug: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  @override
  Future<Either<Failure, bool>> existsByName(
    String name, {
    String? excludeId,
  }) async {
    // ✅ Esta validación funciona offline usando el datasource local
    try {
      final exists = await localDataSource.existsByName(name, excludeId);
      return Right(exists);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al verificar nombre: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> reorderCategories(
    List<CategoryReorder> reorders,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        // Convertir a formato esperado por el API
        final reorderData =
            reorders
                .map(
                  (reorder) => {
                    'id': reorder.id,
                    'sortOrder': reorder.sortOrder,
                  },
                )
                .toList();

        await remoteDataSource.reorderCategories(reorderData);

        // Invalidar cache después del reordenamiento
        try {
          // await _invalidateListCache(); // This would delete the category we just cached!
        } catch (e) {
          print('⚠️ Error al invalidar cache después de reordenar: $e');
        }

        return const Right(unit);
      } on ServerException catch (e) {
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al reordenar categorías: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
    }
  }

  // ==================== CACHE OPERATIONS ====================

  @override
  Future<Either<Failure, List<Category>>> getCachedCategories() async {
    try {
      final categories = await localDataSource.getCachedCategories();
      return Right(categories.map((model) => model.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado al obtener cache: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearCategoryCache() async {
    try {
      await localDataSource.clearCategoryCache();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado al limpiar cache: $e'));
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Determinar si se debe cachear el resultado
  /// FASE 3: Siempre cachear a ISAR (upsert por serverId evita duplicados)
  bool _shouldCacheResult(
    int page,
    String? search,
    CategoryStatus? status,
    String? parentId,
  ) {
    return true;
  }

  /// Invalidar cache de listados para reflejar cambios
  Future<void> _invalidateListCache() async {
    try {
      await localDataSource.clearCategoryCache();
    } catch (e) {
      print('⚠️ Error al invalidar cache de listados: $e');
    }
  }

  /// Obtener categorías desde cache local con filtros aplicados
  Future<Either<Failure, PaginatedResult<Category>>> _getCategoriesFromCache({
    int page = 1,
    int limit = 10,
    String? search,
    CategoryStatus? status,
    String? parentId,
    bool? onlyParents,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final categories = await localDataSource.getCachedCategories();
      var filteredCategories =
          categories.map((model) => model.toEntity()).toList();

      print(
        '📂 CategoryRepository: Applying offline filters to ${filteredCategories.length} cached categories',
      );
      print(
        '   Filters: status=$status, onlyParents=$onlyParents, search=$search, parentId=$parentId',
      );

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        filteredCategories =
            filteredCategories.where((category) {
              return category.name.toLowerCase().contains(
                    search.toLowerCase(),
                  ) ||
                  (category.description?.toLowerCase().contains(
                        search.toLowerCase(),
                      ) ??
                      false);
            }).toList();
        print(
          '   After search filter: ${filteredCategories.length} categories',
        );
      }

      // Apply status filter
      if (status != null) {
        filteredCategories =
            filteredCategories.where((category) {
              return category.status == status;
            }).toList();
        print(
          '   After status filter: ${filteredCategories.length} categories',
        );
      }

      // Apply parent filter
      if (parentId != null) {
        filteredCategories =
            filteredCategories.where((category) {
              return category.parentId == parentId;
            }).toList();
        print(
          '   After parentId filter: ${filteredCategories.length} categories',
        );
      } else if (onlyParents == true) {
        filteredCategories =
            filteredCategories.where((category) {
              return category.parentId == null || category.parentId!.isEmpty;
            }).toList();
        print(
          '   After onlyParents filter: ${filteredCategories.length} categories',
        );
      }

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'name':
            filteredCategories.sort((a, b) {
              final comparison = a.name.compareTo(b.name);
              return sortOrder == 'desc' ? -comparison : comparison;
            });
            break;
          case 'created_at':
            filteredCategories.sort((a, b) {
              final comparison = a.createdAt.compareTo(b.createdAt);
              return sortOrder == 'desc' ? -comparison : comparison;
            });
            break;
          case 'sort_order':
          default:
            filteredCategories.sort((a, b) {
              final comparison = (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0);
              return sortOrder == 'desc' ? -comparison : comparison;
            });
            break;
        }
        print(
          '   After sorting by $sortBy: ${filteredCategories.length} categories',
        );
      }

      // Apply pagination
      final totalItems = filteredCategories.length;
      final totalPages = (totalItems / limit).ceil();
      final startIndex = (page - 1) * limit;
      final endIndex = (startIndex + limit).clamp(0, totalItems);

      final paginatedCategories = filteredCategories.sublist(
        startIndex.clamp(0, totalItems),
        endIndex,
      );

      print(
        '   Final result: ${paginatedCategories.length}/$totalItems categories (page $page/$totalPages)',
      );

      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(
        PaginatedResult<Category>(data: paginatedCategories, meta: meta),
      );
    } on CacheException catch (e) {
      print(
        '❌ CategoryRepository: Cache error in _getCategoriesFromCache: ${e.message}',
      );
      return Left(CacheFailure(e.message));
    } catch (e) {
      print(
        '❌ CategoryRepository: Unexpected error in _getCategoriesFromCache: $e',
      );
      return Left(
        UnknownFailure('Error al obtener categorías desde cache: $e'),
      );
    }
  }

  /// Obtener categoría individual desde cache local
  Future<Either<Failure, Category>> _getCategoryFromCache(String id) async {
    try {
      final category = await localDataSource.getCachedCategory(id);
      if (category != null) {
        return Right(category.toEntity());
      } else {
        return const Left(CacheFailure('Datos no encontrados en cache'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Error al obtener categoría desde cache: $e'));
    }
  }

  /// Obtener árbol de categorías desde cache
  // Future<Either<Failure, List<CategoryTree>>>
  // _getCategoryTreeFromCache() async {
  //   try {
  //     final categories = await localDataSource.getCachedCategoryTree();
  //     final categoryTrees =
  //         categories
  //             .map((model) => CategoryTree.fromCategory(model.toEntity()))
  //             .toList();

  //     return Right(categoryTrees);
  //   } on CacheException catch (e) {
  //     return Left(CacheFailure(e.message));
  //   } catch (e) {
  //     return Left(UnknownFailure('Error al obtener árbol desde cache: $e'));
  //   }
  // }

  Future<Either<Failure, List<CategoryTree>>>
  _getCategoryTreeFromCache() async {
    try {
      print('📂 CategoryRepository: Loading category tree from cache');

      final categories = await localDataSource.getCachedCategoryTree();

      // ✅ CORRECCIÓN: Convertir correctamente desde cache
      final categoryTrees =
          categories.map((categoryModel) {
            try {
              // Convertir CategoryModel a JSON y luego a CategoryTree
              final jsonData = categoryModel.toJson();

              // Asegurar campos obligatorios para CategoryTree
              if (jsonData['level'] == null) {
                jsonData['level'] = categoryModel.level;
              }
              if (jsonData['hasChildren'] == null) {
                jsonData['hasChildren'] = categoryModel.isParent;
              }

              return CategoryTree.fromJson(jsonData);
            } catch (e) {
              print(
                '❌ Error converting cached CategoryModel to CategoryTree: $e',
              );
              rethrow;
            }
          }).toList();

      print(
        '✅ CategoryRepository: Successfully loaded ${categoryTrees.length} CategoryTrees from cache',
      );
      return Right(categoryTrees);
    } on CacheException catch (e) {
      // No imprimir error - es normal que no haya cache del árbol
      return Left(CacheFailure(e.message));
    } catch (e) {
      // No imprimir error - es normal que no haya cache
      return Left(UnknownFailure('Error al obtener árbol desde cache: $e'));
    }
  }

  /// Obtener estadísticas desde cache
  Future<Either<Failure, CategoryStats>> _getCategoryStatsFromCache() async {
    try {
      final stats = await localDataSource.getCachedCategoryStats();
      if (stats != null) {
        return Right(stats.toEntity());
      } else {
        return const Left(CacheFailure('Datos no encontrados en cache'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
        UnknownFailure('Error al obtener estadísticas desde cache: $e'),
      );
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sincronizar categorías creadas offline con el servidor
  Future<Either<Failure, List<Category>>> syncOfflineCategories() async {
    if (!await networkInfo.isConnected) {
      return const Left(ConnectionFailure.noInternet);
    }

    try {
      print('🔄 CategoryRepository: Starting offline categories sync...');

      // Obtener categorías no sincronizadas desde ISAR
      final isar = IsarDatabase.instance.database;
      final unsyncedCategories = await isar.isarCategorys
          .filter()
          .isSyncedEqualTo(false)
          .and()
          .deletedAtIsNull()
          .findAll();

      if (unsyncedCategories.isEmpty) {
        print('✅ CategoryRepository: No categories to sync');
        return const Right([]);
      }

      print('📤 CategoryRepository: Syncing ${unsyncedCategories.length} offline categories...');
      final syncedCategories = <Category>[];

      for (final isarCategory in unsyncedCategories) {
        try {
          // Determinar si es CREATE o UPDATE basándose en el serverId
          final isCreate = isarCategory.serverId.startsWith('category_offline_');

          if (isCreate) {
            // CREATE: Enviar al servidor y actualizar con ID real
            print('📝 Creating category: ${isarCategory.name}');

            final request = CreateCategoryRequestModel.fromParams(
              name: isarCategory.name,
              description: isarCategory.description,
              slug: isarCategory.slug,
              image: isarCategory.image,
              status: isarCategory.status == IsarCategoryStatus.active
                  ? CategoryStatus.active
                  : CategoryStatus.inactive,
              sortOrder: isarCategory.sortOrder,
              parentId: isarCategory.parentId,
            );

            final created = await remoteDataSource.createCategory(request);

            // Actualizar ISAR con el ID real del servidor
            isarCategory.serverId = created.id;
            isarCategory.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarCategorys.put(isarCategory);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheCategory(created);

            syncedCategories.add(created.toEntity());
            print('✅ Category created and synced: ${isarCategory.name} -> ${created.id}');
          } else {
            // UPDATE: Enviar actualización al servidor
            print('📝 Updating category: ${isarCategory.name}');

            final request = UpdateCategoryRequestModel.fromParams(
              name: isarCategory.name,
              description: isarCategory.description,
              slug: isarCategory.slug,
              image: isarCategory.image,
              status: isarCategory.status == IsarCategoryStatus.active
                  ? CategoryStatus.active
                  : CategoryStatus.inactive,
              sortOrder: isarCategory.sortOrder,
              parentId: isarCategory.parentId,
            );

            final updated = await remoteDataSource.updateCategory(
              isarCategory.serverId,
              request,
            );

            isarCategory.markAsSynced();

            await isar.writeTxn(() async {
              await isar.isarCategorys.put(isarCategory);
            });

            // También actualizar en SecureStorage
            await localDataSource.cacheCategory(updated);

            syncedCategories.add(updated.toEntity());
            print('✅ Category updated and synced: ${isarCategory.name}');
          }
        } catch (e) {
          print('❌ Error sincronizando categoría ${isarCategory.name}: $e');
          // Continuar con la siguiente
        }
      }

      print('🎯 CategoryRepository: Sync completed. Success: ${syncedCategories.length}');
      return Right(syncedCategories);
    } catch (e) {
      print('💥 CategoryRepository: Error during offline categories sync: $e');
      return Left(UnknownFailure('Error al sincronizar categorías offline: $e'));
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
