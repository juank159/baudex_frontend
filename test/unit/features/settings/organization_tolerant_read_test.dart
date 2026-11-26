// El negocio se lee del servidor sin que un campo raro tumbe todo: nulos,
// números como texto, fechas raras, campos faltantes, listas vacías.
import 'package:baudex_desktop/app/core/utils/tolerant_json.dart';
import 'package:baudex_desktop/features/settings/data/models/organization_model.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> normal() => {
      'id': 'org-1',
      'name': 'Tienda La Esquina',
      'slug': 'la-esquina',
      'domain': null,
      'logo': null,
      'settings': {
        'defaultProfitMarginPercentage': 25,
        'multiCurrencyEnabled': false,
        'cashRegisterEnabled': true,
        'acceptedCurrencies': [
          {'code': 'USD', 'rate': 4100},
        ],
      },
      'subscriptionPlan': 'basic',
      'subscriptionStatus': 'active',
      'isActive': true,
      'currency': 'COP',
      'locale': 'es',
      'timezone': 'America/Bogota',
      'createdAt': '2026-01-10T15:00:00.000Z',
      'updatedAt': '2026-11-20T15:00:00.000Z',
      'subscriptionStartDate': '2026-01-10T15:00:00.000Z',
      'subscriptionEndDate': '2027-01-10T15:00:00.000Z',
      'hasValidSubscription': true,
      'isTrialExpired': false,
      'daysUntilExpiration': 45,
      'isActivePlan': true,
    };

