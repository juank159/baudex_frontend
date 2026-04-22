// lib/features/purchase_orders/presentation/screens/purchase_order_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/shared/widgets/app_scaffold.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/purchase_order_form_controller.dart';
import '../../domain/entities/purchase_order.dart';
import '../widgets/supplier_selector_widget.dart';
import '../widgets/product_selector_widget.dart';
import '../widgets/product_item_form_widget.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';

class PurchaseOrderFormScreen extends GetView<PurchaseOrderFormController> {
  const PurchaseOrderFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => AppScaffold(
      includeDrawer: false, // Quitar drawer
      appBar: AppBarBuilder.buildGradient(
        title: controller.titleText,
        automaticallyImplyLeading: true, // Solo arrow back
        gradientColors: [
          ElegantLightTheme.primaryGradient.colors.first,
          ElegantLightTheme.primaryGradient.colors.last,
          ElegantLightTheme.primaryBlue,
        ],
        actions: [
          const SyncStatusIcon(),
          if (!controller.isLoading.value)
            TextButton(
              onPressed: controller.clearForm,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Limpiar'),
            ),
          const SizedBox(width: AppDimensions.paddingSmall),
        ],
      ),
      body: controller.isLoading.value
          ? const Center(child: LoadingWidget())
          : _buildFormContent(),
    ));
  }

  Widget _buildFormContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              // Stepper progress indicator
              _buildStepperHeader(),
              
              // Form content with responsive constraints
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1000 : isTablet ? 800 : double.infinity,
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : isTablet ? 24 : 0,
                  ),
                  child: Form(
                    key: controller.formKey,
                    child: _buildCurrentStepContent(),
                  ),
                ),
              ),
              
              // Navigation buttons with responsive styling
              _buildNavigationButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepperHeader() {
    final stepIcons = [Icons.store, Icons.inventory_2, Icons.note_add];
    final stepLabels = ['Básica', 'Productos', 'Adicional'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          for (int i = 0; i < 3; i++) ...[
            Expanded(
              child: Obx(() {
                final isActive = controller.currentStep.value == i;
                final isDone = controller.currentStep.value > i;
                return GestureDetector(
                  onTap: () => controller.goToStep(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isActive || isDone
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : Icon(stepIcons[i], color: Colors.white, size: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            stepLabels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? AppColors.primary
                                  : isDone
                                      ? AppColors.primary.withOpacity(0.7)
                                      : Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            if (i < 2)
              Obx(() => Container(
                width: 20,
                height: 2,
                color: controller.currentStep.value > i
                    ? AppColors.primary
                    : Colors.grey.shade300,
              )),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    return Obx(() {
      switch (controller.currentStep.value) {
        case 0:
          return _buildBasicInfoStep();
        case 1:
          return _buildItemsStep();
        case 2:
          return _buildAdditionalInfoStep();
        default:
          return Container();
      }
    });
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Proveedor
          Text(
            'Proveedor *',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Obx(() => SupplierSelectorWidget(
            selectedSupplier: controller.selectedSupplier.value,
            controller: controller,
            onSupplierSelected: controller.selectSupplier,
            onClearSupplier: controller.clearSupplier,
            activateOnTextFieldTap: true, // Activar con tap en textfield
          )),
          if (controller.supplierError.value)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Debe seleccionar un proveedor',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Prioridad
          Text(
            'Prioridad',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Obx(() => DropdownButtonFormField<PurchaseOrderPriority>(
            value: controller.priority.value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              prefixIcon: Icon(
                _getPriorityIcon(controller.priority.value),
                color: _getPriorityColor(controller.priority.value),
              ),
            ),
            items: PurchaseOrderPriority.values.map((priority) =>
              DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Icon(
                      _getPriorityIcon(priority),
                      size: 16,
                      color: _getPriorityColor(priority),
                    ),
                    const SizedBox(width: AppDimensions.paddingSmall),
                    Text(_getPriorityText(priority)),
                  ],
                ),
              ),
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.priority.value = value;
              }
            },
          )),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Fechas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de Orden *',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Obx(() => InkWell(
                      onTap: controller.selectOrderDate,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: controller.orderDateError.value 
                                ? Colors.red 
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: AppDimensions.paddingSmall),
                            Text(
                              controller.orderDateController.text,
                              style: Get.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha de Entrega *',
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingSmall),
                    Obx(() => InkWell(
                      onTap: controller.selectExpectedDeliveryDate,
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: controller.expectedDeliveryDateError.value 
                                ? Colors.red 
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: AppDimensions.paddingSmall),
                            Text(
                              controller.expectedDeliveryDateController.text,
                              style: Get.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),

          if (controller.orderDateError.value || controller.expectedDeliveryDateError.value)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'La fecha de entrega debe ser posterior a la fecha de orden',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Moneda — si la org tiene multi-moneda habilitado, muestra selector
          // con las monedas aceptadas y campos de tasa/monto foráneo.
          _buildCurrencySection(),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Notas
          CustomTextField(
            controller: controller.notesController,
            label: 'Notas',
            hint: 'Notas adicionales sobre la orden...',
            maxLines: 3,
            prefixIcon: Icons.note,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
        ],
      ),
    );
  }

  /// Sección de moneda elegante. Si la org no tiene multi-moneda activa,
  /// muestra el campo simple como antes. Si sí: tarjeta con gradiente,
  /// selector tipo chips con el código+nombre+símbolo de cada moneda,
  /// y panel de tasa/total con AnimatedSwitcher.
  Widget _buildCurrencySection() {
    return Obx(() {
      if (!controller.multiCurrencyEnabled) {
        return CustomTextField(
          controller: controller.currencyController,
          label: 'Moneda',
          hint: 'COP',
          prefixIcon: Icons.monetization_on,
        );
      }

      final accepted = controller.acceptedCurrencies;
      final base = controller.baseCurrencyCode;
      final selectedCode = controller.selectedPurchaseCurrency.value ?? base;
      final isForeign = selectedCode != base;

      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isForeign
                ? [
                    const Color(0xFFE11D48).withValues(alpha: 0.06),
                    const Color(0xFFE11D48).withValues(alpha: 0.02),
                  ]
                : [
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                    ElegantLightTheme.primaryBlue.withValues(alpha: 0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isForeign
                ? const Color(0xFFE11D48).withValues(alpha: 0.25)
                : ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono + título
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isForeign
                          ? const [Color(0xFFE11D48), Color(0xFFBE123C)]
                          : const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.currency_exchange_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Moneda de la compra',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Chips seleccionables (moneda base + extranjeras)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _currencyChip(
                  code: base,
                  label: '$base · base',
                  isSelected: !isForeign,
                  onTap: () => controller.onCurrencyChanged(base),
                ),
                ...accepted
                    .where((c) => (c['code'] as String?) != base)
                    .map((c) {
                      final code = c['code'] as String? ?? '';
                      return _currencyChip(
                        code: code,
                        label: code,
                        isSelected: selectedCode == code,
                        onTap: () => controller.onCurrencyChanged(code),
                      );
                    }),
              ],
            ),
            // Panel de tasa/total (solo si eligió extranjera)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isForeign
                  ? Padding(
                      key: const ValueKey('foreign-panel'),
                      padding: const EdgeInsets.only(top: 14),
                      child: _buildForeignPanel(selectedCode, base),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty-panel')),
            ),
          ],
        ),
      );
    });
  }

  Widget _currencyChip({
    required String code,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected
        ? (code == controller.baseCurrencyCode
            ? const Color(0xFF3B82F6)
            : const Color(0xFFE11D48))
        : Colors.grey.shade400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currencyFlag(code),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForeignPanel(String code, String base) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.exchangeRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tasa de cambio',
                  helperText: '1 $code = ? $base',
                  prefixIcon: const Icon(Icons.swap_vert_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE11D48),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: controller.onExchangeRateChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller.foreignAmountController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Total en $code',
                  helperText: 'Calculado',
                  prefixIcon: const Icon(Icons.payments_rounded),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Info card con equivalencia + consejo
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Los precios de los items los ingresas en $base. '
                  'El total en $code se calcula con la tasa. Si la tasa '
                  'del día difiere, edítala arriba.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _currencyFlag(String code) {
    switch (code.toUpperCase()) {
      case 'COP':
        return '\u{1F1E8}\u{1F1F4}';
      case 'USD':
        return '\u{1F1FA}\u{1F1F8}';
      case 'EUR':
        return '\u{1F1EA}\u{1F1FA}';
      case 'VES':
        return '\u{1F1FB}\u{1F1EA}';
      case 'BRL':
        return '\u{1F1E7}\u{1F1F7}';
      case 'MXN':
        return '\u{1F1F2}\u{1F1FD}';
      default:
        return '\u{1F4B1}';
    }
  }

  Widget _buildItemsStep() {
    return Column(
      children: [
        _buildOptimizedItemsHeader(),
        Expanded(
          child: _buildOptimizedItemsList(),
        ),
        _buildCompactTotalsSummary(),
      ],
    );
  }

  Widget _buildOptimizedItemsHeader() {
    return Obx(() {
      final completed = controller.items.where((i) => i.isValid).length;
      final showSearch = completed >= 3;
      final hasActiveItem = controller.activeItemIndex.value >= 0;
      final isSearching = controller.itemSearchQuery.value.isNotEmpty;
      final showAddButton = !hasActiveItem && !isSearching;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.04),
          border: Border(
            bottom: BorderSide(color: AppColors.primary.withOpacity(0.15)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$completed producto${completed != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatCurrency(controller.totalAmount.value),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                if (showAddButton) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: controller.addEmptyItem,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Agregar', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (showSearch) ...[
              const SizedBox(height: 8),
              _buildItemSearchBar(),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildItemSearchBar() {
    return Obx(() {
      final isSearching = controller.itemSearchQuery.value.isNotEmpty;
      final filteredCount = controller.filteredItemIndices.length;
      final totalValid = controller.items.where((i) => i.isValid).length;

      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSearching ? AppColors.primary : AppColors.primary.withOpacity(0.2),
            width: isSearching ? 1.5 : 1,
          ),
          boxShadow: isSearching
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.search, size: 18, color: isSearching ? AppColors.primary : Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller.itemSearchController,
                onChanged: (value) => controller.itemSearchQuery.value = value,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar en $totalValid productos...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (isSearching) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: filteredCount > 0 ? AppColors.primary.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$filteredCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: filteredCount > 0 ? AppColors.primary : Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: controller.clearItemSearch,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                ),
              ),
            ],
            if (!isSearching) const SizedBox(width: 10),
          ],
        ),
      );
    });
  }

  Widget _buildOptimizedItemsList() {
    return Obx(() {
      if (controller.items.isEmpty) {
        return _buildEmptyItemsState();
      }

      final hasActiveItem = controller.activeItemIndex.value >= 0;
      final isSearching = controller.itemSearchQuery.value.isNotEmpty;
      final filteredIndices = controller.filteredItemIndices;

      // Si busca y no hay resultados
      if (isSearching && filteredIndices.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(
                  'Sin resultados para "${controller.itemSearchQuery.value}"',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: controller.clearItemSearch,
                    icon: const Icon(Icons.clear, size: 14),
                    label: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        controller: controller.itemsScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filteredIndices.length,
        itemBuilder: (context, listIndex) {
          final originalIndex = filteredIndices[listIndex];
          final item = controller.items[originalIndex];
          final isActive = controller.activeItemIndex.value == originalIndex;

          return ProductItemFormWidget(
            key: ValueKey('item_${item.productId}_$originalIndex'),
            item: item,
            index: originalIndex,
            isActive: isActive,
            onQuantityChanged: (value) =>
                controller.updateItemQuantity(originalIndex, value),
            onPriceChanged: (value) =>
                controller.updateItemPrice(originalIndex, value),
            onDiscountChanged: (value) =>
                controller.updateItemDiscount(originalIndex, value),
            onRemove: controller.items.length > 1
                ? () => controller.removeItem(originalIndex)
                : null,
            onComplete: () => controller.completeActiveItem(),
            onEdit: () => controller.editItem(originalIndex),
            onProductSelected: (product) {
              if (product != null) {
                controller.selectProductForItem(originalIndex, product);
              } else {
                controller.updateItemProduct(originalIndex, '', '', 0.0);
              }
            },
          );
        },
      );
    });
  }

  Widget _buildCompactTotalsSummary() {
    return Obx(() {
      final validCount = controller.items.where((i) => i.isValid).length;
      final hasActiveItem = controller.activeItemIndex.value >= 0;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          border: Border(
            top: BorderSide(color: AppColors.primary.withOpacity(0.2)),
          ),
        ),
        child: Row(
          children: [
            if (hasActiveItem)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 4),
                  Text(
                    'Agrega el producto para continuar',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            else
              Text(
                '$validCount producto${validCount != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            const Spacer(),
            Text(
              AppFormatters.formatCurrency(controller.totalAmount.value),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAdditionalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),

          // Toggle para información de entrega
          Obx(() => SwitchListTile(
            title: const Text('Información de Entrega'),
            subtitle: const Text('Agregar detalles específicos de entrega'),
            value: controller.showDeliveryInfo.value,
            onChanged: (value) => controller.toggleDeliveryInfo(),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          )),

          // Información de entrega (condicional)
          Obx(() => controller.showDeliveryInfo.value
              ? _buildDeliveryInfoSection()
              : const SizedBox.shrink()),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Notas internas
          CustomTextField(
            controller: controller.internalNotesController,
            label: 'Notas Internas',
            hint: 'Notas internas para el equipo...',
            maxLines: 3,
            prefixIcon: Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de Entrega',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            
            CustomTextField(
              controller: controller.deliveryAddressController,
              label: 'Dirección de Entrega',
              hint: 'Dirección completa para la entrega',
              prefixIcon: Icons.location_on,
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            CustomTextField(
              controller: controller.contactPersonController,
              label: 'Persona de Contacto',
              hint: 'Nombre de la persona que recibe',
              prefixIcon: Icons.person,
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: controller.contactPhoneController,
                    label: 'Teléfono',
                    hint: 'Número de contacto',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: CustomTextField(
                    controller: controller.contactEmailController,
                    label: 'Email',
                    hint: 'Email de contacto',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItemsState() {
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
            'No hay productos agregados',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Agrega productos para crear la orden de compra',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: 'Agregar Primer Producto',
            onPressed: controller.addEmptyItem,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    return Obx(() {
      final item = controller.items[index];
      
      return Card(
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del item
              Row(
                children: [
                  Text(
                    'Producto ${index + 1}',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (controller.items.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.removeItem(index),
                      color: Colors.red.shade600,
                      tooltip: 'Eliminar producto',
                    ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Selector de producto
              ProductSelectorWidget(
                selectedProduct: item.productId.isNotEmpty ? null : null, // Necesitaremos el objeto Product completo
                controller: controller,
                hint: item.productName.isNotEmpty ? item.productName : 'Seleccionar producto',
                activateOnTextFieldTap: true,
                onProductSelected: (product) => controller.selectProductForItem(index, product),
                onClearProduct: () {
                  final updatedItem = item.copyWith(
                    productId: '',
                    productName: '',
                    unitPrice: 0.0,
                  );
                  controller.items[index] = updatedItem;
                  controller.calculateTotals();
                },
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Cantidad y precio
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('quantity_${item.productId}_$index'),
                      controller: TextEditingController(text: AppFormatters.formatStock(item.quantity)),
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        print('🔢 DEBUG: Cantidad changed para item $index: $value');
                        final quantity = AppFormatters.parseNumber(value)?.toInt() ?? 0;
                        print('🔢 DEBUG: Parsed quantity: $quantity');
                        controller.updateItemQuantity(index, quantity);
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('price_${item.productId}_$index'),
                      controller: TextEditingController(text: AppFormatters.formatCurrency(item.unitPrice)),
                      decoration: InputDecoration(
                        labelText: 'Precio Unitario',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        print('💰 DEBUG: Precio changed para item $index: $value');
                        final price = AppFormatters.parseNumber(value) ?? 0.0;
                        print('💰 DEBUG: Parsed price: $price');
                        controller.updateItemPrice(index, price);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.paddingMedium),
              
              // Descuento y total del item
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('discount_${item.productId}_$index'),
                      controller: TextEditingController(text: AppFormatters.formatStock(item.discountPercentage)),
                      decoration: InputDecoration(
                        labelText: 'Descuento (%)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final discount = double.tryParse(value) ?? 0.0;
                        controller.updateItemDiscount(index, discount);
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Item',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(item.quantity * item.unitPrice * (1 - item.discountPercentage / 100)),
                            style: Get.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Debug info (deshabilitado en producción)
              if (false) // Set to true for debugging
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'DEBUG: Item $index - Q:${item.quantity}, P:${item.unitPrice}, Valid:${item.isValid}',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTotalsSummary() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Obx(() => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: Get.textTheme.bodyMedium),
              Text(
                AppFormatters.formatCurrency(controller.subtotal.value),
                style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Descuento:', style: Get.textTheme.bodyMedium),
              Text(
                '-${AppFormatters.formatCurrency(controller.discountAmount.value)}',
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Impuestos:', style: Get.textTheme.bodyMedium),
              Text(
                AppFormatters.formatCurrency(controller.taxAmount.value),
                style: Get.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                AppFormatters.formatCurrency(controller.totalAmount.value),
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _buildNavigationButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
        final isMobile = constraints.maxWidth < 600;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : isTablet ? 20 : 14,
            vertical: isMobile ? 10 : 16,
          ),
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1000 : isTablet ? 800 : double.infinity,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : isTablet ? 24 : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Obx(() {
              return Row(
                children: [
                  if (!controller.isFirstStep) ...[
                    Expanded(
                      child: CustomButton(
                        text: 'Anterior',
                        onPressed: controller.previousStep,
                        type: ButtonType.outline,
                        icon: Icons.arrow_back,
                      ),
                    ),
                    SizedBox(width: isMobile ? 12 : isDesktop ? 20 : AppDimensions.paddingMedium),
                  ],

                  Expanded(
                    flex: controller.isFirstStep ? 3 : 2,
                    child: controller.isLastStep
                        ? CustomButton(
                            text: controller.saveButtonText,
                            onPressed: controller.isSaving.value ? null : controller.savePurchaseOrder,
                            isLoading: controller.isSaving.value,
                            icon: Icons.save,
                          )
                        : CustomButton(
                            text: 'Siguiente',
                            onPressed: controller.canProceed ? controller.nextStep : null,
                            icon: Icons.arrow_forward,
                          ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // Helper methods
  void _selectSupplier() {
    // Implementación del selector será manejada por el widget SupplierSelectorWidget
    // que será agregado directamente en el build
  }

  void _selectProduct(int index) {
    // Implementación del selector será manejada por el widget ProductSelectorWidget
    // que será agregado directamente en el build del item
  }

  Color _getPriorityColor(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Colors.green;
      case PurchaseOrderPriority.medium:
        return Colors.orange;
      case PurchaseOrderPriority.high:
        return Colors.red;
      case PurchaseOrderPriority.urgent:
        return Colors.deepPurple;
    }
  }

  IconData _getPriorityIcon(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return Icons.keyboard_arrow_down;
      case PurchaseOrderPriority.medium:
        return Icons.remove;
      case PurchaseOrderPriority.high:
        return Icons.keyboard_arrow_up;
      case PurchaseOrderPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _getPriorityText(PurchaseOrderPriority priority) {
    switch (priority) {
      case PurchaseOrderPriority.low:
        return 'Baja';
      case PurchaseOrderPriority.medium:
        return 'Media';
      case PurchaseOrderPriority.high:
        return 'Alta';
      case PurchaseOrderPriority.urgent:
        return 'Urgente';
    }
  }

}