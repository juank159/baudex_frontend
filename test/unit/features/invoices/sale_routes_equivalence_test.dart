// La MISMA venta por las dos rutas de guardado debe dar lo mismo.
//
// Ruta con servidor: InvoiceRepositoryImpl → POST /invoices → copia local.
// Ruta local: InvoiceOfflineRepositorySimple → Isar + cola de subida.
//
// Desde que un tope de tiempo o un 5xx marcan el servidor como no disponible,
// más ventas pasan por la ruta local. Aquí se comprueba, con el código REAL
// de las dos rutas, que:
//   * dan el mismo total, los mismos pagos (por moneda y tasa), el mismo
//     saldo de crédito y el mismo stock y lotes;
//   * lo que la cola le manda al servidor es la misma venta que le habría
//     mandado la ruta con servidor, y la manda UNA sola vez;
//   * la marca de "servidor no disponible" se pone y se levanta sola.
//
// Base Isar temporal (nunca la del equipo), servidor HTTP local, sin llavero.
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/api_interceptor.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/services/idempotency_service.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/app/data/local/sync_queue.dart';
import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/features/auth/domain/entities/user.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';
import 'package:baudex_desktop/features/customer_credits/data/models/isar/isar_customer_credit.dart';
import 'package:baudex_desktop/features/customers/data/models/isar/isar_customer.dart';
import 'package:baudex_desktop/features/inventory/data/models/isar/isar_inventory_batch.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_local_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/datasources/invoice_remote_datasource.dart';
import 'package:baudex_desktop/features/invoices/data/models/isar/isar_invoice.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_offline_repository_simple.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/invoice_repository_impl.dart';
import 'package:baudex_desktop/features/invoices/data/repositories/sale_server_down_rule.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:baudex_desktop/features/products/data/models/isar/isar_product.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_isar.dart';

// ───────────────────────── datos de la venta ─────────────────────────

const _customerId = 'b0000000-0000-4000-8000-000000000001';
const _p1 = 'a0000000-0000-4000-8000-000000000001';
const _p2 = 'a0000000-0000-4000-8000-000000000002';
const _bank = 'd0000000-0000-4000-8000-000000000001';

/// 2 × 3.500 + 1 × 10.000 = 17.000
const _items = [
  CreateInvoiceItemParams(
      description: 'Producto uno', quantity: 2, unitPrice: 3500, unit: 'und', productId: _p1),
  CreateInvoiceItemParams(
      description: 'Producto dos', quantity: 1, unitPrice: 10000, unit: 'und', productId: _p2),
];

class _Case {
  const _Case(
    this.name, {
    required this.method,
    required this.status,
    this.metadata,
    this.taxPercentage = 0,
    this.discountPercentage = 0,
    required this.total,
    required this.paid,
    required this.balance,
    required this.payments,
    this.credit = 0,
    this.stockMoves = true,
    this.serverRouteMovesDraftStock = false,
  });
  final String name;
  final PaymentMethod method;
  final InvoiceStatus status;
  final Map<String, dynamic>? metadata;
  final double taxPercentage;
  final double discountPercentage;

  // Lo esperado, calculado a mano.
  final double total;
  final double paid;
  final double balance;

  /// método|monto|moneda|monto en esa moneda|tasa
  final List<String> payments;
  final double credit;
  final bool stockMoves;

  /// Diferencia que YA existía (no la introduce este cambio): al guardar un
  /// borrador por la ruta con servidor, la app descuenta el stock local
  /// aunque un borrador no mueve inventario; la siguiente bajada lo corrige.
  final bool serverRouteMovesDraftStock;
}

