// // lib/features/categories/presentation/bindings/category_binding.dart
// import 'package:get/get.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';

// import '../../../../app/core/network/dio_client.dart';
// import '../../../../app/core/network/network_info.dart';
// import '../../../../app/core/storage/secure_storage_service.dart';
// import '../../data/datasources/category_local_datasource.dart';
// import '../../data/datasources/category_remote_datasource.dart';
// import '../../data/repositories/category_repository_impl.dart';
// import '../../domain/repositories/category_repository.dart';
// import '../../domain/usecases/get_categories_usecase.dart';
// import '../../domain/usecases/get_category_by_id_usecase.dart';
// import '../../domain/usecases/get_category_tree_usecase.dart';
// import '../../domain/usecases/create_category_usecase.dart';
// import '../../domain/usecases/update_category_usecase.dart';
// import '../../domain/usecases/delete_category_usecase.dart';
// import '../../domain/usecases/search_categories_usecase.dart';
// import '../../domain/usecases/get_category_stats_usecase.dart';
// import '../controllers/categories_controller.dart';
// import '../controllers/category_form_controller.dart';
// import '../controllers/category_detail_controller.dart';
// import '../controllers/category_tree_controller.dart';

// /// Binding principal para todas las funcionalidades de categorías
// ///
// /// Este binding se encarga de:
// /// - Verificar que InitialBinding se haya ejecutado primero
// /// - Registrar todas las dependencias específicas de categorías
// /// - Proporcionar controllers listos para usar
// /// - Manejar la limpieza adecuada de recursos
// class CategoryBinding extends Bindings {
//   @override
//   void dependencies() {
//     print('🏷️ CategoryBinding: Iniciando registro de dependencias...');

//     try {
//       // ==================== STEP 1: VERIFICAR DEPENDENCIAS CORE ====================
//       _verifyCoreDependencies();

//       // ==================== STEP 2: REGISTRAR DATA LAYER ====================
//       _registerDataLayer();

//       // ==================== STEP 3: REGISTRAR DOMAIN LAYER ====================
//       _registerDomainLayer();

//       // ==================== STEP 4: REGISTRAR PRESENTATION LAYER ====================
//       _registerPresentationLayer();

//       print(
//         '✅ CategoryBinding: Todas las dependencias registradas exitosamente',
//       );

//       // Debug opcional
//       if (kDebugMode) {
//         CategoryBindingHelper.printRegistrationSummary();
//       }
//     } catch (e, stackTrace) {
//       print('💥 CategoryBinding: Error durante el registro de dependencias');
//       print('   Error: $e');
//       print('   StackTrace: $stackTrace');
//       rethrow;
//     }
//   }

//   /// Verificar que las dependencias core de InitialBinding estén disponibles
//   void _verifyCoreDependencies() {
//     print('🔍 Verificando dependencias core...');

//     final requiredDependencies = <String, bool>{
//       'DioClient': Get.isRegistered<DioClient>(),
//       'SecureStorageService': Get.isRegistered<SecureStorageService>(),
//       'NetworkInfo': Get.isRegistered<NetworkInfo>(),
//       'Connectivity': Get.isRegistered<Connectivity>(),
//     };

//     final missingDependencies =
//         requiredDependencies.entries
//             .where((entry) => !entry.value)
//             .map((entry) => entry.key)
//             .toList();

//     if (missingDependencies.isNotEmpty) {
//       final errorMsg = '''
// ❌ CategoryBinding Error: Dependencias core faltantes

// Dependencias faltantes: ${missingDependencies.join(', ')}

// SOLUCIÓN:
// 1. Asegúrate de que InitialBinding().dependencies() se ejecute ANTES que CategoryBinding
// 2. Verifica que las dependencias core estén correctamente registradas en InitialBinding
// 3. El orden correcto es: InitialBinding → CategoryBinding

// En main.dart debería ser:
//   InitialBinding().dependencies();  // PRIMERO
//   runApp(MyApp());                  // DESPUÉS
// ''';

//       print(errorMsg);
//       throw Exception(
//         'CategoryBinding requiere InitialBinding. Dependencias faltantes: ${missingDependencies.join(', ')}',
//       );
//     }

//     print('✅ Dependencias core verificadas correctamente');
//   }

//   /// Registrar capa de datos (DataSources y Repository)
//   void _registerDataLayer() {
//     print('💾 Registrando capa de datos...');

//     // Remote DataSource
//     if (!Get.isRegistered<CategoryRemoteDataSource>()) {
//       Get.lazyPut<CategoryRemoteDataSource>(
//         () => CategoryRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
//         fenix: true,
//       );
//       print('  ✅ CategoryRemoteDataSource registrado');
//     } else {
//       print('  ℹ️ CategoryRemoteDataSource ya existe');
//     }

