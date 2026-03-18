// lib/app/shared/services/subscription_validation_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../features/settings/presentation/controllers/organization_controller.dart';
import '../../../features/settings/data/models/isar/isar_organization.dart';
import '../../../features/subscriptions/data/models/isar/isar_subscription.dart';
import '../../../features/subscriptions/presentation/controllers/subscription_controller.dart';
import '../../../app/core/network/network_info.dart';
import '../../../app/data/local/isar_database.dart';
import '../widgets/subscription_error_dialog.dart';

/// Servicio para validar suscripciones ANTES de hacer operaciones críticas.
///
/// IMPORTANTE: Este servicio valida suscripciones tanto ONLINE como OFFLINE.
/// - ONLINE: Usa datos del OrganizationController (actualizados del servidor)
/// - OFFLINE: Usa datos cacheados en ISAR (IsarOrganization)
///
/// La validación se basa en FECHAS REALES, no en snapshots booleanos.
class SubscriptionValidationService {
  /// Días antes del vencimiento para mostrar advertencia
  static const int _warningDaysBeforeExpiration = 7;

  // ==================== MÉTODOS PÚBLICOS ASYNC ====================

  /// Valida si el usuario puede crear facturas (ASYNC - usa para validación real)
  static Future<bool> canCreateInvoiceAsync() async {
    return _validateSubscriptionAsync('crear factura');
  }

  /// Valida si el usuario puede editar facturas (ASYNC)
  static Future<bool> canUpdateInvoiceAsync() async {
    return _validateSubscriptionAsync('editar factura');
  }

  /// Valida si el usuario puede crear productos (ASYNC)
  static Future<bool> canCreateProductAsync() async {
    return _validateSubscriptionAsync('crear producto');
  }

  /// Valida si el usuario puede editar productos (ASYNC)
  static Future<bool> canUpdateProductAsync() async {
    return _validateSubscriptionAsync('editar producto');
  }

  /// Valida si el usuario puede crear clientes (ASYNC)
  static Future<bool> canCreateCustomerAsync() async {
    return _validateSubscriptionAsync('crear cliente');
  }

  /// Valida si el usuario puede editar clientes (ASYNC)
  static Future<bool> canUpdateCustomerAsync() async {
    return _validateSubscriptionAsync('editar cliente');
  }

  /// Valida si el usuario puede agregar pagos (ASYNC)
  static Future<bool> canAddPaymentAsync() async {
    return _validateSubscriptionAsync('agregar pago');
  }

  // ==================== MÉTODOS PÚBLICOS SYNC (COMPATIBILIDAD) ====================
  // Nota: Estos métodos usan datos en memoria. Para validación completa, usar versiones Async.

  /// Valida si el usuario puede crear facturas (sync - usa memoria)
  static bool canCreateInvoice() {
    return _validateSubscriptionSync('crear factura');
  }

  /// Valida si el usuario puede editar facturas
  static bool canUpdateInvoice() {
    return _validateSubscriptionSync('editar factura');
  }

  /// Valida si el usuario puede crear productos
  static bool canCreateProduct() {
    return _validateSubscriptionSync('crear producto');
  }

  /// Valida si el usuario puede editar productos
  static bool canUpdateProduct() {
    return _validateSubscriptionSync('editar producto');
  }

  /// Valida si el usuario puede crear clientes
  static bool canCreateCustomer() {
    return _validateSubscriptionSync('crear cliente');
  }

  /// Valida si el usuario puede editar clientes
  static bool canUpdateCustomer() {
    return _validateSubscriptionSync('editar cliente');
  }

  /// Valida si el usuario puede agregar pagos
  static bool canAddPayment() {
    return _validateSubscriptionSync('agregar pago');
  }

  // ==================== VALIDACIÓN PRINCIPAL ASYNC ====================

