// lib/features/invoices/data/short_code_index_keeper.dart
import 'dart:async';

import '../../products/data/product_code_events.dart';
import '../domain/price_entry.dart';

/// Mantiene al día el índice de códigos cortos de la factura:
/// - lo carga de la base en segundo plano, armándolo por partes para no
///   frenar la pantalla (y lo rehace cada [maxAge] como respaldo);
/// - aplica AL INSTANTE los productos creados/editados/borrados en el
///   equipo ([codeChanges]);
/// - si la colección cambió por otro camino (la sincronización, el stock
///   de una venta), queda "pendiente" y se rehace UNA vez cuando las
///   escrituras se calman ([settleDelay]), no por cada tecla ni por cada
///   tanda. Mientras tanto [guess] sigue respondiendo en memoria (la
///   pantalla pinta de una vez y confirma después).
class ShortCodeIndexKeeper {
  ShortCodeIndexKeeper({
    required this.loadCodes,
    required this.isCatalogComplete,
    Stream<ProductCodeChange>? codeChanges,
    Stream<void>? collectionChanges,
    this.maxAge = const Duration(minutes: 10),
    this.settleDelay = const Duration(seconds: 2),
    this.maxSettle = const Duration(seconds: 15),
    this.onLoaded,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _subs = [
      if (codeChanges != null) codeChanges.listen(_apply),
      if (collectionChanges != null) collectionChanges.listen((_) => _markStale()),
    ];
  }

  final Future<List<(String?, int)>> Function() loadCodes;
  final Future<bool> Function() isCatalogComplete;
  final Duration maxAge;

  /// Calma que se espera tras el último cambio de la colección antes de
  /// rehacer el índice, y tope de espera si los cambios no paran.
  final Duration settleDelay;
  final Duration maxSettle;

  /// Aviso de cada carga terminada (ms que tardó), para el diagnóstico.
  final void Function(double ms)? onLoaded;

  /// Códigos que se arman por vuelta antes de ceder el hilo.
  static const int _chunk = 4000;
  final DateTime Function() _now;

  late final List<StreamSubscription<dynamic>> _subs;
  ShortCodeIndex? _index;
  Future<void>? _loading;
  Timer? _retry;
  int _changes = 0;
  bool _stale = false;
  bool _disposed = false;

  ShortCodeIndex? get index => _index;
  bool get isStale => _stale;
  int get loads => _loads;
  int _loads = 0;
  DateTime? _staleSince;

  /// Lo que se pinta en la misma tecla. Nunca espera ni responde "no sé".
  ValueEntryGuess guess(String value) {
    final idx = _index;
    if (idx == null || idx.isOlderThan(maxAge, _now())) unawaited(refresh());
    return guessValueEntry(value, idx, stale: _stale);
  }

  /// Qué hacer con un valor escrito por el cajero, sin esperar nada.
  PriceEntryDecision decide(String value) {
    final idx = _index;
    if (idx == null || idx.isOlderThan(maxAge, _now())) {
      unawaited(refresh());
    }
    final decision = decidePriceEntry(value, idx);
    // Un producto que llegó por la sincronización y aún no está en el
    // índice no debe salir como "sin registrar": se consulta la base.
    if (_stale && decision is AddUnregisteredProduct) {
      return const PriceEntryNeedsLookup();
    }
    return decision;
  }

  /// Rehace el índice (una carga a la vez).
  Future<void> refresh() => _loading ??= _load().whenComplete(() {
        _loading = null;
      });

  Future<void> _load() async {
    _appliedDuringLoad.clear();
    final changesAtStart = _changes;
    final watch = Stopwatch()..start();
    final entries = await loadCodes();
    final complete = await isCatalogComplete();
    if (_disposed) return;
    // Por partes: con 50 mil productos, armarlo de un tirón frenaba la
    // pantalla decenas de ms en cada carga.
    final fresh =
        ShortCodeIndex.build(const [], complete: complete, builtAt: _now());
    for (var from = 0; from < entries.length; from += _chunk) {
      final to = from + _chunk < entries.length ? from + _chunk : entries.length;
      fresh.addCodes(entries.getRange(from, to));
      if (to < entries.length) {
        await Future<void>.delayed(Duration.zero);
        if (_disposed) return;
      }
    }
    _loads++;
    onLoaded?.call(watch.elapsedMicroseconds / 1000);
    for (final c in _appliedDuringLoad) {
      fresh.upsert(c.localId, [c.sku, c.barcode], active: c.active);
    }
    _appliedDuringLoad.clear();
    _index = fresh;
    if (_changes == changesAtStart) {
      _stale = false;
      _staleSince = null;
    } else {
      // Cambió mientras se cargaba: otra vuelta cuando se calme.
      _staleSince = _now();
      _scheduleSettledRefresh();
    }
  }

  void _apply(ProductCodeChange c) {
    _index?.upsert(c.localId, [c.sku, c.barcode], active: c.active);
    // Si hay una carga en curso, su foto de la base puede no tenerlo: se
    // vuelve a aplicar sobre el índice nuevo.
    if (_loading != null) _appliedDuringLoad.add(c);
  }

  final List<ProductCodeChange> _appliedDuringLoad = [];

  void _markStale() {
    _changes++;
    _stale = true;
    _staleSince ??= _now();
    _scheduleSettledRefresh();
  }

  /// Rehace el índice cuando pasan [settleDelay] sin cambios (o, si no
  /// paran, a los [maxSettle] del primero). Antes se rehacía con cada tecla
  /// mientras la sincronización escribía.
  void _scheduleSettledRefresh() {
    if (_disposed) return;
    final waited = _now().difference(_staleSince ?? _now());
    final left = maxSettle - waited;
    final delay = left < settleDelay
        ? (left.isNegative ? Duration.zero : left)
        : settleDelay;
    _retry?.cancel();
    _retry = Timer(delay, () => unawaited(refresh()));
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
  }
}
