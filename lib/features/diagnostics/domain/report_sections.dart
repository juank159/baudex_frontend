// lib/features/diagnostics/domain/report_sections.dart
//
// Reporte de diagnóstico por secciones. Sin Flutter ni GetX: se prueba solo.

/// Una sección del reporte: su nombre y quien la escribe.
typedef ReportSection = (String name, void Function(StringBuffer out) write);

/// Arma el reporte sección por sección. Si una sección falla, el reporte NO
/// se pierde: queda lo que esa sección alcanzó a escribir, una línea
/// `Sección "X" no disponible: <error>` y todas las demás secciones.
String buildSectionedReport(Iterable<ReportSection> sections) {
  final report = StringBuffer();
  for (final (name, write) in sections) {
    final part = StringBuffer();
    try {
      write(part);
      report.write(part);
    } catch (e) {
      report.write(part);
      if (part.isNotEmpty && !part.toString().endsWith('\n')) report.writeln();
      report.writeln('Sección "$name" no disponible: ${_oneLine(e)}');
    }
  }
  return report.toString();
}

String _oneLine(Object error) {
  String text;
  try {
    text = '$error';
  } catch (_) {
    text = error.runtimeType.toString();
  }
  text = text.split('\n').first.trim();
  return text.length > 300 ? '${text.substring(0, 300)}…' : text;
}
