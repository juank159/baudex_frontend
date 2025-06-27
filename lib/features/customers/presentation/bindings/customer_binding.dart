// // lib/features/customers/presentation/bindings/customer_binding.dart
// import 'package:baudex_desktop/features/customers/presentation/controllers/customer_detail_controller.dart';
// import 'package:baudex_desktop/features/customers/presentation/controllers/customer_form_controller.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/network/dio_client.dart';
// import '../../../../app/core/network/network_info.dart';
// import '../../../../app/core/storage/secure_storage_service.dart';
// import '../../data/datasources/customer_remote_datasource.dart';
// import '../../data/datasources/customer_local_datasource.dart';
// import '../../data/repositories/customer_repository_impl.dart';
// import '../../domain/repositories/customer_repository.dart';
// import '../../domain/usecases/get_customers_usecase.dart';
// import '../../domain/usecases/get_customer_by_id_usecase.dart';
// import '../../domain/usecases/create_customer_usecase.dart';
// import '../../domain/usecases/update_customer_usecase.dart';
// import '../../domain/usecases/delete_customer_usecase.dart';
// import '../../domain/usecases/search_customers_usecase.dart';
// import '../../domain/usecases/get_customer_stats_usecase.dart';
// import '../controllers/customers_controller.dart';

// class CustomerBinding extends Bindings {
//   @override
//   void dependencies() {
//     print('🔄 Inicializando Customer Binding...');

//     // ==================== DATA SOURCES ====================

//     // Remote DataSource
//     Get.lazyPut<CustomerRemoteDataSource>(
//       () => CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
//       fenix: true,
//     );

//     // Local DataSource
//     Get.lazyPut<CustomerLocalDataSource>(
//       () => CustomerLocalDataSourceImpl(
//         storageService: Get.find<SecureStorageService>(),
//       ),
//       fenix: true,
//     );

//     // ==================== REPOSITORY ====================

//     Get.lazyPut<CustomerRepository>(
//       () => CustomerRepositoryImpl(
//         remoteDataSource: Get.find<CustomerRemoteDataSource>(),
//         localDataSource: Get.find<CustomerLocalDataSource>(),
//         networkInfo: Get.find<NetworkInfo>(),
//       ),
//       fenix: true,
//     );

//     // ==================== USE CASES ====================

//     Get.lazyPut<GetCustomersUseCase>(
//       () => GetCustomersUseCase(Get.find<CustomerRepository>()),
//       fenix: true,
//     );

//     Get.lazyPut<GetCustomerByIdUseCase>(
//       () => GetCustomerByIdUseCase(Get.find<CustomerRepository>()),
//       fenix: true,
//     );

//     Get.lazyPut<CreateCustomerUseCase>(
//       () => CreateCustomerUseCase(Get.find<CustomerRepository>()),
//       fenix: true,
//     );

//     Get.lazyPut<UpdateCustomerUseCase>(
//       () => UpdateCustomerUseCase(Get.find<CustomerRepository>()),
//       fenix: true,
//     );

//     Get.lazyPut<DeleteCustomerUseCase>(
//       () => DeleteCustomerUseCase(Get.find<CustomerRepository>()),
//       fenix: true,
//     );

//     Get.lazyPut<SearchCustomersUseCase>(
//       () => SearchCustomersUseCase(Get.find<CustomerRepository>()),
//       fenix: true,
//     );

//     Get.lazyPut<GetCustomerStatsUseCase>(
//       () => GetCustomerStatsUseCase(Get.find<CustomerRepository>()),
//       fenix: true,
//     );

//     // ==================== CONTROLLERS ====================

//     Get.lazyPut<CustomersController>(
//       () => CustomersController(
//         getCustomersUseCase: Get.find<GetCustomersUseCase>(),
//         deleteCustomerUseCase: Get.find<DeleteCustomerUseCase>(),
//         searchCustomersUseCase: Get.find<SearchCustomersUseCase>(),
//         getCustomerStatsUseCase: Get.find<GetCustomerStatsUseCase>(),
//       ),
//       fenix: true,
//     );

//     print('✅ Customer Binding inicializado correctamente');
//   }
// }

// // Binding específico para formulario de clientes
// class CustomerFormBinding extends Bindings {
//   @override
//   void dependencies() {
//     print('🔄 Inicializando Customer Form Binding...');

//     // Asegurar que tenemos las dependencias base
//     if (!Get.isRegistered<CustomerRepository>()) {
//       CustomerBinding().dependencies();
//     }

