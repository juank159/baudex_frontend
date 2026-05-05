// lib/features/diagnostics/presentation/screens/sync_diagnostic_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/data/local/sync_event_log.dart';
import '../controllers/sync_diagnostic_controller.dart';

class SyncDiagnosticScreen extends GetView<SyncDiagnosticController> {
  const SyncDiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      body: Column(
        children: [
          _DiagnosticHeader(isNarrow: isNarrow),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.entityCounts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: ElegantLightTheme.primaryBlue,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refreshAll,
                color: ElegantLightTheme.primaryBlue,
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12 : 20,
                    vertical: 16,
                  ),
                  children: [
                    _ConnectionStatusSection(isNarrow: isNarrow),
                    const SizedBox(height: 16),
                    _EntityHealthSection(isNarrow: isNarrow),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.pendingQueueOps.value == 0) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _PendingOpsSection(isNarrow: isNarrow),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                    _RecentEventsSection(isNarrow: isNarrow),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            }),
          ),
          _FixedFooter(isNarrow: isNarrow),
        ],
      ),
    );
  }
}

// ==================== HEADER ====================

class _DiagnosticHeader extends GetView<SyncDiagnosticController> {
  final bool isNarrow;
  const _DiagnosticHeader({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: isNarrow ? 12 : 20,
        right: isNarrow ? 8 : 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
            tooltip: 'Volver',
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diagnostico del sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Text(
                      'Actualizando...',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    );
                  }
                  return const Text(
                    'Estado de sincronizacion y errores',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  );
                }),
              ],
            ),
          ),
          Obx(() => controller.isLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: controller.refreshAll,
                  tooltip: 'Refrescar',
                )),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _exportReport(),
            tooltip: 'Exportar reporte',
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    final text =
        Get.find<SyncDiagnosticController>().exportDiagnosticReport();
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Reporte copiado',
      'El diagnostico fue copiado al portapapeles',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(milliseconds: 2500),
      backgroundColor: ElegantLightTheme.successGreen.withOpacity(0.95),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }
}

// ==================== CONNECTION STATUS ====================