  /// Validación ASYNC completa - consulta ISAR si es necesario
  static Future<bool> _validateSubscriptionAsync(String context) async {
    try {
      print('🔒 SUBSCRIPTION VALIDATION [ASYNC]: Validando para: $context');

      // PASO 1: Intentar obtener datos del OrganizationController (memoria)
      SubscriptionData? subscriptionData = _getSubscriptionFromController();

      // PASO 2: Si no hay datos en memoria, consultar ISAR
      if (subscriptionData == null) {
        print('📴 No hay datos en memoria, consultando ISAR...');
        subscriptionData = await _getSubscriptionFromIsar();
      }

      // PASO 3: Si no hay datos en ningún lado
      if (subscriptionData == null) {
        print('❌ No hay datos de suscripción disponibles');
        _showNoSubscriptionDataDialog(context);
        return false;
      }

      // PASO 4: Validar la suscripción
      return _validateSubscriptionData(subscriptionData, context);
    } catch (e) {
      print('💥 Error en validación async: $e');
      // En caso de error, bloquear por seguridad
      _showValidationErrorDialog(context, e.toString());
      return false;
    }
  }

  /// Validación SYNC - solo usa datos en memoria
  static bool _validateSubscriptionSync(String context) {
    try {
      print('🔒 SUBSCRIPTION VALIDATION [SYNC]: Validando para: $context');

      // Solo usar datos del OrganizationController
      final subscriptionData = _getSubscriptionFromController();

      if (subscriptionData == null) {
        print('⚠️ No hay datos en memoria');
        // Para sync, si no hay datos y parece estar offline, bloquear
        final isOnline = _isOnlineSync();
        if (!isOnline) {
          print('🚫 OFFLINE sin datos - bloqueando');
          _showNoSubscriptionDataDialog(context);
          return false;
        }
        // Si está online pero no hay datos, permitir (backend validará)
        print('🌐 ONLINE sin datos - permitiendo (backend validará)');
        return true;
      }

      return _validateSubscriptionData(subscriptionData, context);
    } catch (e) {
      print('💥 Error en validación sync: $e');
      return false;
    }
  }

  // ==================== OBTENCIÓN DE DATOS ====================

  /// Obtener datos de suscripción del OrganizationController (memoria)
  static SubscriptionData? _getSubscriptionFromController() {
    try {
      if (!Get.isRegistered<OrganizationController>()) {
        print('⚠️ OrganizationController no registrado');
        return null;
      }

      final orgController = Get.find<OrganizationController>();
      final organization = orgController.currentOrganization;

      if (organization == null) {
        print('⚠️ No hay organización en el controlador');
        return null;
      }

      print('✅ Datos obtenidos del OrganizationController');
      return SubscriptionData(
        status: organization.subscriptionStatus.name.toLowerCase(),
        endDate: organization.subscriptionEndDate,
        trialEndDate: organization.trialEndDate,
        hasValidSubscription: organization.hasValidSubscription ?? false,
        isTrialExpired: organization.isTrialExpired ?? false,
        planName: organization.subscriptionPlan.name,
        source: 'controller',
      );
    } catch (e) {
      print('⚠️ Error obteniendo datos del controlador: $e');
      return null;
    }
  }

