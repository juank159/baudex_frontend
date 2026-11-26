// lib/features/invoices/data/presentation_lookup.dart
import 'dart:async';

import '../../products/domain/entities/product_presentation.dart';

/// Presentaciones de un producto al agregarlo a la factura (cartón, kilo,
/// unidad…), SIN frenar la venta.
///
/// Antes, cada producto agregado preguntaba y esperaba: si el equipo no
/// tenía sus presentaciones y el módulo no figuraba como descargado, la
/// línea esperaba la respuesta del servidor (un cuarto de segundo o más por
/// cada lectura, también al re-leer el mismo producto).
///
/// Ahora:
/// - [known] responde solo con lo del equipo (memoria y base local); `null`
///   significa "el equipo no lo sabe": la línea entra ya y se pregunta
///   después con [resolve];
/// - la respuesta se recuerda [maxAge], así re-leer un producto no vuelve a
///   preguntar;
/// - [resolve] hace una sola pregunta a la vez por producto.
class PresentationLookup {
  PresentationLookup({
    required this.readLocal,
    required this.isModuleComplete,
    required this.fetch,
    this.maxAge = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Presentaciones guardadas en el equipo (solo la base local).
  final Future<List<ProductPresentation>> Function(String productId) readLocal;

  /// ¿El módulo de presentaciones ya bajó completo? Entonces "no hay nada
  /// en el equipo" quiere decir "no tiene".
  final Future<bool> Function() isModuleComplete;

  /// Pregunta completa (puede ir al servidor). `null` si no se pudo.
  final Future<List<ProductPresentation>?> Function(String productId) fetch;

  final Duration maxAge;
  final DateTime Function() _now;

  final Map<String, (DateTime, List<ProductPresentation>)> _memo = {};
  final Map<String, Future<List<ProductPresentation>?>> _asking = {};

  List<ProductPresentation>? _remembered(String productId) {
    final entry = _memo[productId];
    if (entry == null) return null;
    if (_now().difference(entry.$1) > maxAge) {
      _memo.remove(productId);
      return null;
    }
    return entry.$2;
  }

  void _remember(String productId, List<ProductPresentation> list) {
    if (_memo.length > 2000) _memo.clear();
    _memo[productId] = (_now(), list);
  }

  /// Lo que el equipo sabe, sin esperar al servidor: la lista (vacía si no
  /// tiene), o `null` si hay que preguntar.
  Future<List<ProductPresentation>?> known(String productId) async {
    final remembered = _remembered(productId);
    if (remembered != null) return remembered;
    final local = await readLocal(productId);
    if (local.isNotEmpty) {
      _remember(productId, local);
      return local;
    }
    if (await isModuleComplete()) {
      _remember(productId, const []);
      return const [];
    }
    return null;
  }

  /// Pregunta (si hace falta, al servidor) y recuerda la respuesta. Varias
  /// llamadas seguidas por el mismo producto comparten una sola pregunta.
  Future<List<ProductPresentation>?> resolve(String productId) {
    final remembered = _remembered(productId);
    if (remembered != null) return Future.value(remembered);
    return _asking[productId] ??= () async {
      try {
        final list = await fetch(productId);
        if (list != null) _remember(productId, list);
        return list;
      } catch (_) {
        return null;
      } finally {
        unawaited(_asking.remove(productId));
      }
    }();
  }

  /// Un producto cambió sus presentaciones en este equipo: olvidar.
  void forget([String? productId]) =>
      productId == null ? _memo.clear() : _memo.remove(productId);
}
