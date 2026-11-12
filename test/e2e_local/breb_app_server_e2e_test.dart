// Prueba de la app REAL (modelos, llamadas y controlador de Bre-B) contra el
// servidor de PRUEBAS. No corre con `flutter test` normal: necesita el
// servidor de simulación arriba.
//
//   BAUDEX_E2E_URL=http://127.0.0.1:3990/api flutter test test/e2e_local/breb_app_server_e2e_test.dart
//
// Variables opcionales: BAUDEX_E2E_EMAIL, BAUDEX_E2E_PASSWORD,
// BAUDEX_E2E_MAILGUN_KEY (la misma del servidor de pruebas) y BAUDEX_E2E_PSQL.
//
// Comprueba que la app y el servidor se entienden: el borrador que arma la app
// pasa la validación del servidor, el aviso del banco confirma el cobro y la
// app recibe la factura creada; y que los rechazos del servidor llegan a la
// app con su motivo.
import 'dart:convert';
import 'dart:io';

import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/features/breb/data/breb_api.dart';
import 'package:baudex_desktop/features/breb/presentation/controllers/breb_payment_controller.dart';
import 'package:baudex_desktop/features/invoices/data/models/create_invoice_request_model.dart';
import 'package:baudex_desktop/features/invoices/domain/repositories/invoice_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final _env = Platform.environment;
final _base = _env['BAUDEX_E2E_URL'];
final _mailgunKey = _env['BAUDEX_E2E_MAILGUN_KEY'] ?? 'llave-de-firma-solo-para-simulacion';
final _psql = (_env['BAUDEX_E2E_PSQL'] ?? 'docker exec inv-test-pg psql -U postgres -d baudex_sim').split(' ');

/// El cliente HTTP de la app, apuntando al servidor de pruebas. Convierte los
/// errores igual que el real (mismo tipo y mismo prefijo en el mensaje).
class _SimClient implements DioClient {
  final Dio _dio;
  _SimClient(String token)
      : _dio = Dio(BaseOptions(baseUrl: _base!, headers: {
          'Authorization': 'Bearer $token',
          'X-Device-Id': 'app-e2e',
          'User-Agent': 'Baudex/Desktop (prueba)',
        }));

  Exception _convert(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return ConnectionException('Error de conexión: ${e.message}');
    final body = e.response?.data;
    final raw = body is Map ? body['message'] : null;
    final message = raw is List ? raw.join(', ') : (raw?.toString() ?? '');
    switch (status) {
      case 400:
        return ServerException('Solicitud incorrecta: $message', statusCode: 400);
      case 404:
        return ServerException('Recurso no encontrado: $message', statusCode: 404);
      case 409:
        return ServerException('Conflicto: $message', statusCode: 409);
      default:
        return ServerException('Error: $message', statusCode: status);
    }
  }

