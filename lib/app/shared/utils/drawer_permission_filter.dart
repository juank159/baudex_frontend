import 'package:get/get.dart';
import '../../core/services/permissions_service.dart';
import '../../../features/employees/domain/entities/module_permission.dart';
import '../../../features/settings/presentation/controllers/organization_controller.dart';
import '../models/drawer_menu_item.dart';

/// Filtra los items del drawer según los permisos del usuario actual.
///
/// Mantiene la lista plana (incluyendo grupos colapsables) pero descarta:
///  - Items de un módulo cuyo `canView` sea false.
///  - Grupos cuyos hijos quedaron todos filtrados.
///
/// Items que NO mapean a ningún módulo se preservan SIEMPRE
/// (notificaciones, configuración del usuario, etc.).
class DrawerPermissionFilter {
  /// Mapeo del id del item del drawer → código del módulo. Items que no
  /// están aquí no se filtran (ej: dashboard, notifications, settings).
  static const Map<String, String> _itemToModule = {
    // Comercial
    'invoices': ModuleCode.invoices,
    'invoices_create': ModuleCode.invoices,
    'credit_notes': ModuleCode.invoices,
    'customers': ModuleCode.customers,
    'customer_credits': ModuleCode.customers,
    'client_balances': ModuleCode.customers,
    // Inventario
    'products': ModuleCode.products,
    'initial_inventory': ModuleCode.inventory,
    'categories': ModuleCode.products,
    'inventory': ModuleCode.inventory,
    // Compras / proveedores
    'purchase_orders': ModuleCode.purchaseOrders,
    'suppliers': ModuleCode.purchaseOrders,
    // Finanzas
    'expenses': ModuleCode.expenses,
    'expense_categories': ModuleCode.expenses,
    'bank_accounts': ModuleCode.bankAccounts,
    'bank_movements': ModuleCode.bankAccounts,
    'payment_methods': ModuleCode.bankAccounts,
    // Operaciones
    'cash_register': ModuleCode.cashRegister,
    // Reportes
    'reports': ModuleCode.reports,
    // Empleados (gestión de equipo) — controlado por su propio módulo
    'employees': ModuleCode.employees,
    // Configuración del sistema (todos los items con isInConfigurationGroup
    // que no tengan otro módulo más específico). Si el admin retira
    // canView('settings'), TODA la sección de configuración se oculta.
    'organization_settings': ModuleCode.settings,
    'invoice_settings': ModuleCode.settings,
    'printer_settings': ModuleCode.settings,
    'app_settings': ModuleCode.settings,
    'user_preferences': ModuleCode.settings,
    'backup_settings': ModuleCode.settings,
    'security_settings': ModuleCode.settings,
    'notifications_settings': ModuleCode.settings,
    'diagnostics': ModuleCode.settings,
  };

  /// Aplica el filtro a una lista de items. Si no hay
  /// PermissionsService registrado, devuelve la lista intacta.
  static List<DrawerMenuItem> apply(List<DrawerMenuItem> items) {
    if (!Get.isRegistered<PermissionsService>()) return items;
    final perms = Get.find<PermissionsService>();
    return items
        .map((item) => _filterItem(item, perms))
        .whereType<DrawerMenuItem>()
        .toList();
  }

  /// Items que pertenecen a un módulo OPCIONAL controlado por
  /// configuración del tenant (no por permisos del usuario). Si la
  /// organización tiene ese módulo apagado, el item se oculta para
  /// todos los usuarios del tenant.
  static const Set<String> _cashRegisterItems = {
    'cash_register',
  };

  /// Devuelve null si el item debe ocultarse.
  static DrawerMenuItem? _filterItem(
    DrawerMenuItem item,
    PermissionsService perms,
  ) {
    // 0. Módulos opcionales del tenant. Si el admin desactivó la caja
    // registradora desde Settings, los items asociados desaparecen del
    // menú independientemente de los permisos del usuario.
    if (_cashRegisterItems.contains(item.id) &&
        Get.isRegistered<OrganizationController>() &&
        !Get.find<OrganizationController>().isCashRegisterEnabled) {
      return null;
    }

    // 1. Si el item tiene submenu, filtrar sus hijos primero.
    if (item.hasSubmenu) {
      final filteredChildren = item.submenu!
          .map((child) => _filterItem(child, perms))
          .whereType<DrawerMenuItem>()
          .toList();
      // Si todos los hijos quedaron filtrados, ocultar el grupo entero.
      if (filteredChildren.isEmpty) return null;
      return item.copyWith(submenu: filteredChildren);
    }

    // 2. Item hoja: chequear si pertenece a un módulo restringido.
    final moduleCode = _itemToModule[item.id];
    if (moduleCode == null) {
      // No mapea a módulo → siempre visible (dashboard, settings, etc).
      return item;
    }

    return perms.canView(moduleCode) ? item : null;
  }
}
