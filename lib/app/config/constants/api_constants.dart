// // lib/app/config/constants/api_constants.dart
// import 'dart:io';
// import 'package:flutter/foundation.dart';

// class ApiConstants {
//   // ==================== CONFIGURACIÓN DINÁMICA ====================

//   // Base URL - Detecta automáticamente según la plataforma
//   static String get baseUrl {
//     if (kDebugMode) {
//       // En desarrollo, detectar plataforma automáticamente
//       if (kIsWeb) {
//         return 'http://localhost:3000/api';
//       } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
//         // Desktop: usar localhost
//         return 'http://localhost:3000/api';
//       } else if (Platform.isAndroid) {
//         // Android: usar IP especial del emulador o IP de red según el caso
//         return _getAndroidUrl();
//       } else if (Platform.isIOS) {
//         // iOS: usar IP de la red local
//         return 'http://192.168.152.239/api';
//       }
//     }
//     // En producción, usar URL de producción
//     return 'https://tu-servidor-produccion.com/api';
//   }

//   static String _getAndroidUrl() {
//     // Intentar detectar si es emulador vs dispositivo físico
//     // En emulador usar 10.0.2.2, en dispositivo físico usar IP de red
//     try {
//       // Heurística simple: si hay variables de entorno del emulador
//       if (Platform.environment.containsKey('ANDROID_EMULATOR') ||
//           Platform.environment['ANDROID_DEVICE']?.contains('emulator') ==
//               true) {
//         print('🤖 Detectado emulador Android - usando 10.0.2.2:3000');
//         return 'http://10.0.2.2:3000/api';
//       } else {
//         print(
//           '📱 Detectado dispositivo Android físico - usando 192.168.0.14:3000',
//         );
//         return 'http://192.168.152.239/api';
//       }
//     } catch (e) {
//       // Si no puede detectar, usar IP del emulador por defecto
//       print(
//         '❓ No se pudo detectar tipo de Android - usando 10.0.2.2:3000 por defecto',
//       );
//       return 'http://10.0.2.2:3000/api';
//     }
//   }

//   // Método para debug - ver qué URL se está usando
//   static void printCurrentConfig() {
//     print('🌐 Configuración API:');
//     print('   Plataforma: ${Platform.operatingSystem}');
//     print('   Debug Mode: $kDebugMode');
//     print('   Base URL: $baseUrl');
//     print('   Timeouts: ${connectTimeout}ms');
//   }

//   // Timeouts
//   static const int connectTimeout = 30000; // 30 segundos
//   static const int receiveTimeout = 30000; // 30 segundos
//   static const int sendTimeout = 30000; // 30 segundos

//   // ==================== AUTH ENDPOINTS ====================

//   // Auth Endpoints
//   static const String authBase = '/auth';
//   static const String login = '$authBase/login';
//   static const String register = '$authBase/register';
//   static const String profile = '$authBase/profile';
//   static const String refreshToken = '$authBase/refresh';

//   // User Endpoints
//   static const String usersBase = '/users';
//   static const String userProfile = '$usersBase/me';
//   static const String changePassword = '$usersBase/me/password';
//   static const String updateAvatar = '$usersBase/me/avatar';

//   // ==================== CATEGORIES ENDPOINTS ====================

//   // Base endpoints
//   static const String categoriesBase = '/categories';
//   static const String categoriesAdminBase = '/admin/categories';

//   // Public endpoints
//   static const String categories = categoriesBase;
//   static const String categoriesTree = '$categoriesBase/tree';
//   static const String categoriesStats = '$categoriesBase/stats';
//   static const String categoriesSearch = '$categoriesBase/search';
//   static const String categoriesReorder = '$categoriesBase/reorder';

//   // Individual category endpoints
//   static String categoryById(String id) => '$categoriesBase/$id';
//   static String categoryBySlug(String slug) => '$categoriesBase/slug/$slug';
//   static String categoryChildren(String id) => '$categoriesBase/$id/children';
//   static String categoryProducts(String id) => '$categoriesBase/$id/products';

//   // Category management endpoints
//   static String updateCategoryStatus(String id) => '$categoriesBase/$id/status';
//   static String deleteCategory(String id) => '$categoriesBase/$id';
//   static String restoreCategory(String id) => '$categoriesBase/$id/restore';

//   // Validation endpoints
//   static String checkSlugAvailability(String slug) =>
//       '$categoriesBase/slug/$slug/available';
//   static const String validateHierarchy = '$categoriesBase/validate-hierarchy';

