import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/permissions_service.dart';
import '../../core/theme/elegant_light_theme.dart';

/// Acción a verificar.
enum PermissionAction { view, edit, delete }

/// Widget que oculta su hijo según los permisos del usuario actual.
///
/// Ejemplos:
/// ```dart
/// // Ocultar el FAB si no puede crear facturas
/// PermissionGate.canEdit(
///   moduleCode: 'invoices',
///   child: FloatingActionButton(...),
/// )
///
/// // Mostrar fallback (ej: tooltip deshabilitado) cuando no tiene permiso
/// PermissionGate.canDelete(
///   moduleCode: 'products',
///   child: IconButton(icon: Icon(Icons.delete), onPressed: _delete),
///   fallback: SizedBox.shrink(),
/// )
/// ```
///
/// Es reactivo: cuando los permisos cambian (ej: el admin ajusta en otra
/// sesión y el sync actualiza) el widget se reconstruye automáticamente.
class PermissionGate extends StatelessWidget {
  final String moduleCode;
  final PermissionAction action;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.moduleCode,
    required this.action,
    required this.child,
    this.fallback,
  });

  /// Atajo: visible si puede VER el módulo.
  factory PermissionGate.canView({
    required String moduleCode,
    required Widget child,
    Widget? fallback,
  }) =>
      PermissionGate(
        moduleCode: moduleCode,
        action: PermissionAction.view,
        child: child,
        fallback: fallback,
      );

  /// Atajo: visible si puede EDITAR el módulo.
  factory PermissionGate.canEdit({
    required String moduleCode,
    required Widget child,
    Widget? fallback,
  }) =>
      PermissionGate(
        moduleCode: moduleCode,
        action: PermissionAction.edit,
        child: child,
        fallback: fallback,
      );

  /// Atajo: visible si puede ELIMINAR el módulo.
  factory PermissionGate.canDelete({
    required String moduleCode,
    required Widget child,
    Widget? fallback,
  }) =>
      PermissionGate(
        moduleCode: moduleCode,
        action: PermissionAction.delete,
        child: child,
        fallback: fallback,
      );

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PermissionsService>()) {
      // Servicio no registrado todavía → mostrar el child para no romper
      // la app antes de que el binding inicial complete.
      return child;
    }
    final perms = Get.find<PermissionsService>();
    return Obx(() {
      // Suscripción reactiva al cache de permisos.
      // ignore: unused_local_variable
      final _length = perms.rxPermissions.length;
      final allowed = switch (action) {
        PermissionAction.view => perms.canView(moduleCode),
        PermissionAction.edit => perms.canEdit(moduleCode),
        PermissionAction.delete => perms.canDelete(moduleCode),
      };
      if (allowed) return child;
      return fallback ?? const SizedBox.shrink();
    });
  }
}

/// Helper para mostrar un snackbar cuando el usuario intenta una acción
/// que no le permite su rol/permisos. Útil cuando una acción se invoca
/// desde un atajo de teclado o navegación que no usa PermissionGate.
class PermissionDeniedSnackbar {
  static void show({String? customMessage}) {
    Get.snackbar(
      'Sin permiso',
      customMessage ??
          'No tienes permiso para realizar esta acción. '
              'Pídele al administrador que te lo conceda.',
      snackPosition: SnackPosition.TOP,
      backgroundColor:
          ElegantLightTheme.errorRed.withValues(alpha: 0.12),
      colorText: ElegantLightTheme.errorRed,
      icon: Icon(Icons.lock_outline_rounded,
          color: ElegantLightTheme.errorRed),
      duration: const Duration(seconds: 3),
    );
  }
}
