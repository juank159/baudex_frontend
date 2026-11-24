// El controlador real de impresión contra una impresora de red de mentira
// (un puerto local). Comprueba el camino completo "imprimir → enviado":
// dos facturas seguidas salen las dos (la segunda ya no se rechaza), en
// orden, y la medición queda en el reporte de diagnóstico.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:baudex_desktop/features/invoices/domain/entities/invoice.dart';
import 'package:baudex_desktop/features/invoices/domain/entities/invoice_item.dart';
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/thermal_printer_controller.dart';
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Invoice invoice(String number, {int lines = 8}) {
  final now = DateTime(2026, 11, 24, 10, 30);
  return Invoice(
    id: 'id-$number',
    number: number,
    date: now,
    dueDate: now,
    status: InvoiceStatus.paid,
    paymentMethod: PaymentMethod.cash,
    subtotal: lines * 2500.0,
    taxPercentage: 0,
    taxAmount: 0,
    discountPercentage: 0,
    discountAmount: 0,
    total: lines * 2500.0,
    paidAmount: lines * 2500.0,
    balanceDue: 0,
    customerId: 'c1',
    createdById: 'u1',
    items: [
      for (var i = 1; i <= lines; i++)
        InvoiceItem(
          id: 'i$i',
          description: 'Producto de prueba $i',
          quantity: 1,
          unitPrice: 2500,
          discountPercentage: 0,
          discountAmount: 0,
          subtotal: 2500,
          invoiceId: 'id-$number',
          createdAt: now,
          updatedAt: now,
        ),
    ],
    payments: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ServerSocket server;
  final jobs = <Uint8List>[];
  late StreamController<void> arrived;

  setUp(() async {
    Get.testMode = true;
    InvoiceEntryMetrics.instance.reset();
    jobs.clear();
    arrived = StreamController<void>.broadcast();
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((client) {
      final data = BytesBuilder();
      client.listen(
        data.add,
        onDone: () {
          jobs.add(data.toBytes());
          arrived.add(null);
          client.destroy();
        },
        onError: (_) {},
      );
    });
  });

  tearDown(() async {
    await server.close();
    await arrived.close();
    Get.reset();
  });

  PrinterSettings networkPrinter({bool autoCut = true}) => PrinterSettings(
    id: 'p1',
    name: 'Caja',
    connectionType: PrinterConnectionType.network,
    ipAddress: '127.0.0.1',
    port: server.port,
    autoCut: autoCut,
    isDefault: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Future<void> waitJobs(int n) async {
    while (jobs.length < n) {
      await arrived.stream.first.timeout(const Duration(seconds: 5));
    }
  }

  test(
    'dos facturas seguidas: salen las dos, en orden, sin rechazar ninguna',
    () async {
      final controller = Get.put(ThermalPrinterController());
      await controller.setTempPrinterConfig(networkPrinter());

      final a = controller.printInvoice(invoice('FV-0001'));
      final b = controller.printInvoice(invoice('FV-0002'));
      expect(controller.isPrinting, isTrue);

      expect(await a, isTrue);
      expect(await b, isTrue);
      expect(controller.isPrinting, isFalse);
      await waitJobs(2);

      expect(String.fromCharCodes(jobs[0]), contains('FV-0001'));
      expect(String.fromCharCodes(jobs[1]), contains('FV-0002'));
      // Termina con el corte de papel, como antes.
      final cut = SATQ22UEConfig.cutCommands;
      expect(jobs[0].sublist(jobs[0].length - cut.length), cut);
    },
  );

  test('medición: imprimir → enviado queda en el reporte, por tipo', () async {
    final controller = Get.put(ThermalPrinterController());
    await controller.setTempPrinterConfig(networkPrinter());

    // El primero paga la carga del perfil de la impresora; se mide aparte.
    await controller.printInvoice(invoice('FV-0000'));
    final times = <double>[];
    for (var i = 1; i <= 20; i++) {
      final sw = Stopwatch()..start();
      expect(
        await controller.printInvoice(invoice('FV-00$i', lines: 15)),
        isTrue,
      );
      times.add(sw.elapsedMicroseconds / 1000);
    }
    await waitJobs(21);
    times.sort();
    // ignore: avoid_print
    print(
      'MEDICIÓN controlador real, red local, 15 líneas (20 tiquetes): '
      'normal ${times[10].toStringAsFixed(1)} ms, '
      'peor ${times.last.toStringAsFixed(1)} ms',
    );
    // Antes: mínimo 350 ms de pausas fijas por tiquete.
    expect(times[10], lessThan(150));

    final m = InvoiceEntryMetrics.instance;
    expect(m.printerKinds, ['Red']);
    expect(m.printSummary('Red')!.count, 21);
    expect(m.printFailures('Red'), 0);
    // ignore: avoid_print
    print(m.report().split('\n').where((l) => l.contains('Red')).join('\n'));
  });

  test('sin corte automático no se manda el corte', () async {
    final controller = Get.put(ThermalPrinterController());
    await controller.setTempPrinterConfig(networkPrinter(autoCut: false));
    expect(await controller.printInvoice(invoice('FV-0003')), isTrue);
    await waitJobs(1);
    final cut = SATQ22UEConfig.cutCommands;
    expect(jobs[0].sublist(jobs[0].length - cut.length), isNot(cut));
  });
}
