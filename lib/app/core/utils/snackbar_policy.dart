// lib/app/core/utils/snackbar_policy.dart
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
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
}
