// lib/features/subscriptions/presentation/widgets/trial_countdown_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/subscription.dart';
import '../controllers/subscription_controller.dart';

/// Widget que muestra un contador regresivo de los días de trial
///
/// Muestra visualmente cuánto tiempo queda del período de prueba
/// con diferentes estilos según la urgencia.
class TrialCountdownWidget extends StatelessWidget {
  final bool showProgress;
  final bool compact;
  final VoidCallback? onUpgradePressed;

  const TrialCountdownWidget({
    super.key,
    this.showProgress = true,
    this.compact = false,
    this.onUpgradePressed,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : null,
      builder: (controller) {
        if (!controller.hasSubscription || !controller.isTrial) {
          return const SizedBox.shrink();
        }

        final subscription = controller.subscription!;
        final daysLeft = subscription.daysUntilExpiration;
        final progress = subscription.subscriptionProgress;

        if (compact) {
          return _buildCompactVersion(context, daysLeft, progress);
        }

        return _buildFullVersion(context, subscription, daysLeft, progress);
      },
    );
  }

  Widget _buildCompactVersion(
    BuildContext context,
    int daysLeft,
    double progress,
  ) {
    final config = _getConfig(daysLeft);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.gradientStart, config.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.gradientStart.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$daysLeft días',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullVersion(
    BuildContext context,
    Subscription subscription,
    int daysLeft,
    double progress,
  ) {
    final config = _getConfig(daysLeft);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.gradientStart, config.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.gradientStart.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  config.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Período de Prueba',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      config.message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contador de días
          _buildDaysCounter(daysLeft, config),

          if (showProgress) ...[
            const SizedBox(height: 20),

            // Barra de progreso
            _buildProgressBar(progress, subscription),
          ],

          const SizedBox(height: 20),

          // Botón de upgrade
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpgradePressed ?? () => Get.toNamed('/settings/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: config.gradientStart,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch,
                    size: 18,
                    color: config.gradientStart,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    daysLeft <= 3 ? 'Activar Ahora' : 'Ver Planes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysCounter(int daysLeft, _CountdownConfig config) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeUnit(daysLeft, 'días', config),
      ],
    );
  }

  Widget _buildTimeUnit(int value, String label, _CountdownConfig config) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, Subscription subscription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso del trial',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(subscription.startDate),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
            Text(
              _formatDate(subscription.endDate),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  _CountdownConfig _getConfig(int daysLeft) {
    if (daysLeft <= 1) {
      return _CountdownConfig(
        gradientStart: Colors.red.shade600,
        gradientEnd: Colors.red.shade400,
        icon: Icons.error_outline,
        message: '¡Último día! Activa tu plan ahora',
      );
    }

    if (daysLeft <= 3) {
      return _CountdownConfig(
        gradientStart: Colors.deepOrange.shade600,
        gradientEnd: Colors.orange.shade500,
        icon: Icons.warning_amber_rounded,
        message: '¡Tu trial está por terminar!',
      );
    }

    if (daysLeft <= 7) {
      return _CountdownConfig(
        gradientStart: Colors.orange.shade600,
        gradientEnd: Colors.amber.shade500,
        icon: Icons.hourglass_bottom,
        message: 'Aprovecha al máximo tu prueba',
      );
    }

    return _CountdownConfig(
      gradientStart: Colors.blue.shade600,
      gradientEnd: Colors.blue.shade400,
      icon: Icons.hourglass_empty,
      message: 'Explora todas las funciones',
    );
  }
}

class _CountdownConfig {
  final Color gradientStart;
  final Color gradientEnd;
  final IconData icon;
  final String message;

  const _CountdownConfig({
    required this.gradientStart,
    required this.gradientEnd,
    required this.icon,
    required this.message,
  });
}

/// Widget que muestra un banner de trial en la parte superior
class TrialBanner extends StatelessWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onUpgrade;

  const TrialBanner({
    super.key,
    this.onDismiss,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : null,
      builder: (controller) {
        if (!controller.hasSubscription || !controller.isTrial) {
          return const SizedBox.shrink();
        }

        final daysLeft = controller.daysUntilExpiration;

        // No mostrar si quedan más de 14 días
        if (daysLeft > 14) {
          return const SizedBox.shrink();
        }

        final isUrgent = daysLeft <= 3;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUrgent
                  ? [Colors.orange.shade500, Colors.deepOrange.shade500]
                  : [Colors.blue.shade500, Colors.blue.shade600],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  isUrgent ? Icons.hourglass_bottom : Icons.hourglass_empty,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isUrgent
                        ? '¡Solo $daysLeft ${daysLeft == 1 ? 'día' : 'días'} de trial!'
                        : '$daysLeft días restantes de prueba',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onUpgrade ?? () => Get.toNamed('/settings/subscription'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isUrgent ? Colors.deepOrange : Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Activar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDismiss,
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
