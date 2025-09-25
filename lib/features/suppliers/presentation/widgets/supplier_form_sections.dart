// lib/features/suppliers/presentation/widgets/supplier_form_sections.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_dropdown.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
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
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
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
                  color: AppColors.primary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
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
              ? color.withOpacity(0.2) 
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

class CurrencySelectorWidget extends StatelessWidget {
  final String selectedCurrency;
  final Function(String) onChanged;
  final List<String> currencies = [
    'COP', 'USD', 'EUR', 'CAD', 'GBP', 'JPY', 'AUD', 'CHF'
  ];

  CurrencySelectorWidget({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CustomDropdown<String>(
      value: selectedCurrency.isNotEmpty ? selectedCurrency : null,
      label: 'Moneda *',
      hintText: 'Seleccionar moneda',
      prefixIcon: const Icon(Icons.monetization_on),
      isRequired: true,
      items: currencies.map((currency) => DropdownMenuItem(
        value: currency,
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  currency,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(currency),
          ],
        ),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class PaymentTermsWidget extends StatelessWidget {
  final TextEditingController controller;
  final List<int> commonTerms = [15, 30, 45, 60, 90];

  PaymentTermsWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: controller,
          label: 'Términos de pago (días) *',
          hint: '30',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Campo requerido';
            final days = int.tryParse(value!);
            if (days == null || days <= 0) return 'Debe ser un número positivo';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: commonTerms.map((days) => ActionChip(
            label: Text('$days días'),
            onPressed: () => controller.text = days.toString(),
            backgroundColor: controller.text == days.toString()
                ? AppColors.primary.withOpacity(0.2)
                : Colors.grey.shade100,
          )).toList(),
        ),
      ],
    );
  }
}