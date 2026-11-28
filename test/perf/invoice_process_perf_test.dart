// Medición: ¿cuánto tarda "Procesar" en el diálogo de pago, etapa por etapa,
// con o sin internet, con internet lento y con una base de negocio grande?
//
// Usa el código REAL de guardado (InvoiceRepositoryImpl → servidor; si falla,
// InvoiceOfflineRepositorySimple → Isar, FIFO, cola) contra:
//   * una base Isar TEMPORAL (nunca la real) de tamaño chico y grande,
//   * un servidor HTTP local al que se le pone la demora (0 ms, 300 ms, 2 s,
//     8 s, sin respuesta, error 500),
//   * un almacén de sesión simulado (nunca el llavero real) que pasa por la
//     misma fila `SerialQueue` que usa Windows.
//
//   flutter test test/perf/invoice_process_perf_test.dart
//   BAUDEX_PERF_SLOW=1 ... (incluye 8 s, sin respuesta y fila del almacén retenida)
// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/network/api_interceptor.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_store_migration.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/models/create_invoice_request_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/invoice_item_model.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart'
    show FlutterSecureStoragePlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/isar_test_lib.dart';
import '../unit/core/storage/secure_storage_lost_key_test.dart' show FakeProtector;

// ───────────────────────── dobles de prueba ─────────────────────────

/// Almacén de sesión simulado: cada operación pasa por una `SerialQueue`
/// real (la misma clase de la fila de Windows).
class _FakeSecure implements SecureStorageService {
  final queue = SerialQueue();
  Duration writeDelay = Duration.zero;
  int writes = 0;

