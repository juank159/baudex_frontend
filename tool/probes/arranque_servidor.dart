// tool/probes/arranque_servidor.dart
//
// Servidor de mentira para la medición de arranque (ver
// arranque_windows_probe.dart). Corre en otro hilo (isolate) para no
// quitarle tiempo a la app, atiende HTTP de verdad en 127.0.0.1 y cuenta
// cada petición y cada registro que entrega. Solo Dart puro: sin Flutter.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

const String probeOrganizationId = '0a000000-0000-4000-8000-000000000001';
const String probeUserId = '0b000000-0000-4000-8000-000000000001';
const String probeBusiness = 'Tienda de Medición';
const String probeEmail = 'caja@medicion.test';
const String probePassword = 'Medicion#2026';

/// Lo que el servidor le cuenta a la app por cada petición atendida.
class ServedRequest {
  ServedRequest(this.method, this.path, this.entity, this.records);
  final String method;
  final String path;

  /// Módulo de `/sync/changes/<módulo>`, o null.
  final String? entity;
  final int records;
}

class ArranqueServerConfig {
  const ArranqueServerConfig({
    this.invoices = 6000,
    this.products = 3000,
    this.latencyMs = 0,
    this.port = 3990,
  });

  /// Puerto fijo: es el que trae el `.env` con que se compila la medición.
  final int port;
  final int invoices;
  final int products;

  /// Demora por petición (internet de verdad no responde en 0 ms).
  final int latencyMs;
}

/// Arranca el servidor en otro isolate. Devuelve el puerto y un flujo con
/// cada petición atendida.
Future<({int port, Stream<ServedRequest> served})> startArranqueServer(
  ArranqueServerConfig config,
) async {
  final ready = Completer<int>();
  final served = StreamController<ServedRequest>.broadcast();
  final inbox = ReceivePort();
  inbox.listen((message) {
    if (message is int) {
      ready.complete(message);
    } else if (message is List) {
      served.add(ServedRequest(
        message[0] as String,
        message[1] as String,
        message[2] as String?,
        message[3] as int,
      ));
    }
  });
  await Isolate.spawn(
    _serve,
    [inbox.sendPort, config.invoices, config.products, config.latencyMs, config.port],
    debugName: 'servidor_medicion',
  );
  return (port: await ready.future, served: served.stream);
}

String _uuid(int kind, int n) =>
    '${kind.toRadixString(16).padLeft(8, '0')}-0000-4000-8000-${n.toString().padLeft(12, '0')}';

/// Marca de tiempo fija del registro [n] (igual en cada arranque, para que
/// "solo lo que cambió" sea de verdad cero).
String _stamp(int n) => DateTime.utc(2025, 1, 1)
    .add(Duration(minutes: n))
    .toIso8601String()
    .replaceFirst('Z', '000Z');

Map<String, dynamic> _product(int n) {
  final id = _uuid(0x0c, n);
  final at = _stamp(n);
  return {
    'id': id,
    'name': 'Producto de medición $n',
    'sku': 'SKU-$n',
    'barcode': '${7700000000000 + n}',
    'type': 'product',
    'status': 'active',
    'stock': 25.0,
    'minStock': 1.0,
    'categoryId': _uuid(0x0d, 1),
    'createdById': probeUserId,
    'prices': [
      {
        'id': _uuid(0x0e, n),
        'productId': id,
        'type': 'price1',
        'amount': 1500 + n,
        'currency': 'COP',
        'status': 'active',
        'discountPercentage': 0,
        'minQuantity': 1,
        'createdAt': at,
        'updatedAt': at,
      },
    ],
    'createdAt': at,
    'updatedAt': at,
    'taxCategory': 'IVA',
    'taxRate': 19.0,
    'isTaxable': true,
  };
}

Map<String, dynamic> _invoice(int n) {
  final id = _uuid(0x0f, n);
  final at = _stamp(n);
  return {
    'id': id,
    'number': 'FV-${n.toString().padLeft(6, '0')}',
    'date': at,
    'dueDate': at,
    'status': 'paid',
    'paymentMethod': 'cash',
    'subtotal': 9000,
    'taxPercentage': 0,
    'taxAmount': 0,
    'discountPercentage': 0,
    'discountAmount': 0,
    'total': 9000,
    'paidAmount': 9000,
    'balanceDue': 0,
    'customerId': _uuid(0x10, 1),
    'createdById': probeUserId,
    'items': [
      for (var i = 1; i <= 3; i++)
        {
          'id': _uuid(0x11, n * 10 + i),
          'description': 'Producto de medición $i',
          'quantity': 2,
          'unitPrice': 1500,
          'discountPercentage': 0,
          'discountAmount': 0,
          'subtotal': 3000,
          'invoiceId': id,
          'productId': _uuid(0x0c, i),
          'createdAt': at,
          'updatedAt': at,
        },
    ],
    'payments': [],
    'createdAt': at,
    'updatedAt': at,
  };
}

