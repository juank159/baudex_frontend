// Comprobación en un Windows REAL del envío directo a la cola de impresión
// (lib/app/core/printing/windows_raw_printer.dart). No es una simulación:
// usa el código de la app contra una impresora instalada en Windows.
//
// Solo corre en Windows y solo si se le dice a qué impresora mandar:
//   BAUDEX_PRUEBA_IMPRESORA  nombre de la impresora instalada (obligatoria)
//   BAUDEX_PRUEBA_SALIDA     archivo donde esa impresora deja lo que recibe
//                            (impresora "a archivo" o escucha TCP). Si falta,
//                            no se comparan bytes (p. ej. impresora de papel).
//   BAUDEX_PRUEBA_ENVIOS     cuántos tiquetes seguidos (por defecto 20)
//
//   flutter test test/windows/windows_raw_printer_real_test.dart
@TestOn('windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:baudex_desktop/app/core/printing/windows_powershell_raw_printer.dart';
import 'package:baudex_desktop/app/core/printing/windows_raw_printer.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/thermal_printer_controller.dart';
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart'
    as cfg;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final String printerName =
    Platform.environment['BAUDEX_PRUEBA_IMPRESORA']?.trim() ?? '';
final String outputPath =
    Platform.environment['BAUDEX_PRUEBA_SALIDA']?.trim() ?? '';
final int sends =
    int.tryParse(Platform.environment['BAUDEX_PRUEBA_ENVIOS'] ?? '') ?? 20;

void log(String line) {
  // ignore: avoid_print
  print('IMPRESION-WINDOWS | $line');
}

/// Tiquete de ejemplo de 80 mm: texto con acentos, un bloque de imagen con
/// todos los valores de byte (0 a 255) y corte de papel.
Uint8List sampleTicket(CapabilityProfile profile, int n) {
  final gen = Generator(PaperSize.mm80, profile);
  final out = BytesBuilder();
  out.add([0x1B, 0x40]);
  out.add(gen.text('TIENDA DE PRUEBA',
      styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2)));
  out.add(gen.text('Señor cajero: prueba de impresión número $n'));
  out.add(gen.text('Café, azúcar, jamón, piña, ñame - áéíóú ÁÉÍÓÚ'));
  out.add(gen.hr());
  for (var i = 1; i <= 10; i++) {
    out.add(gen.row([
      PosColumn(text: 'Producto $i', width: 8),
      PosColumn(
          text: '\$${i * 1500}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
  }
  // Imagen raster (GS v 0) de 32 bytes de ancho por 8 puntos de
  // alto: sus datos son los 256 valores posibles de un byte, en orden.
  out.add([0x1D, 0x76, 0x30, 0x00, 32, 0, 8, 0]);
  out.add(List<int>.generate(256, (i) => i));
  out.add(gen.feed(3));
  out.add([0x1D, 0x56, 0x00]);
  return out.toBytes();
}

Future<Uint8List?> readOutput() async {
  try {
    final f = File(outputPath);
    if (!await f.exists()) return null;
    return await f.readAsBytes();
  } catch (_) {
    return null; // la cola de impresión lo está escribiendo
  }
}

bool sameBytes(Uint8List? a, Uint8List b) {
  if (a == null || a.length != b.length) return false;
  for (var i = 0; i < b.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool containsBytes(Uint8List? haystack, List<int> needle) {
  if (haystack == null) return false;
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

/// Borra el archivo de salida para que el siguiente tiquete se compare solo.
Future<void> clearOutput() async {
  if (outputPath.isEmpty) return;
  final f = File(outputPath);
  for (var i = 0; i < 100; i++) {
    try {
      if (await f.exists()) await f.delete();
      return;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
  fail('No se pudo borrar $outputPath (¿la cola de impresión lo tiene tomado?)');
}

/// Espera a que el archivo de salida cumpla [ok] (la cola escribe después de
/// aceptar el trabajo). Devuelve lo último leído.
Future<Uint8List?> waitOutput(bool Function(Uint8List?) ok,
    {Duration timeout = const Duration(seconds: 30)}) async {
  final sw = Stopwatch()..start();
  Uint8List? last;
  while (sw.elapsed < timeout) {
    last = await readOutput();
    if (ok(last)) return last;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  return last;
}

String stats(List<double> ms) {
  final s = [...ms]..sort();
  String f(double v) => v.toStringAsFixed(1);
  return 'normal ${f(s[(s.length - 1) ~/ 2])} ms, mejor ${f(s.first)} ms, '
      'peor ${f(s.last)} ms (${s.length} envíos)';
}

double median(List<double> ms) {
  final s = [...ms]..sort();
  return s[(s.length - 1) ~/ 2];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final skip = printerName.isEmpty
      ? 'Falta BAUDEX_PRUEBA_IMPRESORA (nombre de la impresora de Windows)'
      : null;
  final checkBytes = outputPath.isNotEmpty;

  late CapabilityProfile profile;
  setUpAll(() async {
    profile = await CapabilityProfile.load();
    log('impresora: "$printerName" | salida: '
        '${checkBytes ? outputPath : "(sin archivo: no se comparan bytes)"}'
        ' | envíos: $sends');
  });

  test('envío directo: $sends tiquetes seguidos, bytes idénticos y tiempos',
      () async {
    final direct = <double>[];
    for (var n = 1; n <= sends; n++) {
      final ticket = sampleTicket(profile, n);
      await clearOutput();
      final sw = Stopwatch()..start();
      await sendRawToWindowsPrinter(printerName, ticket);
      direct.add(sw.elapsedMicroseconds / 1000);
      if (checkBytes) {
        final got = await waitOutput((b) => sameBytes(b, ticket));
        expect(sameBytes(got, ticket), isTrue,
            reason: 'Tiquete $n: el archivo tiene ${got?.length ?? 0} bytes y '
                'se enviaron ${ticket.length}; no son idénticos');
      }
    }
    log('DIRECTO (winspool desde la app): ${stats(direct)}');
    if (checkBytes) {
      log('DIRECTO: los $sends tiquetes llegaron con bytes idénticos');
    }

    // Camino viejo sobre la misma impresora, para comparar.
    final old = <double>[];
    final oldSends = sends < 5 ? sends : 5;
    for (var n = 1; n <= oldSends; n++) {
      final ticket = sampleTicket(profile, 1000 + n);
      await clearOutput();
      final sw = Stopwatch()..start();
      final temp = File('${Directory.systemTemp.path}\\baudex_prueba_'
          '${DateTime.now().microsecondsSinceEpoch}.bin');
      await temp.writeAsBytes(ticket);
      final ok = await sendFileViaPowerShell(printerName, temp.path);
      old.add(sw.elapsedMicroseconds / 1000);
      try {
        await temp.delete();
      } catch (_) {}
      expect(ok, isTrue, reason: 'El camino viejo de PowerShell no imprimió');
      if (checkBytes) {
        final got = await waitOutput((b) => sameBytes(b, ticket));
        expect(sameBytes(got, ticket), isTrue,
            reason: 'PowerShell, tiquete $n: bytes distintos a los enviados');
      }
    }
    log('POWERSHELL (camino viejo): ${stats(old)}');
    log('RESULTADO: directo ${median(direct).toStringAsFixed(1)} ms vs '
        'PowerShell ${median(old).toStringAsFixed(1)} ms por tiquete '
        '(${(median(old) / median(direct)).toStringAsFixed(0)} veces más rápido)');

    expect(median(direct), lessThan(median(old)),
        reason: 'El envío directo debería ser más rápido que PowerShell');
    expect(median(direct), lessThan(1000),
        reason: 'El envío directo no debería tardar un segundo por tiquete');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 10)));

  test('la app (controlador real) imprime una factura por el camino directo, '
      'sin caer a PowerShell', () async {
    Get.testMode = true;
    InvoiceEntryMetrics.instance.reset();
    addTearDown(Get.reset);
    final controller = Get.put(ThermalPrinterController());
    final now = DateTime(2026, 11, 24, 10, 30);
    await controller.setTempPrinterConfig(cfg.PrinterSettings(
      id: 'prueba',
      name: 'Prueba',
      connectionType: cfg.PrinterConnectionType.usb,
      usbPath: printerName,
      isDefault: true,
      createdAt: now,
      updatedAt: now,
    ));
    final invoice = Invoice(
      id: 'id-prueba',
      number: 'FV-PRUEBA-WIN',
      date: now,
      dueDate: now,
      status: InvoiceStatus.paid,
      paymentMethod: PaymentMethod.cash,
      subtotal: 5000,
      taxPercentage: 0,
      taxAmount: 0,
      discountPercentage: 0,
      discountAmount: 0,
      total: 5000,
      paidAmount: 5000,
      balanceDue: 0,
      customerId: 'c1',
      createdById: 'u1',
      items: [
        for (var i = 1; i <= 2; i++)
          InvoiceItem(
            id: 'i$i',
            description: 'Producto de prueba $i',
            quantity: 1,
            unitPrice: 2500,
            discountPercentage: 0,
            discountAmount: 0,
            subtotal: 2500,
            invoiceId: 'id-prueba',
            createdAt: now,
            updatedAt: now,
          ),
      ],
      payments: const [],
      createdAt: now,
      updatedAt: now,
    );

    await clearOutput();
    final sw = Stopwatch()..start();
    final ok = await controller.printInvoice(invoice);
    final ms = sw.elapsedMicroseconds / 1000;
    final kinds = InvoiceEntryMetrics.instance.printerKinds;
    log('APP: factura enviada=$ok en ${ms.toStringAsFixed(1)} ms por: $kinds'
        '${ok ? "" : " | error: ${controller.lastError}"}');

    expect(ok, isTrue, reason: controller.lastError);
    // Si el directo fallara, aquí saldría "USB Windows (PowerShell; el
    // directo falló: código N)".
    expect(kinds, ['USB Windows (directo)']);
    if (checkBytes) {
      final marker = 'FV-PRUEBA-WIN'.codeUnits;
      final got = await waitOutput((b) => containsBytes(b, marker));
      expect(containsBytes(got, marker), isTrue,
          reason: 'La factura no llegó al archivo de la impresora');
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

  test('impresora que no existe: falla rápido y con mensaje claro', () async {
    final ticket = sampleTicket(profile, 1);
    final sw = Stopwatch()..start();
    Object? error;
    try {
      await sendRawToWindowsPrinter('Baudex No Existe 12345', ticket);
    } catch (e) {
      error = e;
    }
    final ms = sw.elapsedMicroseconds / 1000;
    log('INEXISTENTE: falló en ${ms.toStringAsFixed(1)} ms con: $error');
    expect(error, isA<WindowsRawPrintException>());
    final e = error! as WindowsRawPrintException;
    expect(e.step, 'abrir la impresora');
    expect(e.code, isNot(0)); // 1801 = nombre de impresora no válido
    expect(e.toString(), contains('abrir la impresora'));
    expect(ms, lessThan(3000));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 1)));
}
