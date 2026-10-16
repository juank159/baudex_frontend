import 'dart:async';

import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../../data/local/sync_service.dart';

/// Mixin que auto-refresca datos del controller cuando SyncService
/// completa un ciclo de sincronización (push o pull).
///
/// Uso:
/// ```dart
/// class SuppliersController extends GetxController
///     with CacheFirstMixin<Supplier>, SyncAutoRefreshMixin {
///
///   @override
///   void onInit() {
///     super.onInit();
///     setupSyncListener();
///   }
///
///   @override
///   Future<void> onSyncCompleted() async {
///     invalidateCache();
///     await _refreshInBackground();
///   }
/// }
/// ```
mixin SyncAutoRefreshMixin on GetxController {
  Worker? _syncWorker;
  Timer? _deferredRefresh;
  Timer? _coalescedRefresh;

  /// Varias sincronizaciones seguidas (subida + descarga al abrir la app, o
  /// varias ventas) se juntan en un solo refresco. Antes cada una recargaba
  /// la pantalla completa y el mismo cálculo se repetía 3 o 4 veces.
  static const Duration _coalesceWindow = Duration(milliseconds: 700);

  /// Llamado cuando SyncService transiciona a idle (sync completó).
  /// Cada controller implementa para refrescar sus datos.
  Future<void> onSyncCompleted();

  /// `true` en las pantallas que no forman parte de facturación (tablero,
  /// listados, estadísticas). Mientras el cajero está en facturación, su
  /// recarga espera a que salga de ahí: después de cada venta que sube,
  /// todas recargaban a la vez sin verse y frenaban la búsqueda de
  /// productos de la venta siguiente. Los datos no se pierden: quedan en
  /// la base local y la pantalla se refresca apenas se sale de facturación.
  bool get deferRefreshWhileSelling => false;

  /// La pantalla visible es facturación (punto de venta).
  static bool get isSellingScreenVisible {
    final route = Get.currentRoute;
    return route.startsWith(AppRoutes.invoicesWithTabs) ||
        route.startsWith(AppRoutes.invoicesCreate) ||
        route.startsWith(AppRoutes.invoicesEdit);
  }

  /// Configurar el listener. Llamar desde onInit().
  void setupSyncListener() {
    try {
      final syncService = Get.find<SyncService>();
      _syncWorker = ever(syncService.syncStateObs, (SyncState state) {
        if (state == SyncState.idle && !isClosed) {
          requestSyncRefresh();
        }
      });
    } catch (_) {
      // SyncService no disponible (ej: tests)
    }
  }

  /// Refrescar ahora, o al salir de facturación si esta pantalla espera
  /// ([deferRefreshWhileSelling]). Varias peticiones mientras se vende se
  /// juntan en un solo refresco.
  void requestSyncRefresh() {
    if (isClosed) return;
    if (!deferRefreshWhileSelling || !isSellingScreenVisible) {
      _coalescedRefresh?.cancel();
      _coalescedRefresh = Timer(_coalesceWindow, () {
        _coalescedRefresh = null;
        if (!isClosed) onSyncCompleted();
      });
      return;
    }
    _deferredRefresh ??= Timer.periodic(const Duration(seconds: 2), (timer) {
      if (isClosed) {
        timer.cancel();
        _deferredRefresh = null;
        return;
      }
      if (!isSellingScreenVisible) {
        timer.cancel();
        _deferredRefresh = null;
        onSyncCompleted();
      }
    });
  }

  /// Limpiar el listener
  void disposeSyncListener() {
    _syncWorker?.dispose();
    _syncWorker = null;
    _deferredRefresh?.cancel();
    _deferredRefresh = null;
    _coalescedRefresh?.cancel();
    _coalescedRefresh = null;
  }

  @override
  void onClose() {
    disposeSyncListener();
    super.onClose();
  }
}