//     // Controller específico del formulario
//     Get.lazyPut<CustomerFormController>(
//       () => CustomerFormController(
//         createCustomerUseCase: Get.find<CreateCustomerUseCase>(),
//         updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
//         getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
//         customerRepository: Get.find<CustomerRepository>(),
//       ),
//       fenix: true,
//     );

//     print('✅ Customer Form Binding inicializado correctamente');
//   }
// }

// // Binding específico para detalles de cliente
// class CustomerDetailBinding extends Bindings {
//   @override
//   void dependencies() {
//     print('🔄 Inicializando Customer Detail Binding...');

//     // Asegurar que tenemos las dependencias base
//     if (!Get.isRegistered<CustomerRepository>()) {
//       CustomerBinding().dependencies();
//     }

//     // Controller específico de detalles
//     Get.lazyPut<CustomerDetailController>(
//       () => CustomerDetailController(
//         getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
//         updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
//         deleteCustomerUseCase: Get.find<DeleteCustomerUseCase>(),
//         customerRepository: Get.find<CustomerRepository>(),
//       ),
//       fenix: true,
//     );

//     print('✅ Customer Detail Binding inicializado correctamente');
//   }
// }
// lib/features/customers/presentation/bindings/customer_binding.dart
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/datasources/customer_local_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/get_customer_by_id_usecase.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';
import '../../domain/usecases/search_customers_usecase.dart';
import '../../domain/usecases/get_customer_stats_usecase.dart';
import '../controllers/customers_controller.dart';
import '../controllers/customer_stats_controller.dart';
import '../controllers/customer_detail_controller.dart';
import '../controllers/customer_form_controller.dart';

