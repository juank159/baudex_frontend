// lib/features/subscriptions/presentation/widgets/subscription_status_badge.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../controllers/subscription_controller.dart';

/// Badge que muestra el estado de la suscripción en el AppBar
///
/// Muestra diferentes estados:
/// - Trial con días restantes
/// - Plan activo (Basic, Premium, Enterprise)
/// - Advertencia de expiración próxima
/// - Expirado
class SubscriptionStatusBadge extends StatelessWidget {
  final bool showPlanName;
  final bool compact;
  final VoidCallback? onTap;

  const SubscriptionStatusBadge({
    super.key,
    this.showPlanName = true,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : null,
      builder: (controller) {
        if (!controller.hasSubscription) {
          return const SizedBox.shrink();
        }

        final subscription = controller.subscription!;
        final config = _getBadgeConfig(subscription);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? () => _showSubscriptionInfo(context, subscription),
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: config.backgroundColor,
                borderRadius: BorderRadius.circular(compact ? 12 : 16),
                border: Border.all(color: config.borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    config.icon,
                    size: compact ? 14 : 16,
                    color: config.iconColor,
                  ),
                  if (showPlanName) ...[
                    SizedBox(width: compact ? 4 : 6),
                    Text(
                      config.label,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: config.textColor,
                      ),
                    ),
                  ],
                  if (config.showDays && subscription.daysUntilExpiration > 0) ...[
                    SizedBox(width: compact ? 4 : 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: config.daysBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${subscription.daysUntilExpiration}d',
                        style: TextStyle(
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.bold,
                          color: config.daysTextColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _BadgeConfig _getBadgeConfig(Subscription subscription) {
    // Si está expirado
    if (subscription.isExpired) {
      return _BadgeConfig(
        label: 'Expirado',
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade50,
        borderColor: Colors.red.shade200,
        iconColor: Colors.red.shade600,
        textColor: Colors.red.shade700,
        showDays: false,
      );
    }

    // Si es trial
    if (subscription.isTrial) {
      final daysLeft = subscription.daysUntilExpiration;

      if (daysLeft <= 3) {
        return _BadgeConfig(
          label: 'Trial',
          icon: Icons.hourglass_bottom,
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade300,
          iconColor: Colors.orange.shade600,
          textColor: Colors.orange.shade700,
          showDays: true,
          daysBackgroundColor: Colors.orange.shade100,
          daysTextColor: Colors.orange.shade800,
        );
      }

      return _BadgeConfig(
        label: 'Trial',
        icon: Icons.hourglass_empty,
        backgroundColor: Colors.blue.shade50,
        borderColor: Colors.blue.shade200,
        iconColor: Colors.blue.shade600,
        textColor: Colors.blue.shade700,
        showDays: true,
        daysBackgroundColor: Colors.blue.shade100,
        daysTextColor: Colors.blue.shade800,
      );
    }

    // Si está por expirar (< 7 días)
    if (subscription.isExpiringSoon) {
      return _BadgeConfig(
        label: subscription.planDisplayName,
        icon: Icons.warning_amber_rounded,
        backgroundColor: Colors.amber.shade50,
        borderColor: Colors.amber.shade300,
        iconColor: Colors.amber.shade700,
        textColor: Colors.amber.shade800,
        showDays: true,
        daysBackgroundColor: Colors.amber.shade100,
        daysTextColor: Colors.amber.shade900,
      );
    }

    // Plan activo normal
    return _getBadgeConfigForPlan(subscription.plan, subscription.planDisplayName);
  }

  _BadgeConfig _getBadgeConfigForPlan(SubscriptionPlan plan, String displayName) {
    switch (plan) {
      case SubscriptionPlan.basic:
        return _BadgeConfig(
          label: displayName,
          icon: Icons.star_outline,
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          iconColor: Colors.green.shade600,
          textColor: Colors.green.shade700,
          showDays: false,
        );
      case SubscriptionPlan.premium:
        return _BadgeConfig(
          label: displayName,
          icon: Icons.star,
          backgroundColor: Colors.purple.shade50,
          borderColor: Colors.purple.shade200,
          iconColor: Colors.purple.shade600,
          textColor: Colors.purple.shade700,
          showDays: false,
        );
      case SubscriptionPlan.enterprise:
        return _BadgeConfig(
          label: displayName,
          icon: Icons.diamond,
          backgroundColor: Colors.indigo.shade50,
          borderColor: Colors.indigo.shade200,
          iconColor: Colors.indigo.shade600,
          textColor: Colors.indigo.shade700,
          showDays: false,
        );
      default:
        return _BadgeConfig(
          label: displayName,
          icon: Icons.verified_user_outlined,
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          iconColor: Colors.grey.shade600,
          textColor: Colors.grey.shade700,
          showDays: false,
        );
    }
  }

  void _showSubscriptionInfo(BuildContext context, Subscription subscription) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SubscriptionInfoSheet(subscription: subscription),
    );
  }
}

class _BadgeConfig {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final bool showDays;
  final Color daysBackgroundColor;
  final Color daysTextColor;

  const _BadgeConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.showDays,
    this.daysBackgroundColor = Colors.transparent,
    this.daysTextColor = Colors.black,
  });
}

class _SubscriptionInfoSheet extends StatelessWidget {
  final Subscription subscription;

  const _SubscriptionInfoSheet({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getPlanIcon(subscription.plan),
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.planDisplayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusText(subscription),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(subscription),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Detalles
          _buildInfoRow(
            context,
            Icons.calendar_today,
            'Fecha de inicio',
            _formatDate(subscription.startDate),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.event,
            'Fecha de vencimiento',
            _formatDate(subscription.endDate),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            Icons.people,
            'Usuarios máximos',
            '${subscription.maxUsers}',
          ),

          if (subscription.daysUntilExpiration > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.timer,
              'Días restantes',
              '${subscription.daysUntilExpiration} días',
              valueColor: subscription.daysUntilExpiration <= 7
                  ? Colors.orange.shade700
                  : null,
            ),
          ],

          const SizedBox(height: 24),

          // Botón de acción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/settings/subscription');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ver detalles del plan'),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  IconData _getPlanIcon(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.trial:
        return Icons.hourglass_empty;
      case SubscriptionPlan.basic:
        return Icons.star_outline;
      case SubscriptionPlan.premium:
        return Icons.star;
      case SubscriptionPlan.enterprise:
        return Icons.diamond;
    }
  }

  String _getStatusText(Subscription subscription) {
    if (subscription.isExpired) return 'Expirado';
    if (subscription.isTrial) return 'Período de prueba';
    if (subscription.isActive) return 'Activo';
    return subscription.status.name;
  }

  Color _getStatusColor(Subscription subscription) {
    if (subscription.isExpired) return Colors.red.shade600;
    if (subscription.isTrial) return Colors.blue.shade600;
    if (subscription.isActive) return Colors.green.shade600;
    return Colors.grey.shade600;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
