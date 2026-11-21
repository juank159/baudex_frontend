// lib/app/core/utils/snackbar_policy.dart
import 'dart:async';

import 'package:get/get.dart';

/// Un solo aviso a la vez: el nuevo reemplaza al que está en pantalla.
///
/// GetX pone los avisos en FILA: 100 escaneos con aviso dejaban 93 esperando
/// (4 minutos de avisos) y, mientras hubiera uno, `Get.back()` solo cerraba el
/// aviso y no volvía de pantalla. Llamarla justo antes de `Get.snackbar`.
///
/// Cierra el aviso actual (no usa `closeAllSnackbars`: en GetX 4.7 ese vacía
/// la lista DESPUÉS de cerrar y el aviso siguiente queda en pantalla sin que
/// GetX lo sepa).
void replacePreviousSnackbar() {
  if (!Get.isSnackbarOpen) return;
  _guarded(() => Get.closeCurrentSnackbar());
}

/// Cierra el aviso en pantalla y vacía la fila, sin fallar nunca.
///
/// GetX 4.7 falla (`LateInitializationError`) si el primero de la fila aún no
/// se terminó de mostrar (recién pedido): el error salía por la zona, la fila
/// no se vaciaba y "Volver" quedaba sin efecto (50 veces en 90 vueltas de la
/// prueba de estrés). Aquí el error se atrapa y se reintenta cuando el aviso
/// ya está en pantalla.
void dismissAllSnackbars({int retries = 5}) {
  if (!Get.isSnackbarOpen) return;
  var failed = false;
  _guarded(() => Get.closeAllSnackbars(), onError: () {
    if (failed) return;
    failed = true;
    if (retries > 0) {
      Timer(const Duration(milliseconds: 60),
          () => dismissAllSnackbars(retries: retries - 1));
    }
  });
}

void _guarded(void Function() action, {void Function()? onError}) {
  runZonedGuarded(action, (error, stack) => onError?.call());
}