class _ConnectionStatusSection extends GetView<SyncDiagnosticController> {
  final bool isNarrow;
  const _ConnectionStatusSection({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Estado de conexion',
      icon: Icons.wifi,
      child: Obx(() {
        final online = controller.isOnline.value;
        final pending = controller.pendingQueueOps.value;

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (online
                        ? ElegantLightTheme.successGreen
                        : ElegantLightTheme.errorRed)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: online
                      ? ElegantLightTheme.successGreen
                      : ElegantLightTheme.errorRed,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    online ? Icons.circle : Icons.cancel,
                    color: online
                        ? ElegantLightTheme.successGreen
                        : ElegantLightTheme.errorRed,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    online ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: online
                          ? ElegantLightTheme.successGreen
                          : ElegantLightTheme.errorRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operaciones pendientes',
                    style: TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _CountBadge(
                        value: pending,
                        zeroColor: ElegantLightTheme.successGreen,
                        nonZeroColor: pending > 10
                            ? ElegantLightTheme.errorRed
                            : ElegantLightTheme.warningOrange,
                      ),
                      if (pending > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          'en cola',
                          style: const TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ==================== ENTITY HEALTH ====================

class _EntityHealthSection extends GetView<SyncDiagnosticController> {
  final bool isNarrow;
  const _EntityHealthSection({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Salud por entidad',
      icon: Icons.storage_outlined,
      child: Obx(() {
        final counts = controller.entityCounts;
        if (counts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Sin datos disponibles',
              style: TextStyle(color: ElegantLightTheme.textTertiary),
            ),
          );
        }
        return Column(
          children: counts.map((ec) => _EntityRow(ec: ec)).toList(),
        );
      }),
    );
  }
}

class _EntityRow extends StatelessWidget {
  final EntityCount ec;
  const _EntityRow({required this.ec});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ec.hasIssues
            ? ElegantLightTheme.warningOrange.withOpacity(0.06)
            : ElegantLightTheme.successGreen.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ec.hasIssues
              ? ElegantLightTheme.warningOrange.withOpacity(0.35)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            ec.hasIssues ? Icons.warning_amber_rounded : Icons.check_circle,
            color: ec.hasIssues
                ? ElegantLightTheme.warningOrange
                : ElegantLightTheme.successGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ec.label,
              style: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${ec.total}',
            style: const TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          if (ec.unsynced > 0) ...[
            const SizedBox(width: 6),
            _SmallBadge(
              label: '${ec.unsynced} sin sync',
              color: ElegantLightTheme.warningOrange,
            ),
          ],
          if (ec.offline > 0) ...[
            const SizedBox(width: 4),
            _SmallBadge(
              label: '${ec.offline} offline',
              color: ElegantLightTheme.errorRed,
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== PENDING OPS ====================

class _PendingOpsSection extends GetView<SyncDiagnosticController> {
  final bool isNarrow;
  const _PendingOpsSection({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Operaciones pendientes',
      icon: Icons.pending_outlined,
      child: Obx(() {
        final bd = controller.pendingBreakdown.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary row
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _SummaryChip(
                    label: '${bd.pending} pendientes',
                    color: ElegantLightTheme.primaryBlue),
                _SummaryChip(
                    label: '${bd.failed} fallidas',
                    color: ElegantLightTheme.errorRed),
                _SummaryChip(
                    label: '${bd.inProgress} en progreso',
                    color: ElegantLightTheme.warningOrange),
              ],
            ),
            if (bd.byEntityType.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ExpandableEntityList(byEntityType: bd.byEntityType),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.retryFailedOperations,
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text('Reintentar fallidas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ElegantLightTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => _confirmClean(context),
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    size: 16,
                    color: ElegantLightTheme.warningOrange,
                  ),
                  label: const Text(
                    'Limpiar fallidas',
                    style: TextStyle(color: ElegantLightTheme.warningOrange),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmClean(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar operaciones fallidas'),
        content: const Text(
          'Se eliminaran las operaciones que superaron el limite de reintentos. '
          'Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Limpiar',
              style: TextStyle(color: ElegantLightTheme.warningOrange),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.cleanFailedOperations();
    }
  }
}

class _ExpandableEntityList extends StatefulWidget {
  final Map<String, int> byEntityType;
  const _ExpandableEntityList({required this.byEntityType});

  @override
  State<_ExpandableEntityList> createState() => _ExpandableEntityListState();
}

class _ExpandableEntityListState extends State<_ExpandableEntityList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _expanded ? 'Ocultar por tipo' : 'Ver por tipo',
                style: const TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          ...widget.byEntityType.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                  _SmallBadge(
                    label: '${e.value}',
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ==================== RECENT EVENTS ====================

class _RecentEventsSection extends GetView<SyncDiagnosticController> {
  final bool isNarrow;
  const _RecentEventsSection({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return _FilterableEventsSection(isNarrow: isNarrow);
  }
}

class _FilterableEventsSection extends GetView<SyncDiagnosticController> {
  final bool isNarrow;
  const _FilterableEventsSection({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return _EventsSectionContent(isNarrow: isNarrow);
  }
}

class _EventsSectionContent extends StatefulWidget {
  final bool isNarrow;
  const _EventsSectionContent({required this.isNarrow});

  @override
  State<_EventsSectionContent> createState() => _EventsSectionContentState();
}

class _EventsSectionContentState extends State<_EventsSectionContent> {
  // 0 = all, 1 = errors only, 2 = warnings only
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SyncDiagnosticController>();

    return _SectionCard(
      title: 'Eventos recientes',
      icon: Icons.list_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity count chips
          Obx(() {
            final counts = ctrl.eventCountsBySeverity.value;
            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _SeverityChip(
                  icon: Icons.info_outline,
                  count: counts[SyncEventSeverity.info] ?? 0,
                  color: ElegantLightTheme.primaryBlue,
                  label: 'info',
                ),
                _SeverityChip(
                  icon: Icons.warning_amber_rounded,
                  count: counts[SyncEventSeverity.warning] ?? 0,
                  color: ElegantLightTheme.warningOrange,
                  label: 'warnings',
                ),
                _SeverityChip(
                  icon: Icons.error_outline,
                  count: counts[SyncEventSeverity.error] ?? 0,
                  color: ElegantLightTheme.errorRed,
                  label: 'errores',
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          // Filter selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _filterIndex == 0,
                  onTap: () => setState(() => _filterIndex = 0),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Solo errores',
                  selected: _filterIndex == 1,
                  onTap: () => setState(() => _filterIndex = 1),
                  color: ElegantLightTheme.errorRed,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Solo warnings',
                  selected: _filterIndex == 2,
                  onTap: () => setState(() => _filterIndex = 2),
                  color: ElegantLightTheme.warningOrange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Events list
          Obx(() {
            final all = ctrl.recentEvents;
            final filtered = _filterIndex == 0
                ? all
                : _filterIndex == 1
                    ? all
                        .where((e) => e.severity == SyncEventSeverity.error)
                        .toList()
                    : all
                        .where((e) => e.severity == SyncEventSeverity.warning)
                        .toList();

            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Sin eventos en este filtro',
                    style: TextStyle(
                      color: ElegantLightTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: filtered
                  .take(100)
                  .map((e) => _EventRow(event: e))
                  .toList(),
            );
          }),
          const SizedBox(height: 12),
          // Prune button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => ctrl.pruneOldEvents(days: 30),
              icon: const Icon(
                Icons.auto_delete_outlined,
                size: 15,
                color: ElegantLightTheme.textSecondary,
              ),
              label: const Text(
                'Limpiar eventos > 30 dias',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatefulWidget {
  final IsarSyncEventLog event;
  const _EventRow({required this.event});

  @override
  State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.event.severity) {
      case SyncEventSeverity.error:
        return ElegantLightTheme.errorRed;
      case SyncEventSeverity.warning:
        return ElegantLightTheme.warningOrange;
      case SyncEventSeverity.info:
        return ElegantLightTheme.primaryBlue;
    }
  }

  IconData get _severityIcon {
    switch (widget.event.severity) {
      case SyncEventSeverity.error:
        return Icons.error_outline;
      case SyncEventSeverity.warning:
        return Icons.warning_amber_rounded;
      case SyncEventSeverity.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails =
        widget.event.details != null && widget.event.details!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _severityColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _severityColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_severityIcon, color: _severityColor, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.event.entityType.isNotEmpty ? "${widget.event.entityType} / " : ""}${widget.event.operation}',
                      style: TextStyle(
                        color: _severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.event.message,
                      style: const TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppFormatters.formatDateTime(widget.event.timestamp.toLocal()),
                style: const TextStyle(
                  color: ElegantLightTheme.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (hasDetails) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: ElegantLightTheme.textTertiary,
                  ),
                  Text(
                    _expanded ? 'Ocultar detalle' : 'Ver detalle',
                    style: const TextStyle(
                      color: ElegantLightTheme.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (_expanded)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.cardColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.event.details!,
                  style: const TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ==================== FIXED FOOTER ====================

class _FixedFooter extends GetView<SyncDiagnosticController> {
  final bool isNarrow;
  const _FixedFooter({required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12 : 20,
        12,
        isNarrow ? 12 : 20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: ElegantLightTheme.surfaceColor,
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Obx(() {
              final disabled = !controller.isOnline.value ||
                  controller.isLoading.value;
              return _GradientButton(
                label: 'Forzar sincronizacion completa',
                icon: Icons.sync,
                gradient: disabled ? null : ElegantLightTheme.primaryGradient,
                onPressed: disabled ? null : controller.forceFullSync,
                isLoading: controller.isLoading.value,
              );
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _exportReport,
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Exportar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: ElegantLightTheme.primaryBlue,
                side: const BorderSide(color: ElegantLightTheme.primaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    final text =
        Get.find<SyncDiagnosticController>().exportDiagnosticReport();
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Reporte copiado',
      'El diagnostico fue copiado al portapapeles',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(milliseconds: 2500),
      backgroundColor: ElegantLightTheme.successGreen.withOpacity(0.95),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }
}

// ==================== SHARED WIDGETS ====================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ElegantLightTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ElegantLightTheme.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int value;
  final Color zeroColor;
  final Color nonZeroColor;

  const _CountBadge({
    required this.value,
    required this.zeroColor,
    required this.nonZeroColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = value == 0 ? zeroColor : nonZeroColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  final String label;

  const _SeverityChip({
    required this.icon,
    required this.count,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? ElegantLightTheme.primaryBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeColor : ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : ElegantLightTheme.textTertiary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : ElegantLightTheme.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient? gradient;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    required this.icon,
    this.gradient,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        decoration: BoxDecoration(
          gradient: disabled ? null : gradient,
          color: disabled ? ElegantLightTheme.cardColor : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: disabled ? null : ElegantLightTheme.elevatedShadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: disabled
                          ? ElegantLightTheme.textTertiary
                          : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: disabled
                              ? ElegantLightTheme.textTertiary
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