  /// Obtener datos de suscripción de ISAR (cache local)
  /// Busca PRIMERO en IsarSubscription (más completo) y luego fallback a IsarOrganization
  static Future<SubscriptionData?> _getSubscriptionFromIsar() async {
    try {
      final Isar isar;
      try {
        isar = IsarDatabase.instance.database;
      } catch (e) {
        print('⚠️ ISAR no disponible: $e');
        return null;
      }

      // PASO 1: Buscar en IsarSubscription (fuente más completa y precisa)
      final isarSub = await isar.isarSubscriptions.where().findFirst();
      if (isarSub != null) {
        print('✅ Datos obtenidos de IsarSubscription (cache completo)');
        print('   - Status: ${isarSub.status}');
        print('   - End Date: ${isarSub.endDate}');
        print('   - Plan: ${isarSub.plan}');
        print('   - Last Sync: ${isarSub.lastSyncAt}');

        return SubscriptionData(
          status: isarSub.status.name.toLowerCase(),
          endDate: isarSub.endDate,
          trialEndDate: isarSub.trialEndsAt,
          hasValidSubscription: isarSub.isActive && !isarSub.isExpired,
          isTrialExpired: isarSub.isTrial && isarSub.isExpired,
          planName: isarSub.plan.name.toLowerCase(),
          source: 'isar_subscription',
          lastSyncAt: isarSub.lastSyncAt,
        );
      }

      // PASO 2: Fallback a IsarOrganization (datos básicos de suscripción)
      final isarOrg = await isar.isarOrganizations
          .filter()
          .deletedAtIsNull()
          .findFirst();

      if (isarOrg == null) {
        print('⚠️ No hay datos de suscripción en ISAR');
        return null;
      }

      print('✅ Datos obtenidos de IsarOrganization (fallback)');
      print('   - Status: ${isarOrg.subscriptionStatus}');
      print('   - End Date: ${isarOrg.subscriptionEndDate}');

      return SubscriptionData(
        status: isarOrg.subscriptionStatus.name.toLowerCase(),
        endDate: isarOrg.subscriptionEndDate,
        trialEndDate: isarOrg.trialEndDate,
        hasValidSubscription: isarOrg.hasValidSubscription ?? false,
        isTrialExpired: isarOrg.isTrialExpired ?? false,
        planName: isarOrg.subscriptionPlan.name.toLowerCase(),
        source: 'isar',
        lastSyncAt: isarOrg.lastSyncAt,
      );
    } catch (e) {
      print('⚠️ Error obteniendo datos de ISAR: $e');
      return null;
    }
  }

  // ==================== VALIDACIÓN DE DATOS ====================

  /// Validar datos de suscripción
  static bool _validateSubscriptionData(SubscriptionData data, String context) {
    print('📋 Validando suscripción:');
    print('   - Fuente: ${data.source}');
    print('   - Status: ${data.status}');
    print('   - Plan: ${data.planName}');
    print('   - End Date: ${data.endDate}');
    print('   - Trial End: ${data.trialEndDate}');
    print('   - Has Valid: ${data.hasValidSubscription}');
    print('   - Trial Expired: ${data.isTrialExpired}');
    if (data.lastSyncAt != null) {
      print('   - Last Sync: ${data.lastSyncAt}');
    }

    // VALIDACIÓN 1: Estado de suscripción inválido
    final invalidStatuses = ['expired', 'inactive', 'cancelled', 'suspended'];
    if (invalidStatuses.contains(data.status)) {
      print('🚫 Status inválido: ${data.status}');
      _showExpiredDialog(context, data.status == 'expired' || data.isTrialExpired);
      return false;
    }

    // VALIDACIÓN 2: Fecha de expiración (MÁS IMPORTANTE)
    final now = DateTime.now();

    // Verificar fecha de suscripción
    if (data.endDate != null) {
      if (now.isAfter(data.endDate!)) {
        print('🚫 Suscripción vencida por fecha: ${data.endDate}');
        _showExpiredDialog(context, false);
        return false;
      }
    }

    // Verificar fecha de trial
    if (data.trialEndDate != null && data.status == 'trial') {
      if (now.isAfter(data.trialEndDate!)) {
        print('🚫 Trial vencido por fecha: ${data.trialEndDate}');
        _showExpiredDialog(context, true);
        return false;
      }
    }

    // VALIDACIÓN 3: Campos booleanos del servidor (respaldo)
    if (data.isTrialExpired && data.status == 'trial') {
      print('🚫 Trial marcado como expirado');
      _showExpiredDialog(context, true);
      return false;
    }

    if (!data.hasValidSubscription && data.status != 'trial' && data.status != 'active') {
      print('🚫 Suscripción marcada como inválida');
      _showExpiredDialog(context, false);
      return false;
    }

    // VALIDACIÓN 4: Verificar si el cache es muy antiguo (opcional, para datos de ISAR)
    if (data.source == 'isar' && data.lastSyncAt != null) {
      final daysSinceSync = now.difference(data.lastSyncAt!).inDays;
      if (daysSinceSync > 30) {
        print('⚠️ Cache muy antiguo: $daysSinceSync días');
        // No bloquear, pero advertir
        _showOldCacheWarning(daysSinceSync);
      }
    }

    // Mostrar advertencia si está por vencer
    _showExpirationWarningIfNeeded(data);

    print('✅ SUBSCRIPTION VALIDATION: Suscripción válida - PERMITIENDO $context');
    return true;
  }

