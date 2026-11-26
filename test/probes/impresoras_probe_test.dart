// Corre la prueba de impresoras de Windows (tool/probes/impresoras_probe.dart)
// en cualquier equipo, sin los pasos que necesitan una impresora instalada.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tool/probes/impresoras_probe.dart';
import '../helpers/isar_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initIsarCore);

  test('todos los pasos que no necesitan Windows cumplen', () async {
    SharedPreferences.setMockInitialValues({});
    final lines = <String>[];
    final done = Completer<ImpresorasProbeResult>();
    // Los avisos (`Get.snackbar`) no tienen pantalla aquí.
    runZonedGuarded(
      () async => done.complete(
        await runImpresorasProbe(
          config: const ImpresorasProbeConfig(label: 'prueba local'),
          log: lines.add,
        ),
      ),
      (error, stack) {
        if (stack.toString().contains('snackbar')) return;
        if (!done.isCompleted) done.completeError(error, stack);
      },
    );
    final result = await done.future;
    // ignore: avoid_print
    print(lines.join('\n'));
    expect(lines.where((l) => l.contains('| FALLA')), isEmpty);
    expect(result.ok, isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