Map<String, dynamic> _user() => {
      'id': probeUserId,
      'firstName': 'Caja',
      'lastName': 'Medición',
      'email': probeEmail,
      'role': 'admin',
      'status': 'active',
      'isEmailVerified': true,
      'createdAt': _stamp(0),
      'updatedAt': _stamp(0),
      'organizationId': probeOrganizationId,
      'organizationSlug': 'medicion',
      'organizationName': probeBusiness,
    };

String _jwt() {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  final exp = DateTime.utc(2099).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${part({'sub': probeUserId, 'organizationId': probeOrganizationId, 'exp': exp})}.'
      'firma-de-medicion';
}

Future<void> _serve(List<Object?> args) async {
  final out = args[0] as SendPort;
  final totals = {'invoices': args[1] as int, 'products': args[2] as int};
  final latency = Duration(milliseconds: args[3] as int);
  final builders = <String, Map<String, dynamic> Function(int)>{
    'invoices': _invoice,
    'products': _product,
  };
  final kinds = {'invoices': 0x0f, 'products': 0x0c};

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, args[4] as int);
  out.send(server.port);

  Map<String, dynamic> changes(String entity, Uri uri) {
    final total = totals[entity] ?? 0;
    final since = uri.queryParameters['since'] ?? '';
    final afterId = uri.queryParameters['afterId'];
    final limit = int.tryParse(uri.queryParameters['limit'] ?? '') ?? 200;
    final now = DateTime.now().toUtc().toIso8601String().replaceFirst('Z', '000Z');
    final items = <Map<String, dynamic>>[];
    final stamps = <String>[];
    var more = false;
    if (total > 0) {
      final sinceAt = DateTime.tryParse(since) ?? DateTime.utc(1970);
      // Primer registro con marca posterior a `since` (una marca por minuto).
      var first = sinceAt.difference(DateTime.utc(2025, 1, 1)).inMinutes;
      if (first < 1) first = 1;
      for (var n = first; n <= total; n++) {
        final at = DateTime.parse(_stamp(n));
        final id = _uuid(kinds[entity]!, n);
        final after = at.isAfter(sinceAt) ||
            (at.isAtSameMomentAs(sinceAt) &&
                afterId != null &&
                id.compareTo(afterId) > 0);
        if (!after) continue;
        if (items.length == limit) {
          more = true;
          break;
        }
        items.add(builders[entity]!(n));
        stamps.add(_stamp(n));
      }
    }
    return {
      'items': items,
      'stamps': stamps,
      'deletedIds': <String>[],
      'hasMore': more,
      if (more) 'next': {'since': stamps.last, 'afterId': items.last['id']},
      if (afterId == null) 'watermark': now,
    };
  }

  await for (final request in server) {
    final path = request.uri.path;
    String? entity;
    var records = 0;
    Object body = {'success': true, 'data': <Object>[]};
    var status = 200;
    try {
      // Vaciar el cuerpo de la petición antes de responder.
      await request.drain<void>();
      if (latency > Duration.zero) await Future<void>.delayed(latency);
      if (path.endsWith('/auth/login')) {
        body = {
          'success': true,
          'data': {'token': _jwt(), 'refreshToken': 'refresh-medicion', 'user': _user()},
        };
      } else if (path.endsWith('/auth/profile')) {
        body = {
          'success': true,
          'data': {'user': _user()},
        };
      } else if (path.endsWith('/auth/refresh')) {
        body = {
          'success': true,
          'data': {'token': _jwt(), 'refreshToken': 'refresh-medicion'},
        };
      } else if (path.contains('/sync/changes/')) {
        entity = path.substring(path.lastIndexOf('/') + 1);
        final page = changes(entity, request.uri);
        records = (page['items'] as List).length;
        body = {'success': true, 'data': page};
      } else if (path.contains('/sync/count/')) {
        final name = path.substring(path.lastIndexOf('/') + 1);
        body = {
          'success': true,
          'data': {'count': totals[name] ?? 0},
        };
      } else if (request.method != 'GET' && request.method != 'HEAD') {
        body = {'success': true, 'data': <String, Object>{}};
      }
    } catch (e) {
      status = 500;
      body = {'success': false, 'message': '$e'};
    }
    out.send([request.method, path, entity, records]);
    try {
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await request.response.close();
    } catch (_) {}
  }
}
