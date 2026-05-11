import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/settings/presentation/controllers/organization_controller.dart';
import '../../config/routes/app_routes.dart';

/// Middleware que bloquea acceso a rutas del módulo de caja registradora
/// cuando el tenant lo ha desactivado en Settings.
///
/// Cubre el caso de:
///   - Deep link directo (URL en web, intent en mobile)
///   - Bookmark / historial del navegador
///   - Botón residual en alguna pantalla que aún navegue a /cash-register
///
/// Sin este middleware, un usuario podría llegar a la pantalla de caja
/// aunque el admin la haya apagado — confuso y un agujero de UX.
///
/// Comportamiento: si el módulo está apagado, redirige a `/dashboard` y
/// muestra un snackbar explicativo. Si está activo, no hace nada.
class CashRegisterRouteMiddleware extends GetMiddleware {
  /// Prioridad alta para correr antes que cualquier otro middleware.
  @override
  int? get priority => 10;

  @override
  RouteSettings? redirect(String? route) {
    // Si OrganizationController no está registrado (bootstrap temprano),
    // dejamos pasar — el usuario nunca llegaría aquí sin haber pasado
    // por el login que registra el controller.
    if (!Get.isRegistered<OrganizationController>()) return null;

    final enabled = Get.find<OrganizationController>().isCashRegisterEnabled;
    if (enabled) return null;

    // Módulo apagado → redirigir y avisar.
    // Postergamos el snackbar al siguiente frame para no chocar con la
    // transición de ruta que GetX está procesando en este instante.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        'Módulo desactivado',
        'La caja registradora no está habilitada para tu organización. '
        'Puedes activarla desde Configuración → Caja Registradora.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
      );
    });

    return const RouteSettings(name: AppRoutes.dashboard);
  }
}
