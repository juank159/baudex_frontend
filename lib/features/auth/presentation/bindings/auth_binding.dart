// // lib/features/auth/presentation/bindings/auth_binding.dart
// import 'package:get/get.dart';
// import '../../../../app/core/network/dio_client.dart';
// import '../../../../app/core/network/network_info.dart';
// import '../../../../app/core/storage/secure_storage_service.dart';
// import '../../data/datasources/auth_local_datasource.dart';
// import '../../data/datasources/auth_remote_datasource.dart';
// import '../../data/repositories/auth_repository_impl.dart';
// import '../../domain/repositories/auth_repository.dart';
// import '../../domain/usecases/login_usecase.dart';
// import '../../domain/usecases/register_usecase.dart';
// import '../../domain/usecases/get_profile_usecase.dart';
// import '../../domain/usecases/logout_usecase.dart';
// import '../../domain/usecases/change_password_usecase.dart';
// import '../../domain/usecases/is_authenticated_usecase.dart';
// import '../controllers/auth_controller.dart';

// class AuthBinding extends Bindings {
//   @override
//   void dependencies() {
//     // ==================== CORE DEPENDENCIES ====================

//     // Network y Storage (si no están ya registrados)
//     if (!Get.isRegistered<SecureStorageService>()) {
//       Get.lazyPut<SecureStorageService>(() => SecureStorageService());
//     }

//     if (!Get.isRegistered<DioClient>()) {
//       Get.lazyPut<DioClient>(() => DioClient());
//     }

//     if (!Get.isRegistered<NetworkInfo>()) {
//       Get.lazyPut<NetworkInfo>(() => NetworkInfoImpl());
//     }

//     // ==================== DATA LAYER ====================

//     // DataSources
//     Get.lazyPut<AuthRemoteDataSource>(
//       () => AuthRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
//     );

//     Get.lazyPut<AuthLocalDataSource>(
//       () => AuthLocalDataSourceImpl(
//         storageService: Get.find<SecureStorageService>(),
//       ),
//     );

//     // Repository
//     Get.lazyPut<AuthRepository>(
//       () => AuthRepositoryImpl(
//         remoteDataSource: Get.find<AuthRemoteDataSource>(),
//         localDataSource: Get.find<AuthLocalDataSource>(),
//         networkInfo: Get.find<NetworkInfo>(),
//       ),
//     );

//     // ==================== DOMAIN LAYER ====================

//     // Use Cases
//     Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()));
//     Get.lazyPut(() => RegisterUseCase(Get.find<AuthRepository>()));
//     Get.lazyPut(() => GetProfileUseCase(Get.find<AuthRepository>()));
//     Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()));
//     Get.lazyPut(() => ChangePasswordUseCase(Get.find<AuthRepository>()));
//     Get.lazyPut(() => IsAuthenticatedUseCase(Get.find<AuthRepository>()));

//     // ==================== PRESENTATION LAYER ====================

//     // Controller - usar put en lugar de lazyPut para mantener la instancia
//     Get.put<AuthController>(
//       AuthController(
//         loginUseCase: Get.find<LoginUseCase>(),
//         registerUseCase: Get.find<RegisterUseCase>(),
//         getProfileUseCase: Get.find<GetProfileUseCase>(),
//         logoutUseCase: Get.find<LogoutUseCase>(),
//         changePasswordUseCase: Get.find<ChangePasswordUseCase>(),
//         isAuthenticatedUseCase: Get.find<IsAuthenticatedUseCase>(),
//       ),
//       permanent: true, // Mantener la instancia durante toda la sesión de auth
//     );
//   }
// }

// /// Binding específico para inicialización de la app
// class InitialBinding extends Bindings {
//   @override
//   void dependencies() {
//     // Servicios core que necesitan estar disponibles desde el inicio
//     Get.put<SecureStorageService>(SecureStorageService(), permanent: true);
//     Get.put<DioClient>(DioClient(), permanent: true);
//     Get.put<NetworkInfo>(NetworkInfoImpl(), permanent: true);
//   }
// }

// /// Binding para páginas que solo necesitan verificar autenticación
// class AuthCheckBinding extends Bindings {
//   @override
//   void dependencies() {
//     // Solo las dependencias mínimas para verificar autenticación
//     if (!Get.isRegistered<AuthRepository>()) {
//       Get.lazyPut<AuthLocalDataSource>(
//         () => AuthLocalDataSourceImpl(
//           storageService: Get.find<SecureStorageService>(),
//         ),
//       );

//       Get.lazyPut<AuthRemoteDataSource>(
//         () => AuthRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
//       );

//       Get.lazyPut<AuthRepository>(
//         () => AuthRepositoryImpl(
//           remoteDataSource: Get.find<AuthRemoteDataSource>(),
//           localDataSource: Get.find<AuthLocalDataSource>(),
//           networkInfo: Get.find<NetworkInfo>(),
//         ),
//       );
//     }

//     if (!Get.isRegistered<IsAuthenticatedUseCase>()) {
//       Get.lazyPut(() => IsAuthenticatedUseCase(Get.find<AuthRepository>()));
//     }
//   }
// }

import 'package:get/get.dart';

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    // ✅ Este binding ya no es necesario porque todas las dependencias
    // de auth están en InitialBinding
    //
    // Solo se mantiene para compatibilidad, pero no registra nada
    // porque todo ya está disponible globalmente desde InitialBinding

    // Si necesitas registrar controladores específicos para pantallas
    // particulares (no AuthController), hazlo aquí

    print(
      '🔧 AuthBinding: Todas las dependencias ya están registradas en InitialBinding',
    );
  }

  @override
  void onDispose() {
    // No eliminar dependencias globales aquí
    print('🔧 AuthBinding: onDispose - manteniendo dependencias globales');
  }
}
