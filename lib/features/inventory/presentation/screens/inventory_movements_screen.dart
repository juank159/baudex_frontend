// lib/features/inventory/presentation/screens/inventory_movements_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/inventory_movements_controller.dart';
import '../widgets/inventory_movement_card_widget.dart';
import '../widgets/inventory_movements_filter_widget.dart';

class InventoryMovementsScreen extends GetView<InventoryMovementsController> {
  const InventoryMovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Movimientos de Inventario',
      showBackButton: true,
      showDrawer: false,
      actions: [
        Obx(() {
          return IconButton(
            icon: Icon(
              controller.showFilters.value ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: controller.toggleFilters,
            tooltip: controller.showFilters.value 
                ? 'Ocultar filtros'
                : 'Mostrar filtros',
          );
        }),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshMovements,
          tooltip: 'Actualizar',
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
      ],
      body: Column(
        children: [
          // Filter section
          Obx(() => controller.showFilters.value 
              ? const InventoryMovementsFilterWidget()
              : const SizedBox.shrink()),
          
          // Results header
          _buildResultsHeader(),
          
          // Movements list
          Expanded(
            child: Obx(() => _buildContent()),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => Text(
              controller.resultsText,
              style: Get.textTheme.titleSmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            )),
          ),
          Obx(() {
            final activeFilters = controller.activeFiltersCount;
            if (activeFilters['count'] > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSmall,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  '${activeFilters['count']} filtros activos',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isLoading.value && controller.movements.isEmpty) {
      return const Center(child: LoadingWidget());
    }

    if (controller.error.value.isNotEmpty && controller.movements.isEmpty) {
      return _buildErrorState();
    }

    if (!controller.hasResults && !controller.isLoading.value) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: controller.refreshMovements,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        itemCount: controller.displayedMovements.length + 
                   (controller.canLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= controller.displayedMovements.length) {
            // Load more indicator
            if (controller.isLoadingMore.value) {
              return const Padding(
                padding: EdgeInsets.all(AppDimensions.paddingMedium),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: CustomButton(
                  text: 'Cargar más',
                  onPressed: controller.loadNextPage,
                  type: ButtonType.outline,
                ),
              );
            }
          }

          final movement = controller.displayedMovements[index];
          return InventoryMovementCardWidget(
            movement: movement,
            onTap: () => controller.goToMovementDetail(movement),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'No hay movimientos de inventario',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'No hay movimientos registrados para este producto',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Error al cargar movimientos',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
            ),
            child: Obx(() => Text(
              controller.error.value,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            )),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: 'Reintentar',
            onPressed: controller.refreshMovements,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }


  void _confirmMovement(String movementId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Movimiento'),
        content: const Text(
          '¿Está seguro de que desea confirmar este movimiento de inventario?\n\n'
          'Esta acción afectará el stock del producto y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.confirmMovement(movementId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _cancelMovement(String movementId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancelar Movimiento'),
        content: const Text(
          '¿Está seguro de que desea cancelar este movimiento de inventario?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.cancelMovement(movementId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancelar Movimiento'),
          ),
        ],
      ),
    );
  }
}