// // lib/features/products/presentation/bindings/product_binding.dart
// import 'package:baudex_desktop/app/core/network/dio_client.dart';
// import 'package:baudex_desktop/app/core/network/network_info.dart';
// import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:get/get.dart';

// import '../../data/datasources/product_remote_datasource.dart';
// import '../../data/datasources/product_local_datasource.dart';

// // Repository Imports
// import '../../data/repositories/product_repository_impl.dart';
// import '../../domain/repositories/product_repository.dart';

// // Use Cases Imports
// import '../../domain/usecases/get_products_usecase.dart';
// import '../../domain/usecases/get_product_by_id_usecase.dart';
// import '../../domain/usecases/create_product_usecase.dart';
// import '../../domain/usecases/update_product_usecase.dart';
// import '../../domain/usecases/delete_product_usecase.dart';
// import '../../domain/usecases/search_products_usecase.dart';
// import '../../domain/usecases/get_product_stats_usecase.dart';
// import '../../domain/usecases/update_product_stock_usecase.dart';
// import '../../domain/usecases/get_low_stock_products_usecase.dart';
// import '../../domain/usecases/get_products_by_category_usecase.dart';

// // Controllers Imports
// import '../controllers/products_controller.dart';
// import '../controllers/product_detail_controller.dart';
// import '../controllers/product_form_controller.dart';

// class ProductBinding implements Bindings {
//   @override
//   void dependencies() {
//     print('🔧 ProductBinding: Registrando dependencias...');

//     // ==================== DATA SOURCES ====================
//     Get.lazyPut<ProductRemoteDataSource>(
//       () => ProductRemoteDataSourceImpl(dioClient: Get.find()),
//       tag: 'ProductRemoteDataSource',
//     );

//     Get.lazyPut<ProductLocalDataSource>(
//       () => ProductLocalDataSourceImpl(storageService: Get.find()),
//       tag: 'ProductLocalDataSource',
//     );

//     // ==================== REPOSITORY ====================
//     Get.lazyPut<ProductRepository>(
//       () => ProductRepositoryImpl(
//         remoteDataSource: Get.find(tag: 'ProductRemoteDataSource'),
//         localDataSource: Get.find(tag: 'ProductLocalDataSource'),
//         networkInfo: Get.find(),
//       ),
//       tag: 'ProductRepository',
//     );

//     // ==================== USE CASES ====================
//     Get.lazyPut(() => GetProductsUseCase(Get.find(tag: 'ProductRepository')));
//     Get.lazyPut(
//       () => GetProductByIdUseCase(Get.find(tag: 'ProductRepository')),
//     );
//     Get.lazyPut(
//       () => SearchProductsUseCase(Get.find(tag: 'ProductRepository')),
//     );
//     Get.lazyPut(
//       () => GetProductStatsUseCase(Get.find(tag: 'ProductRepository')),
//     );
//     Get.lazyPut(
//       () => GetLowStockProductsUseCase(Get.find(tag: 'ProductRepository')),
//     );
//     Get.lazyPut(
//       () => GetProductsByCategoryUseCase(Get.find(tag: 'ProductRepository')),
//     );
//     Get.lazyPut(() => CreateProductUseCase(Get.find(tag: 'ProductRepository')));
//     Get.lazyPut(() => UpdateProductUseCase(Get.find(tag: 'ProductRepository')));
//     Get.lazyPut(
//       () => UpdateProductStockUseCase(Get.find(tag: 'ProductRepository')),
//     );
//     Get.lazyPut(() => DeleteProductUseCase(Get.find(tag: 'ProductRepository')));

//     // ==================== CONTROLLERS ====================
//     Get.lazyPut(
//       () => ProductsController(
//         getProductsUseCase: Get.find(),
//         searchProductsUseCase: Get.find(),
//         getProductStatsUseCase: Get.find(),
//         getLowStockProductsUseCase: Get.find(),
//         getProductsByCategoryUseCase: Get.find(),
//         deleteProductUseCase: Get.find(),
//       ),
//     );

//     // ✅ CONTROLADOR CORREGIDO - Sin el parámetro problemático
//     Get.lazyPut(
//       () => ProductDetailController(
//         getProductByIdUseCase: Get.find(),
//         updateProductStockUseCase: Get.find(),
//         deleteProductUseCase: Get.find(),
//       ),
//     );

//     Get.lazyPut(
//       () => ProductFormController(
//         createProductUseCase: Get.find(),
//         updateProductUseCase: Get.find(),
//         getProductByIdUseCase: Get.find(),
//       ),
//     );

