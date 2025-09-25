// lib/features/suppliers/domain/repositories/supplier_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/supplier.dart';

abstract class SupplierRepository {
  // ==================== READ OPERATIONS ====================

  /// Obtener proveedores con paginación y filtros
  Future<Either<Failure, PaginatedResult<Supplier>>> getSuppliers({
    int page = 1,
    int limit = 10,
    String? search,
    SupplierStatus? status,
    DocumentType? documentType,
    String? currency,
    bool? hasEmail,
    bool? hasPhone,
    bool? hasCreditLimit,
    bool? hasDiscount,
    String? sortBy,
    String? sortOrder,
  });

  /// Obtener proveedor por ID
  Future<Either<Failure, Supplier>> getSupplierById(String id);

  /// Buscar proveedores por término
  Future<Either<Failure, List<Supplier>>> searchSuppliers(
    String searchTerm, {
    int limit = 10,
  });

  /// Obtener proveedores activos
  Future<Either<Failure, List<Supplier>>> getActiveSuppliers();

  /// Obtener estadísticas de proveedores
  Future<Either<Failure, SupplierStats>> getSupplierStats();

  // ==================== WRITE OPERATIONS ====================

  /// Crear proveedor
  Future<Either<Failure, Supplier>> createSupplier({
    required String name,
    String? code,
    required DocumentType documentType,
    required String documentNumber,
    String? contactPerson,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? website,
    SupplierStatus? status,
    String? currency,
    int? paymentTermsDays,
    double? creditLimit,
    double? discountPercentage,
    String? notes,
    Map<String, dynamic>? metadata,
  });

  /// Actualizar proveedor
  Future<Either<Failure, Supplier>> updateSupplier({
    required String id,
    String? name,
    String? code,
    DocumentType? documentType,
    String? documentNumber,
    String? contactPerson,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? website,
    SupplierStatus? status,
    String? currency,
    int? paymentTermsDays,
    double? creditLimit,
    double? discountPercentage,
    String? notes,
    Map<String, dynamic>? metadata,
  });

  /// Actualizar estado del proveedor
  Future<Either<Failure, Supplier>> updateSupplierStatus({
    required String id,
    required SupplierStatus status,
  });

  /// Eliminar proveedor (soft delete)
  Future<Either<Failure, Unit>> deleteSupplier(String id);

  /// Restaurar proveedor
  Future<Either<Failure, Supplier>> restoreSupplier(String id);

  // ==================== VALIDATION OPERATIONS ====================

  /// Validar si un documento ya existe
  Future<Either<Failure, bool>> validateDocument({
    required DocumentType documentType,
    required String documentNumber,
    String? excludeId, // Para excluir en edición
  });

  /// Validar si un código ya existe
  Future<Either<Failure, bool>> validateCode({
    required String code,
    String? excludeId,
  });

  /// Validar si un email ya existe
  Future<Either<Failure, bool>> validateEmail({
    required String email,
    String? excludeId,
  });

  /// Verificar si la combinación de documento es única
  Future<Either<Failure, bool>> checkDocumentUniqueness({
    required DocumentType documentType,
    required String documentNumber,
    String? excludeId,
  });

  // ==================== BUSINESS LOGIC OPERATIONS ====================

  /// Verificar si un proveedor puede recibir órdenes de compra
  Future<Either<Failure, bool>> canReceivePurchaseOrders(String supplierId);

  /// Obtener historial de compras con un proveedor
  Future<Either<Failure, double>> getTotalPurchasesAmount(String supplierId);

  /// Obtener última fecha de compra con un proveedor
  Future<Either<Failure, DateTime?>> getLastPurchaseDate(String supplierId);

  // ==================== CACHE OPERATIONS ====================

  /// Obtener proveedores desde cache
  Future<Either<Failure, List<Supplier>>> getCachedSuppliers();

  /// Limpiar cache de proveedores
  Future<Either<Failure, Unit>> clearSupplierCache();
}

// Parámetros para la query de proveedores
class SupplierQueryParams {
  final int page;
  final int limit;
  final String? search;
  final SupplierStatus? status;
  final DocumentType? documentType;
  final String? currency;
  final bool? hasEmail;
  final bool? hasPhone;
  final bool? hasCreditLimit;
  final bool? hasDiscount;
  final String? sortBy;
  final String? sortOrder;

  const SupplierQueryParams({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.status,
    this.documentType,
    this.currency,
    this.hasEmail,
    this.hasPhone,
    this.hasCreditLimit,
    this.hasDiscount,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'page': page,
      'limit': limit,
    };

    if (search != null && search!.isNotEmpty) data['search'] = search;
    if (status != null) data['status'] = status!.name;
    if (documentType != null) data['documentType'] = documentType!.name;
    if (currency != null) data['currency'] = currency;
    if (hasEmail != null) data['hasEmail'] = hasEmail;
    if (hasPhone != null) data['hasPhone'] = hasPhone;
    if (hasCreditLimit != null) data['hasCreditLimit'] = hasCreditLimit;
    if (hasDiscount != null) data['hasDiscount'] = hasDiscount;
    if (sortBy != null) data['sortBy'] = sortBy;
    if (sortOrder != null) data['sortOrder'] = sortOrder;

    return data;
  }
}