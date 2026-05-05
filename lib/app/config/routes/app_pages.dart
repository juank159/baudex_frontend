// lib/app/config/routes/app_pages.dart
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
import 'package:baudex_desktop/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:baudex_desktop/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:baudex_desktop/features/customers/presentation/screens/customer_stats_screen.dart';
import 'package:baudex_desktop/features/customers/presentation/screens/modern_customers_list_screen.dart';
import 'package:baudex_desktop/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:baudex_desktop/features/inventory/domain/usecases/create_inventory_movement_usecase.dart';
import 'package:baudex_desktop/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:baudex_desktop/features/inventory/data/datasources/inventory_local_datasource_isar.dart';
import 'package:baudex_desktop/app/core/network/dio_client.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/invoices/presentation/bindings/invoice_binding.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_screen_wrapper.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_form_tabs_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_list_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_print_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_settings_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/screens/invoice_stats_screen.dart';
import 'package:baudex_desktop/features/settings/presentation/screens/printer_configuration_screen.dart';
import 'package:baudex_desktop/features/settings/presentation/screens/organization_settings_screen.dart';
import 'package:baudex_desktop/features/settings/presentation/screens/user_preferences_screen.dart';
import 'package:baudex_desktop/features/settings/presentation/bindings/settings_binding.dart';
import 'package:baudex_desktop/features/settings/presentation/bindings/user_preferences_binding.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/settings_controller.dart';
import 'package:baudex_desktop/features/settings/presentation/controllers/organization_controller.dart';
import 'package:baudex_desktop/features/products/domain/usecases/get_products_usecase.dart';
import 'package:baudex_desktop/features/products/domain/usecases/search_products_usecase.dart';
import 'package:baudex_desktop/features/products/presentation/bindings/product_binding.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/products_controller.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_detail_controller.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_form_controller.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_form_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_stats_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/products_list_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_detail_screen.dart';
import 'package:baudex_desktop/features/products/presentation/screens/initial_inventory_screen.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/initial_inventory_controller.dart';
import 'package:baudex_desktop/features/products/domain/usecases/create_product_usecase.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_presentations_screen.dart';
import 'package:baudex_desktop/features/products/presentation/bindings/product_presentation_binding.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_presentations_controller.dart';
import 'package:baudex_desktop/features/products/presentation/screens/product_waste_screen.dart';
import 'package:baudex_desktop/features/products/presentation/bindings/product_waste_binding.dart';
import 'package:baudex_desktop/features/products/presentation/controllers/product_waste_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/bindings/expense_binding.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/expense_form_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/expense_detail_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/expense_categories_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/controllers/enhanced_expenses_controller.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/expenses_list_screen.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/modern_expense_form_screen.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/expense_detail_screen.dart';
import 'package:baudex_desktop/features/expenses/presentation/screens/expense_categories_screen.dart';
import 'package:baudex_desktop/features/suppliers/presentation/bindings/suppliers_binding.dart';
import 'package:baudex_desktop/features/suppliers/presentation/screens/suppliers_list_screen.dart';
import 'package:baudex_desktop/features/suppliers/presentation/screens/supplier_detail_screen.dart';
import 'package:baudex_desktop/features/suppliers/presentation/screens/supplier_form_screen.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/bindings/purchase_orders_binding.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/bindings/purchase_order_form_binding.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/screens/purchase_orders_list_screen.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/screens/futuristic_purchase_order_detail_screen.dart';
import 'package:baudex_desktop/features/purchase_orders/presentation/screens/purchase_order_form_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/bindings/inventory_binding.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_dashboard_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_movements_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_adjustments_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_bulk_adjustments_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/kardex_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_balance_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_batches_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_transfers_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/create_transfer_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/bindings/create_transfer_binding.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/warehouses_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/warehouse_form_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/warehouse_detail_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_aging_report_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/screens/inventory_valuation_screen.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_movements_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_bulk_adjustments_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/kardex_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_balance_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_batches_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_transfers_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/warehouses_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/warehouse_form_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/warehouse_detail_controller.dart';
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_aging_controller.dart';
import 'package:baudex_desktop/features/reports/presentation/bindings/reports_binding.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/reports_dashboard_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/profitability_products_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/profitability_categories_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/top_profitable_products_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/valuation_summary_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/valuation_products_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/valuation_categories_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/kardex_multi_product_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/movements_summary_screen.dart';
import 'package:baudex_desktop/features/reports/presentation/screens/inventory_aging_screen.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/bindings/credit_note_binding.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_list_screen.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_detail_screen.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_form_screen.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/bindings/bank_accounts_binding.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/bindings/bank_account_movements_binding.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/screens/bank_accounts_screen.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/screens/bank_account_movements_screen.dart';
import 'package:baudex_desktop/features/customer_credits/presentation/bindings/customer_credit_binding.dart';
import 'package:baudex_desktop/features/customer_credits/presentation/pages/customer_credits_page.dart';
import 'package:baudex_desktop/features/customer_credits/presentation/pages/client_balances_page.dart';
import 'package:baudex_desktop/features/notifications/presentation/bindings/notification_binding.dart';
import 'package:baudex_desktop/features/notifications/presentation/screens/notifications_list_screen.dart';
import 'package:baudex_desktop/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:baudex_desktop/features/diagnostics/presentation/bindings/sync_diagnostic_binding.dart';
import 'package:baudex_desktop/features/diagnostics/presentation/screens/sync_diagnostic_screen.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/auth/presentation/screens/register_screen.dart';
import '../../../features/auth/presentation/screens/profile_screen.dart';
import '../../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../../features/auth/presentation/screens/forgot_password_screen.dart';
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
      name: AppRoutes.verifyEmail,
      page: () => const VerifyEmailScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      preventDuplicates: true,
    ),

    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== DASHBOARD ====================
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
      preventDuplicates: true,
    ),

    // ==================== CATEGORIES PAGES ====================
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesListScreen(),
      binding: CategoryBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== PRODUCT PRESENTATIONS ====================
    GetPage(
      name: '/products/:productId/presentations',
      page: () => const ProductPresentationsScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProductPresentationsController>()) {
          ProductPresentationBinding().dependencies();
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // ==================== PRODUCT WASTE ====================
    GetPage(
      name: '/products/:productId/waste',
      page: () => const ProductWasteScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProductWasteController>()) {
          ProductWasteBinding().dependencies();
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
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
      // middlewares: [AuthMiddleware()],
    ),

    // ✅ NUEVA RUTA PARA ESTADÍSTICAS DE PRODUCTOS
    GetPage(
      name: AppRoutes.productsStats,
      page: () => const ProductStatsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [ESTADÍSTICAS PRODUCTOS] Verificando ProductsController...');
        if (!Get.isRegistered<ProductsController>()) {
          print(
            '📦 [ESTADÍSTICAS PRODUCTOS] Registrando ProductBinding para ProductsController',
          );
          ProductBinding().dependencies();
          print(
            '✅ [ESTADÍSTICAS PRODUCTOS] ProductBinding registrado exitosamente',
          );
        } else {
          print('✅ [ESTADÍSTICAS PRODUCTOS] ProductsController ya registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),
    // ==================== INVENTARIO INICIAL ====================
    GetPage(
      name: AppRoutes.productsInitialInventory,
      page: () => const InitialInventoryScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [INVENTARIO INICIAL] Inicializando bindings...');

        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          print('📂 [INVENTARIO INICIAL] Registrando CategoryBinding...');
          CategoryBinding().dependencies();
          print('✅ [INVENTARIO INICIAL] CategoryBinding registrado');
        }

        if (!Get.isRegistered<CreateProductUseCase>()) {
          print('📦 [INVENTARIO INICIAL] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [INVENTARIO INICIAL] ProductBinding registrado');
        }

        // Registrar dependencias de inventario para crear movimientos (stock inicial)
        if (!Get.isRegistered<CreateInventoryMovementUseCase>()) {
          print('📦 [INVENTARIO INICIAL] Registrando dependencias de inventario...');
          if (!Get.isRegistered<InventoryRemoteDataSource>()) {
            Get.lazyPut<InventoryRemoteDataSource>(
              () => InventoryRemoteDataSourceImpl(dio: Get.find<DioClient>().dio),
              fenix: true,
            );
          }
          if (!Get.isRegistered<InventoryLocalDataSource>()) {
            Get.lazyPut<InventoryLocalDataSource>(
              () => InventoryLocalDataSourceIsar(Get.find<IsarDatabase>()),
              fenix: true,
            );
          }
          if (!Get.isRegistered<InventoryRepository>()) {
            Get.lazyPut<InventoryRepository>(
              () => InventoryRepositoryImpl(
                remoteDataSource: Get.find(),
                localDataSource: Get.find(),
                networkInfo: Get.find<NetworkInfo>(),
              ),
              fenix: true,
            );
          }
          Get.lazyPut<CreateInventoryMovementUseCase>(
            () => CreateInventoryMovementUseCase(Get.find()),
            fenix: true,
          );
          print('✅ [INVENTARIO INICIAL] CreateInventoryMovementUseCase registrado');
        }

        if (!Get.isRegistered<InitialInventoryController>()) {
          Get.lazyPut<InitialInventoryController>(
            () => InitialInventoryController(
              createProductUseCase: Get.find(),
              getCategoriesUseCase: Get.find(),
              createMovementUseCase: Get.find(),
            ),
          );
          print('✅ [INVENTARIO INICIAL] InitialInventoryController registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

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
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== CUSTOMERS PAGES ====================
    GetPage(
      name: AppRoutes.customers,
      page: () => const ModernCustomersListScreen(),
      binding: CustomerBinding(), // ✅ OK - Solo necesita CustomersController
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.customersEdit}/:id',
      page: () => const CustomerFormScreen(),
      binding: CustomerFormBinding(), // ← CAMBIADO: binding directo
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ✅ DETALLE CLIENTE - USAR CustomerDetailBinding
    GetPage(
      name: '${AppRoutes.customersDetail}/:id',
      page: () => const CustomerDetailScreen(),
      binding:
          CustomerDetailBinding(), // ← CAMBIADO: Usar CustomerDetailBinding directamente
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ✅ ESTADÍSTICAS CLIENTES - USAR CustomerStatsBinding
    GetPage(
      name: AppRoutes.customersStats,
      page: () => const CustomerStatsScreen(),
      binding:
          CustomerStatsBinding(), // ← CAMBIADO: Usar CustomerStatsBinding directamente
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== SUPPLIERS PAGES ====================
    GetPage(
      name: AppRoutes.suppliers,
      page: () => const SuppliersListScreen(),
      binding: SuppliersBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.suppliersCreate,
      page: () => const SupplierFormScreen(),
      binding: SupplierFormBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.suppliersEdit}/:id',
      page: () => const SupplierFormScreen(),
      binding: SupplierFormBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.suppliersDetail}/:id',
      page: () => const SupplierDetailScreen(),
      binding: SupplierDetailBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== PURCHASE ORDERS PAGES ====================
    GetPage(
      name: AppRoutes.purchaseOrders,
      page: () => const PurchaseOrdersListScreen(),
      binding: PurchaseOrdersBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.purchaseOrdersCreate,
      page: () => const PurchaseOrderFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR ORDEN] Inicializando binding con cleanup...');
        PurchaseOrderFormBinding().dependencies();
        print('✅ [CREAR ORDEN] PurchaseOrderFormBinding completado');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.purchaseOrdersEdit}/:id',
      page: () => const PurchaseOrderFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [EDITAR ORDEN] Inicializando binding con cleanup...');
        PurchaseOrderFormBinding().dependencies();
        print('✅ [EDITAR ORDEN] PurchaseOrderFormBinding completado');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.purchaseOrdersDetail}/:id',
      page: () => const FuturisticPurchaseOrderDetailScreen(),
      binding: PurchaseOrderDetailBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 500),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/purchase-orders/supplier/:supplierId',
      page: () => const PurchaseOrdersListScreen(),
      binding: PurchaseOrdersBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/purchase-orders/status/:status',
      page: () => const PurchaseOrdersListScreen(),
      binding: PurchaseOrdersBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== NOTIFICATIONS PAGES ====================

    // 🔔 LISTA DE NOTIFICACIONES
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsListScreen(),
      binding: NotificationBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 👁️ DETALLE DE NOTIFICACIÓN
    GetPage(
      name: '/notifications/:id',
      page: () => const NotificationDetailScreen(),
      binding: NotificationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== INVENTORY PAGES ====================

    // 📦 LISTA DE INVENTARIO (pantalla principal con tabs)
    GetPage(
      name: AppRoutes.inventory,
      page: () => const InventoryDashboardScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CENTRO INVENTARIO] Inicializando bindings...');

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [CENTRO INVENTARIO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [CENTRO INVENTARIO] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        // _safePut() dentro de InventoryBinding maneja re-registración segura
        print('📊 [CENTRO INVENTARIO] Registrando InventoryBinding...');
        InventoryBinding().dependencies();
        print('✅ [CENTRO INVENTARIO] InventoryBinding registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📋 MOVIMIENTOS DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryMovements,
      page: () => const InventoryMovementsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [MOVIMIENTOS INVENTARIO] Inicializando bindings...');

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [MOVIMIENTOS INVENTARIO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [MOVIMIENTOS INVENTARIO] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          print('📋 [MOVIMIENTOS INVENTARIO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [MOVIMIENTOS INVENTARIO] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ⚖️ AJUSTES DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryAdjustments,
      page: () => const InventoryAdjustmentsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [AJUSTES INVENTARIO] Inicializando bindings...');

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [AJUSTES INVENTARIO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [AJUSTES INVENTARIO] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryAdjustmentsController>()) {
          print('⚖️ [AJUSTES INVENTARIO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [AJUSTES INVENTARIO] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📊 BALANCES DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryBalances,
      page: () => const InventoryBalanceScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [BALANCES INVENTARIO] Inicializando bindings...');

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBalanceController>()) {
          print('📊 [BALANCES INVENTARIO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [BALANCES INVENTARIO] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📈 KARDEX DE PRODUCTO
    GetPage(
      name: '/inventory/product/:productId/kardex',
      page: () => const KardexScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [KARDEX] Inicializando bindings...');

        // Registrar binding completo de inventario
        if (!Get.isRegistered<KardexController>()) {
          print('📈 [KARDEX] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [KARDEX] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📦 LOTES DE PRODUCTO
    GetPage(
      name: '/inventory/product/:productId/batches',
      page: () => const InventoryBatchesScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [LOTES] Inicializando bindings...');
        print('🔧 [LOTES] Get.parameters: ${Get.parameters}');

        // Primero asegurar que las dependencias base estén registradas
        if (!Get.isRegistered<InventoryRepository>()) {
          print('📦 [LOTES] Registrando InventoryBinding base...');
          InventoryBinding().dependencies();
        }

        // Siempre eliminar y re-crear el controller para esta ruta
        // porque necesita el productId de los parámetros de ruta
        if (Get.isRegistered<InventoryBatchesController>()) {
          print('🔄 [LOTES] Eliminando controller anterior...');
          Get.delete<InventoryBatchesController>();
        }

        print('📦 [LOTES] Creando nuevo InventoryBatchesController...');
        Get.put<InventoryBatchesController>(
          InventoryBatchesController(getInventoryBatchesUseCase: Get.find()),
        );
        print('✅ [LOTES] InventoryBatchesController creado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ➕ CREAR MOVIMIENTO DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryMovementsCreate,
      page: () => const InventoryMovementsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR MOVIMIENTO] Inicializando bindings...');

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [CREAR MOVIMIENTO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [CREAR MOVIMIENTO] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          print('➕ [CREAR MOVIMIENTO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [CREAR MOVIMIENTO] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ➕ CREAR AJUSTE DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryAdjustmentsCreate,
      page: () => const InventoryAdjustmentsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR AJUSTE] Inicializando bindings...');

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [CREAR AJUSTE] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [CREAR AJUSTE] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryAdjustmentsController>()) {
          print('➕ [CREAR AJUSTE] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [CREAR AJUSTE] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📦 AJUSTES MASIVOS DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryBulkAdjustments,
      page: () => const InventoryBulkAdjustmentsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [AJUSTES MASIVOS] Inicializando bindings...');

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [AJUSTES MASIVOS] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [AJUSTES MASIVOS] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBulkAdjustmentsController>()) {
          print('📦 [AJUSTES MASIVOS] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [AJUSTES MASIVOS] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 🔄 TRANSFERENCIAS DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryTransfers,
      page: () => const InventoryTransfersScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [TRANSFERENCIAS] Inicializando bindings...');

        // Registrar ProductBinding primero (dependencia requerida)
        if (!Get.isRegistered<SearchProductsUseCase>()) {
          print('📦 [TRANSFERENCIAS] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [TRANSFERENCIAS] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryTransfersController>()) {
          print('🔄 [TRANSFERENCIAS] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [TRANSFERENCIAS] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ➕ CREAR TRANSFERENCIA DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryTransfersCreate,
      page: () => const CreateTransferScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR TRANSFERENCIA] Inicializando bindings...');

        // Registrar ProductBinding primero (dependencia requerida)
        if (!Get.isRegistered<SearchProductsUseCase>()) {
          print('📦 [CREAR TRANSFERENCIA] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [CREAR TRANSFERENCIA] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryTransfersController>()) {
          print('📦 [CREAR TRANSFERENCIA] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [CREAR TRANSFERENCIA] InventoryBinding registrado');
        }

        // Registrar binding específico para creación de transferencias
        CreateTransferBinding().dependencies();
        print('✅ [CREAR TRANSFERENCIA] CreateTransferBinding registrado');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ⏰ REPORTE DE ANTIGÜEDAD DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryAgingReport,
      page: () => const InventoryAgingReportScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [REPORTE ANTIGÜEDAD] Inicializando bindings...');

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryAgingController>()) {
          print('⏰ [REPORTE ANTIGÜEDAD] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [REPORTE ANTIGÜEDAD] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 🏪 ALMACENES
    GetPage(
      name: AppRoutes.warehouses,
      page: () => const WarehousesScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [ALMACENES] Inicializando bindings...');

        // Registrar binding completo de inventario
        if (!Get.isRegistered<WarehousesController>()) {
          print('🏪 [ALMACENES] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [ALMACENES] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ➕ CREAR ALMACÉN
    GetPage(
      name: AppRoutes.warehousesCreate,
      page: () => const WarehouseFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR ALMACÉN] Inicializando bindings...');

        if (!Get.isRegistered<WarehouseFormController>()) {
          print('➕ [CREAR ALMACÉN] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [CREAR ALMACÉN] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ✏️ EDITAR ALMACÉN
    GetPage(
      name: '${AppRoutes.warehousesEdit}/:id',
      page: () => const WarehouseFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [EDITAR ALMACÉN] Inicializando bindings...');

        if (!Get.isRegistered<WarehouseFormController>()) {
          print('✏️ [EDITAR ALMACÉN] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [EDITAR ALMACÉN] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 👁️ DETALLE DE ALMACÉN
    GetPage(
      name: '${AppRoutes.warehousesDetail}/:id',
      page: () => const WarehouseDetailScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [DETALLE ALMACÉN] Inicializando bindings...');

        if (!Get.isRegistered<WarehouseDetailController>()) {
          print('👁️ [DETALLE ALMACÉN] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [DETALLE ALMACÉN] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 💰 VALORACIÓN DE INVENTARIO
    GetPage(
      name: AppRoutes.inventoryValuation,
      page: () => const InventoryValuationScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [VALORACIÓN INVENTARIO] Inicializando bindings...');

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBalanceController>()) {
          print('💰 [VALORACIÓN INVENTARIO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [VALORACIÓN INVENTARIO] InventoryBinding registrado');
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📋 DETALLE DE PRODUCTO EN INVENTARIO
    GetPage(
      name: '/inventory/product/:productId',
      page: () => const InventoryBalanceScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [PRODUCTO INVENTARIO] Inicializando bindings...');

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBalanceController>()) {
          print('📋 [PRODUCTO INVENTARIO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [PRODUCTO INVENTARIO] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📋 DETALLE DE MOVIMIENTO
    GetPage(
      name: '/inventory/movement/:movementId',
      page: () => const InventoryMovementsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [DETALLE MOVIMIENTO] Inicializando bindings...');

        // Registrar dependencias base de productos
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [DETALLE MOVIMIENTO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [DETALLE MOVIMIENTO] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          print('📋 [DETALLE MOVIMIENTO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [DETALLE MOVIMIENTO] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ✏️ EDITAR MOVIMIENTO
    GetPage(
      name: '/inventory/movement/:movementId/edit',
      page: () => const InventoryMovementsScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [EDITAR MOVIMIENTO] Inicializando bindings...');

        // Registrar dependencias base de productos
        if (!Get.isRegistered<GetProductsUseCase>()) {
          print('📦 [EDITAR MOVIMIENTO] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [EDITAR MOVIMIENTO] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          print('✏️ [EDITAR MOVIMIENTO] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [EDITAR MOVIMIENTO] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 🔄 DETALLE DE TRANSFERENCIA
    GetPage(
      name: '/inventory/transfer/:transferId',
      page: () => const InventoryTransfersScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [DETALLE TRANSFERENCIA] Inicializando bindings...');

        // Registrar ProductBinding primero (dependencia requerida)
        if (!Get.isRegistered<SearchProductsUseCase>()) {
          print('📦 [DETALLE TRANSFERENCIA] Registrando ProductBinding...');
          ProductBinding().dependencies();
          print('✅ [DETALLE TRANSFERENCIA] ProductBinding registrado');
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryTransfersController>()) {
          print('🔄 [DETALLE TRANSFERENCIA] Registrando InventoryBinding...');
          InventoryBinding().dependencies();
          print('✅ [DETALLE TRANSFERENCIA] InventoryBinding registrado');
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
    ),

    // 📝 CREAR FACTURA
    GetPage(
      name: AppRoutes.invoicesCreate,
      page: () => const InvoiceFormScreenWrapper(),
      // ✅ SOLUCIÓN RADICAL: NO BINDING - Todo lazy
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ✏️ EDITAR FACTURA
    GetPage(
      name: '${AppRoutes.invoicesEdit}/:id',
      page: () => const InvoiceFormScreenWrapper(),
      // ✅ SOLUCIÓN RADICAL: NO BINDING - Todo lazy
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== EXPENSES PAGES ====================
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensesListScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [LISTA GASTOS] Inicializando bindings...');
        // Verificar si el controller ya existe (re-visita vs primera visita)
        final alreadyRegistered = Get.isRegistered<EnhancedExpensesController>();
        ExpenseBinding().dependencies();
        // Si ya existía (controller permanente), refrescar datos
        // En primera visita, onInit() se encarga de la carga inicial
        if (alreadyRegistered) {
          print('🔄 [LISTA GASTOS] Re-visita detectada, refrescando datos...');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.find<EnhancedExpensesController>().refreshExpenses();
          });
        }
        print('✅ [LISTA GASTOS] ExpenseBinding registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.expensesCreate,
      page: () => const ModernExpenseFormScreen(),
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
              updateExpenseCategoryUseCase: Get.find(),
              uploadAttachmentsUseCase: Get.find(),
              deleteAttachmentUseCase: Get.find(),
              fileService: Get.find(),
            ),
          );
        }
        print('✅ [CREAR GASTO] ExpenseFormController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.expensesEdit}/:id',
      page: () => const ModernExpenseFormScreen(),
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
              updateExpenseCategoryUseCase: Get.find(),
              uploadAttachmentsUseCase: Get.find(),
              deleteAttachmentUseCase: Get.find(),
              fileService: Get.find(),
            ),
          );
        }
        print('✅ [EDITAR GASTO] ExpenseFormController registrado');
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
    ),

    // ⚙️ CONFIGURACIÓN DE FACTURAS
    GetPage(
      name: AppRoutes.settingsInvoice,
      page: () => const InvoiceSettingsScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
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
      // middlewares: [AuthMiddleware()],
    ),

    // 👤 PREFERENCIAS DE USUARIO
    GetPage(
      name: AppRoutes.settingsUserPreferences,
      page: () => const UserPreferencesScreen(),
      binding: UserPreferencesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // DIAGNOSTICO DEL SISTEMA
    GetPage(
      name: AppRoutes.diagnostics,
      page: () => const SyncDiagnosticScreen(),
      binding: SyncDiagnosticBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
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
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== REPORTS PAGES ====================

    // 📊 CENTRO DE REPORTES
    GetPage(
      name: AppRoutes.reportsDashboard,
      page: () => const ReportsDashboardScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📈 RENTABILIDAD POR PRODUCTOS
    GetPage(
      name: AppRoutes.reportsProfitabilityProducts,
      page: () => const ProfitabilityProductsScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 💰 VALORACIÓN DE INVENTARIO
    GetPage(
      name: AppRoutes.reportsValuationSummary,
      page: () => const ValuationSummaryScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📊 RENTABILIDAD POR CATEGORÍAS
    GetPage(
      name: AppRoutes.reportsProfitabilityCategories,
      page: () => const ProfitabilityCategoriesScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 🏆 TOP PRODUCTOS RENTABLES
    GetPage(
      name: AppRoutes.reportsProfitabilityTop,
      page: () => const TopProfitableProductsScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📦 VALORACIÓN POR PRODUCTOS
    GetPage(
      name: AppRoutes.reportsValuationProducts,
      page: () => const ValuationProductsScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📂 VALORACIÓN POR CATEGORÍAS
    GetPage(
      name: AppRoutes.reportsValuationCategories,
      page: () => const ValuationCategoriesScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 🔄 KARDEX MULTI-PRODUCTO
    GetPage(
      name: AppRoutes.reportsKardexMultiProduct,
      page: () => const KardexMultiProductScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📋 RESUMEN DE MOVIMIENTOS
    GetPage(
      name: AppRoutes.reportsMovementsSummary,
      page: () => const MovementsSummaryScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ⏰ ANÁLISIS DE ANTIGÜEDAD
    GetPage(
      name: AppRoutes.reportsInventoryAging,
      page: () => const InventoryAgingScreen(),
      binding: ReportsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== CREDIT NOTES PAGES ====================

    // 📋 LISTA DE NOTAS DE CRÉDITO
    GetPage(
      name: AppRoutes.creditNotes,
      page: () => const CreditNoteListScreen(),
      binding: CreditNoteListBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ➕ CREAR NOTA DE CRÉDITO
    GetPage(
      name: AppRoutes.creditNotesCreate,
      page: () => const CreditNoteFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [CREAR NOTA CRÉDITO] Inicializando bindings...');

        // Asegurar dependencias de Invoice para GetInvoiceByIdUseCase
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [CREAR NOTA CRÉDITO] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [CREAR NOTA CRÉDITO] InvoiceBinding base registrado');
        }

        // Registrar CreditNoteFormBinding
        CreditNoteFormBinding().dependencies();
        print('✅ [CREAR NOTA CRÉDITO] CreditNoteFormBinding registrado');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ✏️ EDITAR NOTA DE CRÉDITO
    GetPage(
      name: '${AppRoutes.creditNotesEdit}/:id',
      page: () => const CreditNoteFormScreen(),
      binding: BindingsBuilder(() {
        print('🔧 [EDITAR NOTA CRÉDITO] Inicializando bindings...');

        // Asegurar dependencias de Invoice
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          print('📄 [EDITAR NOTA CRÉDITO] Registrando InvoiceBinding base...');
          InvoiceBinding().dependencies();
          print('✅ [EDITAR NOTA CRÉDITO] InvoiceBinding base registrado');
        }

        // Registrar CreditNoteFormBinding
        CreditNoteFormBinding().dependencies();
        print('✅ [EDITAR NOTA CRÉDITO] CreditNoteFormBinding registrado');
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 👁️ DETALLE DE NOTA DE CRÉDITO
    GetPage(
      name: '${AppRoutes.creditNotesDetail}/:id',
      page: () => const CreditNoteDetailScreen(),
      binding: CreditNoteDetailBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 📋 NOTAS DE CRÉDITO POR FACTURA
    GetPage(
      name: '/credit-notes/invoice/:invoiceId',
      page: () => const CreditNoteListScreen(),
      binding: CreditNoteListBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== BANK ACCOUNTS PAGES ====================

    // 🏦 CUENTAS BANCARIAS
    GetPage(
      name: AppRoutes.bankAccounts,
      page: () => const BankAccountsScreen(),
      binding: BankAccountsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 💳 MOVIMIENTOS DE CUENTA BANCARIA
    GetPage(
      name: '${AppRoutes.bankAccounts}/:id/movements',
      page: () => const BankAccountMovementsScreen(),
      binding: BankAccountMovementsBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== CUSTOMER CREDITS PAGES ====================

    // 💳 CRÉDITOS DE CLIENTES
    GetPage(
      name: AppRoutes.customerCredits,
      page: () => const CustomerCreditsPage(),
      binding: CustomerCreditBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 👁️ DETALLE DE CRÉDITO
    GetPage(
      name: '${AppRoutes.customerCreditsDetail}/:id',
      page: () => const CustomerCreditsPage(),
      binding: CustomerCreditBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 👤 CRÉDITOS POR CLIENTE
    GetPage(
      name: '/customer-credits/customer/:customerId',
      page: () => const CustomerCreditsPage(),
      binding: CustomerCreditBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== CLIENT BALANCES PAGES ====================

    // 💰 SALDOS A FAVOR
    GetPage(
      name: AppRoutes.clientBalances,
      page: () => const ClientBalancesPage(),
      binding: CustomerCreditBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
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
