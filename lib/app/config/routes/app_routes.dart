// abstract class AppRoutes {
//   // Auth Routes
//   static const String splash = '/splash';
//   static const String login = '/login';
//   static const String register = '/register';
//   static const String forgotPassword = '/forgot-password';

//   // Main Routes
//   static const String home = '/home';
//   static const String profile = '/profile';
//   static const String dashboard = '/dashboard';

//   // ==================== CATEGORIES ROUTES ====================
//   static const String categories = '/categories';
//   static const String categoriesCreate = '/categories/create';
//   static const String categoriesEdit = '/categories/edit';
//   static const String categoriesDetail = '/categories/detail';
//   static const String categoriesTree = '/categories/tree';

//   // Categories with parameters
//   static String categoryEdit(String id) => '/categories/edit/$id';
//   static String categoryDetail(String id) => '/categories/detail/$id';

//   // ==================== PRODUCTS ROUTES ====================
//   static const String products = '/products';
//   static const String productsCreate = '/products/create';
//   static const String productsEdit = '/products/edit';
//   static const String productsDetail = '/products/detail';
//   static const String productsLowStock = '/products/low-stock';
//   static const String productsStats = '/products/stats';

//   // Products with parameters
//   static String productEdit(String id) => '/products/edit/$id';
//   static String productDetail(String id) => '/products/detail/$id';
//   static String productsByCategory(String categoryId) =>
//       '/products/category/$categoryId';

//   // Error Routes
//   static const String notFound = '/404';
//   static const String noInternet = '/no-internet';

//   // Initial Route
//   static const String initial = splash;
// }

abstract class AppRoutes {
  // Auth Routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String dashboard = '/dashboard';

  // ==================== CATEGORIES ROUTES ====================
  static const String categories = '/categories';
  static const String categoriesCreate = '/categories/create';
  static const String categoriesEdit = '/categories/edit';
  static const String categoriesDetail = '/categories/detail';
  static const String categoriesTree = '/categories/tree';

  // Categories with parameters
  static String categoryEdit(String id) => '/categories/edit/$id';
  static String categoryDetail(String id) => '/categories/detail/$id';

  // ==================== PRODUCTS ROUTES ====================
  static const String products = '/products';
  static const String productsCreate = '/products/create';
  static const String productsEdit = '/products/edit';
  static const String productsDetail = '/products/detail';
  static const String productsLowStock = '/products/low-stock';
  static const String productsStats = '/products/stats';

  // Products with parameters
  static String productEdit(String id) => '/products/edit/$id';
  static String productDetail(String id) => '/products/detail/$id';
  static String productsByCategory(String categoryId) =>
      '/products/category/$categoryId';

  // ==================== CUSTOMERS ROUTES ====================
  static const String customers = '/customers';
  static const String customersCreate = '/customers/create';
  static const String customersEdit = '/customers/edit';
  static const String customersDetail = '/customers/detail';
  static const String customersStats = '/customers/stats';

  // Customers with parameters
  static String customerEdit(String id) => '/customers/edit/$id';
  static String customerDetail(String id) => '/customers/detail/$id';

  // ==================== INVOICES ROUTES ====================
  static const String invoices = '/invoices';
  static const String invoicesWithTabs = '/invoices/tabs';
  static const String invoicesCreate = '/invoices/create';
  static const String invoicesEdit = '/invoices/edit';
  static const String invoicesDetail = '/invoices/detail';
  static const String invoicesStats = '/invoices/stats';
  static const String invoicesPrint = '/invoices/print';
  static const String invoicesOverdue = '/invoices/overdue';

  // Invoices with parameters
  static String invoiceEdit(String id) => '/invoices/edit/$id';
  static String invoiceDetail(String id) => '/invoices/detail/$id';
  static String invoicePrint(String id) => '/invoices/print/$id';
  static String invoicesByCustomer(String customerId) =>
      '/invoices/customer/$customerId';
  static String invoicesByStatus(String status) => '/invoices/status/$status';

  // ==================== SUPPLIERS ROUTES ====================
  static const String suppliers = '/suppliers';
  static const String suppliersCreate = '/suppliers/create';
  static const String suppliersEdit = '/suppliers/edit';
  static const String suppliersDetail = '/suppliers/detail';
  static const String suppliersStats = '/suppliers/stats';

  // Suppliers with parameters
  static String supplierEdit(String id) => '/suppliers/edit/$id';
  static String supplierDetail(String id) => '/suppliers/detail/$id';

  // ==================== PURCHASE ORDERS ROUTES ====================
  static const String purchaseOrders = '/purchase-orders';
  static const String purchaseOrdersCreate = '/purchase-orders/create';
  static const String purchaseOrdersEdit = '/purchase-orders/edit';
  static const String purchaseOrdersDetail = '/purchase-orders/detail';
  static const String purchaseOrdersStats = '/purchase-orders/stats';

