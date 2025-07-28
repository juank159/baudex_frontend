// lib/features/settings/presentation/controllers/organization_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../../../app/core/errors/failures.dart';

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
        (organization) => _currentOrganization.value = organization,
      );
    } catch (e) {
      _handleError('Error inesperado al cargar organización: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar organización actual del usuario
  Future<bool> updateCurrentOrganization(
    Map<String, dynamic> updates,
  ) async {
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
  Future<void> refresh() async {
    await loadCurrentOrganization();
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

  // ==================== PRIVATE METHODS ====================

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
    String message;

    switch (failure.runtimeType) {
      case ServerFailure:
        message = 'Error del servidor. Intente nuevamente.';
        break;
      case ConnectionFailure:
        message = 'Sin conexión a internet. Verifique su conexión.';
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
