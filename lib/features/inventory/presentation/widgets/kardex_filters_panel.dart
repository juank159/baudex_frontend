// lib/features/inventory/presentation/widgets/kardex_filters_panel.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/core/widgets/custom_date_picker.dart';
import '../controllers/kardex_controller.dart';

class KardexFiltersPanel extends GetView<KardexController> {
  const KardexFiltersPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros de Búsqueda',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Date range filters
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha Inicio',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => CustomDatePicker(
                      selectedDate: controller.startDate.value,
                      hintText: 'Seleccionar fecha',
                      onChanged: (date) {
                        if (date != null) {
                          controller.updateDateRange(
                            date,
                            controller.endDate.value,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Seleccionar fecha',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha Fin',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => CustomDatePicker(
                      selectedDate: controller.endDate.value,
                      hintText: 'Seleccionar fecha',
                      onChanged: (date) {
                        if (date != null) {
                          controller.updateDateRange(
                            controller.startDate.value,
                            date,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Seleccionar fecha',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick date filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip(
                'Últimos 7 días',
                () => controller.updateDateRange(
                  DateTime.now().subtract(const Duration(days: 7)),
                  DateTime.now(),
                ),
              ),
              _buildQuickFilterChip(
                'Últimos 30 días',
                () => controller.updateDateRange(
                  DateTime.now().subtract(const Duration(days: 30)),
                  DateTime.now(),
                ),
              ),
              _buildQuickFilterChip(
                'Este mes',
                () => controller.updateDateRange(
                  DateTime(DateTime.now().year, DateTime.now().month, 1),
                  DateTime.now(),
                ),
              ),
              _buildQuickFilterChip(
                'Últimos 90 días',
                () => controller.updateDateRange(
                  DateTime.now().subtract(const Duration(days: 90)),
                  DateTime.now(),
                ),
              ),
              _buildQuickFilterChip(
                'Este año',
                () => controller.updateDateRange(
                  DateTime(DateTime.now().year, 1, 1),
                  DateTime.now(),
                ),
              ),
              _buildQuickFilterChip(
                'Ver todo',
                () => controller.updateDateRange(
                  DateTime(2020, 1, 1),
                  DateTime.now(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar Filtros'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.loadKardex,
                  icon: const Icon(Icons.search),
                  label: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Get.textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}