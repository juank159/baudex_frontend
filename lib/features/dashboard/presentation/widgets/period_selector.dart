// lib/features/dashboard/presentation/widgets/period_selector.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';

class PeriodSelector extends GetView<DashboardController> {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSmall),
          children: [
            _buildPeriodChip('hoy', 'Hoy'),
            const SizedBox(width: AppDimensions.spacingSmall),
            _buildPeriodChip('esta_semana', 'Esta Semana'),
            const SizedBox(width: AppDimensions.spacingSmall),
            _buildPeriodChip('este_mes', 'Este Mes'),
            const SizedBox(width: AppDimensions.spacingMedium),
            _buildCustomDateButton(),
            const SizedBox(width: AppDimensions.paddingSmall), // Espacio extra al final
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = controller.selectedPeriod == period;
    
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          controller.setPredefinedPeriod(period);
        }
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: 1,
      ),
      elevation: isSelected ? 2 : 0,
      pressElevation: 4,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildCustomDateButton() {
    return Container(
      constraints: const BoxConstraints(minWidth: 120), // Asegurar ancho mínimo
      child: OutlinedButton.icon(
        onPressed: () => _showDateRangePicker(),
        icon: Icon(
          Icons.date_range,
          size: 16,
          color: AppColors.primary,
        ),
        label: Text(
          'Personalizado',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked);
      // El setDateRange ya maneja el cambio automáticamente
    }
  }
}