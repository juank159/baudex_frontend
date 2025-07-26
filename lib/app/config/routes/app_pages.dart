// lib/app/config/routes/app_pages.dart
import 'package:baudex_desktop/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:baudex_desktop/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:baudex_desktop/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:baudex_desktop/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:baudex_desktop/features/dashboard/presentation/bindings/dashboard_binding.dart';
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
import 'package:baudex_desktop/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:baudex_desktop/features/customers/presentation/bindings/customer_binding.dart';
import 'package:baudex_desktop/features/customers/presentation/controllers/customer_detail_controller.dart';
import 'package:baudex_desktop/features/customers/presentation/controllers/customer_form_controller.dart';
import 'package:baudex_desktop/features/customers/presentation/controllers/customers_controller.dart';
import 'package:baudex_desktop/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:baudex_desktop/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:baudex_desktop/features/customers/presentation/screens/customer_stats_screen.dart';
import 'package:baudex_desktop/features/customers/presentation/screens/modern_customers_list_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/bindings/invoice_binding.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_screen_wrapper.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_list_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_print_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_settings_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_stats_screen.dart';
import 'package:baudex_desktop/features/settings/presentation/screens/printer_configuration_screen.dart';
import 'package:baudex_desktop/features/settings/presentation/screens/organization_settings_screen.dart';
import 'package:baudex_desktop/features/settings/presentation/bindings/settings_binding.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/settings_controller.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/organization_controller.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_products_usecase.dart';
import 'package:baudex_desktop/features/products/presentation/bindings/product_binding.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/products_controller.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_detail_controller.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_form_controller.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_form_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_stats_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/products_list_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_detail_screen.dart';
import 'package:baudex_desktop/features/expenses/presentation/bindings/expense_binding.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/expenses_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/expense_form_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/expense_detail_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/expense_categories_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/expenses_list_screen.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/expense_detail_screen.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/expense_categories_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/register_screen.dart';
import '../../../features/auth/presentation/screens/profile_screen.dart';
import '../../shared/screens/not_found_screen.dart';
import 'app_routes.dart';

