//lib features/settings/presentation/controllers/user_preferences_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/usecases/update_user_preferences_usecase.dart';

class UserPreferencesController extends GetxController {
  final GetUserPreferencesUseCase _getUserPreferencesUseCase;
  final UpdateUserPreferencesUseCase _updateUserPreferencesUseCase;

  UserPreferencesController({
    required GetUserPreferencesUseCase getUserPreferencesUseCase,
    required UpdateUserPreferencesUseCase updateUserPreferencesUseCase,
  }) : _getUserPreferencesUseCase = getUserPreferencesUseCase,
       _updateUserPreferencesUseCase = updateUserPreferencesUseCase;

  // Observable states
  final Rx<UserPreferences?> _userPreferences = Rx<UserPreferences?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  UserPreferences? get userPreferences => _userPreferences.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  // Individual preference getters for easy access
  bool get autoDeductInventory =>
      _userPreferences.value?.autoDeductInventory ?? true;
  bool get useFifoCosting => _userPreferences.value?.useFifoCosting ?? true;
  bool get validateStockBeforeInvoice =>
      _userPreferences.value?.validateStockBeforeInvoice ?? true;
  bool get allowOverselling =>
      _userPreferences.value?.allowOverselling ?? false;
  bool get showStockWarnings =>
      _userPreferences.value?.showStockWarnings ?? true;
  bool get showConfirmationDialogs =>
      _userPreferences.value?.showConfirmationDialogs ?? true;
  bool get useCompactMode => _userPreferences.value?.useCompactMode ?? false;
  bool get enableExpiryNotifications =>
      _userPreferences.value?.enableExpiryNotifications ?? true;
  bool get enableLowStockNotifications =>
      _userPreferences.value?.enableLowStockNotifications ?? true;
  String? get defaultWarehouseId => _userPreferences.value?.defaultWarehouseId;

  @override
  void onInit() {
    super.onInit();
    loadUserPreferences();
  }

  Future<void> loadUserPreferences() async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final result = await _getUserPreferencesUseCase(NoParams());

      result.fold(
        (failure) {
          _errorMessage.value = failure.message;
          Get.snackbar(
            'Error',
            'No se pudieron cargar las preferencias: ${failure.message}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        (preferences) {
          _userPreferences.value = preferences;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updatePreference(String key, dynamic value) async {
    try {
      final preferences = {key: value};

      final result = await _updateUserPreferencesUseCase(
        UpdateUserPreferencesParams(preferences: preferences),
      );

      return result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            'No se pudo actualizar la preferencia: ${failure.message}',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        },
        (updatedPreferences) {
          _userPreferences.value = updatedPreferences;
          return true;
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado al actualizar la preferencia',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> updateMultiplePreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final result = await _updateUserPreferencesUseCase(
        UpdateUserPreferencesParams(preferences: preferences),
      );

      return result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            'No se pudieron actualizar las preferencias: ${failure.message}',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        },
        (updatedPreferences) {
          _userPreferences.value = updatedPreferences;
          Get.snackbar(
            'Éxito',
            'Preferencias actualizadas correctamente',
            snackPosition: SnackPosition.BOTTOM,
          );
          return true;
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado al actualizar las preferencias',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      Get.back(); // Cerrar loading dialog
    }
  }

  // Convenience methods for common preference updates
  Future<void> toggleAutoDeductInventory() async {
    final currentValue = autoDeductInventory;
    final success = await updatePreference(
      'autoDeductInventory',
      !currentValue,
    );

    if (success) {
      final action = !currentValue ? 'habilitado' : 'deshabilitado';
      Get.snackbar(
        'Configuración actualizada',
        'Descuento automático de inventario $action',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleUseFifoCosting() async {
    final currentValue = useFifoCosting;
    await updatePreference('useFifoCosting', !currentValue);
  }

  Future<void> toggleValidateStockBeforeInvoice() async {
    final currentValue = validateStockBeforeInvoice;
    await updatePreference('validateStockBeforeInvoice', !currentValue);
  }

  Future<void> toggleAllowOverselling() async {
    final currentValue = allowOverselling;
    await updatePreference('allowOverselling', !currentValue);
  }

  Future<void> toggleShowStockWarnings() async {
    final currentValue = showStockWarnings;
    await updatePreference('showStockWarnings', !currentValue);
  }

  Future<void> toggleShowConfirmationDialogs() async {
    final currentValue = showConfirmationDialogs;
    await updatePreference('showConfirmationDialogs', !currentValue);
  }

  Future<void> toggleUseCompactMode() async {
    final currentValue = useCompactMode;
    await updatePreference('useCompactMode', !currentValue);
  }

  Future<void> toggleEnableExpiryNotifications() async {
    final currentValue = enableExpiryNotifications;
    await updatePreference('enableExpiryNotifications', !currentValue);
  }

  Future<void> toggleEnableLowStockNotifications() async {
    final currentValue = enableLowStockNotifications;
    await updatePreference('enableLowStockNotifications', !currentValue);
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
