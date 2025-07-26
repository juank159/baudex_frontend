// lib/app/shared/services/subscription_validation_service.dart
import 'package:get/get.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/settings/presentation/controllers/organization_controller.dart';
import '../../../app/core/errors/failures.dart';
import '../utils/subscription_error_handler.dart';

/// Servicio para validar suscripciones ANTES de hacer operaciones críticas
/// Esto evita que operaciones pasen si el backend no está validando correctamente
class SubscriptionValidationService {
  
  /// Valida si el usuario puede crear facturas
  static bool canCreateInvoice() {
    return _validateSubscriptionForAction('crear factura');
  }
  
  /// Valida si el usuario puede editar facturas
  static bool canUpdateInvoice() {
    return _validateSubscriptionForAction('editar factura');
  }
  
  /// Valida si el usuario puede crear productos
  static bool canCreateProduct() {
    return _validateSubscriptionForAction('crear producto');
  }
  
  /// Valida si el usuario puede editar productos
  static bool canUpdateProduct() {
    return _validateSubscriptionForAction('editar producto');
  }
  
  /// Valida si el usuario puede crear clientes
  static bool canCreateCustomer() {
    return _validateSubscriptionForAction('crear cliente');
  }
  
  /// Valida si el usuario puede editar clientes
  static bool canUpdateCustomer() {
    return _validateSubscriptionForAction('editar cliente');
  }
  
  /// Valida si el usuario puede agregar pagos
  static bool canAddPayment() {
    return _validateSubscriptionForAction('agregar pago');
  }
  
  /// Validación central de suscripción
  static bool _validateSubscriptionForAction(String context) {
    try {
      print('🔒 FRONTEND VALIDATION: Validando suscripción para: $context');
      
      // Verificar si tenemos controlador de organización
      if (!Get.isRegistered<OrganizationController>()) {
        print('⚠️ OrganizationController no registrado - permitiendo operación');
        return true; // Permitir si no hay controlador (evitar bloqueos)
      }
      
      final orgController = Get.find<OrganizationController>();
      final organization = orgController.currentOrganization;
      
      if (organization == null) {
        print('⚠️ No hay organización actual - permitiendo operación');
        return true; // Permitir si no hay organización
      }
      
      // Verificar estado de suscripción
      final subscriptionStatus = organization.subscriptionStatus?.name.toLowerCase();
      final isExpired = subscriptionStatus == 'expired' || 
                       subscriptionStatus == 'inactive' ||
                       subscriptionStatus == null;
      
      print('📋 Estado de suscripción actual:');
      print('   - Status: $subscriptionStatus');
      print('   - Plan: ${organization.subscriptionPlan?.name}');
      print('   - Expirada: $isExpired');
      
      if (isExpired) {
        print('🚫 FRONTEND VALIDATION: Suscripción expirada - BLOQUEANDO $context');
        
        // Mostrar diálogo de suscripción expirada
        SubscriptionErrorHandler.handleFailure(
          _createFakeFailure(context),
          context: context,
        );
        
        return false; // Bloquear operación
      }
      
      print('✅ FRONTEND VALIDATION: Suscripción válida - PERMITIENDO $context');
      return true; // Permitir operación
      
    } catch (e) {
      print('💥 Error en validación de suscripción: $e');
      // En caso de error, permitir la operación para no bloquear el sistema
      return true;
    }
  }
  
  /// Crear un failure falso para activar el SubscriptionErrorHandler
  static Failure _createFakeFailure(String context) {
    return ServerFailure(
      'Tu suscripción ha expirado. Para continuar con $context, necesitas renovar tu suscripción.',
      code: 403, // Código 403 para activar el handler
    );
  }
}