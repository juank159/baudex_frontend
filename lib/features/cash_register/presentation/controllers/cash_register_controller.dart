// lib/features/cash_register/presentation/controllers/cash_register_controller.dart
import 'dart:async';
import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';
import '../../../settings/presentation/controllers/organization_controller.dart';

/// Controlador de Caja Registradora.
///
/// Es PERMANENTE (registrado en app_binding) para que el badge del
/// AppBar y el banner del dashboard reaccionen al estado en vivo
/// sin importar en qué pantalla esté el usuario.
///
/// Auto-refresca cada 60s para que el "esperado" se mantenga al día
/// cuando se cobran facturas en efectivo o se pagan gastos con caja.
class CashRegisterController extends GetxController {
  final CashRegisterRepository repository;

  CashRegisterController({required this.repository});

  Timer? _autoRefreshTimer;

  // ===== State =====
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;
  final Rx<CashRegisterCurrentState> currentState =
      const CashRegisterCurrentState().obs;
  final RxList<CashRegister> history = <CashRegister>[].obs;

  // ===== Getters =====
  CashRegister? get openRegister => currentState.value.cashRegister;
  bool get hasOpenRegister => currentState.value.hasOpenRegister;
  CashRegisterSummary get summary => currentState.value.summary;
  double get expectedAmount => currentState.value.expectedAmount;

  /// Si el tenant tiene el módulo de caja activo. Si está apagado,
  /// evitamos llamadas HTTP innecesarias (loadCurrent + auto-refresh
  /// cada 60s) — el controller existe como singleton permanent, pero
  /// queda dormido sin gastar red.
  bool get _moduleEnabled {
    if (!Get.isRegistered<OrganizationController>()) return true;
    return Get.find<OrganizationController>().isCashRegisterEnabled;
  }

  @override
  void onReady() {
    super.onReady();
    if (_moduleEnabled) loadCurrent();
    // Auto-refresh cada 60s. El tick chequea el flag — si el admin
    // apaga/prende el módulo en runtime, el siguiente tick respeta
    // el nuevo estado automáticamente (sin recrear el timer).
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (isSubmitting.value) return;
      if (!_moduleEnabled) return;
      loadCurrent(silent: true);
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  /// Limpia TODO el estado en memoria del controller y dispara una carga
  /// inmediata del estado del nuevo tenant. Crítico al cambiar de tenant
  /// o hacer logout: como el controller es `permanent: true`, no se
  /// recrea automáticamente.
  ///
  /// **UX**: dejamos `isLoading=true` para que el badge muestre spinner
  /// (no "Caja cerrada" engañoso) mientras llega el dato real. La llamada
  /// `loadCurrent()` se dispara FIRE-AND-FORGET; el caller no necesita
  /// awaitear. Soporta tanto online (lee del server) como offline (lee
  /// del cache, si existe — si fue borrado por cambio de tenant, mostrará
  /// el error apropiado).
  void resetStateAndReload() {
    // Estado limpio + spinner activo
    isLoading.value = true;
    isSubmitting.value = false;
    errorMessage.value = '';
    currentState.value = const CashRegisterCurrentState();
    history.clear();
    // Disparar carga del nuevo tenant SIN bloquear al caller. El badge
    // mostrará spinner hasta que esto resuelva.
    // ignore: discarded_futures
    loadCurrent();
  }

  /// Variante sin reload — útil si el caller quiere solo limpiar (ej. en
  /// pruebas o flujos donde el reload se dispara por otra ruta).
  void resetState() {
    isLoading.value = false;
    isSubmitting.value = false;
    errorMessage.value = '';
    currentState.value = const CashRegisterCurrentState();
    history.clear();
  }

  /// Carga el estado de la caja del tenant.
  /// `silent`: no mostrar loading spinner ni borrar errores previos.
  /// Útil para auto-refresh en background.
  Future<void> loadCurrent({bool silent = false}) async {
    // Módulo apagado para el tenant → no hacemos fetch. El caller que
    // dependa del flag debe verificarlo antes; este chequeo es defensa
    // en profundidad para callers externos (auth reset, resync, etc.).
    if (!_moduleEnabled) return;
    if (!silent) {
      isLoading.value = true;
      errorMessage.value = '';
    }
    final result = await repository.getCurrent();
    result.fold(
      (failure) {
        if (!silent) errorMessage.value = failure.message;
      },
      (state) {
        currentState.value = state;
        if (silent) errorMessage.value = ''; // limpiar si refresh exitoso
      },
    );
    if (!silent) isLoading.value = false;
  }

  /// Abre caja con saldo inicial.
  Future<bool> open({
    required double openingAmount,
    String? openingNotes,
  }) async {
    if (isSubmitting.value) return false;
    if (openingAmount < 0) {
      _showError('El saldo inicial no puede ser negativo');
      return false;
    }
    isSubmitting.value = true;
    final result = await repository.open(
      openingAmount: openingAmount,
      openingNotes: openingNotes,
    );
    isSubmitting.value = false;
    return result.fold(
      (failure) {
        _showError(failure.message);
        return false;
      },
      (_) {
        _showSuccess('¡Caja abierta!',
            'Saldo inicial: \$${openingAmount.toStringAsFixed(0)}');
        loadCurrent();
        return true;
      },
    );
  }

  /// Cierra la caja actual con el efectivo contado físicamente.
  Future<bool> close({
    required double closingActualAmount,
    String? closingNotes,
  }) async {
    if (isSubmitting.value) return false;
    final reg = openRegister;
    if (reg == null) {
      _showError('No hay caja abierta para cerrar');
      return false;
    }
    if (closingActualAmount < 0) {
      _showError('El monto contado no puede ser negativo');
      return false;
    }
    isSubmitting.value = true;
    final result = await repository.close(
      id: reg.id,
      closingActualAmount: closingActualAmount,
      closingNotes: closingNotes,
    );
    isSubmitting.value = false;
    return result.fold(
      (failure) {
        _showError(failure.message);
        return false;
      },
      (closed) {
        final diff = closed.closingDifference ?? 0;
        final diffMsg = diff == 0
            ? '¡Cuadre perfecto!'
            : diff > 0
                ? 'Sobrante: \$${diff.abs().toStringAsFixed(0)}'
                : 'Faltante: \$${diff.abs().toStringAsFixed(0)}';
        _showSuccess('Caja cerrada', diffMsg);
        loadCurrent();
        loadHistory();
        return true;
      },
    );
  }

  Future<void> loadHistory() async {
    final result = await repository.list(limit: 50);
    result.fold(
      (_) {},
      (list) => history.value = list,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: const Color(0xFFFFFFFF),
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF388E3C),
      colorText: const Color(0xFFFFFFFF),
    );
  }
}