final _cases = <_Case>[
  const _Case('efectivo',
      method: PaymentMethod.cash,
      status: InvoiceStatus.paid,
      total: 17000,
      paid: 17000,
      balance: 0,
      payments: ['cash|17000.00|-|-|-']),
  const _Case('efectivo con IVA 19% y descuento 10%',
      method: PaymentMethod.cash,
      status: InvoiceStatus.paid,
      taxPercentage: 19,
      discountPercentage: 10,
      // 17.000 − 1.700 = 15.300; + 19% (2.907) = 18.207
      total: 18207,
      paid: 18207,
      balance: 0,
      payments: ['cash|18207.00|-|-|-']),
  const _Case('a crédito',
      method: PaymentMethod.credit,
      status: InvoiceStatus.pending,
      // Como lo arma la pantalla de venta.
      metadata: {'createCreditForRemaining': true, 'remainingBalance': 17000, 'isPureCreditInvoice': true},
      total: 17000,
      paid: 0,
      balance: 17000,
      payments: [],
      credit: 17000),
  const _Case('borrador',
      method: PaymentMethod.cash,
      status: InvoiceStatus.draft,
      total: 17000,
      paid: 0,
      balance: 17000,
      payments: [],
      stockMoves: false,
      serverRouteMovesDraftStock: true),
  const _Case('pago múltiple con el resto a crédito',
      method: PaymentMethod.cash,
      status: InvoiceStatus.partiallyPaid,
      metadata: {
        'multiplePayments': [
          {'amount': 5000, 'method': 'cash', 'bankAccountId': null, 'bankAccountName': null},
          {'amount': 4000, 'method': 'bank_transfer', 'bankAccountId': _bank, 'bankAccountName': 'Banco'},
        ],
        'totalPaid': 9000,
        'remainingBalance': 8000,
        'createCreditForRemaining': true,
        'isMultiplePayment': true,
      },
      total: 17000,
      paid: 9000,
      balance: 8000,
      payments: ['bank_transfer|4000.00|-|-|-', 'cash|5000.00|-|-|-'],
      credit: 8000),
  const _Case('dos monedas con tasa (pesos + dólares a 4.000)',
      method: PaymentMethod.cash,
      status: InvoiceStatus.paid,
      metadata: {
        'multiplePayments': [
          {'amount': 10000, 'method': 'cash', 'bankAccountId': null, 'bankAccountName': null},
          {
            'amount': 7000,
            'method': 'cash',
            'bankAccountId': null,
            'bankAccountName': null,
            'paymentCurrency': 'USD',
            'paymentCurrencyAmount': 1.75,
            'exchangeRate': 4000,
          },
        ],
        'totalPaid': 17000,
        'remainingBalance': 0,
        'createCreditForRemaining': false,
        'isMultiplePayment': true,
      },
      total: 17000,
      paid: 17000,
      balance: 0,
      payments: ['cash|10000.00|-|-|-', 'cash|7000.00|USD|1.75|4000.00']),
  const _Case('una moneda extranjera (pago simple en dólares)',
      method: PaymentMethod.cash,
      status: InvoiceStatus.paid,
      metadata: {'paymentCurrency': 'USD', 'paymentCurrencyAmount': 4.25, 'exchangeRate': 4000},
      total: 17000,
      paid: 17000,
      balance: 0,
      payments: ['cash|17000.00|USD|4.25|4000.00']),
  const _Case('con saldo a favor (5.000) y el resto en efectivo',
      method: PaymentMethod.cash,
      status: InvoiceStatus.paid,
      metadata: {'clientBalanceApplied': 5000, 'clientId': _customerId},
      total: 17000,
      paid: 17000,
      balance: 0,
      payments: ['cash|12000.00|-|-|-', 'client_balance|5000.00|-|-|-']),
];

// ───────────────────────── servidor de referencia ─────────────────────────

String _normalizeMethod(String name) => switch (name.toLowerCase()) {
      'creditcard' => 'credit_card',
      'debitcard' => 'debit_card',
      'banktransfer' => 'bank_transfer',
      'clientbalance' => 'client_balance',
      _ => name,
    };

