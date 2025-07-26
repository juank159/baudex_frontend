// lib/features/dashboard/presentation/widgets/dashboard_header.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/responsive_builder.dart';

class DashboardHeader extends GetView<DashboardController> {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ResponsiveBuilder(
        mobile: _buildMobileHeader(),
        tablet: _buildTabletHeader(),
        desktop: _buildDesktopHeader(),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      controller.selectedDateRange != null
                          ? _formatDateRange(controller.selectedDateRange!)
                          : 'Resumen general',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildRefreshButton(),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMedium),
        Row(
          children: [
            Expanded(child: _buildDateRangeButton()),
            const SizedBox(width: AppDimensions.spacingSmall),
            _buildClearFiltersButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  controller.selectedDateRange != null
                      ? _formatDateRange(controller.selectedDateRange!)
                      : 'Resumen general del negocio',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMedium),
        _buildDateRangeButton(),
        const SizedBox(width: AppDimensions.spacingSmall),
        _buildClearFiltersButton(),
        const SizedBox(width: AppDimensions.spacingSmall),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTextStyles.headlineLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Text(
                  controller.selectedDateRange != null
                      ? _formatDateRange(controller.selectedDateRange!)
                      : 'Resumen general del negocio',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingLarge),
        _buildDateRangeButton(),
        const SizedBox(width: AppDimensions.spacingSmall),
        _buildClearFiltersButton(),
        const SizedBox(width: AppDimensions.spacingSmall),
        _buildRefreshButton(),
      ],
    );
  }

  Widget _buildDateRangeButton() {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: _showDateRangePicker,
        icon: const Icon(Icons.date_range, size: 18),
        label: Text(
          controller.selectedDateRange != null
              ? 'Cambiar período'
              : 'Seleccionar período',
          style: AppTextStyles.bodyMedium,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return Obx(
      () =>
          controller.selectedDateRange != null
              ? IconButton(
                onPressed: controller.clearFilters,
                icon: const Icon(Icons.clear),
                tooltip: 'Limpiar filtros',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              )
              : const SizedBox.shrink(),
    );
  }

  Widget _buildRefreshButton() {
    return Obx(
      () => IconButton(
        onPressed: controller.isLoading ? null : controller.refreshAll,
        icon: AnimatedRotation(
          turns: controller.isLoading ? 1 : 0,
          duration: const Duration(milliseconds: 1000),
          child: const Icon(Icons.refresh),
        ),
        tooltip: 'Actualizar',
        style: IconButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.primary.withOpacity(0.1),
        ),
      ),
    );
  }

  void _showDateRangePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2);
    final lastDate = now;

    final dateRange = await showDateRangePicker(
      context: Get.context!,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: controller.selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      controller.setDateRange(dateRange);
    }
  }

  String _formatDateRange(DateTimeRange dateRange) {
    final startDate = AppFormatters.formatDate(dateRange.start);
    final endDate = AppFormatters.formatDate(dateRange.end);
    return '$startDate - $endDate';
  }
}
