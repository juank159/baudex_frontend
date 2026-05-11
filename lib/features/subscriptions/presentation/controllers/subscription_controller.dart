// lib/features/subscriptions/presentation/controllers/subscription_controller.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/network/network_info.dart';
import '../../../../app/data/local/sync_service.dart';
import '../../../../app/shared/services/subscription_alert_service.dart';
import '../../../../app/shared/widgets/subscription_error_dialog.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_enums.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/entities/action_validation.dart';
import '../../domain/entities/plan_limits.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Tipo de diálogo de suscripción pendiente
enum _SubscriptionDialogType {
  expired,
  critical,
  warning,
  trial,
}

/// Mapeo `_SubscriptionDialogType` → `SubscriptionAlertLevel` para
/// consultar el servicio de throttling central. `trial` se trata como
/// `warning` porque también es un aviso preventivo de "queda poco".
SubscriptionAlertLevel _dialogTypeToAlertLevel(_SubscriptionDialogType t) {
  switch (t) {
    case _SubscriptionDialogType.expired:
      return SubscriptionAlertLevel.expired;
    case _SubscriptionDialogType.critical:
      return SubscriptionAlertLevel.critical;
    case _SubscriptionDialogType.warning:
    case _SubscriptionDialogType.trial:
      return SubscriptionAlertLevel.warning;
  }
}

class SubscriptionController extends GetxController {
  final SubscriptionRepository repository;
  final NetworkInfo? networkInfo;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SubscriptionController({
    required this.repository,
    this.networkInfo,
  });

  // ==================== ESTADO REACTIVO ====================

  final _subscription = Rxn<Subscription>();
  final _limits = Rxn<PlanLimits>();
  final _usage = Rxn<SubscriptionUsage>();
  final _isLoading = false.obs;
  final _isOfflineMode = false.obs;
  final _error = Rxn<String>();
  final _wasExpiredWhileOffline = false.obs;

  // ✅ Flag para mostrar diálogo DESPUÉS de que el Dashboard esté listo
  final _pendingSubscriptionDialog = Rxn<_SubscriptionDialogType>();
  final _pendingDialogDays = 0.obs;
  bool _dialogShown = false; // Para evitar mostrar múltiples veces

  // Getters
  Subscription? get subscription => _subscription.value;
  PlanLimits? get limits => _limits.value ?? subscription?.limits;
  SubscriptionUsage? get usage => _usage.value;
  bool get isLoading => _isLoading.value;
  bool get isOfflineMode => _isOfflineMode.value;
  String? get error => _error.value;
  bool get wasExpiredWhileOffline => _wasExpiredWhileOffline.value;

