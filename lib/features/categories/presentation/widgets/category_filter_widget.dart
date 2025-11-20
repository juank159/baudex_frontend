// lib/features/categories/presentation/widgets/category_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/category.dart';
import '../controllers/categories_controller.dart';

class CategoryFilterWidget extends GetView<CategoriesController> {
  const CategoryFilterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header futurista
          _buildFuturisticHeader(context),
          const SizedBox(height: 16),

          // Filtros con diseño elegante
          _buildStatusFilter(context),
          const SizedBox(height: 16),
          _buildParentFilter(context),
          const SizedBox(height: 16),
          _buildSortingOptions(context),
          const SizedBox(height: 16),
          _buildQuickFilters(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFuturisticHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtros Avanzados',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                    ),
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personaliza tu búsqueda',
                  style: TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 36, // Ancho mínimo para solo el ícono
        maxWidth: 80, // Ancho máximo permitido
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.errorGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.errorGradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: controller.clearFilters,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Si hay espacio suficiente, mostrar texto, si no, solo ícono
                final hasSpaceForText = constraints.maxWidth > 60;
                
                if (hasSpaceForText) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.cleaning_services, // Cambiado a ícono de escobita
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Limpiar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Icon(
                    Icons.cleaning_services, // Cambiado a ícono de escobita
                    color: Colors.white,
                    size: 16,
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return _buildFuturisticCard(
      title: 'Estado',
      icon: Icons.toggle_on,
      gradient: ElegantLightTheme.successGradient,
      child: Obx(() {
        return Column(
          children: [
            _buildStatusOption(
              context,
              'Todas',
              null,
              controller.currentStatus == null,
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              context,
              'Activas',
              CategoryStatus.active,
              controller.currentStatus == CategoryStatus.active,
            ),
            const SizedBox(height: 8),
            _buildStatusOption(
              context,
              'Inactivas',
              CategoryStatus.inactive,
              controller.currentStatus == CategoryStatus.inactive,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    CategoryStatus? status,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
          ? ElegantLightTheme.glassGradient
          : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.applyStatusFilter(status),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? ElegantLightTheme.primaryGradient
                        : ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? ElegantLightTheme.textPrimary
                          : ElegantLightTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (status != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: status == CategoryStatus.active
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      status == CategoryStatus.active
                          ? Icons.check_circle
                          : Icons.pause_circle,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentFilter(BuildContext context) {
    return _buildFuturisticCard(
      title: 'Jerarquía',
      icon: Icons.account_tree,
      gradient: ElegantLightTheme.infoGradient,
      child: Obx(() {
        return Column(
          children: [
            _buildHierarchyOption(
              context,
              'Todas las categorías',
              null,
              controller.selectedParentId == null,
            ),
            const SizedBox(height: 8),
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
    );
  }

  Widget _buildHierarchyOption(
    BuildContext context,
    String label,
    String? parentId,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
          ? ElegantLightTheme.glassGradient
          : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: ElegantLightTheme.infoGradient.colors.first.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.applyParentFilter(parentId),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? ElegantLightTheme.infoGradient
                        : ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    parentId == 'parents_only' ? Icons.folder : Icons.folder_open,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? ElegantLightTheme.textPrimary
                          : ElegantLightTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortingOptions(BuildContext context) {
    return _buildFuturisticCard(
      title: 'Ordenar por',
      icon: Icons.sort,
      gradient: ElegantLightTheme.warningGradient,
      child: Obx(() {
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
            const SizedBox(height: 8),
            _buildSortOption(
              context,
              'Nombre (A-Z)',
              'name',
              'ASC',
              controller.sortBy == 'name' && controller.sortOrder == 'ASC',
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              context,
              'Nombre (Z-A)',
              'name',
              'DESC',
              controller.sortBy == 'name' && controller.sortOrder == 'DESC',
            ),
            const SizedBox(height: 8),
            _buildSortOption(
              context,
              'Más recientes',
              'createdAt',
              'DESC',
              controller.sortBy == 'createdAt' &&
                  controller.sortOrder == 'DESC',
            ),
            const SizedBox(height: 8),
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
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String sortBy,
    String sortOrder,
    bool isSelected,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected 
          ? ElegantLightTheme.glassGradient
          : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.3)
              : ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: ElegantLightTheme.warningGradient.colors.first.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.changeSorting(sortBy, sortOrder),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? ElegantLightTheme.warningGradient
                        : ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    sortOrder == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? ElegantLightTheme.textPrimary
                          : ElegantLightTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sortOrder == 'ASC' ? 'A-Z' : 'Z-A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return _buildFuturisticCard(
      title: 'Filtros Rápidos',
      icon: Icons.flash_on,
      gradient: ElegantLightTheme.primaryGradient,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildQuickFilterChip(
            context,
            'Con productos',
            Icons.inventory,
            ElegantLightTheme.successGradient,
            () {
              // TODO: Implementar filtro por categorías con productos
              Get.snackbar('Info', 'Filtro pendiente de implementar');
            },
          ),
          _buildQuickFilterChip(
            context,
            'Sin productos',
            Icons.inventory_2_outlined,
            ElegantLightTheme.errorGradient,
            () {
              // TODO: Implementar filtro por categorías sin productos
              Get.snackbar('Info', 'Filtro pendiente de implementar');
            },
          ),
          _buildQuickFilterChip(
            context,
            'Con subcategorías',
            Icons.account_tree,
            ElegantLightTheme.infoGradient,
            () {
              // TODO: Implementar filtro por categorías padre
              Get.snackbar('Info', 'Filtro pendiente de implementar');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return Container(
      width: 175, // Ancho aumentado para evitar overflow (160 + 15 pixels extra)
      height: 40, // Altura fija para todos los botones
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticCard({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient.colors.first.withValues(alpha: 0.1),
                  gradient.colors.last.withValues(alpha: 0.05),
                ],
              ),
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
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: gradient.colors.first,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
