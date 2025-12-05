// lib/features/suppliers/presentation/widgets/supplier_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/supplier.dart';
import '../controllers/suppliers_controller.dart';

class SupplierFilterWidget extends GetView<SuppliersController> {
  const SupplierFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header compacto
        _buildFilterHeader(context),
        const SizedBox(height: 16),

        // Filtros principales
        _buildStatusFilter(context),
        const SizedBox(height: 12),
        _buildDocumentTypeFilter(context),
        const SizedBox(height: 12),
        _buildAdditionalFilters(context),
      ],
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withOpacity(0.05),
            ElegantLightTheme.primaryBlueLight.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Filtros de Búsqueda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
          Obx(() {
            final filtersInfo = controller.activeFiltersCount;
            return GestureDetector(
              onTap: () {
                controller.clearFilters();
                Get.snackbar(
                  'Filtros limpiados',
                  'Se han restablecido todos los filtros',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                  backgroundColor: ElegantLightTheme.surfaceColor,
                  colorText: ElegantLightTheme.textPrimary,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.accentOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.clear,
                      size: 12,
                      color: ElegantLightTheme.accentOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Limpiar (${filtersInfo['count']})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.accentOrange,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.traffic,
                  size: 16,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Estado del Proveedor',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SupplierStatus.values.map((status) {
                final isSelected = controller.statusFilter.value == status;
                return _buildStatusChip(status, isSelected);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusChip(SupplierStatus status, bool isSelected) {
    Color color;
    LinearGradient gradient;
    String text;
    IconData icon;

    switch (status) {
      case SupplierStatus.active:
        color = Colors.green.shade600;
        gradient = ElegantLightTheme.successGradient;
        text = 'Activo';
        icon = Icons.check_circle;
        break;
      case SupplierStatus.inactive:
        color = ElegantLightTheme.accentOrange;
        gradient = ElegantLightTheme.warningGradient;
        text = 'Inactivo';
        icon = Icons.pause_circle;
        break;
      case SupplierStatus.blocked:
        color = Colors.red.shade600;
        gradient = ElegantLightTheme.errorGradient;
        text = 'Bloqueado';
        icon = Icons.block;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          controller.statusFilter.value = null;
        } else {
          controller.statusFilter.value = status;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient.scale(0.2) : null,
          color: isSelected ? null : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.badge,
                  size: 16,
                  color: ElegantLightTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tipo de Documento',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DocumentType.values.map((docType) {
                final isSelected = controller.documentTypeFilter.value == docType;
                return _buildDocumentTypeChip(docType, isSelected);
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeChip(DocumentType docType, bool isSelected) {
    final color = ElegantLightTheme.primaryBlue;
    final gradient = ElegantLightTheme.primaryGradient;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          controller.documentTypeFilter.value = null;
        } else {
          controller.documentTypeFilter.value = docType;
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient.scale(0.2) : null,
          color: isSelected ? null : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.5)
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getDocumentTypeIcon(docType),
              size: 14,
              color: isSelected ? color : ElegantLightTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              controller.getDocumentTypeText(docType),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient.scale(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.filter_alt,
                  size: 16,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Filtros Adicionales',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBooleanFilterChip(
                label: 'Con Email',
                value: controller.hasEmailFilter,
                icon: Icons.email_outlined,
                color: Colors.blue.shade600,
              ),
              _buildBooleanFilterChip(
                label: 'Con Teléfono',
                value: controller.hasPhoneFilter,
                icon: Icons.phone_outlined,
                color: Colors.green.shade600,
              ),
              _buildBooleanFilterChip(
                label: 'Con Crédito',
                value: controller.hasCreditLimitFilter,
                icon: Icons.credit_card_outlined,
                color: Colors.purple.shade600,
              ),
              _buildBooleanFilterChip(
                label: 'Con Descuento',
                value: controller.hasDiscountFilter,
                icon: Icons.discount_outlined,
                color: ElegantLightTheme.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanFilterChip({
    required String label,
    required RxBool value,
    required IconData icon,
    required Color color,
  }) {
    return Obx(() {
      final isSelected = value.value;
      final gradient = _getGradientForColor(color);

      return GestureDetector(
        onTap: () => value.value = !value.value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? gradient.scale(0.2) : null,
            color: isSelected ? null : ElegantLightTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.5)
                  : ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                size: 14,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  IconData _getDocumentTypeIcon(DocumentType docType) {
    switch (docType) {
      case DocumentType.nit:
        return Icons.business;
      case DocumentType.cc:
        return Icons.credit_card;
      case DocumentType.ce:
        return Icons.badge;
      case DocumentType.passport:
        return Icons.flight;
      case DocumentType.rut:
        return Icons.description;
      case DocumentType.other:
        return Icons.article;
    }
  }

  LinearGradient _getGradientForColor(Color color) {
    if (color == ElegantLightTheme.primaryBlue || color == Colors.blue.shade600) {
      return ElegantLightTheme.primaryGradient;
    } else if (color == Colors.green.shade600) {
      return ElegantLightTheme.successGradient;
    } else if (color == ElegantLightTheme.accentOrange) {
      return ElegantLightTheme.warningGradient;
    } else if (color == Colors.purple.shade600) {
      return LinearGradient(
        colors: [Colors.purple.shade500, Colors.purple.shade700],
      );
    } else {
      return ElegantLightTheme.infoGradient;
    }
  }
}
