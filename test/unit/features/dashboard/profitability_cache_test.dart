import 'package:baudex_desktop/features/dashboard/data/datasources/profitability_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/dashboard_fixtures.dart';

void main() {
  late Map<String, String> storage;
  late ProfitabilityCache cache;
  final start = DateTime(2026, 11, 1);
  final end = DateTime(2026, 11, 30, 23, 59, 59);

  setUp(() {
    storage = {};
    cache = ProfitabilityCache(
      read: (key) async => storage[key],
      write: (key, value) async => storage[key] = value,
    );
  });

  test('guarda y devuelve una pérdida (utilidad negativa)', () async {
    final loss = DashboardFixtures.createProfitabilityStatsModel(
      totalRevenue: 1000,
      totalCOGS: 1300,
      grossProfit: -300,
      netProfit: -450,
    );
    await cache.save(
        organizationId: 'org-a', start: start, end: end, stats: loss);

    final loaded =
        await cache.load(organizationId: 'org-a', start: start, end: end);
    expect(loaded, isNotNull);
    expect(loaded!.grossProfit, -300);
    expect(loaded.netProfit, -450);
  });

  test('otra organización u otro rango no ven esa caché', () async {
    await cache.save(
      organizationId: 'org-a',
      start: start,
      end: end,
      stats: DashboardFixtures.createProfitabilityStatsModel(),
    );

    expect(await cache.load(organizationId: 'org-b', start: start, end: end),
        isNull);
    expect(
        await cache.load(
            organizationId: 'org-a', start: DateTime(2026, 10, 1), end: end),
        isNull);
  });

  test('sin organización conocida no guarda ni lee', () async {
    await cache.save(
      organizationId: null,
      start: start,
      end: end,
      stats: DashboardFixtures.createProfitabilityStatsModel(),
    );
    expect(storage, isEmpty);
    expect(await cache.load(organizationId: null, start: start, end: end),
        isNull);
  });
}
