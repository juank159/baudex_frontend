import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/customers/data/repositories/customer_offline_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

class _Db implements IIsarDatabase {
  _Db(this.database);
  @override
  final Isar database;
}

/// La búsqueda de clientes de facturación lee la base local (sirve sin
/// internet). El cajero escribe nombre y apellido juntos, en cualquier orden
/// y sin tildes: debe encontrar al cliente igual.
void main() {
  late Isar isar;
  late CustomerOfflineRepository repo;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_customers');
    isar = await Isar.open([IsarCustomerSchema], directory: dir.path);
    repo = CustomerOfflineRepository(database: _Db(isar));

    IsarCustomer c(String id, String first, String last,
            {String doc = '1', String? phone, DateTime? deletedAt}) =>
        IsarCustomer.create(
          serverId: id,
          firstName: first,
          lastName: last,
          email: '$id@x.com',
          phone: phone,
          documentType: IsarDocumentType.cc,
          documentNumber: doc,
          status: IsarCustomerStatus.active,
          creditLimit: 0,
          currentBalance: 0,
          paymentTerms: 30,
          totalPurchases: 0,
          totalOrders: 0,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          deletedAt: deletedAt,
          isSynced: true,
        );

    await isar.writeTxn(() => isar.isarCustomers.putAll([
          c('1', 'KEYLA', 'MAITA', doc: '51616136583'),
          c('2', 'YOLIMAR', 'DÍAZ', phone: '+573214569875'),
          c('3', 'Ender', 'Peña'),
          c('4', 'keyla', 'maita', deletedAt: DateTime(2026, 5, 11)),
          c('5', 'KEILA', 'DOS'),
        ]));
  });

  tearDown(() => isar.close(deleteFromDisk: true));

  Future<List<String>> search(String q) async =>
      (await repo.searchCustomers(q)).getOrElse(() => []).map((c) => c.id).toList();

  test('una palabra: nombre o apellido', () async {
    expect(await search('keyla'), ['1']);
    expect(await search('maita'), ['1']);
  });

  test('nombre y apellido juntos, en cualquier orden', () async {
    expect(await search('keyla maita'), ['1']);
    expect(await search('MAITA  Keyla'), ['1']);
  });

  test('sin tildes encuentra con tildes y al revés', () async {
    expect(await search('yolimar diaz'), ['2']);
    expect(await search('díaz'), ['2']);
    expect(await search('pena'), ['3']);
  });

  test('por documento y por teléfono', () async {
    expect(await search('51616'), ['1']);
    expect(await search('3214569'), ['2']);
  });

  test('no muestra clientes borrados ni los que no coinciden', () async {
    expect(await search('keyla dos'), isEmpty);
    expect(await search('keila'), ['5']);
  });

  test('rápida con muchos clientes (5.000)', () async {
    await isar.writeTxn(() => isar.isarCustomers.putAll([
          for (var i = 0; i < 5000; i++)
            IsarCustomer.create(
              serverId: 'm$i',
              firstName: 'Cliente$i',
              lastName: 'Apellido${i % 97}',
              email: 'm$i@x.com',
              documentType: IsarDocumentType.cc,
              documentNumber: '$i',
              status: IsarCustomerStatus.active,
              creditLimit: 0,
              currentBalance: 0,
              paymentTerms: 30,
              totalPurchases: 0,
              totalOrders: 0,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              isSynced: true,
            ),
        ]));
    final sw = Stopwatch()..start();
    final r = await search('cliente4999 apellido');
    sw.stop();
    expect(r, ['m4999']);
    // ignore: avoid_print
    print('búsqueda en 5.000 clientes: ${sw.elapsedMilliseconds} ms');
    expect(sw.elapsedMilliseconds, lessThan(500));
  });

  test('respeta el límite cuando se pide', () async {
    final r = (await repo.searchCustomers('a', limit: 2)).getOrElse(() => []);
    expect(r.length, 2);
  });
}