  @override
  Future<String?> getToken() => queue.run(() async => 'token-de-prueba');
  @override
  Future<String> getOrCreateDeviceId() async => 'equipo-prueba';
  @override
  Future<String?> peekDeviceId() async => 'equipo-prueba';
  @override
  Future<void> write(String key, String value) => queue.run(() async {
        writes++;
        if (writeDelay > Duration.zero) await Future.delayed(writeDelay);
      });
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Cliente HTTP con la MISMA pila que la app: Dio + ApiInterceptor real.
class _FakeDioClient implements DioClient {
  _FakeDioClient(String baseUrl, SecureStorageService storage)
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ))
          ..interceptors.add(ApiInterceptor(storage));
  final Dio _dio;

  @override
  Future<Response> post(String endpoint,
          {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.post(endpoint, data: data, queryParameters: queryParameters, options: options);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Como el de la app: marcado como no disponible, deja de contar como
/// conectado hasta que se levanta la marca.
class _FakeNetwork implements NetworkInfo {
  bool connected = true;
  int markedUnreachable = 0;
  @override
  Future<bool> get isConnected async => connected;
  @override
  bool get isServerReachable => connected;
  @override
  void markServerUnreachable() {
    markedUnreachable++;
    connected = false;
  }

  @override
  void resetServerReachability() => connected = true;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeAuth extends GetxController implements AuthController {
  @override
  User? get currentUser => User(
        id: 'user-1',
        firstName: 'Caja',
        lastName: 'Uno',
        email: 'caja@prueba.test',
        role: UserRole.user,
        status: UserStatus.active,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        organizationId: 'org-1',
        organizationSlug: 'org-1',
      );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// SyncService real (encolar, contar pendientes) sin arrancar escuchas ni
/// temporizadores; sin internet para que no intente subir.
class _PerfSync extends SyncService {
  _PerfSync() : super(IsarDatabase.instance);
  @override
  Future<void> onInit() async {}
}

/// Complemento del almacén seguro simulado (nunca el llavero real): mientras
/// [gate] esté puesto, toda operación espera, como una escritura lenta.
class _SlowPlugin extends TestFlutterSecureStoragePlatform {
  _SlowPlugin(super.data);
  Completer<void>? gate;

  Future<void> _wait() async {
    final g = gate;
    if (g != null) await g.future;
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    await _wait();
    return super.read(key: key, options: options);
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async {
    await _wait();
    return Map<String, String>.of(data);
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    await _wait();
    return super.write(key: key, value: value, options: options);
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    await _wait();
    return super.delete(key: key, options: options);
  }
}

/// Servidor local con demora configurable para POST /invoices.
class _SlowServer {
  late HttpServer _server;
  Duration delay = Duration.zero;
  bool hang = false;
  int status = 201;
  late Map<String, dynamic> invoiceJson;
  final _hanging = <HttpResponse>[];

  String get baseUrl => 'http://127.0.0.1:${_server.port}/api';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      await req.drain<void>();
      if (hang) {
        _hanging.add(req.response); // nunca contesta
        return;
      }
      if (delay > Duration.zero) await Future.delayed(delay);
      req.response.statusCode = status;
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode(status < 300
          ? {'success': true, 'data': invoiceJson}
          : {'success': false, 'message': 'error'}));
      await req.response.close();
    });
  }

  Future<void> stop() async {
    for (final r in _hanging) {
      try {
        await r.close();
      } catch (_) {}
    }
    await _server.close(force: true);
  }
}

// ───────────────────────── datos ─────────────────────────

class _Size {
  const _Size(this.name, this.products, this.lots, this.invoices,
      this.pending, this.completed);
  final String name;
  final int products, lots, invoices, pending, completed;
}

Future<Isar> _openDb(_Size s) async {
  final dir = await Directory.systemTemp.createTemp('isar_process_perf');
  final isar = await Isar.open(IsarDatabase.schemas,
      directory: dir.path, name: 'p_${s.name}', maxSizeMiB: 4096);
  IsarDatabase.debugSetDatabase(isar);
  final now = DateTime(2026, 11, 1);

  for (var b = 0; b < s.products; b += 2000) {
    await isar.writeTxn(() => isar.isarProducts.putAll([
          for (var i = b; i < (b + 2000).clamp(0, s.products); i++)
            IsarProduct.create(
              serverId: 'prod-$i',
              name: 'Producto $i',
              sku: 'SKU$i',
              barcode: '770$i',
              type: IsarProductType.product,
              status: IsarProductStatus.active,
              stock: 1000,
              minStock: 1,
              categoryId: 'cat-1',
              createdAt: now,
              updatedAt: now,
              isSynced: true,
            ),
        ]));
  }
  final perProduct = s.lots ~/ s.products;
  for (var b = 0; b < s.lots; b += 4000) {
    await isar.writeTxn(() => isar.isarInventoryBatchs.putAll([
          for (var i = b; i < (b + 4000).clamp(0, s.lots); i++)
            IsarInventoryBatch.create(
              serverId: 'lot-$i',
              productId: 'prod-${i ~/ perProduct}',
              productName: 'Producto ${i ~/ perProduct}',
              productSku: 'SKU${i ~/ perProduct}',
              batchNumber: 'L$i',
              originalQuantity: 300,
              currentQuantity: 250,
              consumedQuantity: 50,
              unitCost: 1000,
              totalCost: 250000,
              entryDate: now.subtract(Duration(days: i % perProduct)),
              status: IsarInventoryBatchStatus.active,
              warehouseId: 'wh-1',
              createdAt: now,
              updatedAt: now,
              isSynced: true,
            ),
        ]));
  }
  final itemsJson = jsonEncode([
    for (var k = 0; k < 6; k++)
      {
        'id': 'it$k',
        'description': 'Producto de prueba $k',
        'quantity': 2,
        'unitPrice': 3500,
        'subtotal': 7000,
        'productId': 'prod-$k',
      }
  ]);
  for (var b = 0; b < s.invoices; b += 2000) {
    await isar.writeTxn(() => isar.isarInvoices.putAll([
          for (var i = b; i < (b + 2000).clamp(0, s.invoices); i++)
            IsarInvoice.create(
              serverId: 'inv-$i',
              number: 'FV-$i',
              date: now,
              dueDate: now,
              status: IsarInvoiceStatus.paid,
              paymentMethod: IsarPaymentMethod.cash,
              subtotal: 42000,
              taxPercentage: 0,
              taxAmount: 0,
              discountPercentage: 0,
              discountAmount: 0,
              total: 42000,
              paidAmount: 42000,
              balanceDue: 0,
              itemsJson: itemsJson,
              metadataJson: jsonEncode({'items': jsonDecode(itemsJson)}),
              customerId: 'cust-${i % 500}',
              createdAt: now,
              updatedAt: now,
              isSynced: true,
            ),
        ]));
  }
  await isar.writeTxn(() => isar.isarCustomers.putAll([
        for (var i = 0; i < 500; i++)
          IsarCustomer.create(
            serverId: 'cust-$i',
            firstName: 'Cliente$i',
            lastName: 'X',
            email: 'c$i@x.test',
            documentType: IsarDocumentType.cc,
            documentNumber: '10$i',
            status: IsarCustomerStatus.active,
            creditLimit: 0,
            currentBalance: 0,
            paymentTerms: 30,
            totalPurchases: 0,
            totalOrders: 0,
            createdAt: now,
            updatedAt: now,
            isSynced: true,
          ),
      ]));
  final payload = jsonEncode({
    'items': [
      for (var k = 0; k < 8; k++) {'productId': 'prod-$k', 'quantity': 1, 'unitPrice': 3500}
    ],
    'notes': 'x' * 300,
  });
  final total = s.pending + s.completed;
  for (var b = 0; b < total; b += 4000) {
    await isar.writeTxn(() => isar.syncOperations.putAll([
          for (var i = b; i < (b + 4000).clamp(0, total); i++)
            SyncOperation.create(
              entityType: i.isEven ? 'Invoice' : 'inventory_movement_fifo',
              entityId: 'op-$i',
              operationType: SyncOperationType.create,
              payload: payload,
              organizationId: 'org-1',
            )..status = i < s.pending ? SyncStatus.pending : SyncStatus.completed,
        ]));
  }
  return isar;
}

/// La venta de prueba: 10 productos distintos (los últimos del catálogo, para
/// que un recorrido completo no los encuentre al principio).
List<CreateInvoiceItemParams> _saleItems(_Size s) => [
      for (var k = 0; k < 10; k++)
        CreateInvoiceItemParams(
          description: 'Producto ${s.products - 1 - k}',
          quantity: 2,
          unitPrice: 3500,
          unit: 'und',
          productId: 'prod-${s.products - 1 - k}',
        ),
    ];

Map<String, dynamic> _serverInvoiceJson(_Size s) {
  const id = '0f8fad5b-d9cb-469f-a165-70867728950e';
  const at = '2026-11-27T10:00:00.000Z';
  return {
    'id': id,
    'number': 'FV-999999',
    'date': at,
    'dueDate': at,
    'status': 'paid',
    'paymentMethod': 'cash',
    'subtotal': 70000,
    'taxPercentage': 0,
    'taxAmount': 0,
    'discountPercentage': 0,
    'discountAmount': 0,
    'total': 70000,
    'paidAmount': 70000,
    'balanceDue': 0,
    'customerId': 'cust-1',
    'createdById': 'user-1',
    'items': [
      for (var k = 0; k < 10; k++)
        {
          'id': 'a1b2c3d4-0000-4000-8000-00000000000$k',
          'description': 'Producto ${s.products - 1 - k}',
          'quantity': 2,
          'unitPrice': 3500,
          'discountPercentage': 0,
          'discountAmount': 0,
          'subtotal': 7000,
          'unit': 'und',
          'invoiceId': id,
          'productId': 'prod-${s.products - 1 - k}',
          'createdAt': at,
          'updatedAt': at,
        },
    ],
    'payments': [],
    'createdAt': at,
    'updatedAt': at,
  };
}

double _ms(Stopwatch w) => w.elapsedMicroseconds / 1000;

// ───────────────────────── pruebas ─────────────────────────

void main() {
  final slow = Platform.environment['BAUDEX_PERF_SLOW'] == '1';
  const sizes = [
    _Size('chico', 500, 2000, 1000, 20, 1000),
    _Size('grande', 5000, 20000, 10000, 200, 20000),
  ];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // El binding de pruebas contesta 400 a todo HTTP: aquí se usa el servidor local.
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    await initIsarForTests();
    Get.testMode = true;
  });

  for (final size in sizes) {
    group('base ${size.name} (${size.products} productos, ${size.lots} lotes, '
        '${size.invoices} facturas, cola ${size.pending}+${size.completed})', () {
      late Isar isar;
      late _SlowServer server;
      late _FakeSecure secure;
      late _FakeNetwork network;
      late InvoiceRepositoryImpl repo;

      setUpAll(() async {
        final seed = Stopwatch()..start();
        isar = await _openDb(size);
        print('MEDICION [${size.name}] base sembrada en ${_ms(seed).toStringAsFixed(0)} ms');
        Get.put<AuthController>(_FakeAuth());
        Get.put<SyncService>(_PerfSync());
        server = _SlowServer()..invoiceJson = _serverInvoiceJson(size);
        await server.start();
        secure = _FakeSecure();
        network = _FakeNetwork();
        repo = InvoiceRepositoryImpl(
          remoteDataSource: InvoiceRemoteDataSourceImpl(
              dioClient: _FakeDioClient(server.baseUrl, secure)),
          localDataSource: InvoiceLocalDataSourceImpl(storageService: secure),
          networkInfo: network,
          offlineRepository: InvoiceOfflineRepositorySimple(),
        );
      });

      tearDownAll(() async {
        await server.stop();
        Get.reset();
        IsarDatabase.debugSetDatabase(null);
        await isar.close(deleteFromDisk: true);
      });

      Future<(double, Invoice?)> sell() async {
        final w = Stopwatch()..start();
        final r = await repo.createInvoice(
          customerId: 'cust-1',
          items: _saleItems(size),
          paymentMethod: PaymentMethod.cash,
          status: InvoiceStatus.paid,
        );
        return (_ms(w), r.fold((_) => null, (i) => i));
      }

      test('sonda: POST directo', () async {
        try {
          final r = await InvoiceRemoteDataSourceImpl(dioClient: _FakeDioClient(server.baseUrl, secure)).createInvoice(CreateInvoiceRequestModel(customerId: 'cust-1', items: _saleItems(size).map(CreateInvoiceItemRequestModel.fromEntity).toList(), paymentMethod: 'cash', status: 'paid'));
          print('SONDA ok ${r.id}');
          final wc = Stopwatch()..start();
          await InvoiceLocalDataSourceImpl(storageService: secure).cacheInvoice(r);
          print('MEDICION [${size.name}] guardar copia de la factura del servidor (Isar + almacén de sesión): ${_ms(wc).toStringAsFixed(1)} ms');
        } catch (e, st) { print('SONDA error $e $st'); }
      });

      test('consultas del guardado: recorrido completo (filter) vs índice (where)', () async {
        final pid = 'prod-${size.products - 1}';
        Future<double> t(Future<Object?> Function() f) async {
          final runs = <double>[];
          for (var i = 0; i < 7; i++) {
            final w = Stopwatch()..start();
            await f();
            runs.add(_ms(w));
          }
          runs.sort();
          return runs[3];
        }

        final lotsFilter = await t(() => isar.isarInventoryBatchs
            .filter().deletedAtIsNull().and().productIdEqualTo(pid).findAll());
        final lotsWhere = await t(() => isar.isarInventoryBatchs
            .where().productIdEqualTo(pid).filter().deletedAtIsNull().findAll());
        final prodFilter = await t(() =>
            isar.isarProducts.filter().serverIdEqualTo(pid).findFirst());
        final prodWhere = await t(() =>
            isar.isarProducts.where().serverIdEqualTo(pid).findFirst());
        final invFilter = await t(() => isar.isarInvoices
            .filter().serverIdEqualTo('inv-${size.invoices - 1}').findFirst());
        final invWhere = await t(() => isar.isarInvoices
            .where().serverIdEqualTo('inv-${size.invoices - 1}').findFirst());
        final pending = await t(() => isar.syncOperations
            .filter()
            .group((q) => q.statusEqualTo(SyncStatus.pending).or().statusEqualTo(SyncStatus.failed))
            .sortByPriority()
            .thenByCreatedAt()
            .findAll());
        print('MEDICION [${size.name}] lotes de 1 producto: filter ${lotsFilter.toStringAsFixed(2)} ms | where ${lotsWhere.toStringAsFixed(2)} ms');
        print('MEDICION [${size.name}] producto por serverId: filter ${prodFilter.toStringAsFixed(2)} ms | where ${prodWhere.toStringAsFixed(2)} ms');
        print('MEDICION [${size.name}] factura por serverId: filter ${invFilter.toStringAsFixed(2)} ms | where ${invWhere.toStringAsFixed(2)} ms');
        print('MEDICION [${size.name}] pendientes de la cola (por cada operación encolada): ${pending.toStringAsFixed(2)} ms');
      });

      test('sin internet: guardado local completo, por etapas', () async {
        network.connected = false;
        // Etapas sueltas (las mismas consultas del guardado sin internet).
        final sync = Get.find<SyncService>();
        final wq = Stopwatch()..start();
        await sync.addOperationForCurrentUser(
          entityType: 'Customer',
          entityId: 'probe',
          operationType: SyncOperationType.create,
          data: {'firstName': 'Sonda', 'lastName': 'Cola', 'documentNumber': '1'},
        );
        final enqueue = _ms(wq);
        final runs = <double>[];
        for (var i = 0; i < 3; i++) {
          final (ms, inv) = await sell();
          expect(inv, isNotNull);
          runs.add(ms);
        }
        print('MEDICION [${size.name}] SIN INTERNET: venta de 10 productos '
            '${runs.map((e) => e.toStringAsFixed(0)).join(' / ')} ms '
            '(encolar 1 operación: ${enqueue.toStringAsFixed(1)} ms; la venta encola 11)');
        // Comprobación con el dato: stock bajó y hay movimientos en la cola.
        final p = await isar.isarProducts
            .where().serverIdEqualTo('prod-${size.products - 1}').findFirst();
        print('MEDICION [${size.name}] stock prod final tras 3 ventas x2: ${p?.stock} (de 1000)');
        network.connected = true;
      }, timeout: const Timeout(Duration(minutes: 5)));

      final scenarios = <(String, Duration, bool, int)>[
        ('servidor 0 ms', Duration.zero, false, 201),
        ('servidor 300 ms', const Duration(milliseconds: 300), false, 201),
        ('servidor 2 s', const Duration(seconds: 2), false, 201),
        ('servidor error 500', Duration.zero, false, 500),
        if (slow) ('servidor 8 s', const Duration(seconds: 8), false, 201),
        if (slow) ('servidor sin respuesta', Duration.zero, true, 201),
      ];
      for (final (name, delay, hang, status) in scenarios) {
        test('con internet: $name', () async {
          network.connected = true; // cada escenario empieza con el servidor disponible
          server
            ..delay = delay
            ..hang = hang
            ..status = status;
          final writesBefore = secure.writes;
          final marksBefore = network.markedUnreachable;
          Future<double> stock() async => (await isar.isarProducts.where().serverIdEqualTo('prod-${size.products - 1}').findFirst())!.stock;
          final stockBefore = await stock();
          final (ms, inv) = await sell();
          // Segunda venta seguida: ¿aprendió que el servidor está lento?
          final (ms2, inv2) = await sell();
          print('MEDICION [${size.name}] CON INTERNET, $name: botón ocupado '
              '${ms.toStringAsFixed(0)} ms, venta siguiente ${ms2.toStringAsFixed(0)} ms '
              '(factura ${inv?.id.startsWith('invoice_offline_') == true ? 'local' : 'del servidor'}; '
              'escrituras al almacén de sesión ${secure.writes - writesBefore}; '
              'marcó servidor caído ${network.markedUnreachable - marksBefore} veces)');
          print('MEDICION [${size.name}]   stock del producto vendido: $stockBefore -> ${await stock()} (2 ventas x 2 und)');
          expect(inv, isNotNull);
          if (hang || status >= 500) {
            // El servidor no sirvió: la venta siguiente NO vuelve a esperarlo.
            expect(network.markedUnreachable - marksBefore, 1);
            expect(inv2?.id, startsWith('invoice_offline_'));
            expect(ms2, lessThan(1000), reason: 'la venta siguiente volvió a esperar al servidor');
          } else {
            expect(network.markedUnreachable - marksBefore, 0);
            expect(secure.writes - writesBefore, 0,
                reason: 'la venta escribió en el almacén de sesión');
          }
          network.connected = true;
        }, timeout: const Timeout(Duration(minutes: 3)));
      }

      if (size.name == 'chico') {
        test('almacén de sesión ocupado (escritura lenta de Windows) mientras se vende', () async {
          server
            ..delay = Duration.zero
            ..hang = false
            ..status = 201;
          network.connected = true;
          // El almacén REAL de la app sobre un complemento simulado, en modo
          // Windows (todas las operaciones pasan por una sola fila).
          debugDefaultTargetPlatformOverride = TargetPlatform.windows;
          SecureStorageService.debugSimulateRestart();
          SecureStorageService.debugResetQueue();
          SecureStorageService.debugProtector = FakeProtector();
          final plugin = _SlowPlugin({'auth_token': 'token-de-prueba'});
          FlutterSecureStoragePlatform.instance = plugin;
          final real = SecureStorageService();
          try {
            final realRepo = InvoiceRepositoryImpl(
              remoteDataSource: InvoiceRemoteDataSourceImpl(
                  dioClient: _FakeDioClient(server.baseUrl, real)),
              localDataSource: InvoiceLocalDataSourceImpl(storageService: real),
              networkInfo: network,
              offlineRepository: InvoiceOfflineRepositorySimple(),
            );
            Future<(double, Invoice?)> sellReal() async {
              final w = Stopwatch()..start();
              final r = await realRepo.createInvoice(
                customerId: 'cust-1',
                items: _saleItems(size),
                paymentMethod: PaymentMethod.cash,
                status: InvoiceStatus.paid,
              );
              return (_ms(w), r.fold((_) => null, (i) => i));
            }

            final (warm, _) = await sellReal(); // carga el token una vez
            // Una escritura del almacén que no termina (DPAPI lento,
            // antivirus): retiene la fila. QA midió 12 s de botón ocupado.
            plugin.gate = Completer<void>();
            var released = false;
            unawaited(real.write('otra_clave', 'valor').then((_) => released = true).catchError((_) => true));
            await Future<void>.delayed(const Duration(milliseconds: 30));
            final (ms, inv) = await sellReal();
            print('MEDICION [${size.name}] CON INTERNET, servidor 0 ms, almacén de sesión '
                'ocupado: botón ocupado ${ms.toStringAsFixed(0)} ms (sin almacén ocupado ${warm.toStringAsFixed(0)} ms; '
                'factura ${inv?.id.startsWith('invoice_offline_') == true ? 'local' : 'del servidor'})');
            expect(released, isFalse, reason: 'el almacén no estuvo ocupado durante la venta');
            expect(inv, isNotNull);
            expect(inv!.id, isNot(startsWith('invoice_offline_')));
            expect(ms, lessThan(1000), reason: 'la venta esperó al almacén de sesión');
            plugin.gate!.complete();
            plugin.gate = null;
          } finally {
            plugin.gate?.complete();
            debugDefaultTargetPlatformOverride = null;
            SecureStorageService.debugProtector = null;
            SecureStorageService.debugSimulateRestart();
            SecureStorageService.debugResetQueue();
          }
        }, timeout: const Timeout(Duration(minutes: 2)));
      }
    });
  }
}
