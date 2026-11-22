// Sync REAL de productos (SyncService + ProductRemoteDataSource) contra un
// servidor de PRUEBAS. Caso real (Granada): la cola guardaba
// taxCategory 'IVA' / retentionCategory 'RET_IVA' (valor del servidor) y la
// subida fallaba siempre con "Bad state: No element".
//
//   BAUDEX_E2E_URL=http://127.0.0.1:3106/api \
//   BAUDEX_E2E_EMAIL=... BAUDEX_E2E_PASSWORD=... \
//   BAUDEX_E2E_PSQL='docker exec ecommerce psql -U baudex_qa -d baudex_imp' \
//   BAUDEX_E2E_CATEGORY=<uuid de una categoría del negocio> \
//   flutter test test/e2e_local/product_tax_sync_e2e_test.dart
//
// Usa una base Isar temporal (nunca la del equipo) y no toca el llavero.
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/services/idempotency_service.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/products/data/datasources/product_remote_datasource.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:baudex_desktop/features/products/data/repositories/product_offline_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_isar.dart';

final _env = Platform.environment;
final _base = _env['BAUDEX_E2E_URL'];
final _psql = (_env['BAUDEX_E2E_PSQL'] ?? 'docker exec inv-test-pg psql -U postgres -d baudex_sim').split(' ');

class _SimClient implements DioClient {
  final Dio _dio;
  _SimClient(String token)
      : _dio = Dio(BaseOptions(baseUrl: _base!, headers: {
          'Authorization': 'Bearer $token',
          'X-Device-Id': 'app-e2e-impuesto',
        }));

  Exception _convert(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return ConnectionException('Error de conexión: ${e.message}');
    final body = e.response?.data;
    final raw = body is Map ? body['message'] : null;
    final message = raw is List ? raw.join(', ') : (raw?.toString() ?? '');
    if (status == 400) return ServerException('Solicitud incorrecta: $message', statusCode: 400);
    return ServerException('Error: $message', statusCode: status);
  }

