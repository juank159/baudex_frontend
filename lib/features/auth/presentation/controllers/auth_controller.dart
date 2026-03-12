// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dartz/dartz.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/usecases/login_usecase.dart' show LoginParams;
import '../../domain/usecases/register_usecase.dart' show RegisterParams;
import '../../domain/usecases/register_with_onboarding_usecase.dart'
    show RegisterWithOnboardingParams;
import '../../domain/usecases/change_password_usecase.dart'
    show ChangePasswordParams;
import '../../../../core/storage/tenant_storage.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
// ✅ IMPORT PARA LIMPIAR CACHE DE CATEGORÍAS AL LOGOUT
import '../../../products/presentation/controllers/product_form_controller.dart';
import '../../../../app/data/local/full_sync_service.dart';

class AuthController extends GetxController {
  // Dependencies
  final UseCase<AuthResult, LoginParams> _loginUseCase;
  final UseCase<AuthResult, RegisterParams> _registerUseCase;
  final UseCase<AuthResult, RegisterWithOnboardingParams>
  _registerWithOnboardingUseCase;
  final UseCase<User, NoParams> _getProfileUseCase;
  final UseCase<Unit, NoParams> _logoutUseCase;
  final UseCase<Unit, ChangePasswordParams> _changePasswordUseCase;
  final UseCase<bool, NoParams> _isAuthenticatedUseCase;
  final TenantStorage _tenantStorage;
  final SecureStorageService _secureStorageService;

  AuthController({
    required UseCase<AuthResult, LoginParams> loginUseCase,
    required UseCase<AuthResult, RegisterParams> registerUseCase,
    required UseCase<AuthResult, RegisterWithOnboardingParams>
    registerWithOnboardingUseCase,
    required UseCase<User, NoParams> getProfileUseCase,
    required UseCase<Unit, NoParams> logoutUseCase,
    required UseCase<Unit, ChangePasswordParams> changePasswordUseCase,
    required UseCase<bool, NoParams> isAuthenticatedUseCase,
    required TenantStorage tenantStorage,
    required SecureStorageService secureStorageService,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _registerWithOnboardingUseCase = registerWithOnboardingUseCase,
       _getProfileUseCase = getProfileUseCase,
       _logoutUseCase = logoutUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       _isAuthenticatedUseCase = isAuthenticatedUseCase,
       _tenantStorage = tenantStorage,
       _secureStorageService = secureStorageService;

  // ==================== OBSERVABLES ====================

  // Estados de carga
  final _isLoading = false.obs;
  final _isLoginLoading = false.obs;
  final _isRegisterLoading = false.obs;
  final _isProfileLoading = false.obs;

  // Estado de autenticación
  final _isAuthenticated = false.obs;
  final Rxn<User> _currentUser = Rxn<User>();

  // Form controllers para login
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Form controllers para registro
  final registerFirstNameController = TextEditingController();
  final registerLastNameController = TextEditingController();
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();
  final registerConfirmPasswordController = TextEditingController();

  // Form controllers para cambio de contraseña
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Visibility de contraseñas
  final _isLoginPasswordVisible = false.obs;
  final _isRegisterPasswordVisible = false.obs;
  final _isConfirmPasswordVisible = false.obs;
  final _isCurrentPasswordVisible = false.obs;
  final _isNewPasswordVisible = false.obs;

  // Form keys
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();
  final changePasswordFormKey = GlobalKey<FormState>();

  // Correos guardados
  final _savedEmails = <String>[].obs;
  final _showEmailSuggestions = false.obs;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoginLoading => _isLoginLoading.value;
  bool get isRegisterLoading => _isRegisterLoading.value;
  bool get isProfileLoading => _isProfileLoading.value;
  bool get isAuthenticated => _isAuthenticated.value;
  User? get currentUser => _currentUser.value;

  bool get isLoginPasswordVisible => _isLoginPasswordVisible.value;
  bool get isRegisterPasswordVisible => _isRegisterPasswordVisible.value;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible.value;
  bool get isCurrentPasswordVisible => _isCurrentPasswordVisible.value;
  bool get isNewPasswordVisible => _isNewPasswordVisible.value;

  List<String> get savedEmails => _savedEmails;
  bool get showEmailSuggestions => _showEmailSuggestions.value;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _initializeTenant();
    _checkAuthenticationStatus();
    _loadSavedEmails();
    _setupEmailListener();
  }

  /// Inicializar el tenant basado en la sesión del usuario autenticado
  Future<void> _initializeTenant() async {
    try {
      // Verificar si ya hay un tenant establecido
      final existingTenant = await _tenantStorage.getTenantSlug();

      if (existingTenant != null && existingTenant.isNotEmpty) {
        print('🏢 Tenant existente encontrado: $existingTenant');
        return;
      }

      // Si no hay tenant y hay un usuario autenticado, obtener su organización
      final isAuthenticated = await _isAuthenticatedUseCase.call(NoParams());

      await isAuthenticated.fold(
        (failure) async {
          print(
            '🏢 Usuario no autenticado, esperando login para establecer tenant',
          );
        },
        (authenticated) async {
          if (authenticated) {
            // Usuario autenticado pero sin tenant, obtener organización
            await _setTenantFromCurrentUser();
          } else {
            print(
              '🏢 Usuario no autenticado, esperando login para establecer tenant',
            );
          }
        },
      );
    } catch (e) {
      print('❌ Error inicializando tenant: $e');
    }
  }

  /// Establecer el tenant basado en la organización del usuario actual
  Future<void> _setTenantFromCurrentUser() async {
    try {
      final profileResult = await _getProfileUseCase.call(NoParams());

      await profileResult.fold(
        (failure) async {
          print(
            '❌ No se pudo obtener perfil del usuario para establecer tenant',
          );
        },
        (user) async {
          // Usar directamente el organizationSlug del usuario
          await _tenantStorage.setTenantSlug(user.organizationSlug);
          print(
            '🏢 Tenant establecido desde perfil de usuario: ${user.organizationSlug}',
          );
        },
      );
    } catch (e) {
      print('❌ Error estableciendo tenant desde usuario: $e');
    }
  }

  /// Generar tenant slug temporal basado en el dominio del email
  /// NOTA: Esto es temporal hasta que implementemos organizationSlug en el User
  String _generateTenantSlugFromEmail(String emailDomain) {
    // Limpiar dominio para crear un slug válido
    return emailDomain
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, emailDomain.length > 20 ? 20 : emailDomain.length);
  }

