import 'package:flutter_test/flutter_test.dart';
import 'package:baudex_desktop/features/settings/domain/services/organization_settings_rules.dart';

/// Caso real (2026-11): la clienta cambia la tasa de cambio en el celular y en
/// el computador no se refleja.
void main() {
  group('mergeOrganizationSettings', () {
    final base = <String, dynamic>{
      'acceptedCurrencies': [
        {'code': 'USD', 'name': 'Dólar', 'defaultRate': 40},
      ],
      'footerMessage': 'Gracias por su compra',
      'multiCurrencyEnabled': true,
    };

    test('cambiar solo el pie de factura no toca las monedas', () {
      final r = mergeOrganizationSettings(base, {'footerMessage': 'Vuelva pronto'});
      expect(r['acceptedCurrencies'], base['acceptedCurrencies']);
      expect(r['footerMessage'], 'Vuelva pronto');
      expect(r['multiCurrencyEnabled'], true);
    });

    test('cambiar solo la tasa conserva el resto', () {
      final r = mergeOrganizationSettings(base, {
        'acceptedCurrencies': [
          {'code': 'USD', 'name': 'Dólar', 'defaultRate': 42},
        ],
      });
      expect((r['acceptedCurrencies'] as List).first['defaultRate'], 42);
      expect(r['footerMessage'], 'Gracias por su compra');
    });

    test('null borra la clave y no se modifica el original', () {
      final r = mergeOrganizationSettings(base, {'footerMessage': null});
      expect(r.containsKey('footerMessage'), false);
      expect(base['footerMessage'], 'Gracias por su compra');
      expect(mergeOrganizationSettings(null, {'a': 1}), {'a': 1});
      expect(mergeOrganizationSettings(base, null), base);
    });
  });

  group('blocksServerOrganization', () {
    test('un cambio de configuración pendiente protege lo local', () {
      expect(blocksServerOrganization(entityType: 'organization', retryCount: 0, maxRetries: 10), true);
      expect(blocksServerOrganization(entityType: 'organization_profit_margin', retryCount: 3, maxRetries: 10), true);
    });

    test('una operación rechazada definitivamente NO congela la configuración', () {
      expect(blocksServerOrganization(entityType: 'organization', retryCount: 10, maxRetries: 10), false);
    });

    test('operaciones de otras entidades no afectan', () {
      expect(blocksServerOrganization(entityType: 'invoice', retryCount: 0, maxRetries: 10), false);
    });
  });
}
