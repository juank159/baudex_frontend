// lib/features/suppliers/presentation/screens/suppliers_list_screen.dart
import 'package:baudex_desktop/app/ui/layouts/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/suppliers_controller.dart';
import '../widgets/supplier_card_widget.dart';
import '../widgets/supplier_filter_widget.dart';
import '../widgets/supplier_stats_widget.dart';

class SuppliersListScreen extends GetView<SuppliersController> {
  const SuppliersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Proveedores',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: controller.toggleFilters,
          tooltip: 'Filtros',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshSuppliers,
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToCreateSupplier,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Proveedor'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(),

          // Tabs
          DefaultTabController(length: 2, child: _buildTabs()),

          // Filtros (colapsable)
          Obx(
            () =>
                controller.showFilters.value
                    ? const SupplierFilterWidget()
                    : const SizedBox.shrink(),
          ),

          // Contenido principal
          Expanded(child: Obx(() => _buildContent())),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              label: 'Buscar',
              controller: controller.searchController,
              hint: 'Buscar proveedores...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                controller.searchQuery.value = value;
              },
            ),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Obx(() {
            final filtersInfo = controller.activeFiltersCount;
            return Badge(
              isLabelVisible: filtersInfo['count'] > 0,
              label: Text('${filtersInfo['count']}'),
              child: IconButton(
                icon: Icon(
                  controller.showFilters.value
                      ? Icons.filter_list_off
                      : Icons.filter_list,
                ),
                onPressed: controller.toggleFilters,
                tooltip:
                    controller.showFilters.value
                        ? 'Ocultar filtros'
                        : 'Mostrar filtros',
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        onTap: controller.switchTab,
        tabs: const [
          Tab(icon: Icon(Icons.list), text: 'Lista'),
          Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (controller.selectedTab.value == 0) {
      return _buildSuppliersList();
    } else {
      return _buildStatsView();
    }
  }

  Widget _buildSuppliersList() {
    if (controller.isLoading.value && controller.suppliers.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (controller.error.value.isNotEmpty && controller.suppliers.isEmpty) {
      return _buildErrorState();
    }

    if (!controller.hasResults) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: controller.refreshSuppliers,
      child: Column(
        children: [
          // Header con información de resultados
          _buildResultsHeader(),

          // Lista de proveedores
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              itemCount:
                  controller.displayedSuppliers.length +
                  (controller.canLoadMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.displayedSuppliers.length) {
                  return _buildLoadMoreButton();
                }

                final supplier = controller.displayedSuppliers[index];
                return SupplierCardWidget(
                  supplier: supplier,
                  onTap: () => controller.goToSupplierDetail(supplier.id),
                  onEdit: () => controller.goToSupplierEdit(supplier.id),
                  onDelete: () => controller.deleteSupplier(supplier.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Obx(
              () => Text(
                controller.resultsText,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _showSortOptions,
                tooltip: 'Ordenar',
              ),
              Obx(
                () => Text(
                  'Página ${controller.currentPage.value} de ${controller.totalPages.value}',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Obx(
        () =>
            controller.isLoadingMore.value
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
                  text: 'Cargar más',
                  onPressed: controller.loadNextPage,
                  type: ButtonType.outline,
                ),
      ),
    );
  }

  Widget _buildStatsView() {
    return Obx(() {
      if (controller.stats.value == null && controller.isLoading.value) {
        return const Center(child: LoadingWidget());
      }

      if (controller.stats.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              Text(
                'No hay estadísticas disponibles',
                style: Get.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),
              CustomButton(text: 'Recargar', onPressed: controller.loadStats),
            ],
          ),
        );
      }

      return SupplierStatsWidget(stats: controller.stats.value!);
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'No se encontraron proveedores'
                : 'No hay proveedores registrados',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Comienza agregando tu primer proveedor',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          if (controller.searchQuery.value.isNotEmpty)
            CustomButton(
              text: 'Limpiar búsqueda',
              onPressed: () {
                controller.searchController.clear();
                controller.searchQuery.value = '';
              },
              type: ButtonType.outline,
            )
          else
            CustomButton(
              text: 'Agregar Proveedor',
              onPressed: controller.goToCreateSupplier,
              icon: Icons.add,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Error al cargar proveedores',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
            ),
            child: Obx(
              () => Text(
                controller.error.value,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: 'Reintentar',
            onPressed: controller.reloadSuppliers,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusMedium),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ordenar por', style: Get.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.paddingMedium),
            _buildSortOption('name', 'Nombre'),
            _buildSortOption('createdAt', 'Fecha de creación'),
            _buildSortOption('updatedAt', 'Última actualización'),
            _buildSortOption('paymentTermsDays', 'Términos de pago'),
            _buildSortOption('creditLimit', 'Límite de crédito'),
            const SizedBox(height: AppDimensions.paddingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String field, String label) {
    return Obx(
      () => ListTile(
        title: Text(label),
        trailing:
            controller.sortBy.value == field
                ? Icon(
                  controller.sortOrder.value == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: AppColors.primary,
                )
                : null,
        selected: controller.sortBy.value == field,
        onTap: () {
          controller.sortSuppliers(field);
          Get.back();
        },
      ),
    );
  }
}
