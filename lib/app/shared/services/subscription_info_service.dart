// lib/app/shared/services/subscription_info_service.dart
import 'package:get/get.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/settings/presentation/controllers/organization_controller.dart';

/// Service para obtener información dinámica de suscripción del usuario
class SubscriptionInfoService {
  /// Obtiene información del plan actual del usuario
  static Map<String, dynamic> getCurrentSubscriptionInfo() {
    try {
      // Obtener datos del controlador de organización
      if (Get.isRegistered<OrganizationController>()) {
        final orgController = Get.find<OrganizationController>();
        final organization = orgController.currentOrganization;

        if (organization != null) {
          final subscriptionPlan =
              organization.subscriptionPlan?.name.toLowerCase() ?? 'trial';
          final subscriptionStatus =
              organization.subscriptionStatus?.name.toLowerCase() ?? 'expired';

          return {
            'plan': subscriptionPlan,
            'status': subscriptionStatus,
            'planDisplayName': _getPlanDisplayName(subscriptionPlan),
            'contactInfo': _getContactInfo(),
            'isExpired':
                subscriptionStatus == 'expired' ||
                subscriptionStatus == 'inactive',
          };
        }
      }

      // Fallback si no hay información disponible
      return {
        'plan': 'trial',
        'status': 'expired',
        'planDisplayName': 'Plan de Prueba',
        'contactInfo': _getContactInfo(),
        'isExpired': true,
      };
    } catch (e) {
      print(
        '⚠️ SubscriptionInfoService: Error obteniendo info de suscripción: $e',
      );
      return {
        'plan': 'trial',
        'status': 'expired',
        'planDisplayName': 'Plan de Prueba',
        'contactInfo': _getContactInfo(),
        'isExpired': true,
      };
    }
  }

  /// Genera mensaje personalizado basado en el plan y contexto
  static String getContextualMessage(String? context) {
    final info = getCurrentSubscriptionInfo();
    final planName = info['planDisplayName'] as String;
    final contactInfo = info['contactInfo'] as Map<String, String>;

    final baseMessage = _getBaseMessage(context, planName);
    final contactMessage = _getContactMessage(contactInfo);

    return '$baseMessage\n\n$contactMessage';
  }

  /// Mensaje base según el contexto y plan
  static String _getBaseMessage(String? context, String planName) {
    if (context == null) {
      return 'Tu $planName ha expirado. Para continuar usando todas las funcionalidades, necesitas renovar tu suscripción.';
    }

    final contextMessages = {
      'crear producto':
          'Tu $planName ha expirado. Para continuar creando productos, necesitas renovar tu suscripción.',
      'editar producto':
          'Tu $planName ha expirado. Para continuar editando productos, necesitas renovar tu suscripción.',
      'eliminar producto':
          'Tu $planName ha expirado. Para continuar eliminando productos, necesitas renovar tu suscripción.',

      'crear cliente':
          'Tu $planName ha expirado. Para continuar creando clientes, necesitas renovar tu suscripción.',
      'editar cliente':
          'Tu $planName ha expirado. Para continuar editando clientes, necesitas renovar tu suscripción.',
      'eliminar cliente':
          'Tu $planName ha expirado. Para continuar eliminando clientes, necesitas renovar tu suscripción.',

      'crear factura':
          'Tu $planName ha expirado. Para continuar creando facturas, necesitas renovar tu suscripción.',
      'editar factura':
          'Tu $planName ha expirado. Para continuar editando facturas, necesitas renovar tu suscripción.',
      'eliminar factura':
          'Tu $planName ha expirado. Para continuar eliminando facturas, necesitas renovar tu suscripción.',
      'agregar pago':
          'Tu $planName ha expirado. Para continuar agregando pagos a facturas, necesitas renovar tu suscripción.',
      'procesar pago':
          'Tu $planName ha expirado. Para continuar procesando pagos, necesitas renovar tu suscripción.',

      'crear gasto':
          'Tu $planName ha expirado. Para continuar creando gastos, necesitas renovar tu suscripción.',
      'editar gasto':
          'Tu $planName ha expirado. Para continuar editando gastos, necesitas renovar tu suscripción.',
      'eliminar gasto':
          'Tu $planName ha expirado. Para continuar eliminando gastos, necesitas renovar tu suscripción.',

      'crear categoría':
          'Tu $planName ha expirado. Para continuar creando categorías, necesitas renovar tu suscripción.',
      'editar categoría':
          'Tu $planName ha expirado. Para continuar editando categorías, necesitas renovar tu suscripción.',
      'eliminar categoría':
          'Tu $planName ha expirado. Para continuar eliminando categorías, necesitas renovar tu suscripción.',

      'crear usuario':
          'Tu $planName ha expirado. Para continuar creando usuarios, necesitas renovar tu suscripción.',
      'editar usuario':
          'Tu $planName ha expirado. Para continuar editando usuarios, necesitas renovar tu suscripción.',
      'eliminar usuario':
          'Tu $planName ha expirado. Para continuar eliminando usuarios, necesitas renovar tu suscripción.',
    };

    return contextMessages[context.toLowerCase()] ??
        'Tu $planName ha expirado. Para continuar con $context, necesitas renovar tu suscripción.';
  }

  /// Mensaje de contacto para renovación
  static String _getContactMessage(Map<String, String> contactInfo) {
    return 'Para renovar tu suscripción, contacta a nuestro equipo de ventas:\n\n' +
        '📞 ${contactInfo['phone']}\n' +
        '📧 ${contactInfo['email']}\n' +
        '💬 ${contactInfo['whatsapp']}';
  }

  /// Obtiene nombre display del plan
  static String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case 'trial':
        return 'Plan de Prueba';
      case 'basic':
        return 'Plan Básico';
      case 'premium':
        return 'Plan Premium';
      case 'enterprise':
        return 'Plan Empresarial';
      default:
        return 'Plan de Prueba';
    }
  }

  /// Información de contacto para renovación
  static Map<String, String> _getContactInfo() {
    return {
      'phone': '+57 313 844 8436',
      'email': 'baudexgrouop@gmail.com',
      'whatsapp': 'WhatsApp: +57 313 844 8436',
    };
  }
}
