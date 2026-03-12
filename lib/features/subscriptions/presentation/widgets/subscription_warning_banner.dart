// lib/features/subscriptions/presentation/widgets/subscription_warning_banner.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/subscription_error_dialog.dart';

import '../../domain/entities/subscription.dart';
import '../controllers/subscription_controller.dart';

/// Banner de advertencia que se muestra cuando la suscripción está por expirar
///
/// Niveles de advertencia:
/// - Normal (> 7 días): No se muestra
/// - Warning (3-7 días): Banner amarillo
/// - Critical (1-3 días): Banner naranja
/// - Expired: Banner rojo
class SubscriptionWarningBanner extends StatelessWidget {
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onDismiss;
  final bool dismissible;

  const SubscriptionWarningBanner({
    super.key,
    this.onUpgradePressed,
    this.onDismiss,
    this.dismissible = true,
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
        final alertLevel = subscription.alertLevel;

        // No mostrar si el nivel es normal
        if (alertLevel == SubscriptionAlertLevel.normal) {
          return const SizedBox.shrink();
        }

        final config = _getBannerConfig(alertLevel, subscription);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [config.gradientStart, config.gradientEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: config.shadowColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Icono animado
                  _AnimatedIcon(
                    icon: config.icon,
                    color: config.iconColor,
                    animate: alertLevel == SubscriptionAlertLevel.critical ||
                        alertLevel == SubscriptionAlertLevel.expired,
                  ),
                  const SizedBox(width: 12),

                  // Mensaje
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          config.title,
                          style: TextStyle(
                            color: config.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          config.message,
                          style: TextStyle(
                            color: config.textColor.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Botón de acción - ✅ Muestra info de contacto
                  ElevatedButton(
                    onPressed: onUpgradePressed ?? () => _showContactInfo(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: config.buttonColor,
                      foregroundColor: config.buttonTextColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      config.buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Botón de cerrar (si es dismissible)
                  if (dismissible) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDismiss,
                      icon: Icon(
                        Icons.close,
                        color: config.textColor.withOpacity(0.7),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
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

  /// ✅ Muestra snackbar con información de contacto para renovar
  void _showContactInfo() {
    Get.snackbar(
      'Contacta para renovar',
      'WhatsApp: ${SubscriptionContactInfo.whatsappDisplay}\nEmail: ${SubscriptionContactInfo.email}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 8),
      icon: Icon(Icons.support_agent, color: Colors.green.shade700),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  _BannerConfig _getBannerConfig(
    SubscriptionAlertLevel level,
    Subscription subscription,
  ) {
    switch (level) {
      case SubscriptionAlertLevel.warning:
        return _BannerConfig(
          title: 'Tu suscripción vence pronto',
          message: 'Te quedan ${subscription.daysUntilExpiration} días. Renueva ahora para no perder acceso.',
          icon: Icons.access_time,
          gradientStart: Colors.amber.shade400,
          gradientEnd: Colors.amber.shade600,
          shadowColor: Colors.amber,
          iconColor: Colors.white,
          textColor: Colors.white,
          buttonColor: Colors.white,
          buttonTextColor: Colors.amber.shade700,
          buttonText: 'Renovar',
        );
      case SubscriptionAlertLevel.critical:
        return _BannerConfig(
          title: '¡Atención! Suscripción por vencer',
          message: subscription.daysUntilExpiration == 1
              ? '¡Último día! Renueva inmediatamente.'
              : 'Solo ${subscription.daysUntilExpiration} días restantes.',
          icon: Icons.warning_amber_rounded,
          gradientStart: Colors.orange.shade500,
          gradientEnd: Colors.deepOrange.shade600,
          shadowColor: Colors.deepOrange,
          iconColor: Colors.white,
          textColor: Colors.white,
          buttonColor: Colors.white,
          buttonTextColor: Colors.deepOrange.shade700,
          buttonText: 'Renovar Ya',
        );
      case SubscriptionAlertLevel.expired:
        return _BannerConfig(
          title: 'Suscripción expirada',
          message: 'Tu acceso está limitado. Renueva para continuar.',
          icon: Icons.error_outline,
          gradientStart: Colors.red.shade500,
          gradientEnd: Colors.red.shade700,
          shadowColor: Colors.red,
          iconColor: Colors.white,
          textColor: Colors.white,
          buttonColor: Colors.white,
          buttonTextColor: Colors.red.shade700,
          buttonText: 'Activar',
        );
      default:
        return _BannerConfig(
          title: '',
          message: '',
          icon: Icons.info_outline,
          gradientStart: Colors.grey.shade400,
          gradientEnd: Colors.grey.shade600,
          shadowColor: Colors.grey,
          iconColor: Colors.white,
          textColor: Colors.white,
          buttonColor: Colors.white,
          buttonTextColor: Colors.grey.shade700,
          buttonText: 'Ver',
        );
    }
  }
}

class _BannerConfig {
  final String title;
  final String message;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowColor;
  final Color iconColor;
  final Color textColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final String buttonText;

  const _BannerConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadowColor,
    required this.iconColor,
    required this.textColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.buttonText,
  });
}

class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool animate;

  const _AnimatedIcon({
    required this.icon,
    required this.color,
    this.animate = false,
  });

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _scaleAnimation.value : 1.0,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 24,
          ),
        );
      },
    );
  }
}