//   // Admin endpoints
//   static const String categoriesAdmin = categoriesAdminBase;
//   static const String generateSlug = '$categoriesAdminBase/generate-slug';
//   static String validateSlugAdmin(String slug) =>
//       '$categoriesAdminBase/validate-slug/$slug';
//   static const String categoriesWithDeleted =
//       '$categoriesAdminBase/with-deleted';
//   static const String categoriesDeleted = '$categoriesAdminBase/deleted';
//   static const String categoriesDetailedStats =
//       '$categoriesAdminBase/detailed-stats';
//   static const String categoriesHealthCheck =
//       '$categoriesAdminBase/health-check';
//   static const String categoriesBulkUpdateStatus =
//       '$categoriesAdminBase/bulk-update-status';
//   static const String categoriesBulkRestore =
//       '$categoriesAdminBase/bulk-restore';
//   static const String categoriesExport = '$categoriesAdminBase/export';
//   static const String categoriesImport = '$categoriesAdminBase/import';

//   // Maintenance endpoints
//   static const String rebuildTree = '$categoriesAdminBase/rebuild-tree';
//   static const String fixSortOrder = '$categoriesAdminBase/fix-sort-order';
//   static const String removeOrphans = '$categoriesAdminBase/remove-orphans';

//   // Force delete (admin only)
//   static String forceCategoryDelete(String id) =>
//       '$categoriesAdminBase/$id/force-delete';

//   // Audit endpoints
//   static String categoryAuditLog(String id) =>
//       '$categoriesAdminBase/$id/audit-log';

//   // ==================== HEADERS & STORAGE ====================

//   // Headers
//   static const String contentType = 'application/json';
//   static const String accept = 'application/json';
//   static const String authorization = 'Authorization';
//   static const String bearerPrefix = 'Bearer ';

//   // Storage Keys
//   static const String tokenKey = 'auth_token';
//   static const String userKey = 'user_data';
//   static const String refreshTokenKey = 'refresh_token';

//   // Categories Cache Keys
//   static const String categoriesCacheKey = 'categories_cache';
//   static const String categoryTreeCacheKey = 'category_tree_cache';
//   static const String categoryStatsCacheKey = 'category_stats_cache';

//   // ==================== PRODUCTS ENDPOINTS ====================

//   // Base endpoints
//   static const String productsBase = '/products';

//   // Public endpoints
//   static const String products = productsBase;
//   static const String productsSearch = '$productsBase/search';
//   static const String productsStats = '$productsBase/stats';
//   static const String productsLowStock = '$productsBase/low-stock';
//   static const String productsOutOfStock = '$productsBase/out-of-stock';
//   static const String productsInventoryValue = '$productsBase/inventory/value';

//   // Individual product endpoints
//   static String productById(String id) => '$productsBase/$id';
//   static String productBySku(String sku) => '$productsBase/sku/$sku';
//   static String productByBarcode(String barcode) =>
//       '$productsBase/barcode/$barcode';
//   static String productBySkuOrBarcode(String code) =>
//       '$productsBase/search/code/$code';
//   static String productsByCategory(String categoryId) =>
//       '$productsBase/category/$categoryId';

//   // Product management endpoints
//   static String updateProductStatus(String id) => '$productsBase/$id/status';
//   static String updateProductStock(String id) => '$productsBase/$id/stock';
//   static String deleteProduct(String id) => '$productsBase/$id';
//   static String restoreProduct(String id) => '$productsBase/$id/restore';

//   // Stock operations
//   static String validateStockForSale(String id) =>
//       '$productsBase/$id/validate-stock';
//   static String reduceStockForSale(String id) =>
//       '$productsBase/$id/reduce-stock';
// }