//     print('✅ ProductBinding: Dependencias registradas exitosamente');
//   }

//   @override
//   void onDispose() {
//     print('🗑️ ProductBinding: Limpiando dependencias...');

//     // Controllers
//     Get.delete<ProductsController>();
//     Get.delete<ProductDetailController>();
//     Get.delete<ProductFormController>();

//     // Use Cases
//     Get.delete<GetProductsUseCase>();
//     Get.delete<GetProductByIdUseCase>();
//     Get.delete<SearchProductsUseCase>();
//     Get.delete<GetProductStatsUseCase>();
//     Get.delete<GetLowStockProductsUseCase>();
//     Get.delete<GetProductsByCategoryUseCase>();
//     Get.delete<CreateProductUseCase>();
//     Get.delete<UpdateProductUseCase>();
//     Get.delete<UpdateProductStockUseCase>();
//     Get.delete<DeleteProductUseCase>();

//     // Repository
//     Get.delete<ProductRepository>(tag: 'ProductRepository');

//     // DataSources
//     Get.delete<ProductRemoteDataSource>(tag: 'ProductRemoteDataSource');
//     Get.delete<ProductLocalDataSource>(tag: 'ProductLocalDataSource');
//   }

//   // ✅ MÉTODO DE VERIFICACIÓN MEJORADO
//   static void verifyDependencies() {
//     print('🔍 Verificando dependencias del módulo Products...');

//     final dependencies = [
//       () => Get.find<ProductRepository>(),
//       () => Get.find<ProductsController>(),
//       () => Get.find<ProductFormController>(),
//       () => Get.find<ProductDetailController>(),
//       () => Get.find<Connectivity>(),
//       () => Get.find<NetworkInfo>(),
//       () => Get.find<DioClient>(),
//       () => Get.find<SecureStorageService>(),
//     ];

//     final names = [
//       'ProductRepository',
//       'ProductsController',
//       'ProductFormController',
//       'ProductDetailController',
//       'Connectivity',
//       'NetworkInfo',
//       'DioClient',
//       'SecureStorageService',
//     ];

//     for (int i = 0; i < dependencies.length; i++) {
//       try {
//         dependencies[i]();
//         print('✅ ${names[i]} registrado');
//       } catch (e) {
//         print('❌ ${names[i]} no encontrado: $e');
//       }
//     }

//     print('🔍 Verificación completada');
//   }
// }

// lib/features/products/presentation/bindings/product_binding.dart
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

// Product Data Layer
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';

// Product Use Cases
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import '../../domain/usecases/get_product_stats_usecase.dart';
import '../../domain/usecases/update_product_stock_usecase.dart';
import '../../domain/usecases/get_low_stock_products_usecase.dart';
import '../../domain/usecases/get_products_by_category_usecase.dart';

// Category Use Cases (para ProductFormController)
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../../../categories/domain/usecases/search_categories_usecase.dart';

// Product Controllers
import '../controllers/products_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/product_form_controller.dart';

