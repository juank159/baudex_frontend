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

  // ==================== SETTINGS ROUTES ====================
  static const String settings = '/settings';
  static const String settingsPrinter = '/settings/printer';
  static const String settingsInvoices = '/settings/invoices';
  static const String invoicesWithTabs = '/invoices/tabs';

  // Error Routes
  static const String notFound = '/404';
  static const String noInternet = '/no-internet';

  // ✅ Initial Route vuelve a splash
  static const String initial = splash;
}
