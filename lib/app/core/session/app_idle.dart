// lib/app/core/session/app_idle.dart
//
// ¿La app está ociosa AHORA? Para trabajo de fondo que puede congelar la
// ventana (p. ej. leer el almacén seguro de Windows en un equipo lento): solo
// corre si nadie está vendiendo, no hay un diálogo abierto (pago, Bre-B…) y
// pasó un rato sin teclado ni ratón.
import 'package:get/get.dart';

import '../../config/routes/app_routes.dart';
import '../navigation/route_stack_observer.dart';
import 'user_activity.dart';

class AppIdle {
  AppIdle._();

  /// Rato sin teclado ni ratón para considerar la app ociosa.
  static const Duration quiet = Duration(seconds: 30);

  /// Regla pura: ociosa = sin facturación visible, sin diálogo abierto y
  /// al menos [quiet] sin entradas del usuario.
  static bool isIdle({
    required Duration idleFor,
    required bool sellingVisible,
    required bool dialogOpen,
    Duration quiet = AppIdle.quiet,
  }) =>
      !sellingVisible && !dialogOpen && idleFor >= quiet;

  /// La pantalla visible es facturación (punto de venta).
  static bool get sellingScreenVisible {
    final route = Get.currentRoute;
    return route.startsWith(AppRoutes.invoicesWithTabs) ||
        route.startsWith(AppRoutes.invoicesCreate) ||
        route.startsWith(AppRoutes.invoicesEdit);
  }

  /// Estado real de la app ahora.
  static bool now() {
    try {
      return isIdle(
        idleFor: UserActivity.idleFor,
        sellingVisible: sellingScreenVisible,
        dialogOpen: RouteStackObserver.instance.hasOpenPopup || (Get.isDialogOpen ?? false),
      );
    } catch (_) {
      return false;
    }
  }
}
