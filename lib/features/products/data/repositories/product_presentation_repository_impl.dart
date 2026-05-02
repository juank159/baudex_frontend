// lib/features/products/data/repositories/product_presentation_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/utils/app_logger.dart';
import '../../domain/entities/product_presentation.dart';
import '../../domain/repositories/product_presentation_repository.dart';
import '../datasources/product_presentation_remote_datasource.dart';
import '../datasources/product_presentation_local_datasource.dart';
import '../models/create_product_presentation_request_model.dart';
import '../models/update_product_presentation_request_model.dart';

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
      return Left(
        const ConnectionFailure('Sin conexión a internet'),
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
    if (!isConnected) {
      return Left(
        const ConnectionFailure('Sin conexión a internet'),
      );
    }
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
      await localDataSource.savePresentation(model);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al crear presentación: $e'));
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
    if (!isConnected) {
      return Left(
        const ConnectionFailure('Sin conexión a internet'),
      );
    }
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
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al actualizar presentación: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePresentation(
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
      await remoteDataSource.deletePresentation(productId, id);
      await localDataSource.deletePresentation(id);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.statusCode));
    } on ConnectionException catch (e) {
      return Left(ConnectionFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error al eliminar presentación: $e'));
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
