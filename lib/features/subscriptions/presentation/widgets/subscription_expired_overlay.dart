// lib/features/subscriptions/presentation/widgets/subscription_expired_overlay.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/subscription_error_dialog.dart';

import '../controllers/subscription_controller.dart';

/// Overlay de pantalla completa que se muestra cuando la suscripción ha expirado
///
/// Bloquea la interacción con la aplicación hasta que el usuario
/// renueve su suscripción o esté en período de gracia.
class SubscriptionExpiredOverlay extends StatelessWidget {
  final VoidCallback? onUpgradePressed;
  final VoidCallback? onLogoutPressed;
  final bool showGracePeriodInfo;
  final int? gracePeriodDaysRemaining;

  const SubscriptionExpiredOverlay({
    super.key,
    this.onUpgradePressed,
    this.onLogoutPressed,
    this.showGracePeriodInfo = false,
    this.gracePeriodDaysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono animado
                  _buildAnimatedIcon(),

                  const SizedBox(height: 32),

                  // Título
                  Text(
                    showGracePeriodInfo
                        ? 'Período de Gracia Activo'
                        : 'Suscripción Expirada',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Mensaje
                  Text(
                    showGracePeriodInfo
                        ? _getGracePeriodMessage()
                        : 'Tu suscripción ha expirado. Para continuar usando todas las funcionalidades de la aplicación, necesitas renovar tu plan.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (showGracePeriodInfo && gracePeriodDaysRemaining != null) ...[
                    const SizedBox(height: 24),
                    _buildGracePeriodCountdown(context),
                  ],

                  const SizedBox(height: 32),

                  // Información de lo que pierdes
                  _buildFeaturesList(context),

                  const SizedBox(height: 32),

                  // Botones de acción
                  _buildActionButtons(context),

                  const SizedBox(height: 16),

                  // Link de contacto soporte
                  TextButton(
                    onPressed: () => _contactSupport(),
                    child: Text(
                      '¿Necesitas ayuda? Contacta soporte',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5),
          child: Opacity(
            opacity: value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: showGracePeriodInfo
                      ? [Colors.orange.shade400, Colors.deepOrange.shade600]
                      : [Colors.red.shade400, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (showGracePeriodInfo ? Colors.orange : Colors.red)
                        .withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                showGracePeriodInfo
                    ? Icons.hourglass_bottom
                    : Icons.lock_outline,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getGracePeriodMessage() {
    if (gracePeriodDaysRemaining == null) {
      return 'Estás en período de gracia. Durante este tiempo solo puedes ver tu información pero no crear nuevos registros.';
    }

    if (gracePeriodDaysRemaining == 1) {
      return '¡Último día de gracia! Mañana se bloqueará completamente tu acceso. Renueva ahora para no perder tus datos.';
    }

    return 'Te quedan $gracePeriodDaysRemaining días de gracia. Durante este período solo puedes consultar información existente.';
  }

  Widget _buildGracePeriodCountdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tiempo restante',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                '$gracePeriodDaysRemaining ${gracePeriodDaysRemaining == 1 ? 'día' : 'días'}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = showGracePeriodInfo
        ? [
            _FeatureItem(
              icon: Icons.visibility,
              text: 'Ver información existente',
              available: true,
            ),
            _FeatureItem(
              icon: Icons.search,
              text: 'Buscar y filtrar datos',
              available: true,
            ),
            _FeatureItem(
              icon: Icons.picture_as_pdf,
              text: 'Exportar PDFs',
              available: true,
            ),
            _FeatureItem(
              icon: Icons.add_circle,
              text: 'Crear nuevos registros',
              available: false,
            ),
            _FeatureItem(
              icon: Icons.edit,
              text: 'Editar información',
              available: false,
            ),
          ]
        : [
            _FeatureItem(
              icon: Icons.inventory,
              text: 'Gestión de productos',
              available: false,
            ),
            _FeatureItem(
              icon: Icons.people,
              text: 'Gestión de clientes',
              available: false,
            ),
            _FeatureItem(
              icon: Icons.receipt,
              text: 'Facturación',
              available: false,
            ),
            _FeatureItem(
              icon: Icons.analytics,
              text: 'Reportes y estadísticas',
              available: false,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showGracePeriodInfo ? 'Durante el período de gracia:' : 'Sin acceso a:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  feature.available ? Icons.check_circle : Icons.cancel,
                  color: feature.available ? Colors.green : Colors.red.shade300,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Icon(
                  feature.icon,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature.text,
                    style: TextStyle(
                      color: Colors.white.withOpacity(feature.available ? 0.9 : 0.6),
                      fontSize: 14,
                      decoration: feature.available ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // ✅ MODIFICADO: Mostrar información de contacto en lugar de navegar
        // Información de contacto para renovación
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Contacta para renovar:',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // WhatsApp
              Row(
                children: [
                  const Icon(Icons.chat, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  SelectableText(
                    'WhatsApp: ${SubscriptionContactInfo.whatsappDisplay}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Teléfono
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  SelectableText(
                    'Teléfono: ${SubscriptionContactInfo.phoneDisplay}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Email
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  SelectableText(
                    'Email: ${SubscriptionContactInfo.email}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botón secundario
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onLogoutPressed ?? () => _showLogoutConfirmation(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión? '
          'Podrás volver a iniciar sesión cuando renueves tu suscripción.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Llamar al logout
              if (Get.isRegistered<SubscriptionController>()) {
                Get.find<SubscriptionController>();
              }
              Get.offAllNamed('/login');
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    Get.snackbar(
      'Contacto para renovación',
      'WhatsApp: ${SubscriptionContactInfo.whatsappDisplay} | Email: ${SubscriptionContactInfo.email}',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      duration: const Duration(seconds: 8),
      icon: const Icon(Icons.support_agent, color: Colors.green),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String text;
  final bool available;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.available,
  });
}

/// Widget para mostrar el overlay de forma condicional
class SubscriptionExpiredWrapper extends StatelessWidget {
  final Widget child;
  final bool blockOnExpired;

  const SubscriptionExpiredWrapper({
    super.key,
    required this.child,
    this.blockOnExpired = true,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SubscriptionController>(
      init: Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : null,
      builder: (controller) {
        if (!blockOnExpired || !controller.hasSubscription) {
          return child;
        }

        final subscription = controller.subscription!;

        // Si está expirado, mostrar overlay
        if (subscription.isExpired) {
          return Stack(
            children: [
              child,
              const SubscriptionExpiredOverlay(),
            ],
          );
        }

        return child;
      },
    );
  }
}
