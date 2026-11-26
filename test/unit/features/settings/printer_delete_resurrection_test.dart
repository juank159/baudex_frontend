// "Le doy Eliminar y no se eliminan: cierro la app y siguen ahí."
// La bajada del servidor pisaba la base a ciegas: si su lista se había
// pedido antes del borrado (o el borrado estaba en cola), la impresora
// volvía. Y una fila que el servidor ya no tenía se quedaba para siempre.
import 'dart:io';

import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:baudex_desktop/features/settings/data/models/printer_settings_model.dart';
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/isar_core.dart';

const _a = 'aaaaaaaa-0000-4000-8000-000000000001';
const _b = 'bbbbbbbb-0000-4000-8000-000000000002';
const _temp = 'printer_offline_1764000000000';

PrinterSettings printer(String id, String name, {bool isDefault = false}) =>
    PrinterSettings.usbPrinter(
      id: id,
      name: name,
      usbPath: name,
      isDefault: isDefault,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late Directory dir;
  late SettingsLocalDataSourceImpl local;

  setUpAll(initIsarCore);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('baudex_printer_delete');
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    local = SettingsLocalDataSourceImpl();
  });

  tearDown(() async {
    IsarDatabase.debugSetDatabase(null);
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  /// Filas como las deja un equipo con historia: [age] atrás.
  Future<void> seed(
    List<PrinterSettings> printers, {
    Duration age = const Duration(days: 2),
  }) => isar.writeTxn(() async {
    final when = DateTime.now().subtract(age);
    for (final p in printers) {
      await isar.printerSettingsModels.put(
        PrinterSettingsModel.fromEntity(p)
          ..createdAt = when
          ..updatedAt = when
          ..lastSyncAt = when,
      );
    }
  });

  Future<List<String>> visible() async =>
      (await local.getAllPrinterSettings())
          .getOrElse(() => [])
          .map((p) => p.name)
          .toList();

  test('así fallaba: la bajada antigua (pisar por id) revive la eliminada', () async {
    await seed([printer(_a, 'Caja')]);
    await isar.writeTxn(
      () => isar.printerSettingsModels.filter().serverIdEqualTo(_a).deleteAll(),
    );
    // Lista que el servidor había entregado antes del borrado.
    await isar.writeTxn(
      () => isar.printerSettingsModels.putAllByServerId([
        PrinterSettingsModel.fromEntity(printer(_a, 'Caja')),
      ]),
    );
    expect(await visible(), ['Caja']);
  });

  test('eliminada aquí: una bajada con la lista vieja no la revive', () async {
    await seed([printer(_a, 'Caja'), printer(_b, 'Cocina')]);

    await local.deletePrinterSettings(_a);
    await local.mergeServerPrinters([printer(_a, 'Caja'), printer(_b, 'Cocina')]);

    expect(await visible(), ['Cocina']);
  });

  test('eliminada sin internet (borrado en cola): no vuelve mientras el '
      'servidor la siga listando, y la marca se limpia cuando deja de listarla', () async {
    await seed([printer(_a, 'Caja'), printer(_b, 'Cocina')]);
    await local.deletePrinterSettings(_a);

    for (var i = 0; i < 3; i++) {
      await local.mergeServerPrinters([printer(_a, 'Caja'), printer(_b, 'Cocina')]);
    }
    expect(await visible(), ['Cocina']);

    await local.mergeServerPrinters([printer(_b, 'Cocina')]);
    expect(await visible(), ['Cocina']);
    expect(await isar.printerSettingsModels.count(), 1);
  });

  test('restos que el servidor ya no tiene se quitan solos (si no son '
      'recientes)', () async {
    await seed([printer(_a, 'Resto viejo'), printer(_b, 'Cocina')]);

    await local.mergeServerPrinters([printer(_b, 'Cocina')]);

    expect(await visible(), ['Cocina']);
  });

  test('recién creada y el servidor aún no la lista: se respeta', () async {
    await seed([printer(_b, 'Cocina')]);
    await seed([printer(_a, 'Recién creada')], age: const Duration(seconds: 20));

    await local.mergeServerPrinters([printer(_b, 'Cocina')]);

    expect((await visible()).toSet(), {'Cocina', 'Recién creada'});
  });

  test('si el servidor responde vacío no se quita nada de este equipo', () async {
    await seed([printer(_a, 'Caja')]);

    await local.mergeServerPrinters(const []);

    expect(await visible(), ['Caja']);
  });

  test('las creadas sin internet no se tocan', () async {
    await seed([printer(_temp, 'Sin subir'), printer(_b, 'Cocina')]);

    await local.mergeServerPrinters([printer(_b, 'Cocina')]);

    expect((await visible()).toSet(), {'Sin subir', 'Cocina'});
  });

  test('la bajada no cambia con cuál factura este equipo', () async {
    await seed([printer(_a, 'Caja', isDefault: true), printer(_b, 'Cocina')]);

    // En el servidor otro equipo marcó la otra.
    await local.mergeServerPrinters([
      printer(_a, 'Caja'),
      printer(_b, 'Cocina', isDefault: true),
    ]);

    final chosen = (await local.getDefaultPrinterSettings()).getOrElse(() => null);
    expect(chosen?.name, 'Caja');
  });

  test('varias con id del servidor, eliminadas una por una, con una '
      'bajada entre cada borrado: no queda ninguna', () async {
    final ids = [
      for (var i = 1; i <= 6; i++)
        'cccccccc-0000-4000-8000-${i.toString().padLeft(12, '0')}',
    ];
    final all = [for (final id in ids) printer(id, 'Impresora ${ids.indexOf(id)}')];
    await seed(all);
    final onServer = [...all];

    for (final p in all) {
      // La lista se pidió antes de que el servidor borrara esta.
      final stale = [...onServer];
      await local.deletePrinterSettings(p.id);
      onServer.remove(p);
      await local.mergeServerPrinters(stale);
    }
    await local.mergeServerPrinters(onServer);

    expect(await visible(), isEmpty);
  });
}
