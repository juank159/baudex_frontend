// lib/features/products/data/repositories/product_presentation_repository_impl.dart
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/data/local/sync_queue.dart';
import '../../domain/entities/product_presentation.dart';
import '../../domain/repositories/product_presentation_repository.dart';
import '../datasources/product_presentation_remote_datasource.dart';
import '../datasources/product_presentation_local_datasource.dart';
import '../models/create_product_presentation_request_model.dart';
import '../models/update_product_presentation_request_model.dart';
import '../models/isar/isar_product_presentation.dart';

class ProductPresentationRepositoryImpl
    implements ProductPresentationRepository {
  final ProductPresentationRemoteDataSource remoteDataSource;
  final ProductPresentationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const ProductPresentationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  // ---- helpers ----

  String _generateTempId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(99999);
    return 'presentation_offline_${ts}_$rand';
  }

  Future<void> _enqueue({
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final syncService = Get.find<SyncService>();
      await syncService.addOperationForCurrentUser(
        entityType: 'ProductPresentation',
        entityId: entityId,
        operationType: operationType,
        data: data,
        priority: 1,
      );
    } catch (e) {
      AppLogger.w(
        'ProductPresentationRepo: Error encolando operación: $e',
        tag: 'PresentationRepo',
      );
    }
  }

  // ---- public interface ----

  @override
  Future<Either<Failure, List<ProductPresentation>>> getPresentations(
    String productId,
  ) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final models = await remoteDataSource.getPresentations(productId);
        await localDataSource.cachePresentations(models);
        return Right(models.map((m) => m.toEntity()).toList());
      } on ServerException catch (e) {
        AppLogger.w(
          'Error remoto al obtener presentaciones, usando cache: $e',
          tag: 'PresentationRepo',
        );
        return _getFromCache(productId);
      } on ConnectionException catch (e) {
        AppLogger.w(
          'Sin conexión, usando cache: $e',
          tag: 'PresentationRepo',
        );
        return _getFromCache(productId);
      } catch (e) {
        AppLogger.e(
          'Error inesperado al obtener presentaciones: $e',
          tag: 'PresentationRepo',
        );
        return _getFromCache(productId);
      }
    } else {
      return _getFromCache(productId);
    }
  }

  Future<Either<Failure, List<ProductPresentation>>> _getFromCache(
    String productId,
  ) async {
    try {
      final cached =
          await localDataSource.getPresentationsByProductId(productId);
      return Right(cached.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Error al leer cache de presentaciones: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductPresentation>> getPresentationById(
    String productId,
    String id,
  ) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      // Offline-first: leer del cache local. Si no está, recién entonces
      // reportamos error. Soporta también IDs temp `presentation_offline_*`.
      try {
        final list = await localDataSource.getPresentationsByProductId(productId);
        final cached = list.firstWhereOrNull((p) => p.id == id);
        if (cached != null) {
          return Right(cached.toEntity());
        }
      } catch (_) {}
      return Left(
        const CacheFailure('Presentación no disponible en caché local'),
      );
    }
    try {
      final model = await remoteDataSource.getPresentationById(productId, id);
      await localDataSource.savePresentation(model);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al obtener presentación: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductPresentation>> createPresentation({
    required String productId,
    required String name,
    required double factor,
    required double price,
    String? currency,
    String? barcode,
    String? sku,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final request = CreateProductPresentationRequestModel(
          name: name,
          factor: factor,
          price: price,
          currency: currency,
          barcode: barcode,
          sku: sku,
          isDefault: isDefault,
          isActive: isActive,
          sortOrder: sortOrder,
        );
        final model = await remoteDataSource.createPresentation(
          productId,
          request,
        );
        // Persist with isSynced=true (server ID is real)
        await localDataSource.savePresentation(model);
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.statusCode));
      } on ConnectionException {
        // Fall through to offline path
      } catch (e) {
        return Left(ServerFailure('Error al crear presentación: $e'));
      }
    }

    // ---- Offline path ----
    try {
      final now = DateTime.now();
      final tempId = _generateTempId();

      final isarPresentation = IsarProductPresentation.create(
        serverId: tempId,
        productId: productId,
        name: name,
        factor: factor,
        price: price,
        currency: currency ?? 'COP',
        barcode: barcode,
        sku: sku,
        isDefault: isDefault ?? false,
        isActive: isActive ?? true,
        sortOrder: sortOrder ?? 0,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
        version: 1,
      );

      final isar = IsarDatabase.instance.database as Isar;
      await isar.writeTxn(() async {
        await isar.isarProductPresentations.put(isarPresentation);
      });

      AppLogger.i(
        'Presentación creada offline: $tempId',
        tag: 'PresentationRepo',
      );

      await _enqueue(
        entityId: tempId,
        operationType: SyncOperationType.create,
        data: {
          'productId': productId,
          'name': name,
          'factor': factor,
          'price': price,
          'currency': currency ?? 'COP',
          'barcode': barcode,
          'sku': sku,
          'isDefault': isDefault ?? false,
          'isActive': isActive ?? true,
          'sortOrder': sortOrder ?? 0,
        },
      );

      final entity = isarPresentation.toEntity();
      return Right(entity);
    } catch (e) {
      AppLogger.e(
        'Error creando presentación offline: $e',
        tag: 'PresentationRepo',
      );
      return Left(CacheFailure('Error al crear presentación offline: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductPresentation>> updatePresentation({
    required String productId,
    required String id,
    String? name,
    double? factor,
    double? price,
    String? currency,
    String? barcode,
    String? sku,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
  }) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        final request = UpdateProductPresentationRequestModel(
          name: name,
          factor: factor,
          price: price,
          currency: currency,
          barcode: barcode,
          sku: sku,
          isDefault: isDefault,
          isActive: isActive,
          sortOrder: sortOrder,
        );
        final model = await remoteDataSource.updatePresentation(
          productId,
          id,
          request,
        );
        await localDataSource.savePresentation(model);
        return Right(model.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.statusCode));
      } on ConnectionException {
        // Fall through to offline path
      } catch (e) {
        return Left(ServerFailure('Error al actualizar presentación: $e'));
      }
    }

    // ---- Offline path ----
    try {
      final isar = IsarDatabase.instance.database as Isar;
      final existing = await isar.isarProductPresentations
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (existing == null) {
        return Left(CacheFailure('Presentación no encontrada en cache: $id'));
      }

      // Apply partial update
      if (name != null) existing.name = name;
      if (factor != null) existing.factor = factor;
      if (price != null) existing.price = price;
      if (currency != null) existing.currency = currency;
      if (barcode != null) existing.barcode = barcode;
      if (sku != null) existing.sku = sku;
      if (isDefault != null) existing.isDefault = isDefault;
      if (isActive != null) existing.isActive = isActive;
      if (sortOrder != null) existing.sortOrder = sortOrder;
      existing.markAsUnsynced();

      await isar.writeTxn(() async {
        await isar.isarProductPresentations.put(existing);
      });

      AppLogger.i(
        'Presentación actualizada offline: $id',
        tag: 'PresentationRepo',
      );

      await _enqueue(
        entityId: id,
        operationType: SyncOperationType.update,
        data: {
          'productId': productId,
          'name': existing.name,
          'factor': existing.factor,
          'price': existing.price,
          'currency': existing.currency,
          'barcode': existing.barcode,
          'sku': existing.sku,
          'isDefault': existing.isDefault,
          'isActive': existing.isActive,
          'sortOrder': existing.sortOrder,
        },
      );

      return Right(existing.toEntity());
    } catch (e) {
      AppLogger.e(
        'Error actualizando presentación offline: $e',
        tag: 'PresentationRepo',
      );
      return Left(CacheFailure('Error al actualizar presentación offline: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePresentation(
    String productId,
    String id,
  ) async {
    final isConnected = await networkInfo.isConnected;

    if (isConnected) {
      try {
        await remoteDataSource.deletePresentation(productId, id);
        await localDataSource.deletePresentation(id);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message, code: e.statusCode));
      } on ConnectionException {
        // Fall through to offline path
      } catch (e) {
        return Left(ServerFailure('Error al eliminar presentación: $e'));
      }
    }

    // ---- Offline path ----
    try {
      final isar = IsarDatabase.instance.database as Isar;
      final existing = await isar.isarProductPresentations
          .filter()
          .serverIdEqualTo(id)
          .findFirst();

      if (existing != null) {
        await isar.writeTxn(() async {
          await isar.isarProductPresentations.delete(existing.id);
        });
      }

      AppLogger.i(
        'Presentación eliminada offline (local): $id',
        tag: 'PresentationRepo',
      );

      // Only enqueue DELETE if this is a server-synced entity (not a temp ID)
      if (!id.startsWith('presentation_offline_')) {
        await _enqueue(
          entityId: id,
          operationType: SyncOperationType.delete,
          data: {
            'productId': productId,
          },
        );
      } else {
        // Cancel any pending CREATE/UPDATE ops for this temp entity
        try {
          final isarDb = IsarDatabase.instance;
          final pendingOps = await isarDb.getPendingSyncOperations();
          for (final op in pendingOps) {
            if (op.entityId == id) {
              await isarDb.deleteSyncOperation(op.id);
            }
          }
        } catch (e) {
          AppLogger.w(
            'Error cancelando ops pendientes para $id: $e',
            tag: 'PresentationRepo',
          );
        }
      }

      return const Right(unit);
    } catch (e) {
      AppLogger.e(
        'Error eliminando presentación offline: $e',
        tag: 'PresentationRepo',
      );
      return Left(CacheFailure('Error al eliminar presentación offline: $e'));
    }
  }

  @override
  Future<Either<Failure, ProductPresentation>> restorePresentation(
    String productId,
    String id,
  ) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return Left(
        const ConnectionFailure('Sin conexión a internet'),
      );
    }
    try {
      final model = await remoteDataSource.restorePresentation(productId, id);
      await localDataSource.savePresentation(model);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al restaurar presentación: $e'));
    }
  }
}
