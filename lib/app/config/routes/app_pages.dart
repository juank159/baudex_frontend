// import 'package:baudex_desktop/app/shared/screens/dashboard_screen.dart';
// import 'package:baudex_desktop/app/shared/screens/splash_screen.dart';
// import 'package:baudex_desktop/features/categories/presentation/bindings/category_binding.dart';
// import 'package:baudex_desktop/features/categories/presentation/controllers/category_detail_controller.dart';
// import 'package:baudex_desktop/features/categories/presentation/controllers/category_form_controller.dart';
// import 'package:baudex_desktop/features/categories/presentation/controllers/category_tree_controller.dart';
// import 'package:baudex_desktop/features/categories/presentation/screens/categories_list_screen.dart';
// import 'package:baudex_desktop/features/categories/presentation/screens/category_detail_screen.dart';
// import 'package:baudex_desktop/features/categories/presentation/screens/category_form_screen.dart';
// import 'package:baudex_desktop/features/categories/presentation/screens/category_tree_screen.dart';
// import 'package:baudex_desktop/features/products/presentation/bindings/product_binding.dart';
// import 'package:baudex_desktop/features/products/presentation/controllers/products_controller.dart';
// import 'package:baudex_desktop/features/products/presentation/controllers/product_detail_controller.dart';
// import 'package:baudex_desktop/features/products/presentation/controllers/product_form_controller.dart';
// import 'package:baudex_desktop/features/products/presentation/screens/product_form_screen.dart';
// import 'package:baudex_desktop/features/products/presentation/screens/product_stats_screen.dart';
// import 'package:baudex_desktop/features/products/presentation/screens/products_list_screen.dart';
// import 'package:baudex_desktop/features/products/presentation/screens/product_detail_screen.dart';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../features/auth/presentation/controllers/auth_controller.dart';
// import '../../../features/auth/presentation/screens/login_screen.dart';
// import '../../../features/auth/presentation/screens/register_screen.dart';
// import '../../../features/auth/presentation/screens/profile_screen.dart';
// import '../../shared/screens/not_found_screen.dart';
// import 'app_routes.dart';

// class AppPages {
//   static final pages = [
//     // ==================== SPLASH PAGE ====================
//     GetPage(
//       name: AppRoutes.splash,
//       page: () => const SplashScreen(),
//       // ✅ No necesita binding porque AuthController ya está en InitialBinding
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//     ),

//     // ==================== AUTH PAGES ====================
//     GetPage(
//       name: AppRoutes.login,
//       page: () => const LoginScreen(),
//       // ✅ No necesita binding porque AuthController ya está en InitialBinding
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       preventDuplicates: true,
//     ),

//     GetPage(
//       name: AppRoutes.register,
//       page: () => const RegisterScreen(),
//       // ✅ No necesita binding porque AuthController ya está en InitialBinding
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       preventDuplicates: true,
//     ),