/// Binding principal para el módulo de clientes
/// Incluye todas las dependencias base y controllers principales
class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    print('🔄 Inicializando Customer Binding...');

    // ==================== DATA SOURCES ====================

    // Remote DataSource
    Get.lazyPut<CustomerRemoteDataSource>(
      () => CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      fenix: true,
    );

    // Local DataSource
    Get.lazyPut<CustomerLocalDataSource>(
      () => CustomerLocalDataSourceImpl(
        storageService: Get.find<SecureStorageService>(),
      ),
      fenix: true,
    );

    // ==================== REPOSITORY ====================

    Get.lazyPut<CustomerRepository>(
      () => CustomerRepositoryImpl(
        remoteDataSource: Get.find<CustomerRemoteDataSource>(),
        localDataSource: Get.find<CustomerLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      fenix: true,
    );

    // ==================== USE CASES ====================

    Get.lazyPut<GetCustomersUseCase>(
      () => GetCustomersUseCase(Get.find<CustomerRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetCustomerByIdUseCase>(
      () => GetCustomerByIdUseCase(Get.find<CustomerRepository>()),
      fenix: true,
    );

    Get.lazyPut<CreateCustomerUseCase>(
      () => CreateCustomerUseCase(Get.find<CustomerRepository>()),
      fenix: true,
    );

    Get.lazyPut<UpdateCustomerUseCase>(
      () => UpdateCustomerUseCase(Get.find<CustomerRepository>()),
      fenix: true,
    );

    Get.lazyPut<DeleteCustomerUseCase>(
      () => DeleteCustomerUseCase(Get.find<CustomerRepository>()),
      fenix: true,
    );

    Get.lazyPut<SearchCustomersUseCase>(
      () => SearchCustomersUseCase(Get.find<CustomerRepository>()),
      fenix: true,
    );

    Get.lazyPut<GetCustomerStatsUseCase>(
      () => GetCustomerStatsUseCase(Get.find<CustomerRepository>()),
      fenix: true,
    );

    // ==================== CONTROLLERS ====================

    // Controller principal de listado de clientes
    Get.lazyPut<CustomersController>(
      () => CustomersController(
        getCustomersUseCase: Get.find<GetCustomersUseCase>(),
        deleteCustomerUseCase: Get.find<DeleteCustomerUseCase>(),
        searchCustomersUseCase: Get.find<SearchCustomersUseCase>(),
      ),
      fenix: true,
    );

    // Controller de estadísticas (NUEVO)
    Get.lazyPut<CustomerStatsController>(
      () => CustomerStatsController(
        getCustomerStatsUseCase: Get.find<GetCustomerStatsUseCase>(),
        customerRepository: Get.find<CustomerRepository>(),
      ),
      fenix: true,
    );

    print('✅ Customer Binding inicializado correctamente');
  }
}

/// Binding específico para formulario de clientes
/// Se usa para crear y editar clientes
class CustomerFormBinding extends Bindings {
  @override
  void dependencies() {
    print('🔄 Inicializando Customer Form Binding...');

    // Asegurar que tenemos las dependencias base
    if (!Get.isRegistered<CustomerRepository>()) {
      CustomerBinding().dependencies();
    }

    // Controller específico del formulario
    Get.lazyPut<CustomerFormController>(
      () => CustomerFormController(
        createCustomerUseCase: Get.find<CreateCustomerUseCase>(),
        updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
        getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
        customerRepository: Get.find<CustomerRepository>(),
      ),
      fenix: true,
    );

    print('✅ Customer Form Binding inicializado correctamente');
  }
}

/// Binding específico para detalles de cliente
/// Se usa para mostrar información detallada de un cliente
class CustomerDetailBinding extends Bindings {
  @override
  void dependencies() {
    print('🔄 Inicializando Customer Detail Binding...');

    // Asegurar que tenemos las dependencias base
    if (!Get.isRegistered<CustomerRepository>()) {
      CustomerBinding().dependencies();
    }

    // Controller específico de detalles
    Get.lazyPut<CustomerDetailController>(
      () => CustomerDetailController(
        getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
        updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
        deleteCustomerUseCase: Get.find<DeleteCustomerUseCase>(),
        customerRepository: Get.find<CustomerRepository>(),
      ),
      fenix: true,
    );

    print('✅ Customer Detail Binding inicializado correctamente');
  }
}

/// Binding específico para pantalla de estadísticas
/// Se usa exclusivamente para la pantalla de estadísticas completas
class CustomerStatsBinding extends Bindings {
  @override
  void dependencies() {
    print('🔄 Inicializando Customer Stats Binding...');

    // Asegurar que tenemos las dependencias base
    if (!Get.isRegistered<CustomerRepository>()) {
      CustomerBinding().dependencies();
    }

    // Controller de estadísticas (si no está ya registrado)
    if (!Get.isRegistered<CustomerStatsController>()) {
      Get.lazyPut<CustomerStatsController>(
        () => CustomerStatsController(
          getCustomerStatsUseCase: Get.find<GetCustomerStatsUseCase>(),
          customerRepository: Get.find<CustomerRepository>(),
        ),
        fenix: true,
      );
    }

    print('✅ Customer Stats Binding inicializado correctamente');
  }
}

/// Binding completo para todas las pantallas de clientes
/// Usar cuando necesites acceso a todos los controllers simultáneamente
class CustomerFullBinding extends Bindings {
  @override
  void dependencies() {
    print('🔄 Inicializando Customer Full Binding...');

    // Inicializar dependencias base
    CustomerBinding().dependencies();

    // ==================== CONTROLLERS ADICIONALES ====================

    // Controller de formulario
    if (!Get.isRegistered<CustomerFormController>()) {
      Get.lazyPut<CustomerFormController>(
        () => CustomerFormController(
          createCustomerUseCase: Get.find<CreateCustomerUseCase>(),
          updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
          getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
          customerRepository: Get.find<CustomerRepository>(),
        ),
        fenix: true,
      );
    }

    // Controller de detalles
    if (!Get.isRegistered<CustomerDetailController>()) {
      Get.lazyPut<CustomerDetailController>(
        () => CustomerDetailController(
          getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
          updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
          deleteCustomerUseCase: Get.find<DeleteCustomerUseCase>(),
          customerRepository: Get.find<CustomerRepository>(),
        ),
        fenix: true,
      );
    }

    // Controller de estadísticas (ya está en CustomerBinding)
    // Pero aseguramos que esté disponible
    if (!Get.isRegistered<CustomerStatsController>()) {
      Get.lazyPut<CustomerStatsController>(
        () => CustomerStatsController(
          getCustomerStatsUseCase: Get.find<GetCustomerStatsUseCase>(),
          customerRepository: Get.find<CustomerRepository>(),
        ),
        fenix: true,
      );
    }

    print('✅ Customer Full Binding inicializado correctamente');
  }
}

/// Binding optimizado para desarrollo/testing
/// Inicializa todos los controllers inmediatamente
class CustomerDevBinding extends Bindings {
  @override
  void dependencies() {
    print('🔄 Inicializando Customer Dev Binding (Modo Desarrollo)...');

    // ==================== DATA SOURCES ====================

    Get.put<CustomerRemoteDataSource>(
      CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
      permanent: true,
    );

    Get.put<CustomerLocalDataSource>(
      CustomerLocalDataSourceImpl(
        storageService: Get.find<SecureStorageService>(),
      ),
      permanent: true,
    );

    // ==================== REPOSITORY ====================

    Get.put<CustomerRepository>(
      CustomerRepositoryImpl(
        remoteDataSource: Get.find<CustomerRemoteDataSource>(),
        localDataSource: Get.find<CustomerLocalDataSource>(),
        networkInfo: Get.find<NetworkInfo>(),
      ),
      permanent: true,
    );

    // ==================== USE CASES ====================

    Get.put<GetCustomersUseCase>(
      GetCustomersUseCase(Get.find<CustomerRepository>()),
      permanent: true,
    );

    Get.put<GetCustomerByIdUseCase>(
      GetCustomerByIdUseCase(Get.find<CustomerRepository>()),
      permanent: true,
    );

    Get.put<CreateCustomerUseCase>(
      CreateCustomerUseCase(Get.find<CustomerRepository>()),
      permanent: true,
    );

    Get.put<UpdateCustomerUseCase>(
      UpdateCustomerUseCase(Get.find<CustomerRepository>()),
      permanent: true,
    );

    Get.put<DeleteCustomerUseCase>(
      DeleteCustomerUseCase(Get.find<CustomerRepository>()),
      permanent: true,
    );

    Get.put<SearchCustomersUseCase>(
      SearchCustomersUseCase(Get.find<CustomerRepository>()),
      permanent: true,
    );

    Get.put<GetCustomerStatsUseCase>(
      GetCustomerStatsUseCase(Get.find<CustomerRepository>()),
      permanent: true,
    );

    // ==================== CONTROLLERS ====================

    Get.put<CustomersController>(
      CustomersController(
        getCustomersUseCase: Get.find<GetCustomersUseCase>(),
        deleteCustomerUseCase: Get.find<DeleteCustomerUseCase>(),
        searchCustomersUseCase: Get.find<SearchCustomersUseCase>(),
      ),
      permanent: true,
    );

    Get.put<CustomerStatsController>(
      CustomerStatsController(
        getCustomerStatsUseCase: Get.find<GetCustomerStatsUseCase>(),
        customerRepository: Get.find<CustomerRepository>(),
      ),
      permanent: true,
    );

    Get.put<CustomerFormController>(
      CustomerFormController(
        createCustomerUseCase: Get.find<CreateCustomerUseCase>(),
        updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
        getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
        customerRepository: Get.find<CustomerRepository>(),
      ),
      permanent: true,
    );

    Get.put<CustomerDetailController>(
      CustomerDetailController(
        getCustomerByIdUseCase: Get.find<GetCustomerByIdUseCase>(),
        updateCustomerUseCase: Get.find<UpdateCustomerUseCase>(),
        deleteCustomerUseCase: Get.find<DeleteCustomerUseCase>(),
        customerRepository: Get.find<CustomerRepository>(),
      ),
      permanent: true,
    );

    print('✅ Customer Dev Binding inicializado correctamente');
  }
}

/// Helper para verificar el estado de los bindings
class CustomerBindingValidator {
  static void validateDependencies() {
    final dependencies = [
      'CustomerRemoteDataSource',
      'CustomerLocalDataSource',
      'CustomerRepository',
      'GetCustomersUseCase',
      'GetCustomerByIdUseCase',
      'CreateCustomerUseCase',
      'UpdateCustomerUseCase',
      'DeleteCustomerUseCase',
      'SearchCustomersUseCase',
      'GetCustomerStatsUseCase',
      'CustomersController',
      'CustomerStatsController',
    ];

    print('🔍 Validando dependencias de Customer Binding...');

    for (String dependency in dependencies) {
      final isRegistered = Get.isRegistered(tag: dependency);
      print('  ${isRegistered ? '✅' : '❌'} $dependency');
    }

    print('🏁 Validación completada');
  }

  static Map<String, bool> getDependencyStatus() {
    return {
      'CustomerRepository': Get.isRegistered<CustomerRepository>(),
      'CustomersController': Get.isRegistered<CustomersController>(),
      'CustomerStatsController': Get.isRegistered<CustomerStatsController>(),
      'CustomerFormController': Get.isRegistered<CustomerFormController>(),
      'CustomerDetailController': Get.isRegistered<CustomerDetailController>(),
      'GetCustomersUseCase': Get.isRegistered<GetCustomersUseCase>(),
      'GetCustomerStatsUseCase': Get.isRegistered<GetCustomerStatsUseCase>(),
    };
  }
}
