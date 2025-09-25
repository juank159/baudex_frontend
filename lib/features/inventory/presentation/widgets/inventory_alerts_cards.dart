// lib/features/inventory/presentation/widgets/inventory_alerts_cards.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../controllers/inventory_balance_controller.dart';

class InventoryAlertsCards extends GetView<InventoryBalanceController> {
  const InventoryAlertsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final alerts = controller.alertCards;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;
      
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 8 : 16, 
            isMobile ? 8 : 12, 
            isMobile ? 8 : 16, 
            isMobile ? 8 : 12
          ),
          child: Row(
            children: List.generate(alerts.length, (index) {
              final alert = alerts[index];
              final isSelected = controller.selectedAlertCard.value == index;
              final color = alert['color'] as Color;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.selectAlertCard(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                      right: index < alerts.length - 1 ? (isMobile ? 4 : 8) : 0
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 12, 
                      vertical: isMobile ? 6 : 8
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                    ),
                    child: isMobile ? 
                      // Layout móvil - más compacto
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            alert['icon'], 
                            size: 14,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${alert['count']}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ) :
                      // Layout desktop - normal
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                alert['icon'], 
                                size: 12,
                                color: isSelected ? Colors.white : color,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                alert['title'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Colors.white.withValues(alpha: 0.2) 
                                      : color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${alert['count']}',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    });
  }

}