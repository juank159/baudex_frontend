// Comprueba que la sonda del lector (tool/probes/lector_probe.dart) corre de
// punta a punta, con teclas simuladas y tiempo real. En Windows de verdad
// la sonda se compila como app (tool/probes/lector_windows_probe.dart) y
// las teclas las manda el sistema.
//
//   flutter test test/windows/lector_probe_smoke_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/probes/lector_probe.dart';
import '../helpers/isar_test_lib.dart';

class _SimulatedKeys implements KeyInjector {
  _SimulatedKeys(this.tester);
  final WidgetTester tester;
  String _text = '';

  @override
  String get name => 'simuladas (prueba)';

  @override
  Future<String?> prepare() async => null;

  void _setText(String text) {
    _text = text;
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ));
  }

  @override
  Future<void> type(String digits, {required int gapMs, bool enter = true}) async {
    for (final ch in digits.split('')) {
      final key = LogicalKeyboardKey(0x30 + int.parse(ch));
      await simulateKeyDownEvent(key);
      _setText(_text + ch);
      await simulateKeyUpEvent(key);
      if (gapMs > 0) await Future<void>.delayed(Duration(milliseconds: gapMs));
    }
    if (enter) {
      await simulateKeyDownEvent(LogicalKeyboardKey.enter);
      _text = '';
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await simulateKeyUpEvent(LogicalKeyboardKey.enter);
    }
  }

  @override
  Future<void> backspace(int count) async => _setText('');
}

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('la sonda del lector corre y saca la tabla', (tester) async {
    final previous = FlutterError.onError;
    FlutterError.onError = (_) {}; // sin fuentes reales hay desbordes
    final lines = <String>[];
    final result = await runLectorProbe(
      mount: (app) => tester.pumpWidget(app),
      injector: _SimulatedKeys(tester),
      config: const LectorProbeConfig(
          products: 500, scans: 2, label: 'prueba de humo'),
      isarLibrary: isarTestLibraryPath(),
      // ignore: avoid_print
      log: (line) {
        lines.add(line);
        // ignore: avoid_print
        print(line);
      },
    );
    FlutterError.onError = previous;
    expect(result.text, contains('A. 2 lecturas'));
    expect(result.text, contains('RESULTADO'));
    expect(lines.where((l) => l.contains('ERROR')), isEmpty);
    expect(lines.where((l) => l.contains('NO ENTRÓ')), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
