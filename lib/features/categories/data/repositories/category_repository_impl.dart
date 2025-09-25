// lib/features/categories/data/repositories/category_repository_impl.dart
import 'package:baudex_desktop/app/core/models/pagination_meta.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_datasource.dart';
import '../datasources/category_local_datasource.dart';

import '../models/category_query_model.dart';
import '../models/create_category_request_model.dart';
import '../models/update_category_request_model.dart';

/// Implementación del repositorio de categorías
///
/// Esta clase maneja la lógica de datos combinando fuentes remotas y locales,
/// implementando estrategias de cache y manejo de errores robusto.
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final CategoryLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

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
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        return Left(ConnectionFailure(e.message));
      } on CacheException catch (e) {
        return Left(CacheFailure(e.message));
      } catch (e) {
        return Left(
          UnknownFailure('Error inesperado al obtener categorías: $e'),
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
        print('❌ CategoryRepository: ServerException in getCategoryTree: $e');
        return Left(_mapServerExceptionToFailure(e));
      } on ConnectionException catch (e) {
        print(
          '❌ CategoryRepository: ConnectionException in getCategoryTree: $e',
        );
        return Left(ConnectionFailure(e.message));
      } catch (e, stackTrace) {
        print('❌ CategoryRepository: Unexpected error in getCategoryTree: $e');
        print('   StackTrace: $stackTrace');
        return Left(
          UnknownFailure('Error inesperado al obtener árbol de categorías: $e'),
        );
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
        return Left(UnknownFailure('Error inesperado al crear categoría: $e'));
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
          UnknownFailure('Error inesperado al actualizar categoría: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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

        // Remover del cache
        try {
          await localDataSource.removeCachedCategory(id);
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
          UnknownFailure('Error inesperado al eliminar categoría: $e'),
        );
      }
    } else {
      return const Left(ConnectionFailure.noInternet);
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
          await _invalidateListCache();
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
  /// Cacheamos más casos para asegurar disponibilidad offline
  bool _shouldCacheResult(
    int page,
    String? search,
    CategoryStatus? status,
    String? parentId,
  ) {
    // Cache first page results for common use cases
    return page == 1 && search == null && 
           (status == null || status == CategoryStatus.active) &&
           parentId == null;
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
  Future<Either<Failure, PaginatedResult<Category>>>
  _getCategoriesFromCache({
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
      var filteredCategories = categories.map((model) => model.toEntity()).toList();

      print('📂 CategoryRepository: Applying offline filters to ${filteredCategories.length} cached categories');
      print('   Filters: status=$status, onlyParents=$onlyParents, search=$search, parentId=$parentId');

      // Apply search filter
      if (search != null && search.isNotEmpty) {
        filteredCategories = filteredCategories.where((category) {
          return category.name.toLowerCase().contains(search.toLowerCase()) ||
                 (category.description?.toLowerCase().contains(search.toLowerCase()) ?? false);
        }).toList();
        print('   After search filter: ${filteredCategories.length} categories');
      }

      // Apply status filter
      if (status != null) {
        filteredCategories = filteredCategories.where((category) {
          return category.status == status;
        }).toList();
        print('   After status filter: ${filteredCategories.length} categories');
      }

      // Apply parent filter
      if (parentId != null) {
        filteredCategories = filteredCategories.where((category) {
          return category.parentId == parentId;
        }).toList();
        print('   After parentId filter: ${filteredCategories.length} categories');
      } else if (onlyParents == true) {
        filteredCategories = filteredCategories.where((category) {
          return category.parentId == null || category.parentId!.isEmpty;
        }).toList();
        print('   After onlyParents filter: ${filteredCategories.length} categories');
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
        print('   After sorting by $sortBy: ${filteredCategories.length} categories');
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

      print('   Final result: ${paginatedCategories.length}/${totalItems} categories (page $page/$totalPages)');

      final meta = PaginationMeta(
        page: page,
        limit: limit,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      );

      return Right(
        PaginatedResult<Category>(
          data: paginatedCategories,
          meta: meta,
        ),
      );
    } on CacheException catch (e) {
      print('❌ CategoryRepository: Cache error in _getCategoriesFromCache: ${e.message}');
      return Left(CacheFailure(e.message));
    } catch (e) {
      print('❌ CategoryRepository: Unexpected error in _getCategoriesFromCache: $e');
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
      print(
        '❌ CategoryRepository: CacheException in _getCategoryTreeFromCache: $e',
      );
      return Left(CacheFailure(e.message));
    } catch (e) {
      print(
        '❌ CategoryRepository: Unexpected error in _getCategoryTreeFromCache: $e',
      );
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
