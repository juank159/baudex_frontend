// lib/features/diagnostics/presentation/widgets/speed_test_dialog.dart
//
// "Prueba de velocidad de este equipo": corre las mediciones y las muestra
// con semáforo y milisegundos. Se abre desde Diagnóstico y desde la pantalla
// de inicio de sesión (no necesita sesión). El reporte se copia o se guarda
// como texto para enviarlo a soporte.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/core/diagnostics/action_timings.dart';
import '../../../../app/core/diagnostics/speed_test.dart';
import '../../../../app/core/diagnostics/speed_test_probes.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';

Color speedGradeColor(SpeedGrade grade) => switch (grade) {
      SpeedGrade.fast => ElegantLightTheme.successGreen,
      SpeedGrade.slow => ElegantLightTheme.warningOrange,
      SpeedGrade.verySlow => ElegantLightTheme.errorRed,
      SpeedGrade.failed => ElegantLightTheme.errorRed,
      SpeedGrade.skipped => ElegantLightTheme.textTertiary,
    };

IconData speedGradeIcon(SpeedGrade grade) => switch (grade) {
      SpeedGrade.fast => Icons.check_circle,
      SpeedGrade.slow => Icons.warning_amber_rounded,
      SpeedGrade.verySlow => Icons.error,
      SpeedGrade.failed => Icons.cancel,
      SpeedGrade.skipped => Icons.remove_circle_outline,
    };

/// Abre la prueba de velocidad.
Future<void> showSpeedTestDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const SpeedTestDialog(),
    );

class SpeedTestDialog extends StatefulWidget {
  const SpeedTestDialog({
    super.key,
    this.buildRunner,
    this.extraText,
    this.saveFolder,
    this.autoStart = true,
  });

  /// Reemplazable en pruebas e imágenes (por defecto, las mediciones reales).
  final SpeedTestRunner Function()? buildRunner;

  /// Texto que acompaña al reporte (por defecto, los tiempos reales de las
  /// acciones de la app).
  final String Function()? extraText;

  /// Dónde se guarda el archivo de texto (por defecto, Descargas).
  final Future<Directory?> Function()? saveFolder;

  final bool autoStart;

  @override
  State<SpeedTestDialog> createState() => _SpeedTestDialogState();
}

class _SpeedTestDialogState extends State<SpeedTestDialog> {
  late SpeedTestRunner _runner;
  final List<SpeedResult> _results = [];
  SpeedReport? _report;
  bool _running = false;
  String? _notice;
  bool _noticeIsError = false;

  @override
  void initState() {
    super.initState();
    _runner = (widget.buildRunner ?? buildDeviceSpeedTest)();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _runner = (widget.buildRunner ?? buildDeviceSpeedTest)();
      _running = true;
      _results.clear();
      _report = null;
      _notice = null;
    });
    final report = await _runner.run(onResult: (result) {
      if (mounted) setState(() => _results.add(result));
    });
    SpeedTestHistory.last = report;
    if (!mounted) return;
    setState(() {
      _report = report;
      _running = false;
    });
  }

  String _fullText() {
    final report = _report;
    if (report == null) return '';
    final extra = (widget.extraText ?? () => ActionTimings.instance.report())();
    return '${report.toText()}\n$extra';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _fullText()));
    if (!mounted) return;
    setState(() {
      _noticeIsError = false;
      _notice = 'Reporte copiado. Pégalo en el chat o el correo de soporte.';
    });
  }

  Future<void> _save() async {
    try {
      Directory? folder;
      if (widget.saveFolder != null) {
        folder = await widget.saveFolder!();
      } else {
        try {
          folder = await getDownloadsDirectory();
        } catch (_) {}
        folder ??= await getApplicationDocumentsDirectory();
      }
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final name = 'baudex-velocidad-${now.year}${two(now.month)}${two(now.day)}-'
          '${two(now.hour)}${two(now.minute)}.txt';
      final file = File('${folder!.path}${Platform.pathSeparator}$name');
      await file.writeAsString(_fullText());
      if (!mounted) return;
      setState(() {
        _noticeIsError = false;
        _notice = 'Guardado en: ${file.path}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _noticeIsError = true;
        _notice = 'No se pudo guardar el archivo. Usa "Copiar reporte".';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final narrow = size.width < 560;
    final report = _report;
    return Dialog(
      backgroundColor: ElegantLightTheme.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: brebDialogShape,
      insetPadding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 40, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: size.height * 0.9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 4),
              child: brebDialogTitle(Icons.speed, 'Prueba de velocidad de este equipo'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 10),
              child: Text(
                'Mide lo que la app necesita de este computador. No cambia ni '
                'borra ningún dato del negocio.',
                style: TextStyle(color: ElegantLightTheme.textSecondary, fontSize: 13, height: 1.35),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (report != null) _verdict(report),
                    if (_running)
                      BrebInlineLoading(
                        'Midiendo… (${_results.length} de ${_runner.checks.length})',
                      ),
                    const SizedBox(height: 4),
                    for (var i = 0; i < _runner.checks.length; i++)
                      _row(_runner.checks[i], i < _results.length ? _results[i] : null,
                          current: _running && i == _results.length),
                    if (report != null) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'Este equipo',
                        style: TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final (name, value, alert) in report.facts.rows)
                        _fact(name, value, alert),
                    ],
                    if (_notice != null) ...[
                      const SizedBox(height: 12),
                      _noticeIsError
                          ? BrebNotice.error(_notice!)
                          : BrebNotice.success(_notice!),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    style: brebTextButtonStyle(color: ElegantLightTheme.textSecondary),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Cerrar'),
                  ),
                  if (!_running)
                    TextButton.icon(
                      style: brebTextButtonStyle(),
                      onPressed: _run,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Repetir'),
                    ),
                  OutlinedButton.icon(
                    style: brebSecondaryButtonStyle(),
                    onPressed: report == null ? null : _save,
                    icon: const Icon(Icons.save_alt, size: 18),
                    label: const Text('Guardar como texto'),
                  ),
                  ElevatedButton.icon(
                    style: brebPrimaryButtonStyle(),
                    onPressed: report == null ? null : _copy,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Copiar reporte'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verdict(SpeedReport report) {
    final grade = report.overall;
    final color = speedGradeColor(grade);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(speedGradeIcon(grade), color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (grade) {
                    SpeedGrade.fast => 'Equipo rápido',
                    SpeedGrade.slow => 'Equipo lento',
                    _ => 'Equipo muy lento',
                  },
                  style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  report.verdict,
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(SpeedCheck check, SpeedResult? result, {required bool current}) {
    final grade = result?.grade;
    final color = grade == null ? ElegantLightTheme.textTertiary : speedGradeColor(grade);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: current
                ? const Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
                    ),
                  )
                : Icon(
                    grade == null ? Icons.radio_button_unchecked : speedGradeIcon(grade),
                    color: color,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.title,
                  style: const TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  result == null ? (current ? 'Midiendo…' : 'En espera') : result.timeLabel,
                  style: const TextStyle(color: ElegantLightTheme.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (grade != null) ...[
            const SizedBox(width: 8),
            BrebChip(label: grade.label, color: color),
          ],
        ],
      ),
    );
  }

  Widget _fact(String name, String value, bool alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            alert ? Icons.warning_amber_rounded : Icons.circle,
            size: alert ? 15 : 6,
            color: alert ? ElegantLightTheme.warningOrange : ElegantLightTheme.textTertiary,
          ),
          SizedBox(width: alert ? 6 : 15),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
              style: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