  @override
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<Response> post(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.post(endpoint, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<Response> patch(String endpoint, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) =>
      _dio.patch(endpoint, data: data, queryParameters: queryParameters, options: options);

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

/// Envía el aviso del banco como lo entrega Mailgun (con su firma).
Future<int> _bankNotice(String recipient, int amount, String reference) async {
  final ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  final token = DateTime.now().microsecondsSinceEpoch.toString();
  final signature = Hmac(sha256, utf8.encode(_mailgunKey)).convert(utf8.encode(ts + token)).toString();
  final body = 'Venta exitosa\nMonto: \$$amount\nEstado: Aprobada\nPagador: CLIENTE DE PRUEBA\nBanco: Nequi\nReferencia: $reference';
  final result = await Process.run('curl', [
    '-s', '-o', '/dev/null', '-w', '%{http_code}', '-X', 'POST', '$_base/breb/inbound-email',
    '-F', 'timestamp=$ts', '-F', 'token=$token', '-F', 'signature=$signature',
    '-F', 'recipient=$recipient', '-F', 'From=Nequi <notificaciones@nequi.com.co>', '-F', 'body-plain=$body',
  ]);
  return int.tryParse((result.stdout as String).trim()) ?? 0;
}

void main() {
  if (_base == null) {
    test('Bre-B app ↔ servidor (omitida: falta BAUDEX_E2E_URL)', () {}, skip: 'Requiere el servidor de pruebas');
    return;
  }

  late _SimClient client;
  late BrebApi api;
  late String finalConsumerId;
  late String productId;
  final run = DateTime.now().millisecondsSinceEpoch.toRadixString(16);

  Map<String, dynamic> draft(double quantity) => CreateInvoiceRequestModel.fromParams(
        customerId: finalConsumerId,
        items: [
          CreateInvoiceItemParams(
            description: 'Gaseosa de prueba',
            quantity: quantity,
            unitPrice: 5000,
            productId: productId,
          ),
        ],
        date: DateTime.now(),
        dueDate: DateTime.now(),
        paymentMethod: 'bank_transfer',
      ).toJson();

  setUpAll(() async {
    await _sql('update active_sessions set is_active=false'); // base de pruebas: libera dispositivos
    final login = await Dio(BaseOptions(baseUrl: _base!, headers: {'X-Device-Id': 'app-e2e'})).post('/auth/login', data: {
      'email': _env['BAUDEX_E2E_EMAIL'] ?? 'sim@baudex.test',
      'password': _env['BAUDEX_E2E_PASSWORD'] ?? 'Prueba123!',
    });
    client = _SimClient(_unwrap(login.data)['token'] as String);
    api = BrebApi(client);

    await client.patch('/organizations/current', data: {
      'settings': {
        'breb': {
          'llaves': [
            {'id': 'nequi', 'label': 'Nequi tienda', 'llave': '3000000000'},
          ],
        },
      },
    });
    finalConsumerId = await _sql("select id from customers where \"documentNumber\"='222222222222' and deleted_at is null limit 1");
    final category = _unwrap((await client.post('/categories', data: {'name': 'App $run', 'slug': 'app-$run'})).data);
    final product = _unwrap((await client.post('/products', data: {
      'name': 'Gaseosa app $run', 'sku': 'APP-$run', 'type': 'product', 'categoryId': category['id'],
      'stock': 100, 'minStock': 0,
      'prices': [{'type': 'price1', 'amount': 5000}, {'type': 'cost', 'amount': 2000}],
    })).data);
    productId = product['id'] as String;
  });

  test('venta de mostrador: el borrador de la app pasa, el banco avisa y la app recibe la factura pagada', () async {
    final address = await api.inboundAddress();
    expect(address, matches(RegExp(r'^pagos-bx[a-f0-9]{12}@')));

    final controller = BrebPaymentController(api, pollEvery: const Duration(milliseconds: 300))..onInit();
    addTearDown(controller.onClose);

    // Valor poco común para no chocar con otros cobros pendientes de la base.
    const amount = 15000;
    await controller.startForSale(draft: draft(3), amount: amount.toDouble());
    expect(controller.phase.value, BrebPaymentPhase.waiting, reason: controller.errorMessage.value);
    final charged = controller.charge.value!.amount.toInt();

    expect(await _bankNotice(address, charged, 'APP$run'), 200);
    for (var i = 0; i < 40 && controller.phase.value == BrebPaymentPhase.waiting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    expect(controller.phase.value, BrebPaymentPhase.confirmed);
    expect(controller.state.value!.payerName, 'CLIENTE DE PRUEBA');
    final invoiceId = controller.invoiceId!;
    final row = await _sql("select status, total::float, \"balanceDue\"::float from invoices where id='$invoiceId'");
    expect(row, 'paid|15000|0');
  });

  Future<void> waitConfirmed(BrebPaymentController controller) async {
    for (var i = 0; i < 40 && controller.phase.value == BrebPaymentPhase.waiting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  test('producto NO registrado (el cajero digita el valor): se cobra y la venta queda pagada', () async {
    final address = await api.inboundAddress();
    final controller = BrebPaymentController(api, pollEvery: const Duration(milliseconds: 300))..onInit();
    addTearDown(controller.onClose);

    // Así lo arma la app: un producto temporal con su identificador `temp_…`.
    final draftWithTemp = CreateInvoiceRequestModel.fromParams(
      customerId: finalConsumerId,
      items: [
        CreateInvoiceItemParams(
          description: 'Verduras',
          quantity: 1,
          unitPrice: 2137,
          productId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        ),
      ],
      date: DateTime.now(),
      dueDate: DateTime.now(),
      paymentMethod: 'bank_transfer',
    ).toJson();

    await controller.startForSale(draft: draftWithTemp, amount: 2137);
    expect(controller.phase.value, BrebPaymentPhase.waiting, reason: controller.errorMessage.value);
    expect(await _bankNotice(address, controller.charge.value!.amount.toInt(), 'TMP$run'), 200);
    await waitConfirmed(controller);

    expect(controller.phase.value, BrebPaymentPhase.confirmed);
    final row = await _sql(
      "select i.status, i.total::float, it.description, it.\"productId\" is null from invoices i "
      "join invoice_items it on it.\"invoiceId\" = i.id where i.id='${controller.invoiceId}'",
    );
    expect(row, 'paid|2137|Verduras|t');
  });

  test('crédito: abono por Bre-B desde la app y luego el saldo completo', () async {
    final address = await api.inboundAddress();
    final customer = _unwrap((await client.post('/customers', data: {
      'firstName': 'Cliente', 'lastName': 'App $run', 'documentType': 'cc',
      'documentNumber': '5${DateTime.now().millisecondsSinceEpoch % 100000000}',
      'email': 'app$run@baudex.test', 'creditLimit': 5000000, 'paymentTerms': 30,
    })).data);
    final invoice = _unwrap((await client.post('/invoices', data: {
      'customerId': customer['id'], 'paymentMethod': 'credit', 'status': 'pending',
      'items': [{'description': 'Gaseosa de prueba', 'quantity': 3, 'unitPrice': 5000, 'productId': productId}],
    })).data);
    final creditId = await _sql("select id from customer_credits where invoice_id='${invoice['id']}'");
    expect(creditId, hasLength(36));

    final abono = BrebPaymentController(api, pollEvery: const Duration(milliseconds: 300))..onInit();
    addTearDown(abono.onClose);
    await abono.startForCredit(creditId, amount: 6000);
    expect(abono.phase.value, BrebPaymentPhase.waiting, reason: abono.errorMessage.value);
    expect(await _bankNotice(address, abono.charge.value!.amount.toInt(), 'CRA$run'), 200);
    await waitConfirmed(abono);
    expect(abono.phase.value, BrebPaymentPhase.confirmed);
    expect(abono.settledId, isNotNull);
    expect(await _sql("select status, balance_due::float from customer_credits where id='$creditId'"), 'partially_paid|9000');

    final resto = BrebPaymentController(api, pollEvery: const Duration(milliseconds: 300))..onInit();
    addTearDown(resto.onClose);
    await resto.startForCredit(creditId);
    expect(resto.charge.value!.requestedAmount, 9000);
    expect(await _bankNotice(address, resto.charge.value!.amount.toInt(), 'CRB$run'), 200);
    await waitConfirmed(resto);
    expect(resto.phase.value, BrebPaymentPhase.confirmed);
    expect(await _sql("select status, balance_due::float from customer_credits where id='$creditId'"), 'paid|0');
    expect(await _sql("select status from invoices where id='${invoice['id']}'"), 'paid');
  });

  test('el motivo de un rechazo del servidor llega tal cual a la app', () async {
    final controller = BrebPaymentController(api)..onInit();
    addTearDown(controller.onClose);
    final empty = draft(1)..['items'] = [];
    await controller.startForSale(draft: empty, amount: 5000);
    expect(controller.phase.value, BrebPaymentPhase.failed);
    expect(controller.errorMessage.value, isNot(startsWith('Solicitud incorrecta')));
    expect(controller.errorMessage.value, contains('venta'));
  });

  test('cancelar desde la app cancela el cobro en el servidor', () async {
    final controller = BrebPaymentController(api, pollEvery: const Duration(milliseconds: 300))..onInit();
    addTearDown(controller.onClose);
    await controller.startForSale(draft: draft(1), amount: 5000);
    final chargeId = controller.charge.value!.chargeId;
    expect(await controller.cancel(), isTrue);
    expect(await _sql("select status from breb_pending_charges where id='$chargeId'"), 'cancelled');
  });
}
