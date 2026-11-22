// Buscar impresoras sin depender de `wmic` (ya no viene en Windows 11 24H2).
import 'dart:io';

import 'package:baudex_desktop/app/core/printing/system_printer_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

PrinterSource ok(String name, List<String> printers) =>
    PrinterSource(name, () async => printers);
PrinterSource fails(String name) => PrinterSource(
    name,
    () async => throw ProcessException(
        name, const [], 'El sistema no puede encontrar el archivo especificado.', 2));

void main() {
  test('la primera fuente con impresoras gana', () async {
    final r = await discoverPrinters([
      ok('printing', ['EPSON TM-T20', 'Microsoft Print to PDF']),
      ok('powershell', ['otra']),
    ]);
    expect(r.printers, ['EPSON TM-T20', 'Microsoft Print to PDF']);
    expect(r.source, 'printing');
  });

  test('si la API falla se usa PowerShell; wmic queda de último', () async {
    var wmicCalled = false;
    final r = await discoverPrinters([
      fails('printing'),
      ok('powershell', ['POS-80']),
      PrinterSource('wmic', () async {
        wmicCalled = true;
        return ['x'];
      }),
    ]);
    expect(r.printers, ['POS-80']);
    expect(r.source, 'powershell');
    expect(wmicCalled, isFalse);
    expect(r.errors.single, startsWith('printing:'));
  });

  test('wmic ausente (24H2) no rompe: mensaje claro en español', () async {
    final r = await discoverPrinters([fails('printing'), fails('powershell'), fails('wmic')]);
    expect(r.isEmpty, isTrue);
    expect(r.source, isNull);
    expect(r.errors, hasLength(3));
    expect(r.emptyMessage, isNot(contains('ProcessException')));
    expect(r.emptyMessage, contains('Revisa'));
  });

  test('sin impresoras instaladas: mensaje para instalar una', () async {
    final r = await discoverPrinters([ok('printing', []), ok('powershell', ['  '])]);
    expect(r.isEmpty, isTrue);
    expect(r.source, 'printing');
    expect(r.emptyMessage, contains('Conecta e instala'));
  });

  test('limpia espacios, vacíos y repetidos', () {
    expect(cleanPrinterNames([' A ', '', 'a', 'B']), ['A', 'B']);
  });

  test('lee la salida de PowerShell, wmic y lpstat', () {
    expect(parseLinePerPrinter('EPSON TM-T20\r\nPOS-80\r\n\r\n'), ['EPSON TM-T20', 'POS-80']);
    expect(parseWmicList('\r\n\r\nName=EPSON TM-T20\r\n\r\nName=POS-80\r\n'), ['EPSON TM-T20', 'POS-80']);
    expect(parseLpstat('EPSON_TM accepting requests since Lun\nPOS80 accepting\n'), ['EPSON_TM', 'POS80']);
  });

  test('containsPrinter no distingue mayúsculas', () {
    expect(containsPrinter(['EPSON TM-T20'], 'epson tm-t20 '), isTrue);
    expect(containsPrinter(['EPSON TM-T20'], 'POS-80'), isFalse);
  });

  test('en Windows el orden es API, PowerShell, wmic', () {
    final names = defaultPrinterSources().map((s) => s.name).toList();
    if (Platform.isWindows) {
      expect(names, ['printing', 'powershell', 'wmic']);
    } else {
      expect(names.first, 'printing');
      expect(names, isNot(contains('wmic')));
    }
  });
}
