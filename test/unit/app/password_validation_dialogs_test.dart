// Los dos diálogos de confirmar con contraseña muestran un mensaje claro:
// nunca "Exception: ..." crudo.
import 'package:baudex_desktop/app/core/errors/exceptions.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/services/password_validation_service.dart';
import 'package:baudex_desktop/app/shared/widgets/password_validation_dialog.dart';
import 'package:baudex_desktop/features/inventory/presentation/widgets/confirm_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements DioClient {}

class _FakeService extends PasswordValidationService {
  _FakeService(this.answer) : super(_MockDio());
  final Future<bool> Function(String) answer;
  final List<String> received = [];

  @override
  Future<bool> validatePassword(String password) {
    received.add(password);
    return answer(password);
  }
}

void main() {
  tearDown(Get.reset);

  Future<void> openConfirm(WidgetTester tester) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Builder(
        builder: (_) => TextButton(
          onPressed: () => showConfirmPasswordDialog(
              title: 'Confirmar ajustes', message: 'Se aplicarán 3 ajustes'),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  group('diálogo de inventario', () {
    testWidgets('contraseña incorrecta', (tester) async {
      Get.put<PasswordValidationService>(_FakeService((_) async => false));
      await openConfirm(tester);
      await tester.enterText(find.byType(TextField), 'mala');
      await tester.tap(find.text('Confirmar y aplicar'));
      await tester.pumpAndSettle();
      expect(find.text(wrongPasswordMessage), findsOneWidget);
    });

    testWidgets('sin conexión: mensaje claro y la contraseña sin recortar',
        (tester) async {
      final svc = _FakeService((_) async => throw const PasswordValidationException(
          'No se pudo validar la contraseña: sin conexión con el servidor'));
      Get.put<PasswordValidationService>(svc);
      await openConfirm(tester);
      await tester.enterText(find.byType(TextField), ' clave con espacios ');
      await tester.tap(find.text('Confirmar y aplicar'));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'No se pudo validar la contraseña: sin conexión con el servidor'),
          findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(svc.received.single, ' clave con espacios ');
    });

    testWidgets('error raro: nunca "Exception:"', (tester) async {
      Get.put<PasswordValidationService>(
          _FakeService((_) async => throw Exception('algo')));
      await openConfirm(tester);
      await tester.enterText(find.byType(TextField), 'x');
      await tester.tap(find.text('Confirmar y aplicar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('No se pudo validar la contraseña'),
          findsOneWidget);
    });
  });

  group('diálogo de configuración', () {
    Future<void> open(WidgetTester tester, Future<bool> Function(String) f,
        String password) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PasswordValidationDialog(
              title: 'Confirmar', message: 'Cambio sensible', onValidate: f),
        ),
      ));
      await tester.enterText(find.byType(TextFormField), password);
      await tester.tap(find.text('Validar'));
      await tester.pumpAndSettle();
    }

    testWidgets('contraseña incorrecta', (tester) async {
      await open(tester, (_) async => false, 'clave-mala');
      expect(find.text(wrongPasswordMessage), findsOneWidget);
    });

    testWidgets('error del servidor sin "Exception:" ni prefijo',
        (tester) async {
      await open(
          tester,
          (_) async => throw const ServerException(
              'Solicitud incorrecta: algo raro',
              statusCode: 400),
          'clave-123');
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Solicitud incorrecta'), findsNothing);
      expect(find.text('No se pudo validar la contraseña: algo raro'),
          findsOneWidget);
    });
  });
}
