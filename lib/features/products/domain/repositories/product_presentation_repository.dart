// lib/features/products/domain/repositories/product_presentation_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/product_presentation.dart';

abstract class ProductPresentationRepository {
  /// Obtener todas las presentaciones de un producto
  Future<Either<Failure, List<ProductPresentation>>> getPresentations(
    String productId,
  );

  /// Obtener una presentación por ID
  Future<Either<Failure, ProductPresentation>> getPresentationById(
    String productId,
    String id,
  );

  /// Crear una presentación
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
  });

  /// Actualizar una presentación
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
  });

  /// Eliminar una presentación (soft delete)
  Future<Either<Failure, Unit>> deletePresentation(
    String productId,
    String id,
  );

  /// Restaurar una presentación eliminada
  Future<Either<Failure, ProductPresentation>> restorePresentation(
    String productId,
    String id,
  );
}
