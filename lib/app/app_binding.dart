// import 'package:get/get.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';

// import 'package:baudex_desktop/app/core/network/dio_client.dart';
// import 'package:baudex_desktop/app/core/network/network_info.dart';
// import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
// import 'package:baudex_desktop/features/auth/data/datasources/auth_remote_datasource.dart';
// import 'package:baudex_desktop/features/auth/data/datasources/auth_local_datasource.dart';
// import 'package:baudex_desktop/features/auth/data/repositories/auth_repository_impl.dart';
// import 'package:baudex_desktop/features/auth/domain/repositories/auth_repository.dart';
// import 'package:baudex_desktop/features/auth/domain/usecases/is_authenticated_usecase.dart';
// import 'package:baudex_desktop/features/auth/domain/usecases/login_usecase.dart';
// import 'package:baudex_desktop/features/auth/domain/usecases/logout_usecase.dart';
// import 'package:baudex_desktop/features/auth/domain/usecases/register_usecase.dart';
// import 'package:baudex_desktop/features/auth/domain/usecases/get_profile_usecase.dart';
// import 'package:baudex_desktop/features/auth/domain/usecases/change_password_usecase.dart';
// import 'package:baudex_desktop/features/auth/presentation/controllers/auth_controller.dart';

// class InitialBinding implements Bindings {
//   @override
//   void dependencies() {
//     // ==================== CORE DEPENDENCIES ====================
//     Get.lazyPut(() => DioClient(), fenix: true);
//     Get.lazyPut(() => SecureStorageService(), fenix: true);
//     Get.lazyPut<Connectivity>(() => Connectivity(), fenix: true);
//     Get.lazyPut<NetworkInfo>(
//       () => NetworkInfoImpl(Get.find<Connectivity>()),
//       fenix: true,
//     );

//     // ==================== AUTH DATA LAYER ====================
//     Get.lazyPut<AuthRemoteDataSource>(
//       () => AuthRemoteDataSourceImpl(dioClient: Get.find()),
//       fenix: true,
//     );
//     Get.lazyPut<AuthLocalDataSource>(
//       () => AuthLocalDataSourceImpl(storageService: Get.find()),
//       fenix: true,
//     );
//     Get.lazyPut<AuthRepository>(
//       () => AuthRepositoryImpl(
//         remoteDataSource: Get.find(),
//         localDataSource: Get.find(),
//         networkInfo: Get.find(),
//       ),
//       fenix: true,
//     );

//     // ==================== AUTH USE CASES ====================
//     Get.lazyPut(() => LoginUseCase(Get.find()), fenix: true);
//     Get.lazyPut(() => LogoutUseCase(Get.find()), fenix: true);
//     Get.lazyPut(() => IsAuthenticatedUseCase(Get.find()), fenix: true);
//     Get.lazyPut(() => RegisterUseCase(Get.find()), fenix: true);
//     Get.lazyPut(() => GetProfileUseCase(Get.find()), fenix: true);
//     Get.lazyPut(() => ChangePasswordUseCase(Get.find()), fenix: true);

//     // ==================== AUTH CONTROLLER (Permanent) ====================
//     Get.put(
//       AuthController(
//         loginUseCase: Get.find(),
//         logoutUseCase: Get.find(),
//         isAuthenticatedUseCase: Get.find(),
//         registerUseCase: Get.find(),
//         getProfileUseCase: Get.find(),
//         changePasswordUseCase: Get.find(),
//       ),
//       permanent: true,
//     );
//   }

//   @override
//   void onDispose() {
//     // Solo eliminar dependencias no permanentes si es necesario
//     // Las dependencias con fenix: true se auto-gestionan
//     // Las dependencias permanent: true no deben eliminarse aquí
//   }
// }

// lib/app/app_binding.dart
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// ==================== CORE IMPORTS ====================
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';

// ==================== AUTH IMPORTS ====================
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

// ==================== CUSTOMER IMPORTS ====================
import 'package:baudex_desktop/features/customers/presentation/bindings/customer_binding.dart';
import 'package:baudex_desktop/features/customers/domain/repositories/customer_repository.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customer_by_id_usecase.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:baudex_desktop/features/customers/domain/usecases/search_customers_usecase.dart';

// ==================== SHARED UI IMPORTS ====================
import 'package:baudex_desktop/app/shared/controllers/app_drawer_controller.dart';

