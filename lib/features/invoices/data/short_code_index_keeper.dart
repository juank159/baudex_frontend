// lib/features/invoices/data/short_code_index_keeper.dart
import 'dart:async';

import '../../products/data/product_code_events.dart';
import '../domain/price_entry.dart';

/// Mantiene al día el índice de códigos cortos de la factura:
/// - lo carga de la base en segundo plano (y lo rehace cada [maxAge] como
///   respaldo);
/// - aplica AL INSTANTE los productos creados/editados/borrados en el
///   equipo ([codeChanges]);
/// - si la colección cambió por otro camino (la sincronización), queda
///   "pendiente" y, mientras se rehace, la decisión consulta la base
///   ([PriceEntryNeedsLookup]) en vez de arriesgar un "sin registrar".
class ShortCodeIndexKeeper {
  ShortCodeIndexKeeper({
    required this.loadCodes,
    required this.isCatalogComplete,
    Stream<ProductCodeChange>? codeChanges,
    Stream<void>? collectionChanges,
    this.maxAge = const Duration(seconds: 20),
    this.retryDelay = const Duration(seconds: 1),
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
  final Duration retryDelay;
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

  /// Qué hacer con un valor escrito por el cajero, sin esperar nada.
  PriceEntryDecision decide(String value) {
    final idx = _index;
    if (idx == null || _stale || idx.isOlderThan(maxAge, _now())) {
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
    final entries = await loadCodes();
    final complete = await isCatalogComplete();
    if (_disposed) return;
    final fresh = ShortCodeIndex.build(entries, complete: complete, builtAt: _now());
    for (final c in _appliedDuringLoad) {
      fresh.upsert(c.localId, [c.sku, c.barcode], active: c.active);
    }
    _appliedDuringLoad.clear();
    _index = fresh;
    if (_changes == changesAtStart) {
      _stale = false;
    } else {
      // Cambió mientras se cargaba: otra vuelta, sin martillar la base.
      _retry?.cancel();
      _retry = Timer(retryDelay, () => unawaited(refresh()));
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
  }

  void dispose() {
    _disposed = true;
    _retry?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
  }
}
