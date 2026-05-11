import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../core/utils/app_logger.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import 'isar_database.dart';
import 'sync_event_log.dart';

/// Servicio para escribir y leer eventos del log de sincronización.
///
/// Encapsula el acceso a la colección `IsarSyncEventLog` para que el resto
/// del código no tenga que conocer detalles de Isar.
///
/// Diseñado para ser **inyectado vía GetX** y tolerar la ausencia de
/// `organizationId` (algunos eventos globales se loguean antes del login).
class SyncEventLogService {
  /// Límite de eventos persistidos por defecto. Cuando hay más de N, el
  /// `prune()` automático borra los más viejos. 5000 cubre semanas de uso
  /// activo sin saturar Isar.
  static const int defaultMaxEvents = 5000;

  /// Eventos más recientes para mostrar en la UI por default.
  static const int defaultRecentLimit = 100;

  /// Escribe un evento al log. **Tolerante a fallas**: si Isar falla,
  /// solo se loguea por consola y el flujo continúa. NUNCA propaga
  /// excepciones — esta función no debe romper sync.
  Future<void> log({
    required SyncEventSeverity severity,
    required SyncEventType eventType,
    required String operation,
    required String message,
    String entityType = '',
    String entityId = '',
    String? details,
    int retryCount = 0,
    String? organizationId,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final orgId = organizationId ?? _resolveCurrentOrganizationId();
      final entry = IsarSyncEventLog.create(
        severity: severity,
        eventType: eventType,
        operation: operation,
        message: message,
        entityType: entityType,
        entityId: entityId,
        details: details,
        retryCount: retryCount,
        organizationId: orgId,
      );
      await isar.writeTxn(() async {
        await isar.isarSyncEventLogs.put(entry);
      });
    } catch (e) {
      // Tolerante a fallas: si no podemos persistir el log, no rompemos
      // el flujo de sync. Solo notificamos por consola/AppLogger.
      AppLogger.w(
        'SyncEventLogService: no pudo persistir log (continuando): $e',
        tag: 'DIAGNOSTIC',
      );
    }
  }

  /// Logs de los últimos `limit` eventos del tenant actual, ordenados de
  /// más reciente a más viejo.
  Future<List<IsarSyncEventLog>> getRecent({
    int limit = defaultRecentLimit,
    SyncEventSeverity? severity,
    SyncEventType? eventType,
  }) async {
    try {
      final isar = IsarDatabase.instance.database;
      final orgId = _resolveCurrentOrganizationId();

      var query = isar.isarSyncEventLogs.filter().organizationIdEqualTo(orgId);

      if (severity != null) {
        query = query.severityEqualTo(severity);
      }
      if (eventType != null) {
        query = query.eventTypeEqualTo(eventType);
      }

      return await query.sortByTimestampDesc().limit(limit).findAll();
    } catch (e) {
      AppLogger.w('SyncEventLogService.getRecent falló: $e',
          tag: 'DIAGNOSTIC');
      return [];
    }
  }

  /// Cuenta eventos del tenant agrupados por severidad. Útil para el
  /// header del módulo de diagnóstico.
  Future<Map<SyncEventSeverity, int>> countBySeverity() async {
    try {
      final isar = IsarDatabase.instance.database;
      final orgId = _resolveCurrentOrganizationId();
      final result = <SyncEventSeverity, int>{};

      for (final s in SyncEventSeverity.values) {
        result[s] = await isar.isarSyncEventLogs
            .filter()
            .organizationIdEqualTo(orgId)
            .severityEqualTo(s)
            .count();
      }
      return result;
    } catch (e) {
      AppLogger.w('SyncEventLogService.countBySeverity falló: $e',
          tag: 'DIAGNOSTIC');
      return {for (final s in SyncEventSeverity.values) s: 0};
    }
  }

  /// Borra todos los eventos del tenant más viejos que `cutoff`.
  /// Devuelve cuántos eventos se eliminaron.
  Future<int> pruneOlderThan(DateTime cutoff) async {
    try {
      final isar = IsarDatabase.instance.database;
      final orgId = _resolveCurrentOrganizationId();
      final old = await isar.isarSyncEventLogs
          .filter()
          .organizationIdEqualTo(orgId)
          .timestampLessThan(cutoff)
          .findAll();
      if (old.isEmpty) return 0;
      await isar.writeTxn(() async {
        await isar.isarSyncEventLogs.deleteAll(old.map((e) => e.id).toList());
      });
      return old.length;
    } catch (e) {
      AppLogger.w('SyncEventLogService.pruneOlderThan falló: $e',
          tag: 'DIAGNOSTIC');
      return 0;
    }
  }

  /// Borra TODOS los eventos del tenant. Útil para limpieza manual desde
  /// la pantalla de diagnóstico.
  Future<int> clearAll() async {
    try {
      final isar = IsarDatabase.instance.database;
      final orgId = _resolveCurrentOrganizationId();
      final all = await isar.isarSyncEventLogs
          .filter()
          .organizationIdEqualTo(orgId)
          .findAll();
      if (all.isEmpty) return 0;
      await isar.writeTxn(() async {
        await isar.isarSyncEventLogs.deleteAll(all.map((e) => e.id).toList());
      });
      return all.length;
    } catch (e) {
      AppLogger.w('SyncEventLogService.clearAll falló: $e', tag: 'DIAGNOSTIC');
      return 0;
    }
  }

  /// Resuelve el organizationId del usuario autenticado siguiendo el
  /// patrón del proyecto (Get.find<AuthController>()). Si no hay sesión
  /// activa o el controller no está registrado, devuelve cadena vacía:
  /// el evento se persiste igual y la UI de diagnóstico simplemente no
  /// lo mostrará para ningún tenant (queda como log "huérfano" para
  /// soporte).
  String _resolveCurrentOrganizationId() {
    try {
      if (!Get.isRegistered<AuthController>()) return '';
      final auth = Get.find<AuthController>();
      return auth.currentUser?.organizationId ?? '';
    } catch (_) {
      return '';
    }
  }
}
