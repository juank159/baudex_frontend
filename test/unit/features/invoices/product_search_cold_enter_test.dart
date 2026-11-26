// Primer Enter "en frío" sobre un valor: el campo del nombre debe salir
// ANTES de que el motor de voz diga nada, y la voz se precalienta al abrir
// la factura (en Windows la primera frase carga la voz y puede frenar la
// app de medio segundo a varios segundos).
import 'package:baudex_desktop/app/core/services/audio_notification_service.dart';
import 'package:baudex_desktop/features/invoices/domain/invoice_entry_metrics.dart';
import 'package:baudex_desktop/features/invoices/domain/price_entry.dart';
import 'package:baudex_desktop/features/invoices/presentation/controllers/invoice_form_controller.dart';
import 'package:baudex_desktop/features/invoices/presentation/widgets/product_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockInvoiceFormController extends Mock implements InvoiceFormController {}

void main() {
  // Motor de voz de mentira: anota cada llamada y el volumen del momento.
  final calls = <String>[];
  var volume = 1.0;
  var dialogOnScreen = () => false;

  setUp(() {
    Get.testMode = true;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'),
            (call) async {
      switch (call.method) {
        case 'getLanguages':
          return ['es-ES'];
        case 'setVolume':
          volume = (call.arguments as num).toDouble();
        case 'speak':
          calls.add('speak "${call.arguments}" volumen ${volume.toStringAsFixed(1)} '
              'diálogo ${dialogOnScreen() ? 'en pantalla' : 'NO'}');
      }
      return 1;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
    Get.reset();
  });

  testWidgets('la voz se precalienta sin volumen en un rato libre tras abrir '
      'la factura (una vez); en el primer Enter el campo del nombre sale '
      'antes de cualquier frase',
      (tester) async {
    final controller = MockInvoiceFormController();
    final index = ShortCodeIndex.build(const [], complete: true);
    when(() => controller.guessValueEntry(any())).thenAnswer((inv) =>
        guessValueEntry(inv.positionalArguments.first as String, index));
    when(() => controller.entryContext()).thenReturn(const EntryContext());
    when(() => controller.shouldValidateStock).thenReturn(false);
    dialogOnScreen =
        () => find.text('Nombre en la factura').evaluate().isNotEmpty;

    await tester.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: ProductSearchWidget(
          controller: controller,
          onProductSelected: (_, __) {},
        ),
      ),
    ));
    // Al abrir no se toca la voz: espera un rato libre (3 s sin teclear).
    await tester.pump(const Duration(seconds: 2));
    expect(calls, isEmpty);
    expect(AudioNotificationService.instance.warmUpPending, isTrue);
    // Teclear aplaza el precalentamiento.
    await tester.enterText(find.byType(TextField).first, 'a');
    await tester.pump(const Duration(seconds: 2));
    expect(calls, isEmpty, reason: 'hubo tecleo hace 2 s: todavía no');
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(AudioNotificationService.instance.warmUpPending, isFalse);

    // Precalentado al abrir: una sílaba, sin volumen, y el volumen vuelve.
    // (En modo de pruebas el servicio además saluda al iniciar.)
    calls.removeWhere((c) => c.contains('Bienvenido'));
    expect(calls, ['speak "a" volumen 0.0 diálogo NO']);
    expect(volume, greaterThan(0));
    expect(AudioNotificationService.instance.warmUpMs, isNotNull);
    calls.clear();

    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(); // el cuadro del Enter
    await tester.pump();
    expect(find.text('Nombre en la factura'), findsOneWidget);
    final name = tester.widget<EditableText>(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(EditableText)));
    expect(name.focusNode.hasFocus, isTrue);
    expect(calls, isEmpty,
        reason: 'la voz todavía no habló: no puede frenar el campo');

    await tester.pump(const Duration(milliseconds: 80));
    expect(calls, ['speak "Producto no registrado" volumen 0.8 diálogo en pantalla']);
    expect(AudioNotificationService.instance.report(),
        contains('de más de 100 ms: 0'));
    await tester.pump(const Duration(seconds: 1));

    // Nunca dos veces: volver a abrir la factura no repite la sílaba.
    calls.clear();
    AudioNotificationService.instance.warmUpWhenIdle();
    await tester.pump(const Duration(seconds: 5));
    expect(calls, isEmpty);
  });
}
