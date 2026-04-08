import 'package:get/get.dart';

/// Entrada de cache con items, stats y timestamp
class _CacheEntry {
  List<dynamic>? items;
  dynamic stats;
  DateTime? lastTime;
  bool needsRefresh = false;

  bool isValid(Duration validity) {
    if (items == null || lastTime == null) return false;
    return DateTime.now().difference(lastTime!) < validity;
  }

  void update(List<dynamic> newItems, {dynamic newStats}) {
    items = List.from(newItems);
    if (newStats != null) stats = newStats;
    lastTime = DateTime.now();
    needsRefresh = false;
  }

  void invalidate() {
    items = null;
    stats = null;
    lastTime = null;
    needsRefresh = true;
  }
}

/// Mixin que agrega cache estático por tipo de controller.
///
/// Usa un registry static (como SearchLifecycleMixin._memory) para
/// persistir datos entre recreaciones del controller.
///
/// Uso:
/// ```dart
/// class SuppliersController extends GetxController
///     with CacheFirstMixin<Supplier> {
///
///   @override
///   String get cacheKey => 'SuppliersController';
///
///   // En loadSuppliers():
///   if (tryLoadFromCache(...)) {
///     refreshInBackground(() => _fetchFromServer());
///     return;
///   }
/// }
/// ```
mixin CacheFirstMixin<T> on GetxController {
  // Registry estático: una entrada por cacheKey (típicamente runtimeType)
  static final Map<String, _CacheEntry> _registry = {};

  /// Clave única para el cache de este controller
  String get cacheKey => runtimeType.toString();

  /// Duración de validez del cache (default 5 min)
  Duration get cacheValidity => const Duration(minutes: 5);

  /// Guard para prevenir refreshes concurrentes en background
  bool _bgRefreshing = false;

  _CacheEntry get _cache => _registry.putIfAbsent(cacheKey, () => _CacheEntry());

  /// Cache disponible y válido
  bool get hasCachedData => _cache.isValid(cacheValidity);

  /// Items del cache, casteados a List<T>
  List<T>? get cachedItems => _cache.items?.cast<T>();

  /// Stats del cache (tipo genérico)
  S? getCachedStats<S>() => _cache.stats as S?;

  /// Actualizar cache con nuevos datos
  void updateCache(List<T> items, {dynamic stats}) {
    _cache.update(items, newStats: stats);
  }

  /// Invalidar cache (llamar después de operaciones CRUD)
  void invalidateCache() {
    _cache.invalidate();
  }

  /// Invalidar cache estáticamente (desde form controllers u otros)
  static void invalidateCacheFor(String key) {
    _registry[key]?.invalidate();
  }

  /// Intentar cargar desde cache. Retorna true si usó cache.
  ///
  /// Si retorna true, el caller debe hacer return (skip fetch del servidor).
  /// Automáticamente dispara refreshInBackground si hay cache válido.
  bool tryLoadFromCache({
    required void Function(List<T> items) onHit,
    void Function(dynamic stats)? onStatsHit,
    required bool hasFilters,
    required bool isFirstPage,
    required bool isSearching,
    bool forceRefresh = false,
  }) {
    if (forceRefresh) return false;
    if (!isFirstPage || hasFilters || isSearching) return false;

    if (_cache.needsRefresh) {
      _cache.needsRefresh = false;
      return false;
    }

    if (!hasCachedData) return false;

    onHit(List<T>.from(cachedItems!));

    if (_cache.stats != null && onStatsHit != null) {
      onStatsHit(_cache.stats);
    }

    return true;
  }

  /// Ejecutar fetch en background sin bloquear UI.
  /// Guard previene ejecuciones concurrentes.
  Future<void> refreshInBackground(Future<void> Function() fetcher) async {
    if (_bgRefreshing) return;
    _bgRefreshing = true;
    try {
      await fetcher();
    } catch (_) {
    } finally {
      _bgRefreshing = false;
    }
  }
}
