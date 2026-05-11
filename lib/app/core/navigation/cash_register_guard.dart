import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/cash_register/presentation/controllers/cash_register_controller.dart';
import '../../../features/cash_register/presentation/widgets/open_cash_register_dialog.dart';
import '../../../features/settings/presentation/controllers/organization_controller.dart';
import '../theme/elegant_light_theme.dart';

/// Guard de caja abierta para flujos que dependen de ella (facturación).
///
/// **Problema que resuelve:**
/// Si el usuario llegaba al form de "Crear factura" con la caja cerrada,
/// agregaba 500 ítems y al procesar el sistema le decía "abre la caja",
/// al ir a abrirla perdía todos los ítems del carrito. Frustración total.
///
/// **Solución profesional:**
/// Validar caja ANTES de abrir el form de factura. Si está cerrada,
/// mostrar un prompt corto con dos opciones:
///
///   - "Cancelar"   → no navega, no pasa nada.
///   - "Abrir caja" → muestra el dialog de apertura INLINE (no navega
///     a la pantalla de caja). Si la apertura es exitosa, el guard
///     retorna `true` y el flujo continúa al form de factura.
///
/// Así el usuario nunca llega al form con caja cerrada → nunca pierde
/// ítems por irse a abrirla a mitad de proceso.
class CashRegisterGuard {
  CashRegisterGuard._();

  /// Verifica que haya caja abierta. Si no la hay, ofrece abrirla
  /// inline. Retorna `true` si el flujo puede continuar; `false` si
  /// el usuario canceló.
  ///
  /// Llamar ANTES de cualquier navegación a un flujo que requiera
  /// caja abierta (facturación, principalmente).
  static Future<bool> requireOpen(BuildContext context) async {
    // Si el tenant desactivó el módulo de caja, el guard deja pasar
    // todo — facturación funciona sin requerir caja abierta. Esto es
    // lo que permite que clientes "sin caja" usen la app normal.
    if (Get.isRegistered<OrganizationController>() &&
        !Get.find<OrganizationController>().isCashRegisterEnabled) {
      return true;
    }
    // Si por algún motivo el controller no está registrado (bootstrap
    // temprano, tests), dejamos pasar — el form interno tendrá su
    // propia validación al procesar.
    if (!Get.isRegistered<CashRegisterController>()) return true;

    final ctrl = Get.find<CashRegisterController>();
    // Refrescar estado por si la caja fue abierta/cerrada en otro
    // dispositivo desde la última carga. Silent = sin spinner global.
    await ctrl.loadCurrent(silent: true);
    if (ctrl.hasOpenRegister) return true;

    // Caja cerrada → prompt.
    final shouldOpen = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.warningGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: const Text(
          'Caja cerrada',
          style: TextStyle(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Para crear una factura necesitas abrir primero la caja del '
          'día. ¿Quieres abrirla ahora?',
          textAlign: TextAlign.center,
          style: TextStyle(height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: ElegantLightTheme.textSecondary),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Get.back<bool>(result: true),
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text('Abrir caja'),
            style: FilledButton.styleFrom(
              backgroundColor: ElegantLightTheme.warningOrange,
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (shouldOpen != true) return false;

    // Dialog inline de apertura — NO navega, no rompe el flujo.
    // Si el usuario completa la apertura → retorna true → el caller
    // sigue al form de factura sin perder nada.
    return await showOpenCashRegisterDialog(context);
  }
}