//     // Local DataSource
//     if (!Get.isRegistered<CategoryLocalDataSource>()) {
//       Get.lazyPut<CategoryLocalDataSource>(
//         () => CategoryLocalDataSourceImpl(
//           storageService: Get.find<SecureStorageService>(),
//         ),
//         fenix: true,
//       );
//       print('  ✅ CategoryLocalDataSource registrado');
//     } else {
//       print('  ℹ️ CategoryLocalDataSource ya existe');
//     }

//     // Repository
//     if (!Get.isRegistered<CategoryRepository>()) {
//       Get.lazyPut<CategoryRepository>(
//         () => CategoryRepositoryImpl(
//           remoteDataSource: Get.find<CategoryRemoteDataSource>(),
//           localDataSource: Get.find<CategoryLocalDataSource>(),
//           networkInfo: Get.find<NetworkInfo>(),
//         ),
//         fenix: true,
//       );
//       print('  ✅ CategoryRepository registrado');
//     } else {
//       print('  ℹ️ CategoryRepository ya existe');
//     }
//   }

//   /// Registrar capa de dominio (Use Cases) - VERSIÓN OPTIMIZADA
//   void _registerDomainLayer() {
//     print('🎯 Registrando casos de uso...');

//     final repository = Get.find<CategoryRepository>();

//     // Registrar cada use case individualmente para asegurar disponibilidad
//     // GetCategoriesUseCase
//     if (!Get.isRegistered<GetCategoriesUseCase>()) {
//       Get.lazyPut<GetCategoriesUseCase>(
//         () => GetCategoriesUseCase(repository),
//         fenix: true,
//       );
//       print('    • GetCategoriesUseCase ✅');
//     } else {
//       print('    • GetCategoriesUseCase ℹ️ (ya existe)');
//     }

//     // GetCategoryByIdUseCase
//     if (!Get.isRegistered<GetCategoryByIdUseCase>()) {
//       Get.lazyPut<GetCategoryByIdUseCase>(
//         () => GetCategoryByIdUseCase(repository),
//         fenix: true,
//       );
//       print('    • GetCategoryByIdUseCase ✅');
//     } else {
//       print('    • GetCategoryByIdUseCase ℹ️ (ya existe)');
//     }

//     // GetCategoryTreeUseCase
//     if (!Get.isRegistered<GetCategoryTreeUseCase>()) {
//       Get.lazyPut<GetCategoryTreeUseCase>(
//         () => GetCategoryTreeUseCase(repository),
//         fenix: true,
//       );
//       print('    • GetCategoryTreeUseCase ✅');
//     } else {
//       print('    • GetCategoryTreeUseCase ℹ️ (ya existe)');
//     }

//     // CreateCategoryUseCase
//     if (!Get.isRegistered<CreateCategoryUseCase>()) {
//       Get.lazyPut<CreateCategoryUseCase>(
//         () => CreateCategoryUseCase(repository),
//         fenix: true,
//       );
//       print('    • CreateCategoryUseCase ✅');
//     } else {
//       print('    • CreateCategoryUseCase ℹ️ (ya existe)');
//     }

//     // UpdateCategoryUseCase
//     if (!Get.isRegistered<UpdateCategoryUseCase>()) {
//       Get.lazyPut<UpdateCategoryUseCase>(
//         () => UpdateCategoryUseCase(repository),
//         fenix: true,
//       );
//       print('    • UpdateCategoryUseCase ✅');
//     } else {
//       print('    • UpdateCategoryUseCase ℹ️ (ya existe)');
//     }

//     // DeleteCategoryUseCase
//     if (!Get.isRegistered<DeleteCategoryUseCase>()) {
//       Get.lazyPut<DeleteCategoryUseCase>(
//         () => DeleteCategoryUseCase(repository),
//         fenix: true,
//       );
//       print('    • DeleteCategoryUseCase ✅');
//     } else {
//       print('    • DeleteCategoryUseCase ℹ️ (ya existe)');
//     }

//     // SearchCategoriesUseCase
//     if (!Get.isRegistered<SearchCategoriesUseCase>()) {
//       Get.lazyPut<SearchCategoriesUseCase>(
//         () => SearchCategoriesUseCase(repository),
//         fenix: true,
//       );
//       print('    • SearchCategoriesUseCase ✅');
//     } else {
//       print('    • SearchCategoriesUseCase ℹ️ (ya existe)');
//     }

