// lib/features/products/presentation/bindings/product_binding.dart
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/core/storage/secure_storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

// Product Data Layer
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/datasources/product_local_datasource_isar.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../app/data/local/isar_database.dart';

// Product Use Cases
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';
import '../../domain/usecases/get_product_stats_usecase.dart';
import '../../domain/usecases/update_product_stock_usecase.dart';
import '../../domain/usecases/get_low_stock_products_usecase.dart' as products_usecases;
import '../../domain/usecases/get_products_by_category_usecase.dart';

// Category Use Cases (para ProductFormController)
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../../../categories/domain/usecases/search_categories_usecase.dart';
import '../../../categories/domain/usecases/create_category_usecase.dart';

// Product Controllers
import '../controllers/products_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/product_form_controller.dart';

class ProductBinding implements Bindings {
  @override
  void dependencies() {

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

    } catch (e, stackTrace) {
      rethrow;
    }
  }

  /// Verificar dependencias core del sistema
  void _verifyCoreDependencies() {

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

      throw Exception(
        'ProductBinding requiere InitialBinding. Dependencias faltantes: ${missingDependencies.join(', ')}',
      );
    }

  }

  /// Verificar dependencias de categorías (requeridas para ProductFormController)
  void _verifyCategoryDependencies() {

    final categoryDependencies = <String, bool>{
      'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
      'SearchCategoriesUseCase': Get.isRegistered<SearchCategoriesUseCase>(),
      'CreateCategoryUseCase': Get.isRegistered<CreateCategoryUseCase>(),
    };

    final missingCategoryDeps =
        categoryDependencies.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();

    if (missingCategoryDeps.isNotEmpty) {
    } else {
    }
  }

  /// Registrar capa de datos
  void _registerDataLayer() {

    // Remote DataSource
    if (!Get.isRegistered<ProductRemoteDataSource>()) {
      Get.lazyPut<ProductRemoteDataSource>(
        () => ProductRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
    }

    // Local DataSource - ISAR Implementation (offline-first)
    if (!Get.isRegistered<ProductLocalDataSource>()) {
      Get.lazyPut<ProductLocalDataSource>(
        () => ProductLocalDataSourceIsar(Get.find<IsarDatabase>()),
        fenix: true,
      );
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
    }
  }

  /// Registrar casos de uso
  void _registerUseCases() {

    final repository = Get.find<ProductRepository>();

    // Read Operations
    Get.lazyPut(() => GetProductsUseCase(repository), fenix: true);
    Get.lazyPut(() => GetProductByIdUseCase(repository), fenix: true);
    Get.lazyPut(() => SearchProductsUseCase(repository), fenix: true);
    Get.lazyPut(() => GetProductStatsUseCase(repository), fenix: true);
    Get.lazyPut(() => products_usecases.GetLowStockProductsUseCase(repository), fenix: true, tag: 'products');
    Get.lazyPut(() => GetProductsByCategoryUseCase(repository), fenix: true);

    // Write Operations
    Get.lazyPut(() => CreateProductUseCase(repository), fenix: true);
    Get.lazyPut(() => UpdateProductUseCase(repository), fenix: true);
    Get.lazyPut(() => UpdateProductStockUseCase(repository), fenix: true);
    Get.lazyPut(() => DeleteProductUseCase(repository), fenix: true);

  }

  /// Registrar controladores
  void _registerControllers() {

    // ProductsController - PERMANENTE para evitar disposal al navegar
    if (!Get.isRegistered<ProductsController>()) {
      Get.put<ProductsController>(
        ProductsController(
          getProductsUseCase: Get.find<GetProductsUseCase>(),
          searchProductsUseCase: Get.find<SearchProductsUseCase>(),
          getProductStatsUseCase: Get.find<GetProductStatsUseCase>(),
          getLowStockProductsUseCase: Get.find<products_usecases.GetLowStockProductsUseCase>(tag: 'products'),
          getProductsByCategoryUseCase:
              Get.find<GetProductsByCategoryUseCase>(),
          deleteProductUseCase: Get.find<DeleteProductUseCase>(),
        ),
        permanent: true, // ✅ PERMANENTE para evitar disposal al navegar
      );
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
    }

    // ProductFormController (con dependencias de categorías)
    if (!Get.isRegistered<ProductFormController>()) {
      Get.lazyPut<ProductFormController>(
        () => ProductFormController(
          createProductUseCase: Get.find<CreateProductUseCase>(),
          updateProductUseCase: Get.find<UpdateProductUseCase>(),
          getProductByIdUseCase: Get.find<GetProductByIdUseCase>(),
          getCategoriesUseCase: _getCategoriesUseCaseSafely(),
          createCategoryUseCase: _getCreateCategoryUseCaseSafely(),
          secureStorageService: Get.find<SecureStorageService>(),
          productRepository: Get.find<ProductRepository>(),
        ),
        fenix: true, // ✅ USAR fenix: true para evitar disposal prematuro
      );
    }
  }

  /// Obtener GetCategoriesUseCase de forma segura
  GetCategoriesUseCase _getCategoriesUseCaseSafely() {
    try {
      if (Get.isRegistered<GetCategoriesUseCase>()) {
        return Get.find<GetCategoriesUseCase>();
      } else {
        // Crear una implementación mock si no está disponible
        return _createMockGetCategoriesUseCase();
      }
    } catch (e) {
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

  /// Obtener CreateCategoryUseCase de forma segura
  CreateCategoryUseCase _getCreateCategoryUseCaseSafely() {
    try {
      if (Get.isRegistered<CreateCategoryUseCase>()) {
        return Get.find<CreateCategoryUseCase>();
      } else {
        // Crear una implementación mock si no está disponible
        return _createMockCreateCategoryUseCase();
      }
    } catch (e) {
      return _createMockCreateCategoryUseCase();
    }
  }

  /// Crear implementación mock de CreateCategoryUseCase
  CreateCategoryUseCase _createMockCreateCategoryUseCase() {
    throw UnimplementedError(
      'CreateCategoryUseCase no está disponible. '
      'Asegúrate de ejecutar CategoryBinding antes de ProductBinding.',
    );
  }

  @override
  void onDispose() {

    try {
      // Controllers
      _cleanupControllers();

      // Use Cases
      _cleanupUseCases();

      // Data Layer (opcional, ya que son fenix)
      _cleanupDataLayer();

    } catch (e) {
    }
  }

  void _cleanupControllers() {
    try {
      if (Get.isRegistered<ProductsController>()) {
        Get.delete<ProductsController>(force: true);
      }
    } catch (e) {
    }

    try {
      if (Get.isRegistered<ProductDetailController>()) {
        Get.delete<ProductDetailController>(force: true);
      }
    } catch (e) {
    }

    try {
      if (Get.isRegistered<ProductFormController>()) {
        Get.delete<ProductFormController>(force: true);
      }
    } catch (e) {
    }
  }

  void _cleanupUseCases() {
    final useCases = [
      () => Get.delete<GetProductsUseCase>(force: true),
      () => Get.delete<GetProductByIdUseCase>(force: true),
      () => Get.delete<SearchProductsUseCase>(force: true),
      () => Get.delete<GetProductStatsUseCase>(force: true),
      () => Get.delete<products_usecases.GetLowStockProductsUseCase>(force: true, tag: 'products'),
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
      } catch (e) {
      }
    }
  }

  void _cleanupDataLayer() {
    try {
      if (Get.isRegistered<ProductRepository>()) {
        Get.delete<ProductRepository>(force: true);
      }
    } catch (e) {
    }

    try {
      if (Get.isRegistered<ProductRemoteDataSource>()) {
        Get.delete<ProductRemoteDataSource>(force: true);
      }
    } catch (e) {
    }

    try {
      if (Get.isRegistered<ProductLocalDataSource>()) {
        Get.delete<ProductLocalDataSource>(force: true);
      }
    } catch (e) {
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
      'CreateCategoryUseCase': Get.isRegistered<CreateCategoryUseCase>(),
    };

    dependencies.forEach((name, isRegistered) {
      final status = isRegistered ? '✅' : '❌';
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
        'CreateCategoryUseCase': Get.isRegistered<CreateCategoryUseCase>(),
      },
    };
  }

  /// Imprimir información de debugging
  static void printDebugInfo() {
    final info = getDebugInfo();
  }
}
