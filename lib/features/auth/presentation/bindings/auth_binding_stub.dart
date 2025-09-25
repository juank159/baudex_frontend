// lib/features/auth/presentation/bindings/auth_binding_stub.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../data/datasources/auth_local_datasource_isar.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/register_with_onboarding_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';
import '../../domain/usecases/is_authenticated_usecase.dart';
import '../../../../core/storage/tenant_storage.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/network/dio_client.dart';

/// Binding híbrido para el AuthController
/// 
/// Registra dependencias reales: API backend + ISAR offline
class AuthBindingStub implements Bindings {
  @override
  void dependencies() {
    // Datasource local híbrido (SecureStorage + futura extensión ISAR)
    Get.lazyPut<AuthLocalDataSource>(
      () => AuthLocalDataSourceIsar(Get.find<SecureStorageService>()),
      fenix: true,
    );

    // Remote datasource real
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Tenant storage - usando implementación real
    Get.lazyPut<TenantStorage>(
      () => TenantStorageImpl(Get.find<SecureStorageService>()),
      fenix: true,
    );

    // Repositorio real de autenticación
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: Get.find<AuthRemoteDataSource>(),
        localDataSource: Get.find<AuthLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // Use cases - USAR IMPLEMENTACIONES REALES
    Get.lazyPut(
      () => LoginUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => RegisterUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => RegisterWithOnboardingUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => GetProfileUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => LogoutUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => ChangePasswordUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    Get.lazyPut(
      () => IsAuthenticatedUseCase(Get.find<AuthRepository>()),
      fenix: true,
    );

    // AuthController
    Get.put<AuthController>(
      AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        registerUseCase: Get.find<RegisterUseCase>(),
        registerWithOnboardingUseCase: Get.find<RegisterWithOnboardingUseCase>(),
        getProfileUseCase: Get.find<GetProfileUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
        changePasswordUseCase: Get.find<ChangePasswordUseCase>(),
        isAuthenticatedUseCase: Get.find<IsAuthenticatedUseCase>(),
        tenantStorage: Get.find<TenantStorage>(),
        secureStorageService: Get.find<SecureStorageService>(),
      ),
      permanent: true,
    );

    print('✅ AuthBindingReal: AuthController REAL registrado exitosamente (PostgreSQL + ISAR)');
  }
}