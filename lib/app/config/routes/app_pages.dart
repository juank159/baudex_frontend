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
import 'package:baudex_desktop/features/employees/presentation/bindings/employee_binding.dart';
import 'package:baudex_desktop/features/employees/presentation/screens/employees_screen.dart';
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
import 'package:baudex_desktop/features/invoices/presentation/screens/product_exchange_screen.dart';
import 'package:baudex_desktop/features/invoices/presentation/bindings/product_exchange_binding.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/bindings/bank_accounts_binding.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/bindings/bank_account_movements_binding.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/screens/bank_accounts_screen.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/screens/bank_account_movements_screen.dart';
import 'package:baudex_desktop/features/bank_accounts/presentation/screens/bank_accounts_audit_screen.dart';
import 'package:baudex_desktop/features/cash_register/presentation/bindings/cash_register_binding.dart';
import 'package:baudex_desktop/features/cash_register/presentation/screens/cash_register_screen.dart';
import 'package:baudex_desktop/features/cash_register/presentation/screens/cash_register_history_screen.dart';
import 'package:baudex_desktop/app/core/navigation/cash_register_route_middleware.dart';
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

  // Registrar dependencias básicas de Invoice (SIN estadísticas automáticas)
  if (!InvoiceBinding.areBaseDependenciesRegistered()) {
    InvoiceBinding().dependenciesWithoutStats();
  }

  // Customer dependencies
  try {
    Get.find<GetCustomersUseCase>();
  } catch (e) {
    CustomerBinding().dependencies();
  }

  // Product dependencies
  try {
    Get.find<GetProductsUseCase>();
  } catch (e) {
    ProductBinding().dependencies();
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

        // CategoryBinding primero (para filtros de categoría)
        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          CategoryBinding().dependencies();
        }

        // ProductBinding después
        if (!Get.isRegistered<ProductsController>()) {
          ProductBinding().dependencies();
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

        // 1. PRIMERO: CategoryBinding (para GetCategoriesUseCase)
        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          CategoryBinding().dependencies();
        } else {
        }

        // 2. SEGUNDO: ProductBinding (ahora puede usar GetCategoriesUseCase)
        if (!Get.isRegistered<ProductFormController>()) {
          ProductBinding().dependencies();
        } else {
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

        // 1. PRIMERO: CategoryBinding
        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          CategoryBinding().dependencies();
        } else {
        }

        // 2. SEGUNDO: ProductBinding
        if (!Get.isRegistered<ProductFormController>()) {
          ProductBinding().dependencies();
        } else {
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
        if (!Get.isRegistered<ProductDetailController>()) {
          ProductBinding().dependencies();
        } else {
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
        if (!Get.isRegistered<ProductsController>()) {
          ProductBinding().dependencies();
        } else {
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
        if (!Get.isRegistered<ProductsController>()) {
          ProductBinding().dependencies();
        } else {
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

        if (!Get.isRegistered<GetCategoriesUseCase>()) {
          CategoryBinding().dependencies();
        }

        if (!Get.isRegistered<CreateProductUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar dependencias de inventario para crear movimientos (stock inicial)
        if (!Get.isRegistered<CreateInventoryMovementUseCase>()) {
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
        }

        if (!Get.isRegistered<InitialInventoryController>()) {
          Get.lazyPut<InitialInventoryController>(
            () => InitialInventoryController(
              createProductUseCase: Get.find(),
              getCategoriesUseCase: Get.find(),
              createMovementUseCase: Get.find(),
            ),
          );
        }
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: '/products/category/:categoryId',
      page: () => const ProductsListScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProductsController>()) {
          ProductBinding().dependencies();
        } else {
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // ==================== EMPLOYEES PAGES ====================
    GetPage(
      name: AppRoutes.employees,
      page: () => const EmployeesScreen(),
      binding: EmployeeBinding(),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
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
        PurchaseOrderFormBinding().dependencies();
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.purchaseOrdersEdit}/:id',
      page: () => const PurchaseOrderFormScreen(),
      binding: BindingsBuilder(() {
        PurchaseOrderFormBinding().dependencies();
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

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        // _safePut() dentro de InventoryBinding maneja re-registración segura
        InventoryBinding().dependencies();
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

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          InventoryBinding().dependencies();
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

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryAdjustmentsController>()) {
          InventoryBinding().dependencies();
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

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBalanceController>()) {
          InventoryBinding().dependencies();
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

        // Registrar binding completo de inventario
        if (!Get.isRegistered<KardexController>()) {
          InventoryBinding().dependencies();
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

        // Primero asegurar que las dependencias base estén registradas
        if (!Get.isRegistered<InventoryRepository>()) {
          InventoryBinding().dependencies();
        }

        // Siempre eliminar y re-crear el controller para esta ruta
        // porque necesita el productId de los parámetros de ruta
        if (Get.isRegistered<InventoryBatchesController>()) {
          Get.delete<InventoryBatchesController>();
        }

        Get.put<InventoryBatchesController>(
          InventoryBatchesController(getInventoryBatchesUseCase: Get.find()),
        );
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

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          InventoryBinding().dependencies();
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

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryAdjustmentsController>()) {
          InventoryBinding().dependencies();
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

        // Registrar dependencias base de productos (para búsqueda)
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBulkAdjustmentsController>()) {
          InventoryBinding().dependencies();
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

        // Registrar ProductBinding primero (dependencia requerida)
        if (!Get.isRegistered<SearchProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryTransfersController>()) {
          InventoryBinding().dependencies();
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

        // Registrar ProductBinding primero (dependencia requerida)
        if (!Get.isRegistered<SearchProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryTransfersController>()) {
          InventoryBinding().dependencies();
        }

        // Registrar binding específico para creación de transferencias
        CreateTransferBinding().dependencies();
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

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryAgingController>()) {
          InventoryBinding().dependencies();
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

        // Registrar binding completo de inventario
        if (!Get.isRegistered<WarehousesController>()) {
          InventoryBinding().dependencies();
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

        if (!Get.isRegistered<WarehouseFormController>()) {
          InventoryBinding().dependencies();
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

        if (!Get.isRegistered<WarehouseFormController>()) {
          InventoryBinding().dependencies();
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

        if (!Get.isRegistered<WarehouseDetailController>()) {
          InventoryBinding().dependencies();
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

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBalanceController>()) {
          InventoryBinding().dependencies();
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

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryBalanceController>()) {
          InventoryBinding().dependencies();
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

        // Registrar dependencias base de productos
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          InventoryBinding().dependencies();
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

        // Registrar dependencias base de productos
        if (!Get.isRegistered<GetProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryMovementsController>()) {
          InventoryBinding().dependencies();
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

        // Registrar ProductBinding primero (dependencia requerida)
        if (!Get.isRegistered<SearchProductsUseCase>()) {
          ProductBinding().dependencies();
        }

        // Registrar binding completo de inventario
        if (!Get.isRegistered<InventoryTransfersController>()) {
          InventoryBinding().dependencies();
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

        // 1. Registrar dependencias base del InvoiceBinding
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        // 2. Registrar controlador específico de lista
        InvoiceBinding.registerListController();
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

        // 1. Verificar y registrar dependencias base
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        // 2. Registrar controlador específico de detalle
        InvoiceBinding.registerDetailController();
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

          // Siempre registrar dependencias base si no están
          if (!InvoiceBinding.areBaseDependenciesRegistered()) {
            InvoiceBinding().dependencies();
          }

          // Verificar que el stats controller esté disponible
          if (!InvoiceBinding.isStatsControllerRegistered()) {
            InvoiceBinding().dependencies();
          }

        } catch (e) {
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

        // Solo necesita el controlador de detalle para obtener los datos
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        // Registrar controlador de detalle para obtener la factura
        InvoiceBinding.registerDetailController();
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

        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        InvoiceBinding.registerListController();
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

        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        InvoiceBinding.registerListController();
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

        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        InvoiceBinding.registerListController();
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
        // Verificar si el controller ya existe (re-visita vs primera visita)
        final alreadyRegistered = Get.isRegistered<EnhancedExpensesController>();
        ExpenseBinding().dependencies();
        // Si ya existía (controller permanente), refrescar datos
        // En primera visita, onInit() se encarga de la carga inicial
        if (alreadyRegistered) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.find<EnhancedExpensesController>().refreshExpenses();
          });
        }
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.expensesCreate,
      page: () => const ModernExpenseFormScreen(),
      binding: BindingsBuilder(() {
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
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.expensesEdit}/:id',
      page: () => const ModernExpenseFormScreen(),
      binding: BindingsBuilder(() {
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
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '${AppRoutes.expensesDetail}/:id',
      page: () => const ExpenseDetailScreen(),
      binding: BindingsBuilder(() {
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
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/expenses/category/:categoryId',
      page: () => const ExpensesListScreen(),
      binding: BindingsBuilder(() {
        ExpenseBinding().dependencies();
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: '/expenses/status/:status',
      page: () => const ExpensesListScreen(),
      binding: BindingsBuilder(() {
        ExpenseBinding().dependencies();
      }),
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: AppRoutes.expensesCategories,
      page: () => const ExpenseCategoriesScreen(),
      binding: BindingsBuilder(() {
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

        if (!Get.isRegistered<SettingsController>()) {
          SettingsBinding().dependencies();
        }

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

        if (!Get.isRegistered<SettingsController>() ||
            !Get.isRegistered<OrganizationController>()) {
          SettingsBinding().dependencies();
        }

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

        // Asegurar dependencias de Invoice para GetInvoiceByIdUseCase
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        // Registrar CreditNoteFormBinding
        CreditNoteFormBinding().dependencies();
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

        // Asegurar dependencias de Invoice
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }

        // Registrar CreditNoteFormBinding
        CreditNoteFormBinding().dependencies();
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // middlewares: [AuthMiddleware()],
    ),

    // 🔄 CAMBIO DE PRODUCTO (Product Exchange)
    GetPage(
      name: AppRoutes.productExchange,
      page: () => const ProductExchangeScreen(),
      binding: BindingsBuilder(() {
        // Asegurar dependencias core de Invoice
        if (!InvoiceBinding.areBaseDependenciesRegistered()) {
          InvoiceBinding().dependencies();
        }
        // Asegurar dependencias de CreditNote
        CreditNoteFormBinding().dependencies();
        // Registrar binding del exchange
        ProductExchangeBinding().dependencies();
      }),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
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

    // 🔍 AUDITORÍA DE SALDOS BANCARIOS (Phase 0.4)
    GetPage(
      name: AppRoutes.bankAccountsAudit,
      page: () => const BankAccountsAuditScreen(),
      // Reusa el mismo binding que ya provee BankAccountRemoteDataSource.
      binding: BankAccountsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 🧾 CAJA REGISTRADORA
    // Middleware bloquea acceso si el tenant tiene el módulo desactivado
    // (deep link, bookmark, botón residual). Redirige a /dashboard.
    GetPage(
      name: AppRoutes.cashRegister,
      page: () => const CashRegisterScreen(),
      binding: CashRegisterBinding(),
      middlewares: [CashRegisterRouteMiddleware()],
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // 🧾 HISTORIAL DE CAJAS
    GetPage(
      name: AppRoutes.cashRegisterHistory,
      page: () => const CashRegisterHistoryScreen(),
      binding: CashRegisterBinding(),
      middlewares: [CashRegisterRouteMiddleware()],
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
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
        return const RouteSettings(name: AppRoutes.login);
      }

      return null; // Permitir acceso
    } catch (e) {
      return const RouteSettings(name: AppRoutes.login);
    }
  }
}
