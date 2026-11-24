// Incidente #324: "Null check operator used on a null value" en
// AnimationController.stop <- value= <- reset, llamado desde un Timer.
//
// GetX 4.7: al deslizar un aviso para quitarlo programa
// `Timer(200 ms, _controller.reset)`. Si en esos 200 ms llega otro aviso
// (`replacePreviousSnackbar` cierra el actual) y la salida termina antes,
// GetX destruye la animación y el temporizador la toca ya destruida.
//
// En la prueba la salida se acelera con `timeDilation` (en la app lo hace un
// cuadro que llega tarde): la animación avanza más rápido que los relojes.
import 'package:baudex_desktop/app/core/theme/futuristic_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const GetMaterialApp(home: Scaffold(body: SizedBox.expand())),
  );
}

Future<void> _swipeUp(WidgetTester tester, String text) async {
  await tester.drag(find.text(text), const Offset(0, -300));
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> _pumpFor(WidgetTester tester, Duration total) async {
  const step = Duration(milliseconds: 16);
  for (var t = Duration.zero; t < total; t += step) {
    await tester.pump(step);
  }
}

void main() {
  tearDown(() {
    timeDilation = 1.0;
    Get.reset();
  });

  testWidgets(
      'deslizar un aviso y llegar otro enseguida no rompe la app '
      '(salida más rápida que el temporizador de GetX)', (tester) async {
    await _pumpApp(tester);
    FuturisticNotifications.showSuccess('Listo', 'deslízame');
    await tester.pumpAndSettle();

    timeDilation = 0.25; // salida de 300 ms en ~75 ms
    await _swipeUp(tester, 'deslízame');
    FuturisticNotifications.showInfo('Otro', 'aviso nuevo');
    await _pumpFor(tester, const Duration(milliseconds: 600));

    // Un fallo en el temporizador haría fallar la prueba aquí mismo.
    expect(find.text('deslízame'), findsNothing);
    expect(find.text('aviso nuevo'), findsOneWidget);

    // Deja que el aviso nuevo (4 s) se vaya solo: la fila de GetX es global.
    timeDilation = 1.0;
    await _pumpFor(tester, const Duration(seconds: 5));
    expect(Get.isSnackbarOpen, isFalse);
  });

  testWidgets('deslizar un aviso de la app lo sigue quitando', (tester) async {
    await _pumpApp(tester);
    FuturisticNotifications.showError('Error', 'deslízame');
    await tester.pumpAndSettle();

    await _swipeUp(tester, 'deslízame');
    await tester.pumpAndSettle();

    expect(find.text('deslízame'), findsNothing);
    expect(Get.isSnackbarOpen, isFalse);
  });
}
