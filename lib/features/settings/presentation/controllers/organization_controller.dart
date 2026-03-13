// lib/features/settings/presentation/controllers/organization_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/services/password_validation_service.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';

class OrganizationController extends GetxController {
  // ==================== DEPENDENCIES ====================

  final OrganizationRepository _organizationRepository;

  OrganizationController(this._organizationRepository);

  // ==================== OBSERVABLES ====================

  final _isLoading = false.obs;
  final _currentOrganization = Rxn<Organization>();
  final _error = Rxn<String>();

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  Organization? get currentOrganization => _currentOrganization.value;
  String? get error => _error.value;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    loadCurrentOrganization();
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar la organización actual del usuario
  Future<void> loadCurrentOrganization() async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _organizationRepository.getCurrentOrganization();

      result.fold(
        (failure) => _handleFailure(failure),
        (organization) {
          _currentOrganization.value = organization;
          _syncTimezone(organization);
        },
      );
    } catch (e) {
      _handleError('Error inesperado al cargar organización: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar organización actual del usuario
  Future<bool> updateCurrentOrganization(Map<String, dynamic> updates) async {
    try {
      print('🔄 Starting organization update...');
      _setLoading(true);
      _clearError();

      final result = await _organizationRepository.updateCurrentOrganization(
        updates,
      );

      return result.fold(
        (failure) {
          print('❌ Update failed: $failure');
          _handleFailure(failure);
          return false;
        },
        (organization) {
          print('✅ Update successful!');
          _currentOrganization.value = organization;
          _syncTimezone(organization);

          // Actualizar la organización actual
          // Movemos el snackbar al diálogo para evitar conflictos de timing

          print('📤 Returning true from controller');
          return true;
        },
      );
    } catch (e) {
      print('❌ Exception in controller: $e');
      _handleError('Error inesperado al actualizar organización: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener organización por ID
  Future<Organization?> getOrganizationById(String id) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _organizationRepository.getOrganizationById(id);

      return result.fold((failure) {
        _handleFailure(failure);
        return null;
      }, (organization) => organization);
    } catch (e) {
      _handleError('Error inesperado al obtener organización: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Refrescar datos
  @override
  Future<void> refresh() async {
    await loadCurrentOrganization();
    // Actualizar el valor temporal del slider con el valor cargado
    _tempProfitMargin.value = profitMarginPercentage;
    print('🔄 Datos refrescados - Margen actual: $profitMarginPercentage%');
  }

  /// Limpiar error
  void clearError() {
    _clearError();
  }

  // ==================== FORM VALIDATION ====================

  /// Validar nombre de organización
  String? validateOrganizationName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la organización es requerido';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }

    return null;
  }

  /// Validar slug de organización
  String? validateOrganizationSlug(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El slug es requerido';
    }

    final slugRegex = RegExp(r'^[a-z0-9-]+$');
    if (!slugRegex.hasMatch(value.trim())) {
      return 'El slug solo puede contener letras minúsculas, números y guiones';
    }

    if (value.trim().length < 2) {
      return 'El slug debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 50) {
      return 'El slug no puede exceder 50 caracteres';
    }

    return null;
  }

  /// Validar dominio (opcional)
  String? validateDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // El dominio es opcional
    }

    final domainRegex = RegExp(
      r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
    );

    if (!domainRegex.hasMatch(value.trim())) {
      return 'Ingrese un dominio válido (ej: miempresa.com)';
    }

    return null;
  }

  // ==================== MULTI-CURRENCY METHODS ====================

  /// Verificar si multi-moneda está habilitado
  bool get isMultiCurrencyEnabled =>
      currentOrganization?.multiCurrencyEnabled ?? false;

  /// Obtener monedas aceptadas
  List<Map<String, dynamic>> get acceptedCurrencies =>
      currentOrganization?.acceptedCurrencies ?? [];

  /// Obtener moneda base de la organización
  String get baseCurrency => currentOrganization?.currency ?? 'COP';

  /// Activar/desactivar multi-moneda
  Future<bool> toggleMultiCurrency(bool enabled) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = Map<String, dynamic>.from(org.settings ?? {});
    final updates = <String, dynamic>{
      'multiCurrencyEnabled': enabled,
      'settings': settings,
    };

    return await updateCurrentOrganization(updates);
  }

  /// Agregar una moneda aceptada
  Future<bool> addAcceptedCurrency(Map<String, dynamic> currency) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = Map<String, dynamic>.from(org.settings ?? {});
    final currencies =
        List<Map<String, dynamic>>.from(settings['acceptedCurrencies'] ?? []);

    // Verificar que no exista ya
    if (currencies.any((c) => c['code'] == currency['code'])) {
      Get.snackbar(
        'Moneda duplicada',
        'La moneda ${currency['code']} ya está en la lista',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        icon: const Icon(Icons.warning, color: Colors.orange),
        duration: const Duration(seconds: 2),
      );
      return false;
    }

    currencies.add(currency);
    settings['acceptedCurrencies'] = currencies;

    return await updateCurrentOrganization({'settings': settings});
  }

  /// Eliminar una moneda aceptada
  Future<bool> removeAcceptedCurrency(String code) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = Map<String, dynamic>.from(org.settings ?? {});
    final currencies =
        List<Map<String, dynamic>>.from(settings['acceptedCurrencies'] ?? []);

    currencies.removeWhere((c) => c['code'] == code);
    settings['acceptedCurrencies'] = currencies;

    return await updateCurrentOrganization({'settings': settings});
  }

  /// Actualizar tasa de cambio por defecto de una moneda
  Future<bool> updateCurrencyRate(String code, double newRate) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = Map<String, dynamic>.from(org.settings ?? {});
    final currencies =
        List<Map<String, dynamic>>.from(settings['acceptedCurrencies'] ?? []);

    final index = currencies.indexWhere((c) => c['code'] == code);
    if (index == -1) return false;

    currencies[index] = Map<String, dynamic>.from(currencies[index])
      ..['defaultRate'] = newRate;
    settings['acceptedCurrencies'] = currencies;

    return await updateCurrentOrganization({'settings': settings});
  }

  // ==================== PROFIT MARGIN METHODS ====================

  /// ✅ NUEVO: Obtener margen de ganancia actual (por defecto 20%)
  double get profitMarginPercentage =>
      currentOrganization?.profitMargin ?? 20.0;

  /// ✅ NUEVO: Variable temporal para el slider
  final _tempProfitMargin = 20.0.obs;
  double get tempProfitMargin => _tempProfitMargin.value;

  @override
  void onReady() {
    super.onReady();
    // ✅ Solo recargar si no hay organización cargada (evita doble carga)
    // Si onInit() ya cargó la organización o falló con error de conexión, no reintentar
    if (_currentOrganization.value == null && !_isLoading.value) {
      loadCurrentOrganization().then((_) {
        _tempProfitMargin.value = profitMarginPercentage;
        print(
          '🏢 Margen de ganancia cargado desde backend: $profitMarginPercentage%',
        );
      });
    } else {
      // Ya está cargada o cargando, solo inicializar el valor temporal
      _tempProfitMargin.value = profitMarginPercentage;
    }
  }

  /// ✅ NUEVO: Actualizar margen temporal (para el slider) - SIN snackbar
  void updateTempProfitMargin(double value) {
    _tempProfitMargin.value = value;
    // No llamar update() aquí porque estamos usando Obs
    // Los Obx() se actualizarán automáticamente
  }

  /// ✅ NUEVO: Guardar margen de ganancia en el backend - LLAMADA REAL AL SERVIDOR CON VALIDACIÓN
  Future<bool> saveProfitMargin() async {
    try {
      _setLoading(true);
      _clearError();

      print(
        '🔐 Solicitando validación de contraseña para cambiar margen de ganancia...',
      );

      // ✅ VALIDACIÓN DE CONTRASEÑA OBLIGATORIA
      final passwordValid =
          await PasswordValidationService.showPasswordValidationDialog(
            title: 'Confirmar Cambio de Margen',
            message:
                'Por seguridad, confirma tu contraseña para cambiar el margen de ganancia a ${_tempProfitMargin.value.toStringAsFixed(0)}%',
          );

      if (!passwordValid) {
        print('🚫 Validación de contraseña cancelada o fallida');
        _setLoading(false);
        return false;
      }

      print(
        '✅ Contraseña validada. Procediendo a guardar margen: ${_tempProfitMargin.value}%',
      );

      // ✅ LLAMADA REAL AL BACKEND usando el repositorio
      final result = await _organizationRepository.updateProfitMargin(
        _tempProfitMargin.value,
      );

      return result.fold(
        (failure) {
          print('❌ Error al actualizar margen: $failure');
          _handleFailure(failure);
          return false;
        },
        (success) {
          print('✅ Margen actualizado exitosamente en el backend');

          // Recargar la organización desde el backend para tener los datos actualizados
          loadCurrentOrganization();

          Get.snackbar(
            'Margen Actualizado',
            'Nuevo margen: ${_tempProfitMargin.value.toStringAsFixed(0)}% guardado en el servidor',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.trending_up, color: Colors.green),
            duration: const Duration(seconds: 2),
          );

          return true;
        },
      );
    } catch (e) {
      print('❌ Excepción al actualizar margen: $e');
      _handleError('Error al actualizar margen de ganancia: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== PRIVATE METHODS ====================

  void _syncTimezone(Organization organization) {
    try {
      if (Get.isRegistered<TenantDateTimeService>()) {
        Get.find<TenantDateTimeService>().updateTimezone(organization.timezone);
      }
    } catch (e) {
      print('⚠️ Error sincronizando timezone: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _clearError() {
    _error.value = null;
  }

  void _handleError(String message) {
    _error.value = message;

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 5),
    );
  }

  void _handleFailure(Failure failure) {
    // ✅ NO mostrar snackbars de error de conexión cuando backend está offline
    // El usuario ya sabe que está trabajando offline
    if (failure is ConnectionFailure) {
      print('⚠️ OrganizationController: Sin conexión - trabajando offline');
      _error.value = null; // No mostrar error en UI
      return; // NO mostrar snackbar
    }

    String message;

    switch (failure.runtimeType) {
      case ServerFailure:
        message = 'Error del servidor. Intente nuevamente.';
        break;
      case ValidationFailure:
        message = 'Error de validación. Verifique los datos ingresados.';
        break;
      case AuthFailure:
        message = 'Error de autenticación. Inicie sesión nuevamente.';
        break;
      default:
        message = 'Error desconocido. Intente nuevamente.';
    }

    _handleError(message);
  }

  // ==================== DEBUGGING ====================

  void printDebugInfo() {
    print('🐛 OrganizationController Debug Info:');
    print('   isLoading: $isLoading');
    print('   currentOrganization: ${currentOrganization?.name ?? 'null'}');
    print('   error: ${error ?? 'none'}');
  }
}
