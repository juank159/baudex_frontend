// lib/features/invoices/presentation/widgets/barcode_scan_queue.dart
import 'dart:async';

import '../../../products/domain/entities/product.dart';

/// Cola de escaneos del buscador de la factura.
///
/// El lector de código de barras escribe el código en milésimas y manda
/// Enter. Antes el Enter se ignoraba: se esperaba a que "se dejara de
/// escribir" (300 ms) y luego 500 ms más para agregar el producto, y si el
/// cajero escaneaba el siguiente producto en ese tiempo los dos códigos se
/// pegaban en la caja y uno se perdía.
///
/// Ahora cada código entra a esta cola al recibir el Enter: se busca de una
/// vez y se procesan EN ORDEN, uno a la vez, aunque se escanee muy rápido.
class BarcodeScanQueue {
  BarcodeScanQueue({
    required this.find,
    required this.onFound,
    required this.onNotFound,
  });

  /// Busca el producto exacto de ese código (`null` si no existe).
  final Future<Product?> Function(String code) find;

  /// Producto encontrado: agregarlo a la factura.
  final void Function(Product product, String code) onFound;

  /// Código sin producto: avisar.
  final void Function(String code) onNotFound;

  final List<String> _pending = [];
  Completer<void>? _running;
  bool _disposed = false;

  /// Códigos que esperan su turno (incluye el que se está buscando).
  int get pendingCount => _pending.length + (_running == null ? 0 : 1);

  /// Agrega un código escaneado. Devuelve cuando la cola queda vacía.
  Future<void> add(String code) {
    final trimmed = code.trim();
    if (trimmed.isNotEmpty) _pending.add(trimmed);
    return _drain();
  }

  Future<void> _drain() {
    final running = _running;
    if (running != null) return running.future;
    final completer = _running = Completer<void>();
    () async {
      try {
        while (_pending.isNotEmpty && !_disposed) {
          final code = _pending.removeAt(0);
          Product? product;
          try {
            product = await find(code);
          } catch (_) {
            product = null;
          }
          if (_disposed) break;
          if (product != null) {
            onFound(product, code);
          } else {
            onNotFound(code);
          }
        }
      } finally {
        _running = null;
        completer.complete();
      }
    }();
    return completer.future;
  }

  /// La pantalla se cerró: no avisar nada más.
  void dispose() {
    _disposed = true;
    _pending.clear();
  }
}
