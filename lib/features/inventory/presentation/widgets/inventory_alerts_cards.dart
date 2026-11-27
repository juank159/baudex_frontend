// lib/features/inventory/presentation/widgets/inventory_alerts_cards.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/inventory_balance_controller.dart';

class InventoryAlertsCards extends GetView<InventoryBalanceController> {
  const InventoryAlertsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final alerts = controller.alertCards;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;

      Color themed(Map alert) {
        switch (alert['title']) {
          case 'Todos':
            return ElegantLightTheme.primaryBlue;
          case 'Con Stock':
            return ElegantLightTheme.successGreen;
          case 'Stock Bajo':
            return ElegantLightTheme.warningOrange;
          case 'Sin Stock':
          case 'Vencidos':
            return ElegantLightTheme.errorRed;
        }
        return alert['color'] as Color;
      }

      Widget chip(int index, {required bool expand}) {
        final alert = alerts[index];
        final isSelected = controller.selectedAlertCard.value == index;
        final color = themed(alert);
        final fg = isSelected ? Colors.white : color;
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(alert['icon'], size: 14, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                alert['title'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                AppFormatters.formatNumber(alert['count'] as num?),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
        return Material(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => controller.selectAlertCard(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: content,
            ),
          ),
        );
      }

      if (isMobile) {
        // En celular: fichas con nombre, deslizables a lo ancho.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < alerts.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                chip(i, expand: false),
              ],
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            for (var i = 0; i < alerts.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: chip(i, expand: true)),
            ],
          ],
        ),
      );
    });
  }
}
