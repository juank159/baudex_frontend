// lib/features/dashboard/presentation/widgets/credit_notes_banner.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/dashboard_controller.dart';

/// Banner prominente que aparece en el dashboard cuando hay notas de
/// crédito aplicadas en el período. Hace IMPOSIBLE no notar el impacto
/// de las devoluciones sobre los ingresos brutos.
///
/// Diseño: barra horizontal a todo el ancho, fondo rojo claro con borde
/// rojo, icono de alerta, monto grande, leyenda explicativa.
class CreditNotesBanner extends GetView<DashboardController> {
  const CreditNotesBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasCreditNotes) return const SizedBox.shrink();

      final ncTotal = controller.creditNotesTotal;
      final ncCount = controller.creditNotesCount;
      final gross = controller.totalCollected;
      final net = controller.netRevenue;

      return Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingMedium),
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.red.shade50,
              Colors.orange.shade50,
            ],
          ),
          border: Border.all(color: Colors.red.shade300, width: 1.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade100.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_return_outlined,
                color: Colors.red.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '⚠️ Devoluciones aplicadas en este período',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$ncCount NC',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _buildAmountChip(
                        label: 'Cobrado bruto',
                        value: AppFormatters.formatCurrency(gross),
                        color: Colors.grey.shade700,
                      ),
                      _buildAmountChip(
                        label: 'Devuelto',
                        value: '−${AppFormatters.formatCurrency(ncTotal)}',
                        color: Colors.red.shade700,
                        bold: true,
                      ),
                      _buildAmountChip(
                        label: 'INGRESO REAL',
                        value: AppFormatters.formatCurrency(net),
                        color: net > 0
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        bold: true,
                        large: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ver notas de crédito',
              icon: Icon(Icons.arrow_forward_rounded,
                  color: Colors.red.shade700),
              onPressed: () => Get.toNamed('/credit-notes'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAmountChip({
    required String label,
    required String value,
    required Color color,
    bool bold = false,
    bool large = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 16 : 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
