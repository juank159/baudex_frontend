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

  /// La espera se cortó porque pasó el tiempo máximo (el botón no se queda
  /// cargando para siempre).
  tookTooLong,

  /// Cualquier otro rechazo: se muestra el mensaje tal cual llegó.
  other,
}

/// Tiempos máximos del inicio de sesión. Ninguna espera del botón "Iniciar
/// sesión" queda sin tope: red, almacén de sesión del equipo y pasos previos
/// a entrar a la pantalla principal.
class LoginDeadlines {
  const LoginDeadlines._();

  /// Conectar con el servidor (DNS, cortafuegos que no responde, TLS).
  static const Duration connect = Duration(seconds: 15);

  /// Enviar la petición y recibir la respuesta del servidor.
  static const Duration send = Duration(seconds: 15);
  static const Duration response = Duration(seconds: 30);

  /// Leer el almacén de sesión antes de una petición pública (no lo necesita).
  static const Duration requestPreparation = Duration(seconds: 5);

  /// Guardar la sesión que el servidor ya aceptó. Mayor que el tope para
  /// decidir dónde se guarda (12 s) más una escritura: con el mismo valor
  /// salía "tardó demasiado" justo cuando el equipo ya iba a guardar.
  static const Duration saveSession = Duration(seconds: 20);

  /// Guardar la huella para entrar sin internet (opcional).
  static const Duration saveOfflineAccess = Duration(seconds: 8);

  /// Leer la sesión guardada cuando no hay conexión.
  static const Duration offlineSession = Duration(seconds: 10);

  /// Cada paso entre "el servidor aceptó" y "entra a la pantalla principal".
  static const Duration afterLoginStep = Duration(seconds: 12);

  /// Revisar de qué negocio son los datos del equipo. NO es un tope corto:
  /// se espera el resultado real. Solo si pasa este tiempo se deja de
  /// esperar, y entonces NO se entra (nunca se da por permitido).
  static const Duration businessCheck = Duration(seconds: 120);

  /// Tope general del botón: pase lo que pase, deja de cargar.
  static const Duration overall = Duration(seconds: 90);
}

/// Resultado de revisar el negocio de los datos del equipo al iniciar sesión.
enum BusinessCheckResult {
  /// La revisión terminó y deja entrar.
  allowed,

  /// La revisión terminó y NO deja entrar (operaciones sin subir de otro
  /// negocio).
  blocked,

  /// La revisión no terminó: no se sabe. No se entra.
  unfinished,
}

/// Espera el resultado REAL de la revisión del negocio. Esa revisión protege
/// la cola pendiente de otro negocio y limpia los datos locales: si se diera
/// por permitida antes de terminar, se podría saltar el bloqueo o vaciar los
/// datos a mitad de la descarga. Si no termina en [cap] (o falla), el
/// resultado es [BusinessCheckResult.unfinished], nunca "permitido".
Future<BusinessCheckResult> awaitBusinessCheck(
  Future<bool> check, {
  Duration cap = LoginDeadlines.businessCheck,
}) async {
  try {
    final allowed = await check.timeout(cap);
    return allowed ? BusinessCheckResult.allowed : BusinessCheckResult.blocked;
  } catch (_) {
    return BusinessCheckResult.unfinished;
  }
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

  if (failure is LoginTimeoutFailure) {
    return LoginFailureView(
      kind: LoginFailureKind.tookTooLong,
      title: 'El inicio de sesión tardó demasiado',
      message: switch (failure.stage) {
        LoginWaitStage.saveSession =>
          'Tu correo y contraseña son correctos, pero este equipo no terminó '
              'de guardar la sesión. Cierra Baudex, ábrelo de nuevo e intenta '
              'otra vez. Si sigue igual, comparte este mensaje con soporte.',
        LoginWaitStage.offlineSession =>
          'Este equipo no logró conectarse con Baudex y tampoco terminó de '
              'leer la sesión guardada para entrar sin internet. Revisa el '
              'internet e intenta de nuevo.',
        LoginWaitStage.unknown =>
          'Baudex no terminó de iniciar sesión en este equipo. Revisa el '
              'internet (y que un antivirus o cortafuegos no esté bloqueando '
              'a Baudex), cierra la app, ábrela de nuevo e intenta otra vez. '
              'Si sigue igual, comparte este mensaje con soporte.',
      },
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
