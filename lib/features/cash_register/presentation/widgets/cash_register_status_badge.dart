// lib/features/cash_register/presentation/widgets/cash_register_status_badge.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/cash_register_controller.dart';

/// Badge compacto que se inserta en el AppBar para mostrar el estado
/// de la caja en cualquier pantalla. Tres estados visuales:
///   - 🟢 Caja abierta: muestra "Caja $X" con monto esperado.
///   - 🔒 Caja cerrada: muestra "Caja cerrada" en gris.
///   - ⏳ Cargando: spinner discreto.
///
/// Click → siempre navega a la pantalla de Caja Registradora.
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
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      final isOpen = controller.hasOpenRegister;
      final color = isOpen ? Colors.green.shade700 : Colors.grey.shade600;
      final icon = isOpen ? Icons.lock_open_rounded : Icons.lock_outline_rounded;
      final label = isOpen
          ? AppFormatters.formatCurrency(controller.expectedAmount)
          : 'Caja cerrada';

      return InkWell(
        onTap: () => Get.toNamed(AppRoutes.cashRegister),
        borderRadius: BorderRadius.circular(20),
        child: Tooltip(
          message: isOpen
              ? 'Caja abierta — Toca para ver detalle'
              : 'Caja cerrada — Toca para abrir',
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                if (!compact) ...[
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else ...[
                  Text(
                    isOpen ? '🟢' : '🔒',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Banner GRANDE que aparece en el dashboard cuando la caja está
/// cerrada. Es la forma profesional de invitar al usuario a abrir
/// caja sin forzarlo (flujo no-bloqueante).
class CashRegisterClosedBanner extends StatelessWidget {
  const CashRegisterClosedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CashRegisterController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<CashRegisterController>();

    return Obx(() {
      // Solo mostrar si:
      //   - Ya tenemos data (no está en loading inicial)
      //   - No hay error de red
      //   - La caja está cerrada
      if (controller.isLoading.value &&
          controller.currentState.value.cashRegister == null) {
        return const SizedBox.shrink();
      }
      if (controller.errorMessage.isNotEmpty) return const SizedBox.shrink();
      if (controller.hasOpenRegister) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: Colors.amber.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade200.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.point_of_sale_rounded,
                  color: Colors.amber.shade900, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '💰 Caja cerrada',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.shade900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ACCIÓN REQUERIDA',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Abre la caja para empezar a registrar las ventas en '
                    'efectivo del día y poder cuadrar al cierre.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900.withOpacity(0.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(Icons.lock_open_rounded, size: 16),
              label: const Text('Abrir Caja'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              onPressed: () => Get.toNamed(AppRoutes.cashRegister),
            ),
          ],
        ),
      );
    });
  }
}