  /// Ejecutar Full Sync en background después del login
  void _triggerFullSync() {
    try {
      if (Get.isRegistered<FullSyncService>()) {
        final fullSyncService = Get.find<FullSyncService>();
        // Ejecutar en background sin bloquear la UI
        fullSyncService.performFullSync().then((result) {
          print('🔄 AuthController: Full Sync completado - ${result.totalSynced} registros');
          if (result.hasErrors) {
            print('⚠️ AuthController: Full Sync con errores: ${result.errors}');
          }
        }).catchError((e) {
          print('❌ AuthController: Error en Full Sync: $e');
        });
      }
    } catch (e) {
      print('⚠️ AuthController: No se pudo iniciar Full Sync: $e');
    }
  }

  /// Establecer el tenant correcto después de un login exitoso
  Future<void> _setTenantAfterLogin(User user) async {
    try {
      // Usar directamente el organizationSlug del usuario
      await _tenantStorage.setTenantSlug(user.organizationSlug);
      print(
        '🏢 Tenant establecido después del login: ${user.organizationSlug} para usuario ${user.email}',
      );

      // Verificar que se estableció correctamente
      final verifyTenant = await _tenantStorage.getTenantSlug();
      print('🏢 Tenant verificado después del login: $verifyTenant');
    } catch (e) {
      print('❌ Error estableciendo tenant después del login: $e');
      // En caso crítico de error, usar organizationSlug del usuario
      try {
        await _tenantStorage.setTenantSlug(user.organizationSlug);
        print(
          '🏢 Tenant establecido usando organizationSlug del usuario: ${user.organizationSlug}',
        );
      } catch (fallbackError) {
        print('💥 Error crítico estableciendo tenant: $fallbackError');
      }
    }
  }

