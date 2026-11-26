// Guardar una impresora sobre una base local "con historia": restos de
// versiones anteriores que una base limpia no tiene.
import 'dart:io';

import 'package:baudex_desktop/app/core/storage/shared_prefs_repair.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/settings/data/printer_diagnostics.dart';
import 'package:baudex_desktop/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:baudex_desktop/features/settings/data/models/printer_settings_model.dart';
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../../../helpers/isar_core.dart';

const _id = '3f2b8c1e-5a7d-4e9b-8c1a-2d3e4f5a6b7c';

PrinterSettingsModel row(
  String serverId, {
  String name = 'Vieja',
  bool isDefault = false,
  bool deleted = false,
}) => PrinterSettingsModel.fromEntity(
  PrinterSettings.usbPrinter(
    id: serverId,
    name: name,
    usbPath: 'POS-80',
    isDefault: isDefault,
  ),
)..deletedAt = deleted ? DateTime(2026, 11, 20) : null;

/// Preferencias del equipo que no se pueden leer: es lo que hace el
/// complemento de Windows cuando `shared_preferences.json` quedó dañado
/// (por ejemplo al apagar el computador mientras se escribía): lanza
/// `FormatException` en cada lectura, para siempre.
class BrokenPrefsStore extends SharedPreferencesStorePlatform {
  @override
  Future<Map<String, Object>> getAll() async =>
      throw const FormatException('Unexpected character (at character 1)');
  @override
  Future<bool> clear() async => throw const FormatException('dañado');
  @override
  Future<bool> remove(String key) async => throw const FormatException('dañado');
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw const FormatException('dañado');
}

