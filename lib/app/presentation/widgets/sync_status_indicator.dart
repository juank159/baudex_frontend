import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/local/sync_service.dart';

/// Widget que muestra el estado de sincronización
///
/// Estados:
/// - ⏳ Sincronizando (spinner animado)
/// - ☁️ Pendiente (badge con número de operaciones)
/// - ✅ Sincronizado (ícono verde)
/// - ❌ Error (ícono rojo con tooltip)
/// - 📡 Offline (ícono gris)
class SyncStatusIndicator extends StatelessWidget {
  final bool showLabel;
  final double iconSize;

  const SyncStatusIndicator({
    super.key,
    this.showLabel = false,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final syncService = Get.find<SyncService>();

    return Obx(() {
      // Estado offline
      if (!syncService.isOnline) {
        return _buildOfflineIndicator();
      }

      // Estado sincronizando
      if (syncService.syncState == SyncState.syncing) {
        return _buildSyncingIndicator();
      }

      // Estado con operaciones pendientes
      if (syncService.pendingOperationsCount > 0) {
        return _buildPendingIndicator(syncService.pendingOperationsCount);
      }

      // Estado error
      if (syncService.syncState == SyncState.error) {
        return _buildErrorIndicator();
      }

      // Estado sincronizado
      return _buildSyncedIndicator(syncService.lastSyncTime);
    });
  }

  /// Indicador de modo offline
  Widget _buildOfflineIndicator() {
    return Tooltip(
      message: 'Sin conexión - Trabajando offline',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: iconSize,
            color: Colors.grey,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            const Text(
              'Offline',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Indicador de sincronización en progreso
  Widget _buildSyncingIndicator() {
    return Tooltip(
      message: 'Sincronizando datos...',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'Sincronizando',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Indicador de operaciones pendientes
  Widget _buildPendingIndicator(int count) {
    return Tooltip(
      message: '$count operación${count > 1 ? 'es' : ''} pendiente${count > 1 ? 's' : ''}',
      child: InkWell(
        onTap: () {
          // Forzar sincronización al hacer clic
          Get.find<SyncService>().forceSyncNow();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    size: iconSize,
                    color: Colors.orange.shade600,
                  ),
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  'Pendiente${count > 1 ? 's' : ''}: $count',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Indicador de error
  Widget _buildErrorIndicator() {
    return Tooltip(
      message: 'Error en sincronización - Toca para reintentar',
      child: InkWell(
        onTap: () {
          // Reintentar sincronización
          Get.find<SyncService>().forceSyncNow();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: iconSize,
                color: Colors.red.shade600,
              ),
              if (showLabel) ...[
                const SizedBox(width: 4),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Indicador de sincronizado
  Widget _buildSyncedIndicator(DateTime? lastSyncTime) {
    final message = lastSyncTime != null
        ? 'Sincronizado - ${_formatLastSyncTime(lastSyncTime)}'
        : 'Sincronizado';

    return Tooltip(
      message: message,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            size: iconSize,
            color: Colors.green.shade600,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              'Sincronizado',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Formatear última sincronización para mostrar en tooltip
  String _formatLastSyncTime(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds} segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    }
  }
}

/// Widget compacto para mostrar solo el ícono en AppBar
class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: SyncStatusIndicator(
        showLabel: false,
        iconSize: 20,
      ),
    );
  }
}

/// Widget con etiqueta para mostrar en drawer o settings
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncStatusIndicator(
      showLabel: true,
      iconSize: 24,
    );
  }
}