class ProductBinding implements Bindings {
  @override
  void dependencies() {
    print('🔧 ProductBinding: Iniciando registro de dependencias...');

    try {
      // ==================== STEP 1: VERIFICAR DEPENDENCIAS CORE ====================
      _verifyCoreDependencies();

      // ==================== STEP 2: VERIFICAR DEPENDENCIAS DE CATEGORÍAS ====================
      _verifyCategoryDependencies();

      // ==================== STEP 3: REGISTRAR DATA LAYER ====================
      _registerDataLayer();

      // ==================== STEP 4: REGISTRAR USE CASES ====================
      _registerUseCases();

      // ==================== STEP 5: REGISTRAR CONTROLLERS ====================
      _registerControllers();

      print(
        '✅ ProductBinding: Todas las dependencias registradas exitosamente',
      );
    } catch (e, stackTrace) {
      print('💥 ProductBinding: Error durante el registro de dependencias');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Verificar dependencias core del sistema
  void _verifyCoreDependencies() {
    print('🔍 ProductBinding: Verificando dependencias core...');

    final requiredDependencies = <String, bool>{
      'DioClient': Get.isRegistered<DioClient>(),
      'SecureStorageService': Get.isRegistered<SecureStorageService>(),
      'NetworkInfo': Get.isRegistered<NetworkInfo>(),
      'Connectivity': Get.isRegistered<Connectivity>(),
    };

    final missingDependencies =
        requiredDependencies.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

    if (missingDependencies.isNotEmpty) {
      final errorMsg = '''
❌ ProductBinding Error: Dependencias core faltantes

Dependencias faltantes: ${missingDependencies.join(', ')}

SOLUCIÓN:
1. Asegúrate de que InitialBinding().dependencies() se ejecute ANTES que ProductBinding
2. Verifica que las dependencias core estén correctamente registradas en InitialBinding
''';

      print(errorMsg);
      throw Exception(
        'ProductBinding requiere InitialBinding. Dependencias faltantes: ${missingDependencies.join(', ')}',
      );
    }

    print('✅ ProductBinding: Dependencias core verificadas');
  }

  /// Verificar dependencias de categorías (requeridas para ProductFormController)
  void _verifyCategoryDependencies() {
    print('🔍 ProductBinding: Verificando dependencias de categorías...');

    final categoryDependencies = <String, bool>{
      'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
      'SearchCategoriesUseCase': Get.isRegistered<SearchCategoriesUseCase>(),
    };

    final missingCategoryDeps =
        categoryDependencies.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

    if (missingCategoryDeps.isNotEmpty) {
      print('''
⚠️ ProductBinding Warning: Dependencias de categorías faltantes

Dependencias faltantes: ${missingCategoryDeps.join(', ')}

NOTA: El selector de categorías en ProductFormController tendrá funcionalidad limitada.

SOLUCIÓN RECOMENDADA:
1. Ejecutar CategoryBinding().dependencies() ANTES de ProductBinding
2. Orden correcto: InitialBinding → CategoryBinding → ProductBinding
''');
    } else {
      print('✅ ProductBinding: Dependencias de categorías verificadas');
    }
  }

  /// Registrar capa de datos
  void _registerDataLayer() {
    print('💾 ProductBinding: Registrando capa de datos...');

    // Remote DataSource
    if (!Get.isRegistered<ProductRemoteDataSource>()) {
      Get.lazyPut<ProductRemoteDataSource>(
        () => ProductRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
      print('  ✅ ProductRemoteDataSource registrado');
    }

    // Local DataSource
    if (!Get.isRegistered<ProductLocalDataSource>()) {
      Get.lazyPut<ProductLocalDataSource>(
        () => ProductLocalDataSourceImpl(
          storageService: Get.find<SecureStorageService>(),
        ),
        fenix: true,
      );
      print('  ✅ ProductLocalDataSource registrado');
    }

    // Repository
    if (!Get.isRegistered<ProductRepository>()) {
      Get.lazyPut<ProductRepository>(
        () => ProductRepositoryImpl(
          remoteDataSource: Get.find<ProductRemoteDataSource>(),
          localDataSource: Get.find<ProductLocalDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
        fenix: true,
      );
      print('  ✅ ProductRepository registrado');
    }
  }

  /// Registrar casos de uso
  void _registerUseCases() {
    print('🎯 ProductBinding: Registrando casos de uso...');

    final repository = Get.find<ProductRepository>();

    // Read Operations
    Get.lazyPut(() => GetProductsUseCase(repository), fenix: true);
    Get.lazyPut(() => GetProductByIdUseCase(repository), fenix: true);
    Get.lazyPut(() => SearchProductsUseCase(repository), fenix: true);
    Get.lazyPut(() => GetProductStatsUseCase(repository), fenix: true);
    Get.lazyPut(() => GetLowStockProductsUseCase(repository), fenix: true);
    Get.lazyPut(() => GetProductsByCategoryUseCase(repository), fenix: true);

    // Write Operations
    Get.lazyPut(() => CreateProductUseCase(repository), fenix: true);
    Get.lazyPut(() => UpdateProductUseCase(repository), fenix: true);
    Get.lazyPut(() => UpdateProductStockUseCase(repository), fenix: true);
    Get.lazyPut(() => DeleteProductUseCase(repository), fenix: true);

    print('  ✅ Todos los casos de uso de productos registrados');
  }

  /// Registrar controladores
  void _registerControllers() {
    print('🎮 ProductBinding: Registrando controladores...');

    // ProductsController
    if (!Get.isRegistered<ProductsController>()) {
      Get.lazyPut<ProductsController>(
        () => ProductsController(
          getProductsUseCase: Get.find<GetProductsUseCase>(),
          searchProductsUseCase: Get.find<SearchProductsUseCase>(),
          getProductStatsUseCase: Get.find<GetProductStatsUseCase>(),
          getLowStockProductsUseCase: Get.find<GetLowStockProductsUseCase>(),
          getProductsByCategoryUseCase:
              Get.find<GetProductsByCategoryUseCase>(),
          deleteProductUseCase: Get.find<DeleteProductUseCase>(),
        ),
        fenix: true,
      );
      print('  ✅ ProductsController registrado');
    }

    // ProductDetailController
    if (!Get.isRegistered<ProductDetailController>()) {
      Get.lazyPut<ProductDetailController>(
        () => ProductDetailController(
          getProductByIdUseCase: Get.find<GetProductByIdUseCase>(),
          updateProductStockUseCase: Get.find<UpdateProductStockUseCase>(),
          deleteProductUseCase: Get.find<DeleteProductUseCase>(),
        ),
        fenix: true,
      );
      print('  ✅ ProductDetailController registrado');
    }

    // ProductFormController (con dependencias de categorías)
    if (!Get.isRegistered<ProductFormController>()) {
      Get.lazyPut<ProductFormController>(
        () => ProductFormController(
          createProductUseCase: Get.find<CreateProductUseCase>(),
          updateProductUseCase: Get.find<UpdateProductUseCase>(),
          getProductByIdUseCase: Get.find<GetProductByIdUseCase>(),
          getCategoriesUseCase: _getCategoriesUseCaseSafely(),
        ),
        fenix: true,
      );
      print('  ✅ ProductFormController registrado');
    }
  }

  /// Obtener GetCategoriesUseCase de forma segura
  GetCategoriesUseCase _getCategoriesUseCaseSafely() {
    try {
      if (Get.isRegistered<GetCategoriesUseCase>()) {
        return Get.find<GetCategoriesUseCase>();
      } else {
        // Crear una implementación mock si no está disponible
        print(
          '⚠️ GetCategoriesUseCase no disponible, usando implementación mock',
        );
        return _createMockGetCategoriesUseCase();
      }
    } catch (e) {
      print('⚠️ Error al obtener GetCategoriesUseCase: $e');
      return _createMockGetCategoriesUseCase();
    }
  }

  /// Crear implementación mock de GetCategoriesUseCase
  GetCategoriesUseCase _createMockGetCategoriesUseCase() {
    // Nota: Esto requiere que tengas una implementación mock o que manejes el caso
    // cuando CategoryBinding no está disponible
    throw UnimplementedError(
      'GetCategoriesUseCase no está disponible. '
      'Asegúrate de ejecutar CategoryBinding antes de ProductBinding.',
    );
  }

  @override
  void onDispose() {
    print('🧹 ProductBinding: Iniciando limpieza de dependencias...');

    try {
      // Controllers
      _cleanupControllers();

      // Use Cases
      _cleanupUseCases();

      // Data Layer (opcional, ya que son fenix)
      _cleanupDataLayer();

      print('✅ ProductBinding: Limpieza completada exitosamente');
    } catch (e) {
      print('⚠️ ProductBinding: Error durante limpieza: $e');
    }
  }

  void _cleanupControllers() {
    try {
      if (Get.isRegistered<ProductsController>()) {
        Get.delete<ProductsController>(force: true);
        print('  🗑️ ProductsController eliminado');
      }
    } catch (e) {
      print('  ⚠️ Error eliminando ProductsController: $e');
    }

    try {
      if (Get.isRegistered<ProductDetailController>()) {
        Get.delete<ProductDetailController>(force: true);
        print('  🗑️ ProductDetailController eliminado');
      }
    } catch (e) {
      print('  ⚠️ Error eliminando ProductDetailController: $e');
    }

    try {
      if (Get.isRegistered<ProductFormController>()) {
        Get.delete<ProductFormController>(force: true);
        print('  🗑️ ProductFormController eliminado');
      }
    } catch (e) {
      print('  ⚠️ Error eliminando ProductFormController: $e');
    }
  }

  void _cleanupUseCases() {
    final useCases = [
      () => Get.delete<GetProductsUseCase>(force: true),
      () => Get.delete<GetProductByIdUseCase>(force: true),
      () => Get.delete<SearchProductsUseCase>(force: true),
      () => Get.delete<GetProductStatsUseCase>(force: true),
      () => Get.delete<GetLowStockProductsUseCase>(force: true),
      () => Get.delete<GetProductsByCategoryUseCase>(force: true),
      () => Get.delete<CreateProductUseCase>(force: true),
      () => Get.delete<UpdateProductUseCase>(force: true),
      () => Get.delete<UpdateProductStockUseCase>(force: true),
      () => Get.delete<DeleteProductUseCase>(force: true),
    ];

    final names = [
      'GetProductsUseCase',
      'GetProductByIdUseCase',
      'SearchProductsUseCase',
      'GetProductStatsUseCase',
      'GetLowStockProductsUseCase',
      'GetProductsByCategoryUseCase',
      'CreateProductUseCase',
      'UpdateProductUseCase',
      'UpdateProductStockUseCase',
      'DeleteProductUseCase',
    ];

    for (int i = 0; i < useCases.length; i++) {
      try {
        useCases[i]();
        print('  🗑️ ${names[i]} eliminado');
      } catch (e) {
        print('  ⚠️ Error eliminando ${names[i]}: $e');
      }
    }
  }

  void _cleanupDataLayer() {
    try {
      if (Get.isRegistered<ProductRepository>()) {
        Get.delete<ProductRepository>(force: true);
        print('  🗑️ ProductRepository eliminado');
      }
    } catch (e) {
      print('  ⚠️ Error eliminando ProductRepository: $e');
    }

    try {
      if (Get.isRegistered<ProductRemoteDataSource>()) {
        Get.delete<ProductRemoteDataSource>(force: true);
        print('  🗑️ ProductRemoteDataSource eliminado');
      }
    } catch (e) {
      print('  ⚠️ Error eliminando ProductRemoteDataSource: $e');
    }

    try {
      if (Get.isRegistered<ProductLocalDataSource>()) {
        Get.delete<ProductLocalDataSource>(force: true);
        print('  🗑️ ProductLocalDataSource eliminado');
      }
    } catch (e) {
      print('  ⚠️ Error eliminando ProductLocalDataSource: $e');
    }
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Verificar si todas las dependencias están registradas
  static bool get isFullyInitialized {
    return Get.isRegistered<ProductRepository>() &&
        Get.isRegistered<ProductsController>() &&
        Get.isRegistered<ProductDetailController>() &&
        Get.isRegistered<ProductFormController>() &&
        Get.isRegistered<GetProductsUseCase>() &&
        Get.isRegistered<CreateProductUseCase>();
  }

  /// Verificar dependencias específicas
  static void verifyDependencies() {
    print('🔍 Verificando dependencias del módulo Products...');

    final dependencies = {
      // Core Dependencies
      'DioClient': Get.isRegistered<DioClient>(),
      'SecureStorageService': Get.isRegistered<SecureStorageService>(),
      'NetworkInfo': Get.isRegistered<NetworkInfo>(),
      'Connectivity': Get.isRegistered<Connectivity>(),

      // Product Dependencies
      'ProductRepository': Get.isRegistered<ProductRepository>(),
      'ProductsController': Get.isRegistered<ProductsController>(),
      'ProductFormController': Get.isRegistered<ProductFormController>(),
      'ProductDetailController': Get.isRegistered<ProductDetailController>(),

      // Product Use Cases
      'GetProductsUseCase': Get.isRegistered<GetProductsUseCase>(),
      'CreateProductUseCase': Get.isRegistered<CreateProductUseCase>(),

      // Category Dependencies (optional)
      'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
      'SearchCategoriesUseCase': Get.isRegistered<SearchCategoriesUseCase>(),
    };

    dependencies.forEach((name, isRegistered) {
      final status = isRegistered ? '✅' : '❌';
      print('   $status $name');
    });

    final allCoreRegistered = [
      'DioClient',
      'ProductRepository',
      'ProductsController',
      'ProductFormController',
    ].every((key) => dependencies[key] == true);

    final statusMsg =
        allCoreRegistered
            ? '✅ DEPENDENCIAS CORE REGISTRADAS'
            : '❌ FALTAN DEPENDENCIAS CORE';

    print('📋 Estado: $statusMsg');
    print('🔍 Verificación completada');
  }

  /// Obtener información de estado para debugging
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isFullyInitialized': isFullyInitialized,
      'hasCategoryDependencies': Get.isRegistered<GetCategoriesUseCase>(),
      'registeredControllers': {
        'ProductsController': Get.isRegistered<ProductsController>(),
        'ProductFormController': Get.isRegistered<ProductFormController>(),
        'ProductDetailController': Get.isRegistered<ProductDetailController>(),
      },
      'registeredUseCases': {
        'GetProductsUseCase': Get.isRegistered<GetProductsUseCase>(),
        'CreateProductUseCase': Get.isRegistered<CreateProductUseCase>(),
        'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
      },
    };
  }

  /// Imprimir información de debugging
  static void printDebugInfo() {
    final info = getDebugInfo();
    print('🐛 ProductBinding Debug Info:');
    print('   ${info.toString()}');
  }
}
