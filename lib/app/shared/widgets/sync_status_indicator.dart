// lib/app/shared/widgets/sync_status_indicator.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/local/sync_service.dart';
import '../../data/local/sync_config.dart';

/// Widget indicador del estado de sincronización
///
/// Muestra un indicador visual del estado de sincronización y permite
/// al usuario ver problemas y tomar acciones cuando sea necesario.
///
/// Uso:
/// ```dart
/// SyncStatusIndicator()
/// // O con estilo compacto:
/// SyncStatusIndicator(compact: true)
/// ```
class SyncStatusIndicator extends StatelessWidget {
  /// Si es true, muestra solo el icono sin texto
  final bool compact;

  /// Si es true, muestra el indicador solo cuando hay problemas
  final bool showOnlyOnIssues;

  const SyncStatusIndicator({
    super.key,
    this.compact = false,
    this.showOnlyOnIssues = false,
  });

  @override
  Widget build(BuildContext context) {
    // Verificar si SyncService está registrado
    if (!Get.isRegistered<SyncService>()) {
      return const SizedBox.shrink();
    }

    final syncService = Get.find<SyncService>();

    return Obx(() {
      final healthInfo = syncService.healthInfo;
      final pendingCount = syncService.pendingOperationsCount;

      // Si solo mostrar en problemas y no hay problemas, ocultar
      if (showOnlyOnIssues && healthInfo.status == SyncHealthStatus.healthy) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () => _showSyncStatusDialog(context, syncService),
        child: Container(
          padding: compact
              ? const EdgeInsets.all(4)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getBackgroundColor(healthInfo.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getBackgroundColor(healthInfo.status).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(healthInfo, pendingCount),
              if (!compact) ...[
                const SizedBox(width: 6),
                _buildStatusText(healthInfo, pendingCount),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatusIcon(SyncHealthInfo healthInfo, int pendingCount) {
    final color = _getIconColor(healthInfo.status);

    // Animación de sincronización en progreso
    if (healthInfo.status == SyncHealthStatus.healthy && pendingCount > 0) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Icon(
      _getIcon(healthInfo.status),
      size: 16,
      color: color,
    );
  }

  Widget _buildStatusText(SyncHealthInfo healthInfo, int pendingCount) {
    String text;
    switch (healthInfo.status) {
      case SyncHealthStatus.healthy:
        text = pendingCount > 0 ? 'Sincronizando ($pendingCount)' : 'Sincronizado';
        break;
      case SyncHealthStatus.degraded:
        text = '${healthInfo.failedCount} fallidas';
        break;
      case SyncHealthStatus.overloaded:
        text = '${healthInfo.pendingCount} pendientes';
        break;
      case SyncHealthStatus.critical:
        text = 'Requiere atención';
        break;
      case SyncHealthStatus.offline:
        text = 'Sin conexión';
        break;
      case SyncHealthStatus.error:
        text = 'Error';
        break;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: _getIconColor(healthInfo.status),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  IconData _getIcon(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return Icons.cloud_done_outlined;
      case SyncHealthStatus.degraded:
        return Icons.cloud_sync_outlined;
      case SyncHealthStatus.overloaded:
        return Icons.cloud_queue_outlined;
      case SyncHealthStatus.critical:
        return Icons.cloud_off_outlined;
      case SyncHealthStatus.offline:
        return Icons.cloud_off_outlined;
      case SyncHealthStatus.error:
        return Icons.error_outline;
    }
  }

  Color _getIconColor(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return Colors.green;
      case SyncHealthStatus.degraded:
        return Colors.orange;
      case SyncHealthStatus.overloaded:
        return Colors.orange;
      case SyncHealthStatus.critical:
        return Colors.red;
      case SyncHealthStatus.offline:
        return Colors.grey;
      case SyncHealthStatus.error:
        return Colors.red;
    }
  }

  Color _getBackgroundColor(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return Colors.green;
      case SyncHealthStatus.degraded:
        return Colors.orange;
      case SyncHealthStatus.overloaded:
        return Colors.orange;
      case SyncHealthStatus.critical:
        return Colors.red;
      case SyncHealthStatus.offline:
        return Colors.grey;
      case SyncHealthStatus.error:
        return Colors.red;
    }
  }

  void _showSyncStatusDialog(BuildContext context, SyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => SyncStatusDialog(syncService: syncService),
    );
  }
}

/// Diálogo detallado del estado de sincronización
class SyncStatusDialog extends StatelessWidget {
  final SyncService syncService;

  const SyncStatusDialog({super.key, required this.syncService});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final healthInfo = syncService.healthInfo;
      final metrics = syncService.getSessionMetrics();

      return AlertDialog(
        title: Row(
          children: [
            Icon(
              _getStatusIcon(healthInfo.status),
              color: _getStatusColor(healthInfo.status),
            ),
            const SizedBox(width: 8),
            const Text('Estado de Sincronización'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado general
              _buildInfoTile(
                'Estado',
                _getStatusText(healthInfo.status),
                _getStatusColor(healthInfo.status),
              ),
              const SizedBox(height: 12),

              // Conexión
              _buildInfoTile(
                'Conexión',
                healthInfo.isOnline ? 'En línea' : 'Sin conexión',
                healthInfo.isOnline ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 12),

              // Estadísticas
              const Text(
                'Estadísticas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatRow('Pendientes', healthInfo.pendingCount),
              _buildStatRow('Fallidas', healthInfo.failedCount),
              _buildStatRow('Completadas', healthInfo.completedCount),
              if (healthInfo.permanentlyFailedCount > 0)
                _buildStatRow(
                  'Permanentemente fallidas',
                  healthInfo.permanentlyFailedCount,
                  color: Colors.red,
                ),

              const SizedBox(height: 12),

              // Métricas de sesión
              const Text(
                'Sesión actual:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatRow('Exitosas', metrics['successCount'] ?? 0),
              _buildStatRow('Fallidas', metrics['failureCount'] ?? 0),
              _buildStatRow('Omitidas', metrics['skippedCount'] ?? 0),

              // Última sincronización
              if (healthInfo.lastSyncTime != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Última sincronización: ${_formatDateTime(healthInfo.lastSyncTime!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              // Advertencias
              if (healthInfo.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Advertencias:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ...healthInfo.warnings.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(w, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Problemas críticos
              if (healthInfo.issues.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Problemas que requieren atención:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...healthInfo.issues.map(
                  (issue) => Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getIssueSeverityIcon(issue.severity),
                                size: 16,
                                color: _getIssueSeverityColor(issue.severity),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  issue.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _getIssueSeverityColor(issue.severity),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (issue.entityType != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${issue.entityType}: ${issue.entityId ?? "N/A"}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          // Botón para limpiar operaciones fallidas
          if (healthInfo.permanentlyFailedCount > 0)
            TextButton(
              onPressed: () async {
                final count = await syncService.cleanPermanentlyFailedOperations();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$count operaciones eliminadas'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                'Limpiar fallidas',
                style: TextStyle(color: Colors.red),
              ),
            ),

          // Botón para forzar sincronización
          if (healthInfo.isOnline && healthInfo.pendingCount > 0)
            TextButton(
              onPressed: () {
                syncService.forceSyncNow();
                Navigator.of(context).pop();
              },
              child: const Text('Sincronizar ahora'),
            ),

          // Botón cerrar
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    });
  }

  Widget _buildInfoTile(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return Icons.check_circle_outline;
      case SyncHealthStatus.degraded:
        return Icons.warning_amber_rounded;
      case SyncHealthStatus.overloaded:
        return Icons.hourglass_top;
      case SyncHealthStatus.critical:
        return Icons.error_outline;
      case SyncHealthStatus.offline:
        return Icons.cloud_off_outlined;
      case SyncHealthStatus.error:
        return Icons.error;
    }
  }

  Color _getStatusColor(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return Colors.green;
      case SyncHealthStatus.degraded:
        return Colors.orange;
      case SyncHealthStatus.overloaded:
        return Colors.orange;
      case SyncHealthStatus.critical:
        return Colors.red;
      case SyncHealthStatus.offline:
        return Colors.grey;
      case SyncHealthStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText(SyncHealthStatus status) {
    switch (status) {
      case SyncHealthStatus.healthy:
        return 'Saludable';
      case SyncHealthStatus.degraded:
        return 'Degradado';
      case SyncHealthStatus.overloaded:
        return 'Sobrecargado';
      case SyncHealthStatus.critical:
        return 'Crítico';
      case SyncHealthStatus.offline:
        return 'Sin conexión';
      case SyncHealthStatus.error:
        return 'Error';
    }
  }

  IconData _getIssueSeverityIcon(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.info:
        return Icons.info_outline;
      case IssueSeverity.warning:
        return Icons.warning_amber_rounded;
      case IssueSeverity.error:
        return Icons.error_outline;
      case IssueSeverity.critical:
        return Icons.report_problem;
    }
  }

  Color _getIssueSeverityColor(IssueSeverity severity) {
    switch (severity) {
      case IssueSeverity.info:
        return Colors.blue;
      case IssueSeverity.warning:
        return Colors.orange;
      case IssueSeverity.error:
        return Colors.red;
      case IssueSeverity.critical:
        return Colors.red.shade700;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Hace un momento';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} minutos';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Snackbar para notificaciones de sincronización
class SyncNotificationService {
  static void showSyncStarted(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Sincronizando datos...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
  }

  static void showSyncCompleted(BuildContext context, int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('$count operación(es) sincronizada(s)'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void showSyncFailed(BuildContext context, int failedCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$failedCount operación(es) no pudieron sincronizarse'),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Ver detalles',
          textColor: Colors.white,
          onPressed: () {
            // Navegar a detalles de sync
          },
        ),
      ),
    );
  }

  static void showCriticalSyncIssue(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Resolver',
          textColor: Colors.white,
          onPressed: () {
            // Navegar a resolver problema
          },
        ),
      ),
    );
  }

  static void showOfflineMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Modo sin conexión - Los cambios se sincronizarán cuando vuelvas a estar en línea'),
          ],
        ),
        duration: Duration(seconds: 4),
        backgroundColor: Colors.grey,
      ),
    );
  }

  static void showOnlineMode(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.cloud_done, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Conexión restaurada - Sincronizando cambios...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}
