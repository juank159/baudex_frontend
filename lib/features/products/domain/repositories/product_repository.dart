// lib/features/products/domain/repositories/product_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/product.dart';
import '../entities/product_price.dart';
import '../entities/product_stats.dart';

abstract class ProductRepository {
  // ==================== READ OPERATIONS ====================

  /// Obtener productos con paginación y filtros
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
  });

  /// Obtener producto por ID
  Future<Either<Failure, Product>> getProductById(String id);

  /// Obtener producto por SKU
  Future<Either<Failure, Product>> getProductBySku(String sku);

  /// Obtener producto por código de barras
  Future<Either<Failure, Product>> getProductByBarcode(String barcode);

  /// Buscar productos por SKU o código de barras
  Future<Either<Failure, Product>> findBySkuOrBarcode(String code);

  /// Buscar productos por término
  Future<Either<Failure, List<Product>>> searchProducts(
    String searchTerm, {
    int limit = 10,
  });

  /// Obtener productos con stock bajo
  Future<Either<Failure, List<Product>>> getLowStockProducts();

  /// Obtener productos sin stock
  Future<Either<Failure, List<Product>>> getOutOfStockProducts();

  /// Obtener productos por categoría
  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categoryId,
  );

  /// Obtener estadísticas de productos
  Future<Either<Failure, ProductStats>> getProductStats();

  /// Obtener valor del inventario
  Future<Either<Failure, double>> getInventoryValue();

  // ==================== WRITE OPERATIONS ====================

  /// Crear producto
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
  });

  /// Actualizar producto
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
    List<CreateProductPriceParams>? prices, // <-- Añadido
  });

  /// Actualizar estado del producto
  Future<Either<Failure, Product>> updateProductStatus({
    required String id,
    required ProductStatus status,
  });

  /// Actualizar stock del producto
  Future<Either<Failure, Product>> updateProductStock({
    required String id,
    required double quantity,
    String operation = 'subtract', // 'add' or 'subtract'
  });

  /// Eliminar producto (soft delete)
  Future<Either<Failure, Unit>> deleteProduct(String id);

  /// Restaurar producto
  Future<Either<Failure, Product>> restoreProduct(String id);

  // ==================== STOCK OPERATIONS ====================

  /// Validar stock para venta
  Future<Either<Failure, bool>> validateStockForSale({
    required String productId,
    required double quantity,
  });

  /// Reducir stock por venta
  Future<Either<Failure, Unit>> reduceStockForSale({
    required String productId,
    required double quantity,
  });

  // ==================== PRICE OPERATIONS ====================

  /// Obtener producto con precio específico
  Future<Either<Failure, Product>> getProductWithPrice({
    required String productId,
    PriceType priceType = PriceType.price1,
  });

  // ==================== CACHE OPERATIONS ====================

  /// Obtener productos desde cache
  Future<Either<Failure, List<Product>>> getCachedProducts();

  /// Limpiar cache de productos
  Future<Either<Failure, Unit>> clearProductCache();
}

// Parámetros para crear precios
class CreateProductPriceParams {
  final PriceType type;
  final String? name;
  final double amount;
  final String? currency;
  final double? discountPercentage;
  final double? discountAmount;
  final double? minQuantity;
  final String? notes;

  const CreateProductPriceParams({
    required this.type,
    this.name,
    required this.amount,
    this.currency,
    this.discountPercentage,
    this.discountAmount,
    this.minQuantity,
    this.notes,
  });
}
