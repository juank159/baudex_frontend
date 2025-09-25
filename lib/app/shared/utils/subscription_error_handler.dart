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

    // 🔒 DETECTAR ERROR DE SUSCRIPCIÓN (403)
    if (failure.code == 403) {
      print('✅ SUBSCRIPTION ERROR DETECTED - Showing professional dialog');
      
      // Obtener información dinámica de suscripción
      final subscriptionInfo = SubscriptionInfoService.getCurrentSubscriptionInfo();
      print('📋 Subscription info: $subscriptionInfo');
      
      // Mensaje personalizado basado en el contexto y plan del usuario
      final message = customMessage ?? SubscriptionInfoService.getContextualMessage(context);
      
      SubscriptionErrorDialog.showSubscriptionExpired(
        customMessage: message,
        onUpgradePressed: onUpgradePressed ?? () {
          Get.toNamed('/settings/organization');
        },
      );
      
      return true; // Error manejado
    }

    print('⚠️ NON-SUBSCRIPTION ERROR - Not handled by SubscriptionErrorHandler');
    return false; // No es error de suscripción, usar manejo normal
  }

}