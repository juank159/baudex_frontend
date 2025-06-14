// lib/features/categories/data/models/update_category_request_model.dart
import '../../domain/entities/category.dart';

class UpdateCategoryRequestModel {
  final String? name;
  final String? description;
  final String? slug;
  final String? image;
  final String? status;
  final int? sortOrder;
  final String? parentId;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;
  final String? updateReason;

  const UpdateCategoryRequestModel({
    this.name,
    this.description,
    this.slug,
    this.image,
    this.status,
    this.sortOrder,
    this.parentId,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.updateReason,
  });

  factory UpdateCategoryRequestModel.fromParams({
    String? name,
    String? description,
    String? slug,
    String? image,
    CategoryStatus? status,
    int? sortOrder,
    String? parentId,
    String? metaTitle,
    String? metaDescription,
    String? metaKeywords,
    String? updateReason,
  }) {
    return UpdateCategoryRequestModel(
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
      updateReason: updateReason,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (slug != null) json['slug'] = slug;
    if (image != null) json['image'] = image;
    if (status != null) json['status'] = status;
    if (sortOrder != null) json['sortOrder'] = sortOrder;
    if (parentId != null) json['parentId'] = parentId;
    if (metaTitle != null) json['metaTitle'] = metaTitle;
    if (metaDescription != null) json['metaDescription'] = metaDescription;
    if (metaKeywords != null) json['metaKeywords'] = metaKeywords;
    if (updateReason != null) json['updateReason'] = updateReason;

    return json;
  }

  /// Verificar si hay cambios para actualizar
  bool get hasUpdates {
    return name != null ||
        description != null ||
        slug != null ||
        image != null ||
        status != null ||
        sortOrder != null ||
        parentId != null ||
        metaTitle != null ||
        metaDescription != null ||
        metaKeywords != null;
  }

  @override
  String toString() => 'UpdateCategoryRequestModel(hasUpdates: $hasUpdates)';
}
