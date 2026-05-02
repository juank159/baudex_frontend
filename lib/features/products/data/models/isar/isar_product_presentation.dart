// lib/features/products/data/models/isar/isar_product_presentation.dart
import 'dart:convert';
import 'package:isar/isar.dart';
import '../../../domain/entities/product_presentation.dart';
import '../product_presentation_model.dart';

part 'isar_product_presentation.g.dart';

@collection
class IsarProductPresentation {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String productId;

  late String name;
  late double factor;
  late double price;
  late String currency;
  String? barcode;
  String? sku;
  late bool isDefault;
  late bool isActive;
  late int sortOrder;

  late DateTime createdAt;
  late DateTime updatedAt;

  // Sync fields
  late bool isSynced;
  DateTime? lastSyncAt;
  late int version;

  // Extra fields stored as JSON (extensible)
  String? metadataJson;

  IsarProductPresentation();

  IsarProductPresentation.create({
    required this.serverId,
    required this.productId,
    required this.name,
    required this.factor,
    required this.price,
    this.currency = 'COP',
    this.barcode,
    this.sku,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.version = 0,
    this.metadataJson,
  });

  static IsarProductPresentation fromModel(ProductPresentationModel model) {
    return IsarProductPresentation.create(
      serverId: model.id,
      productId: model.productId,
      name: model.name,
      factor: model.factor,
      price: model.price,
      currency: model.currency,
      barcode: model.barcode,
      sku: model.sku,
      isDefault: model.isDefault,
      isActive: model.isActive,
      sortOrder: model.sortOrder,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  static IsarProductPresentation fromEntity(ProductPresentation entity) {
    return IsarProductPresentation.create(
      serverId: entity.id,
      productId: entity.productId,
      name: entity.name,
      factor: entity.factor,
      price: entity.price,
      currency: entity.currency,
      barcode: entity.barcode,
      sku: entity.sku,
      isDefault: entity.isDefault,
      isActive: entity.isActive,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  ProductPresentation toEntity() {
    return ProductPresentation(
      id: serverId,
      productId: productId,
      name: name,
      factor: factor,
      price: price,
      currency: currency,
      barcode: barcode,
      sku: sku,
      isDefault: isDefault,
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void incrementVersion() {
    version++;
    isSynced = false;
  }

  // Encode/decode metadataJson helpers
  static String encodeMetadata(Map<String, dynamic> data) {
    try {
      return jsonEncode(data);
    } catch (_) {
      return '{}';
    }
  }

  static Map<String, dynamic> decodeMetadata(String? json) {
    if (json == null || json.isEmpty || json == '{}') return {};
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }
}