void breakDevicePreferences() {
  SharedPreferences.setMockInitialValues({});
  SharedPreferencesStorePlatform.instance = BrokenPrefsStore();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late Directory dir;
  late SettingsLocalDataSourceImpl local;

  setUpAll(initIsarCore);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('baudex_printer_dirty');
    isar = await Isar.open(IsarDatabase.schemas, directory: dir.path);
    IsarDatabase.debugSetDatabase(isar);
    local = SettingsLocalDataSourceImpl();
  });

  tearDown(() async {
    IsarDatabase.debugSetDatabase(null);
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  PrinterSettings fresh({String id = _id}) => PrinterSettings.usbPrinter(
    id: id,
    name: 'POS 80 Printer (copia 1)',
    usbPath: 'POS 80 Printer (copia 1)',
    isDefault: true,
  );

  Future<void> seed(List<PrinterSettingsModel> rows) =>
      isar.writeTxn(() => isar.printerSettingsModels.putAll(rows));

  final states = <String, List<PrinterSettingsModel> Function()>{
    'fila con serverId vacío': () => [row('', isDefault: true)],
    'fila borrada lógicamente y marcada predeterminada':
        () => [row('aaaaaaaa-0000-4000-8000-000000000001', isDefault: true, deleted: true)],
    'dos filas marcadas predeterminadas': () => [
      row('aaaaaaaa-0000-4000-8000-000000000001', isDefault: true),
      row('aaaaaaaa-0000-4000-8000-000000000002', isDefault: true),
    ],
    'la misma impresora ya existe borrada lógicamente':
        () => [row(_id, isDefault: true, deleted: true)],
    'restos con id temporal':
        () => [row('printer_offline_1764000000000', isDefault: true)],
  };

  for (final entry in states.entries) {
    test('guardar con ${entry.key}', () async {
      await seed(entry.value());
      SharedPreferences.setMockInitialValues({
        'default_printer_id': 'no-existe',
      });
      local = SettingsLocalDataSourceImpl();

      final result = await local.savePrinterSettings(fresh());

      expect(result.isRight(), isTrue, reason: '$result');
      final all = (await local.getAllPrinterSettings()).getOrElse(() => []);
      expect(all.where((p) => p.id == _id).length, 1, reason: '$all');
      final chosen = (await local.getDefaultPrinterSettings()).getOrElse(() => null);
      expect(chosen?.id, _id);
    });
  }

  group('preferencias del equipo dañadas (shared_preferences.json ilegible)', () {
    setUp(() {
      breakDevicePreferences();
      local = SettingsLocalDataSourceImpl(repairPreferences: () async => false);
    });

    test('agregar una impresora funciona y aparece en la lista', () async {
      final result = await local.savePrinterSettings(fresh());

      expect(result.isRight(), isTrue, reason: '$result');
      final all = (await local.getAllPrinterSettings()).getOrElse(() => []);
      expect(all.map((p) => p.id), [_id]);
      final chosen =
          (await local.getDefaultPrinterSettings()).getOrElse(() => null);
      expect(chosen?.id, _id, reason: 'Sin preferencias manda la marca local');
    });

    test('las impresoras ya guardadas se ven y hay con cuál facturar', () async {
      await seed([row(_id, name: 'Caja')]);

      final all = (await local.getAllPrinterSettings()).getOrElse(() => []);
      final chosen =
          (await local.getDefaultPrinterSettings()).getOrElse(() => null);

      expect(all.single.name, 'Caja');
      expect(chosen?.id, _id);
    });

    test('eliminar funciona', () async {
      await seed([row(_id, name: 'Caja')]);

      final result = await local.deletePrinterSettings(_id);

      expect(result.isRight(), isTrue, reason: '$result');
      expect(await isar.printerSettingsModels.count(), 0);
    });

    test('elegir predeterminada funciona y se recuerda en la base', () async {
      const other = 'aaaaaaaa-0000-4000-8000-000000000002';
      await seed([row(_id, name: 'Caja', isDefault: true), row(other, name: 'Cocina')]);

      final result = await local.setDefaultPrinter(other);
      final chosen =
          (await SettingsLocalDataSourceImpl().getDefaultPrinterSettings()).getOrElse(() => null);

      expect(result.isRight(), isTrue, reason: '$result');
      expect(chosen?.id, other);
    });
  });

  test('un fallo de preferencias queda registrado con su motivo y se '
      'intenta reparar una sola vez', () async {
    final problems = <String>[];
    printerProblemSink = (op, error, _) => problems.add('$op: $error');
    addTearDown(() => printerProblemSink = (_, __, ___) {});
    breakDevicePreferences();
    var repairs = 0;
    local = SettingsLocalDataSourceImpl(
      repairPreferences: () async {
        repairs++;
        return false;
      },
    );

    await local.savePrinterSettings(fresh());
    await local.getAllPrinterSettings();
    await local.deletePrinterSettings(_id);

    expect(repairs, 1);
    expect(problems.single, contains('preferencias del equipo'));
    expect(problems.single, contains('FormatException'));
  });

  test('si la reparación funciona, la elección del equipo vuelve a guardarse', () async {
    breakDevicePreferences();
    local = SettingsLocalDataSourceImpl(
      repairPreferences: () async {
        // Lo que logra apartar el archivo dañado: las preferencias leen.
        SharedPreferences.setMockInitialValues({});
        return true;
      },
    );

    await local.savePrinterSettings(fresh());

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('default_printer_id'), _id);
  });

  group('archivo de preferencias dañado', () {
    late File file;
    setUp(() => file = File('${dir.path}/shared_preferences.json'));

    test('cortado a la mitad: se aparta', () {
      file.writeAsStringSync('{"flutter.default_printer_id":"3f2b');
      expect(setAsideIfCorruptJson(file), isTrue);
      expect(file.existsSync(), isFalse);
      expect(
        dir.listSync().any((f) => f.path.contains('shared_preferences.json.danado-')),
        isTrue,
      );
    });

    test('lleno de ceros (apagón): se aparta', () {
      file.writeAsBytesSync(List<int>.filled(64, 0));
      expect(setAsideIfCorruptJson(file), isTrue);
    });

    test('sano, vacío o inexistente: no se toca', () {
      expect(setAsideIfCorruptJson(file), isFalse);
      file.writeAsStringSync('');
      expect(setAsideIfCorruptJson(file), isFalse);
      file.writeAsStringSync('{"flutter.x":"y"}');
      expect(setAsideIfCorruptJson(file), isFalse);
      expect(file.existsSync(), isTrue);
    });
  });
}
