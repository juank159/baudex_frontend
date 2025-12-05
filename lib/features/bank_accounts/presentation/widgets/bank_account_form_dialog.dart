// lib/features/bank_accounts/presentation/widgets/bank_account_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../domain/entities/bank_account.dart';

/// Lista de iconos disponibles para cuentas bancarias
class BankAccountIcon {
  final String name;
  final IconData icon;
  final String label;
  final Color color;

  const BankAccountIcon({
    required this.name,
    required this.icon,
    required this.label,
    required this.color,
  });

  static const List<BankAccountIcon> availableIcons = [
    BankAccountIcon(
      name: 'payments',
      icon: Icons.payments_rounded,
      label: 'Efectivo',
      color: Color(0xFF10B981),
    ),
    BankAccountIcon(
      name: 'account_balance',
      icon: Icons.account_balance_rounded,
      label: 'Banco',
      color: Color(0xFF3B82F6),
    ),
    BankAccountIcon(
      name: 'credit_card',
      icon: Icons.credit_card_rounded,
      label: 'Tarjeta',
      color: Color(0xFFF59E0B),
    ),
    BankAccountIcon(
      name: 'phone_android',
      icon: Icons.phone_android_rounded,
      label: 'Digital',
      color: Color(0xFF8B5CF6),
    ),
    BankAccountIcon(
      name: 'savings',
      icon: Icons.savings_rounded,
      label: 'Ahorros',
      color: Color(0xFF14B8A6),
    ),
    BankAccountIcon(
      name: 'wallet',
      icon: Icons.account_balance_wallet_rounded,
      label: 'Billetera',
      color: Color(0xFF6366F1),
    ),
    BankAccountIcon(
      name: 'store',
      icon: Icons.store_rounded,
      label: 'Negocio',
      color: Color(0xFFEC4899),
    ),
    BankAccountIcon(
      name: 'attach_money',
      icon: Icons.attach_money_rounded,
      label: 'Dinero',
      color: Color(0xFF22C55E),
    ),
    BankAccountIcon(
      name: 'currency_exchange',
      icon: Icons.currency_exchange_rounded,
      label: 'Cambio',
      color: Color(0xFFF97316),
    ),
    BankAccountIcon(
      name: 'receipt_long',
      icon: Icons.receipt_long_rounded,
      label: 'Recibos',
      color: Color(0xFF64748B),
    ),
    BankAccountIcon(
      name: 'trending_up',
      icon: Icons.trending_up_rounded,
      label: 'Inversión',
      color: Color(0xFF0EA5E9),
    ),
    BankAccountIcon(
      name: 'local_atm',
      icon: Icons.local_atm_rounded,
      label: 'Cajero',
      color: Color(0xFFEF4444),
    ),
  ];

  static BankAccountIcon? getByName(String? name) {
    if (name == null) return null;
    try {
      return availableIcons.firstWhere((i) => i.name == name);
    } catch (_) {
      return null;
    }
  }

  static IconData getIconData(String? name) {
    final icon = getByName(name);
    return icon?.icon ?? Icons.account_balance_wallet_rounded;
  }

  static Color getIconColor(String? name) {
    final icon = getByName(name);
    return icon?.color ?? const Color(0xFF3B82F6);
  }
}

/// Dialogo elegante para crear o editar una cuenta bancaria
class BankAccountFormDialog extends StatefulWidget {
  final BankAccount? account;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const BankAccountFormDialog({
    super.key,
    this.account,
    required this.onSave,
  });

  @override
  State<BankAccountFormDialog> createState() => _BankAccountFormDialogState();
}