  // ==================== DIÁLOGOS Y MENSAJES ====================

  /// Mostrar diálogo de suscripción expirada (usa el diálogo profesional)
  static void _showExpiredDialog(String context, bool isTrial) {
    final message = isTrial
        ? 'Tu período de prueba ha expirado. Para continuar usando la aplicación y $context, necesitas activar una suscripción.'
        : 'Tu suscripción ha vencido. Para continuar usando la aplicación y $context, necesitas renovar tu suscripción.';

    // Usar el diálogo profesional de suscripción
    SubscriptionErrorDialog.showSubscriptionExpired(
      customMessage: message,
    );
  }

  /// Mostrar diálogo cuando no hay datos de suscripción (usa el diálogo profesional)
  static void _showNoSubscriptionDataDialog(String context) {
    SubscriptionErrorDialog.showAccessDenied(
      customTitle: 'Sin datos de suscripción',
      customMessage: 'No se puede verificar tu suscripción en este momento. Para $context, necesitas conexión a internet al menos una vez para validar tu suscripción.\n\nConéctate a internet e intenta de nuevo.',
      actionText: 'Reintentar',
      onActionPressed: () {
        Get.back();
        if (Get.isRegistered<SubscriptionController>()) {
          Get.find<SubscriptionController>().loadSubscription();
        }
      },
    );
  }

  /// Mostrar diálogo de error de validación (usa el diálogo profesional)
  static void _showValidationErrorDialog(String context, String error) {
    SubscriptionErrorDialog.showAccessDenied(
      customTitle: 'Error de validación',
      customMessage: 'Ocurrió un error al validar tu suscripción para $context.\n\nPor favor, intenta de nuevo.',
      actionText: 'Entendido',
      onActionPressed: () => Get.back(),
    );
  }

  /// Mostrar advertencia de cache antiguo
  static void _showOldCacheWarning(int days) {
    Get.snackbar(
      'Datos desactualizados',
      'Los datos de suscripción tienen $days días. Conéctate a internet para actualizar.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade800,
      icon: Icon(Icons.sync_problem, color: Colors.orange.shade700),
      duration: const Duration(seconds: 5),
    );
  }

