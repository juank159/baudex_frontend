// lib/features/settings/data/models/organization_model.dart
import '../../../../app/core/utils/tolerant_json.dart';
import '../../domain/entities/organization.dart';

class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.name,
    required super.slug,
    super.domain,
    super.logo,
    super.settings,
    required super.subscriptionPlan,
    required super.subscriptionStatus,
    required super.isActive,
    required super.currency,
    required super.locale,
    required super.timezone,
    required super.createdAt,
    required super.updatedAt,
    super.defaultProfitMarginPercentage,
    super.multiCurrencyEnabled,
    super.cashRegisterEnabled,
    super.subscriptionStartDate,
    super.subscriptionEndDate,
    super.trialStartDate,
    super.trialEndDate,
    super.hasValidSubscription,
    super.isTrialExpired,
    super.daysUntilExpiration,
    super.isActivePlan,
  });

  /// Lectura tolerante: ningún campo opcional nulo, de otro tipo o con una
  /// fecha rara tumba la lectura del negocio. Lo que no llegó como se
  /// esperaba queda en [issues] (campo y tipo, nunca el valor).
  factory OrganizationModel.fromJson(
    Object? json, {
    List<JsonIssue>? issues,
  }) {
    final r = TolerantJson(json);
    final settings = r.child('settings');
    final now = DateTime.now();
    final model = OrganizationModel(
      id: r.string('id') ?? '',
      name: r.string('name') ?? '',
      slug: r.string('slug') ?? '',
      domain: r.string('domain'),
      logo: r.string('logo'),
      settings: r.object('settings'),
      subscriptionPlan:
          SubscriptionPlan.fromString(r.string('subscriptionPlan') ?? 'trial'),
      subscriptionStatus: SubscriptionStatus.fromString(
          r.string('subscriptionStatus') ?? 'active'),
      isActive: r.boolean('isActive') ?? true,
      currency: r.string('currency') ?? 'EUR',
      locale: r.string('locale') ?? 'es',
      timezone: r.string('timezone') ?? 'Europe/Madrid',
      createdAt: r.date('createdAt') ?? now,
      updatedAt: r.date('updatedAt') ?? now,
      // Extraer margen de ganancia desde settings
      defaultProfitMarginPercentage:
          settings.decimal('defaultProfitMarginPercentage'),
      // settings.multiCurrencyEnabled es la fuente de verdad (es lo que enviamos con PATCH).
      // El campo top-level json['multiCurrencyEnabled'] es computado por el backend y puede estar desactualizado.
      multiCurrencyEnabled: settings.boolean('multiCurrencyEnabled') ??
          r.boolean('multiCurrencyEnabled') ??
          false,
      // Caja registradora — leemos de settings JSONB; default `true` si
      // el campo no existe (organizaciones legacy / clientes existentes
      // ven el módulo activado como hasta hoy).
      cashRegisterEnabled: settings.boolean('cashRegisterEnabled') ?? true,
      subscriptionStartDate: r.date('subscriptionStartDate'),
      subscriptionEndDate: r.date('subscriptionEndDate'),
      trialStartDate: r.date('trialStartDate'),
      trialEndDate: r.date('trialEndDate'),
      hasValidSubscription: r.boolean('hasValidSubscription'),
      isTrialExpired: r.boolean('isTrialExpired'),
      daysUntilExpiration: r.integer('daysUntilExpiration'),
      isActivePlan: r.boolean('isActivePlan'),
    );
    issues?.addAll(r.issues);
    issues?.addAll(settings.issues);
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'domain': domain,
      'logo': logo,
      'settings': settings,
      'subscriptionPlan': subscriptionPlan.value,
      'subscriptionStatus': subscriptionStatus.value,
      'isActive': isActive,
      'currency': currency,
      'locale': locale,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'hasValidSubscription': hasValidSubscription,
      'isTrialExpired': isTrialExpired,
      'daysUntilExpiration': daysUntilExpiration,
      'isActivePlan': isActivePlan,
    };
  }
}