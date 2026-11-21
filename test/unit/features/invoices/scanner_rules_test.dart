import 'package:baudex_desktop/features/invoices/presentation/widgets/invoice_shortcut_keys.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/scan_code_cache.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/scanner_focus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/product_fixtures.dart';

void main() {
  group('foco del lector', () {
    final own = FocusNode();
    final other = FocusNode();
    final scope = FocusScopeNode();

    test('nadie, la propia caja o el ámbito: se recupera', () {
      expect(scannerFocusIsFree(null, own: [own]), isTrue);
      expect(scannerFocusIsFree(own, own: [own]), isTrue);
      // Antes: el foco caía al ámbito al reconstruirse y no se recuperaba.
      expect(scannerFocusIsFree(scope, own: [own]), isTrue);
    });

    test('otro campo lo tiene: se respeta', () {
      expect(scannerFocusIsFree(other, own: [own]), isFalse);
    });
  });

  group('Ctrl + tecla en la factura', () {
    test('suma uno con =, + (español) y + del teclado numérico', () {
      expect(quantityShortcutDelta(LogicalKeyboardKey.equal), 1);
      expect(quantityShortcutDelta(LogicalKeyboardKey.add), 1);
      expect(quantityShortcutDelta(LogicalKeyboardKey.numpadAdd), 1);
      expect(quantityShortcutDelta(LogicalKeyboardKey.bracketRight, character: '+'), 1);
    });

    test('resta uno con - y - del teclado numérico', () {
      expect(quantityShortcutDelta(LogicalKeyboardKey.minus), -1);
      expect(quantityShortcutDelta(LogicalKeyboardKey.numpadSubtract), -1);
    });

    test('otras teclas no', () {
      expect(quantityShortcutDelta(LogicalKeyboardKey.keyA), isNull);
      expect(quantityShortcutDelta(LogicalKeyboardKey.digit5), isNull);
    });
  });

  group('códigos ya escaneados', () {
    test('re-escaneo de un producto en la factura: sin ir a la base', () {
      final cache = ScanCodeCache();
      final p = ProductFixtures.createProductEntity(id: 'p1');
      cache.remember('7701234567890', p);
      expect(cache.lookup('7701234567890', isInInvoice: (id) => id == 'p1'), p);
    });

    test('si se quitó de la factura se vuelve a buscar (precio y existencia al día)', () {
      final cache = ScanCodeCache();
      cache.remember('7701234567890', ProductFixtures.createProductEntity(id: 'p1'));
      expect(cache.lookup('7701234567890', isInInvoice: (_) => false), isNull);
      expect(cache.length, 0);
    });

    test('tamaño acotado', () {
      final cache = ScanCodeCache(maxEntries: 3);
      for (var i = 0; i < 10; i++) {
        cache.remember('code$i', ProductFixtures.createProductEntity(id: 'p$i'));
      }
      expect(cache.length, 3);
      expect(cache.lookup('code9', isInInvoice: (_) => true), isNotNull);
      expect(cache.lookup('code0', isInInvoice: (_) => true), isNull);
    });
  });
}
