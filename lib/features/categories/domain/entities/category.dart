// lib/features/categories/domain/entities/category.dart
import 'package:equatable/equatable.dart';

enum CategoryStatus { active, inactive }

class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String slug;
  final String? image;
  final CategoryStatus status;
  final int sortOrder;
  final String? parentId;
  final Category? parent;
  final List<Category>? children;
  final int? productsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    required this.slug,
    this.image,
    required this.status,
    required this.sortOrder,
    this.parentId,
    this.parent,
    this.children,
    this.productsCount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Computed properties
  bool get isActive => status == CategoryStatus.active && deletedAt == null;
  bool get isParent => children != null && children!.isNotEmpty;

  int get level {
    int levelCount = 0;
    Category? current = parent;
    while (current != null) {
      levelCount++;
      current = current.parent;
    }
    return levelCount;
  }

  String get fullPath {
    final path = <String>[];
    Category? current = this;

    while (current != null) {
      path.insert(0, current.name);
      current = current.parent;
    }

    return path.join(' > ');
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
    Category? parent,
    List<Category>? children,
    int? productsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      image: image ?? this.image,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      parentId: parentId ?? this.parentId,
      parent: parent ?? this.parent,
      children: children ?? this.children,
      productsCount: productsCount ?? this.productsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    slug,
    image,
    status,
    sortOrder,
    parentId,
    parent?.id,
    children?.map((c) => c.id).toList(),
    productsCount,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
