// lib/app/shared/utils/subscription_error_handler.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/core/errors/failures.dart';
import '../widgets/subscription_error_dialog.dart';
import '../services/subscription_info_service.dart';

/// Utility class para manejar errores de suscripción de forma global
class SubscriptionErrorHandler {

  /// Maneja un failure y determina si debe mostrar el diálogo de suscripción
  /// Retorna true si manejó el error, false si debe usar el manejo normal
  static bool handleFailure(
    Failure failure, {
    String? customMessage,
    VoidCallback? onUpgradePressed,
    String? context, // e.g., "crear producto", "editar cliente", etc.
  }) {
    print('🔍 SubscriptionErrorHandler: Analizando failure...');
    print('   Type: ${failure.runtimeType}');
    print('   Message: ${failure.message}');
    print('   Code: ${failure.code}');
    print('   Context: $context');

    // 🔒 DETECTAR ERROR DE SUSCRIPCIÓN (por tipo o código 403)
    final isSubscriptionError = failure is SubscriptionFailure || failure.code == 403;

    if (isSubscriptionError) {
      print('✅ SUBSCRIPTION ERROR DETECTED - Showing professional dialog');

      // Obtener información dinámica de suscripción
      final subscriptionInfo = SubscriptionInfoService.getCurrentSubscriptionInfo();
      print('📋 Subscription info: $subscriptionInfo');

      // Usar el mensaje del failure si es SubscriptionFailure, sino usar el contextual
      String message;
      if (failure is SubscriptionFailure) {
        message = customMessage ?? failure.message;
      } else {
        message = customMessage ?? SubscriptionInfoService.getContextualMessage(context);
      }

      SubscriptionErrorDialog.showSubscriptionExpired(
        customMessage: message,
        onUpgradePressed: onUpgradePressed ?? () {
          Get.toNamed('/settings/subscription');
        },
      );

      return true; // Error manejado
    }

    print('⚠️ NON-SUBSCRIPTION ERROR - Not handled by SubscriptionErrorHandler');
    return false; // No es error de suscripción, usar manejo normal
  }

}