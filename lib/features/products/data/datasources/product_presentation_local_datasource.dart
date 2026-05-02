// lib/features/products/data/datasources/product_presentation_local_datasource.dart
import 'package:isar/isar.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/data/local/isar_database.dart';
import '../models/isar/isar_product_presentation.dart';
import '../models/product_presentation_model.dart';

abstract class ProductPresentationLocalDataSource {
  /// Guardar/actualizar una lista de presentaciones en cache
  Future<void> cachePresentations(List<ProductPresentationModel> presentations);

  /// Obtener todas las presentaciones de un producto desde cache
  Future<List<ProductPresentationModel>> getPresentationsByProductId(
    String productId,
  );

  /// Guardar una sola presentación (upsert por serverId)
  Future<void> savePresentation(ProductPresentationModel presentation);

  /// Eliminar una presentación del cache
  Future<void> deletePresentation(String serverId);

  /// Obtener presentaciones no sincronizadas
  Future<List<IsarProductPresentation>> getUnsynced();
}

class ProductPresentationLocalDataSourceIsar
    implements ProductPresentationLocalDataSource {
  final IIsarDatabase _database;

  ProductPresentationLocalDataSourceIsar(this._database);

  Isar get _isar => _database.database as Isar;

  @override
  Future<void> cachePresentations(
    List<ProductPresentationModel> presentations,
  ) async {
    try {
      await _isar.writeTxn(() async {
        for (final model in presentations) {
          final existing = await _isar.isarProductPresentations
              .filter()
              .serverIdEqualTo(model.id)
              .findFirst();

          if (existing != null) {
            existing
              ..name = model.name
              ..factor = model.factor
              ..price = model.price
              ..currency = model.currency
              ..barcode = model.barcode
              ..sku = model.sku
              ..isDefault = model.isDefault
              ..isActive = model.isActive
              ..sortOrder = model.sortOrder
              ..updatedAt = model.updatedAt
              ..isSynced = true
              ..lastSyncAt = DateTime.now();
            await _isar.isarProductPresentations.put(existing);
          } else {
            final isarPresentation = IsarProductPresentation.fromModel(model);
            await _isar.isarProductPresentations.put(isarPresentation);
          }
        }
      });
    } catch (e) {
      throw CacheException('Error al guardar presentaciones en cache: $e');
    }
  }

  @override
  Future<List<ProductPresentationModel>> getPresentationsByProductId(
    String productId,
  ) async {
    try {
      final results = await _isar.isarProductPresentations
          .filter()
          .productIdEqualTo(productId)
          .sortBySortOrder()
          .findAll();

      return results.map((isar) {
        final entity = isar.toEntity();
        return ProductPresentationModel.fromEntity(entity);
      }).toList();
    } catch (e) {
      throw CacheException(
        'Error al leer presentaciones del cache: $e',
      );
    }
  }

  @override
  Future<void> savePresentation(ProductPresentationModel presentation) async {
    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.isarProductPresentations
            .filter()
            .serverIdEqualTo(presentation.id)
            .findFirst();

        if (existing != null) {
          existing
            ..name = presentation.name
            ..factor = presentation.factor
            ..price = presentation.price
            ..currency = presentation.currency
            ..barcode = presentation.barcode
            ..sku = presentation.sku
            ..isDefault = presentation.isDefault
            ..isActive = presentation.isActive
            ..sortOrder = presentation.sortOrder
            ..updatedAt = presentation.updatedAt
            ..isSynced = true
            ..lastSyncAt = DateTime.now();
          await _isar.isarProductPresentations.put(existing);
        } else {
          final isarPresentation =
              IsarProductPresentation.fromModel(presentation);
          await _isar.isarProductPresentations.put(isarPresentation);
        }
      });
    } catch (e) {
      throw CacheException('Error al guardar presentación en cache: $e');
    }
  }

  @override
  Future<void> deletePresentation(String serverId) async {
    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.isarProductPresentations
            .filter()
            .serverIdEqualTo(serverId)
            .findFirst();
        if (existing != null) {
          await _isar.isarProductPresentations.delete(existing.id);
        }
      });
    } catch (e) {
      throw CacheException('Error al eliminar presentación del cache: $e');
    }
  }

  @override
  Future<List<IsarProductPresentation>> getUnsynced() async {
    try {
      return await _isar.isarProductPresentations
          .filter()
          .isSyncedEqualTo(false)
          .findAll();
    } catch (e) {
      throw CacheException(
        'Error al leer presentaciones no sincronizadas: $e',
      );
    }
  }
}
