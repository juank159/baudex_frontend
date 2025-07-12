// lib/features/categories/data/models/create_category_request_model.dart
import '../../domain/entities/category.dart';

class CreateCategoryRequestModel {
  final String name;
  final String? description;
  final String slug;
  final String? image;
  final String? status;
  final int? sortOrder;
  final String? parentId;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;

  const CreateCategoryRequestModel({
    required this.name,
    this.description,
    required this.slug,
    this.image,
    this.status,
    this.sortOrder,
    this.parentId,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
  });

  factory CreateCategoryRequestModel.fromParams({
    required String name,
    String? description,
    required String slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
    String? metaTitle,
    String? metaDescription,
    String? metaKeywords,
  }) {
    return CreateCategoryRequestModel(
      name: name,
      description: description,
      slug: slug,
      image: image,
      status: status?.name,
      sortOrder: sortOrder,
      parentId: parentId,
      metaTitle: metaTitle,
      metaDescription: metaDescription,
      metaKeywords: metaKeywords,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'name': name, 'slug': slug};

    if (description != null) json['description'] = description;
    if (image != null) json['image'] = image;
    if (status != null) json['status'] = status;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (parentId != null) json['parentId'] = parentId;
    if (metaTitle != null) json['metaTitle'] = metaTitle;
    if (metaDescription != null) json['metaDescription'] = metaDescription;
    if (metaKeywords != null) json['metaKeywords'] = metaKeywords;

    return json;
  }

  @override
  String toString() => 'CreateCategoryRequestModel(name: $name, slug: $slug)';
}