  @override
  void onClose() {
    // Limpiar controllers de forma segura
    _safeDisposeController(loginEmailController);
    _safeDisposeController(loginPasswordController);
    _safeDisposeController(registerFirstNameController);
    _safeDisposeController(registerLastNameController);
    _safeDisposeController(registerEmailController);
    _safeDisposeController(registerPasswordController);
    _safeDisposeController(registerConfirmPasswordController);
    _safeDisposeController(currentPasswordController);
    _safeDisposeController(newPasswordController);
    _safeDisposeController(confirmPasswordController);
    super.onClose();
  }

  // ==================== MÉTODOS PÚBLICOS ====================

  /// Iniciar sesión
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;

    _isLoginLoading.value = true;
    print('🔧 AuthController: Iniciando login...');

    try {
      final result = await _loginUseCase(
        LoginParams(
          email: loginEmailController.text.trim(),
          password: loginPasswordController.text,
        ),
      );

      print('🔧 AuthController: Resultado de login recibido');

      result.fold(
        (failure) {
          print('❌ AuthController: Error en login - ${failure.message}');
          Get.snackbar(
            'Error de Login',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (authResult) async {
          print('✅ AuthController: Login exitoso - ${authResult.user.email}');
          print(
            '🔧 AuthController: Token recibido - ${authResult.token.substring(0, 20)}...',
          );

          _isAuthenticated.value = true;
          _currentUser.value = authResult.user;

          // CRÍTICO: Establecer tenant del usuario después del login exitoso
          await _setTenantAfterLogin(authResult.user);

          // Guardar el correo para recordarlo en futuros logins
          await _saveEmailAfterSuccessfulLogin(
            loginEmailController.text.trim(),
          );

          _clearLoginForm();

          Get.snackbar(
            'Bienvenido',
            'Sesión iniciada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );

          print('🔧 AuthController: Navegando al dashboard...');
          // Navegar al dashboard
          Get.offAllNamed(AppRoutes.dashboard);

          // Iniciar Full Sync en background (después de navegar al dashboard)
          _triggerFullSync();
        },
      );
    } catch (e) {
      print('💥 AuthController: Excepción no manejada en login - $e');
      Get.snackbar(
        'Error Inesperado',
        'Ocurrió un error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isLoginLoading.value = false;
      print('🔧 AuthController: Login finalizado');
    }
  }

  /// Registrar usuario con onboarding automático (crear almacén por defecto)
  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;

    _isRegisterLoading.value = true;
    print(
      '🏗️ AuthController: Iniciando registro con onboarding automático...',
    );

    try {
      final result = await _registerWithOnboardingUseCase(
        RegisterWithOnboardingParams(
          firstName: registerFirstNameController.text.trim(),
          lastName: registerLastNameController.text.trim(),
          email: registerEmailController.text.trim(),
          password: registerPasswordController.text,
          confirmPassword: registerConfirmPasswordController.text,
          organizationName:
              null, // El RegisterRequestModel se encargará de generar el nombre
        ),
      );

      print('🔧 AuthController: Resultado de registro con onboarding recibido');

      result.fold(
        (failure) {
          print(
            '❌ AuthController: Error en registro con onboarding - ${failure.message}',
          );
          Get.snackbar(
            'Error de Registro',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (authResult) {
          print(
            '✅ AuthController: Registro con onboarding exitoso - ${authResult.user.email}',
          );

          final email = registerEmailController.text.trim();
          _clearRegisterForm();

          Get.snackbar(
            'Registro Exitoso',
            '¡Cuenta creada exitosamente! Tu almacén principal ya está configurado.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            duration: const Duration(seconds: 4),
          );

          print('🔧 AuthController: Navegando al login...');
          // Ir al login en lugar del dashboard
          Get.offAllNamed(AppRoutes.login);

          // Pre-llenar el email en el login después de un pequeño delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_isControllerActive(loginEmailController)) {
              loginEmailController.text = email;
            }
          });
        },
      );
    } catch (e) {
      print(
        '💥 AuthController: Excepción no manejada en registro con onboarding - $e',
      );
      Get.snackbar(
        'Error Inesperado',
        'Ocurrió un error inesperado: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      _isRegisterLoading.value = false;
      print('🔧 AuthController: Registro con onboarding finalizado');
    }
  }

  /// Obtener perfil del usuario
  Future<void> getProfile() async {
    _isProfileLoading.value = true;

    try {
      final result = await _getProfileUseCase(const NoParams());

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            'No se pudo obtener el perfil: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade800,
            icon: const Icon(Icons.warning, color: Colors.orange),
          );
        },
        (user) {
          _currentUser.value = user;
        },
      );
    } finally {
      _isProfileLoading.value = false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _isLoading.value = true;

    try {
      final result = await _logoutUseCase(const NoParams());

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            'Error al cerrar sesión: ${failure.message}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (_) {
          _isAuthenticated.value = false;
          _currentUser.value = null;

          // ✅ LIMPIAR CACHE DE CATEGORÍAS AL CERRAR SESIÓN
          try {
            ProductFormController.clearCategoriesCache();
            print(
              '🗑️ AuthController: Cache de categorías limpiado al cerrar sesión',
            );
          } catch (e) {
            print(
              '⚠️ AuthController: Error al limpiar cache de categorías: $e',
            );
          }

          _clearAllForms();

          Get.snackbar(
            'Sesión Cerrada',
            'Has cerrado sesión exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.blue.shade100,
            colorText: Colors.blue.shade800,
            icon: const Icon(Icons.info, color: Colors.blue),
          );

          // Navegar al login
          Get.offAllNamed(AppRoutes.login);
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cambiar contraseña
  Future<void> changePassword() async {
    if (!changePasswordFormKey.currentState!.validate()) return;

    _isLoading.value = true;

    try {
      final result = await _changePasswordUseCase(
        ChangePasswordParams(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
          confirmPassword: confirmPasswordController.text,
        ),
      );

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (_) {
          _clearChangePasswordForm();

          Get.snackbar(
            'Contraseña Actualizada',
            'Tu contraseña ha sido cambiada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );

          // Cerrar modal si está abierto
          if (Get.isDialogOpen == true) {
            Get.back();
          }
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Ir a la pantalla de registro
  void goToRegister() {
    _clearLoginForm();
    Get.offNamed(
      AppRoutes.register,
    ); // Usar offNamed para reemplazar la ruta actual
  }

  /// Ir a la pantalla de login
  void goToLogin() {
    _clearRegisterForm();
    Get.offNamed(
      AppRoutes.login,
    ); // Usar offNamed para reemplazar la ruta actual
  }

  /// Toggle visibility de contraseñas
  void toggleLoginPasswordVisibility() {
    _isLoginPasswordVisible.value = !_isLoginPasswordVisible.value;
  }

  void toggleRegisterPasswordVisibility() {
    _isRegisterPasswordVisible.value = !_isRegisterPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible.value = !_isConfirmPasswordVisible.value;
  }

  void toggleCurrentPasswordVisibility() {
    _isCurrentPasswordVisible.value = !_isCurrentPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    _isNewPasswordVisible.value = !_isNewPasswordVisible.value;
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Verificar estado de autenticación al inicializar
  Future<void> _checkAuthenticationStatus() async {
    try {
      final result = await _isAuthenticatedUseCase(const NoParams());

      result.fold((failure) => _isAuthenticated.value = false, (isAuth) {
        _isAuthenticated.value = isAuth;
        if (isAuth) {
          getProfile(); // Cargar perfil si está autenticado
        }
      });
    } catch (e) {
      _isAuthenticated.value = false;
    }
  }

  /// Verificar si un TextEditingController está activo
  bool _isControllerActive(TextEditingController controller) {
    try {
      // Intentar acceder a una propiedad segura
      controller.text;
      return true;
    } catch (e) {
      // Controller disposed
      return false;
    }
  }

  /// Limpiar controller de forma segura
  void _safeClearController(TextEditingController controller) {
    if (_isControllerActive(controller)) {
      controller.clear();
    }
  }

  /// Dispose controller de forma segura
  void _safeDisposeController(TextEditingController controller) {
    if (_isControllerActive(controller)) {
      controller.dispose();
    }
  }

  /// Limpiar formulario de login
  void _clearLoginForm() {
    _safeClearController(loginEmailController);
    _safeClearController(loginPasswordController);
    _isLoginPasswordVisible.value = false;
  }

  /// Limpiar formulario de registro
  void _clearRegisterForm() {
    _safeClearController(registerFirstNameController);
    _safeClearController(registerLastNameController);
    _safeClearController(registerEmailController);
    _safeClearController(registerPasswordController);
    _safeClearController(registerConfirmPasswordController);
    _isRegisterPasswordVisible.value = false;
    _isConfirmPasswordVisible.value = false;
  }

  /// Limpiar formulario de cambio de contraseña
  void _clearChangePasswordForm() {
    _safeClearController(currentPasswordController);
    _safeClearController(newPasswordController);
    _safeClearController(confirmPasswordController);
    _isCurrentPasswordVisible.value = false;
    _isNewPasswordVisible.value = false;
  }

  /// Limpiar todos los formularios
  void _clearAllForms() {
    _clearLoginForm();
    _clearRegisterForm();
    _clearChangePasswordForm();
  }

  // ==================== EMAIL MANAGEMENT ====================

  /// Cargar correos guardados al inicializar
  Future<void> _loadSavedEmails() async {
    try {
      final emails = await _secureStorageService.getSavedEmails();
      _savedEmails.assignAll(emails);

      // Cargar el último email usado si está disponible
      final lastEmail = await _secureStorageService.getLastEmail();
      if (lastEmail != null && lastEmail.isNotEmpty) {
        loginEmailController.text = lastEmail;
      }
    } catch (e) {
      print('⚠️ Error cargando correos guardados: $e');
    }
  }

  /// Configurar listener para el campo de email
  void _setupEmailListener() {
    loginEmailController.addListener(() {
      final text = loginEmailController.text.toLowerCase();
      if (text.isEmpty) {
        _showEmailSuggestions.value = false;
        return;
      }

      // Mostrar sugerencias solo si hay texto y hay correos guardados que coincidan
      final hasMatches = _savedEmails.any(
        (email) => email.toLowerCase().contains(text),
      );
      _showEmailSuggestions.value = hasMatches;
    });
  }

  /// Guardar correo después de login exitoso
  Future<void> _saveEmailAfterSuccessfulLogin(String email) async {
    try {
      await _secureStorageService.addSavedEmail(email);
      await _secureStorageService.saveLastEmail(email);
      await _loadSavedEmails(); // Recargar la lista
    } catch (e) {
      print('⚠️ Error guardando correo: $e');
    }
  }

  /// Obtener correos filtrados para autocompletado
  List<String> getFilteredEmails(String query) {
    if (query.isEmpty) return _savedEmails;

    final lowerQuery = query.toLowerCase();
    return _savedEmails
        .where((email) => email.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Seleccionar un correo de las sugerencias
  void selectSavedEmail(String email) {
    loginEmailController.text = email;
    _showEmailSuggestions.value = false;
    // Mover el cursor al final
    loginEmailController.selection = TextSelection.fromPosition(
      TextPosition(offset: email.length),
    );
  }

  /// Eliminar un correo guardado
  Future<void> removeSavedEmail(String email) async {
    try {
      await _secureStorageService.removeSavedEmail(email);
      await _loadSavedEmails();
      Get.snackbar(
        'Correo eliminado',
        'El correo ha sido eliminado de los guardados',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('⚠️ Error eliminando correo: $e');
    }
  }

  /// Ocultar sugerencias
  void hideEmailSuggestions() {
    _showEmailSuggestions.value = false;
  }

  /// Mostrar sugerencias
  void displayEmailSuggestions() {
    if (_savedEmails.isNotEmpty) {
      _showEmailSuggestions.value = true;
    }
  }
}
