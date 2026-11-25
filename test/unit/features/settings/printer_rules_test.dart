// Reglas puras de impresoras: con cuál factura este equipo, qué hacer
// cuando el servidor falla al eliminar y qué se le dice al cajero.
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart';
import 'package:baudex_desktop/features/settings/domain/rules/printer_rules.dart';
import 'package:flutter_test/flutter_test.dart';

PrinterSettings p(String id, String name, {bool isDefault = false}) =>
    PrinterSettings.usbPrinter(
      id: id,
      name: name,
      usbPath: name,
      isDefault: isDefault,
    );

void main() {
  group('pickBillingPrinter', () {
    test('sin impresoras no hay con qué facturar', () {
      expect(pickBillingPrinter(const []), isNull);
    });

    test('la única impresora sirve aunque no esté marcada', () {
      expect(pickBillingPrinter([p('a', 'POS-80')])?.id, 'a');
    });

    test('la elegida en este equipo gana a la marcada', () {
      final printers = [p('a', 'Caja', isDefault: true), p('b', 'Cocina')];
      expect(pickBillingPrinter(printers, deviceChoiceId: 'b')?.id, 'b');
    });

    test('si la elegida ya no existe, vale la marcada', () {
      final printers = [p('a', 'Caja'), p('b', 'Cocina', isDefault: true)];
      expect(pickBillingPrinter(printers, deviceChoiceId: 'borrada')?.id, 'b');
    });

    test('sin elegida ni marcada: la primera por nombre', () {
      final printers = [p('a', 'cocina'), p('b', 'Caja')];
      expect(pickBillingPrinter(printers)?.id, 'b');
    });
  });

  test('ids del servidor y creados sin internet', () {
    expect(isServerPrinterId('3f2b8c1e-5a7d-4e9b-8c1a-2d3e4f5a6b7c'), isTrue);
    expect(isServerPrinterId('printer_offline_1764000000000'), isFalse);
    expect(isServerPrinterId(''), isFalse);
  });

  test('qué hacer cuando el servidor falla al eliminar', () {
    expect(classifyPrinterDeleteFailure(404), PrinterDeleteOutcome.alreadyGone);
    expect(classifyPrinterDeleteFailure(403), PrinterDeleteOutcome.rejected);
    expect(classifyPrinterDeleteFailure(400), PrinterDeleteOutcome.rejected);
    expect(classifyPrinterDeleteFailure(null), PrinterDeleteOutcome.retryLater);
    expect(classifyPrinterDeleteFailure(500), PrinterDeleteOutcome.retryLater);
    expect(classifyPrinterDeleteFailure(401), PrinterDeleteOutcome.retryLater);
  });

  test('mensajes para el cajero, sin prefijos técnicos', () {
    expect(
      printerDeleteRejectionMessage(403, 'Forbidden resource'),
      contains('No tienes permiso'),
    );
    expect(
      printerDeleteRejectionMessage(400, 'Solicitud incorrecta: id inválido'),
      'El servidor no permitió eliminar la impresora: id inválido',
    );
    expect(
      windowsUsbFailureMessage('POS-80', nativeCode: 1801),
      contains('no está instalada en este equipo'),
    );
    expect(
      windowsUsbFailureMessage('POS-80', nativeCode: 5),
      contains('Revisa que esté encendida'),
    );
  });
}
