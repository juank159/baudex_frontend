// lib/app/shared/widgets/subscription_error_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive.dart';
import 'custom_button.dart';

/// Datos de contacto del proveedor para renovaciones
class SubscriptionContactInfo {
  static const String whatsapp = '3138448436';
  static const String phone = '3138448436';
  static const String email = 'baudexgroup@gmail.com';
  static const String whatsappDisplay = '+57 313 844 8436';
  static const String phoneDisplay = '+57 313 844 8436';
}

/// Diálogo profesional para mostrar errores de suscripción
class SubscriptionErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryActionPressed;
  final Widget? customContent; // ✅ Contenido personalizado opcional

  const SubscriptionErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionPressed,
    this.secondaryActionText,
    this.onSecondaryActionPressed,
    this.customContent,
  });

  /// Widget reutilizable con información de contacto del proveedor
  static Widget buildContactInfoWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de contacto
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Contacta a tu proveedor para renovar:',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // WhatsApp
              Row(
                children: [
                  Icon(Icons.chat, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 8),
                  SelectableText(
                    'WhatsApp: ${SubscriptionContactInfo.whatsappDisplay}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Teléfono
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 8),
                  SelectableText(
                    'Teléfono: ${SubscriptionContactInfo.phoneDisplay}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Email
              Row(
                children: [
                  Icon(Icons.email, color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 8),
                  SelectableText(
                    'Email: ${SubscriptionContactInfo.email}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Nota adicional
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Las renovaciones se procesan manualmente. Contacta al proveedor para activar tu suscripción.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        constraints: BoxConstraints(maxHeight: context.isMobile ? 400 : 500),
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

              // ✅ Contenido personalizado o el default
              if (customContent != null)
                customContent!
              else
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
  /// ✅ MODIFICADO: Muestra info de contacto y no redirige a ningún lado
  static void showSubscriptionExpired({
    String? customMessage,
    VoidCallback? onUpgradePressed,
    VoidCallback? onDismissed,
  }) {
    Get.dialog(
      Builder(
        builder: (context) => SubscriptionErrorDialog(
          title: 'Suscripción Expirada',
          message: customMessage ??
              'Tu período de prueba o suscripción ha expirado. Para continuar usando la aplicación, necesitas renovar tu suscripción.',
          actionText: 'Entendido',
          onActionPressed: () {
            Get.back();
            onDismissed?.call();
          },
          customContent: buildContactInfoWidget(context),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Muestra el diálogo de acceso denegado por suscripción
  /// ✅ MODIFICADO: Muestra info de contacto y no redirige
  static void showAccessDenied({
    String? customTitle,
    String? customMessage,
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    Get.dialog(
      Builder(
        builder: (context) => SubscriptionErrorDialog(
          title: customTitle ?? 'Acceso Restringido',
          message: customMessage ??
              'Esta funcionalidad requiere una suscripción activa. Contacta a tu proveedor para renovar.',
          actionText: actionText ?? 'Entendido',
          onActionPressed: onActionPressed ?? () => Get.back(),
          customContent: buildContactInfoWidget(context),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Muestra el diálogo de límite de usuarios alcanzado
  /// ✅ MODIFICADO: Muestra info de contacto y no redirige
  static void showUserLimitReached({
    int? maxUsers,
    VoidCallback? onUpgradePressed,
  }) {
    Get.dialog(
      Builder(
        builder: (context) => SubscriptionErrorDialog(
          title: 'Límite de Usuarios Alcanzado',
          message: maxUsers != null
              ? 'Has alcanzado el límite máximo de $maxUsers usuarios para tu plan actual. Contacta a tu proveedor para actualizar.'
              : 'Has alcanzado el límite máximo de usuarios para tu plan actual. Contacta a tu proveedor para actualizar.',
          actionText: 'Entendido',
          onActionPressed: () => Get.back(),
          customContent: buildContactInfoWidget(context),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
