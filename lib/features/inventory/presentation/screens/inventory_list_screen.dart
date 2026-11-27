// lib/features/inventory/presentation/screens/inventory_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../widgets/inventory_states.dart';
import '../controllers/inventory_controller.dart';
import '../inventory_adjust_access.dart';
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
        // Movimiento manual y ajuste: solo el administrador
        // (`canCreateManualMovement` / `canAdjustInventory`). Sin ninguno de
        // los dos, no se muestra el botón "Crear".
        if (sessionCanCreateManualMovement() || sessionCanAdjustInventory())
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
              if (sessionCanCreateManualMovement())
                const PopupMenuItem(
                  value: 'movement',
                  child: ListTile(
                    leading: Icon(Icons.swap_horiz),
                    title: Text('Movimiento'),
                    dense: true,
                  ),
                ),
              // Ajustes: solo el administrador (regla `canAdjustInventory`).
              if (sessionCanAdjustInventory())
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
      body: ColoredBox(
        color: ElegantLightTheme.backgroundColor,
        child: Column(
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          filled: true,
          fillColor: ElegantLightTheme.surfaceColor,
          prefixIcon: const Icon(Icons.search, color: ElegantLightTheme.primaryBlue),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: ElegantLightTheme.textSecondary),
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    controller.searchController.clear();
                    controller.searchQuery.value = '';
                  },
                )
              : const SizedBox.shrink()),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: ElegantLightTheme.primaryBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ElegantLightTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.25),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => _buildTabButton(
              text: 'Balances',
              icon: Icons.inventory_2_outlined,
              index: 0,
              isSelected: controller.selectedTab.value == 0,
            )),
          ),
          Expanded(
            child: Obx(() => _buildTabButton(
              text: 'Movimientos',
              icon: Icons.swap_horiz,
              index: 1,
              isSelected: controller.selectedTab.value == 1,
            )),
          ),
          Expanded(
            child: Obx(() => _buildTabButton(
              text: 'Estadísticas',
              icon: Icons.insights_outlined,
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
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    final color = isSelected ? Colors.white : ElegantLightTheme.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
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
      return const InventoryLoadingState('Cargando inventario...');
    }

    if (controller.error.value.isNotEmpty) {
      return InventoryErrorState(
        title: 'No se pudo cargar el inventario',
        message: friendlyInventoryError(controller.error.value, what: 'el inventario'),
        onRetry: () => controller.loadBalances(),
      );
    }

    if (!controller.hasResults) {
      return InventoryEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No hay productos en inventario',
        actionIcon: Icons.add,
        message: controller.searchQuery.value.isNotEmpty
            ? 'No se encontraron productos que coincidan con tu búsqueda'
            : 'Aún no hay productos registrados en el inventario',
        // Movimiento manual: solo el administrador.
        actionLabel:
            sessionCanCreateManualMovement() ? 'Crear movimiento' : null,
        onAction: sessionCanCreateManualMovement()
            ? controller.goToCreateMovement
            : null,
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
      return const InventoryLoadingState('Cargando movimientos...');
    }

    if (controller.error.value.isNotEmpty) {
      return InventoryErrorState(
        title: 'No se pudieron cargar los movimientos',
        message: friendlyInventoryError(controller.error.value, what: 'los movimientos'),
        onRetry: () => controller.loadMovements(),
      );
    }

    if (!controller.hasResults) {
      return InventoryEmptyState(
        icon: Icons.swap_horiz,
        title: 'No hay movimientos de inventario',
        actionIcon: Icons.add,
        message: controller.searchQuery.value.isNotEmpty
            ? 'No se encontraron movimientos que coincidan con tu búsqueda'
            : 'Aún no hay movimientos registrados',
        // Movimiento manual: solo el administrador.
        actionLabel:
            sessionCanCreateManualMovement() ? 'Crear movimiento' : null,
        onAction: sessionCanCreateManualMovement()
            ? controller.goToCreateMovement
            : null,
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
      return const InventoryLoadingState('Cargando estadísticas...');
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
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
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
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count filtro${count > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.primaryBlue,
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
            const BrebInlineLoading('Cargando más...')
          else
            OutlinedButton(
              onPressed: controller.loadNextPage,
              style: brebSecondaryButtonStyle(),
              child: const Text('Cargar más'),
            ),
        ],
      ),
    );
  }
}