//     // GetCategoryStatsUseCase
//     if (!Get.isRegistered<GetCategoryStatsUseCase>()) {
//       Get.lazyPut<GetCategoryStatsUseCase>(
//         () => GetCategoryStatsUseCase(repository),
//         fenix: true,
//       );
//       print('    • GetCategoryStatsUseCase ✅');
//     } else {
//       print('    • GetCategoryStatsUseCase ℹ️ (ya existe)');
//     }

//     print('  ✅ Todos los casos de uso registrados');
//   }

//   /// Registrar capa de presentación (Controllers) - VERSIÓN OPTIMIZADA
//   void _registerPresentationLayer() {
//     print('🎮 Registrando controllers...');

//     // CategoriesController
//     if (!Get.isRegistered<CategoriesController>()) {
//       Get.lazyPut<CategoriesController>(
//         () => CategoriesController(
//           getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
//           deleteCategoryUseCase: Get.find<DeleteCategoryUseCase>(),
//           searchCategoriesUseCase: Get.find<SearchCategoriesUseCase>(),
//           getCategoryStatsUseCase: Get.find<GetCategoryStatsUseCase>(),
//         ),
//         fenix: true,
//       );
//       print('  ✅ CategoriesController registrado');
//     }

//     // CategoryFormController
//     if (!Get.isRegistered<CategoryFormController>()) {
//       Get.lazyPut<CategoryFormController>(
//         () => CategoryFormController(
//           createCategoryUseCase: Get.find<CreateCategoryUseCase>(),
//           updateCategoryUseCase: Get.find<UpdateCategoryUseCase>(),
//           getCategoryTreeUseCase: Get.find<GetCategoryTreeUseCase>(),
//           getCategoryByIdUseCase: Get.find<GetCategoryByIdUseCase>(),
//         ),
//         fenix: true,
//       );
//       print('  ✅ CategoryFormController registrado');
//     }

//     // CategoryDetailController
//     if (!Get.isRegistered<CategoryDetailController>()) {
//       Get.lazyPut<CategoryDetailController>(
//         () => CategoryDetailController(
//           getCategoryByIdUseCase: Get.find<GetCategoryByIdUseCase>(),
//           getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
//           deleteCategoryUseCase: Get.find<DeleteCategoryUseCase>(),
//           updateCategoryUseCase: Get.find<UpdateCategoryUseCase>(),
//         ),
//         fenix: true,
//       );
//       print('  ✅ CategoryDetailController registrado');
//     }

//     // CategoryTreeController
//     if (!Get.isRegistered<CategoryTreeController>()) {
//       Get.lazyPut<CategoryTreeController>(
//         () => CategoryTreeController(
//           getCategoryTreeUseCase: Get.find<GetCategoryTreeUseCase>(),
//         ),
//         fenix: true,
//       );
//       print('  ✅ CategoryTreeController registrado');
//     }
//   }

//   @override
//   void onDispose() {
//     print('🧹 CategoryBinding: Iniciando limpieza de dependencias...');

//     try {
//       // Limpiar controllers (estos no son permanentes)
//       _cleanupControllers();

//       // Limpiar use cases (estos no son permanentes)
//       _cleanupUseCases();

//       // Las dependencias de datos (DataSources, Repository) son fenix,
//       // se auto-gestionan, pero podemos forzar su limpieza si es necesario
//       _cleanupDataLayer();

//       print('✅ CategoryBinding: Limpieza completada exitosamente');
//     } catch (e) {
//       print('⚠️ CategoryBinding: Error durante limpieza: $e');
//     }
//   }

//   void _cleanupControllers() {
//     final controllers = [
//       CategoriesController,
//       CategoryFormController,
//       CategoryDetailController,
//       CategoryTreeController,
//     ];

//     for (final controller in controllers) {
//       try {
//         if (Get.isRegistered(tag: controller.toString())) {
//           Get.delete(tag: controller.toString(), force: true);
//           print('  🗑️ ${controller.toString()} eliminado');
//         }
//       } catch (e) {
//         print('  ⚠️ Error eliminando ${controller.toString()}: $e');
//       }
//     }
//   }

//   void _cleanupUseCases() {
//     final useCases = [
//       GetCategoriesUseCase,
//       GetCategoryByIdUseCase,
//       GetCategoryTreeUseCase,
//       CreateCategoryUseCase,
//       UpdateCategoryUseCase,
//       DeleteCategoryUseCase,
//       SearchCategoriesUseCase,
//       GetCategoryStatsUseCase,
//     ];

//     for (final useCase in useCases) {
//       try {
//         if (Get.isRegistered(tag: useCase.toString())) {
//           Get.delete(tag: useCase.toString(), force: true);
//           print('  🗑️ ${useCase.toString()} eliminado');
//         }
//       } catch (e) {
//         print('  ⚠️ Error eliminando ${useCase.toString()}: $e');
//       }
//     }
//   }

