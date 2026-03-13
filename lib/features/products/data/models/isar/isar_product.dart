// lib/features/products/data/models/isar/isar_product.dart
import 'dart:convert';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/products/domain/entities/product.dart';
import 'package:baudex_desktop/features/products/domain/entities/tax_enums.dart';
import 'package:baudex_desktop/features/products/data/models/product_model.dart';
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

  // ⭐ FASE 1: Campos de versionamiento para detección de conflictos
  late int version; // Versión del documento (incrementa con cada cambio)
  DateTime? lastModifiedAt; // Timestamp del último cambio
  String? lastModifiedBy; // Usuario que hizo el último cambio

  // Campos fiscales
  @Enumerated(EnumType.name)
  late IsarTaxCategory taxCategory;
  late double taxRate;
  late bool isTaxable;
  String? taxDescription;
  @Enumerated(EnumType.name)
  IsarRetentionCategory? retentionCategory;
  double? retentionRate;
  late bool hasRetention;

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
    this.version = 0, // ⭐ Inicializar versión en 0
    this.lastModifiedAt,
    this.lastModifiedBy,
    this.prices = const [],
    this.taxCategory = IsarTaxCategory.iva,
    this.taxRate = 19.0,
    this.isTaxable = true,
    this.taxDescription,
    this.retentionCategory,
    this.retentionRate,
    this.hasRetention = false,
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
      taxCategory: _mapTaxCategory(entity.taxCategory),
      taxRate: entity.taxRate,
      isTaxable: entity.isTaxable,
      taxDescription: entity.taxDescription,
      retentionCategory: _mapRetentionCategory(entity.retentionCategory),
      retentionRate: entity.retentionRate,
      hasRetention: entity.hasRetention,
    );
  }

  /// Crea un IsarProduct desde un ProductModel (respuesta del servidor)
  static IsarProduct fromModel(ProductModel model) {
    return IsarProduct.create(
      serverId: model.id,
      name: model.name,
      description: model.description,
      sku: model.sku,
      barcode: model.barcode,
      type: _mapProductTypeFromString(model.type),
      status: _mapProductStatusFromString(model.status),
      stock: model.stock,
      minStock: model.minStock,
      unit: model.unit,
      weight: model.weight,
      length: model.length,
      width: model.width,
      height: model.height,
      images: model.images,
      metadataJson:
          model.metadata != null ? _encodeMetadata(model.metadata!) : null,
      categoryId: model.categoryId,
      createdById: model.createdById,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
      prices:
          model.prices?.map((p) => IsarProductPrice.fromModel(p)).toList() ??
          [],
      taxCategory: mapTaxCategoryFromString(model.taxCategory),
      taxRate: model.taxRate,
      isTaxable: model.isTaxable,
      taxDescription: model.taxDescription,
      retentionCategory: _mapRetentionCategoryFromString(model.retentionCategory),
      retentionRate: model.retentionRate,
      hasRetention: model.hasRetention,
    );
  }

  /// Mapea string de tipo de producto a enum ISAR
  static IsarProductType _mapProductTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return IsarProductType.service;
      case 'product':
      default:
        return IsarProductType.product;
    }
  }

  /// Mapea string de estado de producto a enum ISAR
  static IsarProductStatus _mapProductStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'inactive':
        return IsarProductStatus.inactive;
      case 'out_of_stock':
      case 'outofstock':
        return IsarProductStatus.outOfStock;
      case 'active':
      default:
        return IsarProductStatus.active;
    }
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
      taxCategory: _mapIsarTaxCategory(taxCategory),
      taxRate: taxRate.isNaN ? _mapIsarTaxCategory(taxCategory).defaultRate : taxRate,
      isTaxable: isTaxable,
      taxDescription: taxDescription,
      retentionCategory: _mapIsarRetentionCategory(retentionCategory),
      retentionRate: (retentionRate != null && retentionRate!.isNaN) ? null : retentionRate,
      hasRetention: hasRetention,
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

  // Helpers para mapeo de TaxCategory
  static IsarTaxCategory _mapTaxCategory(TaxCategory category) {
    switch (category) {
      case TaxCategory.iva:
        return IsarTaxCategory.iva;
      case TaxCategory.inc:
        return IsarTaxCategory.inc;
      case TaxCategory.incBolsa:
        return IsarTaxCategory.incBolsa;
      case TaxCategory.exento:
        return IsarTaxCategory.exento;
      case TaxCategory.noGravado:
        return IsarTaxCategory.noGravado;
    }
  }

  static TaxCategory _mapIsarTaxCategory(IsarTaxCategory category) {
    switch (category) {
      case IsarTaxCategory.iva:
        return TaxCategory.iva;
      case IsarTaxCategory.inc:
        return TaxCategory.inc;
      case IsarTaxCategory.incBolsa:
        return TaxCategory.incBolsa;
      case IsarTaxCategory.exento:
        return TaxCategory.exento;
      case IsarTaxCategory.noGravado:
        return TaxCategory.noGravado;
    }
  }

  static IsarTaxCategory mapTaxCategoryFromString(String value) {
    switch (value.toUpperCase()) {
      case 'INC':
        return IsarTaxCategory.inc;
      case 'INC_BOLSA':
        return IsarTaxCategory.incBolsa;
      case 'EXENTO':
        return IsarTaxCategory.exento;
      case 'NO_GRAVADO':
        return IsarTaxCategory.noGravado;
      case 'IVA':
      default:
        return IsarTaxCategory.iva;
    }
  }

  static String mapIsarTaxCategoryToString(IsarTaxCategory category) {
    switch (category) {
      case IsarTaxCategory.iva:
        return 'IVA';
      case IsarTaxCategory.inc:
        return 'INC';
      case IsarTaxCategory.incBolsa:
        return 'INC_BOLSA';
      case IsarTaxCategory.exento:
        return 'EXENTO';
      case IsarTaxCategory.noGravado:
        return 'NO_GRAVADO';
    }
  }

  // Helpers para mapeo de RetentionCategory
  static IsarRetentionCategory? _mapRetentionCategory(RetentionCategory? category) {
    if (category == null) return null;
    switch (category) {
      case RetentionCategory.retIva:
        return IsarRetentionCategory.retIva;
      case RetentionCategory.retRenta:
        return IsarRetentionCategory.retRenta;
      case RetentionCategory.retIca:
        return IsarRetentionCategory.retIca;
      case RetentionCategory.retCree:
        return IsarRetentionCategory.retCree;
    }
  }

  static RetentionCategory? _mapIsarRetentionCategory(IsarRetentionCategory? category) {
    if (category == null) return null;
    switch (category) {
      case IsarRetentionCategory.retIva:
        return RetentionCategory.retIva;
      case IsarRetentionCategory.retRenta:
        return RetentionCategory.retRenta;
      case IsarRetentionCategory.retIca:
        return RetentionCategory.retIca;
      case IsarRetentionCategory.retCree:
        return RetentionCategory.retCree;
    }
  }

  static IsarRetentionCategory? _mapRetentionCategoryFromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'RET_IVA':
        return IsarRetentionCategory.retIva;
      case 'RET_RENTA':
        return IsarRetentionCategory.retRenta;
      case 'RET_ICA':
        return IsarRetentionCategory.retIca;
      case 'RET_CREE':
        return IsarRetentionCategory.retCree;
      default:
        return null;
    }
  }

  // Helpers para metadatos
  static String _encodeMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null || metadata.isEmpty) return '{}';
    try {
      return jsonEncode(metadata);
    } catch (e) {
      return '{}';
    }
  }

  static Map<String, dynamic> _decodeMetadata(String? metadataJson) {
    if (metadataJson == null || metadataJson.isEmpty || metadataJson == '{}') {
      return {};
    }
    try {
      final decoded = jsonDecode(metadataJson);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (e) {
      return {};
    }
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

  // ⭐ FASE 1: Métodos de versionamiento y detección de conflictos

  /// Incrementa la versión del documento y marca timestamp de modificación
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  /// Detecta si hay conflicto con otra versión del mismo documento
  bool hasConflictWith(IsarProduct serverVersion) {
    if (version == serverVersion.version &&
        lastModifiedAt != null &&
        serverVersion.lastModifiedAt != null &&
        lastModifiedAt != serverVersion.lastModifiedAt) {
      return true;
    }

    if (version > serverVersion.version) {
      return true;
    }

    return false;
  }

  @override
  String toString() {
    return 'IsarProduct{serverId: $serverId, name: $name, sku: $sku, version: $version, isSynced: $isSynced}';
  }
}