/// Lo que el servidor hace con una venta: totales, pagos y crédito.
Map<String, dynamic> _serverInvoice(Map<String, dynamic> body, int n) {
  final id = 'f0000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
  const at = '2026-11-27T10:00:00.000Z';
  final items = (body['items'] as List).cast<Map<String, dynamic>>();
  var subtotal = 0.0;
  final outItems = <Map<String, dynamic>>[];
  for (var k = 0; k < items.length; k++) {
    final it = items[k];
    final line = (it['quantity'] as num) * (it['unitPrice'] as num) -
        ((it['discountAmount'] ?? 0) as num);
    subtotal += line;
    outItems.add({
      'id': 'e0000000-0000-4000-8000-${(n * 10 + k).toString().padLeft(12, '0')}',
      'description': it['description'],
      'quantity': it['quantity'],
      'unitPrice': it['unitPrice'],
      'discountPercentage': it['discountPercentage'] ?? 0,
      'discountAmount': it['discountAmount'] ?? 0,
      'subtotal': line,
      'unit': it['unit'],
      'invoiceId': id,
      'productId': it['productId'],
      'createdAt': at,
      'updatedAt': at,
    });
  }
  final discountPct = ((body['discountPercentage'] ?? 0) as num).toDouble();
  final discountAmt = ((body['discountAmount'] ?? 0) as num).toDouble();
  final discount = discountAmt > 0 ? discountAmt : subtotal * discountPct / 100;
  final taxPct = ((body['taxPercentage'] ?? 0) as num).toDouble();
  final tax = (subtotal - discount) * taxPct / 100;
  final total = subtotal - discount + tax;

  final status = (body['status'] ?? 'draft') as String;
  final meta = (body['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
  final payments = <Map<String, dynamic>>[];
  void pay(num amount, String method, [Map? extra]) => payments.add({
        'id': 'c1000000-0000-4000-8000-${(n * 10 + payments.length).toString().padLeft(12, '0')}',
        'amount': amount,
        'paymentMethod': method,
        'paymentDate': at,
        'invoiceId': id,
        'createdById': 'user-1',
        'organizationId': 'org-1',
        'paymentCurrency': extra?['paymentCurrency'],
        'paymentCurrencyAmount': extra?['paymentCurrencyAmount'],
        'exchangeRate': extra?['exchangeRate'],
        'createdAt': at,
        'updatedAt': at,
      });
  if (status == 'paid' || status == 'partially_paid') {
    final applied = ((meta['clientBalanceApplied'] ?? 0) as num).toDouble();
    if (applied > 0) pay(applied, 'client_balance');
    final multiple = meta['multiplePayments'];
    if (meta['isMultiplePayment'] == true && multiple is List && multiple.isNotEmpty) {
      for (final p in multiple.cast<Map>()) {
        pay(p['amount'] as num, _normalizeMethod(p['method'] as String? ?? 'cash'), p);
      }
    } else if (total - applied > 0) {
      pay(total - applied, body['paymentMethod'] as String, meta);
    }
  }
  final paid = payments.fold<double>(0, (s, p) => s + (p['amount'] as num));
  return {
    'id': id,
    'number': 'FV-$n',
    'date': at,
    'dueDate': at,
    'status': status,
    'paymentMethod': body['paymentMethod'],
    'subtotal': subtotal,
    'taxPercentage': taxPct,
    'taxAmount': tax,
    'discountPercentage': discountPct,
    'discountAmount': discount,
    'total': total,
    'paidAmount': paid,
    'balanceDue': total - paid > 0 ? total - paid : 0,
    'customerId': body['customerId'],
    'createdById': 'user-1',
    'metadata': body['metadata'],
    'items': outItems,
    'payments': payments,
    'createdAt': at,
    'updatedAt': at,
  };
}

/// Crédito que el servidor abre junto con la factura.
double _serverCredit(Map<String, dynamic> body, Map<String, dynamic> invoice) {
  final pureCredit = body['paymentMethod'] == 'credit' && invoice['status'] == 'pending';
  final remaining = (body['metadata'] as Map?)?['createCreditForRemaining'] == true;
  if (!pureCredit && !remaining) return 0;
  return (invoice['total'] as num).toDouble() - (invoice['paidAmount'] as num).toDouble();
}

enum _Mode { ok, hang, error500, reject400, badBody }

class _Server {
  late HttpServer _http;
  _Mode mode = _Mode.ok;
  final invoiceBodies = <Map<String, dynamic>>[];
  final invoiceKeys = <String?>[];
  final _hanging = <HttpResponse>[];
  int _n = 0;

  int get port => _http.port;
  String get baseUrl => 'http://127.0.0.1:$port/api';

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen((req) async {
      final raw = await utf8.decoder.bind(req).join();
      void reply(int status, Object body) {
        req.response.statusCode = status;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(body));
        req.response.close();
      }

      if (mode == _Mode.hang) {
        if (req.method == 'POST' && req.uri.path == '/api/invoices') {
          invoiceBodies.add(jsonDecode(raw) as Map<String, dynamic>);
          invoiceKeys.add(req.headers.value('idempotency-key'));
        }
        _hanging.add(req.response); // no contesta (tampoco /health)
        return;
      }
      if (req.uri.path.endsWith('/health')) return reply(200, {'ok': true});
      if (req.method == 'POST' && req.uri.path == '/api/invoices') {
        final body = jsonDecode(raw) as Map<String, dynamic>;
        invoiceBodies.add(body);
        invoiceKeys.add(req.headers.value('idempotency-key'));
        switch (mode) {
          case _Mode.error500:
            return reply(500, {'success': false, 'message': 'error interno'});
          case _Mode.reject400:
            return reply(400, {'success': false, 'message': 'El cliente supera su cupo de crédito'});
          case _Mode.badBody:
            return reply(201, {'success': false});
          default:
            return reply(201, {'success': true, 'data': _serverInvoice(body, ++_n)});
        }
      }
      reply(200, {'success': true, 'data': <String, dynamic>{}});
    });
  }

  Future<void> stop() async {
    for (final r in _hanging) {
      try {
        await r.close();
      } catch (_) {}
    }
    await _http.close(force: true);
  }
}

