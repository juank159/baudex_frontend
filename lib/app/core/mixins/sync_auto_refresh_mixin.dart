import 'package:get/get.dart';
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

  /// Llamado cuando SyncService transiciona a idle (sync completó).
  /// Cada controller implementa para refrescar sus datos.
  Future<void> onSyncCompleted();

  /// Configurar el listener. Llamar desde onInit().
  void setupSyncListener() {
    try {
      final syncService = Get.find<SyncService>();
      _syncWorker = ever(syncService.syncStateObs, (SyncState state) {
        if (state == SyncState.idle && !isClosed) {
          onSyncCompleted();
        }
      });
    } catch (_) {
      // SyncService no disponible (ej: tests)
    }
  }

  /// Limpiar el listener
  void disposeSyncListener() {
    _syncWorker?.dispose();
    _syncWorker = null;
  }

  @override
  void onClose() {
    disposeSyncListener();
    super.onClose();
  }
}
