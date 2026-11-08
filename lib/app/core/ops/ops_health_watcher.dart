import 'dart:async';

import 'package:get/get.dart';

import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/diagnostics/domain/system_health_analyzer.dart';
import '../../../features/diagnostics/presentation/controllers/sync_diagnostic_controller.dart';
import 'ops_reporter.dart';

/// Vigilante automático de salud: cada cierto tiempo corre el mismo análisis
/// de la pantalla de Diagnóstico, en segundo plano y sin que el cliente vea
/// nada. Si encuentra problemas críticos o altos (facturas perdidas, productos
/// atascados, operaciones fallidas…), los reporta a la Ops API como
/// incidentes: el equipo recibe el aviso en Telegram automáticamente.
///
/// Cada tipo de problema tiene un fingerprint fijo (`health:<id>`), así la Ops
/// API agrupa el mismo problema de todos los clientes en un solo incidente y
/// avisa cuando aparece, vuelve o se expande a más clientes.
class OpsHealthWatcher extends GetxService {
  static const _firstCheck = Duration(minutes: 3);
  static const _interval = Duration(minutes: 30);
  static const _repeatAfter = Duration(hours: 6);
  static const _tag = 'ops-health-watcher';

  Timer? _timer;
  bool _running = false;
  final Map<String, DateTime> _lastReported = {};

  /// Arranca el vigilante (solo si la central de errores está configurada).
  static void start() {
    if (!OpsReporter.enabled || Get.isRegistered<OpsHealthWatcher>()) return;
    Get.put(OpsHealthWatcher(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    Future.delayed(_firstCheck, () {
      _check();
      _timer = Timer.periodic(_interval, (_) => _check());
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _check() async {
    if (_running) return;
    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (auth == null || !auth.isAuthenticated) return;
    _running = true;
    final ownsController = !Get.isRegistered<SyncDiagnosticController>(tag: _tag);
    try {
      final c = ownsController
          ? Get.put(SyncDiagnosticController(background: true), tag: _tag)
          : Get.find<SyncDiagnosticController>(tag: _tag);
      await c.refreshAll();
      // Sin internet no tiene sentido reportar (ni se podría enviar).
      if (!c.isOnline.value) return;
      _report(c.healthReport.value);
    } catch (e, st) {
      // El propio vigilante nunca debe molestar al usuario.
      OpsReporter.capture(e, st, context: {'kind': 'OpsHealthWatcher'});
    } finally {
      if (ownsController) Get.delete<SyncDiagnosticController>(tag: _tag, force: true);
      _running = false;
    }
  }

  void _report(SystemHealthReport report) {
    final now = DateTime.now();
    for (final issue in report.issues) {
      if (issue.severity != IssueSeverity.critical && issue.severity != IssueSeverity.high) continue;
      final last = _lastReported[issue.id];
      if (last != null && now.difference(last) < _repeatAfter) continue;
      _lastReported[issue.id] = now;
      OpsReporter.capture(
        _HealthIssueError(issue.title),
        null,
        level: issue.severity == IssueSeverity.critical ? 'error' : 'warning',
        route: '/settings/diagnostics',
        errorType: 'HealthIssue',
        fingerprint: 'health:${issue.id}',
        context: {
          'issueId': issue.id,
          'severity': issue.severity.name,
          'affectedCount': issue.affectedCount,
          'explanation': issue.explanation,
          'recommendation': issue.recommendation,
          if (issue.technicalDetail != null) 'technicalDetail': issue.technicalDetail,
          'healthScore': report.healthScore,
          'autoFixAvailable': issue.autoFix != null,
        },
      );
    }
  }
}

class _HealthIssueError implements Exception {
  _HealthIssueError(this.message);
  final String message;
  @override
  String toString() => message;
}
