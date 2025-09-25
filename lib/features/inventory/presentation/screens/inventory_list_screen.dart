// lib/features/inventory/presentation/screens/inventory_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/ui/components/loaders/custom_loading_indicator.dart';
import '../../../../app/ui/components/empty_states/custom_empty_state.dart';
import '../../../../app/ui/components/errors/custom_error_widget.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/inventory_filter_widget.dart';
import '../widgets/inventory_balance_card_widget.dart';
import '../widgets/inventory_movement_card_widget.dart';
import '../widgets/inventory_stats_widget.dart';

class InventoryListScreen extends GetView<InventoryController> {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Inventario',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: controller.toggleFilters,
          tooltip: 'Filtros',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshData,
          tooltip: 'Actualizar',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.add),
          tooltip: 'Crear',
          onSelected: (value) {
            switch (value) {
              case 'movement':
                controller.goToCreateMovement();
                break;
              case 'adjustment':
                controller.goToCreateAdjustment();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'movement',
              child: ListTile(
                leading: Icon(Icons.swap_horiz),
                title: Text('Movimiento'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'adjustment',
              child: ListTile(
                leading: Icon(Icons.tune),
                title: Text('Ajuste'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Filters
          Obx(() => controller.showFilters.value
              ? const InventoryFilterWidget()
              : const SizedBox.shrink()),
          
          // Tabs
          _buildTabBar(),
          
          // Content
          Expanded(
            child: Obx(() => _buildTabContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.searchController.clear();
                    controller.searchQuery.value = '';
                  },
                )
              : const SizedBox.shrink()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildTabButton(
              text: 'Balances',
              index: 0,
              isSelected: controller.selectedTab.value == 0,
            )),
          ),
          Expanded(
            child: Obx(() => _buildTabButton(
              text: 'Movimientos',
              index: 1,
              isSelected: controller.selectedTab.value == 1,
            )),
          ),
          Expanded(
            child: Obx(() => _buildTabButton(
              text: 'Estadísticas',
              index: 2,
              isSelected: controller.selectedTab.value == 2,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String text,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.switchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected 
                  ? Get.theme.colorScheme.primary 
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Get.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? Get.theme.colorScheme.primary 
                : Get.theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (controller.selectedTab.value) {
      case 0:
        return _buildBalancesTab();
      case 1:
        return _buildMovementsTab();
      case 2:
        return _buildStatsTab();
      default:
        return _buildBalancesTab();
    }
  }

  Widget _buildBalancesTab() {
    if (controller.isLoading.value && controller.balances.isEmpty) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (controller.error.value.isNotEmpty) {
      return CustomErrorWidget(
        message: controller.error.value,
        onRetry: () => controller.loadBalances(),
      );
    }

    if (!controller.hasResults) {
      return CustomEmptyState(
        icon: Icons.inventory,
        title: 'No hay productos en inventario',
        subtitle: controller.searchQuery.value.isNotEmpty
            ? 'No se encontraron productos que coincidan con tu búsqueda'
            : 'Aún no hay productos registrados en el inventario',
        actionText: 'Crear movimiento',
        onAction: controller.goToCreateMovement,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: Column(
        children: [
          // Results summary
          _buildResultsSummary(),
          
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: controller.displayedBalances.length + 
                         (controller.canLoadMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.displayedBalances.length) {
                  // Load more indicator
                  return _buildLoadMoreIndicator();
                }

                final balance = controller.displayedBalances[index];
                return InventoryBalanceCardWidget(
                  balance: balance,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsTab() {
    if (controller.isLoading.value && controller.movements.isEmpty) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (controller.error.value.isNotEmpty) {
      return CustomErrorWidget(
        message: controller.error.value,
        onRetry: () => controller.loadMovements(),
      );
    }

    if (!controller.hasResults) {
      return CustomEmptyState(
        icon: Icons.swap_horiz,
        title: 'No hay movimientos de inventario',
        subtitle: controller.searchQuery.value.isNotEmpty
            ? 'No se encontraron movimientos que coincidan con tu búsqueda'
            : 'Aún no hay movimientos registrados',
        actionText: 'Crear movimiento',
        onAction: controller.goToCreateMovement,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: Column(
        children: [
          // Results summary
          _buildResultsSummary(),
          
          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.displayedMovements.length + 
                         (controller.canLoadMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.displayedMovements.length) {
                  // Load more indicator
                  return _buildLoadMoreIndicator();
                }

                final movement = controller.displayedMovements[index];
                return InventoryMovementCardWidget(
                  movement: movement,
                  onTap: () => controller.goToMovementDetail(movement.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (controller.stats.value == null) {
      return const Center(child: CustomLoadingIndicator());
    }

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: InventoryStatsWidget(
          stats: controller.stats.value!,
        ),
      ),
    );
  }

  Widget _buildResultsSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.resultsText,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Active filters indicator
          Obx(() {
            final activeFilters = controller.activeFiltersCount;
            final count = activeFilters['count'] as int;
            
            if (count == 0) return const SizedBox.shrink();
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count filtro${count > 1 ? 's' : ''}',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onPrimaryContainer,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (controller.isLoadingMore.value)
            const CustomLoadingIndicator()
          else
            ElevatedButton(
              onPressed: controller.loadNextPage,
              child: const Text('Cargar más'),
            ),
        ],
      ),
    );
  }
}