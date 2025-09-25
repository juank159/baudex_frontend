// lib/features/categories/data/models/isar/isar_category_working.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
// import 'package:isar/isar.dart'; // Comentado temporalmente hasta resolver problema ISAR

// part 'isar_category_working.g.dart'; // Comentado temporalmente hasta resolver problema ISAR

// @collection // Comentado temporalmente hasta resolver problema ISAR
class IsarCategoryWorking {
  // Id id = Isar.autoIncrement; // Comentado temporalmente
  int id = 0;

  // @Index(unique: true) // Comentado temporalmente
  late String serverId;

  // @Index() // Comentado temporalmente
  late String name;

  String? description;

  // @Index(unique: true) // Comentado temporalmente
  late String slug;

  String? image;

  // @Enumerated(EnumType.name) // Comentado temporalmente
  late IsarCategoryStatus status;

  late int sortOrder;
  String? parentId;
  int? productsCount;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Constructores
  IsarCategoryWorking();

  IsarCategoryWorking.create({
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
  });

  // Mappers
  static IsarCategoryWorking fromEntity(Category entity) {
    return IsarCategoryWorking.create(
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
      isSynced: true,
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

  @override
  String toString() {
    return 'IsarCategoryWorking{serverId: $serverId, name: $name, slug: $slug, parentId: $parentId, isSynced: $isSynced}';
  }
}