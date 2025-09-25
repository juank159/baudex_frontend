// lib/features/products/data/models/isar/isar_product.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:isar/isar.dart';
import 'isar_product_price.dart';

part 'isar_product.g.dart';

@collection
class IsarProduct {
  Id id = Isar.autoIncrement; // Auto-increment ID para ISAR

  @Index(unique: true)
  late String serverId; // ID del servidor (UUID)

  @Index()
  late String name;

  String? description;

  @Index(unique: true)
  late String sku;

  @Index()
  String? barcode;

  @Enumerated(EnumType.name)
  late IsarProductType type;

  @Enumerated(EnumType.name)
  late IsarProductStatus status;

  late double stock;
  late double minStock;

  String? unit;

  // Dimensiones físicas
  double? weight;
  double? length;
  double? width;
  double? height;

  // Lista de URLs de imágenes
  List<String>? images;

  // Metadatos como JSON string
  String? metadataJson;

  // Foreign Keys
  @Index()
  late String categoryId;

  String? createdById;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Relación con precios (embedded)
  List<IsarProductPrice> prices = [];

  // Constructores
  IsarProduct();

  IsarProduct.create({
    required this.serverId,
    required this.name,
    this.description,
    required this.sku,
    this.barcode,
    required this.type,
    required this.status,
    required this.stock,
    required this.minStock,
    this.unit,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.images,
    this.metadataJson,
    required this.categoryId,
    this.createdById,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.prices = const [],
  });

  // Mappers
  static IsarProduct fromEntity(Product entity) {
    return IsarProduct.create(
      serverId: entity.id,
      name: entity.name,
      description: entity.description,
      sku: entity.sku,
      barcode: entity.barcode,
      type: _mapProductType(entity.type),
      status: _mapProductStatus(entity.status),
      stock: entity.stock,
      minStock: entity.minStock,
      unit: entity.unit,
      weight: entity.weight,
      length: entity.length,
      width: entity.width,
      height: entity.height,
      images: entity.images,
      metadataJson:
          entity.metadata != null ? _encodeMetadata(entity.metadata!) : null,
      categoryId: entity.categoryId,
      createdById: entity.createdById,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      // deletedAt: entity.deletedAt, // Comentado porque Product no tiene este campo
      isSynced: true, // Asumimos que viene del servidor sincronizado
      lastSyncAt: DateTime.now(),
      prices:
          entity.prices?.map((p) => IsarProductPrice.fromEntity(p)).toList() ??
          [],
    );
  }

  Product toEntity() {
    return Product(
      id: serverId,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      type: _mapIsarProductType(type),
      status: _mapIsarProductStatus(status),
      stock: stock,
      minStock: minStock,
      unit: unit,
      weight: weight,
      length: length,
      width: width,
      height: height,
      images: images,
      metadata: metadataJson != null ? _decodeMetadata(metadataJson!) : null,
      categoryId: categoryId,
      createdById: createdById ?? '',
      prices: prices.map((p) => p.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      // deletedAt: deletedAt, // Comentado porque Product no tiene este campo
    );
  }

  // Helpers para mapeo de enums
  static IsarProductType _mapProductType(ProductType type) {
    switch (type) {
      case ProductType.product:
        return IsarProductType.product;
      case ProductType.service:
        return IsarProductType.service;
    }
  }

  static ProductType _mapIsarProductType(IsarProductType type) {
    switch (type) {
      case IsarProductType.product:
        return ProductType.product;
      case IsarProductType.service:
        return ProductType.service;
    }
  }

  static IsarProductStatus _mapProductStatus(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return IsarProductStatus.active;
      case ProductStatus.inactive:
        return IsarProductStatus.inactive;
      case ProductStatus.outOfStock:
        return IsarProductStatus.outOfStock;
    }
  }

  static ProductStatus _mapIsarProductStatus(IsarProductStatus status) {
    switch (status) {
      case IsarProductStatus.active:
        return ProductStatus.active;
      case IsarProductStatus.inactive:
        return ProductStatus.inactive;
      case IsarProductStatus.outOfStock:
        return ProductStatus.outOfStock;
    }
  }

  // Helpers para metadatos
  static String _encodeMetadata(Map<String, dynamic> metadata) {
    // En un proyecto real, usarías json.encode aquí
    // Para simplicidad, asumimos que ya viene como string
    return metadata.toString();
  }

  static Map<String, dynamic> _decodeMetadata(String metadataJson) {
    // En un proyecto real, usarías json.decode aquí
    // Para simplicidad, retornamos un mapa vacío
    return {};
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get isActive => status == IsarProductStatus.active && !isDeleted;
  bool get isLowStock => stock <= minStock;
  bool get needsSync => !isSynced;

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void softDelete() {
    deletedAt = DateTime.now();
    markAsUnsynced();
  }

  @override
  String toString() {
    return 'IsarProduct{serverId: $serverId, name: $name, sku: $sku, isSynced: $isSynced}';
  }
}
