// lib/features/diagnostics/domain/system_health_analyzer.dart
//
// Cerebro del diagnóstico. Recibe el estado actual del sistema (datos crudos)
// y produce un [SystemHealthReport] con issues en lenguaje natural.
//
// Para agregar una nueva verificación en el futuro:
//   1. Agrega un método privado _checkXxx()
//   2. Llámalo en analyze()
//   Nada más. El score y el orden se calculan automáticamente.

import '../presentation/controllers/sync_diagnostic_controller.dart';
import '../../../../app/data/local/sync_event_log.dart';

// =====================================================================
// MODELS
// =====================================================================

/// Severidad de un issue. El orden de los valores determina la prioridad
/// visual en la UI (critical primero).
enum IssueSeverity {
  critical, // Integridad de datos en riesgo — acción requerida ya
  high,     // Funcionalidad afectada, puede perder datos si no se atiende
  medium,   // Experiencia degradada, los datos son correctos pero desactualizados
  low,      // Mejora recomendada, no urgente
  info,     // Todo funciona, mensaje informativo
}

/// Un problema detectado en el sistema, descrito en lenguaje natural.
class SystemIssue {
  /// ID único para deduplicar issues entre refreshes.
  final String id;

  final IssueSeverity severity;

  /// Título corto y claro — lo que ve el usuario primero.
  /// Ejemplo: "5 productos con stock congelado"
  final String title;

  /// Por qué este problema importa, en lenguaje de negocio.
  /// Ejemplo: "Tus vendedores pueden estar viendo cantidades incorrectas..."
  final String explanation;

  /// Qué hacer para resolverlo (si hay auto-fix disponible, completa esto).
  final String recommendation;

  /// Descripción técnica para soporte / desarrollador. Opcional.
  final String? technicalDetail;

  /// Texto del botón de acción. null = no hay auto-fix.
  final String? autoFixLabel;

  /// Acción que resuelve el issue automáticamente. null = solo informativo.
  final Future<void> Function()? autoFix;

  /// Cuántos registros/entidades están afectados.
  final int affectedCount;

  final DateTime detectedAt;

  const SystemIssue({
    required this.id,
    required this.severity,
    required this.title,
    required this.explanation,
    required this.recommendation,
    this.technicalDetail,
    this.autoFixLabel,
    this.autoFix,
    required this.affectedCount,
    required this.detectedAt,
  });

  bool get hasAutoFix => autoFix != null;

  /// True si este issue puede resolverse sin confirmación del usuario.
  bool get isSafeAutoFix => severity != IssueSeverity.critical || id == 'stuck_products';
}

/// Resultado completo del análisis del sistema.
class SystemHealthReport {
  /// Puntuación 0-100. 100 = perfecto, <50 = crítico.
  final int healthScore;

  /// Etiqueta legible del score.
  final String healthLabel;

  /// Lista de issues ordenada por severidad (crítico primero).
  final List<SystemIssue> issues;

  final DateTime generatedAt;

  const SystemHealthReport({
    required this.healthScore,
    required this.healthLabel,
    required this.issues,
    required this.generatedAt,
  });

  static final empty = SystemHealthReport(
    healthScore: 100,
    healthLabel: 'Calculando...',
    issues: const [],
    generatedAt: DateTime(2000),
  );

  int get criticalCount =>
      issues.where((i) => i.severity == IssueSeverity.critical).length;
  int get highCount =>
      issues.where((i) => i.severity == IssueSeverity.high).length;
  int get mediumCount =>
      issues.where((i) => i.severity == IssueSeverity.medium).length;

  bool get isHealthy => criticalCount == 0 && highCount == 0;
  bool get hasIssues => issues.isNotEmpty;

  List<SystemIssue> get autoFixableIssues =>
      issues.where((i) => i.hasAutoFix).toList();

  List<SystemIssue> get safeAutoFixIssues =>
      issues.where((i) => i.hasAutoFix && i.isSafeAutoFix).toList();
}

// =====================================================================
// ANALYZER
// =====================================================================

/// Evalúa el estado del sistema y produce un [SystemHealthReport].
///
/// Esta clase es pura (sin estado, sin dependencias de UI) para que sea
/// fácil de testear y extender.
class SystemHealthAnalyzer {
  const SystemHealthAnalyzer._();

