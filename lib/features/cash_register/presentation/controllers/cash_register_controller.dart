// lib/features/cash_register/presentation/controllers/cash_register_controller.dart
import 'dart:async';
import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import '../../domain/entities/cash_register.dart';
import '../../domain/repositories/cash_register_repository.dart';

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

  @override
  void onReady() {
    super.onReady();
    loadCurrent();
    // Auto-refresh cada 60s para mantener el "esperado" al día.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!isSubmitting.value) loadCurrent(silent: true);
    });
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  /// Carga el estado de la caja del tenant.
  /// `silent`: no mostrar loading spinner ni borrar errores previos.
  /// Útil para auto-refresh en background.
  Future<void> loadCurrent({bool silent = false}) async {
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
