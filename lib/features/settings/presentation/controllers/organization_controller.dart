// lib/features/settings/presentation/controllers/organization_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/mixins/sync_auto_refresh_mixin.dart';
import '../../../../app/services/password_validation_service.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class OrganizationController extends GetxController
    with SyncAutoRefreshMixin {
  // ==================== DEPENDENCIES ====================

  final OrganizationRepository _organizationRepository;

  OrganizationController(this._organizationRepository);

  // ==================== OBSERVABLES ====================

  final _isLoading = false.obs;
  final _currentOrganization = Rxn<Organization>();
  final _error = Rxn<String>();
  final _tempProfitMargin = 20.0.obs;
  bool _isRefreshingInBackground = false;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  Organization? get currentOrganization => _currentOrganization.value;
  /// Rx expuesto para que otros controllers usen `ever(...)` y reaccionen
  /// cuando la organización se carga/edita (p. ej. PO form para refrescar
  /// la lista de monedas aceptadas).
  Rxn<Organization> get currentOrganizationRx => _currentOrganization;
  String? get error => _error.value;
  double get profitMarginPercentage =>
      currentOrganization?.profitMargin ?? 20.0;
  double get tempProfitMargin => _tempProfitMargin.value;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    setupSyncListener();

    if (_isAuthenticated) {
      loadCurrentOrganization();
    }
  }

  @override
  void onReady() {
    super.onReady();
    _tempProfitMargin.value = profitMarginPercentage;
  }

  /// SyncAutoRefreshMixin: refrescar cuando FullSync descarga datos nuevos a ISAR
  @override
  Future<void> onSyncCompleted() async {
    if (!_isAuthenticated) return;
    // FullSync ya guardó en ISAR → solo leer cache (instantáneo)
    await _loadFromCacheOnly();
  }

  bool get _isAuthenticated =>
      Get.isRegistered<AuthController>() &&
      Get.find<AuthController>().isAuthenticated;

  OrganizationRepositoryImpl? get _repoImpl =>
      _organizationRepository is OrganizationRepositoryImpl
          ? _organizationRepository as OrganizationRepositoryImpl
          : null;

  // ==================== PUBLIC METHODS ====================

  /// Cache-first: ISAR instantáneo → server en background
  Future<void> loadCurrentOrganization() async {
    if (_isLoading.value) return;

    _clearError();

    // Paso 1: ISAR instantáneo (si hay cache)
    final impl = _repoImpl;
    if (impl != null && _currentOrganization.value == null) {
      final cacheResult = await impl.getCachedOrganization();
      cacheResult.fold(
        (_) {}, // Cache vacío, continuar al server
        (organization) {
          _currentOrganization.value = organization;
          _tempProfitMargin.value = organization.profitMargin ?? 20.0;
          _syncTimezone(organization);
        },
      );
    }

    // Paso 2: Server en background (sin bloquear UI)
    _refreshFromServerInBackground();
  }

  /// Forzar recarga desde el servidor (botón refresh manual)
  Future<void> forceRefreshFromServer() async {
    if (_isLoading.value) return;

    try {
      _setLoading(true);
      _clearError();

      final result = await _organizationRepository.getCurrentOrganization();

      result.fold(
        (failure) => _handleFailure(failure),
        (organization) {
          _currentOrganization.value = organization;
          _tempProfitMargin.value = organization.profitMargin ?? 20.0;
          _syncTimezone(organization);
        },
      );
    } catch (e) {
      if (_isAuthenticated) {
        _handleError('Error al cargar organización: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Actualizar organización actual del usuario
  Future<bool> updateCurrentOrganization(Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _organizationRepository.updateCurrentOrganization(
        updates,
      );

      return result.fold(
        (failure) {
          _handleFailure(failure);
          return false;
        },
        (organization) {
          _currentOrganization.value = organization;
          _syncTimezone(organization);
          return true;
        },
      );
    } catch (e) {
      _handleError('Error al actualizar organización: $e');
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
      _handleError('Error al obtener organización: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  @override
  Future<void> refresh() async {
    await forceRefreshFromServer();
    _tempProfitMargin.value = profitMarginPercentage;
  }

  void clearError() {
    _clearError();
  }

  // ==================== FORM VALIDATION ====================

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

  String? validateDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
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

  bool get isMultiCurrencyEnabled =>
      currentOrganization?.multiCurrencyEnabled ?? false;

  List<Map<String, dynamic>> get acceptedCurrencies =>
      currentOrganization?.acceptedCurrencies ?? [];

  String get baseCurrency => currentOrganization?.currency ?? 'COP';

  Future<bool> toggleMultiCurrency(bool enabled) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = _buildSettings(org);
    settings['multiCurrencyEnabled'] = enabled;

    return await updateCurrentOrganization({'settings': settings});
  }

  Map<String, dynamic> _buildSettings(Organization org) {
    final settings = Map<String, dynamic>.from(org.settings ?? {});
    settings['multiCurrencyEnabled'] = org.multiCurrencyEnabled;
    return settings;
  }

  Future<bool> addAcceptedCurrency(Map<String, dynamic> currency) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = _buildSettings(org);
    final currencies =
        List<Map<String, dynamic>>.from(settings['acceptedCurrencies'] ?? []);

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

  Future<bool> removeAcceptedCurrency(String code) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = _buildSettings(org);
    final currencies =
        List<Map<String, dynamic>>.from(settings['acceptedCurrencies'] ?? []);

    currencies.removeWhere((c) => c['code'] == code);
    settings['acceptedCurrencies'] = currencies;

    return await updateCurrentOrganization({'settings': settings});
  }

  Future<bool> updateCurrencyRate(String code, double newRate) async {
    final org = currentOrganization;
    if (org == null) return false;

    final settings = _buildSettings(org);
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

  void updateTempProfitMargin(double value) {
    _tempProfitMargin.value = value;
  }

  Future<bool> saveProfitMargin() async {
    try {
      _setLoading(true);
      _clearError();

      final passwordValid =
          await PasswordValidationService.showPasswordValidationDialog(
            title: 'Confirmar Cambio de Margen',
            message:
                'Por seguridad, confirma tu contraseña para cambiar el margen de ganancia a ${_tempProfitMargin.value.toStringAsFixed(0)}%',
          );

      if (!passwordValid) {
        _setLoading(false);
        return false;
      }

      final result = await _organizationRepository.updateProfitMargin(
        _tempProfitMargin.value,
      );

      return result.fold(
        (failure) {
          _handleFailure(failure);
          return false;
        },
        (success) {
          // Refrescar datos actualizados del servidor
          _refreshFromServerInBackground();

          Get.snackbar(
            'Margen Actualizado',
            'Nuevo margen: ${_tempProfitMargin.value.toStringAsFixed(0)}% guardado',
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
      _handleError('Error al actualizar margen de ganancia: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== PRIVATE METHODS ====================

  /// Leer solo de ISAR (para onSyncCompleted)
  Future<void> _loadFromCacheOnly() async {
    final impl = _repoImpl;
    if (impl == null) return;

    final cacheResult = await impl.getCachedOrganization();
    cacheResult.fold(
      (_) {},
      (organization) {
        _currentOrganization.value = organization;
        _tempProfitMargin.value = organization.profitMargin ?? 20.0;
        _syncTimezone(organization);
      },
    );
  }

  /// Refrescar desde servidor sin bloquear UI (sin isLoading)
  void _refreshFromServerInBackground() {
    if (_isRefreshingInBackground) return;
    _isRefreshingInBackground = true;

    final impl = _repoImpl;
    if (impl == null) {
      // Fallback: usar getCurrentOrganization normal
      _organizationRepository.getCurrentOrganization().then((result) {
        result.fold(
          (failure) {
            if (_currentOrganization.value == null) {
              _handleFailure(failure);
            }
          },
          (organization) {
            _currentOrganization.value = organization;
            _tempProfitMargin.value = organization.profitMargin ?? 20.0;
            _syncTimezone(organization);
          },
        );
      }).whenComplete(() => _isRefreshingInBackground = false);
      return;
    }

    impl.refreshFromServer().then((result) {
      result.fold(
        (failure) {
          // Si no teníamos datos y el server falló, marcar error
          if (_currentOrganization.value == null) {
            _handleFailure(failure);
          }
          // Si ya teníamos cache, silenciar el error
        },
        (organization) {
          _currentOrganization.value = organization;
          _tempProfitMargin.value = organization.profitMargin ?? 20.0;
          _syncTimezone(organization);
          _clearError();
        },
      );
    }).whenComplete(() => _isRefreshingInBackground = false);
  }

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
    if (failure is ConnectionFailure) {
      _error.value = null;
      return;
    }

    if (!_isAuthenticated) {
      _error.value = null;
      return;
    }

    if (failure is CacheFailure) {
      _error.value = 'No hay datos disponibles. Conecte a internet para cargar.';
      return;
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
}
