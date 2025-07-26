// lib/features/settings/data/models/create_organization_request_model.dart
import '../../domain/entities/create_organization_request.dart';

class CreateOrganizationRequestModel extends CreateOrganizationRequest {
  const CreateOrganizationRequestModel({
    required super.name,
    required super.slug,
    super.domain,
    super.logo,
    super.settings,
    super.subscriptionPlan,
    super.currency,
    super.locale,
    super.timezone,
  });

  factory CreateOrganizationRequestModel.fromEntity(CreateOrganizationRequest entity) {
    return CreateOrganizationRequestModel(
      name: entity.name,
      slug: entity.slug,
      domain: entity.domain,
      logo: entity.logo,
      settings: entity.settings,
      subscriptionPlan: entity.subscriptionPlan,
      currency: entity.currency,
      locale: entity.locale,
      timezone: entity.timezone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      if (domain != null) 'domain': domain,
      if (logo != null) 'logo': logo,
      if (settings != null) 'settings': settings,
      'subscriptionPlan': subscriptionPlan,
      'currency': currency,
      'locale': locale,
      'timezone': timezone,
      'isActive': true, // Por defecto, nueva organización activa
    };
  }
}