// lib/features/inventory/presentation/screens/inventory_adjustments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/inventory_adjustments_controller.dart';
import '../widgets/product_search_widget.dart';

class InventoryAdjustmentsScreen
    extends GetView<InventoryAdjustmentsController> {
  const InventoryAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Ajustar Inventario',
      showBackButton: true,
      showDrawer: false,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value &&
              controller.warehouses.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1200;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
              final isMobile = constraints.maxWidth < 600;

              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop
                          ? 1100.0
                          : isTablet
                              ? 860.0
                              : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInstructionsCard(),
                        const SizedBox(height: 16),
                        _buildWarehouseCard(isMobile),
                        const SizedBox(height: 16),
                        _buildProductCard(),
                        Obx(() {
                          if (!controller.hasCurrentBalance) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            children: [
                              const SizedBox(height: 16),
                              if (isDesktop)
                                _buildDesktopLayout()
                              else if (isTablet)
                                _buildTabletLayout()
                              else
                                _buildMobileLayout(),
                              const SizedBox(height: 24),
                              _buildSubmitButton(isMobile),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ──────────────────────── INSTRUCCIONES ────────────────────────

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajuste de Inventario',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Corrija cantidades cuando encuentre diferencias entre el stock '
                  'del sistema y el conteo físico.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ElegantLightTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── ALMACÉN ────────────────────────

  Widget _buildWarehouseCard(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warehouse, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Almacén',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(
                  color: ElegantLightTheme.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() => _buildWarehouseContent(isMobile)),
        ],
      ),
    );
  }

  Widget _buildWarehouseContent(bool isMobile) {
    // Cargando
    if (controller.warehouses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ElegantLightTheme.primaryBlue,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Cargando almacenes...',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    // Auto-seleccionado (un único almacén)
    if (controller.warehouses.length == 1 &&
        controller.selectedWarehouseId.value.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ElegantLightTheme.successGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.successGreen.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: ElegantLightTheme.successGreen,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.selectedWarehouseName.value,
                style: const TextStyle(
                  color: ElegantLightTheme.successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ElegantLightTheme.successGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Auto-seleccionado',
                style: TextStyle(
                  color: ElegantLightTheme.successGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Dropdown para múltiples almacenes
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.warehouse_outlined,
          color: ElegantLightTheme.primaryBlue,
          size: 20,
        ),
        hintText: 'Seleccione un almacén',
        hintStyle: const TextStyle(
          color: ElegantLightTheme.textTertiary,
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.textTertiary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ElegantLightTheme.primaryBlue,
            width: 2,
          ),
        ),
      ),
      value: controller.selectedWarehouseId.value.isNotEmpty
          ? controller.selectedWarehouseId.value
          : null,
      items: controller.warehouses.map((warehouse) {
        return DropdownMenuItem<String>(
          value: warehouse.id,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  warehouse.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ElegantLightTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? warehouseId) {
        if (warehouseId != null) {
          final warehouse = controller.warehouses.firstWhere(
            (w) => w.id == warehouseId,
          );
          controller.setSelectedWarehouse(warehouseId, warehouse.name);
        }
      },
    );
  }

  // ──────────────────────── BÚSQUEDA DE PRODUCTO ────────────────────────

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.search,
                color: ElegantLightTheme.primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Buscar producto',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ProductSearchWidget existente, sin reinventar
          ProductSearchWidget(
            hintText: 'Buscar producto por nombre o SKU...',
            onProductSelected: controller.selectProduct,
            searchFunction: controller.searchProducts,
          ),
          Obx(() {
            if (controller.selectedProductName.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        color: ElegantLightTheme.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.selectedProductName.value,
                          style: const TextStyle(
                            color: ElegantLightTheme.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ──────────────────────── LAYOUTS ADAPTATIVOS ────────────────────────

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildStockCard(),
        const SizedBox(height: 16),
        _buildAdjustmentFormCard(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildAdjustmentFormCard(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildStockCard(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildStockCard(),
              const SizedBox(height: 16),
              _buildAdjustmentFormCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildSummaryCard(),
        ),
      ],
    );
  }

  // ──────────────────────── STOCK ACTUAL ────────────────────────

  Widget _buildStockCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
                controller.selectedWarehouseName.value != 'Seleccionar almacén'
                    ? 'Stock en ${controller.selectedWarehouseName.value}'
                    : 'Stock Actual',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: ElegantLightTheme.textPrimary,
                ),
              )),
          const SizedBox(height: 14),
          Obx(() {
            final balance = controller.currentBalance.value;
            if (balance == null) return const SizedBox.shrink();

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Stock Total',
                        '${balance.totalQuantity}',
                        Icons.inventory,
                        ElegantLightTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        'Disponible',
                        '${balance.availableQuantity}',
                        Icons.check_circle_outline,
                        ElegantLightTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Reservado',
                        '${balance.reservedQuantity}',
                        Icons.lock_outline,
                        ElegantLightTheme.warningOrange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCard(
                        'Valor Total',
                        controller.formatCurrency(balance.totalValue),
                        Icons.monetization_on_outlined,
                        ElegantLightTheme.primaryBlueDark,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ──────────────────────── FORMULARIO DE AJUSTE ────────────────────────

  Widget _buildAdjustmentFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajuste de Cantidad',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Input cantidad con botones +/-
          _buildQuantityRow(),

          const SizedBox(height: 14),

          // Preview del ajuste
          Obx(() => _buildAdjustmentPreview()),

          const SizedBox(height: 14),

          // Costo unitario (condicional)
          Obx(() {
            if (!controller.showUnitCostField) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Costo Unitario',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.unitCostController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: _inputDecoration(
                    label: 'Costo por Unidad',
                    icon: Icons.attach_money,
                  ),
                ),
                const SizedBox(height: 14),
              ],
            );
          }),

          // Razón del ajuste
          _buildReasonSection(),

          const SizedBox(height: 14),

          // Notas
          TextFormField(
            controller: controller.notesController,
            maxLines: 3,
            decoration: _inputDecoration(
              label: 'Notas (Opcional)',
              hint: 'Información adicional sobre el ajuste...',
              icon: Icons.notes,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: ElegantLightTheme.textSecondary,
        fontSize: 13,
      ),
      hintStyle: TextStyle(
        color: ElegantLightTheme.textTertiary.withOpacity(0.8),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: ElegantLightTheme.primaryBlue, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ElegantLightTheme.textTertiary.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: ElegantLightTheme.primaryBlue,
          width: 2,
        ),
      ),
    );
  }

  // ──────────────────────── INPUT CANTIDAD CON +/- ────────────────────────

  Widget _buildQuantityRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cantidad Final',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Botón −
            Obx(() => _buildStepperButton(
                  icon: Icons.remove,
                  enabled: controller.newQuantity.value > 0,
                  onTap: controller.decreaseQuantity,
                  onLongPress: () => _adjustBy(-10),
                )),
            const SizedBox(width: 12),

            // TextField cantidad
            Expanded(
              child: TextFormField(
                controller: controller.newQuantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ElegantLightTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ElegantLightTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Botón +
            _buildStepperButton(
              icon: Icons.add,
              enabled: true,
              onTap: controller.increaseQuantity,
              onLongPress: () => _adjustBy(10),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Mantener presionado +/− para ajustar de 10 en 10',
          style: TextStyle(
            fontSize: 11,
            color: ElegantLightTheme.textTertiary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return GestureDetector(
      onLongPress: enabled ? onLongPress : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: enabled
                  ? ElegantLightTheme.primaryGradient
                  : null,
              color: enabled ? null : ElegantLightTheme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: enabled ? ElegantLightTheme.elevatedShadow : null,
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.white : ElegantLightTheme.textTertiary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  void _adjustBy(int delta) {
    final newVal = controller.newQuantity.value + delta;
    final clamped = newVal < 0 ? 0 : newVal;
    controller.newQuantity.value = clamped;
    controller.newQuantityController.text = clamped.toString();
  }

  // ──────────────────────── PREVIEW AJUSTE ────────────────────────

  Widget _buildAdjustmentPreview() {
    final difference = controller.adjustmentDifference;
    if (difference == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.remove, color: ElegantLightTheme.textTertiary, size: 18),
            SizedBox(width: 8),
            Text(
              'Sin cambios en el inventario',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final color = controller.getAdjustmentColor();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(controller.getAdjustmentIcon(), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.getAdjustmentText(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (controller.adjustmentValue != 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.monetization_on_outlined,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Impacto: ${controller.adjustmentValueText}',
                    style: TextStyle(color: color, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────── RAZÓN DEL AJUSTE ────────────────────────

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons.description_outlined,
              color: ElegantLightTheme.primaryBlue,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Razón del Ajuste',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: ElegantLightTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chips de razones predefinidas
        LayoutBuilder(
          builder: (context, constraints) {
            final chipWidth = constraints.maxWidth > 500
                ? (constraints.maxWidth - 16) / 3
                : (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.adjustmentReasons.map((reason) {
                return Obx(() {
                  final isSelected = controller.reason.value == reason;
                  return SizedBox(
                    width: chipWidth,
                    child: GestureDetector(
                      onTap: () => controller.setReasonFromPredefined(reason),
                      child: AnimatedContainer(
                        duration: ElegantLightTheme.fastAnimation,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? ElegantLightTheme.primaryGradient
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? ElegantLightTheme.primaryBlue
                                : ElegantLightTheme.textTertiary
                                    .withOpacity(0.3),
                          ),
                          boxShadow: isSelected
                              ? ElegantLightTheme.glowShadow
                              : null,
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : ElegantLightTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                });
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 12),

        // Razón personalizada
        TextFormField(
          controller: controller.reasonController,
          maxLines: 2,
          decoration: _inputDecoration(
            label: 'Razón Personalizada (Opcional)',
            hint: 'Si ninguna opción aplica...',
            icon: Icons.edit_note,
          ),
        ),

        const SizedBox(height: 8),

        // Advertencia si falta razón
        Obx(() {
          final noReason = controller.reason.value.isEmpty &&
              controller.reasonController.text.trim().isEmpty;
          if (!noReason) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ElegantLightTheme.warningOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ElegantLightTheme.warningOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.warning_amber_rounded,
                  color: ElegantLightTheme.warningOrange,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seleccione una razón o escriba una personalizada',
                    style: TextStyle(
                      color: ElegantLightTheme.warningOrange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ──────────────────────── RESUMEN (sidebar) ────────────────────────

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del Ajuste',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Obx(() => _buildAdjustmentPreview()),
          const SizedBox(height: 14),
          Obx(() {
            final balance = controller.currentBalance.value;
            if (balance == null) return const SizedBox.shrink();
            return Column(
              children: [
                _buildSummaryRow(
                  'Stock Actual',
                  '${balance.totalQuantity}',
                  Icons.inventory_outlined,
                ),
                _buildSummaryRow(
                  'Nueva Cantidad',
                  '${controller.newQuantity.value}',
                  Icons.edit_outlined,
                ),
                Divider(color: ElegantLightTheme.textTertiary.withOpacity(0.3)),
                _buildSummaryRow(
                  'Diferencia',
                  '${controller.adjustmentDifference}',
                  controller.getAdjustmentIcon(),
                  color: controller.getAdjustmentColor(),
                ),
                if (controller.unitCost.value > 0) ...[
                  Divider(
                    color: ElegantLightTheme.textTertiary.withOpacity(0.3),
                  ),
                  _buildSummaryRow(
                    'Impacto Monetario',
                    controller.adjustmentValueText,
                    Icons.monetization_on_outlined,
                    color: controller.getAdjustmentColor(),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final c = color ?? ElegantLightTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── BOTÓN SUBMIT ────────────────────────

  Widget _buildSubmitButton(bool isMobile) {
    return Obx(() {
      final valid = controller.isFormValid;
      final submitting = controller.isCreating.value;

      Widget button = Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: valid && !submitting
              ? ElegantLightTheme.primaryGradient
              : null,
          color: valid && !submitting ? null : ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: valid && !submitting ? ElegantLightTheme.glowShadow : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: valid && !submitting ? controller.createAdjustment : null,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (submitting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    controller.adjustmentDifference == 0
                        ? Icons.remove
                        : controller.getAdjustmentIcon(),
                    color: valid ? Colors.white : ElegantLightTheme.textTertiary,
                    size: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  submitting
                      ? 'Aplicando...'
                      : controller.submitButtonText,
                  style: TextStyle(
                    color: valid ? Colors.white : ElegantLightTheme.textTertiary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Desktop: centrado con ancho máximo
      if (!isMobile) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(width: double.infinity, child: button),
          ),
        );
      }

      // Mobile: full-width
      return SizedBox(width: double.infinity, child: button);
    });
  }
}
