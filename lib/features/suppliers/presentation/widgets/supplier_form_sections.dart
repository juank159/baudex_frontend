// lib/features/suppliers/presentation/widgets/supplier_form_sections.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/supplier.dart';

class FormSectionWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool isCollapsible;
  final bool initiallyExpanded;

  const FormSectionWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.children,
    this.isCollapsible = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsible) {
      return Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            expansionTileTheme: const ExpansionTileThemeData(
              tilePadding: EdgeInsets.zero,
            ),
          ),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            title: _buildSectionHeader(),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  children: children,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(),
            const SizedBox(height: AppDimensions.paddingMedium),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: ElegantLightTheme.glowShadow,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppDimensions.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class FormRowWidget extends StatelessWidget {
  final List<Widget> children;
  final List<int>? flex;

  const FormRowWidget({
    super.key,
    required this.children,
    this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(children.length, (index) {
        final child = children[index];
        final flexValue = flex != null && index < flex!.length ? flex![index] : 1;

        return Expanded(
          flex: flexValue,
          child: Padding(
            padding: EdgeInsets.only(
              right: index < children.length - 1 ? AppDimensions.paddingMedium : 0,
            ),
            child: child,
          ),
        );
      }),
    );
  }
}

class StatusChipWidget extends StatelessWidget {
  final SupplierStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const StatusChipWidget({
    super.key,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(status),
              color: isSelected ? color : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _getStatusText(status),
              style: Get.textTheme.bodyMedium?.copyWith(
                color: isSelected ? color : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Colors.green;
      case SupplierStatus.inactive:
        return Colors.orange;
      case SupplierStatus.blocked:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Icons.check_circle;
      case SupplierStatus.inactive:
        return Icons.pause_circle;
      case SupplierStatus.blocked:
        return Icons.block;
    }
  }

  String _getStatusText(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return 'Activo';
      case SupplierStatus.inactive:
        return 'Inactivo';
      case SupplierStatus.blocked:
        return 'Bloqueado';
    }
  }
}

// Widget moderno para selector de moneda siguiendo el patrón de ModernSelectorWidget
class CurrencySelectorWidget extends StatelessWidget {
  final String selectedCurrency;
  final Function(String) onChanged;
  final List<String> currencies = const [
    'COP', 'USD', 'EUR', 'CAD', 'GBP', 'JPY', 'AUD', 'CHF'
  ];

