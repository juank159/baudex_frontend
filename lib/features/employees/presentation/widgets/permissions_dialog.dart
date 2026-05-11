import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/services/permissions_service.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/module_permission.dart';

/// Dialog para configurar los permisos granulares de un empleado.
/// Solo el admin puede usar este dialog (el backend rechaza si no es admin).
class PermissionsDialog extends StatefulWidget {
  final User user;
  const PermissionsDialog({super.key, required this.user});

  static Future<bool?> show(User user) {
    return Get.dialog<bool>(
      PermissionsDialog(user: user),
      barrierDismissible: false,
    );
  }

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  final PermissionsService _service = PermissionsService.to;
  final RxBool _loading = true.obs;
  final RxBool _saving = false.obs;
  final RxList<ModulePermission> _permissions = <ModulePermission>[].obs;
  String? _errorMessage;

  bool get _isAdmin => widget.user.role == UserRole.admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _loading.value = true;
    try {
      final list = await _service.getUserPermissions(widget.user.id);
      _permissions.assignAll(list);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los permisos: $e';
    } finally {
      _loading.value = false;
    }
  }

  void _toggle(int index, {bool? view, bool? edit, bool? delete}) {
    final p = _permissions[index];
    var next = p.copyWith(canView: view, canEdit: edit, canDelete: delete);
    // Regla de UX: si quita canView, también desactiva edit/delete
    // (no tiene sentido editar lo que no puedes ver).
    if (view == false) {
      next = next.copyWith(canEdit: false, canDelete: false);
    }
    // Regla simétrica: si activa edit o delete sin view, activamos view.
    if ((edit == true || delete == true) && !next.canView) {
      next = next.copyWith(canView: true);
    }
    _permissions[index] = next;
  }

  Future<void> _save() async {
    if (_saving.value) return;
    _saving.value = true;
    try {
      await _service.setUserPermissions(
        widget.user.id,
        _permissions.toList(),
      );
      Get.snackbar(
        'Permisos actualizados',
        'Los cambios se aplicarán en el próximo login del empleado',
        snackPosition: SnackPosition.TOP,
        backgroundColor:
            ElegantLightTheme.successGreen.withValues(alpha: 0.12),
        colorText: ElegantLightTheme.successGreen,
        icon: Icon(Icons.check_circle, color: ElegantLightTheme.successGreen),
        duration: const Duration(seconds: 3),
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(true);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo guardar: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: ElegantLightTheme.errorRed.withValues(alpha: 0.12),
        colorText: ElegantLightTheme.errorRed,
      );
    } finally {
      _saving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 540,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_person_rounded,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configurar permisos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.user.fullName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: Obx(() {
                if (_isAdmin) {
                  return _AdminLockedView();
                }
                if (_loading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (_errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: ElegantLightTheme.errorRed, size: 48),
                          const SizedBox(height: 8),
                          Text(_errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: ElegantLightTheme.textSecondary)),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.primaryBlue
                              .withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: ElegantLightTheme.primaryBlue
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: ElegantLightTheme.primaryBlue,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Marca qué módulos puede VER, EDITAR y ELIMINAR este empleado.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ElegantLightTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Header(),
                      const SizedBox(height: 4),
                      ...List.generate(_permissions.length, (i) {
                        final p = _permissions[i];
                        return _ModuleRow(
                          permission: p,
                          onToggleView: (v) => _toggle(i, view: v),
                          onToggleEdit: (v) => _toggle(i, edit: v),
                          onToggleDelete: (v) => _toggle(i, delete: v),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ),
            // Footer
            if (!_isAdmin)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: ElegantLightTheme.textTertiary
                          .withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: ElegantLightTheme.textSecondary,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Obx(() => FilledButton.icon(
                            onPressed:
                                _saving.value || _loading.value ? null : _save,
                            icon: _saving.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text('Guardar permisos'),
                            style: FilledButton.styleFrom(
                              backgroundColor: ElegantLightTheme.primaryBlue,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'MÓDULO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ElegantLightTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'VER',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ElegantLightTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'EDITAR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ElegantLightTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'ELIMINAR',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ElegantLightTheme.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  final ModulePermission permission;
  final ValueChanged<bool> onToggleView;
  final ValueChanged<bool> onToggleEdit;
  final ValueChanged<bool> onToggleDelete;
  const _ModuleRow({
    required this.permission,
    required this.onToggleView,
    required this.onToggleEdit,
    required this.onToggleDelete,
  });

  IconData _iconFor(String code) {
    switch (code) {
      case ModuleCode.dashboard:
        return Icons.dashboard_rounded;
      case ModuleCode.invoices:
        return Icons.receipt_long_rounded;
      case ModuleCode.expenses:
        return Icons.payments_rounded;
      case ModuleCode.customers:
        return Icons.people_rounded;
      case ModuleCode.products:
        return Icons.inventory_2_rounded;
      case ModuleCode.inventory:
        return Icons.warehouse_rounded;
      case ModuleCode.purchaseOrders:
        return Icons.shopping_cart_rounded;
      case ModuleCode.bankAccounts:
        return Icons.account_balance_rounded;
      case ModuleCode.cashRegister:
        return Icons.point_of_sale_rounded;
      case ModuleCode.reports:
        return Icons.analytics_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconFor(permission.moduleCode),
                    size: 16,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ModuleCode.label(permission.moduleCode),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Switch(
                value: permission.canView,
                onChanged: onToggleView,
                activeColor: ElegantLightTheme.successGreen,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Switch(
                value: permission.canEdit,
                onChanged: onToggleEdit,
                activeColor: ElegantLightTheme.warningOrange,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Switch(
                value: permission.canDelete,
                onChanged: onToggleDelete,
                activeColor: ElegantLightTheme.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminLockedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  ElegantLightTheme.errorRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 48,
              color: ElegantLightTheme.errorRed,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Este empleado es Administrador',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Los administradores tienen TODOS los permisos por defecto. '
            'Para restringirlos, primero cambia su rol a Gerente o Usuario.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: ElegantLightTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Get.back(),
            style: FilledButton.styleFrom(
              backgroundColor: ElegantLightTheme.textSecondary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 12),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
