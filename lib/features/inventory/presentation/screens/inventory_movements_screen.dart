// lib/features/inventory/presentation/screens/inventory_movements_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/inventory_movements_controller.dart';
import '../widgets/inventory_movement_card_widget.dart';
import '../widgets/inventory_movements_filter_widget.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../widgets/inventory_states.dart';

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
      body: ColoredBox(
        color: ElegantLightTheme.backgroundColor,
        child: Column(
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
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => Text(
              controller.resultsText,
              style: Get.textTheme.titleSmall?.copyWith(
                color: ElegantLightTheme.textSecondary,
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
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Text(
                  '${activeFilters['count']} filtros activos',
                  style: TextStyle(
                    color: ElegantLightTheme.primaryBlue,
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
      return const InventoryLoadingState('Cargando movimientos...');
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
                child: Center(child: BrebInlineLoading('Cargando más movimientos...')),
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
    return const InventoryEmptyState(
      icon: Icons.swap_horiz,
      title: 'No hay movimientos de inventario',
      message: 'Cuando entre o salga mercancía, aquí verás cada movimiento.',
    );
  }

  Widget _buildErrorState() {
    return Obx(() => InventoryErrorState(
          title: 'No se pudieron cargar los movimientos',
          message: friendlyInventoryError(
            controller.error.value,
            what: 'los movimientos',
          ),
          onRetry: controller.refreshMovements,
        ));
  }

  void _confirmMovement(String movementId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ElegantLightTheme.surfaceColor,
        shape: brebDialogShape,
        title: brebDialogTitle(
          Icons.check_circle_outline,
          'Confirmar movimiento',
          gradient: ElegantLightTheme.successGradient,
        ),
        content: const Text(
          '¿Está seguro de que desea confirmar este movimiento de inventario?\n\n'
          'Esta acción afectará el stock del producto y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: brebTextButtonStyle(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.confirmMovement(movementId);
            },
            style: brebPrimaryButtonStyle(color: ElegantLightTheme.successGreen),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _cancelMovement(String movementId) {
    Get.dialog(
      AlertDialog(
        backgroundColor: ElegantLightTheme.surfaceColor,
        shape: brebDialogShape,
        title: brebDialogTitle(
          Icons.cancel_outlined,
          'Cancelar movimiento',
          gradient: ElegantLightTheme.errorGradient,
        ),
        content: const Text(
          '¿Está seguro de que desea cancelar este movimiento de inventario?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: brebTextButtonStyle(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.cancelMovement(movementId);
            },
            style: brebPrimaryButtonStyle(color: ElegantLightTheme.errorRed),
            child: const Text('Cancelar Movimiento'),
          ),
        ],
      ),
    );
  }
}