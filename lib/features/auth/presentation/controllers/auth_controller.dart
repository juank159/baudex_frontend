// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/is_authenticated_usecase.dart';

class AuthController extends GetxController {
  // Dependencies
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetProfileUseCase _getProfileUseCase;
  final LogoutUseCase _logoutUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final IsAuthenticatedUseCase _isAuthenticatedUseCase;

  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetProfileUseCase getProfileUseCase,
    required LogoutUseCase logoutUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    required IsAuthenticatedUseCase isAuthenticatedUseCase,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _getProfileUseCase = getProfileUseCase,
       _logoutUseCase = logoutUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       _isAuthenticatedUseCase = isAuthenticatedUseCase;

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

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _checkAuthenticationStatus();
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
        (authResult) {
          print('✅ AuthController: Login exitoso - ${authResult.user.email}');
          print(
            '🔧 AuthController: Token recibido - ${authResult.token.substring(0, 20)}...',
          );

          _isAuthenticated.value = true;
          _currentUser.value = authResult.user;

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

  /// Registrar usuario
  Future<void> register() async {
    if (!registerFormKey.currentState!.validate()) return;

    _isRegisterLoading.value = true;
    print('🔧 AuthController: Iniciando registro...');

    try {
      final result = await _registerUseCase(
        RegisterParams(
          firstName: registerFirstNameController.text.trim(),
          lastName: registerLastNameController.text.trim(),
          email: registerEmailController.text.trim(),
          password: registerPasswordController.text,
          confirmPassword: registerConfirmPasswordController.text,
        ),
      );

      print('🔧 AuthController: Resultado recibido');

      result.fold(
        (failure) {
          print('❌ AuthController: Error en registro - ${failure.message}');
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
            '✅ AuthController: Registro exitoso - ${authResult.user.email}',
          );

          final email = registerEmailController.text.trim();
          _clearRegisterForm();

          Get.snackbar(
            'Registro Exitoso',
            'Cuenta creada exitosamente. Ahora puedes iniciar sesión.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            duration: const Duration(seconds: 3),
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
      print('💥 AuthController: Excepción no manejada - $e');
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
      print('🔧 AuthController: Registro finalizado');
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
}
