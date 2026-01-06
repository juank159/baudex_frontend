// lib/features/categories/data/models/isar/isar_category.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:isar/isar.dart';

part 'isar_category.g.dart';

@collection
class IsarCategory {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String name;

  String? description;

  @Index(unique: true)
  late String slug;

  String? image;

  @Enumerated(EnumType.name)
  late IsarCategoryStatus status;

  late int sortOrder;

  @Index()
  String? parentId;

  int? productsCount;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // ⭐ FASE 1: Campos de versionamiento para detección de conflictos
  late int version;
  DateTime? lastModifiedAt;
  String? lastModifiedBy;

  // Constructores
  IsarCategory();

  IsarCategory.create({
    required this.serverId,
    required this.name,
    this.description,
    required this.slug,
    this.image,
    required this.status,
    required this.sortOrder,
    this.parentId,
    this.productsCount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
    this.version = 0,
    this.lastModifiedAt,
    this.lastModifiedBy,
  });

  // Mappers
  static IsarCategory fromEntity(Category entity) {
    return IsarCategory.create(
      serverId: entity.id,
      name: entity.name,
      description: entity.description,
      slug: entity.slug,
      image: entity.image,
      status: _mapCategoryStatus(entity.status),
      sortOrder: entity.sortOrder,
      parentId: entity.parentId,
      productsCount: entity.productsCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: entity.isSynced,
      lastSyncAt: entity.lastSyncAt,
    );
  }

  static IsarCategory fromModel(dynamic model) {
    return IsarCategory.create(
      serverId: model.id,
      name: model.name,
      description: model.description,
      slug: model.slug,
      image: model.image,
      status: _mapCategoryStatus(model.status),
      sortOrder: model.sortOrder,
      parentId: model.parentId,
      productsCount: model.productsCount,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      deletedAt: model.deletedAt,
      isSynced: true, // Model from server is synced by default
      lastSyncAt: DateTime.now(),
    );
  }

  Category toEntity() {
    return Category(
      id: serverId,
      name: name,
      description: description,
      slug: slug,
      image: image,
      status: _mapIsarCategoryStatus(status),
      sortOrder: sortOrder,
      parentId: parentId,
      productsCount: productsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      isSynced: isSynced,
      lastSyncAt: lastSyncAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarCategoryStatus _mapCategoryStatus(CategoryStatus status) {
    switch (status) {
      case CategoryStatus.active:
        return IsarCategoryStatus.active;
      case CategoryStatus.inactive:
        return IsarCategoryStatus.inactive;
    }
  }

  static CategoryStatus _mapIsarCategoryStatus(IsarCategoryStatus status) {
    switch (status) {
      case IsarCategoryStatus.active:
        return CategoryStatus.active;
      case IsarCategoryStatus.inactive:
        return CategoryStatus.inactive;
    }
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get isActive => status == IsarCategoryStatus.active && !isDeleted;
  bool get needsSync => !isSynced;
  bool get isRoot => parentId == null;
  bool get hasProducts => productsCount != null && productsCount! > 0;

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

  void updateProductCount(int newCount) {
    productsCount = newCount;
    markAsUnsynced();
  }

  void updateFromModel(dynamic model) {
    serverId = model.id;
    name = model.name;
    description = model.description;
    slug = model.slug;
    image = model.image;
    status = _mapCategoryStatus(model.status);
    sortOrder = model.sortOrder;
    parentId = model.parentId;
    productsCount = model.productsCount;
    createdAt = model.createdAt;
    updatedAt = model.updatedAt;
    deletedAt = model.deletedAt;
    isSynced = true; // Updated from server means it's synced
    lastSyncAt = DateTime.now();

    // ⭐ FASE 1: Incrementar versión al actualizar desde servidor
    incrementVersion(modifiedBy: 'server');
  }

  // ⭐ FASE 1: Métodos de versionamiento y detección de conflictos
  void incrementVersion({String? modifiedBy}) {
    version++;
    lastModifiedAt = DateTime.now();
    if (modifiedBy != null) {
      lastModifiedBy = modifiedBy;
    }
    isSynced = false;
  }

  bool hasConflictWith(IsarCategory serverVersion) {
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
    return 'IsarCategory{serverId: $serverId, name: $name, slug: $slug, parentId: $parentId, version: $version, isSynced: $isSynced}';
  }
}
