// Qué se le muestra al usuario por cada fallo de inicio de sesión.
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/features/auth/domain/rules/login_failure_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const deviceMsg =
      'Has alcanzado el límite de 3 dispositivo(s) permitido(s) en tu Plan Premium. '
      'Cierra sesión en otro dispositivo para continuar.';

  group('describeLoginFailure', () {
    test('401 del servidor: mensaje genérico de credenciales', () {
      final v = describeLoginFailure(
          ServerFailure.fromStatusCode(401, 'Credenciales inválidas'));
      expect(v.kind, LoginFailureKind.credentials);
      expect(v.message, genericCredentialsMessage);
    });

    test('403 de dispositivos: siempre su diálogo con el mensaje del servidor', () {
      final v = describeLoginFailure(ServerFailure.fromStatusCode(403, deviceMsg));
      expect(v.kind, LoginFailureKind.deviceLimit);
      expect(v.message, deviceMsg);
    });

    test('403 de dispositivos aunque el mensaje empiece con mayúscula', () {
      final v = describeLoginFailure(const ServerFailure(
          'Dispositivo no autorizado: límite alcanzado',
          code: 403));
      expect(v.kind, LoginFailureKind.deviceLimit);
    });

    test('fallo al guardar la sesión local: NO es credenciales, lleva el detalle', () {
      final v = describeLoginFailure(const LocalSessionSaveFailure(
          'CacheException: Error al guardar credenciales offline: PlatformException'));
      expect(v.kind, LoginFailureKind.localStorage);
      expect(v.message, isNot(genericCredentialsMessage));
      expect(v.detail, contains('PlatformException'));
    });

    test('mensajes con "credencial", "invalid", "correo" o "contraseña" ya no '
        'se vuelven credenciales incorrectas', () {
      for (final f in <Failure>[
        const CacheFailure('Error al guardar credenciales offline: x'),
        const UnknownFailure('Error inesperado durante el login: Invalid argument(s)'),
        const ServerFailure('Error desconocido: no se pudo enviar el correo'),
        const UnknownFailure('FormatException: contraseña'),
      ]) {
        expect(describeLoginFailure(f).kind, isNot(LoginFailureKind.credentials),
            reason: f.message);
      }
    });

    test('sin conexión y sin sesión guardada: conexión, con el porqué', () {
      final v = describeLoginFailure(const AuthFailure(
        message: 'No hay sesión previa guardada.',
        errorCode: 'NO_OFFLINE_CREDENTIALS',
        detail: 'Error de conexión: HandshakeException: CERTIFICATE_VERIFY_FAILED',
      ));
      expect(v.kind, LoginFailureKind.connection);
      expect(v.detail, contains('CERTIFICATE_VERIFY_FAILED'));
      expect(v.message, isNot(genericCredentialsMessage));
    });

    test('sin conexión y la clave no coincide con la guardada: conexión', () {
      final v = describeLoginFailure(const AuthFailure(
        message: 'x',
        errorCode: 'OFFLINE_PASSWORD_MISMATCH',
        detail: 'SocketException',
      ));
      expect(v.kind, LoginFailureKind.connection);
    });

    test('ConnectionFailure: conexión', () {
      expect(describeLoginFailure(const ConnectionFailure('Tiempo agotado')).kind,
          LoginFailureKind.connection);
    });

    test('429: demasiados intentos', () {
      final v = describeLoginFailure(ServerFailure.fromStatusCode(
          429, 'ThrottlerException: Too Many Requests'));
      expect(v.kind, LoginFailureKind.tooManyAttempts);
    });

    test('400 de validación: se muestra el mensaje del servidor sin prefijos', () {
      final v = describeLoginFailure(ServerFailure.fromStatusCode(
          400, 'Solicitud incorrecta: [property deviceId should not exist]'));
      expect(v.kind, LoginFailureKind.other);
      expect(v.message, 'property deviceId should not exist');
    });

    test('validación local: muestra los errores', () {
      final v = describeLoginFailure(
          const ValidationFailure(['El email no tiene un formato válido']));
      expect(v.kind, LoginFailureKind.other);
      expect(v.message, 'El email no tiene un formato válido');
    });
  });

  test('shortDetail recorta y aplana', () {
    expect(shortDetail(null), isNull);
    expect(shortDetail('null'), isNull);
    expect(shortDetail('a\n  b'), 'a b');
    expect(shortDetail('x' * 500)!.length, 303);
    expect(shortDetail('Explicación larga. Detalle: HandshakeException: CERTIFICATE_VERIFY_FAILED'),
        'HandshakeException: CERTIFICATE_VERIFY_FAILED');
  });
}