  /// Mostrar notificación del estado de la suscripción al iniciar
  /// ✅ MEJORADO: Muestra diálogos profesionales que el usuario debe confirmar
  /// Funciona tanto ONLINE como OFFLINE
  static void _showExpirationWarningIfNeeded(SubscriptionData data) {
    print('🔔 SUBSCRIPTION DIALOG: Evaluando estado de suscripción...');
    print('   - Fuente: ${data.source}');
    print('   - Status: ${data.status}');
    print('   - End Date: ${data.endDate}');
    print('   - Is Expired (calculated): ${data.isExpired}');

    // PASO 1: Verificar si ya está vencida por el getter isExpired
    if (data.isExpired) {
      print('🔴 SUBSCRIPTION: VENCIDA - Mostrando diálogo de expirado');
      _showExpiredStatusDialog();
      return;
    }

    // PASO 2: Verificar días hasta expiración
    if (data.endDate == null) {
      print('⚠️ SUBSCRIPTION: No hay fecha de expiración, no se muestra diálogo');
      return;
    }

    final now = DateTime.now();
    final daysUntilExpiration = data.endDate!.difference(now).inDays;
    print('   - Días hasta expiración: $daysUntilExpiration');

    // PASO 3: Si ya venció (días negativos o 0)
    if (daysUntilExpiration <= 0) {
      print('🔴 SUBSCRIPTION: VENCIDA (días <= 0) - Mostrando diálogo de expirado');
      _showExpiredStatusDialog();
      return;
    }

    // PASO 4: Si está por vencer (dentro de los próximos 7 días)
    if (daysUntilExpiration <= _warningDaysBeforeExpiration) {
      print('🟡 SUBSCRIPTION: POR VENCER en $daysUntilExpiration días - Mostrando diálogo de advertencia');
      _showExpiringDialog(daysUntilExpiration);
      return;
    }

    // PASO 5: Si tiene más de 7 días, no mostrar nada
    print('🟢 SUBSCRIPTION: Válida por $daysUntilExpiration días - No se muestra diálogo');
  }

