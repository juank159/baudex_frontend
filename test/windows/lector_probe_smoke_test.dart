// Comprueba que la sonda del lector (tool/probes/lector_probe.dart) corre de
// punta a punta, con teclas simuladas y tiempo real. En Windows de verdad
// la sonda se compila como app (tool/probes/lector_windows_probe.dart) y
// las teclas las manda el sistema.
//
//   flutter test test/windows/lector_probe_smoke_test.dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../tool/probes/lector_probe.dart';
import '../helpers/isar_test_lib.dart';

class _SimulatedKeys implements KeyInjector {
  _SimulatedKeys(this.tester);
  final WidgetTester tester;

  @override
  String get name => 'simuladas (prueba)';

  @override
  Future<String?> prepare() async => null;

  void _setText(String text) {
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ));
  }

  // Como en Windows: la tecla llega primero a la app; solo si no la
  // consume, el sistema la escribe en la caja.
  @override
  Future<void> type(String digits, {required int gapMs, bool enter = true}) async {
    final field = tester.widget<EditableText>(find.byType(EditableText).first);
    for (final ch in digits.split('')) {
      final key = LogicalKeyboardKey(0x30 + int.parse(ch));
      final consumed = await simulateKeyDownEvent(key, character: ch);
      if (!consumed) _setText(field.controller.text + ch);
      await simulateKeyUpEvent(key);
      if (gapMs > 0) await Future<void>.delayed(Duration(milliseconds: gapMs));
    }
    if (enter) {
      final consumed = await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      if (!consumed) {
        await tester.testTextInput.receiveAction(TextInputAction.done);
      }
      await simulateKeyUpEvent(LogicalKeyboardKey.enter);
    }
  }

  @override
  Future<void> backspace(int count) async => _setText('');
}

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  for (final (name, config) in const [
    // Las teclas simuladas son lentas (un cuadro cada una): sin tope de
    // tiempo aquí; el tope real se revisa en Windows.
    (
      'normal',
      LectorProbeConfig(
          products: 500, scans: 2, label: 'humo', maxTextMs: 100000),
    ),
    (
      'presentaciones sin descargar y cuadros caros',
      LectorProbeConfig(
        products: 500,
        scans: 2,
        label: 'humo lento',
        maxTextMs: 100000,
        presentationsServerMs: 250,
        frameCostMs: 30,
      ),
    ),
  ]) {
    testWidgets('la sonda del lector corre y cumple los criterios ($name)',
        (tester) async {
      final previous = FlutterError.onError;
      FlutterError.onError = (_) {}; // sin fuentes reales hay desbordes
      final lines = <String>[];
      final result = await runLectorProbe(
        mount: (app) => tester.pumpWidget(app),
        injector: _SimulatedKeys(tester),
        config: config,
        isarLibrary: isarTestLibraryPath(),
        log: (line) {
          lines.add(line);
          // ignore: avoid_print
          print(line);
        },
      );
      FlutterError.onError = previous;
      await tester.pumpWidget(const SizedBox());
      Get.reset();
      expect(result.text, contains('A. 2 lecturas'));
      expect(lines.where((l) => l.contains('ERROR')), isEmpty);
      expect(result.failures, isEmpty,
          reason: 'ni tarjeta ni código a medias en las lecturas; a mano igual');
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
}
