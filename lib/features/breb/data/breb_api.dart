// lib/features/breb/data/breb_api.dart
import 'package:dio/dio.dart';
import '../../../app/core/network/dio_client.dart';
import '../domain/breb_charge.dart';

/// Error de Bre-B con un mensaje listo para mostrarle al cajero.
class BrebException implements Exception {
  final String message;

  /// `true` si no se pudo llegar al servidor (Bre-B necesita internet).
  final bool offline;
  const BrebException(this.message, {this.offline = false});

  @override
  String toString() => message;
}

/// Llamadas al servidor para el cobro Bre-B. Siempre en línea: el banco
/// confirma por el servidor, no hay forma de cobrar por Bre-B sin internet.
class BrebApi {
  final DioClient _dio;
  BrebApi(this._dio);

  /// Cobro de una venta nueva: [draft] es el mismo cuerpo con el que se crea
  /// una factura. La factura se crea en el servidor cuando llega el pago.
  Future<BrebCharge> createChargeForSale({
    required Map<String, dynamic> draft,
    required double amount,
  }) =>
      _send(() => _dio.post('/breb/charge', data: {'draft': draft, 'amount': amount}),
          (data) => BrebCharge.fromJson(data));

  /// Cobro de una factura que ya existe y se debe.
  Future<BrebCharge> createChargeForInvoice(String invoiceId) =>
      _send(() => _dio.post('/breb/charge', data: {'invoiceId': invoiceId}),
          (data) => BrebCharge.fromJson(data));

  Future<BrebChargeState> status(String chargeId) =>
      _send(() => _dio.get('/breb/status/$chargeId'),
          (data) => BrebChargeState.fromJson(data));

  Future<void> cancel(String chargeId) =>
      _send(() => _dio.post('/breb/cancel/$chargeId'), (_) {});

  /// Pagos recibidos (últimas 24 h) que no se unieron solos a un cobro.
  Future<List<BrebReceivedPayment>> unassigned() async {
    try {
      final response = await _dio.get('/breb/unassigned');
      final data = _unwrap(response.data);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => BrebReceivedPayment.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// Asigna a mano un pago recibido a un cobro. Devuelve la factura que quedó
  /// pagada (creada en ese momento si era una venta nueva).
  Future<String?> assign({required String chargeId, required String emailId}) => _send(
      () => _dio.post('/breb/assign', data: {'chargeId': chargeId, 'emailId': emailId}),
      (data) => data['invoiceId']?.toString());

  /// Dirección de correo del negocio a la que debe reenviar los avisos del banco.
  Future<String> inboundAddress() =>
      _send(() => _dio.get('/breb/inbound-address'),
          (data) => data['email']?.toString() ?? '');

  /// QR de prueba para una plantilla antes de guardarla. Lanza si no es válida.
  Future<String> previewQr(String template, double amount) => _send(
      () => _dio.post('/breb/qr-preview', data: {'template': template, 'amount': amount}),
      (data) => data['payload']?.toString() ?? '');

  /// Últimos avisos recibidos que no se conciliaron solos (diagnóstico).
  Future<List<Map<String, dynamic>>> recentEmails() async {
    try {
      final response = await _dio.get('/breb/recent-emails');
      final data = _unwrap(response.data);
      if (data is! List) return [];
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  Future<T> _send<T>(
    Future<Response> Function() call,
    T Function(Map<String, dynamic> data) parse,
  ) async {
    try {
      final response = await call();
      final data = _unwrap(response.data);
      return parse(data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
    } on DioException catch (e) {
      throw _toException(e);
    }
  }

  /// El servidor envuelve las respuestas en `{success, data}` (a veces dos veces).
  static dynamic _unwrap(dynamic body) {
    var current = body;
    while (current is Map &&
        current.containsKey('data') &&
        current.keys.every((k) => const {'success', 'data', 'timestamp', 'message', 'meta'}.contains(k))) {
      current = current['data'];
    }
    return current;
  }

  static BrebException _toException(DioException e) {
    final body = e.response?.data;
    if (e.response != null) {
      final message = body is Map ? body['message'] : null;
      final text = message is List ? message.join('. ') : message?.toString();
      return BrebException(
        (text != null && text.isNotEmpty) ? text : 'El servidor no pudo procesar el cobro Bre-B.',
      );
    }
    return const BrebException(
      'Sin conexión con el servidor. Bre-B necesita internet para confirmar el pago con el banco. '
      'Cobra con otro método.',
      offline: true,
    );
  }
}