  /// ✅ Widget reutilizable con información de contacto
  static Widget _buildContactInfoWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: Colors.green.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                'Contacta para renovar:',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.chat, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 8),
              SelectableText(
                'WhatsApp: ${SubscriptionContactInfo.whatsappDisplay}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 8),
              SelectableText(
                'Teléfono: ${SubscriptionContactInfo.phoneDisplay}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 8),
              SelectableText(
                'Email: ${SubscriptionContactInfo.email}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ✅ Diálogo para suscripción VENCIDA (al iniciar la app)
  static void _showExpiredStatusDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.error_outline, color: Colors.red.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Suscripción Vencida',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu suscripción ha expirado.',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Para continuar usando todas las funcionalidades de la aplicación, necesitas renovar tu suscripción.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactInfoWidget(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Las renovaciones se procesan manualmente. Contacta al proveedor.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
      barrierDismissible: false,
    );
  }

  /// ✅ Diálogo para suscripción POR VENCER
  static void _showExpiringDialog(int daysRemaining) {
    final bool isCritical = daysRemaining <= 3;
    final bool isLastDay = daysRemaining == 1;

    final String title;
    final String subtitle;
    final Color primaryColor;
    final IconData icon;

    if (isLastDay) {
      title = '¡Atención Urgente!';
      subtitle = '¡ÚLTIMO DÍA! Tu suscripción vence HOY.';
      primaryColor = Colors.deepOrange;
      icon = Icons.warning_amber_rounded;
    } else if (isCritical) {
      title = '¡Atención Urgente!';
      subtitle = '¡Solo te quedan $daysRemaining días!';
      primaryColor = Colors.deepOrange;
      icon = Icons.warning_amber_rounded;
    } else {
      title = 'Aviso de Suscripción';
      subtitle = 'Tu suscripción vence en $daysRemaining días.';
      primaryColor = Colors.amber.shade700;
      icon = Icons.access_time;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCritical ? Colors.orange.shade100 : Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCritical ? Colors.orange.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCritical ? Colors.orange.shade300 : Colors.amber.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCritical ? Icons.timer : Icons.calendar_today,
                    color: primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: isCritical ? Colors.deepOrange.shade800 : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isCritical
                  ? 'Tu suscripción está por vencer. Renueva inmediatamente para evitar perder el acceso a la aplicación.'
                  : 'Te recomendamos renovar tu suscripción antes de que expire para no perder acceso a las funcionalidades.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactInfoWidget(),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      ),
      barrierDismissible: false,
    );
  }

  // ==================== UTILIDADES ====================

  /// Verificar si hay conexión (sync)
  static bool _isOnlineSync() {
    try {
      if (Get.isRegistered<NetworkInfo>()) {
        final networkInfo = Get.find<NetworkInfo>();
        return networkInfo.isServerReachable;
      }
      return true; // Asumir online si no hay NetworkInfo
    } catch (e) {
      return true;
    }
  }

  /// Obtener días hasta expiración
  static int? getDaysUntilExpiration() {
    final data = _getSubscriptionFromController();
    if (data?.endDate == null) return null;
    return data!.endDate!.difference(DateTime.now()).inDays;
  }

  /// Verificar si debe mostrar advertencia
  static bool shouldShowExpirationWarning() {
    final days = getDaysUntilExpiration();
    if (days == null) return false;
    return days > 0 && days <= _warningDaysBeforeExpiration;
  }

  /// Obtener información de suscripción
  static SubscriptionData? getSubscriptionInfo() {
    return _getSubscriptionFromController();
  }

  /// Obtener información de suscripción (async, incluye ISAR)
  static Future<SubscriptionData?> getSubscriptionInfoAsync() async {
    var data = _getSubscriptionFromController();
    if (data == null) {
      data = await _getSubscriptionFromIsar();
    }
    return data;
  }

  /// Mostrar advertencia de expiración si la suscripción está por vencer (público)
  /// Usa datos en memoria del OrganizationController
  static void showExpirationWarningIfNeeded() {
    print('🔔 showExpirationWarningIfNeeded (SYNC) llamado');
    final data = _getSubscriptionFromController();
    if (data != null) {
      _showExpirationWarningIfNeeded(data);
    } else {
      print('⚠️ No hay datos de suscripción en memoria');
    }
  }

  /// Mostrar advertencia de expiración si la suscripción está por vencer (async)
  /// ✅ IMPORTANTE: Consulta ISAR si no hay datos en memoria
  /// Funciona tanto ONLINE como OFFLINE
  static Future<void> showExpirationWarningIfNeededAsync() async {
    print('🔔 showExpirationWarningIfNeededAsync (ASYNC) llamado');

    // PASO 1: Intentar obtener datos del OrganizationController (memoria)
    var data = _getSubscriptionFromController();

    if (data != null) {
      print('✅ Datos obtenidos de OrganizationController (memoria)');
    } else {
      print('⚠️ No hay datos en memoria, consultando ISAR...');
      // PASO 2: Si no hay en memoria, consultar ISAR (cache local)
      data = await _getSubscriptionFromIsar();

      if (data != null) {
        print('✅ Datos obtenidos de ISAR (cache local)');
      } else {
        print('❌ No hay datos de suscripción disponibles (ni memoria ni ISAR)');
        return;
      }
    }

    // PASO 3: Mostrar snackbar según el estado
    _showExpirationWarningIfNeeded(data);
  }
}

/// Clase para almacenar datos de suscripción
class SubscriptionData {
  final String status;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final bool hasValidSubscription;
  final bool isTrialExpired;
  final String planName;
  final String source; // 'controller' o 'isar'
  final DateTime? lastSyncAt;

  SubscriptionData({
    required this.status,
    this.endDate,
    this.trialEndDate,
    required this.hasValidSubscription,
    required this.isTrialExpired,
    required this.planName,
    required this.source,
    this.lastSyncAt,
  });

  bool get isExpired {
    // Verificar por estado
    if (status == 'expired' || status == 'inactive' ||
        status == 'cancelled' || status == 'suspended') {
      return true;
    }

    // Verificar por fecha
    final now = DateTime.now();
    if (endDate != null && now.isAfter(endDate!)) {
      return true;
    }
    if (trialEndDate != null && status == 'trial' && now.isAfter(trialEndDate!)) {
      return true;
    }

    // Verificar flags del servidor
    if (isTrialExpired && status == 'trial') {
      return true;
    }
    if (!hasValidSubscription && status != 'trial' && status != 'active') {
      return true;
    }

    return false;
  }

  int? get daysUntilExpiration {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }

  @override
  String toString() {
    return 'SubscriptionData(status: $status, endDate: $endDate, source: $source, isExpired: $isExpired)';
  }
}
