// test/helpers/test_isar.dart
import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:isar/isar.dart';

/// Base Isar REAL y temporal para pruebas, con todas las colecciones de la
/// app (la misma lista que usa la app). Reemplaza la base simulada que el
/// código ya no acepta (ahora exige una `Isar` de verdad).
bool _coreReady = false;
int _counter = 0;

Future<Isar> openTestIsar() async {
  if (!_coreReady) {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
    _coreReady = true;
  }
  final dir = await Directory.systemTemp.createTemp('isar_test');
  final isar = await Isar.open(
    IsarDatabase.schemas,
    directory: dir.path,
    name: 'test_${_counter++}',
  );
  IsarDatabase.debugSetDatabase(isar);
  return isar;
}

Future<void> closeTestIsar(Isar isar) async {
  if (isar.isOpen) await isar.close(deleteFromDisk: true);
  IsarDatabase.debugSetDatabase(null);
}

/// `IsarDatabase` que entrega la base de prueba.
class TestIsarDatabase implements IsarDatabase {
  TestIsarDatabase(this.database);

  @override
  final Isar database;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
