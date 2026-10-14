import 'package:baudex_desktop/app/core/storage/local_cache_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guarda, lee y borra sin usar el llavero del sistema', () async {
    final store = LocalCacheStore(prefix: 'inventory_cache_');
    expect(await store.read(key: 'inventory_out_of_stock_all'), isNull);

    await store.write(key: 'inventory_out_of_stock_all', value: '{"data":[1,2]}');
    expect(await store.read(key: 'inventory_out_of_stock_all'), '{"data":[1,2]}');

    await store.delete(key: 'inventory_out_of_stock_all');
    expect(await store.read(key: 'inventory_out_of_stock_all'), isNull);
  });

  test('cada módulo ve solo sus propias entradas', () async {
    final inventory = LocalCacheStore(prefix: 'inventory_cache_');
    final reports = LocalCacheStore(prefix: 'reports_cache_');
    await inventory.write(key: 'a', value: '1');
    await reports.write(key: 'r1', value: 'x');
    await reports.write(key: 'r2', value: 'y');

    expect(await reports.readAll(), {'r1': 'x', 'r2': 'y'});
    expect(await inventory.readAll(), {'a': '1'});
  });

  test('escribir null equivale a borrar', () async {
    final store = LocalCacheStore();
    await store.write(key: 'k', value: 'v');
    await store.write(key: 'k', value: null);
    expect(await store.read(key: 'k'), isNull);
  });
}