// Helper para registrar dependencias optimizadas para pestañas
void _registerInvoiceTabsDependencies() {
  print('🔧 [PESTAÑAS] Registrando SOLO dependencias esenciales...');

  // Registrar dependencias básicas de Invoice (SIN estadísticas automáticas)
  if (!InvoiceBinding.areBaseDependenciesRegistered()) {
    print('📄 [PESTAÑAS] Registrando InvoiceBinding base sin estadísticas...');
    InvoiceBinding().dependenciesWithoutStats();
    print('✅ [PESTAÑAS] InvoiceBinding base registrado (sin estadísticas)');
  }

  // Customer dependencies
  try {
    Get.find<GetCustomersUseCase>();
    print('✅ [PESTAÑAS] CustomerBinding ya registrado');
  } catch (e) {
    print('📄 [PESTAÑAS] Registrando CustomerBinding...');
    CustomerBinding().dependencies();
    print('✅ [PESTAÑAS] CustomerBinding registrado');
  }

  // Product dependencies
  try {
    Get.find<GetProductsUseCase>();
    print('✅ [PESTAÑAS] ProductBinding ya registrado');
  } catch (e) {
    print('📄 [PESTAÑAS] Registrando ProductBinding...');
    ProductBinding().dependencies();
    print('✅ [PESTAÑAS] ProductBinding registrado');
  }
}

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
      // ✅ NO BINDING - Las dependencias son GLOBALES desde InitialBinding
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
      preventDuplicates: true, // ✅ Prevenir duplicación de rutas
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

    // ✅ NUEVA RUTA PARA ESTADÍSTICAS DE PRODUCTOS
    // GetPage(
    //   name: AppRoutes.productsStats,
    //   page: () => const ProductStatsScreen(),
    //   binding: BindingsBuilder(() {
    //     print('🔧 [ESTADÍSTICAS PRODUCTOS] Verificando ProductsController...');
    //     if (!Get.isRegistered<ProductsController>()) {
    //       print(
    //         '📦 [ESTADÍSTICAS PRODUCTOS] Registrando ProductBinding para ProductsController',
    //       );
    //       ProductBinding().dependencies();
    //       print('✅ [ESTADÍSTICAS PRODUCTOS] ProductBinding registrado exitosamente');
    //     } else {
    //       print('✅ [ESTADÍSTICAS PRODUCTOS] ProductsController ya registrado');
    //     }
    //   }),
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

    // ==================== CUSTOMERS PAGES ====================
    GetPage(
      name: AppRoutes.customers,
      page: () => const ModernCustomersListScreen(),
      binding: CustomerBinding(), // ✅ OK - Solo necesita CustomersController
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // // ✅ CREAR CLIENTE - USAR CustomerFormBinding
    // GetPage(
    //   name: AppRoutes.customersCreate,
    //   page: () => const CustomerFormScreen(),
    //   binding:
    //       CustomerFormBinding(), // ← CAMBIADO: Usar CustomerFormBinding directamente
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    //   middlewares: [AuthMiddleware()],
    // ),

    // // ✅ EDITAR CLIENTE - USAR CustomerFormBinding
    // GetPage(
    //   name: '${AppRoutes.customersEdit}/:id',
    //   page: () => const CustomerFormScreen(),
    //   binding:
    //       CustomerFormBinding(), // ← CAMBIADO: Usar CustomerFormBinding directamente
    //   transition: Transition.rightToLeft,
    //   transitionDuration: const Duration(milliseconds: 300),
    //   middlewares: [AuthMiddleware()],
    // ),
    GetPage(
      name: AppRoutes.customersCreate,
      page: () => const CustomerFormScreen(),
      binding: CustomerFormBinding(), // ← CAMBIADO: binding directo
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.customersEdit}/:id',
      page: () => const CustomerFormScreen(),
      binding: CustomerFormBinding(), // ← CAMBIADO: binding directo
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ DETALLE CLIENTE - USAR CustomerDetailBinding
    GetPage(
      name: '${AppRoutes.customersDetail}/:id',
      page: () => const CustomerDetailScreen(),
      binding:
          CustomerDetailBinding(), // ← CAMBIADO: Usar CustomerDetailBinding directamente
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ✅ ESTADÍSTICAS CLIENTES - USAR CustomerStatsBinding
    GetPage(
      name: AppRoutes.customersStats,
      page: () => const CustomerStatsScreen(),
      binding:
          CustomerStatsBinding(), // ← CAMBIADO: Usar CustomerStatsBinding directamente
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ==================== INVOICES PAGES ====================

    // 📋 LISTA DE FACTURAS
    GetPage(
      name: AppRoutes.invoices,
      page: () => const InvoiceListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [LISTA FACTURAS] Inicializando bindings...');

        // 1. Registrar dependencias base del InvoiceBinding
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [LISTA FACTURAS] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [LISTA FACTURAS] InvoiceBinding base registrado');
        }

        // 2. Registrar controlador específico de lista
        InvoiceBinding.registerListController();
        print('✅ [LISTA FACTURAS] InvoiceListController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // 📝 CREAR FACTURA
    GetPage(
      name: AppRoutes.invoicesCreate,
      page: () => const InvoiceFormScreenWrapper(),
      // ✅ SOLUCIÓN RADICAL: NO BINDING - Todo lazy
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ✏️ EDITAR FACTURA
    GetPage(
      name: '${AppRoutes.invoicesEdit}/:id',
      page: () => const InvoiceFormScreenWrapper(),
      // ✅ SOLUCIÓN RADICAL: NO BINDING - Todo lazy
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // 👁️ DETALLE DE FACTURA
    GetPage(
      name: '${AppRoutes.invoicesDetail}/:id',
      page: () => const InvoiceDetailScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [DETALLE FACTURA] Inicializando bindings...');

        // 1. Verificar y registrar dependencias base
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [DETALLE FACTURA] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [DETALLE FACTURA] InvoiceBinding base registrado');
        }

        // 2. Registrar controlador específico de detalle
        InvoiceBinding.registerDetailController();
        print('✅ [DETALLE FACTURA] InvoiceDetailController registrado');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // 📊 ESTADÍSTICAS DE FACTURAS
    GetPage(
      name: AppRoutes.invoicesStats,
      page: () => const InvoiceStatsScreen(),
      binding: BindingsBuilder(() {
        try {
          print('🔧 [ESTADÍSTICAS FACTURAS] Inicializando bindings...');

          // Siempre registrar dependencias base si no están
          if (!InvoiceBinding.areBaseDependenciesRegistered()) {
            print(
              '📄 [ESTADÍSTICAS FACTURAS] Registrando InvoiceBinding base...',
            );
            InvoiceBinding().dependencies();
            print('✅ [ESTADÍSTICAS FACTURAS] InvoiceBinding base registrado');
          }

          // Verificar que el stats controller esté disponible
          if (!InvoiceBinding.isStatsControllerRegistered()) {
            print(
              '⚠️ [ESTADÍSTICAS FACTURAS] Re-registrando stats controller...',
            );
            InvoiceBinding().dependencies();
          }

          print('✅ [ESTADÍSTICAS FACTURAS] Binding completado exitosamente');
        } catch (e) {
          print('❌ [ESTADÍSTICAS FACTURAS] Error en binding: $e');
          // Fallback: registrar binding básico
          InvoiceBinding().dependencies();
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
      middlewares: [AuthMiddleware()],
    ),

    // 🖨️ IMPRIMIR FACTURA
    GetPage(
      name: '${AppRoutes.invoicesPrint}/:id',
      page:
          () => const InvoicePrintScreen(), // ← Necesitarás crear esta pantalla
      binding: BindingsBuilder(() {
        print('🔧 [IMPRIMIR FACTURA] Inicializando bindings...');

        // Solo necesita el controlador de detalle para obtener los datos
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [IMPRIMIR FACTURA] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [IMPRIMIR FACTURA] InvoiceBinding base registrado');
        }

        // Registrar controlador de detalle para obtener la factura
        InvoiceBinding.registerDetailController();
        print('✅ [IMPRIMIR FACTURA] InvoiceDetailController registrado');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ⚠️ FACTURAS VENCIDAS
    GetPage(
      name: AppRoutes.invoicesOverdue,
      page:
          () =>
              const InvoiceListScreen(), // Reutiliza la lista con filtro de vencidas
      binding: BindingsBuilder(() {
        print('🔧 [FACTURAS VENCIDAS] Inicializando bindings...');

        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [FACTURAS VENCIDAS] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [FACTURAS VENCIDAS] InvoiceBinding base registrado');
        }

        InvoiceBinding.registerListController();
        print('✅ [FACTURAS VENCIDAS] InvoiceListController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // 👤 FACTURAS POR CLIENTE
    GetPage(
      name: '/invoices/customer/:customerId',
      page:
          () =>
              const InvoiceListScreen(), // Reutiliza la lista con filtro por cliente
      binding: BindingsBuilder(() {
        print('🔧 [FACTURAS POR CLIENTE] Inicializando bindings...');

        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [FACTURAS POR CLIENTE] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [FACTURAS POR CLIENTE] InvoiceBinding base registrado');
        }

        InvoiceBinding.registerListController();
        print('✅ [FACTURAS POR CLIENTE] InvoiceListController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // 📋 FACTURAS POR ESTADO
    GetPage(
      name: '/invoices/status/:status',
      page:
          () =>
              const InvoiceListScreen(), // Reutiliza la lista con filtro por estado
      binding: BindingsBuilder(() {
        print('🔧 [FACTURAS POR ESTADO] Inicializando bindings...');

        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [FACTURAS POR ESTADO] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [FACTURAS POR ESTADO] InvoiceBinding base registrado');
        }

        InvoiceBinding.registerListController();
        print('✅ [FACTURAS POR ESTADO] InvoiceListController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ==================== EXPENSES PAGES ====================
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensesListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [LISTA GASTOS] Inicializando bindings...');
        ExpenseBinding().dependencies();
        print('✅ [LISTA GASTOS] ExpenseBinding registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.expensesCreate,
      page: () => const ExpenseFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR GASTO] Inicializando bindings...');
        ExpenseBinding().dependencies();
        if (!Get.isRegistered<ExpenseFormController>()) {
          Get.lazyPut<ExpenseFormController>(
            () => ExpenseFormController(
              createExpenseUseCase: Get.find(),
              updateExpenseUseCase: Get.find(),
              getExpenseByIdUseCase: Get.find(),
              getExpenseCategoriesUseCase: Get.find(),
              createExpenseCategoryUseCase: Get.find(),
              fileService: Get.find(),
            ),
          );
        }
        print('✅ [CREAR GASTO] ExpenseFormController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.expensesEdit}/:id',
      page: () => const ExpenseFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [EDITAR GASTO] Inicializando bindings...');
        ExpenseBinding().dependencies();
        if (!Get.isRegistered<ExpenseFormController>()) {
          Get.lazyPut<ExpenseFormController>(
            () => ExpenseFormController(
              createExpenseUseCase: Get.find(),
              updateExpenseUseCase: Get.find(),
              getExpenseByIdUseCase: Get.find(),
              getExpenseCategoriesUseCase: Get.find(),
              createExpenseCategoryUseCase: Get.find(),
              fileService: Get.find(),
            ),
          );
        }
        print('✅ [EDITAR GASTO] ExpenseFormController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.expensesDetail}/:id',
      page: () => const ExpenseDetailScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [DETALLE GASTO] Inicializando bindings...');
        ExpenseBinding().dependencies();
        if (!Get.isRegistered<ExpenseDetailController>()) {
          Get.lazyPut<ExpenseDetailController>(
            () => ExpenseDetailController(
              getExpenseByIdUseCase: Get.find(),
              deleteExpenseUseCase: Get.find(),
              approveExpenseUseCase: Get.find(),
              submitExpenseUseCase: Get.find(),
            ),
          );
        }
        print('✅ [DETALLE GASTO] ExpenseDetailController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/expenses/category/:categoryId',
      page: () => const ExpensesListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [GASTOS POR CATEGORÍA] Verificando ExpensesController...');
        ExpenseBinding().dependencies();
        print('✅ [GASTOS POR CATEGORÍA] ExpensesController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/expenses/status/:status',
      page: () => const ExpensesListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [GASTOS POR ESTADO] Verificando ExpensesController...');
        ExpenseBinding().dependencies();
        print('✅ [GASTOS POR ESTADO] ExpensesController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.expensesCategories,
      page: () => const ExpenseCategoriesScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CATEGORÍAS GASTOS] Inicializando bindings...');
        ExpenseBinding().dependencies();
        if (!Get.isRegistered<ExpenseCategoriesController>()) {
          Get.lazyPut<ExpenseCategoriesController>(
            () => ExpenseCategoriesController(
              getExpenseCategoriesUseCase: Get.find(),
              createExpenseCategoryUseCase: Get.find(),
              updateExpenseCategoryUseCase: Get.find(),
              deleteExpenseCategoryUseCase: Get.find(),
            ),
          );
        }
        print('✅ [CATEGORÍAS GASTOS] ExpenseCategoriesController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ==================== SETTINGS PAGES ====================
    GetPage(
      name: AppRoutes.settingsPrinter,
      page: () => const PrinterConfigurationScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CONFIGURACIÓN IMPRESORA] Inicializando SettingsBinding...');

        if (!Get.isRegistered<SettingsController>()) {
          SettingsBinding().dependencies();
        }

        print('✅ [CONFIGURACIÓN IMPRESORA] SettingsController disponible');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // ⚙️ CONFIGURACIÓN DE FACTURAS
    GetPage(
      name: AppRoutes.settingsInvoice,
      page: () => const InvoiceSettingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // 🏢 CONFIGURACIÓN DE ORGANIZACIÓN
    GetPage(
      name: AppRoutes.settingsOrganization,
      page: () => const OrganizationSettingsScreen(),
      binding: BindingsBuilder(() {
        print(
          '🔧 [CONFIGURACIÓN ORGANIZACIÓN] Inicializando SettingsBinding...',
        );

        if (!Get.isRegistered<SettingsController>() ||
            !Get.isRegistered<OrganizationController>()) {
          SettingsBinding().dependencies();
        }

        print('✅ [CONFIGURACIÓN ORGANIZACIÓN] Controllers disponibles');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      middlewares: [AuthMiddleware()],
    ),

    // 📝 FACTURAS CON PESTAÑAS
    GetPage(
      name: AppRoutes.invoicesWithTabs,
      page: () => const InvoiceFormTabsScreen(),
      binding: BindingsBuilder(() {
        // Usar helper optimizado que NO carga estadísticas automáticamente
        _registerInvoiceTabsDependencies();
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
