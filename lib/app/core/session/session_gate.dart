// lib/app/core/session/session_gate.dart
import 'package:get/get.dart';

import '../../../features/auth/presentation/controllers/auth_controller.dart';

/// ¿Se SABE que no hay sesión iniciada? (pantalla de iniciar sesión).
///
/// Los servicios globales (sincronización, caja, suscripción) lo consultan
/// para no trabajar antes de entrar: sin sesión no hay nada que subir ni
/// que consultar, y ese trabajo competía con el tecleo del login.
///
/// Solo mira la memoria (no lee el almacén de sesión). Si todavía no se
/// puede saber (controlador de sesión sin registrar, p. ej. en pruebas),
/// devuelve `false`: ante la duda, todo sigue como antes.
bool sessionKnownClosed() {
  try {
    if (!Get.isRegistered<AuthController>()) return false;
    return !Get.find<AuthController>().isAuthenticated;
  } catch (_) {
    return false;
  }
}
