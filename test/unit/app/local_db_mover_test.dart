import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/local_db_mover.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../../helpers/isar_core.dart';

/// Traslado de la base local de Documentos (OneDrive en Windows) a la carpeta
/// interna de la app. Todo en carpetas temporales: nunca se toca la base real.
void main() {
  const name = 'baudex_offline';
  late Directory root;
  late String docs; // carpeta vieja (Documentos)
  late String data; // carpeta nueva (AppData)
  final today = DateTime(2026, 11, 21, 9, 30, 15);

  setUpAll(initIsarCore);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('baudex_db_move');
    docs = '${root.path}/Documents';
    data = '${root.path}/AppData/com.example/baudex_desktop/data';
    await Directory(docs).create(recursive: true);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  File oldDb() => File('$docs/$name.isar');
  File newDb() => File('$data/$name.isar');
  File backup() => File('$docs/$name.isar.migrado-20261121');

  IsarInvoice sale(String id) => IsarInvoice.create(
        serverId: id,
        number: 'INV-$id',
        date: today,
        dueDate: today,
        status: IsarInvoiceStatus.paid,
        paymentMethod: IsarPaymentMethod.cash,
        subtotal: 10000,
        taxPercentage: 0,
        taxAmount: 0,
        discountPercentage: 0,
        discountAmount: 0,
        total: 10000,
        paidAmount: 10000,
        balanceDue: 0,
        customerId: 'c',
        createdAt: today,
        updatedAt: today,
        isSynced: false,
      );

  IsarProduct product(int i) => IsarProduct.create(
        serverId: 'p$i',
        name: 'Producto $i',
        sku: 'SKU$i',
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 5,
        minStock: 1,
        categoryId: 'cat',
        createdAt: today,
        updatedAt: today,
        isSynced: true,
      );

  /// Crea la base vieja con [products] productos y [pendingSales] ventas sin
  /// subir (cada una con su operación en la cola).
  Future<void> seedLegacy({int products = 3, int pendingSales = 0}) async {
    final isar = await Isar.open(IsarDatabase.schemas,
        directory: docs, name: name, inspector: false);
    await isar.writeTxn(() async {
      for (var i = 0; i < products; i++) {
        await isar.isarProducts.put(product(i));
      }
      for (var i = 0; i < pendingSales; i++) {
        final id = 'inv_offline_${1700000000000 + i}';
        await isar.isarInvoices.put(sale(id));
        await isar.syncOperations.put(SyncOperation.create(
          entityType: 'Invoice',
          entityId: id,
          operationType: SyncOperationType.create,
          payload: '{"id":"$id"}',
          organizationId: 'org',
        ));
      }
    });
    await isar.close();
    // Isar 3 deja su candado `<name>.isar-lck` junto a la base en Windows
    // (en macOS lo borra al cerrar): se deja como en Windows.
    final lck = File('$docs/$name.isar-lck');
    if (!await lck.exists()) await lck.writeAsBytes(List.filled(64, 0));
  }

  /// Agrega una venta sin subir a la base de [dir] (como la haría la app).
  Future<void> addPendingSale(String dir, String id) async {
    final isar = await Isar.open(IsarDatabase.schemas,
        directory: dir, name: name, inspector: false);
    await isar.writeTxn(() async {
      await isar.isarInvoices.put(sale(id));
      await isar.syncOperations.put(SyncOperation.create(
        entityType: 'Invoice',
        entityId: id,
        operationType: SyncOperationType.create,
        payload: '{"id":"$id"}',
        organizationId: 'org',
      ));
    });
    await isar.close();
  }

  final problems = <Map<String, dynamic>>[];
  LocalDbMover mover({LocalDbCounter? counter, Duration? lockTimeout}) {
    problems.clear();
    return LocalDbMover(
      legacyDirectory: docs,
      newDirectory: data,
      name: name,
      counter: counter ?? IsarDatabase.countRecords,
      queueReader: IsarDatabase.readQueue,
      lockTimeout: lockTimeout ?? const Duration(seconds: 60),
      onProblem: (e, st, ctx) => problems.add({...ctx, 'error': '$e'}),
      now: () => today,
    );
  }

  test('caso normal: copia, verifica, usa la nueva y deja respaldo', () async {
    await seedLegacy(products: 4);
    final size = await oldDb().length();

    final loc = await mover().resolve();

    expect(loc.outcome, LocalDbMoveOutcome.moved);
    expect(loc.directory, data);
    expect(await newDb().exists(), isTrue);
    expect(await newDb().length(), size);
    expect(await oldDb().exists(), isFalse, reason: 'la vieja se renombra');
    expect(await backup().exists(), isTrue, reason: 'respaldo con fecha');
    expect(await File('$data/$name.isar-lck').exists(), isFalse,
        reason: 'el candado de Isar no se copia');
    expect(await File('$docs/$name.isar-lck').exists(), isFalse,
        reason: 'ni se deja suelto en Documentos');
    expect(await Directory('$data/${LocalDbMover.stagingFolder}').exists(), isFalse);
    final counts = await IsarDatabase.countRecords(data, name);
    expect(counts['products'], 4);
    expect(problems, isEmpty);
  });

  test('ya trasladado: no vuelve a copiar ni a abrir la vieja', () async {
    await seedLegacy();
    await mover().resolve();
    final again = await mover(counter: (_, __) async => throw StateError('no debe contar'))
        .resolve();
    expect(again.outcome, LocalDbMoveOutcome.alreadyMoved);
    expect(again.directory, data);
    expect(problems, isEmpty);
  });

  test('sin base vieja: arranca en la nueva', () async {
    final loc = await mover().resolve();
    expect(loc.outcome, LocalDbMoveOutcome.fresh);
    expect(loc.directory, data);
    expect(await Directory(data).exists(), isTrue);
  });

  test('copia que no cuadra: sigue con la vieja intacta y lo reporta', () async {
    await seedLegacy(products: 2);
    var calls = 0;
    final loc = await mover(counter: (dir, n) async {
      calls++;
      final real = await IsarDatabase.countRecords(dir, n);
      // La segunda vez (la copia) faltan productos.
      return calls == 1 ? real : {...real, 'products': 0};
    }).resolve();

    expect(loc.outcome, LocalDbMoveOutcome.keptLegacy);
    expect(loc.directory, docs);
    expect(await oldDb().exists(), isTrue);
    expect(await backup().exists(), isFalse);
    expect(await newDb().exists(), isFalse, reason: 'nunca queda una nueva a medias');
    expect(await Directory('$data/${LocalDbMover.stagingFolder}').exists(), isFalse);
    expect(problems.single['step'], 'count_copy');
    expect((await IsarDatabase.countRecords(docs, name))['products'], 2);
  });

  test('base vieja dañada y pequeña: no se toca, sigue con la vieja', () async {
    await oldDb().writeAsString('no soy una base');
    final loc = await mover().resolve();
    expect(loc.outcome, LocalDbMoveOutcome.keptLegacy);
    expect(loc.directory, docs);
    expect(await oldDb().readAsString(), 'no soy una base');
    expect(problems.single['step'], 'check_legacy');
  });

  test('base vieja que no abre: sigue con la vieja y lo reporta', () async {
    await oldDb().writeAsBytes(List.filled(3 * 1024 * 1024, 7));
    final loc = await mover().resolve();
    expect(loc.outcome, LocalDbMoveOutcome.keptLegacy);
    expect(loc.directory, docs);
    expect(await oldDb().length(), 3 * 1024 * 1024);
    expect(await newDb().exists(), isFalse);
    expect(problems.single['step'], 'count_legacy');
  });

  test('carpeta nueva imposible de crear: sigue con la vieja', () async {
    await seedLegacy();
    // Un archivo donde debería ir la carpeta.
    await Directory('${root.path}/AppData/com.example').create(recursive: true);
    await File('${root.path}/AppData/com.example/baudex_desktop').writeAsString('x');
    final loc = await mover().resolve();
    expect(loc.outcome, LocalDbMoveOutcome.keptLegacy);
    expect(loc.directory, docs);
    expect(await oldDb().exists(), isTrue);
  });

  test('cierre a mitad de la copia: el siguiente arranque empieza limpio', () async {
    await seedLegacy(products: 3);
    // Lo que deja una copia cortada: un .parcial truncado, sin base nueva.
    final staging = Directory('$data/${LocalDbMover.stagingFolder}');
    await staging.create(recursive: true);
    await File('${staging.path}/$name.isar.parcial').writeAsBytes([1, 2, 3]);

    final loc = await mover().resolve();

    expect(loc.outcome, LocalDbMoveOutcome.moved);
    expect(await newDb().length(), greaterThan(3));
    expect((await IsarDatabase.countRecords(data, name))['products'], 3);
    expect(await staging.exists(), isFalse);
  });

  test('cierre justo después de copiar, antes de renombrar la vieja', () async {
    await seedLegacy(products: 1);
    await Directory(data).create(recursive: true);
    await oldDb().copy(newDb().path); // nueva ya puesta, vieja sin renombrar

    final loc = await mover(counter: (_, __) async => throw StateError('no')).resolve();

    expect(loc.outcome, LocalDbMoveOutcome.alreadyMoved);
    expect(await oldDb().exists(), isFalse);
    expect(await backup().exists(), isTrue);
  });

  test('base vieja con ventas pendientes: llegan todas a la nueva', () async {
    await seedLegacy(products: 2, pendingSales: 3);
    final before = await IsarDatabase.countRecords(docs, name);
    expect(before['pendingSync'], 3);

    final loc = await mover().resolve();

    expect(loc.outcome, LocalDbMoveOutcome.moved);
    final after = await IsarDatabase.countRecords(data, name);
    expect(after['pendingSync'], 3);
    expect(after['invoices'], 3);
    expect(after['syncOperations'], 3);
    expect(LocalDbMover.sameCounts(before, after), isTrue);
  });

  test('ventas pendientes y copia fallida: la app sigue en la vieja con sus ventas', () async {
    await seedLegacy(pendingSales: 2);
    var calls = 0;
    final loc = await mover(counter: (dir, n) async {
      if (++calls == 2) throw const FileSystemException('disco lleno');
      return IsarDatabase.countRecords(dir, n);
    }).resolve();
    expect(loc.directory, docs);
    expect((await IsarDatabase.countRecords(loc.directory, name))['pendingSync'], 2);
    expect(await newDb().exists(), isFalse);
  });

  test('vieja viva con una venta nueva que la nueva no tiene: no se archiva y se reporta', () async {
    await seedLegacy(products: 1, pendingSales: 2);
    await mover().resolve(); // traslado normal
    // Una copia vieja de la app (o un segundo arranque) siguió vendiendo en
    // Documentos: se restaura el archivo y se anota una venta ahí.
    await backup().rename(oldDb().path);
    await addPendingSale(docs, 'inv_offline_solo_en_la_vieja');

    final loc = await mover().resolve();

    expect(loc.outcome, LocalDbMoveOutcome.alreadyMoved);
    expect(await oldDb().exists(), isTrue, reason: 'la venta no queda escondida en un respaldo');
    expect(await backup().exists(), isFalse);
    expect(problems.single['step'], 'leftover_pending');
    expect(problems.single['missing'], 1);
    expect(problems.single['level'], 'error');
  });

  test('vieja viva sin nada nuevo (antivirus impidió renombrarla): se archiva después', () async {
    await seedLegacy(products: 1, pendingSales: 2);
    await mover().resolve();
    await backup().rename(oldDb().path); // como si el rename hubiera fallado
    // La app ya vendió en la nueva: eso no impide archivar la vieja.
    await addPendingSale(data, 'inv_offline_en_la_nueva');

    final loc = await mover().resolve();

    expect(loc.outcome, LocalDbMoveOutcome.alreadyMoved);
    expect(await oldDb().exists(), isFalse);
    expect(await backup().exists(), isTrue);
    expect(problems, isEmpty);
  });

  test('vieja viva que no se puede leer: no se archiva', () async {
    await seedLegacy();
    await mover().resolve();
    await backup().delete();
    await oldDb().writeAsBytes(List.filled(3 * 1024 * 1024, 7)); // dañada
    final loc = await mover().resolve();
    expect(loc.outcome, LocalDbMoveOutcome.alreadyMoved);
    expect(await oldDb().exists(), isTrue);
    expect(problems.single['step'], 'leftover_read');
  });

  test('doble arranque a la vez: un solo traslado, nadie usa la vieja ni pierde ventas', () async {
    await seedLegacy(products: 3, pendingSales: 4);
    final a = mover();
    final b = LocalDbMover(
      legacyDirectory: docs,
      newDirectory: data,
      name: name,
      counter: IsarDatabase.countRecords,
      queueReader: IsarDatabase.readQueue,
      now: () => today,
    );
    final results = await Future.wait([a.resolve(), b.resolve()]);

    expect(results.map((r) => r.directory).toSet(), {data});
    expect(results.map((r) => r.outcome).toSet(),
        {LocalDbMoveOutcome.moved, LocalDbMoveOutcome.alreadyMoved});
    expect((await IsarDatabase.countRecords(data, name))['pendingSync'], 4);
    expect(await backup().exists(), isTrue);
  });

  test('candado ocupado por otro proceso: no copia ni archiva y sigue con la vieja', () async {
    final dart = _dartExecutable();
    if (dart == null) {
      markTestSkipped('sin dart en PATH');
      return;
    }
    await seedLegacy(pendingSales: 1);
    await Directory(data).create(recursive: true);
    final holder = await _holdLockInOtherProcess(dart, root.path, '$data/${LocalDbMover.lockFileName}');
    try {
      final loc = await mover(lockTimeout: const Duration(milliseconds: 800)).resolve();
      expect(loc.outcome, LocalDbMoveOutcome.keptLegacy);
      expect(loc.directory, docs);
      expect(await newDb().exists(), isFalse);
      expect(await oldDb().exists(), isTrue);
      expect(problems.single['step'], 'lock');
    } finally {
      holder.kill();
      await holder.exitCode;
    }
    // Suelto el candado, el siguiente arranque sí traslada.
    expect((await mover().resolve()).outcome, LocalDbMoveOutcome.moved);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('respaldo del mismo día ya existe: usa la hora', () async {
    await seedLegacy();
    await backup().writeAsString('respaldo anterior');
    await mover().resolve();
    expect(await backup().readAsString(), 'respaldo anterior');
    expect(await File('${backup().path}-093015').exists(), isTrue);
  });

  group('carpeta en Windows', () {
    test('pasa de Roaming a Local con la misma subcarpeta', () {
      expect(
        windowsLocalDataPath(
          supportPath: r'C:\Users\caja\AppData\Roaming\com.example\baudex_desktop',
          roamingAppData: r'C:\Users\caja\AppData\Roaming',
          localAppData: r'C:\Users\caja\AppData\Local',
        ),
        r'C:\Users\caja\AppData\Local\com.example\baudex_desktop\data',
      );
    });

    test('sin variables o ruta inesperada: null (usa la de soporte)', () {
      expect(
          windowsLocalDataPath(
              supportPath: r'C:\x\y', roamingAppData: null, localAppData: r'C:\L'),
          isNull);
      expect(
          windowsLocalDataPath(
              supportPath: r'D:\otra\cosa',
              roamingAppData: r'C:\Users\caja\AppData\Roaming',
              localAppData: r'C:\Users\caja\AppData\Local'),
          isNull);
    });
  });
}

/// El `dart` del mismo Flutter que corre la prueba (ejecutable real, no el
/// `.bat`, para poder cerrarlo con kill en Windows).
String? _dartExecutable() {
  final exe = Platform.isWindows ? 'dart.exe' : 'dart';
  final sep = Platform.pathSeparator;
  final tester = Platform.resolvedExecutable;
  final at = tester.indexOf('${sep}bin${sep}cache$sep');
  if (at > 0) {
    final f = File('${tester.substring(0, at)}${sep}bin${sep}cache${sep}dart-sdk${sep}bin$sep$exe');
    if (f.existsSync()) return f.path;
  }
  for (final dir in (Platform.environment['PATH'] ?? '').split(Platform.isWindows ? ';' : ':')) {
    final f = File('$dir$sep$exe');
    if (f.existsSync()) return f.path;
  }
  return null;
}

/// Otro proceso de verdad que toma el candado de [path] y espera; avisa por
/// su salida cuando ya lo tiene.
Future<Process> _holdLockInOtherProcess(String dart, String scratch, String path) async {
  final script = File('$scratch${Platform.pathSeparator}hold_lock.dart');
  await script.writeAsString('''
import 'dart:io';
Future<void> main(List<String> a) async {
  final raf = await File(a[0]).open(mode: FileMode.append);
  await raf.lock(FileLock.exclusive);
  stdout.writeln('LISTO');
  await stdout.flush();
  await Future<void>.delayed(const Duration(minutes: 2));
}
''');
  final p = await Process.start(dart, [script.path, path]);
  final ready = p.stdout
      .transform(const SystemEncoding().decoder)
      .firstWhere((l) => l.contains('LISTO'));
  await ready.timeout(const Duration(seconds: 60));
  return p;
}