// ───────────────────────── dobles de prueba ─────────────────────────

class _Storage implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'token-de-prueba';
  @override
  Future<bool> hasToken() async => true;
  @override
  Future<String> getOrCreateDeviceId() async => 'equipo-prueba';
  @override
  Future<String?> peekDeviceId() async => 'equipo-prueba';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Cliente HTTP con el interceptor REAL y la misma conversión de errores
/// que el de la app. [receiveTimeout] acorta el tope de espera de la
/// respuesta (en la app son 15 s) para no alargar la prueba.
class _Client implements DioClient {
  _Client(String baseUrl, SecureStorageService storage)
      : _dio = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 3)))
          ..interceptors.add(ApiInterceptor(storage));
  final Dio _dio;
  Duration? receiveTimeout;

  Exception _convert(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const RequestTimeoutException();
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map ? (data['message']?.toString() ?? '') : '';
        if (status == 400) return ServerException('Solicitud incorrecta: $message', statusCode: 400);
        return ServerException('Error: $message', statusCode: status);
      case DioExceptionType.cancel:
        return const ServerException('Solicitud cancelada');
      default:
        return DioClient.connectionExceptionFor(e);
    }
  }

  Future<Response> _run(Future<Response> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  Options? _opts(Options? o) =>
      receiveTimeout == null ? o : (o ?? Options()).copyWith(receiveTimeout: receiveTimeout);

  @override
  Future<Response> post(String endpoint,
          {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _run(() => _dio.post(endpoint, data: data, queryParameters: queryParameters, options: _opts(options)));
  @override
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters, Options? options}) =>
      _run(() => _dio.get(endpoint, queryParameters: queryParameters, options: _opts(options)));
  @override
  Future<Response> patch(String endpoint,
          {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _run(() => _dio.patch(endpoint, data: data, queryParameters: queryParameters, options: _opts(options)));
  @override
  Future<Response> put(String endpoint,
          {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _run(() => _dio.put(endpoint, data: data, queryParameters: queryParameters, options: _opts(options)));
  @override
  Future<Response> delete(String endpoint,
          {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _run(() => _dio.delete(endpoint, data: data, queryParameters: queryParameters, options: _opts(options)));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Net implements NetworkInfo {
  bool connected = true;
  int marks = 0;
  @override
  Future<bool> get isConnected async => connected;
  @override
  bool get isServerReachable => connected;
  @override
  void markServerUnreachable() {
    marks++;
    connected = false;
  }

  @override
  void resetServerReachability() => connected = true;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Auth extends GetxController implements AuthController {
  @override
  bool get isAuthenticated => true;
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

/// Cola real (encolar y contar) sin escuchas ni temporizadores: no sube.
class _QueueOnlySync extends SyncService {
  _QueueOnlySync() : super(IsarDatabase.instance);
  @override
  Future<void> onInit() async {}
}

// ───────────────────────── base de prueba ─────────────────────────

Future<void> _seed(Isar isar) async {
  final now = DateTime(2026, 11, 1);
  IsarProduct product(String id, String name) => IsarProduct.create(
        serverId: id,
        name: name,
        sku: 'SKU-${id.substring(id.length - 2)}',
        type: IsarProductType.product,
        status: IsarProductStatus.active,
        stock: 100,
        minStock: 1,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
        isSynced: true,
      );
  IsarInventoryBatch lot(String id, String productId, int qty, int daysAgo) =>
      IsarInventoryBatch.create(
        serverId: id,
        productId: productId,
        productName: productId,
        productSku: productId,
        batchNumber: id,
        originalQuantity: qty,
        currentQuantity: qty,
        consumedQuantity: 0,
        unitCost: 1000,
        totalCost: 1000.0 * qty,
        entryDate: now.subtract(Duration(days: daysAgo)),
        status: IsarInventoryBatchStatus.active,
        warehouseId: 'wh-1',
        createdAt: now,
        updatedAt: now,
        isSynced: true,
      );
  await isar.writeTxn(() async {
    await isar.clear();
    await isar.isarProducts.putAll([product(_p1, 'Producto uno'), product(_p2, 'Producto dos')]);
    // Producto uno: el lote más viejo solo tiene 1 → la venta de 2 toma de dos lotes.
    await isar.isarInventoryBatchs.putAll([
      lot('lote-viejo', _p1, 1, 30),
      lot('lote-nuevo', _p1, 99, 5),
      lot('lote-dos', _p2, 100, 10),
    ]);
    await isar.isarCustomers.put(IsarCustomer.create(
      serverId: _customerId,
      firstName: 'Clienta',
      lastName: 'Prueba',
      email: 'clienta@x.test',
      documentType: IsarDocumentType.cc,
      documentNumber: '1001',
      status: IsarCustomerStatus.active,
      creditLimit: 1000000,
      currentBalance: 15000,
      paymentTerms: 30,
      totalPurchases: 0,
      totalOrders: 0,
      createdAt: now,
      updatedAt: now,
      isSynced: true,
    ));
  });
}

String _money(num? v) => v == null ? '-' : v.toDouble().toStringAsFixed(2);

List<String> _paymentLines(Invoice invoice) => [
      for (final p in invoice.payments)
        '${p.paymentMethod.value}|${_money(p.amount)}|${p.paymentCurrency ?? '-'}|'
            '${p.paymentCurrencyAmount ?? '-'}|${_money(p.exchangeRate)}'
    ]..sort();

/// Lo que queda en el equipo después de la venta.
Future<Map<String, Object?>> _deviceState(Isar isar) async {
  final lots = await isar.isarInventoryBatchs.where().findAll();
  final p1 = await isar.isarProducts.where().serverIdEqualTo(_p1).findFirst();
  final p2 = await isar.isarProducts.where().serverIdEqualTo(_p2).findFirst();
  return {
    'stock uno': p1!.stock,
    'stock dos': p2!.stock,
    for (final l in lots) 'lote ${l.serverId}': l.currentQuantity,
  };
}

/// La venta tal como la recibe el servidor (lo que decide totales, pagos,
/// crédito y stock allá).
Map<String, Object?> _saleAsSent(Map<String, dynamic> body) => {
      'customerId': body['customerId'],
      'paymentMethod': body['paymentMethod'],
      'status': body['status'],
      'taxPercentage': (body['taxPercentage'] as num?)?.toDouble() ?? 0,
      'discountPercentage': (body['discountPercentage'] as num?)?.toDouble() ?? 0,
      'metadata': jsonEncode(body['metadata']),
      'bankAccountId': body['bankAccountId'],
      'items': [
        for (final it in (body['items'] as List).cast<Map>())
          '${it['productId']}|${_money(it['quantity'] as num)}|${_money(it['unitPrice'] as num)}|'
              '${_money((it['discountPercentage'] ?? 0) as num)}|${_money((it['discountAmount'] ?? 0) as num)}'
      ],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late _Server server;
  late _Client client;

  setUpAll(() async {
    HttpOverrides.global = null; // el binding de pruebas bloquea la red
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async => ['wifi'],
    );
    isar = await openTestIsar();
    server = _Server();
    await server.start();
    dotenv.testLoad(
        fileInput: 'SERVER_IP=127.0.0.1\nSERVER_PORT=${server.port}\nAPP_ENV=development');
    Get.testMode = true;
  });

  tearDownAll(() async {
    await server.stop();
    await closeTestIsar(isar);
  });

  InvoiceRepositoryImpl buildRepo(NetworkInfo net) {
    client = _Client(server.baseUrl, _Storage());
    return InvoiceRepositoryImpl(
      remoteDataSource: InvoiceRemoteDataSourceImpl(dioClient: client),
      localDataSource: InvoiceLocalDataSourceImpl(storageService: _Storage()),
      networkInfo: net,
      offlineRepository: InvoiceOfflineRepositorySimple(),
    );
  }

  Future<Either2> sell(InvoiceRepositoryImpl repo, _Case c) async {
    final w = Stopwatch()..start();
    final r = await repo.createInvoice(
      customerId: _customerId,
      items: _items,
      paymentMethod: c.method,
      status: c.status,
      taxPercentage: c.taxPercentage,
      discountPercentage: c.discountPercentage,
      metadata: c.metadata == null ? null : jsonDecode(jsonEncode(c.metadata)) as Map<String, dynamic>,
    );
    return Either2(r.fold((f) => null, (i) => i), r.fold((f) => f.message, (_) => null), w.elapsedMilliseconds);
  }

  group('regla: qué fallo marca el servidor como no disponible', () {
    test('tope de tiempo, sin conexión, 5xx y 408: sí', () {
      expect(saleFailureMeansServerDown(const RequestTimeoutException()), isTrue);
      expect(saleFailureMeansServerDown(const ConnectionException('Sin conexión')), isTrue);
      for (final s in [500, 502, 503, 504, 408]) {
        expect(saleFailureMeansServerDown(ServerException('x', statusCode: s)), isTrue, reason: '$s');
      }
    });
    test('rechazo de negocio (cupo, stock, validación, permisos), 429 y respuesta ilegible: no', () {
      for (final s in [400, 401, 403, 404, 409, 422, 429]) {
        expect(saleFailureMeansServerDown(ServerException('x', statusCode: s)), isFalse, reason: '$s');
      }
      expect(saleFailureMeansServerDown(const ServerException('Respuesta inválida del servidor')), isFalse);
      expect(saleFailureMeansServerDown(const CacheException()), isFalse);
      expect(saleFailureMeansServerDown(StateError('x')), isFalse);
    });
  });

  group('la misma venta por la ruta con servidor y por la ruta local', () {
    late _Net net;
    late InvoiceRepositoryImpl repo;

    setUp(() async {
      Get.reset();
      Get.testMode = true;
      Get.put<AuthController>(_Auth());
      Get.put<SyncService>(_QueueOnlySync());
      net = _Net();
      repo = buildRepo(net);
      server.mode = _Mode.ok;
      server.invoiceBodies.clear();
      server.invoiceKeys.clear();
    });

    for (final c in _cases) {
      test(c.name, () async {
        // ── Ruta con servidor ──
        await _seed(isar);
        net.connected = true;
        final online = await sell(repo, c);
        expect(online.invoice, isNotNull, reason: online.error);
        expect(online.invoice!.id, isNot(startsWith('invoice_offline_')));
        final sentOnline = server.invoiceBodies.single;
        final stateOnline = await _deviceState(isar);
        final creditOnline = _serverCredit(sentOnline, _serverInvoice(sentOnline, 0));

        // ── Ruta local (misma base de partida) ──
        await _seed(isar);
        net.connected = false;
        final local = await sell(repo, c);
        expect(local.invoice, isNotNull, reason: local.error);
        expect(local.invoice!.id, startsWith('invoice_offline_'));
        expect(server.invoiceBodies, hasLength(1), reason: 'la ruta local no debe llamar al servidor');
        final stateLocal = await _deviceState(isar);
        final credits = await isar.isarCustomerCredits.where().findAll();
        final creditLocal = credits.fold<double>(0, (s, cr) => s + cr.balanceDue);

        // Lo que la cola le mandará al servidor: UNA factura, la misma venta.
        final queued = (await isar.syncOperations.where().findAll())
            .where((o) => o.entityType == 'Invoice')
            .toList();
        expect(queued, hasLength(1), reason: 'debe quedar UNA factura en la cola');
        expect(queued.single.entityId, local.invoice!.id);
        final sentLocal = jsonDecode(queued.single.payload) as Map<String, dynamic>;

        for (final (route, inv) in [('servidor', online.invoice!), ('local', local.invoice!)]) {
          expect(inv.total, closeTo(c.total, 0.005), reason: 'total, ruta $route');
          expect(inv.paidAmount, closeTo(c.paid, 0.005), reason: 'pagado, ruta $route');
          expect(inv.balanceDue, closeTo(c.balance, 0.005), reason: 'saldo, ruta $route');
          expect(inv.status, c.status, reason: 'estado, ruta $route');
          expect(inv.paymentMethod, c.method, reason: 'método, ruta $route');
          expect(_paymentLines(inv), c.payments, reason: 'pagos por moneda, ruta $route');
        }
        expect(local.invoice!.subtotal, closeTo(online.invoice!.subtotal, 0.005));
        expect(local.invoice!.taxAmount, closeTo(online.invoice!.taxAmount, 0.005));
        expect(local.invoice!.discountAmount, closeTo(online.invoice!.discountAmount, 0.005));
        expect(local.invoice!.items.length, online.invoice!.items.length);

        expect(_saleAsSent(sentLocal), _saleAsSent(sentOnline),
            reason: 'la cola debe mandar la misma venta que la ruta con servidor');

        expect(creditOnline, closeTo(c.credit, 0.005), reason: 'crédito que abre el servidor');
        expect(creditLocal, closeTo(c.credit, 0.005), reason: 'crédito en el equipo, ruta local');

        final expectedState = {
          'stock uno': c.stockMoves ? 98.0 : 100.0,
          'stock dos': c.stockMoves ? 99.0 : 100.0,
          'lote lote-viejo': c.stockMoves ? 0 : 1,
          'lote lote-nuevo': c.stockMoves ? 98 : 99,
          'lote lote-dos': c.stockMoves ? 99 : 100,
        };
        expect(stateLocal, expectedState, reason: 'stock y lotes, ruta local');
        print('EQUIVALENCIA [${c.name}] total ${_money(c.total)} pagado ${_money(c.paid)} '
            'saldo ${_money(c.balance)} crédito ${_money(c.credit)} pagos ${c.payments} '
            '| stock ruta servidor $stateOnline | ruta local $stateLocal');
        if (c.serverRouteMovesDraftStock) {
          print('DIFERENCIA YA EXISTENTE [${c.name}]: la ruta con servidor descuenta el stock local '
              'de un borrador ($stateOnline); la ruta local no ($stateLocal).');
        } else {
          expect(stateOnline, expectedState, reason: 'stock y lotes, ruta con servidor');
        }
      });
    }
  });

  group('servidor sin respuesta: marca, ventas siguientes y vuelta', () {
    late InvoiceRepositoryImpl repo;
    late NetworkInfoImpl net;
    late SyncService sync;
    final cash = _cases.first;

    Future<List<SyncOperation>> invoiceOps() async => (await isar.syncOperations.where().findAll())
        .where((o) => o.entityType == 'Invoice')
        .toList();

    setUp(() async {
      Get.reset();
      Get.testMode = true;
      await _seed(isar);
      server.mode = _Mode.ok;
      server.invoiceBodies.clear();
      server.invoiceKeys.clear();
      net = NetworkInfoImpl(Connectivity());
      repo = buildRepo(net);
      Get.put<AuthController>(_Auth());
      Get.put<SecureStorageService>(_Storage());
      Get.put<IsarDatabase>(IsarDatabase.instance);
      Get.put<IdempotencyService>(IdempotencyService());
      Get.put<NetworkInfo>(net);
      Get.put<DioClient>(client);
      sync = SyncService(IsarDatabase.instance);
      Get.put<SyncService>(sync); // arranca como en la app (escucha y reloj de 10 s)
      for (var i = 0; i < 50 && !sync.isOnline; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(sync.isOnline, isTrue, reason: 'la sincronización no arrancó con red');
      // La app ya comprobó el servidor al abrir (primer /health).
      expect(await net.isConnected, isTrue);
    });

    tearDown(() async {
      sync.onClose();
      net.dispose();
      // Que ninguna subida en curso quede escribiendo al cerrar la base.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    test('tope de tiempo: la venta 1 espera el tope y queda local; las siguientes '
        'se guardan de inmediato sin llamar al servidor; al volver el servidor la '
        'marca se levanta sola y la cola sube cada venta UNA vez', () async {
      server.mode = _Mode.hang;
      client.receiveTimeout = const Duration(milliseconds: 700);

      final first = await sell(repo, cash);
      expect(first.invoice?.id, startsWith('invoice_offline_'), reason: first.error);
      expect(first.ms, greaterThanOrEqualTo(650), reason: 'la venta 1 sí espera el tope');
      expect(net.isServerReachable, isFalse, reason: 'no marcó el servidor como no disponible');
      expect(server.invoiceBodies, hasLength(1));
      final hungKey = server.invoiceKeys.single;
      expect(hungKey, isNotNull);

      final second = await sell(repo, cash);
      final third = await sell(repo, cash);
      print('MEDICION servidor sin respuesta (tope de prueba 700 ms): venta 1 ${first.ms} ms, '
          'venta 2 ${second.ms} ms, venta 3 ${third.ms} ms');
      for (final s in [second, third]) {
        expect(s.invoice?.id, startsWith('invoice_offline_'), reason: s.error);
        expect(s.ms, lessThan(1000), reason: 'volvió a esperar al servidor');
      }
      expect(server.invoiceBodies, hasLength(1), reason: 'las ventas siguientes llamaron al servidor');
      expect(await invoiceOps(), hasLength(3));
      expect(sync.pendingOperationsCount, greaterThanOrEqualTo(3),
          reason: 'el contador de la cola no se actualizó al terminar la venta');

      // Con la marca puesta la cola no insiste.
      await sync.syncAll();
      expect(server.invoiceBodies, hasLength(1));

      // Vuelve el servidor. Nadie toca nada: el reloj de la sincronización
      // (cada 10 s) comprueba /health, levanta la marca y sube la cola.
      server.mode = _Mode.ok;
      client.receiveTimeout = null;
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (DateTime.now().isBefore(deadline)) {
        final left = (await invoiceOps()).where((o) => o.status != SyncStatus.completed);
        if (server.invoiceBodies.length >= 4 && left.isEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(net.isServerReachable, isTrue, reason: 'la marca no se levantó sola');
      expect(server.invoiceBodies, hasLength(4),
          reason: 'la cola debe mandar cada una de las 3 ventas UNA vez');
      final uploadKeys = server.invoiceKeys.sublist(1);
      expect(uploadKeys.toSet(), hasLength(3), reason: 'dos ventas compartieron clave');
      expect(uploadKeys, contains(hungKey),
          reason: 'la venta que quedó sin respuesta debe subir con la MISMA clave: '
              'si aquel intento sí llegó, el servidor no la crea dos veces');
      expect((await invoiceOps()).where((o) => o.status != SyncStatus.completed), isEmpty);

      // Otra pasada de la cola no vuelve a mandar nada.
      await sync.syncAll(ignoreBackoff: true);
      expect(server.invoiceBodies, hasLength(4), reason: 'la cola mandó una factura dos veces');

      // En el equipo: 3 facturas, ya con el id del servidor, sin duplicados.
      final invoices = await isar.isarInvoices.where().findAll();
      expect(invoices, hasLength(3));
      expect(invoices.where((i) => i.serverId.startsWith('invoice_offline_')), isEmpty);

      // Y la venta siguiente vuelve a ir por el servidor.
      final back = await sell(repo, cash);
      expect(back.invoice?.id, isNot(startsWith('invoice_offline_')), reason: back.error);
      expect(server.invoiceBodies, hasLength(5));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('error 500: la venta queda local y se marca; la siguiente no llama al servidor', () async {
      server.mode = _Mode.error500;
      final first = await sell(repo, cash);
      expect(first.invoice?.id, startsWith('invoice_offline_'), reason: first.error);
      expect(net.isServerReachable, isFalse);
      final second = await sell(repo, cash);
      expect(second.invoice?.id, startsWith('invoice_offline_'));
      expect(second.ms, lessThan(1000));
      expect(server.invoiceBodies, hasLength(1));
    });

    test('rechazo de negocio (400, cupo): se muestra el motivo, NO se guarda local, '
        'NO se marca el servidor y la venta siguiente va al servidor', () async {
      server.mode = _Mode.reject400;
      final rejected = await sell(repo, cash);
      expect(rejected.invoice, isNull);
      expect(rejected.error, contains('cupo'));
      expect(net.isServerReachable, isTrue, reason: 'un rechazo de negocio marcó el servidor');
      expect(await invoiceOps(), isEmpty);
      expect(await isar.isarInvoices.where().findAll(), isEmpty);

      server.mode = _Mode.ok;
      final next = await sell(repo, cash);
      expect(next.invoice?.id, isNot(startsWith('invoice_offline_')), reason: next.error);
      expect(server.invoiceBodies, hasLength(2));
    });

    test('respuesta ilegible del servidor: se guarda local como antes, pero NO marca', () async {
      server.mode = _Mode.badBody;
      final sale = await sell(repo, cash);
      expect(sale.invoice?.id, startsWith('invoice_offline_'), reason: sale.error);
      expect(net.isServerReachable, isTrue);
    });
  });
}

class Either2 {
  Either2(this.invoice, this.error, this.ms);
  final Invoice? invoice;
  final String? error;
  final int ms;
}
