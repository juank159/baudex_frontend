// lib/features/subscriptions/presentation/widgets/usage_indicator_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/subscription_usage.dart';
import '../controllers/subscription_controller.dart';

/// Widget que muestra el uso actual vs límite de un recurso
///
/// Muestra una barra de progreso con el porcentaje de uso
/// y cambia de color según qué tan cerca está del límite.
class UsageIndicatorWidget extends StatelessWidget {
  final String resourceName;
  final ResourceUsage usage;
  final IconData? icon;
  final bool showLabel;
  final bool compact;
  final VoidCallback? onTap;

  const UsageIndicatorWidget({
    super.key,
    required this.resourceName,
    required this.usage,
    this.icon,
    this.showLabel = true,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getColorConfig(usage.percentage);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: compact ? 18 : 20,
                    color: config.iconColor,
                  ),
                  SizedBox(width: compact ? 8 : 10),
                ],
                Expanded(
                  child: Text(
                    resourceName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 13 : 14,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                // Badge de estado
                if (usage.hasReachedLimit)
                  _buildBadge('LÍMITE', Colors.red)
                else if (usage.isNearLimit)
                  _buildBadge('CERCA', Colors.orange)
                else if (usage.isUnlimited)
                  _buildBadge('∞', Colors.green),
              ],
            ),

            SizedBox(height: compact ? 10 : 14),

            // Barra de progreso
            _buildProgressBar(config),

            SizedBox(height: compact ? 6 : 8),

            // Valores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatUsageText(),
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (!usage.isUnlimited)
                  Text(
                    '${usage.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.bold,
                      color: config.progressColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressBar(_UsageColorConfig config) {
    if (usage.isUnlimited) {
      return Container(
        height: compact ? 6 : 8,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: List.generate(
            5,
            (index) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Fondo
        Container(
          height: compact ? 6 : 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Progreso
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          height: compact ? 6 : 8,
          width: double.infinity,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (usage.percentage / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [config.progressColor, config.progressColorEnd],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: config.progressColor.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatUsageText() {
    if (usage.isUnlimited) {
      return '${usage.current} usados (ilimitado)';
    }
    return '${usage.current} de ${usage.limit}';
  }

  _UsageColorConfig _getColorConfig(double percentage) {
    if (usage.isUnlimited) {
      return _UsageColorConfig(
        backgroundColor: Colors.green.shade50,
        borderColor: Colors.green.shade200,
        iconColor: Colors.green.shade600,
        progressColor: Colors.green.shade500,
        progressColorEnd: Colors.green.shade400,
      );
    }

    if (percentage >= 100) {
      return _UsageColorConfig(
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade200,
        iconColor: Colors.red.shade600,
        progressColor: Colors.red.shade600,
        progressColorEnd: Colors.red.shade400,
      );
    }

    if (percentage >= 80) {
      return _UsageColorConfig(
        backgroundColor: Colors.orange.shade50,
        borderColor: Colors.orange.shade200,
        iconColor: Colors.orange.shade600,
        progressColor: Colors.orange.shade500,
        progressColorEnd: Colors.orange.shade400,
      );
    }

    if (percentage >= 60) {
      return _UsageColorConfig(
        backgroundColor: Colors.amber.shade50,
        borderColor: Colors.amber.shade200,
        iconColor: Colors.amber.shade700,
        progressColor: Colors.amber.shade600,
        progressColorEnd: Colors.amber.shade400,
      );
    }

    return _UsageColorConfig(
      backgroundColor: Colors.blue.shade50,
      borderColor: Colors.blue.shade100,
      iconColor: Colors.blue.shade600,
      progressColor: Colors.blue.shade500,
      progressColorEnd: Colors.blue.shade400,
    );
  }
}

class _UsageColorConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color progressColor;
  final Color progressColorEnd;

  const _UsageColorConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.progressColor,
    required this.progressColorEnd,
  });
}

/// Widget que muestra todos los indicadores de uso de la suscripción
class SubscriptionUsageSummary extends StatelessWidget {
  final bool compact;
  final int crossAxisCount;

  const SubscriptionUsageSummary({
    super.key,
    this.compact = false,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : null,
      builder: (controller) {
        final usage = controller.usage;

        if (usage == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Cargando uso...'),
            ),
          );
        }

        final usageItems = [
          _UsageItem(
            name: 'Productos',
            usage: usage.products,
            icon: Icons.inventory_2,
          ),
          _UsageItem(
            name: 'Clientes',
            usage: usage.customers,
            icon: Icons.people,
          ),
          _UsageItem(
            name: 'Usuarios',
            usage: usage.users,
            icon: Icons.person,
          ),
          _UsageItem(
            name: 'Facturas este mes',
            usage: usage.invoicesThisMonth,
            icon: Icons.receipt_long,
          ),
          _UsageItem(
            name: 'Gastos este mes',
            usage: usage.expensesThisMonth,
            icon: Icons.money_off,
          ),
          _UsageItem(
            name: 'Almacenamiento',
            usage: usage.storage,
            icon: Icons.cloud,
          ),
        ];

        // Filtrar los que tienen uso
        final activeItems = usageItems
            .where((item) => item.usage.current > 0 || !item.usage.isUnlimited)
            .toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: compact ? 2.2 : 1.8,
          ),
          itemCount: activeItems.length,
          itemBuilder: (context, index) {
            final item = activeItems[index];
            return UsageIndicatorWidget(
              resourceName: item.name,
              usage: item.usage,
              icon: item.icon,
              compact: compact,
            );
          },
        );
      },
    );
  }
}

class _UsageItem {
  final String name;
  final ResourceUsage usage;
  final IconData icon;

  const _UsageItem({
    required this.name,
    required this.usage,
    required this.icon,
  });
}

/// Widget para mostrar una advertencia de límite cercano
class UsageLimitWarning extends StatelessWidget {
  final String resourceName;
  final ResourceUsage usage;
  final VoidCallback? onUpgrade;

  const UsageLimitWarning({
    super.key,
    required this.resourceName,
    required this.usage,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    if (!usage.isNearLimit && !usage.hasReachedLimit) {
      return const SizedBox.shrink();
    }

    final isAtLimit = usage.hasReachedLimit;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAtLimit ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAtLimit ? Colors.red.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAtLimit ? Icons.error : Icons.warning_amber_rounded,
            color: isAtLimit ? Colors.red.shade600 : Colors.orange.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAtLimit
                      ? 'Límite de $resourceName alcanzado'
                      : 'Cerca del límite de $resourceName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAtLimit ? Colors.red.shade700 : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${usage.current} de ${usage.limit} (${usage.percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 13,
                    color: isAtLimit ? Colors.red.shade600 : Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (onUpgrade != null)
            TextButton(
              onPressed: onUpgrade,
              child: Text(
                'Mejorar',
                style: TextStyle(
                  color: isAtLimit ? Colors.red.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