// ==================== PRODUCT IMPORTS ====================
// TODO: Descomentar cuando tengas ProductBinding
// import 'package:baudex_desktop/features/products/presentation/bindings/product_binding.dart';
// import 'package:baudex_desktop/features/products/domain/repositories/product_repository.dart';
// import 'package:baudex_desktop/features/products/domain/usecases/get_products_usecase.dart';
// import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    print('🚀 InitialBinding: Iniciando dependencias globales...');
    print('📱 Modo: PRODUCCIÓN');

    // ==================== CORE DEPENDENCIES ====================
    _registerCoreDependencies();

    // ==================== SHARED UI CONTROLLERS ====================
    _registerSharedUIControllers();

    // ==================== AUTH MODULE ====================
    _registerAuthModule();

    // ==================== CUSTOMER MODULE ====================
    _registerCustomerModule();

    // ==================== PRODUCT MODULE ====================
    _registerProductModule();

    // ==================== VALIDACIÓN FINAL ====================
    _validateDependencies();

    print(
      '🎉 InitialBinding: Todas las dependencias globales registradas exitosamente',
    );
  }

  /// Registrar dependencias core del sistema
  void _registerCoreDependencies() {
    print('📦 Registrando dependencias core...');

    Get.lazyPut(() => DioClient(), fenix: true);
    Get.lazyPut(() => SecureStorageService(), fenix: true);
    Get.lazyPut<Connectivity>(() => Connectivity(), fenix: true);
    Get.lazyPut<NetworkInfo>(
      () => NetworkInfoImpl(Get.find<Connectivity>()),
      fenix: true,
    );

    print('✅ Dependencias core registradas');
  }

  /// Registrar controladores compartidos de UI
  void _registerSharedUIControllers() {
    print('🎨 Registrando controladores de UI compartidos...');

    try {
      // AppDrawer Controller (global para navegación)
      Get.lazyPut<AppDrawerController>(
        () => AppDrawerController(),
        fenix: true,
      );

      print('✅ Controladores de UI compartidos registrados');
      print('   - AppDrawerController: ✅');
    } catch (e) {
      print('❌ Error registrando controladores de UI: $e');
      rethrow;
    }
  }

  /// Registrar módulo de autenticación
  void _registerAuthModule() {
    print('🔐 Registrando módulo de autenticación...');

    try {
      // AUTH DATA LAYER
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

      // AUTH USE CASES
      Get.lazyPut(() => LoginUseCase(Get.find()), fenix: true);
      Get.lazyPut(() => LogoutUseCase(Get.find()), fenix: true);
      Get.lazyPut(() => IsAuthenticatedUseCase(Get.find()), fenix: true);
      Get.lazyPut(() => RegisterUseCase(Get.find()), fenix: true);
      Get.lazyPut(() => GetProfileUseCase(Get.find()), fenix: true);
      Get.lazyPut(() => ChangePasswordUseCase(Get.find()), fenix: true);

      // AUTH CONTROLLER (Permanent)
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

      print('✅ Módulo de autenticación registrado');
    } catch (e) {
      print('❌ Error registrando módulo de autenticación: $e');
      rethrow; // En producción, fallar si auth no se puede inicializar
    }
  }

  /// Registrar módulo de clientes
  void _registerCustomerModule() {
    print('👥 Registrando módulo de clientes...');

    try {
      // Inicializar CustomerBinding que incluye todas las dependencias de Customer
      CustomerBinding().dependencies();

      // Verificar que las dependencias críticas estén disponibles
      final isCustomerRepoRegistered = Get.isRegistered<CustomerRepository>();
      final isGetCustomerByIdRegistered =
          Get.isRegistered<GetCustomerByIdUseCase>();

      if (isCustomerRepoRegistered && isGetCustomerByIdRegistered) {
        print('✅ Módulo de clientes registrado correctamente');
        print('   - CustomerRepository: ✅');
        print('   - GetCustomerByIdUseCase: ✅');
        print(
          '   - GetCustomersUseCase: ${Get.isRegistered<GetCustomersUseCase>() ? "✅" : "❌"}',
        );
        print(
          '   - SearchCustomersUseCase: ${Get.isRegistered<SearchCustomersUseCase>() ? "✅" : "❌"}',
        );
      } else {
        throw Exception(
          'Dependencias críticas de Customer no se registraron correctamente',
        );
      }
    } catch (e) {
      print('❌ Error registrando módulo de clientes: $e');
      print(
        '⚠️ ADVERTENCIA: InvoiceFormController usará datos mock para clientes',
      );
      // En producción, podrías decidir si quieres fallar aquí o continuar
      // rethrow; // Descomenta si quieres fallar en caso de error
    }
  }

  /// Registrar módulo de productos
  void _registerProductModule() {
    print('📦 Registrando módulo de productos...');

    try {
      // TODO: Cuando tengas ProductBinding, descomenta estas líneas:
      /*
      ProductBinding().dependencies();
      
      final isProductRepoRegistered = Get.isRegistered<ProductRepository>();
      final isGetProductsRegistered = Get.isRegistered<GetProductsUseCase>();
      
      if (isProductRepoRegistered && isGetProductsRegistered) {
        print('✅ Módulo de productos registrado correctamente');
        print('   - ProductRepository: ✅');
        print('   - GetProductsUseCase: ✅');
        print('   - SearchProductsUseCase: ${Get.isRegistered<SearchProductsUseCase>() ? "✅" : "❌"}');
      } else {
        throw Exception('Dependencias críticas de Product no se registraron correctamente');
      }
      */

      // ✅ TEMPORAL: Mientras no tengas ProductBinding
      print('⚠️ ProductBinding no implementado aún');
      print('ℹ️ InvoiceFormController usará datos mock para productos');
    } catch (e) {
      print('❌ Error registrando módulo de productos: $e');
      print(
        '⚠️ ADVERTENCIA: InvoiceFormController usará datos mock para productos',
      );
      // En producción, podrías decidir si quieres fallar aquí o continuar
    }
  }

  /// Validar que todas las dependencias críticas estén registradas
  void _validateDependencies() {
    print('🔍 Validando dependencias críticas...');

    final criticalDependencies = {
      'DioClient': Get.isRegistered<DioClient>(),
      'NetworkInfo': Get.isRegistered<NetworkInfo>(),
      'SecureStorageService': Get.isRegistered<SecureStorageService>(),
      'AuthRepository': Get.isRegistered<AuthRepository>(),
      'AuthController': Get.isRegistered<AuthController>(),
      'CustomerRepository': Get.isRegistered<CustomerRepository>(),
      'GetCustomerByIdUseCase': Get.isRegistered<GetCustomerByIdUseCase>(),
    };

    final failedDependencies =
        criticalDependencies.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

    if (failedDependencies.isEmpty) {
      print('✅ Todas las dependencias críticas están registradas');
    } else {
      print('❌ Dependencias críticas faltantes:');
      for (String dependency in failedDependencies) {
        print('   - $dependency');
      }
      throw Exception(
        'Faltan dependencias críticas: ${failedDependencies.join(", ")}',
      );
    }
  }

  @override
  void onDispose() {
    print('🧹 InitialBinding: Limpiando dependencias...');
    // Solo eliminar dependencias no permanentes si es necesario
    // Las dependencias con fenix: true se auto-gestionan
    // Las dependencias permanent: true no deben eliminarse aquí
  }

  /// Método para debugging en desarrollo
  static void debugDependencies() {
    print('🔍 DEBUG: Estado completo de dependencias globales:');

    // Core
    print('📦 Core Dependencies:');
    print('   - DioClient: ${Get.isRegistered<DioClient>() ? "✅" : "❌"}');
    print('   - NetworkInfo: ${Get.isRegistered<NetworkInfo>() ? "✅" : "❌"}');
    print(
      '   - SecureStorageService: ${Get.isRegistered<SecureStorageService>() ? "✅" : "❌"}',
    );
    print('   - Connectivity: ${Get.isRegistered<Connectivity>() ? "✅" : "❌"}');

    // Auth
    print('🔐 Auth Dependencies:');
    print(
      '   - AuthRepository: ${Get.isRegistered<AuthRepository>() ? "✅" : "❌"}',
    );
    print(
      '   - AuthController: ${Get.isRegistered<AuthController>() ? "✅" : "❌"}',
    );
    print('   - LoginUseCase: ${Get.isRegistered<LoginUseCase>() ? "✅" : "❌"}');
    print(
      '   - LogoutUseCase: ${Get.isRegistered<LogoutUseCase>() ? "✅" : "❌"}',
    );

    // Customer
    print('👥 Customer Dependencies:');
    print(
      '   - CustomerRepository: ${Get.isRegistered<CustomerRepository>() ? "✅" : "❌"}',
    );
    print(
      '   - GetCustomerByIdUseCase: ${Get.isRegistered<GetCustomerByIdUseCase>() ? "✅" : "❌"}',
    );
    print(
      '   - GetCustomersUseCase: ${Get.isRegistered<GetCustomersUseCase>() ? "✅" : "❌"}',
    );
    print(
      '   - SearchCustomersUseCase: ${Get.isRegistered<SearchCustomersUseCase>() ? "✅" : "❌"}',
    );

    // Product (cuando esté implementado)
    print('📦 Product Dependencies:');
    print('   - ProductRepository: ⚠️ No implementado');
    print('   - GetProductsUseCase: ⚠️ No implementado');
    print('   - SearchProductsUseCase: ⚠️ No implementado');

    print('🏁 Debug completado');
  }

  /// Método para obtener un reporte de estado
  static Map<String, dynamic> getDependencyReport() {
    return {
      'core': {
        'DioClient': Get.isRegistered<DioClient>(),
        'NetworkInfo': Get.isRegistered<NetworkInfo>(),
        'SecureStorageService': Get.isRegistered<SecureStorageService>(),
      },
      'auth': {
        'AuthRepository': Get.isRegistered<AuthRepository>(),
        'AuthController': Get.isRegistered<AuthController>(),
      },
      'customer': {
        'CustomerRepository': Get.isRegistered<CustomerRepository>(),
        'GetCustomerByIdUseCase': Get.isRegistered<GetCustomerByIdUseCase>(),
        'GetCustomersUseCase': Get.isRegistered<GetCustomersUseCase>(),
        'SearchCustomersUseCase': Get.isRegistered<SearchCustomersUseCase>(),
      },
      'product': {
        'ProductRepository': false, // Temporal
        'GetProductsUseCase': false, // Temporal
        'SearchProductsUseCase': false, // Temporal
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
