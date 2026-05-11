import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../auth/domain/entities/user.dart';
import '../controllers/employee_list_controller.dart';

/// Modal para crear o editar un empleado.
/// Si `existing` es null → modo CREAR (con campo password obligatorio).
/// Si `existing` no es null → modo EDITAR (sin password; usar dialog de
/// reset por separado).
class EmployeeFormDialog extends StatefulWidget {
  final User? existing;
  const EmployeeFormDialog({super.key, this.existing});

  static Future<bool?> show({User? existing}) {
    return Get.dialog<bool>(
      EmployeeFormDialog(existing: existing),
      barrierDismissible: false,
    );
  }

  @override
  State<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends State<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late UserRole _role;
  bool _showPassword = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _firstName = TextEditingController(text: e?.firstName ?? '');
    _lastName = TextEditingController(text: e?.lastName ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _password = TextEditingController();
    _role = e?.role ?? UserRole.user;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateName(String? v, String label) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$label es requerido';
    if (t.length < 2) return '$label debe tener al menos 2 caracteres';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El email es requerido';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(t)) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (_isEdit) return null; // no se cambia aquí
    final t = v ?? '';
    if (t.length < 6) return 'Mínimo 6 caracteres';
    if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(t)) {
      return 'Debe tener mayúscula, minúscula y número';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null; // opcional
    // Backend exige formato Colombia +57XXXXXXXXXX. Dejamos validación
    // mínima, el backend devuelve mensaje claro si es inválido.
    if (!RegExp(r'^\+?[0-9 ]{7,15}$').hasMatch(t)) {
      return 'Teléfono inválido';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = Get.find<EmployeeListController>();

    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    bool ok;
    if (_isEdit) {
      ok = await controller.updateEmployee(
        id: widget.existing!.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: phone,
        role: _role,
      );
    } else {
      ok = await controller.create(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
        phone: phone,
      );
    }
    if (!ok || !mounted) return;
    // Cerramos el dialog usando Navigator.pop con el context del widget
    // en lugar de Get.back: cuando el controller ya disparó un snackbar
    // (Get.snackbar superpuesto), Get.back puede consumir el snackbar
    // en vez del dialog, dejando el modal abierto.
    Navigator.of(context, rootNavigator: true).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeListController>();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Editar empleado' : 'Nuevo empleado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Get.back(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _firstName,
                              label: 'Nombre',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => _validateName(v, 'El nombre'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              controller: _lastName,
                              label: 'Apellido',
                              icon: Icons.badge_outlined,
                              validator: (v) => _validateName(v, 'El apellido'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        enabled: !_isEdit, // email no se cambia tras crear
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        controller: _phone,
                        label: 'Teléfono (opcional)',
                        icon: Icons.phone_outlined,
                        hint: '+57XXXXXXXXXX',
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                      if (!_isEdit) ...[
                        const SizedBox(height: 14),
                        _Field(
                          controller: _password,
                          label: 'Contraseña inicial',
                          icon: Icons.lock_outline_rounded,
                          obscureText: !_showPassword,
                          validator: _validatePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: ElegantLightTheme.textTertiary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                          hint: 'Min 6, mayúscula, minúscula y número',
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Rol',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RoleSelector(
                        selected: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
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
                              controller.isMutating.value ? null : _submit,
                          icon: controller.isMutating.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(_isEdit
                                  ? Icons.save_rounded
                                  : Icons.person_add_alt_1_rounded),
                          label: Text(_isEdit ? 'Guardar cambios' : 'Crear empleado'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ElegantLightTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled
            ? ElegantLightTheme.textPrimary
            : ElegantLightTheme.textTertiary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon,
            color: enabled
                ? ElegantLightTheme.primaryBlue
                : ElegantLightTheme.textTertiary,
            size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: enabled
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.primaryBlue,
            width: 2,
          ),
        ),
        labelStyle: TextStyle(color: ElegantLightTheme.textSecondary),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final roles = [
      (UserRole.admin, 'Administrador', 'Acceso total al sistema',
          Icons.admin_panel_settings_rounded, ElegantLightTheme.errorRed),
      (UserRole.manager, 'Gerente', 'Gestión y reportes',
          Icons.workspace_premium_rounded, ElegantLightTheme.warningOrange),
      (UserRole.user, 'Usuario', 'Operaciones diarias',
          Icons.person_rounded, ElegantLightTheme.primaryBlue),
    ];
    return Column(
      children: roles.map((tuple) {
        final (role, title, subtitle, icon, color) = tuple;
        final isSelected = role == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(role),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color
                      : ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ElegantLightTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: ElegantLightTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: color, size: 22),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