//     GetPage(
//       name: AppRoutes.profile,
//       page: () => const ProfileScreen(),
//       // ✅ No necesita binding porque AuthController ya está en InitialBinding
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     // ==================== DASHBOARD ====================
//     GetPage(
//       name: AppRoutes.dashboard,
//       page: () => const DashboardScreen(),
//       // ✅ No necesita binding porque AuthController ya está en InitialBinding
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     // ==================== CATEGORIES PAGES ====================
//     GetPage(
//       name: AppRoutes.categories,
//       page: () => const CategoriesListScreen(),
//       binding: CategoryBinding(),
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: AppRoutes.categoriesCreate,
//       page: () => const CategoryFormScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<CategoryFormController>()) {
//           CategoryBinding().dependencies();
//         }
//       }),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: '${AppRoutes.categoriesEdit}/:id',
//       page: () => const CategoryFormScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<CategoryFormController>()) {
//           CategoryBinding().dependencies();
//         }
//       }),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: '${AppRoutes.categoriesDetail}/:id',
//       page: () => const CategoryDetailScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<CategoryDetailController>()) {
//           CategoryBinding().dependencies();
//         }
//       }),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: AppRoutes.categoriesTree,
//       page: () => const CategoryTreeScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<CategoryTreeController>()) {
//           CategoryBinding().dependencies();
//         }
//       }),
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     // ==================== PRODUCTS PAGES ====================
//     GetPage(
//       name: AppRoutes.products,
//       page: () => const ProductsListScreen(),
//       binding: ProductBinding(),
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: AppRoutes.productsCreate,
//       page: () => const ProductFormScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<ProductFormController>()) {
//           ProductBinding().dependencies();
//         }
//       }),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: '${AppRoutes.productsEdit}/:id',
//       page: () => const ProductFormScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<ProductFormController>()) {
//           ProductBinding().dependencies();
//         }
//       }),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: '${AppRoutes.productsDetail}/:id',
//       page: () => const ProductDetailScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<ProductDetailController>()) {
//           ProductBinding().dependencies();
//         }
//       }),
//       transition: Transition.rightToLeft,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: AppRoutes.productsLowStock,
//       page: () => const ProductsListScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<ProductsController>()) {
//           ProductBinding().dependencies();
//         }
//       }),
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: AppRoutes.productsStats,
//       page: () => const ProductStatsScreen(),
//       binding: ProductBinding(),
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     GetPage(
//       name: '/products/category/:categoryId',
//       page: () => const ProductsListScreen(),
//       binding: BindingsBuilder(() {
//         if (!Get.isRegistered<ProductsController>()) {
//           ProductBinding().dependencies();
//         }
//       }),
//       transition: Transition.fade,
//       transitionDuration: const Duration(milliseconds: 300),
//       middlewares: [AuthMiddleware()],
//     ),

//     // ==================== ERROR PAGES ====================
//     GetPage(
//       name: AppRoutes.notFound,
//       page: () => const NotFoundScreen(),
//       transition: Transition.fade,
//     ),
//   ];
// }

// // ✅ Middleware mejorado con mejor manejo de errores
// class AuthMiddleware extends GetMiddleware {
//   @override
//   RouteSettings? redirect(String? route) {
//     try {
//       final authController = Get.find<AuthController>();

//       if (!authController.isAuthenticated) {
//         print(
//           '🔒 AuthMiddleware: Usuario no autenticado, redirigiendo a login',
//         );
//         return const RouteSettings(name: AppRoutes.login);
//       }

//       print(
//         '✅ AuthMiddleware: Usuario autenticado, permitiendo acceso a $route',
//       );
//       return null; // Permitir acceso
//     } catch (e) {
//       print('❌ AuthMiddleware: Error al verificar autenticación - $e');
//       return const RouteSettings(name: AppRoutes.login);
//     }
//   }
// }

import 'package:baudex_desktop/app/shared/screens/dashboard_screen.dart';
import 'package:baudex_desktop/app/shared/screens/splash_screen.dart';
import 'package:baudex_desktop/features/categories/domain/usecases/get_categories_usecase.dart';
import 'package:baudex_desktop/features/categories/presentation/bindings/category_binding.dart';
import 'package:baudex_desktop/features/categories/presentation/controllers/category_detail_controller.dart';
import 'package:baudex_desktop/features/categories/presentation/controllers/category_form_controller.dart';
import 'package:baudex_desktop/features/categories/presentation/controllers/category_tree_controller.dart';
import 'package:baudex_desktop/features/categories/presentation/screens/categories_list_screen.dart';
import 'package:baudex_desktop/features/categories/presentation/screens/category_detail_screen.dart';
import 'package:baudex_desktop/features/categories/presentation/screens/category_form_screen.dart';
import 'package:baudex_desktop/features/categories/presentation/screens/category_tree_screen.dart';
import 'package:baudex_desktop/features/products/presentation/bindings/product_binding.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/products_controller.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_detail_controller.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_form_controller.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_form_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_stats_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/products_list_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_detail_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/register_screen.dart';
import '../../../features/auth/presentation/screens/profile_screen.dart';
import '../../shared/screens/not_found_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    // ==================== SPLASH PAGE ====================
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ==================== AUTH PAGES ====================
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ==================== DASHBOARD ====================
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ==================== CATEGORIES PAGES ====================
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesListScreen(),
      binding: CategoryBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.categoriesCreate,
      page: () => const CategoryFormScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CategoryFormController>()) {
          CategoryBinding().dependencies();
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.categoriesEdit}/:id',
      page: () => const CategoryFormScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CategoryFormController>()) {
          CategoryBinding().dependencies();
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.categoriesDetail}/:id',
      page: () => const CategoryDetailScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CategoryDetailController>()) {
          CategoryBinding().dependencies();
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.categoriesTree,
      page: () => const CategoryTreeScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CategoryTreeController>()) {
          CategoryBinding().dependencies();
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ==================== PRODUCTS PAGES ====================
    // GetPage(
    //   name: AppRoutes.products,
    //   page: () => const ProductsListScreen(),
    //   binding: ProductBinding(),
    //   transition: Transition.fade,
    //   transitionDuration: const Duration(milliseconds: 300),
    //   middlewares: [AuthMiddleware()],
    // ),
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [LISTA PRODUCTOS] Inicializando bindings...');

        // CategoryBinding primero (para filtros de categoría)
        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          print('📂 [LISTA PRODUCTOS] Registrando CategoryBinding...');
          CategoryBinding().dependencies();
          print('✅ [LISTA PRODUCTOS] CategoryBinding registrado');
        }

        // ProductBinding después
        if (!Get.isRegistered<ProductsController>()) {
          print('📦 [LISTA PRODUCTOS] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [LISTA PRODUCTOS] ProductBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ CREAR PRODUCTO - CON LOGS MEJORADOS
    // GetPage(
    //   name: AppRoutes.productsCreate,
    //   page: () => const ProductFormScreen(),
    //   binding: BindingsBuilder(() {
    //     print('🔧 [CREAR PRODUCTO] Verificando ProductFormController...');
    //     if (!Get.isRegistered<ProductFormController>()) {
    //       print(
    //         '📦 [CREAR PRODUCTO] Registrando ProductBinding para ProductFormController',
    //       );
    //       ProductBinding().dependencies();
    //       print('✅ [CREAR PRODUCTO] ProductBinding registrado exitosamente');
    //     } else {
    //       print('✅ [CREAR PRODUCTO] ProductFormController ya registrado');
    //     }
    //   }),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    //   middlewares: [AuthMiddleware()],
    // ),
    GetPage(
      name: AppRoutes.productsCreate,
      page: () => const ProductFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR PRODUCTO] Inicializando bindings...');

        // 1. PRIMERO: CategoryBinding (para GetCategoriesUseCase)
        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          print('📂 [CREAR PRODUCTO] Registrando CategoryBinding...');
          CategoryBinding().dependencies();
          print('✅ [CREAR PRODUCTO] CategoryBinding registrado');
        } else {
          print('✅ [CREAR PRODUCTO] GetCategoriesUseCase ya disponible');
        }

        // 2. SEGUNDO: ProductBinding (ahora puede usar GetCategoriesUseCase)
        if (!Get.isRegistered<ProductFormController>()) {
          print('📦 [CREAR PRODUCTO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [CREAR PRODUCTO] ProductBinding registrado');
        } else {
          print('✅ [CREAR PRODUCTO] ProductFormController ya registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ EDITAR PRODUCTO - CON LOGS MEJORADOS
    // GetPage(
    //   name: '${AppRoutes.productsEdit}/:id',
    //   page: () => const ProductFormScreen(),
    //   binding: BindingsBuilder(() {
    //     print('🔧 [EDITAR PRODUCTO] Verificando ProductFormController...');
    //     if (!Get.isRegistered<ProductFormController>()) {
    //       print(
    //         '📦 [EDITAR PRODUCTO] Registrando ProductBinding para ProductFormController',
    //       );
    //       ProductBinding().dependencies();
    //       print('✅ [EDITAR PRODUCTO] ProductBinding registrado exitosamente');
    //     } else {
    //       print('✅ [EDITAR PRODUCTO] ProductFormController ya registrado');
    //     }
    //   }),
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    //   middlewares: [AuthMiddleware()],
    // ),
    GetPage(
      name: '${AppRoutes.productsEdit}/:id',
      page: () => const ProductFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [EDITAR PRODUCTO] Inicializando bindings...');

        // 1. PRIMERO: CategoryBinding
        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          print('📂 [EDITAR PRODUCTO] Registrando CategoryBinding...');
          CategoryBinding().dependencies();
          print('✅ [EDITAR PRODUCTO] CategoryBinding registrado');
        } else {
          print('✅ [EDITAR PRODUCTO] GetCategoriesUseCase ya disponible');
        }

        // 2. SEGUNDO: ProductBinding
        if (!Get.isRegistered<ProductFormController>()) {
          print('📦 [EDITAR PRODUCTO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [EDITAR PRODUCTO] ProductBinding registrado');
        } else {
          print('✅ [EDITAR PRODUCTO] ProductFormController ya registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ DETALLE PRODUCTO - CON LOGS MEJORADOS
    GetPage(
      name: '${AppRoutes.productsDetail}/:id',
      page: () => const ProductDetailScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [DETALLE PRODUCTO] Verificando ProductDetailController...');
        if (!Get.isRegistered<ProductDetailController>()) {
          print(
            '📦 [DETALLE PRODUCTO] Registrando ProductBinding para ProductDetailController',
          );
          ProductBinding().dependencies();
          print('✅ [DETALLE PRODUCTO] ProductBinding registrado exitosamente');
        } else {
          print('✅ [DETALLE PRODUCTO] ProductDetailController ya registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.productsLowStock,
      page: () => const ProductsListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [LOW STOCK] Verificando ProductsController...');
        if (!Get.isRegistered<ProductsController>()) {
          print(
            '📦 [LOW STOCK] Registrando ProductBinding para ProductsController',
          );
          ProductBinding().dependencies();
          print('✅ [LOW STOCK] ProductBinding registrado exitosamente');
        } else {
          print('✅ [LOW STOCK] ProductsController ya registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // GetPage(
    //   name: AppRoutes.productsStats,
    //   page: () => const ProductStatsScreen(),
    //   binding: ProductBinding(),
    //   transition: Transition.fade,
    //   transitionDuration: const Duration(milliseconds: 300),
    //   middlewares: [AuthMiddleware()],
    // ),
    GetPage(
      name: '/products/category/:categoryId',
      page: () => const ProductsListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [PRODUCTOS POR CATEGORÍA] Verificando ProductsController...');
        if (!Get.isRegistered<ProductsController>()) {
          print(
            '📦 [PRODUCTOS POR CATEGORÍA] Registrando ProductBinding para ProductsController',
          );
          ProductBinding().dependencies();
          print(
            '✅ [PRODUCTOS POR CATEGORÍA] ProductBinding registrado exitosamente',
          );
        } else {
          print('✅ [PRODUCTOS POR CATEGORÍA] ProductsController ya registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ==================== ERROR PAGES ====================
    GetPage(
      name: AppRoutes.notFound,
      page: () => const NotFoundScreen(),
      transition: Transition.fade,
    ),
  ];
}

// ✅ Middleware mejorado con mejor manejo de errores
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authController = Get.find<AuthController>();

      if (!authController.isAuthenticated) {
        print(
          '🔒 AuthMiddleware: Usuario no autenticado, redirigiendo a login',
        );
        return const RouteSettings(name: AppRoutes.login);
      }

      print(
        '✅ AuthMiddleware: Usuario autenticado, permitiendo acceso a $route',
      );
      return null; // Permitir acceso
    } catch (e) {
      print('❌ AuthMiddleware: Error al verificar autenticación - $e');
      return const RouteSettings(name: AppRoutes.login);
    }
  }
}
