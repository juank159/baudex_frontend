// lib/features/categories/data/models/category_model.dart
import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.description,
    required super.slug,
    super.image,
    required super.status,
    required super.sortOrder,
    super.parentId,
    super.parent,
    super.children,
    super.productsCount,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  // factory CategoryModel.fromJson(Map<String, dynamic> json) {
  //   return CategoryModel(
  //     id: json['id'] as String,
  //     name: json['name'] as String,
  //     description: json['description'] as String?,
  //     slug: json['slug'] as String,
  //     image: json['image'] as String?,
  //     status: _parseStatus(json['status']),
  //     sortOrder: json['sortOrder'] as int? ?? 0,
  //     parentId: json['parentId'] as String?,
  //     parent:
  //         json['parent'] != null
  //             ? CategoryModel.fromJson(json['parent'] as Map<String, dynamic>)
  //             : null,
  //     children:
  //         json['children'] != null
  //             ? (json['children'] as List)
  //                 .map(
  //                   (child) =>
  //                       CategoryModel.fromJson(child as Map<String, dynamic>),
  //                 )
  //                 .toList()
  //             : null,
  //     productsCount: json['productsCount'] as int?,
  //     createdAt: DateTime.parse(json['createdAt'] as String),
  //     updatedAt: DateTime.parse(json['updatedAt'] as String),
  //     deletedAt:
  //         json['deletedAt'] != null
  //             ? DateTime.parse(json['deletedAt'] as String)
  //             : null,
  //   );
  // }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    print('🏗️ CategoryModel.fromJson processing: ${json['name']}');
    print('   Available fields: ${json.keys.toList()}');

    try {
      return CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        slug: json['slug'] as String,
        image: json['image'] as String?,
        status: _parseStatus(json['status']), // ✅ Usar método que maneja null
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        parentId: json['parentId'] as String?,
        parent:
            json['parent'] != null
                ? CategoryModel.fromJson(json['parent'] as Map<String, dynamic>)
                : null,
        children:
            json['children'] != null
                ? (json['children'] as List)
                    .map(
                      (child) =>
                          CategoryModel.fromJson(child as Map<String, dynamic>),
                    )
                    .toList()
                : null,
        productsCount: (json['productsCount'] as num?)?.toInt(),
        // ✅ CORRECCIÓN CRÍTICA: Manejar fechas faltantes
        createdAt:
            json['createdAt'] != null
                ? DateTime.parse(json['createdAt'] as String)
                : DateTime.now(), // ✅ Valor por defecto si no está
        updatedAt:
            json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'] as String)
                : DateTime.now(), // ✅ Valor por defecto si no está
        deletedAt:
            json['deletedAt'] != null
                ? DateTime.parse(json['deletedAt'] as String)
                : null,
      );
    } catch (e) {
      print('❌ Error in CategoryModel.fromJson: $e');
      print('   JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'slug': slug,
      'image': image,
      'status': status.name,
      'sortOrder': sortOrder,
      'parentId': parentId,
      'parent': parent != null ? (parent as CategoryModel).toJson() : null,
      'children':
          children?.map((child) => (child as CategoryModel).toJson()).toList(),
      'productsCount': productsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // static CategoryStatus _parseStatus(dynamic status) {
  //   if (status is String) {
  //     switch (status.toLowerCase()) {
  //       case 'active':
  //         return CategoryStatus.active;
  //       case 'inactive':
  //         return CategoryStatus.inactive;
  //       default:
  //         return CategoryStatus.active;
  //     }
  //   }
  //   return CategoryStatus.active;
  // }

  static CategoryStatus _parseStatus(dynamic status) {
    if (status == null) return CategoryStatus.active; // ✅ Default si es null

    if (status is String) {
      switch (status.toLowerCase()) {
        case 'active':
          return CategoryStatus.active;
        case 'inactive':
          return CategoryStatus.inactive;
        default:
          return CategoryStatus.active;
      }
    }
    return CategoryStatus.active;
  }

  Category toEntity() => Category(
    id: id,
    name: name,
    description: description,
    slug: slug,
    image: image,
    status: status,
    sortOrder: sortOrder,
    parentId: parentId,
    parent: parent,
    children: children,
    productsCount: productsCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      slug: category.slug,
      image: category.image,
      status: category.status,
      sortOrder: category.sortOrder,
      parentId: category.parentId,
      parent:
          category.parent != null
              ? CategoryModel.fromEntity(category.parent!)
              : null,
      children:
          category.children
              ?.map((child) => CategoryModel.fromEntity(child))
              .toList(),
      productsCount: category.productsCount,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      deletedAt: category.deletedAt,
    );
  }
}
