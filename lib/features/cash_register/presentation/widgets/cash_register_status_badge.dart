// lib/features/cash_register/presentation/widgets/cash_register_status_badge.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/cash_register_controller.dart';

/// Badge compacto que se inserta en el AppBar (gradiente glass) para
/// mostrar el estado de la caja en cualquier pantalla. Estilizado con
/// ElegantLightTheme para que combine con los AppBars de la app.
class CashRegisterStatusBadge extends StatelessWidget {
  final bool compact;

  const CashRegisterStatusBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
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
      final label = isOpen
          ? AppFormatters.formatCurrency(controller.expectedAmount)
          : 'Caja cerrada';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Tooltip(
          message: isOpen
              ? 'Caja abierta — Toca para ver detalle'
              : 'Caja cerrada — Toca para abrir',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.cashRegister),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12, vertical: 6),
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
                      size: 14,
                      color: Colors.white,
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

      // Caja CERRADA: banner clásico de "acción requerida".

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.warningOrange
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Caja cerrada',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                'ACCIÓN REQUERIDA',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: ElegantLightTheme
                                      .warningOrange,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Abre la caja para empezar a registrar las '
                          'ventas en efectivo del día.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.white.withValues(alpha: 0.95),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            Get.toNamed(AppRoutes.cashRegister),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_open_rounded,
                                  color: ElegantLightTheme
                                      .warningOrange,
                                  size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Abrir Caja',
                                style: TextStyle(
                                  color: ElegantLightTheme
                                      .warningOrange,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
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
    });
  }

  /// Banner de "caja vieja" — recordatorio profesional cuando la caja
  /// lleva muchas horas abierta. Dos niveles de urgencia:
  /// - 12h-20h (warning naranja): "Recuerda cerrar la caja"
  /// - >20h (error rojo): "Caja del día anterior sigue abierta"
  Widget _buildStaleBanner({
    required bool isCritical,
    required int hoursOpen,
  }) {
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
        : 'Recuerda hacer el cuadre al final del día — el turno actual '
            'lleva $hoursOpen horas activo.';
    final tagText = isCritical ? 'URGENTE' : 'RECORDATORIO';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tagText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Get.toNamed(AppRoutes.cashRegister),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: accentColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Cerrar caja',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
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
