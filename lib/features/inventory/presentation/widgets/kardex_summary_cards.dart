// lib/features/inventory/presentation/widgets/kardex_summary_cards.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/kardex_controller.dart';

class KardexSummaryCards extends GetView<KardexController> {
  const KardexSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasKardex) {
        return const SizedBox.shrink();
      }

      final cards = controller.summaryCards;
      final screenWidth = MediaQuery.of(context).size.width;

      // Responsive design: más columnas en pantallas más grandes
      int crossAxisCount;
      double aspectRatio;
      double spacing;

      if (screenWidth > 1200) {
        // Desktop grande - más compacto
        crossAxisCount = 4;
        aspectRatio = 2.2;
        spacing = 12;
      } else if (screenWidth > 900) {
        // Desktop mediano / Tablet landscape
        crossAxisCount = 4;
        aspectRatio = 2.0;
        spacing = 12;
      } else if (screenWidth > 700) {
        // Tablet portrait grande
        crossAxisCount = 2;
        aspectRatio = 1.8;
        spacing = 10;
      } else if (screenWidth > 600) {
        // Tablet portrait pequeño - más compacto
        crossAxisCount = 2;
        aspectRatio = 1.6;
        spacing = 8;
      } else {
        // Mobile
        crossAxisCount = 2;
        aspectRatio = 1.5;
        spacing = 8;
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return _buildCompactSummaryCard(
                title: card['title'],
                value: card['value'],
                subtitle: card['subtitle'],
                icon: card['icon'],
                color: card['color'],
                isLarge: screenWidth > 900,
              );
            },
          );
        },
      );
    });
  }

  Widget _buildCompactSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLarge,
  }) {
    // Convertir color a gradiente elegante
    final LinearGradient gradient = _getElegantGradientForColor(color);

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
        boxShadow: ElegantLightTheme.elevatedShadow,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 16 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono elegante y título
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isLarge ? 8 : 6),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(isLarge ? 8 : 6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isLarge ? 18 : 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: ElegantLightTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: isLarge ? 12 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: isLarge ? 12 : 8),

            // Valor principal elegante
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Get.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                  fontSize: isLarge ? 24 : 20,
                ),
              ),
            ),

            SizedBox(height: isLarge ? 8 : 4),

            // Subtítulo con estilo elegante
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isLarge ? 8 : 6,
                vertical: isLarge ? 4 : 3,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(isLarge ? 6 : 4),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: ElegantLightTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: isLarge ? 11 : 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getElegantGradientForColor(Color color) {
    if (color == Colors.blue) {
      return ElegantLightTheme.primaryGradient;
    } else if (color == Colors.green) {
      return ElegantLightTheme.successGradient;
    } else if (color == Colors.red) {
      return ElegantLightTheme.errorGradient;
    } else if (color == Colors.purple) {
      return ElegantLightTheme.infoGradient;
    } else {
      return ElegantLightTheme.primaryGradient;
    }
  }
}
