import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/local_db_mover.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

/// Traslado de la base local de Documentos (OneDrive en Windows) a la carpeta
/// interna de la app. Todo en carpetas temporales: nunca se toca la base real.
void main() {
  const name = 'baudex_offline';
  late Directory root;
  late String docs; // carpeta vieja (Documentos)
  late String data; // carpeta nueva (AppData)
  final today = DateTime(2026, 11, 21, 9, 30, 15);

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

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
    // Isar deja el candado; la app vieja también lo dejaría al cerrarse mal.
    await File('$docs/$name.isar.lock').writeAsString('x');
  }

  final problems = <Map<String, dynamic>>[];
  LocalDbMover mover({LocalDbCounter? counter}) {
    problems.clear();
    return LocalDbMover(
      legacyDirectory: docs,
      newDirectory: data,
      name: name,
      counter: counter ?? IsarDatabase.countRecords,
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
    expect(await File('$data/$name.isar.lock').exists(), isFalse,
        reason: 'el candado viejo no se copia');
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
