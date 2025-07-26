// lib/app/shared/controllers/app_drawer_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/routes/app_routes.dart';
import '../models/drawer_menu_item.dart';

/// Controlador independiente para el drawer de la aplicación
/// Maneja la navegación, badges, estado de items del menú
class AppDrawerController extends GetxController {
  
  // ==================== OBSERVABLES ====================
  
  /// Lista de items del menú
  final _menuItems = <DrawerMenuItem>[].obs;
  
  /// Contadores de badges para notificaciones
  final _badgeCounts = <String, int>{}.obs;
  
  /// Estado de carga
  final _isLoading = false.obs;
  
  /// Estado de expansión del grupo de configuración
  final _isConfigurationExpanded = false.obs;
  
  // ==================== GETTERS ====================
  
  List<DrawerMenuItem> get menuItems => _menuItems;
  Map<String, int> get badgeCounts => _badgeCounts;
  bool get isLoading => _isLoading.value;
  
  /// Getter para el estado de expansión del grupo de configuración
  bool get isConfigurationExpanded => _isConfigurationExpanded.value;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    _initializeMenuItems();
    _loadBadgeCounts();
  }

  // ==================== INITIALIZATION ====================

  void _initializeMenuItems() {
    _menuItems.value = [
      // ==================== MÓDULOS PRINCIPALES ====================
      
      const DrawerMenuItem(
        id: 'dashboard',
        title: 'Dashboard',
        icon: Icons.dashboard_rounded,
        route: AppRoutes.dashboard,
        subtitle: 'Panel principal',
      ),
      
      const DrawerMenuItem(
        id: 'invoices',
        title: 'Facturas',
        icon: Icons.receipt_long,
        route: AppRoutes.invoices,
        subtitle: 'Gestión de facturas',
      ),
      
      const DrawerMenuItem(
        id: 'invoices_create',
        title: 'Crear Factura',
        icon: Icons.add_box,
        route: AppRoutes.invoicesWithTabs,
        subtitle: 'Nueva factura',
      ),
      
      const DrawerMenuItem(
        id: 'products',
        title: 'Productos',
        icon: Icons.inventory_2,
        route: AppRoutes.products,
        subtitle: 'Catálogo de productos',
      ),
      
      const DrawerMenuItem(
        id: 'customers',
        title: 'Clientes',
        icon: Icons.people,
        route: AppRoutes.customers,
        subtitle: 'Gestión de clientes',
      ),
      
      const DrawerMenuItem(
        id: 'categories',
        title: 'Categorías',
        icon: Icons.category,
        route: AppRoutes.categories,
        subtitle: 'Organizar productos',
      ),
      
      const DrawerMenuItem(
        id: 'expenses',
        title: 'Gastos',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.expenses,
        subtitle: 'Gestión de gastos',
      ),
      
      const DrawerMenuItem(
        id: 'expense_categories',
        title: 'Categorías de Gastos',
        icon: Icons.category_outlined,
        route: AppRoutes.expensesCategories,
        subtitle: 'Gestionar categorías',
      ),

      // ==================== CONFIGURACIÓN Y HERRAMIENTAS ====================
      
      // ==================== GRUPO DE CONFIGURACIÓN ====================
      
      const DrawerMenuItem(
        id: 'organization_settings',
        title: 'Organización',
        icon: Icons.business,
        route: AppRoutes.settingsOrganization,
        subtitle: 'Configuración de empresa',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
      
      const DrawerMenuItem(
        id: 'invoice_settings',
        title: 'Facturas',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.settingsInvoice,
        subtitle: 'Configuración de facturas',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
      
      const DrawerMenuItem(
        id: 'printer_settings', 
        title: 'Impresoras',
        icon: Icons.print,
        route: AppRoutes.settingsPrinter,
        subtitle: 'Configuración de impresoras',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
      
      const DrawerMenuItem(
        id: 'app_settings',
        title: 'Aplicación',
        icon: Icons.tune,
        route: AppRoutes.settingsApp,
        subtitle: 'Configuración general',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
      
      const DrawerMenuItem(
        id: 'user_settings',
        title: 'Usuario',
        icon: Icons.person_outline,
        route: AppRoutes.settingsUser,
        subtitle: 'Perfil y preferencias',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
      
      const DrawerMenuItem(
        id: 'backup_settings',
        title: 'Respaldos',
        icon: Icons.backup,
        route: AppRoutes.settingsBackup,
        subtitle: 'Copias de seguridad',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
      
      const DrawerMenuItem(
        id: 'security_settings',
        title: 'Seguridad',
        icon: Icons.security,
        route: AppRoutes.settingsSecurity,
        subtitle: 'Configuración de seguridad',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
      
      const DrawerMenuItem(
        id: 'notifications_settings',
        title: 'Notificaciones',
        icon: Icons.notifications_outlined,
        route: AppRoutes.settingsNotifications,
        subtitle: 'Configuración de notificaciones',
        isInSettings: true,
        isInConfigurationGroup: true,
      ),
    ];
  }

  /// Cargar contadores de badges desde la API o localStorage
  Future<void> _loadBadgeCounts() async {
    try {
      _isLoading.value = true;
      
      // TODO: Implementar carga real desde API
      // Por ahora usamos datos simulados
      await Future.delayed(const Duration(milliseconds: 500));
      
      _badgeCounts.value = {
        'invoices': 3,        // 3 facturas pendientes
        'customers': 1,       // 1 cliente nuevo
        'products': 5,        // 5 productos con stock bajo
        'expenses': 2,        // 2 gastos pendientes de aprobación
        'notifications': 8,   // 8 notificaciones no leídas
      };
      
    } catch (e) {
      print('❌ Error al cargar badges: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // ==================== PUBLIC METHODS ====================

  /// Obtener contador de badge para un item específico
  int getBadgeCount(String itemId) {
    return _badgeCounts[itemId] ?? 0;
  }

  /// Actualizar contador de badge
  void updateBadgeCount(String itemId, int count) {
    if (count <= 0) {
      _badgeCounts.remove(itemId);
    } else {
      _badgeCounts[itemId] = count;
    }
  }

  /// Incrementar badge
  void incrementBadge(String itemId) {
    final currentCount = getBadgeCount(itemId);
    updateBadgeCount(itemId, currentCount + 1);
  }

  /// Decrementar badge
  void decrementBadge(String itemId) {
    final currentCount = getBadgeCount(itemId);
    if (currentCount > 0) {
      updateBadgeCount(itemId, currentCount - 1);
    }
  }

  /// Limpiar badge específico
  void clearBadge(String itemId) {
    _badgeCounts.remove(itemId);
  }

  /// Limpiar todos los badges
  void clearAllBadges() {
    _badgeCounts.clear();
  }

  /// Actualizar item del menú
  void updateMenuItem(String itemId, DrawerMenuItem updatedItem) {
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _menuItems[index] = updatedItem;
    }
  }

  /// Habilitar/deshabilitar item del menú
  void setMenuItemEnabled(String itemId, bool enabled) {
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _menuItems[index] = _menuItems[index].copyWith(isEnabled: enabled);
    }
  }
  
  /// Alternar expansión del grupo de configuración
  void toggleConfigurationExpanded() {
    _isConfigurationExpanded.value = !_isConfigurationExpanded.value;
  }
  
  /// Método alternativo para obtener el estado de expansión
  bool getConfigurationExpandedState() {
    return _isConfigurationExpanded.value;
  }
  
  /// Expandir grupo de configuración
  void expandConfiguration() {
    _isConfigurationExpanded.value = true;
  }
  
  /// Colapsar grupo de configuración
  void collapseConfiguration() {
    _isConfigurationExpanded.value = false;
  }

  /// Añadir item temporal al menú (ej: para plugins)
  void addTemporaryMenuItem(DrawerMenuItem item) {
    if (!_menuItems.any((existing) => existing.id == item.id)) {
      _menuItems.add(item);
    }
  }

  /// Remover item temporal del menú
  void removeTemporaryMenuItem(String itemId) {
    _menuItems.removeWhere((item) => item.id == itemId);
  }

  // ==================== NAVIGATION HELPERS ====================

  /// Navegación rápida a dashboard
  void goToDashboard() {
    Get.offAllNamed(AppRoutes.dashboard);
  }

  /// Navegación rápida a facturas
  void goToInvoices() {
    Get.toNamed(AppRoutes.invoices);
  }

  /// Navegación rápida a crear factura
  void goToCreateInvoice() {
    Get.toNamed(AppRoutes.invoicesWithTabs);
  }

  /// Navegación rápida a productos
  void goToProducts() {
    Get.toNamed(AppRoutes.products);
  }

  /// Navegación rápida a clientes
  void goToCustomers() {
    Get.toNamed(AppRoutes.customers);
  }

  /// Navegación rápida a categorías
  void goToCategories() {
    Get.toNamed(AppRoutes.categories);
  }

  /// Navegación rápida a gastos
  void goToExpenses() {
    Get.toNamed(AppRoutes.expenses);
  }

  // ==================== STATISTICS METHODS ====================

  /// Refrescar estadísticas y badges
  Future<void> refreshStatistics() async {
    try {
      _isLoading.value = true;
      
      // Cargar estadísticas en paralelo
      final futures = [
        _loadInvoiceStats(),
        _loadCustomerStats(),
        _loadProductStats(),
        _loadExpenseStats(),
        _loadNotificationStats(),
      ];
      
      await Future.wait(futures);
      
    } catch (e) {
      print('❌ Error al refrescar estadísticas: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadInvoiceStats() async {
    // TODO: Implementar carga real de estadísticas de facturas
    await Future.delayed(const Duration(milliseconds: 200));
    updateBadgeCount('invoices', 3); // Facturas pendientes
  }

  Future<void> _loadCustomerStats() async {
    // TODO: Implementar carga real de estadísticas de clientes
    await Future.delayed(const Duration(milliseconds: 200));
    updateBadgeCount('customers', 1); // Clientes nuevos
  }

  Future<void> _loadProductStats() async {
    // TODO: Implementar carga real de estadísticas de productos
    await Future.delayed(const Duration(milliseconds: 200));
    updateBadgeCount('products', 5); // Stock bajo
  }

  Future<void> _loadExpenseStats() async {
    // TODO: Implementar carga real de estadísticas de gastos
    await Future.delayed(const Duration(milliseconds: 200));
    updateBadgeCount('expenses', 2); // Gastos pendientes de aprobación
  }

  Future<void> _loadNotificationStats() async {
    // TODO: Implementar carga real de notificaciones
    await Future.delayed(const Duration(milliseconds: 200));
    updateBadgeCount('notifications', 8); // Notificaciones no leídas
  }

  // ==================== SEARCH METHODS ====================

  /// Buscar en el menú
  List<DrawerMenuItem> searchMenuItems(String query) {
    if (query.trim().isEmpty) return _menuItems;
    
    final lowercaseQuery = query.toLowerCase().trim();
    
    return _menuItems.where((item) {
      return item.title.toLowerCase().contains(lowercaseQuery) ||
             (item.subtitle?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Obtener items favoritos (basado en uso frecuente)
  List<DrawerMenuItem> getFavoriteItems() {
    // TODO: Implementar lógica de favoritos basada en uso
    return [
      _menuItems.firstWhere((item) => item.id == 'dashboard'),
      _menuItems.firstWhere((item) => item.id == 'invoices'),
      _menuItems.firstWhere((item) => item.id == 'products'),
      _menuItems.firstWhere((item) => item.id == 'expenses'),
    ];
  }

  // ==================== DEBUGGING METHODS ====================

  /// Obtener información de estado para debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'menuItemsCount': _menuItems.length,
      'badgeCount': _badgeCounts.length,
      'totalBadges': _badgeCounts.values.fold(0, (sum, count) => sum + count),
      'isLoading': _isLoading.value,
      'enabledItems': _menuItems.where((item) => item.isEnabled).length,
      'settingsItems': _menuItems.where((item) => item.isInSettings).length,
    };
  }

  /// Imprimir información de debugging
  void printDebugInfo() {
    final info = getDebugInfo();
    print('🐛 AppDrawerController Debug Info:');
    info.forEach((key, value) {
      print('   $key: $value');
    });
  }
}