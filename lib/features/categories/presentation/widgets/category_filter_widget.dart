// lib/features/categories/presentation/widgets/category_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../domain/entities/category.dart';
import '../controllers/categories_controller.dart';

class CategoryFilterWidget extends GetView<CategoriesController> {
  const CategoryFilterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.clearFilters,
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ),

        // Filtros
        _buildStatusFilter(context),
        const SizedBox(height: 16),
        _buildParentFilter(context),
        const SizedBox(height: 16),
        _buildSortingOptions(context),
        const SizedBox(height: 16),
        _buildQuickFilters(context),
      ],
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.toggle_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Estado',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Column(
              children: [
                _buildStatusOption(
                  context,
                  'Todas',
                  null,
                  controller.currentStatus == null,
                ),
                _buildStatusOption(
                  context,
                  'Activas',
                  CategoryStatus.active,
                  controller.currentStatus == CategoryStatus.active,
                ),
                _buildStatusOption(
                  context,
                  'Inactivas',
                  CategoryStatus.inactive,
                  controller.currentStatus == CategoryStatus.inactive,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    CategoryStatus? status,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => controller.applyStatusFilter(status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (status != null) ...[
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      status == CategoryStatus.active
                          ? Colors.green
                          : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParentFilter(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Jerarquía',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Column(
              children: [
                _buildHierarchyOption(
                  context,
                  'Todas las categorías',
                  null,
                  controller.selectedParentId == null,
                ),
                _buildHierarchyOption(
                  context,
                  'Solo categorías padre',
                  'parents_only',
                  controller.selectedParentId == 'parents_only',
                ),
                // TODO: Cargar categorías padre dinámicamente
                // for (final parent in controller.parentCategories)
                //   _buildHierarchyOption(context, parent.name, parent.id, false),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHierarchyOption(
    BuildContext context,
    String label,
    String? parentId,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => controller.applyParentFilter(parentId),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortingOptions(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sort, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Column(
              children: [
                _buildSortOption(
                  context,
                  'Orden personalizado',
                  'sortOrder',
                  'ASC',
                  controller.sortBy == 'sortOrder' &&
                      controller.sortOrder == 'ASC',
                ),
                _buildSortOption(
                  context,
                  'Nombre (A-Z)',
                  'name',
                  'ASC',
                  controller.sortBy == 'name' && controller.sortOrder == 'ASC',
                ),
                _buildSortOption(
                  context,
                  'Nombre (Z-A)',
                  'name',
                  'DESC',
                  controller.sortBy == 'name' && controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Más recientes',
                  'createdAt',
                  'DESC',
                  controller.sortBy == 'createdAt' &&
                      controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Más antiguos',
                  'createdAt',
                  'ASC',
                  controller.sortBy == 'createdAt' &&
                      controller.sortOrder == 'ASC',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String sortBy,
    String sortOrder,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => controller.changeSorting(sortBy, sortOrder),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                sortOrder == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtros rápidos',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip(
                context,
                'Con productos',
                Icons.inventory,
                () {
                  // TODO: Implementar filtro por categorías con productos
                  Get.snackbar('Info', 'Filtro pendiente de implementar');
                },
              ),
              _buildQuickFilterChip(
                context,
                'Sin productos',
                Icons.inventory_2_outlined,
                () {
                  // TODO: Implementar filtro por categorías sin productos
                  Get.snackbar('Info', 'Filtro pendiente de implementar');
                },
              ),
              _buildQuickFilterChip(
                context,
                'Con subcategorías',
                Icons.account_tree,
                () {
                  // TODO: Implementar filtro por categorías padre
                  Get.snackbar('Info', 'Filtro pendiente de implementar');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }
}
