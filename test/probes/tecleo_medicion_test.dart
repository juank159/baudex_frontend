// Comprueba que la medición de tecleo (tool/probes/tecleo_medicion.dart)
// encuentra las cajas, escribe a ritmo de persona y mide Enter → otra caja
// con foco. Teclas simuladas: en Windows real las manda el sistema.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/probes/tecleo_medicion.dart';

void main() {
  final binding = LiveTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('escribe "500", ve el aviso y Enter pasa el foco al nombre',
      (tester) async {
    final search = TextEditingController();
    final nameFocus = FocusNode();
    var showCard = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Column(children: [
            TextField(
              autofocus: true,
              controller: search,
              onChanged: (_) {},
              onSubmitted: (_) => nameFocus.requestFocus(),
            ),
            if (showCard) const Text('Producto sin registrar'),
            TextField(focusNode: nameFocus),
            TextButton(
              onPressed: () => setState(() => showCard = true),
              child: const Text('x'),
            ),
          ]),
        ),
      ),
    ));
    search.addListener(() {
      if (search.text == '500' && !showCard) {
        showCard = true;
        (tester.element(find.byType(StatefulBuilder)) as StatefulElement).markNeedsBuild();
      }
    });
    await tester.pump();

    await tester.runAsync(() async {
      final medidor = MedidorDeTecleo()..start();
      expect(cajasDeTexto(), hasLength(2));
      final box = cajaConFoco();
      expect(box, isNotNull);
      expect(identical(box!.widget.controller, search), isTrue);

      final tanda = await medidor.escribir(box, '500', gapMs: 30);
      expect(search.text, '500');
      expect(tanda.porTecla, hasLength(3));
      for (final key in tanda.porTecla) {
        expect(key.$3, isNotNull, reason: 'texto de la tecla ${key.$1}');
        expect(key.$3!, lessThan(1000));
      }
      expect(tanda.cuadros, greaterThan(0));
      expect(await medidor.esperar(() => hayTexto('sin registrar'), seconds: 3), isTrue);
      expect(textosEnPantalla(), contains('Producto sin registrar'));

      final enter = await medidor.pulsar(
        teclaEnter,
        () {
          final focused = cajaConFoco();
          return focused != null && !identical(focused, box);
        },
        box: box,
        seconds: 3,
      );
      expect(enter.$1, isNotNull, reason: 'Enter → otra caja con foco');

      final nunca = await medidor.pulsar(teclaEscape, () => false, seconds: 1);
      expect(nunca.$1, isNull);
    });
  });
}
