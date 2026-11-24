// Impresora de red de mentira (un puerto local que guarda lo que recibe)
// para comprobar dos cosas sin papel:
//  1. el tiquete armado en memoria tiene EXACTAMENTE los mismos bytes que
//     el que mandaba `NetworkPrinter` línea por línea;
//  2. el envío nuevo entrega todo sin las pausas fijas del camino viejo.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:baudex_desktop/app/core/printing/buffered_escpos_printer.dart';
import 'package:baudex_desktop/app/core/printing/network_raw_sender.dart';
import 'package:esc_pos_printer_plus/esc_pos_printer_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePrinter {
  FakePrinter._(this._server);
  final ServerSocket _server;
  final List<Uint8List> jobs = [];
  final StreamController<Uint8List> _done = StreamController.broadcast();

  int get port => _server.port;

  static Future<FakePrinter> start() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final printer = FakePrinter._(server);
    server.listen((client) {
      final data = BytesBuilder();
      client.listen(data.add, onDone: () {
        final bytes = data.toBytes();
        printer.jobs.add(bytes);
        printer._done.add(bytes);
        client.destroy();
      }, onError: (_) {});
    });
    return printer;
  }

  Future<Uint8List> nextJob() =>
      _done.stream.first.timeout(const Duration(seconds: 5));

  Future<void> stop() => _server.close();
}

/// Un tiquete parecido al real, hecho con las mismas llamadas.
void drawTicket(NetworkPrinter p) {
  p.rawBytes([0x1B, 0x40, 0x1B, 0x74, 0x10]);
  p.text('TIENDA DE PRUEBA',
      styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2));
  p.text('NIT: 900123456', styles: const PosStyles(align: PosAlign.center));
  p.feed(1);
  p.hr();
  for (var i = 1; i <= 12; i++) {
    p.row([
      PosColumn(text: 'Producto $i', width: 8),
      PosColumn(
          text: '\$${i * 1500}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
  }
  p.hr(ch: '=');
  p.text('TOTAL: \$117.000',
      styles: const PosStyles(align: PosAlign.right, bold: true));
  p.feed(3);
  p.rawBytes([0x1D, 0x56, 0x00]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CapabilityProfile profile;
  late FakePrinter printer;

  setUpAll(() async => profile = await CapabilityProfile.load());
  setUp(() async => printer = await FakePrinter.start());
  tearDown(() => printer.stop());

  test('el tiquete armado en memoria es idéntico al que mandaba NetworkPrinter',
      () async {
    // Camino viejo: conexión abierta, bloque por bloque, pausa y destroy.
    final old = NetworkPrinter(PaperSize.mm80, profile);
    final received = printer.nextJob();
    expect(await old.connect('127.0.0.1', port: printer.port),
        PosPrintResult.success);
    drawTicket(old);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    old.disconnect();
    final oldBytes = await received;

    final buffer = BufferedEscPosPrinter(PaperSize.mm80, profile);
    drawTicket(buffer);

    expect(buffer.bytes, orderedEquals(oldBytes));
    expect(oldBytes.length, greaterThan(300));
  });

  test('mismos bytes también en papel de 58 mm', () async {
    final old = NetworkPrinter(PaperSize.mm58, profile);
    final received = printer.nextJob();
    await old.connect('127.0.0.1', port: printer.port);
    drawTicket(old);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    old.disconnect();

    final buffer = BufferedEscPosPrinter(PaperSize.mm58, profile);
    drawTicket(buffer);
    expect(buffer.bytes, orderedEquals(await received));
  });

  test('el envío nuevo entrega el tiquete completo y sin pausas fijas',
      () async {
    final buffer = BufferedEscPosPrinter(PaperSize.mm80, profile);
    drawTicket(buffer);
    final bytes = buffer.bytes;

    final times = <double>[];
    for (var i = 0; i < 20; i++) {
      final received = printer.nextJob();
      final sw = Stopwatch()..start();
      await sendBytesToNetworkPrinter('127.0.0.1', printer.port, bytes);
      times.add(sw.elapsedMicroseconds / 1000);
      expect(await received, orderedEquals(bytes));
    }
    times.sort();
    // ignore: avoid_print
    print('MEDICIÓN envío nuevo (20 tiquetes): normal '
        '${times[10].toStringAsFixed(1)} ms, peor ${times.last.toStringAsFixed(1)} ms');
    // El camino viejo no podía bajar de 350 ms (50 + 100 + 200 de pausa).
    expect(times[10], lessThan(100));
  });

  test('camino viejo, para comparar: no baja de 350 ms por las pausas',
      () async {
    final received = printer.nextJob();
    final sw = Stopwatch()..start();
    final old = NetworkPrinter(PaperSize.mm80, profile);
    await old.connect('127.0.0.1', port: printer.port);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    drawTicket(old);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    old.disconnect();
    final ms = sw.elapsedMicroseconds / 1000;
    await received;
    // ignore: avoid_print
    print('MEDICIÓN envío viejo (1 tiquete): ${ms.toStringAsFixed(1)} ms');
    expect(ms, greaterThanOrEqualTo(350));
  });

  test('un tiquete grande (logo de 400 KB) llega entero aunque se devuelva ya',
      () async {
    final big = Uint8List.fromList(
        List<int>.generate(400 * 1024, (i) => (i * 31) & 0xFF));
    final received = printer.nextJob();
    await sendBytesToNetworkPrinter('127.0.0.1', printer.port, big);
    final got = await received;
    expect(got.length, big.length);
    expect(got, orderedEquals(big));
  });

  test('impresora apagada: falla con mensaje claro, sin colgarse', () async {
    final port = printer.port;
    await printer.stop();
    final sw = Stopwatch()..start();
    await expectLater(
      sendBytesToNetworkPrinter('127.0.0.1', port, [1, 2, 3],
          connectTimeout: const Duration(seconds: 2)),
      throwsA(isA<NetworkPrinterException>().having(
          (e) => e.message, 'mensaje', contains('127.0.0.1:$port'))),
    );
    expect(sw.elapsedMilliseconds, lessThan(2500));
  });
}
