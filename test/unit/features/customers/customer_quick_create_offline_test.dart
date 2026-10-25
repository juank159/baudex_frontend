import 'dart:ffi';
import 'dart:io';

import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/customer_credits/data/models/isar/isar_customer_credit.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_local_datasource.dart';
import 'package:baudex_desktop/features/customers/data/datasources/customer_remote_datasource.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/customers/data/repositories/customer_offline_repository.dart';
import 'package:baudex_desktop/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:baudex_desktop/features/customers/domain/entities/customer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

/// Crear un cliente desde la factura SIN internet y encontrarlo después en
/// el buscador de la factura (que lee la base del equipo). No se debe perder
/// ni duplicar nada.
class _FakeSync extends SyncService {
  _FakeSync() : super(null);
  final ops = <Map<String, dynamic>>[];
  bool fail = false;

  @override
  Future<void> onInit() async {}

  @override
  Future<void> addOperationForCurrentUser({
    required String entityType,
    required String entityId,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    if (fail) throw Exception('cola no disponible');
    ops.add({'entityType': entityType, 'entityId': entityId, ...data});
  }
}

class _Offline implements NetworkInfo {
  @override
  Future<bool> get isConnected async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Unused implements CustomerRemoteDataSource, CustomerLocalDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late Isar isar;
  late CustomerRepositoryImpl repo;
  late CustomerOfflineRepository search;
  late _FakeSync sync;

  setUpAll(() async {
    final lib = '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev/'
        'isar_flutter_libs-3.1.0+1/macos/libisar.dylib';
    await Isar.initializeIsarCore(libraries: {Abi.current(): lib});
  });

  IsarCustomer existing(String id, String first, String last, String doc, String email) =>
      IsarCustomer.create(
        serverId: id,
        firstName: first,
        lastName: last,
        email: email,
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
        isSynced: true,
      );

  Future<dynamic> create(String first, String last, String doc, String email) =>
      repo.createCustomer(
        firstName: first,
        lastName: last,
        email: email,
        documentType: DocumentType.cc,
        documentNumber: doc,
        status: CustomerStatus.active,
        creditLimit: 3000000,
        paymentTerms: 30,
      );

  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('isar_customers_quick');
    isar = await Isar.open(
      [IsarCustomerSchema, IsarCustomerCreditSchema],
      directory: dir.path,
    );
    IsarDatabase.debugSetDatabase(isar);
    Get.testMode = true;
    sync = _FakeSync();
    Get.put<SyncService>(sync);
    final unused = _Unused();
    repo = CustomerRepositoryImpl(
      remoteDataSource: unused,
      localDataSource: unused,
      networkInfo: _Offline(),
      database: IsarDatabase.instance,
    );
    search = CustomerOfflineRepository();
    await isar.writeTxn(() => isar.isarCustomers.put(
        existing('uuid-anny', 'ANNY', 'BECERRA', '0215692', 'cliente.0215692@local.baudex')));
  });

  tearDown(() async {
    Get.reset();
    await isar.close(deleteFromDisk: true);
    IsarDatabase.debugSetDatabase(null);
  });

  test('sin internet: se crea, queda en cola y aparece en el buscador', () async {
    final result = await create('Keyla', 'Maita', '786453', 'cliente.786453@local.baudex');

    expect(result.isRight(), isTrue);
    final customer = result.getOrElse(() => throw 'sin cliente') as Customer;
    expect(customer.id, startsWith('customer_offline_'));
    expect(sync.ops.single['entityType'], 'Customer');
    expect(sync.ops.single['documentNumber'], '786453');

    final found = await search.searchCustomers('keyla maita', limit: null);
    expect(found.getOrElse(() => []).map((c) => c.id), [customer.id]);
    final byDoc = await search.searchCustomers('786453', limit: null);
    expect(byDoc.getOrElse(() => []), hasLength(1));
  });

  test('documento ya registrado: avisa quién es y no crea nada', () async {
    final result = await create('Otra', 'Persona', '0215692', 'otra@x.com');

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f.message, contains('ANNY BECERRA')), (_) {});
    expect(sync.ops, isEmpty);
    expect(await isar.isarCustomers.count(), 1);
  });

  test('email ya registrado (sin importar mayúsculas): avisa quién es', () async {
    final result = await create('Otra', 'Persona', '555', 'CLIENTE.0215692@LOCAL.BAUDEX');

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f.message, contains('ANNY BECERRA')), (_) {});
  });

  test('si no se puede encolar, no queda un cliente a medias', () async {
    sync.fail = true;

    final result = await create('Luisa', 'Camargo', '21554783', 'luisa@x.com');

    expect(result.isLeft(), isTrue);
    expect(
      await isar.isarCustomers.filter().documentNumberEqualTo('21554783').count(),
      0,
    );
  });

  test('el cliente real se guarda aunque haya una copia temporal con su email', () async {
    await create('Keyla', 'Maita', '786453', 'keyla@x.com');

    // La descarga trae el cliente real con el mismo email (antes: "Unique
    // index violated" y se caía toda la página de clientes).
    await isar.writeTxn(() => isar.isarCustomers.putAllByServerId(
        [existing('uuid-keyla', 'Keyla', 'Maita', '786453', 'keyla@x.com')]));

    expect(
      await isar.isarCustomers.filter().serverIdEqualTo('uuid-keyla').count(),
      1,
    );
  });
}
