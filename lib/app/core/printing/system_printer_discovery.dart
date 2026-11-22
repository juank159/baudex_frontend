// lib/app/core/printing/system_printer_discovery.dart
import 'dart:io';

import 'package:printing/printing.dart';

/// Una forma de pedirle al sistema operativo la lista de impresoras.
///
/// Devuelve los nombres tal como los conoce el sistema. Si la forma no está
/// disponible en este equipo (por ejemplo `wmic` en Windows 11 24H2) lanza
/// una excepción y el buscador pasa a la siguiente.
class PrinterSource {
  final String name;
  final Future<List<String>> Function() list;

  const PrinterSource(this.name, this.list);
}

/// Resultado de buscar impresoras.
class PrinterDiscoveryResult {
  final List<String> printers;

  /// Fuente que respondió (null si ninguna respondió).
  final String? source;

  /// Errores de las fuentes que fallaron, para el registro técnico.
  /// Nunca se muestran tal cual al cajero.
  final List<String> errors;

  const PrinterDiscoveryResult({
    required this.printers,
    this.source,
    this.errors = const [],
  });

  bool get isEmpty => printers.isEmpty;

  /// Mensaje en español para mostrar cuando no hay impresoras.
  String get emptyMessage => source == null
      ? 'No pudimos revisar las impresoras de este equipo. Revisa que la '
          'impresora esté instalada en el sistema e inténtalo de nuevo.'
      : 'No encontramos impresoras instaladas en este equipo. Conecta e '
          'instala la impresora y vuelve a buscar.';
}

/// Busca impresoras probando las fuentes en orden. La primera que responda
/// con al menos una impresora gana; si todas responden vacías, el resultado
/// es vacío (sin error). Los nombres se limpian y se quitan repetidos.
Future<PrinterDiscoveryResult> discoverPrinters(
  List<PrinterSource> sources,
) async {
  final errors = <String>[];
  String? answered;
  for (final source in sources) {
    try {
      final names = cleanPrinterNames(await source.list());
      answered ??= source.name;
      if (names.isNotEmpty) {
        return PrinterDiscoveryResult(
          printers: names,
          source: source.name,
          errors: errors,
        );
      }
    } catch (e) {
      errors.add('${source.name}: $e');
    }
  }
  return PrinterDiscoveryResult(
    printers: const [],
    source: answered,
    errors: errors,
  );
}

/// Quita espacios, vacíos y repetidos (sin importar mayúsculas), y conserva
/// el orden.
List<String> cleanPrinterNames(Iterable<String> raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final r in raw) {
    final name = r.trim();
    if (name.isEmpty) continue;
    if (seen.add(name.toLowerCase())) out.add(name);
  }
  return out;
}

/// Lee la salida de `Get-Printer | Select -Expand Name` (un nombre por línea).
List<String> parseLinePerPrinter(String stdout) =>
    cleanPrinterNames(stdout.split(RegExp(r'\r?\n')));

/// Lee la salida de `wmic printer get name /format:list` (`Name=...`).
List<String> parseWmicList(String stdout) => cleanPrinterNames(
      stdout
          .split(RegExp(r'\r?\n'))
          .map((l) => l.trim())
          .where((l) => l.startsWith('Name='))
          .map((l) => l.substring(5)),
    );

/// Lee la salida de `lpstat -a` (`nombre accepting requests since ...`).
List<String> parseLpstat(String stdout) => cleanPrinterNames(
      stdout.split(RegExp(r'\r?\n')).map((l) => l.trim().split(' ').first),
    );

Future<String> _run(String exe, List<String> args) async {
  final r = await Process.run(exe, args)
      .timeout(const Duration(seconds: 8));
  if (r.exitCode != 0) {
    throw ProcessException(exe, args, r.stderr.toString().trim(), r.exitCode);
  }
  return r.stdout.toString();
}

/// API nativa del paquete `printing` (en Windows usa EnumPrinters, no
/// depende de ningún comando).
final PrinterSource nativePrinterSource = PrinterSource(
  'printing',
  () async => (await Printing.listPrinters()).map((p) => p.name).toList(),
);

final PrinterSource powershellPrinterSource = PrinterSource(
  'powershell',
  () async => parseLinePerPrinter(await _run('powershell', [
        '-NoProfile',
        '-Command',
        'Get-Printer | Select-Object -ExpandProperty Name',
      ])),
);

/// Último intento: `wmic` ya no existe en Windows 11 24H2.
final PrinterSource wmicPrinterSource = PrinterSource(
  'wmic',
  () async => parseWmicList(
      await _run('wmic', ['printer', 'get', 'name', '/format:list'])),
);

final PrinterSource lpstatPrinterSource = PrinterSource(
  'lpstat',
  () async => parseLpstat(await _run('lpstat', ['-a'])),
);

/// Fuentes del sistema en orden de preferencia para esta plataforma.
List<PrinterSource> defaultPrinterSources() {
  if (Platform.isWindows) {
    return [nativePrinterSource, powershellPrinterSource, wmicPrinterSource];
  }
  if (Platform.isMacOS || Platform.isLinux) {
    return [nativePrinterSource, lpstatPrinterSource];
  }
  return [nativePrinterSource];
}

/// ¿Existe una impresora con ese nombre? (sin importar mayúsculas)
bool containsPrinter(List<String> printers, String name) {
  final target = name.trim().toLowerCase();
  return printers.any((p) => p.toLowerCase() == target);
}