  const CurrencySelectorWidget({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCurrencySelector(context),
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: const EdgeInsets.all(16),
          gradient: ElegantLightTheme.cardGradient,
          child: Row(
            children: [
              // Icono con gradiente en contenedor circular
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Label y valor con tipografía elegante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Moneda *',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCurrency.isNotEmpty
                          ? selectedCurrency
                          : 'Seleccionar moneda',
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedCurrency.isNotEmpty
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                        fontWeight: selectedCurrency.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Icono de dropdown con fondo azul translúcido
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: ElegantLightTheme.primaryBlue,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente azul
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.monetization_on,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seleccionar Moneda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de opciones con animaciones
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final currency = currencies[index];
                    final isSelected = currency == selectedCurrency;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onChanged(currency);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                                        ElegantLightTheme.primaryBlueLight.withValues(alpha: 0.05),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? ElegantLightTheme.primaryBlue
                                    : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Texto
                                Expanded(
                                  child: Text(
                                    currency,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? ElegantLightTheme.primaryBlue
                                          : ElegantLightTheme.textPrimary,
                                    ),
                                  ),
                                ),

                                // Opción seleccionada con gradiente y check icon
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: ElegantLightTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: ElegantLightTheme.glowShadow,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Padding inferior para el gesto
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget moderno para términos de pago siguiendo el patrón de ModernSelectorWidget
class PaymentTermsWidget extends StatelessWidget {
  final TextEditingController controller;
  final List<int> commonTerms = const [15, 30, 45, 60, 90];

  const PaymentTermsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showPaymentTermsSelector(context),
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: const EdgeInsets.all(16),
          gradient: ElegantLightTheme.cardGradient,
          child: Row(
            children: [
              // Icono con gradiente en contenedor circular
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Label y valor con tipografía elegante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Términos de pago (días) *',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.text.isNotEmpty
                          ? '${controller.text} días'
                          : 'Seleccionar días',
                      style: TextStyle(
                        fontSize: 16,
                        color: controller.text.isNotEmpty
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                        fontWeight: controller.text.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Icono de dropdown con fondo azul translúcido
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: ElegantLightTheme.primaryBlue,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentTermsSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente azul
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seleccionar Términos de Pago',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de opciones con animaciones
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: commonTerms.length,
                  itemBuilder: (context, index) {
                    final days = commonTerms[index];
                    final isSelected = controller.text == days.toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            controller.text = days.toString();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                                        ElegantLightTheme.primaryBlueLight.withValues(alpha: 0.05),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? ElegantLightTheme.primaryBlue
                                    : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Texto
                                Expanded(
                                  child: Text(
                                    '$days días',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? ElegantLightTheme.primaryBlue
                                          : ElegantLightTheme.textPrimary,
                                    ),
                                  ),
                                ),

                                // Opción seleccionada con gradiente y check icon
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: ElegantLightTheme.primaryGradient,
                                      shape: BoxShape.circle,
                                      boxShadow: ElegantLightTheme.glowShadow,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Padding inferior para el gesto
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget moderno para selector de estado del proveedor siguiendo el patrón de ModernSelectorWidget
class StatusSelectorWidget extends StatelessWidget {
  final SupplierStatus selectedStatus;
  final Function(SupplierStatus) onChanged;

  const StatusSelectorWidget({
    super.key,
    required this.selectedStatus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showStatusSelector(context),
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: const EdgeInsets.all(16),
          gradient: ElegantLightTheme.cardGradient,
          child: Row(
            children: [
              // Icono con gradiente en contenedor circular
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: _getStatusGradient(selectedStatus),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  _getStatusIcon(selectedStatus),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Label y valor con tipografía elegante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Estado del Proveedor *',
                      style: TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(selectedStatus),
                      style: const TextStyle(
                        fontSize: 16,
                        color: ElegantLightTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Icono de dropdown con fondo translúcido
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getStatusGradient(selectedStatus).colors.first.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: _getStatusGradient(selectedStatus).colors.first,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: _getStatusGradient(selectedStatus),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(selectedStatus),
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seleccionar Estado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de opciones con animaciones
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: SupplierStatus.values.length,
                  itemBuilder: (context, index) {
                    final status = SupplierStatus.values[index];
                    final isSelected = status == selectedStatus;
                    final gradient = _getStatusGradient(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onChanged(status);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        gradient.colors.first.withValues(alpha: 0.1),
                                        gradient.colors.last.withValues(alpha: 0.05),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? gradient.colors.first
                                    : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Icono del estado
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? gradient : null,
                                    color: isSelected ? null : gradient.colors.first.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    size: 18,
                                    color: isSelected ? Colors.white : gradient.colors.first,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Texto
                                Expanded(
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? gradient.colors.first
                                          : ElegantLightTheme.textPrimary,
                                    ),
                                  ),
                                ),

                                // Opción seleccionada con gradiente y check icon
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      gradient: gradient,
                                      shape: BoxShape.circle,
                                      boxShadow: ElegantLightTheme.glowShadow,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Padding inferior para el gesto
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _getStatusGradient(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return ElegantLightTheme.successGradient;
      case SupplierStatus.inactive:
        return ElegantLightTheme.warningGradient;
      case SupplierStatus.blocked:
        return ElegantLightTheme.errorGradient;
    }
  }

  IconData _getStatusIcon(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Icons.check_circle;
      case SupplierStatus.inactive:
        return Icons.pause_circle;
      case SupplierStatus.blocked:
        return Icons.block;
    }
  }

  String _getStatusText(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return 'Activo';
      case SupplierStatus.inactive:
        return 'Inactivo';
      case SupplierStatus.blocked:
        return 'Bloqueado';
    }
  }
}
