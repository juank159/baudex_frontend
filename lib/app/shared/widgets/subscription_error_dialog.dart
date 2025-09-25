// lib/app/shared/widgets/subscription_error_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive.dart';
import 'custom_button.dart';

/// Diálogo profesional para mostrar errores de suscripción
class SubscriptionErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryActionPressed;

  const SubscriptionErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
    this.secondaryActionText,
    this.onSecondaryActionPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
            ),
          ),
        ],
      ),
      content: Container(
        width: context.isMobile ? double.maxFinite : 480,
        constraints: BoxConstraints(
          maxHeight: context.isMobile ? 400 : 500,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje principal
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
              ),
              
              const SizedBox(height: 16),
              
              // Información adicional con icono
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Para continuar usando todas las funcionalidades, actualiza tu suscripción a un plan activo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade700,
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Botón secundario (opcional)
        if (secondaryActionText != null)
          TextButton(
            onPressed: onSecondaryActionPressed ?? () => Get.back(),
            child: Text(
              secondaryActionText!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Botón principal
        CustomButton(
          text: actionText ?? 'Entendido',
          onPressed: onActionPressed ?? () => Get.back(),
          type: ButtonType.primary,
          backgroundColor: Colors.orange.shade600,
          textColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          fontSize: 14,
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }

  /// Muestra el diálogo de error de suscripción expirada
  static void showSubscriptionExpired({
    String? customMessage,
    VoidCallback? onUpgradePressed,
    VoidCallback? onDismissed,
  }) {
    Get.dialog(
      SubscriptionErrorDialog(
        title: 'Suscripción Expirada',
        message: customMessage ?? 
            'Tu período de prueba ha expirado. Para continuar creando productos y accediendo a todas las funcionalidades, necesitas actualizar tu suscripción.',
        actionText: 'Actualizar Suscripción',
        onActionPressed: () {
          Get.back();
          if (onUpgradePressed != null) {
            onUpgradePressed();
          } else {
            // Navegar a la página de suscripciones por defecto
            Get.toNamed('/settings/subscription');
          }
        },
        secondaryActionText: 'Ahora No',
        onSecondaryActionPressed: () {
          Get.back();
          onDismissed?.call();
        },
      ),
      barrierDismissible: false,
    );
  }

  /// Muestra el diálogo de acceso denegado por suscripción
  static void showAccessDenied({
    String? customTitle,
    String? customMessage,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    Get.dialog(
      SubscriptionErrorDialog(
        title: customTitle ?? 'Acceso Restringido',
        message: customMessage ?? 
            'Esta funcionalidad requiere una suscripción activa. Por favor, actualiza tu plan para continuar.',
        actionText: actionText ?? 'Ver Planes',
        onActionPressed: onActionPressed ?? () {
          Get.back();
          Get.toNamed('/settings/subscription');
        },
        secondaryActionText: 'Cancelar',
      ),
      barrierDismissible: true,
    );
  }

  /// Muestra el diálogo de límite de usuarios alcanzado
  static void showUserLimitReached({
    int? maxUsers,
    VoidCallback? onUpgradePressed,
  }) {
    Get.dialog(
      SubscriptionErrorDialog(
        title: 'Límite de Usuarios Alcanzado',
        message: maxUsers != null
            ? 'Has alcanzado el límite máximo de $maxUsers usuarios para tu plan actual. Para agregar más usuarios, actualiza tu suscripción.'
            : 'Has alcanzado el límite máximo de usuarios para tu plan actual. Para agregar más usuarios, actualiza tu suscripción.',
        actionText: 'Actualizar Plan',
        onActionPressed: () {
          Get.back();
          if (onUpgradePressed != null) {
            onUpgradePressed();
          } else {
            Get.toNamed('/settings/subscription');
          }
        },
        secondaryActionText: 'Entendido',
      ),
      barrierDismissible: true,
    );
  }
}