// lib/app/config/constants/api_constants.dart
import 'package:baudex_desktop/app/config/env/env_config.dart';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // ==================== CONFIGURACIÓN DINÁMICA ====================

  /// URL base del API - Leída desde variables de entorno
  static String get baseUrl {
    // Asegurarse de que la configuración esté inicializada
    if (!EnvConfig.isInitialized) {
      print('⚠️ EnvConfig no inicializado, usando configuración por defecto');
      return 'http://localhost:3000/api';
    }
    return EnvConfig.baseUrl;
  }

  /// URL del servidor sin /api
  static String get serverUrl => EnvConfig.serverUrl;

  /// IP del servidor
  static String get serverIP => EnvConfig.serverIP;

  /// Puerto del servidor
  static int get serverPort => EnvConfig.serverPort;

  /// Método para debug - mostrar configuración actual
  static void printCurrentConfig() {
    if (!EnvConfig.showLogs) return;

    print('');
    print('🌐 ============================================');
    print('📡 CONFIGURACIÓN API CONSTANTS');
    print('🌐 ============================================');
    print('🔗 URLs:');
    print('   • Base URL: $baseUrl');
    print('   • Server URL: $serverUrl');
    print('   • Server IP: $serverIP');
    print('   • Server Port: $serverPort');
    print('');
    print('⏱️  Timeouts:');
    print('   • Connect: ${connectTimeout}ms');
    print('   • Receive: ${receiveTimeout}ms');
    print('   • Send: ${sendTimeout}ms');
    print('🌐 ============================================');
    print('');
  }

  /// Actualizar IP del servidor en tiempo de ejecución
  static void updateServerIP(String newIP) {
    EnvConfig.updateServerIP(newIP);
    printCurrentConfig();
  }

  // ==================== TIMEOUTS ====================

  static int get connectTimeout => EnvConfig.apiTimeout;
  static int get receiveTimeout => EnvConfig.apiTimeout;
  static int get sendTimeout => EnvConfig.apiTimeout;

  // ==================== AUTH ENDPOINTS ====================

  static const String authBase = '/auth';
  static const String login = '$authBase/login';
  static const String register = '$authBase/register';
  static const String profile = '$authBase/profile';
  static const String refreshToken = '$authBase/refresh';

  // User Endpoints
  static const String usersBase = '/users';
  static const String userProfile = '$usersBase/me';
  static const String changePassword = '$usersBase/me/password';
  static const String updateAvatar = '$usersBase/me/avatar';

  // ==================== CATEGORIES ENDPOINTS ====================

  static const String categoriesBase = '/categories';
  static const String categoriesAdminBase = '/admin/categories';

  // Public endpoints
  static const String categories = categoriesBase;
  static const String categoriesTree = '$categoriesBase/tree';
  static const String categoriesStats = '$categoriesBase/stats';
  static const String categoriesSearch = '$categoriesBase/search';
  static const String categoriesReorder = '$categoriesBase/reorder';

  // Individual category endpoints
  static String categoryById(String id) => '$categoriesBase/$id';
  static String categoryBySlug(String slug) => '$categoriesBase/slug/$slug';
  static String categoryChildren(String id) => '$categoriesBase/$id/children';
  static String categoryProducts(String id) => '$categoriesBase/$id/products';

  // Category management endpoints
  static String updateCategoryStatus(String id) => '$categoriesBase/$id/status';
  static String deleteCategory(String id) => '$categoriesBase/$id';
  static String restoreCategory(String id) => '$categoriesBase/$id/restore';

  // Validation endpoints
  static String checkSlugAvailability(String slug) =>
      '$categoriesBase/slug/$slug/available';
  static const String validateHierarchy = '$categoriesBase/validate-hierarchy';

  // Admin endpoints
  static const String categoriesAdmin = categoriesAdminBase;
  static const String generateSlug = '$categoriesAdminBase/generate-slug';
  static String validateSlugAdmin(String slug) =>
      '$categoriesAdminBase/validate-slug/$slug';
  static const String categoriesWithDeleted =
      '$categoriesAdminBase/with-deleted';
  static const String categoriesDeleted = '$categoriesAdminBase/deleted';
  static const String categoriesDetailedStats =
      '$categoriesAdminBase/detailed-stats';
  static const String categoriesHealthCheck =
      '$categoriesAdminBase/health-check';
  static const String categoriesBulkUpdateStatus =
      '$categoriesAdminBase/bulk-update-status';
  static const String categoriesBulkRestore =
      '$categoriesAdminBase/bulk-restore';
  static const String categoriesExport = '$categoriesAdminBase/export';
  static const String categoriesImport = '$categoriesAdminBase/import';

  // Maintenance endpoints
  static const String rebuildTree = '$categoriesAdminBase/rebuild-tree';
  static const String fixSortOrder = '$categoriesAdminBase/fix-sort-order';
  static const String removeOrphans = '$categoriesAdminBase/remove-orphans';

  // Force delete (admin only)
  static String forceCategoryDelete(String id) =>
      '$categoriesAdminBase/$id/force-delete';

  // Audit endpoints
  static String categoryAuditLog(String id) =>
      '$categoriesAdminBase/$id/audit-log';

  // ==================== HEADERS & STORAGE ====================

  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearerPrefix = 'Bearer ';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';

  // Categories Cache Keys
  static const String categoriesCacheKey = 'categories_cache';
  static const String categoryTreeCacheKey = 'category_tree_cache';
  static const String categoryStatsCacheKey = 'category_stats_cache';

  // ==================== PRODUCTS ENDPOINTS ====================

  static const String productsBase = '/products';

  // Public endpoints
  static const String products = productsBase;
  static const String productsSearch = '$productsBase/search';
  static const String productsStats = '$productsBase/stats';
  static const String productsLowStock = '$productsBase/low-stock';
  static const String productsOutOfStock = '$productsBase/out-of-stock';
  static const String productsInventoryValue = '$productsBase/inventory/value';

  // Individual product endpoints
  static String productById(String id) => '$productsBase/$id';
  static String productBySku(String sku) => '$productsBase/sku/$sku';
  static String productByBarcode(String barcode) =>
      '$productsBase/barcode/$barcode';
  static String productBySkuOrBarcode(String code) =>
      '$productsBase/search/code/$code';
  static String productsByCategory(String categoryId) =>
      '$productsBase/category/$categoryId';

  // Product management endpoints
  static String updateProductStatus(String id) => '$productsBase/$id/status';
  static String updateProductStock(String id) => '$productsBase/$id/stock';
  static String deleteProduct(String id) => '$productsBase/$id';
  static String restoreProduct(String id) => '$productsBase/$id/restore';

  // Stock operations
  static String validateStockForSale(String id) =>
      '$productsBase/$id/validate-stock';
  static String reduceStockForSale(String id) =>
      '$productsBase/$id/reduce-stock';

  // ==================== CUSTOMERS ENDPOINTS ====================

  static const String customersBase = '/customers';

  // Public endpoints
  static const String customers = customersBase;
  static const String customersSearch = '$customersBase/search';
  static const String customersStats = '$customersBase/stats';
  static const String customersWithOverdue = '$customersBase/with-overdue';
  static const String customersTopCustomers = '$customersBase/top-customers';
  static const String customersStatsWithInvoices =
      '$customersBase/stats-with-invoices';

  // Individual customer endpoints
  static String customerById(String id) => '$customersBase/$id';
  static String customerByEmail(String email) => '$customersBase/email/$email';
  static String customerByDocument(
    String documentType,
    String documentNumber,
  ) => '$customersBase/document/$documentType/$documentNumber';
  static String customerWithInvoices(String id) =>
      '$customersBase/$id/with-invoices';
  static String customerInvoices(String id) => '$customersBase/$id/invoices';
  static String customerFinancialSummary(String id) =>
      '$customersBase/$id/financial-summary';

  // Customer management endpoints
  static String updateCustomerStatus(String id) => '$customersBase/$id/status';
  static String deleteCustomer(String id) => '$customersBase/$id';
  static String restoreCustomer(String id) => '$customersBase/$id/restore';
  static String updateCustomerStats(String id) =>
      '$customersBase/$id/update-stats';

  // Business logic endpoints
  static String canMakePurchase(String id) => '$customersBase/$id/can-purchase';

  // Validation endpoints
  static const String checkCustomerEmail = '$customersBase/check-email';
  static const String checkCustomerDocument = '$customersBase/check-document';

  // Cache Keys para customers
  static const String customersCacheKey = 'customers_cache';
  static const String customerStatsCacheKey = 'customer_stats_cache';

  // ==================== EXPENSES ENDPOINTS ====================

  static const String expensesBase = '/expenses';

  // Public endpoints
  static const String expenses = expensesBase;
  static const String expensesSearch = '$expensesBase/search';
  static const String expensesStats = '$expensesBase/stats';

  // Individual expense endpoints
  static String expenseById(String id) => '$expensesBase/$id';
  static String submitExpense(String id) => '$expensesBase/$id/submit';
  static String approveExpense(String id) => '$expensesBase/$id/approve';
  static String rejectExpense(String id) => '$expensesBase/$id/reject';
  static String markExpenseAsPaid(String id) => '$expensesBase/$id/mark-paid';

  // Expense Categories endpoints
  static const String expenseCategories = '/expense-categories';
  static const String expenseCategoriesSearch = '$expenseCategories/search';
  static String expenseCategoryById(String id) => '$expenseCategories/$id';

  // Cache Keys para expenses
  static const String expensesCacheKey = 'expenses_cache';
  static const String expenseStatsCacheKey = 'expense_stats_cache';
  static const String expenseCategoriesCacheKey = 'expense_categories_cache';

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Validar que todas las URLs estén correctamente configuradas
  static bool validateConfiguration() {
    try {
      print('🔍 Validando configuración de API...');

      // Verificar URL base
      if (baseUrl.isEmpty) {
        print('❌ Base URL vacía');
        return false;
      }

      // Verificar que sea una URL válida
      final uri = Uri.tryParse(baseUrl);
      if (uri == null || !uri.hasAbsolutePath) {
        print('❌ Base URL inválida: $baseUrl');
        return false;
      }

      // Verificar timeouts
      if (connectTimeout <= 0 || receiveTimeout <= 0 || sendTimeout <= 0) {
        print('❌ Timeouts inválidos');
        return false;
      }

      print('✅ Configuración de API válida');
      return true;
    } catch (e) {
      print('❌ Error validando configuración: $e');
      return false;
    }
  }

  /// Obtener información completa de configuración
  static Map<String, dynamic> getConfigInfo() {
    return {
      'baseUrl': baseUrl,
      'serverUrl': serverUrl,
      'serverIP': serverIP,
      'serverPort': serverPort,
      'connectTimeout': connectTimeout,
      'receiveTimeout': receiveTimeout,
      'sendTimeout': sendTimeout,
      'contentType': contentType,
      'accept': accept,
    };
  }
}
