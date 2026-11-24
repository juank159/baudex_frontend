// lib/features/auth/domain/rules/login_failure_rules.dart
import '../../../../app/core/errors/failures.dart';

/// Qué le pasó a un intento de inicio de sesión, visto por el usuario.
enum LoginFailureKind {
  /// El servidor rechazó el correo o la contraseña (401).
  credentials,

  /// El plan no admite más equipos con sesión abierta (403 del servidor).
  deviceLimit,

  /// Demasiados intentos seguidos (429).
  tooManyAttempts,

  /// La app no logró hablar con el servidor (internet, DNS, certificado,
  /// fecha del equipo, cortafuegos...). NO es un problema de credenciales.
  connection,

  /// El servidor aceptó el inicio de sesión pero este equipo no pudo guardar
  /// la sesión. NO es un problema de credenciales.
  localStorage,

  /// Cualquier otro rechazo: se muestra el mensaje tal cual llegó.
  other,
}

/// Lo que se le muestra al usuario por un fallo de inicio de sesión.
class LoginFailureView {
  const LoginFailureView({
    required this.kind,
    required this.title,
    required this.message,
    this.detail,
  });

  final LoginFailureKind kind;
  final String title;
  final String message;

  /// Detalle técnico para soporte (excepción original). Nunca lleva la
  /// contraseña ni el token.
  final String? detail;
}

/// Mensaje único para correo/contraseña/negocio incorrectos: no dice cuál de
/// los tres falló, para no revelar a qué negocio pertenece un correo.
const String genericCredentialsTitle = 'No se pudo iniciar sesión';
const String genericCredentialsMessage =
    'Verifica que el negocio, correo y contraseña sean correctos.';

const _serverPrefixes = <String>[
  'Solicitud incorrecta: ',
  'Error del servidor: ',
  'Error: ',
];

/// Quita los prefijos técnicos que el cliente HTTP antepone a los mensajes
/// del servidor (a veces dos veces).
String cleanServerMessage(String message) {
  var out = message.trim();
  var changed = true;
  while (changed) {
    changed = false;
    for (final p in _serverPrefixes) {
      if (out.startsWith(p)) {
        out = out.substring(p.length).trim();
        changed = true;
      }
    }
  }
  // Los errores de validación llegan como lista: "[a, b]".
  if (out.length > 2 && out.startsWith('[') && out.endsWith(']')) {
    out = out.substring(1, out.length - 1);
  }
  return out;
}

/// Recorta un detalle técnico para que quepa en pantalla. Si el texto trae
/// una explicación seguida de "Detalle: <causa>", se queda con la causa (la
/// explicación ya está en el mensaje principal).
String? shortDetail(String? detail, {int max = 300}) {
  if (detail == null) return null;
  var oneLine = detail.replaceAll(RegExp(r'\s+'), ' ').trim();
  final mark = oneLine.lastIndexOf('Detalle: ');
  if (mark >= 0) oneLine = oneLine.substring(mark + 'Detalle: '.length).trim();
  if (oneLine.isEmpty || oneLine == 'null') return null;
  return oneLine.length <= max ? oneLine : '${oneLine.substring(0, max)}...';
}

/// Decide qué mostrar por un fallo de inicio de sesión.
///
/// La decisión sale del TIPO y del CÓDIGO del fallo, nunca de buscar
/// palabras en el mensaje: antes cualquier texto con "credencial",
/// "invalid", "correo" o "contraseña" (por ejemplo "Error al guardar
/// credenciales offline" o "Invalid argument") se mostraba como
/// credenciales incorrectas aunque el servidor hubiera aceptado el ingreso
/// o ni siquiera se hubiera llegado a él.
LoginFailureView describeLoginFailure(Failure failure) {
  if (failure is LocalSessionSaveFailure) {
    return LoginFailureView(
      kind: LoginFailureKind.localStorage,
      title: 'No se pudo guardar la sesión en este equipo',
      message: 'Tu correo y contraseña son correctos, pero este equipo no '
          'pudo guardar la sesión. Cierra Baudex, ábrelo de nuevo e intenta '
          'otra vez. Si sigue igual, comparte este mensaje con soporte.',
      detail: shortDetail(failure.detail),
    );
  }

  if (failure.code == 403 &&
      failure.message.toLowerCase().contains('dispositivo')) {
    return LoginFailureView(
      kind: LoginFailureKind.deviceLimit,
      title: 'Límite de dispositivos',
      message: cleanServerMessage(failure.message),
    );
  }

  if (failure is AuthFailure) {
    switch (failure.errorCode) {
      case 'NO_OFFLINE_CREDENTIALS':
        return LoginFailureView(
          kind: LoginFailureKind.connection,
          title: 'Sin conexión con el servidor',
          message: 'Este equipo no logró conectarse con Baudex y todavía no '
              'tiene una sesión guardada para entrar sin internet. Revisa el '
              'internet, la fecha y la hora del equipo e intenta de nuevo.',
          detail: shortDetail(failure.detail),
        );
      case 'OFFLINE_PASSWORD_MISMATCH':
        return LoginFailureView(
          kind: LoginFailureKind.connection,
          title: 'Sin conexión con el servidor',
          message: 'Este equipo no logró conectarse con Baudex, y el correo o '
              'la contraseña no coinciden con la última sesión guardada para '
              'entrar sin internet. Revisa el internet e intenta de nuevo.',
          detail: shortDetail(failure.detail),
        );
      case 'SESSION_EXPIRED':
        return LoginFailureView(
          kind: LoginFailureKind.connection,
          title: 'Sin conexión con el servidor',
          message: 'Este equipo no logró conectarse con Baudex y la sesión '
              'guardada ya venció. Necesitas internet para volver a entrar.',
          detail: shortDetail(failure.detail),
        );
      case 'INVALID_CREDENTIALS':
        return const LoginFailureView(
          kind: LoginFailureKind.credentials,
          title: genericCredentialsTitle,
          message: genericCredentialsMessage,
        );
    }
  }

  if (failure is ConnectionFailure) {
    return LoginFailureView(
      kind: LoginFailureKind.connection,
      title: 'Sin conexión con el servidor',
      message: 'Este equipo no logró conectarse con Baudex. Revisa el '
          'internet, la fecha y la hora del equipo e intenta de nuevo.',
      detail: shortDetail(failure.message),
    );
  }

  if (failure.code == 401) {
    return const LoginFailureView(
      kind: LoginFailureKind.credentials,
      title: genericCredentialsTitle,
      message: genericCredentialsMessage,
    );
  }

  if (failure.code == 429) {
    return const LoginFailureView(
      kind: LoginFailureKind.tooManyAttempts,
      title: 'Demasiados intentos',
      message: 'Se hicieron muchos intentos seguidos. Espera un minuto y '
          'vuelve a intentar.',
    );
  }

  if (failure is ValidationFailure) {
    return LoginFailureView(
      kind: LoginFailureKind.other,
      title: 'Revisa los datos',
      message: failure.allErrors,
    );
  }

  final cleaned = cleanServerMessage(failure.message);
  return LoginFailureView(
    kind: LoginFailureKind.other,
    title: 'No se pudo iniciar sesión',
    message: cleaned.isEmpty ? 'Ocurrió un error. Intenta de nuevo.' : cleaned,
  );
}