  // Estado de suscripcion
  bool get hasSubscription => subscription != null;
  bool get isActive => subscription?.isActive ?? false;
  bool get isExpired => subscription?.isExpired ?? false;
  bool get isTrial => subscription?.isTrial ?? false;
  SubscriptionPlan get currentPlan =>
      subscription?.plan ?? SubscriptionPlan.trial;
  int get daysUntilExpiration => subscription?.daysUntilExpiration ?? 0;
  SubscriptionAlertLevel get alertLevel =>
      subscription?.alertLevel ?? SubscriptionAlertLevel.normal;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _initializeSubscription();
    _listenToNetworkChanges();
  }

  Future<void> _initializeSubscription() async {
    await loadSubscription();
  }

  void _listenToNetworkChanges() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final connected = results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.ethernet);

        final wasOffline = _isOfflineMode.value;
        _isOfflineMode.value = !connected;

        if (connected && wasOffline) {
          // Recargar suscripcion del servidor al reconectar
          print('🔄 SubscriptionController: Reconectado - refrescando suscripción');
          loadSubscription();
        }

        if (connected && _wasExpiredWhileOffline.value) {
          _handleReconnectAfterOfflineExpiration();
        }
      },
    );
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  // ==================== CARGA DE DATOS ====================

  Future<void> loadSubscription() async {
    _isLoading.value = true;
    _error.value = null;

    // Resetear flag para permitir nuevo diálogo si el estado cambió
    _dialogShown = false;

    final result = await repository.getCurrentSubscription();

    result.fold(
      (failure) {
        _error.value = failure.message;
        // Intentar cargar del cache
        _loadFromCache();
      },
      (subscription) {
        _subscription.value = subscription;
        _limits.value = subscription.limits;
        _checkSubscriptionStatus();
      },
    );

    _isLoading.value = false;
  }

  Future<void> _loadFromCache() async {
    final cacheResult = await repository.getCachedSubscription();
    cacheResult.fold(
      (failure) {
        // No hay cache, crear trial por defecto
        _subscription.value = Subscription.defaultTrial('');
        _limits.value = PlanLimits.trial;
      },
      (subscription) {
        _subscription.value = subscription;
        _limits.value = subscription.limits;
      },
    );

    // ✅ También verificar estado cuando se carga del cache (offline)
    _checkSubscriptionStatus();
  }

  Future<void> loadUsage({
    int products = 0,
    int customers = 0,
    int users = 0,
    int invoicesThisMonth = 0,
    int expensesThisMonth = 0,
    int storageMB = 0,
  }) async {
    final result = await repository.getSubscriptionUsage(
      products: products,
      customers: customers,
      users: users,
      invoicesThisMonth: invoicesThisMonth,
      expensesThisMonth: expensesThisMonth,
      storageMB: storageMB,
    );

    result.fold(
      (failure) => _error.value = failure.message,
      (usage) => _usage.value = usage,
    );
  }

  Future<void> refreshSubscription() async {
    await loadSubscription();

    // Verificar si expiro mientras estaba offline
    final wasExpired = await repository.isCachedSubscriptionExpired();
    if (wasExpired && !isOfflineMode) {
      _wasExpiredWhileOffline.value = true;
    }
  }

  // ==================== VALIDACION DE ACCIONES ====================

  /// Validar si una accion esta permitida
  Future<ActionValidation> validateAction(
    String action, {
    int? currentUsage,
  }) async {
    final result = await repository.validateAction(
      action,
      currentUsage: currentUsage,
    );

    return result.fold(
      (failure) => ActionValidation.noSubscription(),
      (validation) => validation,
    );
  }

  /// Verificar si una accion esta permitida (sincrono, usa cache)
  bool canPerformAction(String action) {
    if (subscription == null) return false;
    return subscription!.canPerformAction(action);
  }

  /// Verificar si una feature esta disponible
  bool isFeatureAvailable(String feature) {
    if (limits == null) return false;
    return limits!.features.isFeatureEnabled(feature);
  }

  /// Verificar si puede agregar un recurso
  bool canAddProduct(int currentCount) =>
      limits?.canAddProduct(currentCount) ?? false;

  bool canAddCustomer(int currentCount) =>
      limits?.canAddCustomer(currentCount) ?? false;

  bool canAddInvoice(int currentMonthCount) =>
      limits?.canAddInvoice(currentMonthCount) ?? false;

  bool canAddUser(int currentCount) =>
      limits?.canAddUser(currentCount) ?? false;

  bool canAddExpense(int currentMonthCount) =>
      limits?.canAddExpense(currentMonthCount) ?? false;

  /// Verificar si esta cerca de un limite
  bool isNearLimit(String resource) {
    if (usage == null) return false;

    switch (resource) {
      case 'products':
        return usage!.products.isNearLimit;
      case 'customers':
        return usage!.customers.isNearLimit;
      case 'users':
        return usage!.users.isNearLimit;
      case 'invoices':
        return usage!.invoicesThisMonth.isNearLimit;
      case 'expenses':
        return usage!.expensesThisMonth.isNearLimit;
      case 'storage':
        return usage!.storage.isNearLimit;
      default:
        return false;
    }
  }

  // ==================== NOTIFICACIONES ====================

  void _checkSubscriptionStatus() {
    if (subscription == null) return;

    // ✅ Recalcular el estado real basado en endDate
    final now = DateTime.now();
    final realDaysRemaining = subscription!.endDate.difference(now).inDays;
    final isReallyExpired = subscription!.isExpired || realDaysRemaining <= 0;

    print('🔍 _checkSubscriptionStatus: isExpired=${subscription!.isExpired}, '
        'endDate=${subscription!.endDate}, realDaysRemaining=$realDaysRemaining, '
        'isReallyExpired=$isReallyExpired, isTrial=${subscription!.isTrial}');

    // ✅ IMPORTANTE: NO mostrar diálogo aquí, solo guardar el tipo pendiente
    // El diálogo se mostrará cuando el Dashboard esté listo

    // ✅ Si está expirado
    if (isReallyExpired) {
      _pendingSubscriptionDialog.value = _SubscriptionDialogType.expired;
      _pendingDialogDays.value = 0;
      print('📌 Diálogo pendiente: EXPIRED');
      return;
    }

    // ✅ Si es trial y le quedan días
    if (subscription!.isTrial && realDaysRemaining <= 7) {
      _pendingSubscriptionDialog.value = _SubscriptionDialogType.trial;
      _pendingDialogDays.value = realDaysRemaining;
      print('📌 Diálogo pendiente: TRIAL ($realDaysRemaining días)');
      return;
    }

    // ✅ Si no es trial pero está por expirar (1-3 días = crítico, 4-7 = warning)
    if (realDaysRemaining <= 3) {
      _pendingSubscriptionDialog.value = _SubscriptionDialogType.critical;
      _pendingDialogDays.value = realDaysRemaining;
      print('📌 Diálogo pendiente: CRITICAL ($realDaysRemaining días)');
      return;
    }

    if (realDaysRemaining <= 7) {
      _pendingSubscriptionDialog.value = _SubscriptionDialogType.warning;
      _pendingDialogDays.value = realDaysRemaining;
      print('📌 Diálogo pendiente: WARNING ($realDaysRemaining días)');
      return;
    }

    // Más de 7 días - no hay diálogo pendiente
    _pendingSubscriptionDialog.value = null;
    print('✅ Suscripción OK - No hay diálogo pendiente');

    // Si había bloqueo por suscripción expirada, reanudar el sync.
    // Esto ocurre cuando el usuario renueva y la nueva suscripción es válida.
    _maybeUnblockSync();
  }

  /// Reanuda la sincronización si estaba bloqueada por suscripción expirada.
  /// Se llama cuando `_checkSubscriptionStatus` confirma que la suscripción
  /// está vigente (no expirada, >7 días restantes).
  void _maybeUnblockSync() {
    try {
      SyncService.resetSubscriptionBlock();
    } catch (_) {
      // SyncService no cargado (tests, etc.). No es crítico.
    }
  }

  /// ✅ MÉTODO PÚBLICO: Llamar desde DashboardController.onReady()
  /// para mostrar el diálogo de suscripción DESPUÉS de que el Dashboard esté listo
  Future<void> showPendingSubscriptionDialogIfNeeded() async {
    // Evitar mostrar múltiples veces en la misma sesión.
    if (_dialogShown) {
      print('⏭️ Diálogo de suscripción ya fue mostrado, ignorando');
      return;
    }

    final dialogType = _pendingSubscriptionDialog.value;
    if (dialogType == null) {
      print('✅ No hay diálogo de suscripción pendiente');
      return;
    }

    final days = _pendingDialogDays.value;

    // Throttling central: el SubscriptionAlertService decide si está
    // permitido mostrar el aviso según la política unificada (sólo
    // ≤1 día restante, cooldown 2h entre avisos persistido entre
    // sesiones; `expired` 1 vez por sesión). Si dice "no", salimos sin
    // marcar `_dialogShown` para que el siguiente trigger pueda
    // intentar tras el cooldown.
    final alertLevel = _dialogTypeToAlertLevel(dialogType);
    if (Get.isRegistered<SubscriptionAlertService>()) {
      final svc = Get.find<SubscriptionAlertService>();
      final allowed = await svc.tryShow(
        level: alertLevel,
        daysUntilExpiration: days,
      );
      if (!allowed) {
        print('⏸️ SubscriptionAlertService bloqueó el aviso $alertLevel '
            '(cooldown o > 1 día restante)');
        return;
      }
    }

    // Marcar como mostrado en esta sesión.
    _dialogShown = true;
    print('🔔 Mostrando diálogo de suscripción: $dialogType ($days días)');

    // Pequeño delay para asegurar que el Dashboard está completamente renderizado
    Future.delayed(const Duration(milliseconds: 500), () {
      switch (dialogType) {
        case _SubscriptionDialogType.expired:
          _showExpiredDialog();
          break;
        case _SubscriptionDialogType.critical:
          _showCriticalDialog(days);
          break;
        case _SubscriptionDialogType.warning:
          _showWarningDialog(days);
          break;
        case _SubscriptionDialogType.trial:
          _showTrialReminderDialog(days);
          break;
      }
    });

    // Limpiar el pendiente
    _pendingSubscriptionDialog.value = null;
  }

  /// Resetear el flag para permitir mostrar el diálogo nuevamente
  /// (útil si el usuario cierra sesión y vuelve a iniciar)
  void resetDialogShownFlag() {
    _dialogShown = false;
  }

  void _handleReconnectAfterOfflineExpiration() {
    if (!_wasExpiredWhileOffline.value) return;

    Get.dialog(
      GetPlatform.isDesktop
          ? _buildExpiredWhileOfflineDesktopDialog()
          : _buildExpiredWhileOfflineMobileDialog(),
      barrierDismissible: false,
    );

    // Limpiar flag
    _wasExpiredWhileOffline.value = false;
  }

  // ==================== UI HELPERS ====================

  /// ✅ Diálogo de advertencia (4-7 días restantes)
  void _showWarningDialog(int daysRemaining) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.access_time, color: Colors.amber.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aviso de Suscripción',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
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
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu suscripción vence en $daysRemaining días.',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Te recomendamos renovar tu suscripción antes de que expire para no perder acceso a las funcionalidades.',
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
                backgroundColor: Colors.amber.shade600,
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

  /// ✅ Diálogo crítico (1-3 días restantes)
  void _showCriticalDialog(int daysRemaining) {
    final message = daysRemaining == 1
        ? '¡ÚLTIMO DÍA! Tu suscripción vence HOY.'
        : '¡Solo te quedan $daysRemaining días!';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Atención Urgente!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade700,
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.deepOrange, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.deepOrange.shade800,
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
              'Tu suscripción está por vencer. Renueva inmediatamente para evitar perder el acceso a la aplicación.',
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
                backgroundColor: Colors.deepOrange,
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

  /// ✅ Diálogo de suscripción expirada - con info de contacto
  void _showExpiredDialog() {
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

  /// ✅ Diálogo de período de prueba
  void _showTrialReminderDialog(int daysLeft) {
    final message = daysLeft == 1
        ? '¡Último día de prueba!'
        : 'Te quedan $daysLeft días de prueba.';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.hourglass_bottom, color: Colors.blue.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Período de Prueba',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu período de prueba está por terminar. Activa tu suscripción para seguir disfrutando de todas las funcionalidades.',
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
                backgroundColor: Colors.blue.shade600,
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

  Widget _buildExpiredWhileOfflineDesktopDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.wifi_off, color: Colors.red.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Suscripción Expirada',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu suscripción expiró mientras estabas sin conexión. '
            'Para continuar usando la aplicación, contacta a tu proveedor:',
          ),
          const SizedBox(height: 16),
          _buildContactInfoWidget(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }

  Widget _buildExpiredWhileOfflineMobileDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 8),
          const Expanded(child: Text('Suscripción Expirada')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu suscripción expiró mientras estabas offline. Contacta para renovar:',
          ),
          const SizedBox(height: 12),
          _buildContactInfoWidget(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  /// ✅ Widget reutilizable con información de contacto
  Widget _buildContactInfoWidget() {
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

  // ==================== METODOS PUBLICOS ====================

  /// Mostrar dialogo de upgrade
  void showUpgradeDialog(String feature) {
    final requiredPlan = _getMinimumPlanForFeature(feature);

    Get.dialog(
      AlertDialog(
        title: const Text('Funcion Premium'),
        content: Text(
          'Esta funcion requiere el ${requiredPlan.displayName}. '
          'Actualiza tu plan para desbloquearla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Navegar a pagina de planes
              // Get.toNamed(Routes.SUBSCRIPTION_PLANS);
            },
            child: const Text('Ver Planes'),
          ),
        ],
      ),
    );
  }

  /// Mostrar advertencia de limite alcanzado
  void showLimitReachedDialog(String resource, int limit) {
    Get.dialog(
      AlertDialog(
        title: const Text('Limite Alcanzado'),
        content: Text(
          'Has alcanzado el limite de $limit $resource en tu plan. '
          'Actualiza para obtener mas capacidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Navegar a pagina de planes
            },
            child: const Text('Actualizar Plan'),
          ),
        ],
      ),
    );
  }

  SubscriptionPlan _getMinimumPlanForFeature(String feature) {
    final featurePlanMap = {
      'export_reports': SubscriptionPlan.basic,
      'export_excel': SubscriptionPlan.basic,
      'thermal_printer': SubscriptionPlan.basic,
      'advanced_reports': SubscriptionPlan.premium,
      'multiple_warehouses': SubscriptionPlan.premium,
      'custom_branding': SubscriptionPlan.premium,
      'api_integrations': SubscriptionPlan.enterprise,
    };

    return featurePlanMap[feature] ?? SubscriptionPlan.basic;
  }
}
