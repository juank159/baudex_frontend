import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/employee_list_controller.dart';
import '../widgets/employee_form_dialog.dart';
import '../widgets/permissions_dialog.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeListController>();
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _Header(controller: controller),
          _SearchAndFilters(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.employees.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.isNotEmpty &&
                  controller.employees.isEmpty) {
                return _ErrorState(
                  message: controller.errorMessage.value,
                  onRetry: controller.refreshList,
                );
              }
              final list = controller.filteredEmployees;
              if (list.isEmpty) {
                return _EmptyState(
                  hasFilters: controller.searchQuery.value.isNotEmpty ||
                      controller.filterRole.value != null ||
                      controller.filterStatus.value != null,
                  onClear: controller.clearFilters,
                  onCreate: () => EmployeeFormDialog.show(),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.refreshList,
                color: ElegantLightTheme.primaryBlue,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EmployeeCard(
                    user: list[i],
                    isMe: controller.isCurrentUser(list[i]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      // FAB redondo sólo con ícono — sin texto en ningún tamaño.
      // El tooltip basta para descubrir la acción. Patrón Material 3
      // estándar; el `.extended` con label se ve apretado y
      // desproporcionado incluso en desktop dentro de esta vista.
      floatingActionButton: FloatingActionButton(
        onPressed: () => EmployeeFormDialog.show(),
        backgroundColor: ElegantLightTheme.primaryBlue,
        tooltip: 'Nuevo empleado',
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

}

class _Header extends StatelessWidget {
  final EmployeeListController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Empleados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Obx(() => Text(
                        '${controller.employees.length} en el equipo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      )),
                ],
              ),
            ),
            Obx(() => controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon:
                        const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: controller.refreshList,
                    tooltip: 'Recargar',
                  )),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  final EmployeeListController controller;
  const _SearchAndFilters({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => controller.searchQuery.value = v,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email o teléfono...',
              prefixIcon: Icon(Icons.search_rounded,
                  color: ElegantLightTheme.textSecondary),
              filled: true,
              fillColor: ElegantLightTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'Todos',
                      selected: controller.filterRole.value == null &&
                          controller.filterStatus.value == null,
                      onTap: () {
                        controller.filterRole.value = null;
                        controller.filterStatus.value = null;
                      },
                      icon: Icons.filter_list_rounded,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Admin',
                      selected: controller.filterRole.value == UserRole.admin,
                      onTap: () => controller.filterRole.value =
                          controller.filterRole.value == UserRole.admin
                              ? null
                              : UserRole.admin,
                      icon: Icons.admin_panel_settings_rounded,
                      color: ElegantLightTheme.errorRed,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Gerente',
                      selected:
                          controller.filterRole.value == UserRole.manager,
                      onTap: () => controller.filterRole.value =
                          controller.filterRole.value == UserRole.manager
                              ? null
                              : UserRole.manager,
                      icon: Icons.workspace_premium_rounded,
                      color: ElegantLightTheme.warningOrange,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Usuario',
                      selected: controller.filterRole.value == UserRole.user,
                      onTap: () => controller.filterRole.value =
                          controller.filterRole.value == UserRole.user
                              ? null
                              : UserRole.user,
                      icon: Icons.person_rounded,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 1,
                      color: ElegantLightTheme.textTertiary
                          .withValues(alpha: 0.3),
                    ),
                    _FilterChip(
                      label: 'Activos',
                      selected:
                          controller.filterStatus.value == UserStatus.active,
                      onTap: () => controller.filterStatus.value =
                          controller.filterStatus.value == UserStatus.active
                              ? null
                              : UserStatus.active,
                      icon: Icons.check_circle_outline_rounded,
                      color: ElegantLightTheme.successGreen,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Suspendidos',
                      selected: controller.filterStatus.value ==
                          UserStatus.suspended,
                      onTap: () => controller.filterStatus.value =
                          controller.filterStatus.value == UserStatus.suspended
                              ? null
                              : UserStatus.suspended,
                      icon: Icons.block_rounded,
                      color: ElegantLightTheme.errorRed,
                    ),
                  ],
                )),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color? color;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? ElegantLightTheme.primaryBlue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? c
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? c : ElegantLightTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? c : ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final User user;
  final bool isMe;
  const _EmployeeCard({required this.user, required this.isMe});

  /// Solo el admin del tenant puede configurar permisos. Manager/User no
  /// tienen ese poder (restricción del backend, replicada en UI).
  bool _currentUserIsAdmin() {
    try {
      if (!Get.isRegistered<AuthController>()) return false;
      return Get.find<AuthController>().currentUser?.role == UserRole.admin;
    } catch (_) {
      return false;
    }
  }

  Color get _roleColor => switch (user.role) {
        UserRole.admin => ElegantLightTheme.errorRed,
        UserRole.manager => ElegantLightTheme.warningOrange,
        UserRole.user => ElegantLightTheme.primaryBlue,
      };

  String get _roleLabel => switch (user.role) {
        UserRole.admin => 'Admin',
        UserRole.manager => 'Gerente',
        UserRole.user => 'Usuario',
      };

  IconData get _roleIcon => switch (user.role) {
        UserRole.admin => Icons.admin_panel_settings_rounded,
        UserRole.manager => Icons.workspace_premium_rounded,
        UserRole.user => Icons.person_rounded,
      };

  Color get _statusColor => switch (user.status) {
        UserStatus.active => ElegantLightTheme.successGreen,
        UserStatus.suspended => ElegantLightTheme.errorRed,
        UserStatus.inactive => ElegantLightTheme.textTertiary,
      };

  String get _statusLabel => switch (user.status) {
        UserStatus.active => 'Activo',
        UserStatus.suspended => 'Suspendido',
        UserStatus.inactive => 'Inactivo',
      };

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeListController>();
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
        border: Border.all(
          color: _roleColor.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _roleColor.withValues(alpha: 0.2),
                    _roleColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  user.firstName.isNotEmpty
                      ? user.firstName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _roleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: ElegantLightTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.primaryBlue
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Tú',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ElegantLightTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(
                        label: _roleLabel,
                        icon: _roleIcon,
                        color: _roleColor,
                      ),
                      const SizedBox(width: 6),
                      _Badge(
                        label: _statusLabel,
                        icon: user.status == UserStatus.active
                            ? Icons.check_circle_rounded
                            : Icons.block_rounded,
                        color: _statusColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Acciones
            if (!isMe)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: ElegantLightTheme.textSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          user.status == UserStatus.active
                              ? Icons.block_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                          color: user.status == UserStatus.active
                              ? ElegantLightTheme.errorRed
                              : ElegantLightTheme.successGreen,
                        ),
                        const SizedBox(width: 10),
                        Text(user.status == UserStatus.active
                            ? 'Suspender'
                            : 'Activar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset_pwd',
                    child: Row(
                      children: [
                        Icon(Icons.lock_reset_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Restablecer contraseña'),
                      ],
                    ),
                  ),
                  // "Configurar permisos" SOLO visible para admin del tenant.
                  // El backend rechazará la edición si el caller no es admin,
                  // pero la regla de UX es no mostrar opciones que no se pueden
                  // ejecutar.
                  if (_currentUserIsAdmin())
                    const PopupMenuItem(
                      value: 'permissions',
                      child: Row(
                        children: [
                          Icon(Icons.lock_person_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Configurar permisos'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: ElegantLightTheme.errorRed),
                        const SizedBox(width: 10),
                        Text('Eliminar',
                            style: TextStyle(
                                color: ElegantLightTheme.errorRed)),
                      ],
                    ),
                  ),
                ],
                onSelected: (action) async {
                  switch (action) {
                    case 'edit':
                      await EmployeeFormDialog.show(existing: user);
                      break;
                    case 'toggle':
                      await controller.toggleStatus(user);
                      break;
                    case 'reset_pwd':
                      await _showResetPasswordDialog(user, controller);
                      break;
                    case 'permissions':
                      await PermissionsDialog.show(user);
                      break;
                    case 'delete':
                      await _confirmDelete(user, controller);
                      break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetPasswordDialog(
    User user,
    EmployeeListController controller,
  ) async {
    final passController = TextEditingController();
    bool show = false;
    final result = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_reset_rounded,
                  color: ElegantLightTheme.warningOrange),
              const SizedBox(width: 8),
              const Text('Restablecer contraseña'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Asignar nueva contraseña a ${user.fullName}.\n'
                'Comunícale al empleado la nueva contraseña.',
                style: TextStyle(
                    fontSize: 13, color: ElegantLightTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: !show,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  helperText: 'Min 6, mayúscula, minúscula y número',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(show
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () => setState(() => show = !show),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final pwd = passController.text;
                if (pwd.length < 6 ||
                    !RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(pwd)) {
                  Get.snackbar(
                    'Contraseña débil',
                    'Debe tener mín 6 caracteres, mayúscula, minúscula y número',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: ElegantLightTheme.errorRed
                        .withValues(alpha: 0.12),
                    colorText: ElegantLightTheme.errorRed,
                  );
                  return;
                }
                Get.back(result: true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: ElegantLightTheme.warningOrange,
              ),
              child: const Text('Restablecer'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      await controller.resetPassword(user.id, passController.text);
    }
    passController.dispose();
  }

  Future<void> _confirmDelete(
    User user,
    EmployeeListController controller,
  ) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: ElegantLightTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Eliminar empleado'),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar a ${user.fullName}? '
          'No podrá iniciar sesión más. Esta acción se puede revertir desde soporte.',
          style: TextStyle(color: ElegantLightTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: ElegantLightTheme.errorRed,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.delete(user);
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;
  final VoidCallback onCreate;
  const _EmptyState({
    required this.hasFilters,
    required this.onClear,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.filter_alt_off_rounded
                    : Icons.groups_rounded,
                size: 56,
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'Sin resultados' : 'Aún no hay empleados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Intenta ajustar los filtros o búsqueda.'
                  : 'Agrega a tu equipo para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              FilledButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Limpiar filtros'),
                style: FilledButton.styleFrom(
                  backgroundColor: ElegantLightTheme.textSecondary,
                ),
              )
            else
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Crear primer empleado'),
                style: FilledButton.styleFrom(
                  backgroundColor: ElegantLightTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: ElegantLightTheme.errorRed),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar los empleados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
