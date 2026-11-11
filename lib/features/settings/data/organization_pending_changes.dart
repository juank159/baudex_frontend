// lib/features/settings/data/organization_pending_changes.dart
import '../../../app/data/local/isar_database.dart';
import '../../../app/data/local/sync_config.dart';
import '../domain/services/organization_settings_rules.dart';

/// Único criterio de "hay cambios locales de la configuración del negocio que
/// aún no suben". Lo usan el controlador, el repositorio y la descarga
/// (FullSync), para que los tres decidan lo mismo.
class OrganizationPendingChanges {
  const OrganizationPendingChanges._();

  static Future<bool> hasPending() async {
    try {
      final pending = await IsarDatabase.instance.getPendingSyncOperations();
      return pending.any((op) => blocksServerOrganization(
            entityType: op.entityType,
            retryCount: op.retryCount,
            maxRetries: SyncConfig.maxRetries,
          ));
    } catch (_) {
      return false;
    }
  }
}