//   void _cleanupDataLayer() {
//     // Solo limpiar si realmente queremos forzar la recreación
//     // Normalmente las dependencias fenix se auto-gestionan
//     final dataTypes = [
//       CategoryRepository,
//       CategoryRemoteDataSource,
//       CategoryLocalDataSource,
//     ];

//     for (final dataType in dataTypes) {
//       try {
//         if (Get.isRegistered(tag: dataType.toString())) {
//           Get.delete(tag: dataType.toString(), force: true);
//           print('  🗑️ ${dataType.toString()} eliminado');
//         }
//       } catch (e) {
//         print('  ⚠️ Error eliminando ${dataType.toString()}: $e');
//       }
//     }
//   }
// }

// /// Helper class para debugging y acceso seguro a dependencias
// class CategoryBindingHelper {
//   /// Verificar si todas las dependencias están registradas
//   static bool get isFullyInitialized {
//     final requiredTypes = [
//       CategoryRepository,
//       CategoriesController,
//       CategoryFormController,
//       CategoryDetailController,
//       CategoryTreeController,
//     ];

//     return requiredTypes.every(
//       (type) => Get.isRegistered(tag: type.toString()),
//     );
//   }

//   /// Imprimir resumen del registro de dependencias
//   static void printRegistrationSummary() {
//     print('📋 ===============================================');
//     print('📋 RESUMEN DE REGISTRO - CATEGORY BINDING');
//     print('📋 ===============================================');

//     final dependencies = {
//       '🏗️ Core': {
//         'DioClient': Get.isRegistered<DioClient>(),
//         'SecureStorageService': Get.isRegistered<SecureStorageService>(),
//         'NetworkInfo': Get.isRegistered<NetworkInfo>(),
//         'Connectivity': Get.isRegistered<Connectivity>(),
//       },
//       '💾 Data Layer': {
//         'CategoryRepository': Get.isRegistered<CategoryRepository>(),
//         'CategoryRemoteDataSource':
//             Get.isRegistered<CategoryRemoteDataSource>(),
//         'CategoryLocalDataSource': Get.isRegistered<CategoryLocalDataSource>(),
//       },
//       '🎯 Use Cases': {
//         'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
//         'GetCategoryByIdUseCase': Get.isRegistered<GetCategoryByIdUseCase>(),
//         'GetCategoryTreeUseCase': Get.isRegistered<GetCategoryTreeUseCase>(),
//         'CreateCategoryUseCase': Get.isRegistered<CreateCategoryUseCase>(),
//         'UpdateCategoryUseCase': Get.isRegistered<UpdateCategoryUseCase>(),
//         'DeleteCategoryUseCase': Get.isRegistered<DeleteCategoryUseCase>(),
//         'SearchCategoriesUseCase': Get.isRegistered<SearchCategoriesUseCase>(),
//         'GetCategoryStatsUseCase': Get.isRegistered<GetCategoryStatsUseCase>(),
//       },
//       '🎮 Controllers': {
//         'CategoriesController': Get.isRegistered<CategoriesController>(),
//         'CategoryFormController': Get.isRegistered<CategoryFormController>(),
//         'CategoryDetailController':
//             Get.isRegistered<CategoryDetailController>(),
//         'CategoryTreeController': Get.isRegistered<CategoryTreeController>(),
//       },
//     };

//     dependencies.forEach((category, deps) {
//       print('$category:');
//       deps.forEach((name, isRegistered) {
//         final status = isRegistered ? '✅' : '❌';
//         print('   $status $name');
//       });
//       print('');
//     });

//     final status =
//         isFullyInitialized
//             ? '✅ COMPLETAMENTE INICIALIZADO'
//             : '❌ INICIALIZACIÓN INCOMPLETA';
//     print('📋 Estado: $status');
//     print('📋 ===============================================');
//   }

//   /// Obtener controller de forma segura
//   static T? safeGet<T>() {
//     try {
//       return Get.isRegistered<T>() ? Get.find<T>() : null;
//     } catch (e) {
//       print('❌ Error obteniendo ${T.toString()}: $e');
//       return null;
//     }
//   }

//   /// Verificar si una dependencia específica está registrada
//   static bool isDependencyRegistered<T>() {
//     return Get.isRegistered<T>();
//   }