  Future<Response> _wrap(Future<Response> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters, Options? options}) =>
      _wrap(() => _dio.get(endpoint, queryParameters: queryParameters, options: options));
  @override
  Future<Response> post(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _wrap(() => _dio.post(endpoint, data: data, queryParameters: queryParameters, options: options));
  @override
  Future<Response> patch(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _wrap(() => _dio.patch(endpoint, data: data, queryParameters: queryParameters, options: options));
  @override
  Future<Response> put(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _wrap(() => _dio.put(endpoint, data: data, queryParameters: queryParameters, options: options));
  @override
  Future<Response> delete(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _wrap(() => _dio.delete(endpoint, data: data, queryParameters: queryParameters, options: options));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

dynamic _unwrap(dynamic body) {
  var current = body;
  while (current is Map && current.containsKey('data') && current.containsKey('success')) {
    current = current['data'];
  }
  return current;
}

Future<String> _sql(String query) async {
  final result = await Process.run(_psql.first, [..._psql.skip(1), '-At', '-c', query]);
  return (result.stdout as String).trim();
}

/// impuesto guardado en el servidor: "categoria|tasa|retención|tasa|tiene"
Future<String> _taxBySku(String sku) => _sql(
    "select tax_category||'|'||tax_rate||'|'||coalesce(retention_category::text,'-')||'|'||coalesce(retention_rate,0)||'|'||has_retention "
    "from products where sku='$sku' and deleted_at is null");

void main() {
  if (_base == null) {
    test('sync de producto con impuesto (omitida: falta BAUDEX_E2E_URL)', () {}, skip: 'Requiere el servidor de pruebas');
    return;
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  // El binding de pruebas bloquea la red; esta prueba sí va al servidor local.
  HttpOverrides.global = null;

  final run = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  final categoryId = _env['BAUDEX_E2E_CATEGORY']!;
  late Isar isar;
  late SyncService sync;
  late Dio raw;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // connectivity_plus: hay red (sin canal real).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => ['wifi'],
    );
    raw = Dio(BaseOptions(baseUrl: _base!, headers: {'X-Device-Id': 'app-e2e-impuesto'}));
    final login = await raw.post('/auth/login', data: {
      'email': _env['BAUDEX_E2E_EMAIL'],
      'password': _env['BAUDEX_E2E_PASSWORD'],
    });
    final token = _unwrap(login.data)['token'] as String;
    raw.options.headers['Authorization'] = 'Bearer $token';

    isar = await openTestIsar();
    Get.put<IsarDatabase>(IsarDatabase.instance);
    Get.put<IdempotencyService>(IdempotencyService());
    Get.put<ProductRemoteDataSource>(ProductRemoteDataSourceImpl(dioClient: _SimClient(token)));
    Get.put<ProductOfflineRepository>(ProductOfflineRepository(database: IsarDatabase.instance));
    sync = SyncService(IsarDatabase.instance);
    await sync.onInit();
  });

  tearDownAll(() async {
    sync.onClose();
    Get.reset();
    await closeTestIsar(isar);
  });

  Future<SyncOperation> enqueue(String entityId, SyncOperationType type, Map<String, dynamic> data) async {
    final op = SyncOperation.create(
      entityType: 'Product',
      entityId: entityId,
      operationType: type,
      payload: jsonEncode(data),
      organizationId: 'org-e2e',
      priority: 1,
    );
    await IsarDatabase.instance.addSyncOperation(op);
    return op;
  }

  Map<String, dynamic> payload(String sku, {required String name}) => {
        // Igual que product_repository_impl: enums de producto por nombre,
        // impuesto por VALOR del servidor.
        'name': name,
        'sku': sku,
        'type': 'product',
        'status': 'active',
        'stock': 5,
        'minStock': 1,
        'unit': 'und',
        'categoryId': categoryId,
        'prices': [
          {'type': 'price1', 'name': 'Público', 'amount': 3500, 'currency': 'COP'},
        ],
        'taxCategory': 'IVA',
        'taxRate': 19,
        'isTaxable': true,
        'retentionCategory': 'RET_IVA',
        'retentionRate': 15,
        'hasRetention': true,
      };

  Future<List<SyncOperation>> queue() => isar.syncOperations.where().findAll();

  test('create (sin copia en Isar, usa el payload) y update con IVA/RET_IVA suben y la cola queda vacía', () async {
    // Producto existente en el servidor, sin impuesto, para el update.
    final skuU = 'IMP-U-$run';
    final created = _unwrap((await raw.post('/products', data: {
      'name': 'Imp update $run',
      'sku': skuU,
      'categoryId': categoryId,
      'stock': 0,
      'minStock': 0,
      'prices': [
        {'type': 'price1', 'name': 'Público', 'amount': 1000, 'currency': 'COP'},
      ],
    }))
        .data);
    final updateId = created['id'] as String;
    expect(await _taxBySku(skuU), startsWith('NO_GRAVADO|'));

    final skuC = 'IMP-C-$run';
    await enqueue('product_offline_${run}_c', SyncOperationType.create, payload(skuC, name: 'Imp create $run'));
    await enqueue(updateId, SyncOperationType.update, payload(skuU, name: 'Imp update editado $run'));

    await sync.syncAll(ignoreBackoff: true);

    final left = await queue();
    for (final op in left) {
      // ignore: avoid_print
      print('COLA: ${op.entityId} ${op.operationType.name} ${op.status.name} retry=${op.retryCount} error=${op.error}');
    }
    expect(left.where((o) => o.status != SyncStatus.completed), isEmpty, reason: 'la cola debe quedar vacía');
    expect(await _taxBySku(skuC), 'IVA|19.00|RET_IVA|15.00|true');
    expect(await _taxBySku(skuU), 'IVA|19.00|RET_IVA|15.00|true');
    expect(await _sql("select name from products where id='$updateId'"), 'Imp update editado $run'.toUpperCase()); // el servidor guarda el nombre en mayúsculas
  });

  test('create de producto offline que SÍ está en Isar con IVA: ¿sube con su impuesto?', () async {
    final sku = 'IMP-I-$run';
    final tempId = 'product_offline_${run}_i';
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.isarProducts.put(IsarProduct.create(
        serverId: tempId,
        name: 'Imp isar $run',
        sku: sku,
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 5,
        minStock: 1,
        categoryId: categoryId,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
        taxCategory: IsarTaxCategory.iva,
        taxRate: 19,
        isTaxable: true,
        retentionCategory: IsarRetentionCategory.retIva,
        retentionRate: 15,
        hasRetention: true,
      ));
    });
    await enqueue(tempId, SyncOperationType.create, payload(sku, name: 'Imp isar $run'));

    await sync.syncAll(ignoreBackoff: true);

    final pending = (await queue()).where((o) => o.status != SyncStatus.completed).toList();
    for (final op in pending) {
      // ignore: avoid_print
      print('COLA: ${op.entityId} ${op.status.name} error=${op.error}');
    }
    expect(pending, isEmpty);
    final tax = await _taxBySku(sku);
    // ignore: avoid_print
    print('IMPUESTO EN SERVIDOR (producto offline leído de Isar): $tax');
    expect(tax, 'IVA|19.00|RET_IVA|15.00|true');
  });

  test('create + update del mismo producto: la limpieza borra el UPDATE pero sus cambios suben', () async {
    final sku = 'IMP-M-$run';
    final tempId = 'product_offline_${run}_m';
    final now = DateTime.now();
    // Copia en Isar sin impuesto (como la deja ProductOfflineRepository).
    await isar.writeTxn(() async {
      await isar.isarProducts.put(IsarProduct.create(
        serverId: tempId,
        name: 'Imp merge $run',
        sku: sku,
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 5,
        minStock: 1,
        categoryId: categoryId,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      ));
    });
    final createData = payload(sku, name: 'Imp merge $run')
      ..remove('taxCategory')
      ..remove('taxRate')
      ..remove('isTaxable')
      ..remove('retentionCategory')
      ..remove('retentionRate')
      ..remove('hasRetention');
    await enqueue(tempId, SyncOperationType.create, createData);
    await enqueue(tempId, SyncOperationType.update, {
      'taxCategory': 'IVA',
      'taxRate': 19,
      'isTaxable': true,
      'retentionCategory': 'RET_IVA',
      'retentionRate': 15,
      'hasRetention': true,
      'prices': [
        {'type': 'price1', 'name': 'Público', 'amount': 4200, 'currency': 'COP'},
      ],
    });

    await sync.syncAll(ignoreBackoff: true);

    final pending = (await queue()).where((o) => o.status != SyncStatus.completed).toList();
    expect(pending, isEmpty);
    expect(await _taxBySku(sku), 'IVA|19.00|RET_IVA|15.00|true');
    expect(
      await _sql("select pp.amount from product_prices pp join products p on p.id=pp.product_id "
          "where p.sku='$sku' and pp.type='price1' and pp.deleted_at is null"),
      '4200.00',
    );
  });
}
