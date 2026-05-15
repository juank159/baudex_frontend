// lib/app/shared/data/keyboard_shortcuts_registry.dart
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../features/employees/domain/entities/module_permission.dart';
import '../../../features/settings/presentation/controllers/organization_controller.dart';
import '../../core/services/permissions_service.dart';
import '../models/keyboard_shortcut.dart';

/// Registro central de TODOS los atajos de teclado de la app.
///
/// Cualquier atajo nuevo que se implemente debe registrarse aquí. Tanto
/// los handlers (`Shortcuts/Actions`) como la guía visible
/// (`KeyboardShortcutsDialog`) leen de esta lista, garantizando que la
/// documentación visible al usuario coincide con la implementación real.
///
/// Convención de IDs (usados también por los Intents de Flutter):
///   - `nav_<route>` para navegación entre pantallas (Alt+N)
///   - `app_*` para acciones globales de la app (palette, drawer, ayuda)
///   - `invoiceTabs_*` y `invoiceForm_*` para acciones locales
class KeyboardShortcutsRegistry {
  KeyboardShortcutsRegistry._();

  /// === GLOBALES — funcionan en cualquier pantalla autenticada. ===
  static final List<KeyboardShortcut> globals = [
    const KeyboardShortcut(
      id: 'app_command_palette',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.keyK,
      keyLabel: 'K',
      description: 'Buscador rápido (Command Palette)',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'app_toggle_drawer',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.keyB,
      keyLabel: 'B',
      description: 'Mostrar / ocultar el menú lateral',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'app_show_shortcuts',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.slash,
      keyLabel: '/',
      description: 'Mostrar esta guía de atajos',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),

    // Acceso directo a las 9 rutas más usadas — Alt+N para NO chocar
    // con el Ctrl+1..9 del invoice form (que sirve para cantidades).
    const KeyboardShortcut(
      id: 'nav_dashboard',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit1,
      keyLabel: '1',
      description: 'Ir al Dashboard',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_invoices_create',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit2,
      keyLabel: '2',
      description: 'Crear factura',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_invoices',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit3,
      keyLabel: '3',
      description: 'Lista de facturas',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_cash_register',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit4,
      keyLabel: '4',
      description: 'Caja registradora',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_customers',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit5,
      keyLabel: '5',
      description: 'Clientes',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_products',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit6,
      keyLabel: '6',
      description: 'Productos',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_inventory',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit7,
      keyLabel: '7',
      description: 'Gestión de inventario',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_customer_credits',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit8,
      keyLabel: '8',
      description: 'Créditos de clientes',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
    const KeyboardShortcut(
      id: 'nav_expenses',
      modifiers: [ShortcutModifier.alt],
      key: LogicalKeyboardKey.digit9,
      keyLabel: '9',
      description: 'Gastos',
      scope: ShortcutScope.global,
      screenName: 'Cualquier pantalla',
    ),
  ];

  /// === Pantalla "Crear factura con pestañas" (`/invoices/tabs`). ===
  /// Estos atajos los registra `invoice_form_tabs_screen.dart` cuando
  /// se monta; aquí solo los DOCUMENTAMOS para la guía.
  static final List<KeyboardShortcut> invoiceTabs = [
    const KeyboardShortcut(
      id: 'invoiceTabs_new_tab',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.keyT,
      keyLabel: 'T',
      description: 'Nueva pestaña de factura',
      scope: ShortcutScope.invoiceTabs,
      screenName: 'Crear factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceTabs_close_tab',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.keyW,
      keyLabel: 'W',
      description: 'Cerrar pestaña actual',
      scope: ShortcutScope.invoiceTabs,
      screenName: 'Crear factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceTabs_next_tab',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.tab,
      keyLabel: 'Tab',
      description: 'Siguiente pestaña',
      scope: ShortcutScope.invoiceTabs,
      screenName: 'Crear factura',
    ),
  ];

  /// === Dentro del formulario individual de factura. ===
  /// Estos atajos los registra `invoice_form_screen.dart` (cantidades,
  /// navegación de items, etc); aquí solo los documentamos.
  static final List<KeyboardShortcut> invoiceForm = [
    const KeyboardShortcut(
      id: 'invoiceForm_qty_n',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.digit1,
      keyLabel: '1-9',
      description: 'Establecer cantidad exacta (1 a 9)',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_qty_inc',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.equal,
      keyLabel: '+',
      description: 'Incrementar cantidad en 1',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_qty_dec',
      modifiers: [ShortcutModifier.ctrl],
      key: LogicalKeyboardKey.minus,
      keyLabel: '−',
      description: 'Decrementar cantidad en 1',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_nav_up',
      modifiers: [],
      key: LogicalKeyboardKey.arrowUp,
      keyLabel: '↑',
      description: 'Seleccionar ítem anterior',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_nav_down',
      modifiers: [],
      key: LogicalKeyboardKey.arrowDown,
      keyLabel: '↓',
      description: 'Seleccionar ítem siguiente',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_nav_home',
      modifiers: [],
      key: LogicalKeyboardKey.home,
      keyLabel: 'Home',
      description: 'Ir al primer ítem',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_nav_end',
      modifiers: [],
      key: LogicalKeyboardKey.end,
      keyLabel: 'End',
      description: 'Ir al último ítem',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_delete',
      modifiers: [],
      key: LogicalKeyboardKey.delete,
      keyLabel: 'Del',
      description: 'Eliminar ítem seleccionado',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
    const KeyboardShortcut(
      id: 'invoiceForm_add_first_result',
      modifiers: [],
      key: LogicalKeyboardKey.enter,
      keyLabel: 'Enter',
      description: 'Agregar primer producto del buscador',
      scope: ShortcutScope.invoiceForm,
      screenName: 'Formulario de factura',
    ),
  ];

  /// Todos los atajos en una sola lista (orden estable para la guía).
  static List<KeyboardShortcut> get all => [
        ...globals,
        ...invoiceTabs,
        ...invoiceForm,
      ];

  /// Atajos agrupados por scope, listos para mostrar en la guía.
  static Map<ShortcutScope, List<KeyboardShortcut>> get grouped => {
        ShortcutScope.global: globals,
        ShortcutScope.invoiceTabs: invoiceTabs,
        ShortcutScope.invoiceForm: invoiceForm,
      };

  /// Variante de [grouped] que filtra los `Alt + N` por permisos del
  /// usuario actual y por módulos opcionales del tenant (ej. caja
  /// registradora apagada). Los atajos del invoice form / tabs y los
  /// globales no-navegacionales (Ctrl+K, Ctrl+B, Ctrl+/) NO se filtran:
  /// siempre están disponibles dentro de su contexto.
  ///
  /// Si no hay `PermissionsService` (caso pruebas / app aún inicializando)
  /// se devuelve el grupo completo intacto para evitar guías vacías.
  static Map<ShortcutScope, List<KeyboardShortcut>> groupedForUser() {
    final isCashEnabled = _isCashRegisterEnabledForTenant();
    final perms = Get.isRegistered<PermissionsService>()
        ? Get.find<PermissionsService>()
        : null;

    bool isAllowed(KeyboardShortcut s) {
      // Sólo filtramos los atajos de navegación (id que empieza con
      // `nav_`); el resto se preserva siempre.
      if (!s.id.startsWith('nav_')) return true;
      final module = _navIdToModule[s.id];
      if (module == null) return true; // ej. Dashboard
      if (module == ModuleCode.cashRegister && !isCashEnabled) return false;
      if (perms == null) return true;
      return perms.canView(module);
    }

    return {
      ShortcutScope.global: globals.where(isAllowed).toList(),
      ShortcutScope.invoiceTabs: invoiceTabs,
      ShortcutScope.invoiceForm: invoiceForm,
    };
  }

  /// Mapeo de id de shortcut → ModuleCode que requiere. Mantener en
  /// sync con `_moduleForRoute` de `global_shortcuts.dart`.
  static const Map<String, String> _navIdToModule = {
    'nav_invoices_create': ModuleCode.invoices,
    'nav_invoices': ModuleCode.invoices,
    'nav_cash_register': ModuleCode.cashRegister,
    'nav_customers': ModuleCode.customers,
    'nav_products': ModuleCode.products,
    'nav_inventory': ModuleCode.inventory,
    'nav_customer_credits': ModuleCode.customers,
    'nav_expenses': ModuleCode.expenses,
    // `nav_dashboard` intencionalmente NO está aquí: el dashboard es
    // accesible para todos los usuarios autenticados.
  };

  static bool _isCashRegisterEnabledForTenant() {
    if (!Get.isRegistered<OrganizationController>()) return true;
    return Get.find<OrganizationController>().isCashRegisterEnabled;
  }

  /// Etiqueta humana de cada scope para los headers de la guía.
  static String scopeLabel(ShortcutScope scope) {
    switch (scope) {
      case ShortcutScope.global:
        return 'Atajos globales';
      case ShortcutScope.invoiceTabs:
        return 'Pantalla "Crear factura"';
      case ShortcutScope.invoiceForm:
        return 'Formulario de factura';
    }
  }

  /// Descripción corta que se muestra debajo del header de cada grupo,
  /// explicando al usuario dónde aplica.
  static String scopeHint(ShortcutScope scope) {
    switch (scope) {
      case ShortcutScope.global:
        return 'Funcionan en cualquier pantalla mientras estés logueado.';
      case ShortcutScope.invoiceTabs:
        return 'Activos cuando estás en la pantalla con las pestañas de facturas abiertas.';
      case ShortcutScope.invoiceForm:
        return 'Activos cuando estás dentro de una factura, manejando los productos del pedido.';
    }
  }
}
