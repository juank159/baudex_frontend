import 'package:equatable/equatable.dart';

/// Códigos de módulo. Mantener en sync con `PermissionModuleCode` del
/// backend.
class ModuleCode {
  static const dashboard = 'dashboard';
  static const invoices = 'invoices';
  static const expenses = 'expenses';
  static const customers = 'customers';
  static const products = 'products';
  static const inventory = 'inventory';
  static const purchaseOrders = 'purchase_orders';
  static const bankAccounts = 'bank_accounts';
  static const cashRegister = 'cash_register';
  static const reports = 'reports';
  static const settings = 'settings';
  static const employees = 'employees';

  static const all = <String>[
    dashboard,
    invoices,
    expenses,
    customers,
    products,
    inventory,
    purchaseOrders,
    bankAccounts,
    cashRegister,
    reports,
    settings,
    employees,
  ];

  /// Nombre legible para mostrar en UI.
  static String label(String code) {
    switch (code) {
      case dashboard:
        return 'Dashboard';
      case invoices:
        return 'Facturas';
      case expenses:
        return 'Gastos';
      case customers:
        return 'Clientes';
      case products:
        return 'Productos';
      case inventory:
        return 'Inventario';
      case purchaseOrders:
        return 'Órdenes de Compra';
      case bankAccounts:
        return 'Cuentas Bancarias';
      case cashRegister:
        return 'Caja Registradora';
      case reports:
        return 'Reportes';
      case settings:
        return 'Configuración';
      case employees:
        return 'Empleados';
      default:
        return code;
    }
  }
}

/// Permisos sobre un módulo específico.
class ModulePermission extends Equatable {
  final String moduleCode;
  final bool canView;
  final bool canEdit;
  final bool canDelete;

  const ModulePermission({
    required this.moduleCode,
    required this.canView,
    required this.canEdit,
    required this.canDelete,
  });

  factory ModulePermission.fromJson(Map<String, dynamic> json) {
    return ModulePermission(
      moduleCode: json['moduleCode'] as String,
      canView: json['canView'] as bool? ?? false,
      canEdit: json['canEdit'] as bool? ?? false,
      canDelete: json['canDelete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'moduleCode': moduleCode,
        'canView': canView,
        'canEdit': canEdit,
        'canDelete': canDelete,
      };

  ModulePermission copyWith({
    bool? canView,
    bool? canEdit,
    bool? canDelete,
  }) {
    return ModulePermission(
      moduleCode: moduleCode,
      canView: canView ?? this.canView,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
    );
  }

  @override
  List<Object?> get props => [moduleCode, canView, canEdit, canDelete];
}