  // Purchase Orders with parameters
  static String purchaseOrderEdit(String id) => '/purchase-orders/edit/$id';
  static String purchaseOrderDetail(String id) => '/purchase-orders/detail/$id';
  static String purchaseOrdersBySupplier(String supplierId) =>
      '/purchase-orders/supplier/$supplierId';
  static String purchaseOrdersByStatus(String status) => '/purchase-orders/status/$status';

  // ==================== EXPENSES ROUTES ====================
  static const String expenses = '/expenses';
  static const String expensesCreate = '/expenses/create';
  static const String expensesEdit = '/expenses/edit';
  static const String expensesDetail = '/expenses/detail';
  static const String expensesStats = '/expenses/stats';
  static const String expensesCategories = '/expenses/categories';

  // Expenses with parameters
  static String expenseEdit(String id) => '/expenses/edit/$id';
  static String expenseDetail(String id) => '/expenses/detail/$id';
  static String expensesByCategory(String categoryId) =>
      '/expenses/category/$categoryId';
  static String expensesByStatus(String status) => '/expenses/status/$status';

  // ==================== INVENTORY ROUTES ====================
  static const String inventory = '/inventory';
  static const String inventoryMovements = '/inventory/movements';
  static const String inventoryBalances = '/inventory/balances';
  static const String inventoryStats = '/inventory/stats';
  static const String inventoryMovementsCreate = '/inventory/movements/create';
  static const String inventoryAdjustments = '/inventory/adjustments';
  static const String inventoryAdjustmentsCreate = '/inventory/adjustments/create';
  static const String inventoryBulkAdjustments = '/inventory/bulk-adjustments';
  static const String inventoryTransfers = '/inventory/transfers';
  static const String inventoryTransfersCreate = '/inventory/transfers/create';
  static const String inventoryBatches = '/inventory/batches';
  static const String inventorySummary = '/inventory/summary';
  static const String inventoryAgingReport = '/inventory/aging-report';
  static const String inventoryValuation = '/inventory/valuation';
  static const String inventoryReports = '/inventory/reports';

  // ==================== WAREHOUSES ROUTES ====================
  static const String warehouses = '/warehouses';
  static const String warehousesCreate = '/warehouses/create';
  static const String warehousesEdit = '/warehouses/edit';
  static const String warehousesDetail = '/warehouses/detail';
  static const String warehousesStats = '/warehouses/stats';

  // Inventory with parameters
  static String inventoryProductDetail(String productId) => '/inventory/product/$productId';
  static String inventoryMovementDetail(String movementId) => '/inventory/movement/$movementId';
  static String inventoryMovementEdit(String movementId) => '/inventory/movement/$movementId/edit';
  static String inventoryBalanceByProduct(String productId) => '/inventory/balance/product/$productId';
  static String inventoryProductKardex(String productId) => '/inventory/product/$productId/kardex';
  static String inventoryProductBatches(String productId) => '/inventory/product/$productId/batches';
  static String inventoryTransferDetail(String transferId) => '/inventory/transfer/$transferId';

  // Warehouses with parameters
  static String warehouseEdit(String id) => '/warehouses/edit/$id';
  static String warehouseDetail(String id) => '/warehouses/detail/$id';

  // ==================== REPORTS ROUTES ====================
  static const String reports = '/reports';
  static const String reportsDashboard = '/reports/dashboard';
  static const String reportsProfitabilityProducts = '/reports/profitability/products';
  static const String reportsProfitabilityCategories = '/reports/profitability/categories';
  static const String reportsProfitabilityTop = '/reports/profitability/top';
  static const String reportsValuationSummary = '/reports/valuation/summary';
  static const String reportsValuationProducts = '/reports/valuation/products';
  static const String reportsValuationCategories = '/reports/valuation/categories';
  static const String reportsKardexMultiProduct = '/reports/kardex/multi-product';
  static const String reportsMovementsSummary = '/reports/movements/summary';
  static const String reportsInventoryAging = '/reports/inventory/aging';

  // ==================== SETTINGS ROUTES ====================
  static const String settings = '/settings';
  static const String settingsApp = '/settings/app';
  static const String settingsInvoice = '/settings/invoice';
  static const String settingsPrinter = '/settings/printer';
  static const String settingsDatabase = '/settings/database';
  static const String settingsOrganization = '/settings/organization';
  static const String settingsUser = '/settings/user';
  static const String settingsUserPreferences = '/settings/user-preferences';
  static const String settingsBackup = '/settings/backup';
  static const String settingsSecurity = '/settings/security';
  static const String settingsNotifications = '/settings/notifications';

  // Error Routes
  static const String notFound = '/404';
  static const String noInternet = '/no-internet';

  // ✅ Initial Route vuelve a splash
  static const String initial = splash;
}
