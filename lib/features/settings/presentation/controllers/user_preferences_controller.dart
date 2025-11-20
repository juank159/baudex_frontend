//lib features/settings/presentation/controllers/user_preferences_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../../app/services/password_validation_service.dart';
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
  final RxInt selectedTab = 0.obs;

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
          _showSnackbar(
            title: 'Error',
            message: 'No se pudieron cargar las preferencias: ${failure.message}',
            isError: true,
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

  /// Valida la contraseña antes de permitir cambios en preferencias
  Future<bool> _validatePasswordForChanges() async {
    return await PasswordValidationService.showPasswordValidationDialog(
      title: 'Verificación de Seguridad',
      message: 'Para tu seguridad, confirma tu contraseña antes de modificar las preferencias del sistema.',
    );
  }

  Future<bool> updatePreference(String key, dynamic value) async {
    try {
      final preferences = {key: value};

      final result = await _updateUserPreferencesUseCase(
        UpdateUserPreferencesParams(preferences: preferences),
      );

      return result.fold(
        (failure) {
          _showSnackbar(
            title: 'Error',
            message: 'No se pudo actualizar la preferencia: ${failure.message}',
            isError: true,
          );
          return false;
        },
        (updatedPreferences) {
          _userPreferences.value = updatedPreferences;
          return true;
        },
      );
    } catch (e) {
      _showSnackbar(
        title: 'Error',
        message: 'Error inesperado al actualizar la preferencia',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> updateMultiplePreferences(
    Map<String, dynamic> preferences,
  ) async {
    // Validar contraseña antes de permitir múltiples cambios
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return false;

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
          _showSnackbar(
            title: 'Error',
            message: 'No se pudieron actualizar las preferencias: ${failure.message}',
            isError: true,
          );
          return false;
        },
        (updatedPreferences) {
          _userPreferences.value = updatedPreferences;
          _showSnackbar(
            title: 'Éxito',
            message: 'Preferencias actualizadas correctamente',
            isError: false,
          );
          return true;
        },
      );
    } catch (e) {
      _showSnackbar(
        title: 'Error',
        message: 'Error inesperado al actualizar las preferencias',
        isError: true,
      );
      return false;
    } finally {
      Get.back(); // Cerrar loading dialog
    }
  }

  // Convenience methods for common preference updates
  Future<void> toggleAutoDeductInventory() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = autoDeductInventory;
    final success = await updatePreference(
      'autoDeductInventory',
      !currentValue,
    );

    if (success) {
      final action = !currentValue ? 'habilitado' : 'deshabilitado';
      _showSnackbar(
        title: 'Configuración actualizada',
        message: 'Descuento automático de inventario $action',
        isError: false,
      );
    }
  }

  Future<void> toggleUseFifoCosting() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = useFifoCosting;
    await updatePreference('useFifoCosting', !currentValue);
  }

  Future<void> toggleValidateStockBeforeInvoice() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = validateStockBeforeInvoice;
    await updatePreference('validateStockBeforeInvoice', !currentValue);
  }

  Future<void> toggleAllowOverselling() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = allowOverselling;
    await updatePreference('allowOverselling', !currentValue);
  }

  Future<void> toggleShowStockWarnings() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = showStockWarnings;
    await updatePreference('showStockWarnings', !currentValue);
  }

  Future<void> toggleShowConfirmationDialogs() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = showConfirmationDialogs;
    await updatePreference('showConfirmationDialogs', !currentValue);
  }

  Future<void> toggleUseCompactMode() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = useCompactMode;
    await updatePreference('useCompactMode', !currentValue);
  }

  Future<void> toggleEnableExpiryNotifications() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = enableExpiryNotifications;
    await updatePreference('enableExpiryNotifications', !currentValue);
  }

  Future<void> toggleEnableLowStockNotifications() async {
    // Validar contraseña antes de permitir el cambio
    final isPasswordValid = await _validatePasswordForChanges();
    if (!isPasswordValid) return;

    final currentValue = enableLowStockNotifications;
    await updatePreference('enableLowStockNotifications', !currentValue);
  }

  void clearError() {
    _errorMessage.value = '';
  }

  /// Cambiar tab seleccionado
  void switchTab(int tabIndex) {
    selectedTab.value = tabIndex;
  }

  /// Mostrar snackbar estandarizado para la pantalla de preferencias
  void _showSnackbar({
    required String title,
    required String message,
    bool isError = false,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError 
        ? Get.theme.colorScheme.error.withOpacity(0.1)
        : Get.theme.colorScheme.primary.withOpacity(0.1),
      colorText: isError 
        ? Get.theme.colorScheme.error
        : Get.theme.colorScheme.primary,
      borderColor: isError 
        ? Get.theme.colorScheme.error.withOpacity(0.3)
        : Get.theme.colorScheme.primary.withOpacity(0.3),
      borderWidth: 1,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: isError 
          ? Get.theme.colorScheme.error
          : Get.theme.colorScheme.primary,
        size: 24,
      ),
      shouldIconPulse: false,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
