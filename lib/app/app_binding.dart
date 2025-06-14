import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:baudex_desktop/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:baudex_desktop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/is_authenticated_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/login_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/logout_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/register_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:baudex_desktop/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    // ==================== CORE DEPENDENCIES ====================
    Get.lazyPut(() => DioClient(), fenix: true);
    Get.lazyPut(() => SecureStorageService(), fenix: true);
    Get.lazyPut<Connectivity>(() => Connectivity(), fenix: true);
    Get.lazyPut<NetworkInfo>(
      () => NetworkInfoImpl(Get.find<Connectivity>()),
      fenix: true,
    );

    // ==================== AUTH DATA LAYER ====================
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dioClient: Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(storageService: Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: Get.find(),
        localDataSource: Get.find(),
        networkInfo: Get.find(),
      ),
      fenix: true,
    );

    // ==================== AUTH USE CASES ====================
    Get.lazyPut(() => LoginUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => LogoutUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => IsAuthenticatedUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => RegisterUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => GetProfileUseCase(Get.find()), fenix: true);
    Get.lazyPut(() => ChangePasswordUseCase(Get.find()), fenix: true);

    // ==================== AUTH CONTROLLER (Permanent) ====================
    Get.put(
      AuthController(
        loginUseCase: Get.find(),
        logoutUseCase: Get.find(),
        isAuthenticatedUseCase: Get.find(),
        registerUseCase: Get.find(),
        getProfileUseCase: Get.find(),
        changePasswordUseCase: Get.find(),
      ),
      permanent: true,
    );
  }

  @override
  void onDispose() {
    // Solo eliminar dependencias no permanentes si es necesario
    // Las dependencias con fenix: true se auto-gestionan
    // Las dependencias permanent: true no deben eliminarse aquí
  }
}
