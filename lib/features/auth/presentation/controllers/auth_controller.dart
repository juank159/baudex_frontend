// lib/features/auth/presentation/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dartz/dartz.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart' show LoginParams;
import '../../domain/usecases/register_usecase.dart' show RegisterParams;
import '../../domain/usecases/register_with_onboarding_usecase.dart'
    show RegisterWithOnboardingParams;
import '../../domain/usecases/change_password_usecase.dart'
    show ChangePasswordParams;
import '../../domain/usecases/verify_email_usecase.dart' show VerifyEmailParams;
import '../../domain/usecases/resend_verification_usecase.dart'
    show ResendVerificationParams;
import '../../domain/usecases/forgot_password_usecase.dart'
    show ForgotPasswordParams;
import '../../domain/usecases/reset_password_usecase.dart'
    show ResetPasswordParams;
import '../../../../core/storage/tenant_storage.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/data/local/isar_database.dart';
// ✅ IMPORT PARA LIMPIAR CACHE DE CATEGORÍAS AL LOGOUT
import '../../../products/presentation/controllers/product_form_controller.dart';
import '../../../../app/data/local/full_sync_service.dart';
import '../../../subscriptions/presentation/controllers/subscription_controller.dart';
import '../../../cash_register/presentation/controllers/cash_register_controller.dart';
import '../../../../app/core/services/permissions_service.dart';

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
  final UseCase<bool, VerifyEmailParams> _verifyEmailUseCase;
  final UseCase<bool, ResendVerificationParams> _resendVerificationUseCase;
  final UseCase<bool, ForgotPasswordParams> _forgotPasswordUseCase;
  final UseCase<bool, ResetPasswordParams> _resetPasswordUseCase;
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
    required UseCase<bool, VerifyEmailParams> verifyEmailUseCase,
    required UseCase<bool, ResendVerificationParams> resendVerificationUseCase,
    required UseCase<bool, ForgotPasswordParams> forgotPasswordUseCase,
    required UseCase<bool, ResetPasswordParams> resetPasswordUseCase,
    required TenantStorage tenantStorage,
    required SecureStorageService secureStorageService,
  }) : _loginUseCase = loginUseCase,
       _registerUseCase = registerUseCase,
       _registerWithOnboardingUseCase = registerWithOnboardingUseCase,
       _getProfileUseCase = getProfileUseCase,
       _logoutUseCase = logoutUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       _isAuthenticatedUseCase = isAuthenticatedUseCase,
       _verifyEmailUseCase = verifyEmailUseCase,
       _resendVerificationUseCase = resendVerificationUseCase,
       _forgotPasswordUseCase = forgotPasswordUseCase,
       _resetPasswordUseCase = resetPasswordUseCase,
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
  // Phase 3 — Login profesional: campo "Negocio" persistente. No es
  // funcional para auth (el backend determina la organización por el
  // email del usuario), pero da la experiencia POS profesional de
  // saber a qué negocio estás entrando antes de meter credenciales.
  final loginBusinessController = TextEditingController();
  final _hasRememberedBusiness = false.obs;
  bool get hasRememberedBusiness => _hasRememberedBusiness.value;

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
  bool _suppressSuggestions = false;

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
  void _showDeviceLimitDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.devices, color: Colors.orange.shade700, size: 32),
        ),
        title: const Text(
          'Límite de dispositivos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Puedes administrar tus dispositivos desde Configuración > Dispositivos Conectados.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        height: 1.3,
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
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _triggerFullSync() {
    _triggerFullSyncWithRetry(attempt: 1);
  }

  /// FullSync con reintento exponencial. Antes era fire-and-forget: si fallaba
  /// (Bad Gateway, timeout) el dashboard quedaba vacío hasta el próximo
  /// arranque. Ahora reintenta hasta 3 veces con backoff (4s, 16s, 60s).
  void _triggerFullSyncWithRetry({required int attempt}) {
    try {
      if (!Get.isRegistered<FullSyncService>()) return;
      final fullSyncService = Get.find<FullSyncService>();
      fullSyncService.performFullSync().then((result) {
        if (result.totalSynced > 0) {
          print('🔄 AuthController: Full Sync OK ($attempt/3) - ${result.totalSynced} registros');
        }
        if (result.wasAborted || result.hasErrors) {
          if (attempt < 3) {
            // Backoff: 4s → 16s → 60s
            final delaySeconds = attempt == 1 ? 4 : (attempt == 2 ? 16 : 60);
            print(
              '⏳ AuthController: FullSync incompleto, reintentando en ${delaySeconds}s (intento ${attempt + 1}/3)...',
            );
            Future.delayed(Duration(seconds: delaySeconds), () {
              _triggerFullSyncWithRetry(attempt: attempt + 1);
            });
          } else {
            print('❌ AuthController: FullSync falló tras 3 intentos. El usuario verá datos en cache.');
          }
        }
      }).catchError((e) {
        print('❌ AuthController: Error en Full Sync (intento $attempt): $e');
        if (attempt < 3) {
          final delaySeconds = attempt == 1 ? 4 : (attempt == 2 ? 16 : 60);
          Future.delayed(Duration(seconds: delaySeconds), () {
            _triggerFullSyncWithRetry(attempt: attempt + 1);
          });
        }
      });
    } catch (e) {
      print('⚠️ AuthController: No se pudo iniciar Full Sync: $e');
    }
  }

  /// Detecta cambio de tenant comparando el userId actual con el lastUserId
  /// guardado al hacer logout. Si son DIFERENTES, borra la BD ISAR para
  /// evitar mezcla de datos entre tenants. Si son IGUALES, preserva el
  /// cache offline-first.
  ///
  /// **Orden de operaciones (CRÍTICO para resiliencia):**
  /// 1. Persistir `lastUserId` PRIMERO. Si la app muere después de este
  ///    paso, el próximo arranque detectará correctamente el tenant.
  /// 2. SOLO ENTONCES borrar ISAR si hace falta. El clear se ejecuta
  ///    bajo timeout para no bloquear el login indefinidamente.
  /// 3. Cualquier excepción se loguea pero NO se propaga: un error aquí
  ///    no debe impedir que el usuario inicie sesión.
  Future<void> _handleTenantSwitchIfNeeded(String newUserId) async {
    final storage = Get.find<SecureStorageService>();
    String? lastUserId;
    try {
      lastUserId = await storage.getLastUserId();
    } catch (e) {
      print('⚠️ No se pudo leer lastUserId: $e');
      lastUserId = null;
    }

    // PASO 1: Persistir lastUserId ANTES de tocar ISAR. Atómico semántico:
    // si el clear falla o la app muere, el próximo arranque ya sabe a qué
    // tenant pertenece la BD actual.
    try {
      await storage.setLastUserId(newUserId);
    } catch (e) {
      print('⚠️ No se pudo persistir lastUserId: $e — continuando login');
    }

    // PASO 2: Decidir si hace falta limpiar ISAR.
    final needsClear = lastUserId != null && lastUserId != newUserId;
    if (!needsClear) {
      if (lastUserId == newUserId) {
        print('✅ Mismo usuario que el último login — preservando cache ISAR');
      } else {
        print('🆕 Primer login en este dispositivo — sin cleanup');
      }
      return;
    }

    print('🔄 Cambio de tenant detectado ($lastUserId → $newUserId). Limpiando ISAR + caches...');

    // PASO 3: Clear ISAR con timeout y guard de inicialización. Si ISAR
    // nunca se inicializó (init falló en main.dart), NO crasheamos: el
    // próximo arranque tras un buen init recupera todo desde el server.
    try {
      final isarDatabase = IsarDatabase.instance;
      if (!isarDatabase.isInitialized) {
        print('⚠️ ISAR no inicializado — saltando clear (se reseteará en próximo arranque)');
      } else {
        await isarDatabase.clear().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⚠️ Timeout limpiando ISAR — continuando login (se reintentará)');
          },
        );
        print('✅ ISAR limpiado por cambio de tenant');
      }
    } catch (e) {
      // Cualquier error (incluyendo IsarError) NO debe impedir el login.
      // El full sync posterior bajará todo desde el server.
      print('⚠️ Error limpiando ISAR en cambio de tenant: $e — continuando login');
    }

    // PASO 4: Limpiar caches del tenant que viven FUERA de ISAR.
    // Crítico: la caja registradora (cash_register_current_cache) y otros
    // caches de negocio se guardan en SecureStorage/SharedPreferences. Si
    // no los borramos aquí, el nuevo usuario verá el estado de caja del
    // anterior — bug grave de aislamiento entre tenants.
    try {
      await storage.clearTenantBusinessCaches();
    } catch (e) {
      print('⚠️ Error limpiando caches de tenant: $e — continuando login');
    }

    // PASO 5: Resetear estado en MEMORIA de controllers permanent que
    // guardan datos del tenant. CashRegisterController vive con
    // permanent:true, así que su `currentState` (caja abierta del tenant
    // anterior) sobrevive al logout/login. Hay que pedirle reset explícito.
    try {
      _resetPermanentTenantControllers();
    } catch (e) {
      print('⚠️ Error reseteando controllers de tenant: $e — continuando login');
    }
  }

  /// Resetea el estado en memoria de controllers `permanent: true` que
  /// guardan datos del tenant. Se llama en cambio de tenant Y en logout.
  /// Si un controller no está registrado (binding aún no cargado), se
  /// ignora silenciosamente — no es un error crítico.
  ///
  /// `triggerReload`: si true, dispara fetch del nuevo estado para evitar
  /// que la UI muestre "vacío" (badge spinner en vez de "caja cerrada"
  /// engañoso). Si false (típicamente en logout, donde no hay nuevo tenant),
  /// solo limpia memoria.
  void _resetPermanentTenantControllers({bool triggerReload = true}) {
    try {
      if (Get.isRegistered<CashRegisterController>()) {
        final controller = Get.find<CashRegisterController>();
        if (triggerReload) {
          controller.resetStateAndReload();
        } else {
          controller.resetState();
        }
        print('🔄 CashRegisterController: estado reseteado (reload=$triggerReload)');
      }
    } catch (e) {
      print('⚠️ Error reseteando CashRegisterController: $e');
    }

    // Permisos granulares: limpiar cache. La carga del nuevo tenant se
    // dispara desde el login flow (loadCurrentUserPermissions) tras
    // confirmar tenant correcto.
    try {
      if (Get.isRegistered<PermissionsService>()) {
        Get.find<PermissionsService>().clear();
        print('🔄 PermissionsService: cache limpiado');
      }
    } catch (e) {
      print('⚠️ Error limpiando PermissionsService: $e');
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
    _safeDisposeController(loginBusinessController);
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
          // Detectar error de límite de dispositivos (403 del backend)
          if (failure.code == 403 && failure.message.contains('dispositivo')) {
            _showDeviceLimitDialog(failure.message);
          } else if (failure.code == 401 ||
              failure.message.toLowerCase().contains('credencial') ||
              failure.message.toLowerCase().contains('invalid') ||
              failure.message.toLowerCase().contains('correo') ||
              failure.message.toLowerCase().contains('contraseña')) {
            // Mensaje genérico para credenciales malas — debe ser
            // IDÉNTICO al que mostramos cuando el negocio no coincide,
            // para no filtrar cuál de los tres campos falló.
            _showGenericLoginError();
          } else {
            // Otros errores (red, server caído, etc.) sí pueden ser
            // específicos — no son enumeration de cuentas.
            Get.snackbar(
              'Error de Login',
              failure.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red.shade100,
              colorText: Colors.red.shade800,
              icon: const Icon(Icons.error, color: Colors.red),
            );
          }
        },
        (authResult) async {
          print('✅ AuthController: Login exitoso - ${authResult.user.email}');
          print(
            '🔧 AuthController: Token recibido - ${authResult.token.substring(0, 20)}...',
          );

          // Phase 3 — Validar que el "Negocio" declarado por el usuario
          // COINCIDA con la organización real del correo. Si no coincide,
          // mostrar el MISMO mensaje genérico que se muestra ante
          // credenciales inválidas — NO revelar el nombre real del negocio
          // (eso sería enumeration: un atacante con solo el correo podría
          // descubrir a qué empresa pertenece el usuario).
          final declaredBusiness = loginBusinessController.text.trim();
          final realOrgName =
              authResult.user.organizationName?.trim() ?? '';
          final businessMatches = realOrgName.isNotEmpty &&
              declaredBusiness.toLowerCase() == realOrgName.toLowerCase();
          if (!businessMatches) {
            // No guardamos token, no navegamos. Mensaje genérico
            // indistinguible del de password incorrecta para no filtrar
            // si lo que falló fue la pass o el nombre del negocio.
            _showGenericLoginError();
            return;
          }

          _isAuthenticated.value = true;
          _currentUser.value = authResult.user;

          // ✅ CRÍTICO: detectar cambio de tenant ANTES de cualquier sync.
          // Solo se borra la BD ISAR si el usuario que entra es DIFERENTE
          // al que cerró sesión. Si es el mismo, el cache offline se preserva.
          await _handleTenantSwitchIfNeeded(authResult.user.id);

          // CRÍTICO: Establecer tenant del usuario después del login exitoso
          await _setTenantAfterLogin(authResult.user);

          // Recargar suscripción ahora que tenemos JWT válido
          if (Get.isRegistered<SubscriptionController>()) {
            Get.find<SubscriptionController>().loadSubscription();
          }

          // Cargar permisos granulares del usuario actual. El servicio
          // cachea en memoria; las pantallas usarán PermissionsService.to
          // para verificar acceso a módulos y acciones.
          try {
            await Get.find<PermissionsService>()
                .loadCurrentUserPermissions(authResult.user.role);
          } catch (e) {
            print('⚠️ Error cargando permisos: $e');
          }

          // Guardar el correo para recordarlo en futuros logins
          await _saveEmailAfterSuccessfulLogin(
            loginEmailController.text.trim(),
          );

          // Phase 3 — Guardar SIEMPRE el organization.name REAL devuelto
          // por el backend (no lo que el usuario tipeó), así para usuarios
          // que ya estaban registrados antes de este feature, el nombre
          // correcto del negocio queda persistido en el dispositivo desde
          // el primer login post-update.
          final realBusiness = authResult.user.organizationName?.trim() ?? '';
          if (realBusiness.isNotEmpty) {
            try {
              await _secureStorageService.saveLastBusiness(realBusiness);
              _hasRememberedBusiness.value = true;
              loginBusinessController.text = realBusiness;
            } catch (_) {}
          }

          _clearLoginForm();

          print('🔧 AuthController: Navegando al dashboard...');
          // Navegar al dashboard
          Get.offAllNamed(AppRoutes.dashboard);
          Get.snackbar(
            'Bienvenido',
            'Sesión iniciada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );

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

          print('🔧 AuthController: Navegando a verificación de email...');
          // Navegar primero, luego snackbar
          Get.offAllNamed(AppRoutes.verifyEmail, arguments: {'email': email});
          Get.snackbar(
            'Registro Exitoso',
            '¡Cuenta creada! Verifica tu correo electrónico para continuar.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            duration: const Duration(seconds: 4),
          );
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
          // CRÍTICO: cuando la app abre con sesión persistida (sin pasar
          // por login), también necesitamos cargar permisos. Sin esto el
          // drawer queda oculto al reabrir la app porque el cache de
          // permisos está vacío y canView retorna false en todo.
          _loadPermissionsSafely(user.role);
        },
      );
    } finally {
      _isProfileLoading.value = false;
    }
  }

  /// Carga permisos sin bloquear el flow. Si falla, loguea pero no
  /// rompe la app — el usuario simplemente verá un drawer recortado
  /// hasta que la siguiente carga funcione.
  void _loadPermissionsSafely(UserRole role) {
    try {
      if (Get.isRegistered<PermissionsService>()) {
        // Fire-and-forget: el drawer reactivo (Obx en rxPermissions)
        // se actualizará cuando los permisos lleguen.
        Get.find<PermissionsService>().loadCurrentUserPermissions(role);
      }
    } catch (e) {
      print('⚠️ Error disparando carga de permisos: $e');
    }
  }

  /// Cerrar sesión.
  ///
  /// **Orden de operaciones (CRÍTICO para resiliencia):**
  /// 1. Persistir `lastUserId` con AWAIT antes de cualquier limpieza.
  ///    Si la app muere durante el logout, el próximo login del MISMO
  ///    usuario detecta "tenant igual" y preserva el cache ISAR.
  /// 2. Llamar al backend para invalidar la sesión.
  /// 3. Si backend OK → limpiar locales y navegar.
  /// 4. Si backend FALLA → forzar limpieza local igual (el usuario quiere
  ///    salir y los datos sensibles deben borrarse aunque la red caiga).
  Future<void> logout() async {
    _isLoading.value = true;

    // PASO 1: Persistir lastUserId DEFENSIVAMENTE antes de tocar nada.
    // Esto asegura que el próximo login detecte correctamente si es el
    // mismo tenant (preserva cache) o diferente (borra cache).
    try {
      final currentUserId = _currentUser.value?.id;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        final storage = Get.find<SecureStorageService>();
        await storage.setLastUserId(currentUserId);
      }
    } catch (e) {
      print('⚠️ AuthController: No se pudo persistir lastUserId en logout: $e');
    }

    try {
      final result = await _logoutUseCase(const NoParams());

      // Función helper para limpieza local. Se ejecuta en AMBOS paths
      // (éxito o fallo del backend) para garantizar que los datos
      // sensibles se borren del dispositivo aunque la red haya caído.
      Future<void> doLocalCleanup({required bool navigate}) async {
        _isAuthenticated.value = false;
        _currentUser.value = null;

        // Defensa final: si el repo falló al borrar credenciales, lo
        // intentamos de nuevo aquí. Sin esto, en próximo arranque el
        // token "fantasma" haría que la app entre logueada sin user.
        try {
          final storage = Get.find<SecureStorageService>();
          await storage.deleteToken();
          await storage.deleteRefreshToken();
          await storage.deleteUserData();
        } catch (e) {
          print('⚠️ Limpieza de token de respaldo falló: $e');
        }

        try {
          ProductFormController.clearCategoriesCache();
        } catch (e) {
          print('⚠️ Error al limpiar cache de categorías: $e');
        }

        // Resetear estado en memoria de controllers permanent que guardan
        // datos del tenant (CashRegister, etc.). Sin esto el badge de caja
        // mostraría la caja del usuario que hizo logout hasta el próximo
        // login + refresh. En logout NO disparamos reload (no hay tenant).
        _resetPermanentTenantControllers(triggerReload: false);

        _clearAllForms();

        if (navigate) {
          Get.offAllNamed(AppRoutes.login);
        }
      }

      // Extraemos los datos de result con fold y luego ejecutamos la
      // limpieza con await — fold() no permite awaitear callbacks async.
      final failureMessage = result.fold(
        (failure) => failure.message,
        (_) => null,
      );

      // Ejecutar cleanup CON await para garantizar que el token se borre
      // antes de navegar al login.
      await doLocalCleanup(navigate: true);

      if (failureMessage != null) {
        print('⚠️ Logout backend falló: $failureMessage — limpieza local forzada');
        Get.snackbar(
          'Sesión Cerrada',
          'Has cerrado sesión (offline)',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          icon: const Icon(Icons.cloud_off, color: Colors.orange),
        );
      } else {
        Get.snackbar(
          'Sesión Cerrada',
          'Has cerrado sesión exitosamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.blue.shade100,
          colorText: Colors.blue.shade800,
          icon: const Icon(Icons.info, color: Colors.blue),
        );
      }
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

  /// Cambiar contraseña sin mostrar snackbar ni cerrar diálogos.
  /// Retorna true si fue exitoso, lanza excepción si falla.
  Future<bool> changePasswordSilent() async {
    if (!changePasswordFormKey.currentState!.validate()) return false;

    final result = await _changePasswordUseCase(
      ChangePasswordParams(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (_) {
        _clearChangePasswordForm();
        return true;
      },
    );
  }

  /// Actualiza nombre, apellido y/o teléfono del usuario actual. Funciona
  /// online y offline: el repositorio encola en SyncQueue si no hay red.
  /// Retorna true si el cambio fue aplicado (incluso si quedó en cola).
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _isLoading.value = true;
    try {
      final repo = Get.find<AuthRepository>();
      final result = await repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      return result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
          return false;
        },
        (updatedUser) {
          _currentUser.value = updatedUser;
          Get.snackbar(
            'Perfil actualizado',
            'Tus datos fueron actualizados correctamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
          );
          if (Get.isDialogOpen == true) Get.back();
          return true;
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== EMAIL VERIFICATION & PASSWORD RESET ====================

  /// Verificar email con código de 6 dígitos
  Future<void> verifyEmail(String email, String code) async {
    final result = await _verifyEmailUseCase(
      VerifyEmailParams(email: email, code: code),
    );
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => print('✅ AuthController: Email verificado exitosamente'),
    );
  }

  /// Reenviar código de verificación de email
  Future<void> resendVerificationCode(String email) async {
    final result = await _resendVerificationUseCase(
      ResendVerificationParams(email: email),
    );
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => print('✅ AuthController: Código de verificación reenviado'),
    );
  }

  /// Solicitar código de recuperación de contraseña
  Future<void> forgotPassword(String email) async {
    final result = await _forgotPasswordUseCase(
      ForgotPasswordParams(email: email),
    );
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => print('✅ AuthController: Código de recuperación enviado'),
    );
  }

  /// Reenviar código de recuperación de contraseña (usa forgotPassword)
  Future<void> resendForgotPasswordCode(String email) async {
    await forgotPassword(email);
  }

  /// Restablecer contraseña con código
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final result = await _resetPasswordUseCase(
      ResetPasswordParams(email: email, code: code, newPassword: newPassword),
    );
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => print('✅ AuthController: Contraseña restablecida exitosamente'),
    );
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
          // Recargar suscripción con JWT válido
          if (Get.isRegistered<SubscriptionController>()) {
            Get.find<SubscriptionController>().loadSubscription();
          }
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

      // Phase 3 — Cargar el último negocio guardado en este dispositivo.
      // Si existe, pre-rellena el campo y marca el flag para que la UI
      // pueda mostrar el "Volver a entrar a TuNegocio" más amigable.
      final lastBusiness = await _secureStorageService.getLastBusiness();
      if (lastBusiness != null && lastBusiness.trim().isNotEmpty) {
        loginBusinessController.text = lastBusiness;
        _hasRememberedBusiness.value = true;
      }
    } catch (e) {
      print('⚠️ Error cargando correos guardados: $e');
    }
  }

  /// Olvida el negocio recordado en este dispositivo. Útil cuando el
  /// usuario cambia de empresa o presta el dispositivo.
  Future<void> clearRememberedBusiness() async {
    try {
      await _secureStorageService.clearLastBusiness();
      loginBusinessController.clear();
      _hasRememberedBusiness.value = false;
    } catch (_) {}
  }

  /// Phase 3 — Mensaje de error de login GENÉRICO. Mismo texto e
  /// indicador visual sin importar si lo que falló fue el correo, la
  /// contraseña o el nombre del negocio. Esto evita un ataque de
  /// enumeration: con solo el correo, un atacante NO debe poder
  /// descubrir a qué organización pertenece ni si la pass es correcta.
  ///
  /// Solo se llama desde paths donde NO se va a guardar token ni navegar.
  void _showGenericLoginError() {
    Get.snackbar(
      'No se pudo iniciar sesión',
      'Verifica que el negocio, correo y contraseña sean correctos.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }

  /// Configurar listener para el campo de email
  void _setupEmailListener() {
    loginEmailController.addListener(() {
      // Si se acaba de seleccionar un email, no reabrir las sugerencias
      if (_suppressSuggestions) return;

      final text = loginEmailController.text.toLowerCase().trim();
      if (text.isEmpty) {
        _showEmailSuggestions.value = false;
        return;
      }

      // Si el texto coincide exactamente con un email guardado, no mostrar sugerencias
      if (_savedEmails.any((email) => email.toLowerCase() == text)) {
        _showEmailSuggestions.value = false;
        return;
      }

      // Mostrar sugerencias solo si hay correos guardados que coincidan
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
    _suppressSuggestions = true;
    loginEmailController.text = email;
    _showEmailSuggestions.value = false;
    // Mover el cursor al final
    loginEmailController.selection = TextSelection.fromPosition(
      TextPosition(offset: email.length),
    );
    // Reactivar el listener después de que Flutter procese el cambio
    Future.microtask(() => _suppressSuggestions = false);
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