  /// Corre todos los chequeos y devuelve el reporte.
  ///
  /// [onHealStuckProducts], [onRequeueOrphans], [onRetryFailed],
  /// [onForceSync] son callbacks de acción inyectados por el controller.
  static SystemHealthReport analyze({
    required bool isOnline,
    bool isSyncInProgress = false,
    required List<StuckProduct> stuckProducts,
    required List<OrphanedRecord> orphanedRecords,
    required PendingOpsBreakdown pendingBreakdown,
    required List<EntityCount> entityCounts,
    required DateTime? lastFullSyncAt,
    required List<IsarSyncEventLog> recentEvents,
    // Callbacks de auto-fix inyectados por el controller
    Future<void> Function()? onHealStuckProducts,
    Future<void> Function()? onRequeueOrphans,
    Future<void> Function()? onRetryFailed,
    Future<void> Function()? onForceSync,
  }) {
    final issues = <SystemIssue>[];
    final now = DateTime.now();

    // --- Chequeo 1: Productos con stock congelado -----------------------
    if (stuckProducts.isNotEmpty) {
      final n = stuckProducts.length;
      final sample =
          stuckProducts.take(3).map((p) => p.name).join(', ');
      final extra = n > 3 ? ' y ${n - 3} más' : '';
      issues.add(SystemIssue(
        id: 'stuck_products',
        severity: IssueSeverity.critical,
        title: '$n producto${n == 1 ? '' : 's'} con stock congelado',
        explanation:
            'Cuando se registra una venta sin internet, el sistema protege '
            'el stock de esos productos para no pisarlo con datos del servidor. '
            'En ${n == 1 ? 'este producto, esa protección' : 'estos productos, esa protección'} '
            'no se eliminó al terminar de sincronizar. '
            'El resultado: los vendedores ven cantidades que ya no son correctas.',
        recommendation:
            'Usa "Sanar ahora" para liberar la protección. El sistema '
            'descargará los stocks reales del servidor inmediatamente.',
        technicalDetail:
            'isSynced=false sin ops de stock activas en SyncQueue. '
            'Afectados: $sample$extra.',
        autoFixLabel: 'Sanar ahora',
        autoFix: onHealStuckProducts,
        affectedCount: n,
        detectedAt: now,
      ));
    }

    // --- Chequeo 2: Facturas offline sin recuperar ----------------------
    final lostInvoices = orphanedRecords
        .where((o) => o.entityType == 'Invoice' && !o.canAutoRequeue)
        .toList();
    if (lostInvoices.isNotEmpty) {
      final n = lostInvoices.length;
      issues.add(SystemIssue(
        id: 'lost_invoices',
        severity: IssueSeverity.critical,
        title: '$n factura${n == 1 ? '' : 's'} offline sin poder recuperar',
        explanation:
            '${n == 1 ? 'Una factura fue' : '$n facturas fueron'} creadas sin '
            'internet pero el sistema no puede reconstruir su información completa '
            'para enviarla al servidor. Estas ventas existen localmente pero '
            'el servidor no las conoce — clientes, reportes e inventario del '
            'servidor no las incluyen.',
        recommendation:
            'Revisa la sección de "Registros huérfanos". Si las facturas '
            'son importantes, comunícate con soporte para recuperación manual.',
        technicalDetail:
            'Facturas con id temporal sin SyncOperation activa: '
            '${lostInvoices.take(5).map((o) => o.label).join(", ")}.',
        autoFixLabel: null,
        autoFix: null,
        affectedCount: n,
        detectedAt: now,
      ));
    }

    // --- Chequeo 3: Registros offline recuperables ---------------------
    final recoverableOrphans =
        orphanedRecords.where((o) => o.canAutoRequeue).toList();
    if (recoverableOrphans.isNotEmpty) {
      final n = recoverableOrphans.length;
      final byType = <String, int>{};
      for (final o in recoverableOrphans) {
        byType[o.entityType] = (byType[o.entityType] ?? 0) + 1;
      }
      final typeSummary = byType.entries
          .map((e) => '${e.value} ${_entityLabel(e.key)}')
          .join(', ');
      issues.add(SystemIssue(
        id: 'recoverable_orphans',
        severity: IssueSeverity.high,
        title:
            '$n registro${n == 1 ? '' : 's'} offline esperando recuperación',
        explanation:
            '${n == 1 ? 'Un registro fue creado' : '$n registros fueron creados'} '
            'sin internet ($typeSummary) y perdieron su operación de envío. '
            'Todavía se pueden recuperar automáticamente y enviar al servidor.',
        recommendation:
            'Usa "Reencolar todo" para volver a programar su envío. '
            'El sistema los subirá en cuanto haya conexión.',
        technicalDetail:
            'Registros con id temporal sin SyncOperation activa: $typeSummary.',
        autoFixLabel: 'Reencolar todo',
        autoFix: onRequeueOrphans,
        affectedCount: n,
        detectedAt: now,
      ));
    }

    // --- Chequeo 4: Operaciones que fallaron muchas veces ---------------
    if (pendingBreakdown.failed > 3) {
      final n = pendingBreakdown.failed;
      final topTypes = pendingBreakdown.byEntityType.entries
          .where((e) => e.value > 0)
          .take(3)
          .map((e) => '${e.key} (${e.value})')
          .join(', ');
      issues.add(SystemIssue(
        id: 'failed_ops',
        severity: IssueSeverity.high,
        title: '$n operacion${n == 1 ? '' : 'es'} fallaron repetidamente',
        explanation:
            'El sistema intentó enviar $n cambios al servidor varias veces '
            'y no lo logró. Esto puede ocurrir por datos inválidos, '
            'un registro relacionado que aún no existe en el servidor, '
            'o un error temporal de red.',
        recommendation:
            'Prueba "Reintentar todas" si la red está estable. '
            'Si siguen fallando, usa "Limpiar fallidas" para eliminarlas.',
        technicalDetail: topTypes.isNotEmpty
            ? 'Tipos con más fallas: $topTypes.'
            : null,
        autoFixLabel: 'Reintentar todas',
        autoFix: onRetryFailed,
        affectedCount: n,
        detectedAt: now,
      ));
    }

    // --- Chequeo 5: Datos desactualizados (sin sync reciente) ----------
    if (lastFullSyncAt != null) {
      final diff = now.difference(lastFullSyncAt);
      if (diff.inHours > 24 && isOnline) {
        final label = diff.inDays >= 2
            ? '${diff.inDays} días'
            : '${diff.inHours} horas';
        issues.add(SystemIssue(
          id: 'stale_data',
          severity: IssueSeverity.medium,
          title: 'Datos sin actualizar desde hace $label',
          explanation:
              'La última vez que se descargó todo del servidor fue hace $label. '
              'Cambios recientes de otros usuarios, ajustes de inventario o '
              'nuevos productos pueden no estar visibles aquí todavía.',
          recommendation:
              'Toca "Sincronizar ahora" para traer todos los datos '
              'actualizados del servidor en este momento.',
          autoFixLabel: 'Sincronizar ahora',
          autoFix: onForceSync,
          affectedCount: 0,
          detectedAt: now,
        ));
      }
    } else if (isOnline && !isSyncInProgress) {
      // Solo mostrar "nunca sincronizado" si realmente no hay datos locales.
      // Si ISAR ya tiene registros (productos, clientes, facturas…) es prueba
      // suficiente de que ocurrió al menos una sincronización, aunque
      // `lastFullSyncAt` sea null en memoria (se resetea en cada reinicio de app).
      // Mostrar el issue con datos presentes sería un falso positivo permanente
      // que confunde al usuario y hace que presionar "Resolver" no cambie nada.
      final totalLocalData =
          entityCounts.fold<int>(0, (sum, ec) => sum + ec.total);
      if (totalLocalData < 5) {
        issues.add(SystemIssue(
          id: 'never_synced',
          severity: IssueSeverity.medium,
          title: 'Primera sincronización pendiente',
          explanation:
              'No hay datos descargados del servidor todavía. Esto ocurre la '
              'primera vez que se usa la app o después de reinstalarla. '
              'Sin datos locales los vendedores no pueden crear facturas ni '
              'consultar productos.',
          recommendation:
              'Conecta el dispositivo a internet y toca "Sincronizar ahora" '
              'para descargar todos los datos del servidor.',
          autoFixLabel: 'Sincronizar ahora',
          autoFix: onForceSync,
          affectedCount: 0,
          detectedAt: now,
        ));
      }
    }

    // --- Chequeo 6: Cola muy grande -----------------------------------
    if (pendingBreakdown.pending > 50) {
      final n = pendingBreakdown.pending;
      issues.add(SystemIssue(
        id: 'large_queue',
        severity: IssueSeverity.medium,
        title: 'Cola de envío muy grande ($n operaciones)',
        explanation:
            'Hay $n cambios esperando para enviarse al servidor. '
            'Esto es normal después de trabajar offline mucho tiempo, '
            'pero si hay internet activo puede indicar que el proceso '
            'de sincronización está pausado.',
        recommendation: isOnline
            ? 'El sistema debería procesar la cola automáticamente. '
              'Si no avanza, fuerza una sincronización manual.'
            : 'Se procesará automáticamente cuando haya conexión.',
        autoFixLabel: isOnline ? 'Forzar procesamiento' : null,
        autoFix: isOnline ? onForceSync : null,
        affectedCount: n,
        detectedAt: now,
      ));
    }

    // --- Chequeo 7: Errores recientes en el log ----------------------
    final recentCriticalErrors = recentEvents
        .where((e) =>
            e.severity == SyncEventSeverity.error &&
            now.difference(e.timestamp).inHours < 2)
        .length;
    if (recentCriticalErrors > 10) {
      issues.add(SystemIssue(
        id: 'frequent_errors',
        severity: IssueSeverity.medium,
        title: 'Muchos errores de sync en las últimas 2 horas',
        explanation:
            'Se registraron $recentCriticalErrors errores de sincronización '
            'en las últimas 2 horas. Esto puede indicar un problema de '
            'conectividad intermitente o un error en el servidor.',
        recommendation:
            'Revisa la sección de "Eventos recientes" para ver el detalle. '
            'Si el error persiste, comunícate con soporte.',
        technicalDetail: '$recentCriticalErrors errores en log (últimas 2h).',
        autoFixLabel: null,
        autoFix: null,
        affectedCount: recentCriticalErrors,
        detectedAt: now,
      ));
    }

    // --- Chequeo 8: Offline sin datos locales --------------------------
    if (!isOnline) {
      final productsTotal = entityCounts
          .firstWhere((e) => e.name == 'product',
              orElse: () => const EntityCount(
                  name: '', label: '', total: 0, unsynced: 0, offline: 0))
          .total;
      if (productsTotal == 0) {
        issues.add(SystemIssue(
          id: 'offline_no_data',
          severity: IssueSeverity.high,
          title: 'Sin internet y sin datos locales de productos',
          explanation:
              'El dispositivo está offline y no hay productos en el '
              'almacenamiento local. Los vendedores no pueden crear facturas '
              'hasta que haya conexión para descargar los datos del servidor.',
          recommendation:
              'Conecta el dispositivo a internet para que el sistema '
              'descargue los datos necesarios para trabajar offline.',
          autoFixLabel: null,
          autoFix: null,
          affectedCount: 0,
          detectedAt: now,
        ));
      }
    }

    // --- Calcular score ----------------------------------------------
    int score = 100;
    for (final issue in issues) {
      switch (issue.severity) {
        case IssueSeverity.critical:
          score -= 30;
          break;
        case IssueSeverity.high:
          score -= 15;
          break;
        case IssueSeverity.medium:
          score -= 8;
          break;
        case IssueSeverity.low:
          score -= 3;
          break;
        case IssueSeverity.info:
          break;
      }
    }
    score = score.clamp(0, 100);

    String healthLabel;
    if (score >= 95) {
      healthLabel = 'Excelente';
    } else if (score >= 80) {
      healthLabel = 'Estable';
    } else if (score >= 60) {
      healthLabel = 'Con advertencias';
    } else if (score >= 30) {
      healthLabel = 'Problemas detectados';
    } else {
      healthLabel = 'Crítico';
    }

    // Ordenar: crítico primero
    issues.sort((a, b) => a.severity.index.compareTo(b.severity.index));

    return SystemHealthReport(
      healthScore: score,
      healthLabel: healthLabel,
      issues: issues,
      generatedAt: now,
    );
  }

  static String _entityLabel(String entityType) {
    const map = {
      'Customer': 'clientes',
      'Product': 'productos',
      'Invoice': 'facturas',
      'Category': 'categorías',
      'Supplier': 'proveedores',
      'Expense': 'gastos',
      'BankAccount': 'cuentas bancarias',
      'CustomerCredit': 'créditos',
      'PurchaseOrder': 'órdenes de compra',
      'CreditNote': 'notas de crédito',
    };
    return map[entityType] ?? entityType.toLowerCase();
  }
}