void main() {
  group('negocio: lectura tolerante', () {
    test('respuesta normal: sin observaciones', () {
      final issues = <JsonIssue>[];
      final org = OrganizationModel.fromJson(normal(), issues: issues);
      expect(issues, isEmpty);
      expect(org.id, 'org-1');
      expect(org.currency, 'COP');
      expect(org.defaultProfitMarginPercentage, 25.0);
      expect(org.daysUntilExpiration, 45);
      expect(org.subscriptionPlan, SubscriptionPlan.basic);
      expect(org.acceptedCurrencies.single['code'], 'USD');
    });

    test('números como texto, entero con decimales, sí/no como texto o 1/0',
        () {
      final json = normal()
        ..['daysUntilExpiration'] = 44.7
        ..['isActive'] = 'true'
        ..['hasValidSubscription'] = 1
        ..['isTrialExpired'] = '0';
      (json['settings'] as Map)
        ..['defaultProfitMarginPercentage'] = '30'
        ..['multiCurrencyEnabled'] = 'true'
        ..['cashRegisterEnabled'] = 0;
      final issues = <JsonIssue>[];
      final org = OrganizationModel.fromJson(json, issues: issues);
      expect(issues, isEmpty, reason: 'se entienden: no son un problema');
      expect(org.daysUntilExpiration, 44);
      expect(org.isActive, isTrue);
      expect(org.hasValidSubscription, isTrue);
      expect(org.isTrialExpired, isFalse);
      expect(org.defaultProfitMarginPercentage, 30.0);
      expect(org.multiCurrencyEnabled, isTrue);
      expect(org.cashRegisterEnabled, isFalse);
    });

    test('antes esto tumbaba TODO el negocio: margen como texto, días con '
        'decimales, fecha vacía', () {
      final json = normal()
        ..['daysUntilExpiration'] = 12.5
        ..['subscriptionEndDate'] = ''
        ..['trialEndDate'] = 'pronto';
      (json['settings'] as Map)['defaultProfitMarginPercentage'] = '20';
      final issues = <JsonIssue>[];
      final org = OrganizationModel.fromJson(json, issues: issues);
      expect(org.id, 'org-1');
      expect(org.subscriptionEndDate, isNull);
      expect(org.trialEndDate, isNull);
      expect(issues.map((i) => '$i'),
          ['trialEndDate: se esperaba fecha y llegó String'],
          reason: 'dice el campo y el tipo, nunca el valor');
    });

    test('todo nulo o faltante salvo id y nombre: valores por defecto', () {
      final issues = <JsonIssue>[];
      final org = OrganizationModel.fromJson(
          {'id': 'org-1', 'name': 'X', 'settings': null},
          issues: issues);
      expect(issues, isEmpty);
      expect(org.slug, '');
      expect(org.settings, isNull);
      expect(org.isActive, isTrue);
      expect(org.cashRegisterEnabled, isTrue);
      expect(org.multiCurrencyEnabled, isFalse);
      expect(org.subscriptionPlan, SubscriptionPlan.trial);
      expect(org.acceptedCurrencies, isEmpty);
      expect(org.profitMargin, 20.0);
    });

    test('tipos imposibles: se anotan con campo y tipo, y el resto se lee', () {
      final json = normal()
        ..['settings'] = 'no-es-un-objeto'
        ..['isActive'] = ['x']
        ..['currency'] = {'code': 'COP'}
        ..['createdAt'] = true
        ..['daysUntilExpiration'] = 'muchos'
        ..['subscriptionPlan'] = 99;
      final issues = <JsonIssue>[];
      final org = OrganizationModel.fromJson(json, issues: issues);
      expect(org.id, 'org-1');
      expect(org.name, 'Tienda La Esquina');
      expect(org.settings, isNull);
      expect(org.isActive, isTrue);
      expect(org.currency, 'EUR');
      expect(org.subscriptionPlan, SubscriptionPlan.trial);
      final text = issues.map((i) => '$i').join(' | ');
      expect(text, contains('settings: se esperaba objeto y llegó String'));
      expect(text, contains('isActive: se esperaba sí/no y llegó List'));
      expect(text, contains('currency: se esperaba texto y llegó'));
      expect(text, contains('createdAt: se esperaba fecha y llegó bool'));
      expect(text, contains('daysUntilExpiration: se esperaba entero y llegó String'));
      expect(text, isNot(contains('muchos')), reason: 'sin valores');
      expect(text, isNot(contains('COP')));
    });

    test('fechas: ISO, milisegundos, segundos y texto numérico', () {
      final json = normal()
        ..['createdAt'] = 1768057200000
        ..['updatedAt'] = '1768057200'
        ..['subscriptionStartDate'] = '2026-01-10 15:00:00';
      final org = OrganizationModel.fromJson(json);
      expect(org.createdAt.year, 2026);
      expect(org.updatedAt.year, 2026);
      expect(org.subscriptionStartDate!.month, 1);
    });

    test('monedas aceptadas: lista vacía, elementos que no son objetos', () {
      final json = normal();
      (json['settings'] as Map)['acceptedCurrencies'] = [
        'USD',
        null,
        {'code': 'EUR', 'rate': '4500'},
        7,
      ];
      final org = OrganizationModel.fromJson(json);
      expect(org.acceptedCurrencies, [
        {'code': 'EUR', 'rate': '4500'},
      ]);
      (json['settings'] as Map)['acceptedCurrencies'] = [];
      expect(OrganizationModel.fromJson(json).acceptedCurrencies, isEmpty);
      (json['settings'] as Map)['acceptedCurrencies'] = 'ninguna';
      expect(OrganizationModel.fromJson(json).acceptedCurrencies, isEmpty);
    });

    test('la respuesta no es un objeto: no revienta; queda sin id', () {
      for (final body in [null, 'texto', 5, <dynamic>[]]) {
        final issues = <JsonIssue>[];
        final org = OrganizationModel.fromJson(body, issues: issues);
        expect(org.id, isEmpty);
        expect(issues.single.field, '(respuesta)');
      }
    });
  });

  group('envolturas {success, data}', () {
    bool isOrg(Map<dynamic, dynamic> m) => m.containsKey('id') && m.containsKey('name');

    test('sin envolver, envuelta una vez y dos veces', () {
      final org = normal();
      expect(unwrapData(org, looksLikeIt: isOrg), same(org));
      expect(unwrapData({'success': true, 'data': org}, looksLikeIt: isOrg), same(org));
      expect(
          unwrapData({
            'success': true,
            'data': {'success': true, 'data': org},
          }, looksLikeIt: isOrg),
          same(org));
    });

    test('un negocio que tiene un campo "data" propio no se desenvuelve de más',
        () {
      final org = normal()..['data'] = {'otra': 'cosa'};
      expect(unwrapData({'data': org}, looksLikeIt: isOrg), same(org));
    });

    test('lista dentro de data (conteo de almacenes activos)', () {
      expect(unwrapData({'success': true, 'data': [1, 2, 3]}), [1, 2, 3]);
      expect(unwrapData({'success': true, 'data': null}), isNull);
    });
  });
}
