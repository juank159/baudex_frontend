// // lib/features/categories/domain/entities/category_tree.dart
// import 'package:equatable/equatable.dart';
// import 'category.dart';

// class CategoryTree extends Equatable {
//   final String id;
//   final String name;
//   final String slug;
//   final String? image;
//   final int sortOrder;
//   final List<CategoryTree>? children;
//   final int? productsCount;
//   final int level;
//   final bool hasChildren;

//   const CategoryTree({
//     required this.id,
//     required this.name,
//     required this.slug,
//     this.image,
//     required this.sortOrder,
//     this.children,
//     this.productsCount,
//     required this.level,
//     required this.hasChildren,
//   });

//   factory CategoryTree.fromCategory(Category category) {
//     return CategoryTree(
//       id: category.id,
//       name: category.name,
//       slug: category.slug,
//       image: category.image,
//       sortOrder: category.sortOrder,
//       children:
//           category.children
//               ?.map((child) => CategoryTree.fromCategory(child))
//               .toList(),
//       productsCount: category.productsCount,
//       level: category.level,
//       hasChildren: category.isParent,
//     );
//   }

//   @override
//   List<Object?> get props => [
//     id,
//     name,
//     slug,
//     image,
//     sortOrder,
//     children?.map((c) => c.id).toList(),
//     productsCount,
//     level,
//     hasChildren,
//   ];
// }

// lib/features/categories/domain/entities/category_tree.dart
import 'package:equatable/equatable.dart';
import 'category.dart';

class CategoryTree extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? image;
  final int sortOrder;
  final List<CategoryTree>? children;
  final int? productsCount;
  final int level;
  final bool hasChildren;

  const CategoryTree({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    required this.sortOrder,
    this.children,
    this.productsCount,
    required this.level,
    required this.hasChildren,
  });

  factory CategoryTree.fromCategory(Category category) {
    return CategoryTree(
      id: category.id,
      name: category.name,
      slug: category.slug,
      image: category.image,
      sortOrder: category.sortOrder,
      children:
          category.children
              ?.map((child) => CategoryTree.fromCategory(child))
              .toList(),
      productsCount: category.productsCount,
      level: category.level,
      hasChildren: category.isParent,
    );
  }

  // ✅ NUEVO: Factory constructor fromJson
  factory CategoryTree.fromJson(Map<String, dynamic> json) {

    // ✅ Procesar children de forma segura
    List<CategoryTree>? children;
    final childrenJson = json['children'];

    if (childrenJson != null &&
        childrenJson is List &&
        childrenJson.isNotEmpty) {
      children =
          childrenJson
              .map(
                (childJson) =>
                    CategoryTree.fromJson(childJson as Map<String, dynamic>),
              )
              .toList();
    }

    // ✅ Calcular level basado en la jerarquía o usar el del JSON
    int level = 0;
    if (json['level'] != null) {
      level = (json['level'] as num).toInt();
    }

    // ✅ Determinar hasChildren
    final hasChildren = children?.isNotEmpty ?? false;

    final categoryTree = CategoryTree(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      image: json['image'] as String?, // ✅ Puede ser null
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      children: children,
      productsCount:
          (json['productsCount'] as num?)?.toInt(), // ✅ Puede ser null
      level: level,
      hasChildren: hasChildren,
    );

    return categoryTree;
  }

  // ✅ NUEVO: Método toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'sortOrder': sortOrder,
      'children': children?.map((child) => child.toJson()).toList(),
      'productsCount': productsCount,
      'level': level,
      'hasChildren': hasChildren,
    };
  }

  // ✅ NUEVO: Método copyWith
  CategoryTree copyWith({
    String? id,
    String? name,
    String? slug,
    String? image,
    int? sortOrder,
    List<CategoryTree>? children,
    int? productsCount,
    int? level,
    bool? hasChildren,
  }) {
    return CategoryTree(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      image: image ?? this.image,
      sortOrder: sortOrder ?? this.sortOrder,
      children: children ?? this.children,
      productsCount: productsCount ?? this.productsCount,
      level: level ?? this.level,
      hasChildren: hasChildren ?? this.hasChildren,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    image,
    sortOrder,
    children?.map((c) => c.id).toList(),
    productsCount,
    level,
    hasChildren,
  ];

  @override
  String toString() {
    return 'CategoryTree(id: $id, name: $name, slug: $slug, level: $level, hasChildren: $hasChildren, children: ${children?.length ?? 0})';
  }
}