//   /// Obtener estado completo para debugging
//   static Map<String, bool> getRegistrationStatus() {
//     return {
//       'CategoryRepository': Get.isRegistered<CategoryRepository>(),
//       'CategoriesController': Get.isRegistered<CategoriesController>(),
//       'CategoryFormController': Get.isRegistered<CategoryFormController>(),
//       'CategoryDetailController': Get.isRegistered<CategoryDetailController>(),
//       'CategoryTreeController': Get.isRegistered<CategoryTreeController>(),
//       'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
//       'CreateCategoryUseCase': Get.isRegistered<CreateCategoryUseCase>(),
//     };
//   }
// }

// lib/features/categories/presentation/bindings/category_binding.dart
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_category_by_id_usecase.dart';
import '../../domain/usecases/get_category_tree_usecase.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/search_categories_usecase.dart';
import '../../domain/usecases/get_category_stats_usecase.dart';
import '../controllers/categories_controller.dart';
import '../controllers/category_form_controller.dart';
import '../controllers/category_detail_controller.dart';
import '../controllers/category_tree_controller.dart';

/// Binding principal para todas las funcionalidades de categorías
///
/// Este binding se encarga de:
/// - Verificar que InitialBinding se haya ejecutado primero
/// - Registrar todas las dependencias específicas de categorías
/// - Proporcionar controllers listos para usar
/// - Manejar la limpieza adecuada de recursos
class CategoryBinding extends Bindings {
  @override
  void dependencies() {
    print('🏷️ CategoryBinding: Iniciando registro de dependencias...');

    try {
      // ==================== STEP 1: VERIFICAR DEPENDENCIAS CORE ====================
      _verifyCoreDependencies();

      // ==================== STEP 2: REGISTRAR DATA LAYER ====================
      _registerDataLayer();

      // ==================== STEP 3: REGISTRAR DOMAIN LAYER ====================
      _registerDomainLayer();

      // ==================== STEP 4: REGISTRAR PRESENTATION LAYER ====================
      _registerPresentationLayer();

      print(
        '✅ CategoryBinding: Todas las dependencias registradas exitosamente',
      );

      // Debug opcional
      if (kDebugMode) {
        CategoryBindingHelper.printRegistrationSummary();
      }
    } catch (e, stackTrace) {
      print('💥 CategoryBinding: Error durante el registro de dependencias');
      print('   Error: $e');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Verificar que las dependencias core de InitialBinding estén disponibles
  void _verifyCoreDependencies() {
    print('🔍 Verificando dependencias core...');

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
❌ CategoryBinding Error: Dependencias core faltantes

Dependencias faltantes: ${missingDependencies.join(', ')}

SOLUCIÓN:
1. Asegúrate de que InitialBinding().dependencies() se ejecute ANTES que CategoryBinding
2. Verifica que las dependencias core estén correctamente registradas en InitialBinding
3. El orden correcto es: InitialBinding → CategoryBinding

En main.dart debería ser:
  InitialBinding().dependencies();  // PRIMERO
  runApp(MyApp());                  // DESPUÉS
''';

      print(errorMsg);
      throw Exception(
        'CategoryBinding requiere InitialBinding. Dependencias faltantes: ${missingDependencies.join(', ')}',
      );
    }

    print('✅ Dependencias core verificadas correctamente');
  }

  /// Registrar capa de datos (DataSources y Repository)
  void _registerDataLayer() {
    print('💾 Registrando capa de datos...');

    // Remote DataSource
    if (!Get.isRegistered<CategoryRemoteDataSource>()) {
      Get.lazyPut<CategoryRemoteDataSource>(
        () => CategoryRemoteDataSourceImpl(dioClient: Get.find<DioClient>()),
        fenix: true,
      );
      print('  ✅ CategoryRemoteDataSource registrado');
    } else {
      print('  ℹ️ CategoryRemoteDataSource ya existe');
    }

    // Local DataSource
    if (!Get.isRegistered<CategoryLocalDataSource>()) {
      Get.lazyPut<CategoryLocalDataSource>(
        () => CategoryLocalDataSourceImpl(
          storageService: Get.find<SecureStorageService>(),
        ),
        fenix: true,
      );
      print('  ✅ CategoryLocalDataSource registrado');
    } else {
      print('  ℹ️ CategoryLocalDataSource ya existe');
    }

    // Repository
    if (!Get.isRegistered<CategoryRepository>()) {
      Get.lazyPut<CategoryRepository>(
        () => CategoryRepositoryImpl(
          remoteDataSource: Get.find<CategoryRemoteDataSource>(),
          localDataSource: Get.find<CategoryLocalDataSource>(),
          networkInfo: Get.find<NetworkInfo>(),
        ),
        fenix: true,
      );
      print('  ✅ CategoryRepository registrado');
    } else {
      print('  ℹ️ CategoryRepository ya existe');
    }
  }

  /// Registrar capa de dominio (Use Cases) - VERSIÓN CORREGIDA
  void _registerDomainLayer() {
    print('🎯 Registrando casos de uso...');

    final repository = Get.find<CategoryRepository>();

    // Registrar cada use case individualmente para asegurar disponibilidad
    // GetCategoriesUseCase
    if (!Get.isRegistered<GetCategoriesUseCase>()) {
      Get.lazyPut<GetCategoriesUseCase>(
        () => GetCategoriesUseCase(repository),
        fenix: true,
      );
      print('    • GetCategoriesUseCase ✅');
    } else {
      print('    • GetCategoriesUseCase ℹ️ (ya existe)');
    }

    // ✅ CRÍTICO: GetCategoryByIdUseCase
    if (!Get.isRegistered<GetCategoryByIdUseCase>()) {
      Get.lazyPut<GetCategoryByIdUseCase>(
        () => GetCategoryByIdUseCase(repository),
        fenix: true,
      );
      print('    • GetCategoryByIdUseCase ✅');
    } else {
      print('    • GetCategoryByIdUseCase ℹ️ (ya existe)');
    }

    // GetCategoryTreeUseCase
    if (!Get.isRegistered<GetCategoryTreeUseCase>()) {
      Get.lazyPut<GetCategoryTreeUseCase>(
        () => GetCategoryTreeUseCase(repository),
        fenix: true,
      );
      print('    • GetCategoryTreeUseCase ✅');
    } else {
      print('    • GetCategoryTreeUseCase ℹ️ (ya existe)');
    }

    // CreateCategoryUseCase
    if (!Get.isRegistered<CreateCategoryUseCase>()) {
      Get.lazyPut<CreateCategoryUseCase>(
        () => CreateCategoryUseCase(repository),
        fenix: true,
      );
      print('    • CreateCategoryUseCase ✅');
    } else {
      print('    • CreateCategoryUseCase ℹ️ (ya existe)');
    }

    // UpdateCategoryUseCase
    if (!Get.isRegistered<UpdateCategoryUseCase>()) {
      Get.lazyPut<UpdateCategoryUseCase>(
        () => UpdateCategoryUseCase(repository),
        fenix: true,
      );
      print('    • UpdateCategoryUseCase ✅');
    } else {
      print('    • UpdateCategoryUseCase ℹ️ (ya existe)');
    }

    // DeleteCategoryUseCase
    if (!Get.isRegistered<DeleteCategoryUseCase>()) {
      Get.lazyPut<DeleteCategoryUseCase>(
        () => DeleteCategoryUseCase(repository),
        fenix: true,
      );
      print('    • DeleteCategoryUseCase ✅');
    } else {
      print('    • DeleteCategoryUseCase ℹ️ (ya existe)');
    }

    // SearchCategoriesUseCase
    if (!Get.isRegistered<SearchCategoriesUseCase>()) {
      Get.lazyPut<SearchCategoriesUseCase>(
        () => SearchCategoriesUseCase(repository),
        fenix: true,
      );
      print('    • SearchCategoriesUseCase ✅');
    } else {
      print('    • SearchCategoriesUseCase ℹ️ (ya existe)');
    }

    // GetCategoryStatsUseCase
    if (!Get.isRegistered<GetCategoryStatsUseCase>()) {
      Get.lazyPut<GetCategoryStatsUseCase>(
        () => GetCategoryStatsUseCase(repository),
        fenix: true,
      );
      print('    • GetCategoryStatsUseCase ✅');
    } else {
      print('    • GetCategoryStatsUseCase ℹ️ (ya existe)');
    }

    print('  ✅ Todos los casos de uso registrados');
  }

  /// Registrar capa de presentación (Controllers) - ✅ VERSIÓN CORREGIDA
  void _registerPresentationLayer() {
    print('🎮 Registrando controllers...');

    // CategoriesController
    if (!Get.isRegistered<CategoriesController>()) {
      Get.lazyPut<CategoriesController>(
        () => CategoriesController(
          getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
          deleteCategoryUseCase: Get.find<DeleteCategoryUseCase>(),
          searchCategoriesUseCase: Get.find<SearchCategoriesUseCase>(),
          getCategoryStatsUseCase: Get.find<GetCategoryStatsUseCase>(),
        ),
        fenix: true,
      );
      print('  ✅ CategoriesController registrado');
    }

    // ✅ CORRECCIÓN CRÍTICA: CategoryFormController
    if (!Get.isRegistered<CategoryFormController>()) {
      Get.lazyPut<CategoryFormController>(
        () => CategoryFormController(
          createCategoryUseCase: Get.find<CreateCategoryUseCase>(),
          updateCategoryUseCase: Get.find<UpdateCategoryUseCase>(),
          getCategoryTreeUseCase: Get.find<GetCategoryTreeUseCase>(),
          getCategoryByIdUseCase:
              Get.find<
                GetCategoryByIdUseCase
              >(), // ✅ CAMBIO: Específico en lugar de genérico
        ),
        fenix: true,
      );
      print('  ✅ CategoryFormController registrado');
    }

    // CategoryDetailController
    if (!Get.isRegistered<CategoryDetailController>()) {
      Get.lazyPut<CategoryDetailController>(
        () => CategoryDetailController(
          getCategoryByIdUseCase: Get.find<GetCategoryByIdUseCase>(),
          getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
          deleteCategoryUseCase: Get.find<DeleteCategoryUseCase>(),
          updateCategoryUseCase: Get.find<UpdateCategoryUseCase>(),
        ),
        fenix: true,
      );
      print('  ✅ CategoryDetailController registrado');
    }

    // CategoryTreeController
    if (!Get.isRegistered<CategoryTreeController>()) {
      Get.lazyPut<CategoryTreeController>(
        () => CategoryTreeController(
          getCategoryTreeUseCase: Get.find<GetCategoryTreeUseCase>(),
        ),
        fenix: true,
      );
      print('  ✅ CategoryTreeController registrado');
    }
  }

  @override
  void onDispose() {
    print('🧹 CategoryBinding: Iniciando limpieza de dependencias...');

    try {
      // Limpiar controllers (estos no son permanentes)
      _cleanupControllers();

      // Limpiar use cases (estos no son permanentes)
      _cleanupUseCases();

      // Las dependencias de datos (DataSources, Repository) son fenix,
      // se auto-gestionan, pero podemos forzar su limpieza si es necesario
      _cleanupDataLayer();

      print('✅ CategoryBinding: Limpieza completada exitosamente');
    } catch (e) {
      print('⚠️ CategoryBinding: Error durante limpieza: $e');
    }
  }

  void _cleanupControllers() {
    final controllers = [
      CategoriesController,
      CategoryFormController,
      CategoryDetailController,
      CategoryTreeController,
    ];

    for (final controller in controllers) {
      try {
        if (Get.isRegistered(tag: controller.toString())) {
          Get.delete(tag: controller.toString(), force: true);
          print('  🗑️ ${controller.toString()} eliminado');
        }
      } catch (e) {
        print('  ⚠️ Error eliminando ${controller.toString()}: $e');
      }
    }
  }

  void _cleanupUseCases() {
    final useCases = [
      GetCategoriesUseCase,
      GetCategoryByIdUseCase,
      GetCategoryTreeUseCase,
      CreateCategoryUseCase,
      UpdateCategoryUseCase,
      DeleteCategoryUseCase,
      SearchCategoriesUseCase,
      GetCategoryStatsUseCase,
    ];

    for (final useCase in useCases) {
      try {
        if (Get.isRegistered(tag: useCase.toString())) {
          Get.delete(tag: useCase.toString(), force: true);
          print('  🗑️ ${useCase.toString()} eliminado');
        }
      } catch (e) {
        print('  ⚠️ Error eliminando ${useCase.toString()}: $e');
      }
    }
  }

  void _cleanupDataLayer() {
    // Solo limpiar si realmente queremos forzar la recreación
    // Normalmente las dependencias fenix se auto-gestionan
    final dataTypes = [
      CategoryRepository,
      CategoryRemoteDataSource,
      CategoryLocalDataSource,
    ];

    for (final dataType in dataTypes) {
      try {
        if (Get.isRegistered(tag: dataType.toString())) {
          Get.delete(tag: dataType.toString(), force: true);
          print('  🗑️ ${dataType.toString()} eliminado');
        }
      } catch (e) {
        print('  ⚠️ Error eliminando ${dataType.toString()}: $e');
      }
    }
  }
}

/// Helper class para debugging y acceso seguro a dependencias
class CategoryBindingHelper {
  /// Verificar si todas las dependencias están registradas
  static bool get isFullyInitialized {
    final requiredTypes = [
      CategoryRepository,
      CategoriesController,
      CategoryFormController,
      CategoryDetailController,
      CategoryTreeController,
      GetCategoryByIdUseCase, // ✅ AGREGADO para verificación
    ];

    return requiredTypes.every(
      (type) => Get.isRegistered(tag: type.toString()),
    );
  }

  /// Imprimir resumen del registro de dependencias
  static void printRegistrationSummary() {
    print('📋 ===============================================');
    print('📋 RESUMEN DE REGISTRO - CATEGORY BINDING');
    print('📋 ===============================================');

    final dependencies = {
      '🏗️ Core': {
        'DioClient': Get.isRegistered<DioClient>(),
        'SecureStorageService': Get.isRegistered<SecureStorageService>(),
        'NetworkInfo': Get.isRegistered<NetworkInfo>(),
        'Connectivity': Get.isRegistered<Connectivity>(),
      },
      '💾 Data Layer': {
        'CategoryRepository': Get.isRegistered<CategoryRepository>(),
        'CategoryRemoteDataSource':
            Get.isRegistered<CategoryRemoteDataSource>(),
        'CategoryLocalDataSource': Get.isRegistered<CategoryLocalDataSource>(),
      },
      '🎯 Use Cases': {
        'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
        'GetCategoryByIdUseCase': Get.isRegistered<GetCategoryByIdUseCase>(),
        'GetCategoryTreeUseCase': Get.isRegistered<GetCategoryTreeUseCase>(),
        'CreateCategoryUseCase': Get.isRegistered<CreateCategoryUseCase>(),
        'UpdateCategoryUseCase': Get.isRegistered<UpdateCategoryUseCase>(),
        'DeleteCategoryUseCase': Get.isRegistered<DeleteCategoryUseCase>(),
        'SearchCategoriesUseCase': Get.isRegistered<SearchCategoriesUseCase>(),
        'GetCategoryStatsUseCase': Get.isRegistered<GetCategoryStatsUseCase>(),
      },
      '🎮 Controllers': {
        'CategoriesController': Get.isRegistered<CategoriesController>(),
        'CategoryFormController': Get.isRegistered<CategoryFormController>(),
        'CategoryDetailController':
            Get.isRegistered<CategoryDetailController>(),
        'CategoryTreeController': Get.isRegistered<CategoryTreeController>(),
      },
    };

    dependencies.forEach((category, deps) {
      print('$category:');
      deps.forEach((name, isRegistered) {
        final status = isRegistered ? '✅' : '❌';
        print('   $status $name');
      });
      print('');
    });

    final status =
        isFullyInitialized
            ? '✅ COMPLETAMENTE INICIALIZADO'
            : '❌ INICIALIZACIÓN INCOMPLETA';
    print('📋 Estado: $status');
    print('📋 ===============================================');
  }

  /// Obtener controller de forma segura
  static T? safeGet<T>() {
    try {
      return Get.isRegistered<T>() ? Get.find<T>() : null;
    } catch (e) {
      print('❌ Error obteniendo ${T.toString()}: $e');
      return null;
    }
  }

  /// Verificar si una dependencia específica está registrada
  static bool isDependencyRegistered<T>() {
    return Get.isRegistered<T>();
  }

  /// Obtener estado completo para debugging
  static Map<String, bool> getRegistrationStatus() {
    return {
      'CategoryRepository': Get.isRegistered<CategoryRepository>(),
      'CategoriesController': Get.isRegistered<CategoriesController>(),
      'CategoryFormController': Get.isRegistered<CategoryFormController>(),
      'CategoryDetailController': Get.isRegistered<CategoryDetailController>(),
      'CategoryTreeController': Get.isRegistered<CategoryTreeController>(),
      'GetCategoriesUseCase': Get.isRegistered<GetCategoriesUseCase>(),
      'GetCategoryByIdUseCase':
          Get.isRegistered<GetCategoryByIdUseCase>(), // ✅ AGREGADO
      'CreateCategoryUseCase': Get.isRegistered<CreateCategoryUseCase>(),
      'UpdateCategoryUseCase': Get.isRegistered<UpdateCategoryUseCase>(),
    };
  }

  /// ✅ NUEVO: Método para debugging específico del problema
  static void debugCategoryFormControllerDependencies() {
    print('🔍 DEBUG: CategoryFormController Dependencies');
    print(
      '   GetCategoryByIdUseCase: ${Get.isRegistered<GetCategoryByIdUseCase>()}',
    );
    print(
      '   CreateCategoryUseCase: ${Get.isRegistered<CreateCategoryUseCase>()}',
    );
    print(
      '   UpdateCategoryUseCase: ${Get.isRegistered<UpdateCategoryUseCase>()}',
    );
    print(
      '   GetCategoryTreeUseCase: ${Get.isRegistered<GetCategoryTreeUseCase>()}',
    );
    print(
      '   CategoryFormController: ${Get.isRegistered<CategoryFormController>()}',
    );

    if (Get.isRegistered<GetCategoryByIdUseCase>()) {
      try {
        final useCase = Get.find<GetCategoryByIdUseCase>();
        print('   ✅ GetCategoryByIdUseCase se puede obtener correctamente');
      } catch (e) {
        print('   ❌ Error al obtener GetCategoryByIdUseCase: $e');
      }
    }
  }
}
