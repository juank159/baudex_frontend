// lib/features/settings/domain/entities/create_organization_request.dart
import 'package:equatable/equatable.dart';

class CreateOrganizationRequest extends Equatable {
  final String name;
  final String slug;
  final String? domain;
  final String? logo;
  final Map<String, dynamic>? settings;
  final String subscriptionPlan;
  final String currency;
  final String locale;
  final String timezone;

  const CreateOrganizationRequest({
    required this.name,
    required this.slug,
    this.domain,
    this.logo,
    this.settings,
    this.subscriptionPlan = 'free',
    this.currency = 'EUR',
    this.locale = 'es',
    this.timezone = 'Europe/Madrid',
  });

  @override
  List<Object?> get props => [
        name,
        slug,
        domain,
        logo,
        settings,
        subscriptionPlan,
        currency,
        locale,
        timezone,
      ];
}