class _BankAccountFormDialogState extends State<BankAccountFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _holderNameController;
  late final TextEditingController _descriptionController;

  late BankAccountType _selectedType;
  late bool _isDefault;
  String? _selectedIcon;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool get isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _bankNameController =
        TextEditingController(text: widget.account?.bankName ?? '');
    _accountNumberController =
        TextEditingController(text: widget.account?.accountNumber ?? '');
    _holderNameController =
        TextEditingController(text: widget.account?.holderName ?? '');
    _descriptionController =
        TextEditingController(text: widget.account?.description ?? '');
    _selectedType = widget.account?.type ?? BankAccountType.cash;
    _isDefault = widget.account?.isDefault ?? false;
    _selectedIcon = widget.account?.icon;

    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _holderNameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = ResponsiveHelper.responsiveValue(
      context,
      mobile: MediaQuery.of(context).size.width * 0.95,
      tablet: 520.0,
      desktop: 560.0,
    );

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.transparent,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ElegantLightTheme.elevatedShadow,
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(context),

                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre de la cuenta
                            _buildElegantTextField(
                              controller: _nameController,
                              label: 'Nombre de la cuenta',
                              hint: 'Ej: Nequi Personal, Bancolombia Ahorros...',
                              icon: Icons.label_outline_rounded,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre es requerido';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Tipo de cuenta
                            _buildTypeSelector(context),

                            const SizedBox(height: 20),

                            // Selector de icono
                            _buildIconSelector(context),

                            const SizedBox(height: 20),

                            // Nombre del banco (opcional)
                            _buildElegantTextField(
                              controller: _bankNameController,
                              label: 'Nombre del banco (opcional)',
                              hint: 'Ej: Bancolombia, Nequi, Daviplata...',
                              icon: Icons.business_rounded,
                            ),

                            const SizedBox(height: 20),

                            // Numero de cuenta (opcional)
                            _buildElegantTextField(
                              controller: _accountNumberController,
                              label: 'Numero de cuenta (opcional)',
                              hint: 'Ej: 123-456789-00',
                              icon: Icons.numbers_rounded,
                            ),

                            const SizedBox(height: 20),

                            // Titular (opcional)
                            _buildElegantTextField(
                              controller: _holderNameController,
                              label: 'Titular de la cuenta (opcional)',
                              hint: 'Nombre del titular',
                              icon: Icons.person_outline_rounded,
                            ),

                            const SizedBox(height: 20),

                            // Descripcion (opcional)
                            _buildElegantTextField(
                              controller: _descriptionController,
                              label: 'Descripcion (opcional)',
                              hint: 'Notas adicionales...',
                              icon: Icons.notes_rounded,
                              maxLines: 2,
                            ),

                            const SizedBox(height: 20),

                            // Cuenta predeterminada
                            _buildDefaultSwitch(context),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  _buildActions(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEditing
                  ? Icons.edit_rounded
                  : Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar Cuenta' : 'Nueva Cuenta Bancaria',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEditing
                      ? 'Modifica los datos de la cuenta'
                      : 'Configura una nueva cuenta de pago',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            color: ElegantLightTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ElegantLightTheme.textTertiary,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: ElegantLightTheme.primaryBlue,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: ElegantLightTheme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ElegantLightTheme.textTertiary.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ElegantLightTheme.textTertiary.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ElegantLightTheme.primaryBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 2,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de cuenta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BankAccountType.values.map((type) {
            final isSelected = type == _selectedType;
            final typeColor = _getTypeColor(type);

            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: ElegantLightTheme.fastAnimation,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [typeColor, typeColor.withOpacity(0.8)],
                        )
                      : null,
                  color: isSelected ? null : ElegantLightTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? typeColor
                        : ElegantLightTheme.textTertiary.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: typeColor.withOpacity(0.3),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 18,
                      color: isSelected
                          ? Colors.white
                          : ElegantLightTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : ElegantLightTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIconSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Icono de la cuenta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withOpacity(0.15),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BankAccountIcon.availableIcons.map((iconData) {
              final isSelected = _selectedIcon == iconData.name;

              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = iconData.name),
                child: Tooltip(
                  message: iconData.label,
                  child: AnimatedContainer(
                    duration: ElegantLightTheme.fastAnimation,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                iconData.color,
                                iconData.color.withOpacity(0.8),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : iconData.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? iconData.color
                            : iconData.color.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: iconData.color.withOpacity(0.4),
                                offset: const Offset(0, 3),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      iconData.icon,
                      size: 24,
                      color: isSelected ? Colors.white : iconData.color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_selectedIcon != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                BankAccountIcon.getIconData(_selectedIcon),
                size: 16,
                color: BankAccountIcon.getIconColor(_selectedIcon),
              ),
              const SizedBox(width: 6),
              Text(
                'Seleccionado: ${BankAccountIcon.getByName(_selectedIcon)?.label ?? ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: ElegantLightTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _selectedIcon = null),
                child: Text(
                  'Quitar',
                  style: TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultSwitch(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isDefault = !_isDefault),
      child: AnimatedContainer(
        duration: ElegantLightTheme.normalAnimation,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _isDefault
              ? LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.15),
                    const Color(0xFFF59E0B).withOpacity(0.05),
                  ],
                )
              : null,
          color: _isDefault ? null : ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isDefault
                ? const Color(0xFFF59E0B).withOpacity(0.4)
                : ElegantLightTheme.textTertiary.withOpacity(0.15),
            width: _isDefault ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: ElegantLightTheme.fastAnimation,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: _isDefault
                    ? ElegantLightTheme.warningGradient
                    : null,
                color: _isDefault
                    ? null
                    : ElegantLightTheme.textTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                color: _isDefault
                    ? Colors.white
                    : ElegantLightTheme.textTertiary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuenta Principal',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _isDefault
                          ? const Color(0xFFB45309)
                          : ElegantLightTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Se seleccionara automaticamente en los pagos',
                    style: TextStyle(
                      fontSize: 12,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: ElegantLightTheme.fastAnimation,
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                gradient: _isDefault
                    ? ElegantLightTheme.warningGradient
                    : null,
                color: _isDefault
                    ? null
                    : ElegantLightTheme.textTertiary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: ElegantLightTheme.fastAnimation,
                    curve: ElegantLightTheme.smoothCurve,
                    left: _isDefault ? 24 : 2,
                    top: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOutlinedButton(
              label: 'Cancelar',
              onPressed: _isLoading ? null : () => Get.back(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElegantButton(
              text: isEditing ? 'Guardar' : (isMobile ? 'Crear' : 'Crear Cuenta'),
              icon: isEditing ? Icons.save_rounded : Icons.add_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handleSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String label,
    VoidCallback? onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(BankAccountType type) {
    switch (type) {
      case BankAccountType.cash:
        return const Color(0xFF10B981);
      case BankAccountType.savings:
        return const Color(0xFF3B82F6);
      case BankAccountType.checking:
        return const Color(0xFF6366F1);
      case BankAccountType.digitalWallet:
        return const Color(0xFF8B5CF6);
      case BankAccountType.creditCard:
        return const Color(0xFFF59E0B);
      case BankAccountType.debitCard:
        return const Color(0xFF14B8A6);
      case BankAccountType.other:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.onSave({
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'bankName': _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        'holderName': _holderNameController.text.trim().isEmpty
            ? null
            : _holderNameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'icon': _selectedIcon,
        'isDefault': _isDefault,
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
