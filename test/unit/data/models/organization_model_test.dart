import 'package:flutter_test/flutter_test.dart';
import 'package:baudex_desktop/features/organizations/data/models/organization_model.dart';
import 'package:baudex_desktop/features/organizations/domain/entities/organization.dart';

void main() {
  group('OrganizationModel', () {
    final tDateTime = DateTime(2024, 1, 1);

    final tOrganizationModel = OrganizationModel(
      id: 'org-001',
      name: 'Test Organization',
      slug: 'test-org',
      domain: 'test.com',
      logo: 'https://test.com/logo.png',
      subscriptionPlan: SubscriptionPlan.premium,
      isActive: true,
      currency: 'USD',
      locale: 'en',
      timezone: 'UTC',
      settings: {'theme': 'dark', 'notifications': true},
      createdAt: tDateTime,
      updatedAt: tDateTime,
      displayName: 'Test Organization Display',
      isActivePlan: true,
    );

    final tJson = {
      'id': 'org-001',
      'name': 'Test Organization',
      'slug': 'test-org',
      'domain': 'test.com',
      'logo': 'https://test.com/logo.png',
      'subscriptionPlan': 'premium',
      'isActive': true,
      'currency': 'USD',
      'locale': 'en',
      'timezone': 'UTC',
      'settings': {'theme': 'dark', 'notifications': true},
      'createdAt': '2024-01-01T00:00:00.000',
      'updatedAt': '2024-01-01T00:00:00.000',
      'displayName': 'Test Organization Display',
      'isActivePlan': true,
    };

    group('fromJson', () {
      test('should create model from complete JSON', () {
        final result = OrganizationModel.fromJson(tJson);

        expect(result.id, equals('org-001'));
        expect(result.name, equals('Test Organization'));
        expect(result.slug, equals('test-org'));
        expect(result.domain, equals('test.com'));
        expect(result.logo, equals('https://test.com/logo.png'));
        expect(result.subscriptionPlan, equals(SubscriptionPlan.premium));
        expect(result.isActive, equals(true));
        expect(result.currency, equals('USD'));
        expect(result.locale, equals('en'));
        expect(result.timezone, equals('UTC'));
        expect(result.settings, equals({'theme': 'dark', 'notifications': true}));
        expect(result.displayName, equals('Test Organization Display'));
        expect(result.isActivePlan, equals(true));
      });

      test('should handle minimal JSON with defaults', () {
        final minimalJson = {
          'id': 'org-002',
          'name': 'Minimal Org',
          'slug': 'minimal-org',
        };

        final result = OrganizationModel.fromJson(minimalJson);

        expect(result.id, equals('org-002'));
        expect(result.name, equals('Minimal Org'));
        expect(result.subscriptionPlan, equals(SubscriptionPlan.basic));
        expect(result.isActive, equals(true));
        expect(result.currency, equals('USD'));
        expect(result.locale, equals('en'));
        expect(result.timezone, equals('UTC'));
        expect(result.settings, equals({}));
        expect(result.displayName, equals('Minimal Org')); // Falls back to name
        expect(result.isActivePlan, equals(true));
      });

      test('should parse basic subscription plan', () {
        final json = {...tJson, 'subscriptionPlan': 'basic'};
        final result = OrganizationModel.fromJson(json);
        expect(result.subscriptionPlan, equals(SubscriptionPlan.basic));
      });

      test('should parse premium subscription plan', () {
        final json = {...tJson, 'subscriptionPlan': 'premium'};
        final result = OrganizationModel.fromJson(json);
        expect(result.subscriptionPlan, equals(SubscriptionPlan.premium));
      });

      test('should parse enterprise subscription plan', () {
        final json = {...tJson, 'subscriptionPlan': 'enterprise'};
        final result = OrganizationModel.fromJson(json);
        expect(result.subscriptionPlan, equals(SubscriptionPlan.enterprise));
      });

      test('should parse subscription plan case-insensitively', () {
        final json = {...tJson, 'subscriptionPlan': 'PREMIUM'};
        final result = OrganizationModel.fromJson(json);
        expect(result.subscriptionPlan, equals(SubscriptionPlan.premium));
      });

      test('should default to basic for invalid subscription plan', () {
        final json = {...tJson, 'subscriptionPlan': 'invalid'};
        final result = OrganizationModel.fromJson(json);
        expect(result.subscriptionPlan, equals(SubscriptionPlan.basic));
      });

      test('should default to basic for null subscription plan', () {
        final json = {...tJson};
        json.remove('subscriptionPlan');
        final result = OrganizationModel.fromJson(json);
        expect(result.subscriptionPlan, equals(SubscriptionPlan.basic));
      });

      test('should handle null domain', () {
        final json = {...tJson};
        json.remove('domain');
        final result = OrganizationModel.fromJson(json);
        expect(result.domain, isNull);
      });

      test('should handle null logo', () {
        final json = {...tJson};
        json.remove('logo');
        final result = OrganizationModel.fromJson(json);
        expect(result.logo, isNull);
      });

      test('should handle null settings with empty map', () {
        final json = {...tJson};
        json.remove('settings');
        final result = OrganizationModel.fromJson(json);
        expect(result.settings, equals({}));
      });
    });

    group('toJson', () {
      test('should convert model to JSON', () {
        final result = tOrganizationModel.toJson();

        expect(result['id'], equals('org-001'));
        expect(result['name'], equals('Test Organization'));
        expect(result['slug'], equals('test-org'));
        expect(result['domain'], equals('test.com'));
        expect(result['logo'], equals('https://test.com/logo.png'));
        expect(result['subscriptionPlan'], equals('premium'));
        expect(result['isActive'], equals(true));
        expect(result['currency'], equals('USD'));
        expect(result['locale'], equals('en'));
        expect(result['timezone'], equals('UTC'));
        expect(result['settings'], equals({'theme': 'dark', 'notifications': true}));
        expect(result['createdAt'], equals('2024-01-01T00:00:00.000'));
        expect(result['updatedAt'], equals('2024-01-01T00:00:00.000'));
        expect(result['displayName'], equals('Test Organization Display'));
        expect(result['isActivePlan'], equals(true));
      });

      test('should convert subscription plans to string names', () {
        final basic = tOrganizationModel.copyWith(subscriptionPlan: SubscriptionPlan.basic);
        expect(basic.toJson()['subscriptionPlan'], equals('basic'));

        final premium = tOrganizationModel.copyWith(subscriptionPlan: SubscriptionPlan.premium);
        expect(premium.toJson()['subscriptionPlan'], equals('premium'));

        final enterprise = tOrganizationModel.copyWith(subscriptionPlan: SubscriptionPlan.enterprise);
        expect(enterprise.toJson()['subscriptionPlan'], equals('enterprise'));
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final entity = tOrganizationModel.toEntity();

        expect(entity, isA<Organization>());
        expect(entity.id, equals(tOrganizationModel.id));
        expect(entity.name, equals(tOrganizationModel.name));
        expect(entity.slug, equals(tOrganizationModel.slug));
        expect(entity.domain, equals(tOrganizationModel.domain));
        expect(entity.logo, equals(tOrganizationModel.logo));
        expect(entity.subscriptionPlan, equals(tOrganizationModel.subscriptionPlan));
        expect(entity.isActive, equals(tOrganizationModel.isActive));
        expect(entity.currency, equals(tOrganizationModel.currency));
        expect(entity.locale, equals(tOrganizationModel.locale));
        expect(entity.timezone, equals(tOrganizationModel.timezone));
        expect(entity.settings, equals(tOrganizationModel.settings));
        expect(entity.createdAt, equals(tOrganizationModel.createdAt));
        expect(entity.updatedAt, equals(tOrganizationModel.updatedAt));
        expect(entity.displayName, equals(tOrganizationModel.displayName));
        expect(entity.isActivePlan, equals(tOrganizationModel.isActivePlan));
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = Organization(
          id: 'org-003',
          name: 'Entity Org',
          slug: 'entity-org',
          domain: 'entity.com',
          logo: 'logo.png',
          subscriptionPlan: SubscriptionPlan.enterprise,
          isActive: true,
          currency: 'EUR',
          locale: 'es',
          timezone: 'Europe/Madrid',
          settings: {'key': 'value'},
          createdAt: tDateTime,
          updatedAt: tDateTime,
          displayName: 'Entity Display',
          isActivePlan: true,
        );

        final model = OrganizationModel.fromEntity(entity);

        expect(model, isA<OrganizationModel>());
        expect(model.id, equals(entity.id));
        expect(model.name, equals(entity.name));
        expect(model.slug, equals(entity.slug));
        expect(model.domain, equals(entity.domain));
        expect(model.logo, equals(entity.logo));
        expect(model.subscriptionPlan, equals(entity.subscriptionPlan));
        expect(model.isActive, equals(entity.isActive));
        expect(model.currency, equals(entity.currency));
        expect(model.locale, equals(entity.locale));
        expect(model.timezone, equals(entity.timezone));
        expect(model.settings, equals(entity.settings));
        expect(model.createdAt, equals(entity.createdAt));
        expect(model.updatedAt, equals(entity.updatedAt));
        expect(model.displayName, equals(entity.displayName));
        expect(model.isActivePlan, equals(entity.isActivePlan));
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final copy = tOrganizationModel.copyWith(
          name: 'Updated Name',
          subscriptionPlan: SubscriptionPlan.enterprise,
        );

        expect(copy.id, equals(tOrganizationModel.id));
        expect(copy.name, equals('Updated Name'));
        expect(copy.subscriptionPlan, equals(SubscriptionPlan.enterprise));
        expect(copy.slug, equals(tOrganizationModel.slug));
      });

      test('should preserve original values when not specified', () {
        final copy = tOrganizationModel.copyWith();

        expect(copy.id, equals(tOrganizationModel.id));
        expect(copy.name, equals(tOrganizationModel.name));
        expect(copy.subscriptionPlan, equals(tOrganizationModel.subscriptionPlan));
      });
    });

    group('equality', () {
      test('should be equal for same values', () {
        final model1 = OrganizationModel.fromJson(tJson);
        final model2 = OrganizationModel.fromJson(tJson);

        expect(model1, equals(model2));
      });

      test('should not be equal for different ids', () {
        final model1 = OrganizationModel.fromJson(tJson);
        final model2 = OrganizationModel.fromJson({...tJson, 'id': 'different-id'});

        expect(model1, isNot(equals(model2)));
      });
    });

    group('JSON round-trip', () {
      test('should maintain data integrity through toJson and fromJson', () {
        final json = tOrganizationModel.toJson();
        final reconstructed = OrganizationModel.fromJson(json);

        expect(reconstructed.id, equals(tOrganizationModel.id));
        expect(reconstructed.name, equals(tOrganizationModel.name));
        expect(reconstructed.subscriptionPlan, equals(tOrganizationModel.subscriptionPlan));
        expect(reconstructed.settings, equals(tOrganizationModel.settings));
      });
    });
  });
}
