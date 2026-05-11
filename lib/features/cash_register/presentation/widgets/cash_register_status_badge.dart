// lib/features/cash_register/presentation/widgets/cash_register_status_badge.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/navigation/navigation_guard.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../settings/presentation/controllers/organization_controller.dart';
import '../controllers/cash_register_controller.dart';
import 'open_cash_register_dialog.dart';

/// Helper centralizado: retorna `true` si el módulo de caja está
/// habilitado para el tenant actual. Default `true` cuando el
/// OrganizationController no está disponible (bootstrap temprano).
bool _isCashRegisterModuleEnabled() {
  if (!Get.isRegistered<OrganizationController>()) return true;
  return Get.find<OrganizationController>().isCashRegisterEnabled;
}

/// Badge compacto que se inserta en el AppBar (gradiente glass) para
/// mostrar el estado de la caja en cualquier pantalla. Estilizado con
/// ElegantLightTheme para que combine con los AppBars de la app.
class CashRegisterStatusBadge extends StatelessWidget {
  final bool compact;

  const CashRegisterStatusBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    // Si el tenant desactivó el módulo de caja, el badge no aparece.
    // Esto deja el AppBar con sólo Dashboard + sync + refresh — limpio
    // para clientes que no usan caja del día (servicios, software, etc.).
    if (!_isCashRegisterModuleEnabled()) return const SizedBox.shrink();
    if (!Get.isRegistered<CashRegisterController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<CashRegisterController>();

    return Obx(() {
      // Loading inicial sin datos
      if (controller.isLoading.value &&
          controller.currentState.value.cashRegister == null &&
          controller.errorMessage.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          ),
        );
      }

      final isOpen = controller.hasOpenRegister;
      // SIEMPRE valor real ($15.428.000), nunca formato compacto ($15M).
      // En mobile el AppBar lo deja crecer pegando "Dashboard" a la
      // izquierda y comprimiendo padding del badge — pero el monto se
      // muestra completo, sin redondeos engañosos.
      final label = isOpen
          ? AppFormatters.formatCurrency(controller.expectedAmount)
          : (compact ? 'Cerrada' : 'Caja cerrada');

      return Padding(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 4, vertical: compact ? 6 : 8),
        child: Tooltip(
          message: isOpen
              ? 'Caja abierta — Toca para ver detalle'
              : 'Caja cerrada — Toca para abrir',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => AppNav.toNamed(AppRoutes.cashRegister),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 12,
                    vertical: compact ? 4 : 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOpen
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                      size: compact ? 12 : 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: compact ? 4 : 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Banner GRANDE con tema Elegant que aparece en el dashboard.
///
/// Tres estados visuales según contexto (no es molesto en uso normal):
/// 1. Caja CERRADA → banner naranja "Acción requerida — abrir caja"
/// 2. Caja abierta hace > 12h → banner naranja "Tu caja lleva mucho
///    tiempo abierta — recuerda cerrarla al final del día"
/// 3. Caja abierta hace > 20h → banner ROJO "La caja del día anterior
///    sigue abierta — ciérrala para cuadrar"
/// 4. Caja abierta normal (< 12h) → no muestra nada
///
/// El banner es persistente pero no bloqueante — el usuario puede seguir
/// trabajando, el banner sirve solo de recordatorio profesional.
class CashRegisterClosedBanner extends StatelessWidget {
  const CashRegisterClosedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Módulo desactivado por el tenant → ningún banner aparece, ni
    // "Caja cerrada", ni "Tu caja lleva X horas". Para negocios que
    // simplemente no usan el concepto de caja del día.
    if (!_isCashRegisterModuleEnabled()) return const SizedBox.shrink();
    if (!Get.isRegistered<CashRegisterController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<CashRegisterController>();

    return Obx(() {
      if (controller.isLoading.value &&
          controller.currentState.value.cashRegister == null) {
        return const SizedBox.shrink();
      }
      if (controller.errorMessage.isNotEmpty) return const SizedBox.shrink();

      // Caja ABIERTA: solo alertar si lleva mucho tiempo (>12h o >20h).
      if (controller.hasOpenRegister) {
        final reg = controller.openRegister!;
        final hoursOpen = reg.duration.inHours;
        if (hoursOpen >= 20) {
          return _buildStaleBanner(
            isCritical: true,
            hoursOpen: hoursOpen,
          );
        }
        if (hoursOpen >= 12) {
          return _buildStaleBanner(
            isCritical: false,
            hoursOpen: hoursOpen,
          );
        }
        return const SizedBox.shrink();
      }

      // Caja CERRADA → banner unificado con el mismo layout vertical
      // que `_buildStaleBanner` (icono + título + badge en header,
      // subtítulo abajo, botón "Abrir Caja" full-width en mobile /
      // alineado a la derecha en desktop). Además el botón abre el
      // dialog inline de apertura — no navega a otra pantalla, así
      // si el usuario tenía un form a medio llenar no pierde nada.
      return _buildOpenActionBanner(context);
    });
  }

  /// Banner "Caja cerrada — Abrir caja".
  ///
  /// Diseño armónico vertical:
  ///   ┌──────────────────────────────────────┐
  ///   │ [⏰]  Caja cerrada     [ACCIÓN REQ.]  │
  ///   │                                       │
  ///   │ Abre la caja para empezar a           │
  ///   │ registrar ventas en efectivo del día. │
  ///   │                                       │
  ///   │ ┌──────────────────────────────────┐  │
  ///   │ │     🔓  Abrir caja               │  │
  ///   │ └──────────────────────────────────┘  │
  ///   └──────────────────────────────────────┘
  Widget _buildOpenActionBanner(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    const tagText = 'ACCIÓN REQUERIDA';
    final accentColor = ElegantLightTheme.warningOrange;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.warningGradient,
              borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: isMobile ? 10 : 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== Header: icono + título + badge =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Icon(
                        Icons.point_of_sale_rounded,
                        color: Colors.white,
                        size: isMobile ? 18 : 22,
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: isMobile ? 2 : 4),
                        child: Text(
                          'Caja cerrada',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 7 : 9,
                          vertical: isMobile ? 3 : 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tagText,
                        style: TextStyle(
                          fontSize: isMobile ? 8.5 : 9.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 12),
                // ===== Subtítulo full-width =====
                Text(
                  'Abre la caja para empezar a registrar las ventas en '
                  'efectivo del día.',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 14),
                // ===== Botón "Abrir caja" =====
                // Mobile: full-width. Desktop: alineado a la derecha
                // con tamaño acorde al texto (consistente con el banner
                // de "caja vieja").
                Align(
                  alignment: isMobile
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      // Dialog inline — no navega, no rompe contexto.
                      onTap: () => showOpenCashRegisterDialog(context),
                      child: Container(
                        width: isMobile ? double.infinity : null,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 22,
                            vertical: 11),
                        child: Row(
                          mainAxisSize: isMobile
                              ? MainAxisSize.max
                              : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_open_rounded,
                                color: accentColor,
                                size: isMobile ? 17 : 18),
                            const SizedBox(width: 8),
                            Text(
                              'Abrir caja',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Banner de "caja vieja" — recordatorio profesional cuando la caja
  /// lleva muchas horas abierta. Dos niveles de urgencia:
  /// - 12h-20h (warning naranja): "Recuerda cerrar la caja"
  /// - >20h (error rojo): "Caja del día anterior sigue abierta"
  Widget _buildStaleBanner({
    required bool isCritical,
    required int hoursOpen,
  }) {
    final isMobile = MediaQuery.of(Get.context!).size.width < 600;
    final gradient = isCritical
        ? ElegantLightTheme.errorGradient
        : ElegantLightTheme.warningGradient;
    final accentColor = isCritical
        ? ElegantLightTheme.errorRed
        : ElegantLightTheme.warningOrange;
    final title = isCritical
        ? 'Caja del día anterior sigue abierta'
        : 'Tu caja lleva ${hoursOpen}h abierta';
    final subtitle = isCritical
        ? 'Ciérrala para cuadrar el turno y empezar uno nuevo. '
            'Las ventas y gastos seguirán contando hasta que la cierres.'
        : 'Recuerda hacer el cuadre al final del día — el turno '
            'actual lleva $hoursOpen horas activo.';
    final tagText = isCritical ? 'URGENTE' : 'RECORDATORIO';

    // Layout VERTICAL armónico (sin importar tamaño):
    //
    //   ┌─────────────────────────────────────────┐
    //   │ [⏰]  Tu caja lleva 12h    [RECORDATORIO] │ ← header
    //   │                                          │
    //   │ Recuerda hacer el cuadre al final del   │ ← subtítulo
    //   │ día — el turno actual lleva 12 horas...  │
    //   │                                          │
    //   │ ┌────────────────────────────────────┐  │
    //   │ │       🔒 Cerrar caja               │  │ ← botón full-width
    //   │ └────────────────────────────────────┘  │
    //   └─────────────────────────────────────────┘
    //
    // El badge "RECORDATORIO" arriba a la derecha (claramente etiqueta
    // del tipo), título a la izquierda, subtítulo libre debajo y el
    // botón ocupando todo el ancho. Todo alineado verticalmente.
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: isMobile ? 10 : 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== Header: icono + título a la izq, badge a la der
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Icon(
                        isCritical
                            ? Icons.warning_amber_rounded
                            : Icons.access_time_rounded,
                        color: Colors.white,
                        size: isMobile ? 18 : 22,
                      ),
                    ),
                    SizedBox(width: isMobile ? 10 : 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: isMobile ? 2 : 4),
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 7 : 9,
                          vertical: isMobile ? 3 : 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tagText,
                        style: TextStyle(
                          fontSize: isMobile ? 8.5 : 9.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 10 : 12),
                // ===== Subtítulo a ancho completo
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 14),
                // ===== Botón "Cerrar caja"
                //
                // Mobile: ocupa todo el ancho (Row stretch del padre).
                // Desktop: alineado a la derecha con tamaño acorde al
                // texto — full-width se veía desproporcionado porque la
                // card es ancha y el botón es solo una acción.
                Align(
                  alignment: isMobile
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => AppNav.toNamed(AppRoutes.cashRegister),
                      child: Container(
                        width: isMobile ? double.infinity : null,
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 22,
                            vertical: isMobile ? 11 : 11),
                        child: Row(
                          mainAxisSize: isMobile
                              ? MainAxisSize.max
                              : MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: accentColor,
                                size: isMobile ? 17 : 18),
                            const SizedBox(width: 8),
                            Text(
                              'Cerrar caja',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: isMobile ? 13.5 : 13.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
