// lib/features/purchase_orders/presentation/screens/purchase_order_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canExit = await controller.confirmExit();
        if (canExit) Get.back();
      },
      child: Obx(() => AppScaffold(
        includeDrawer: false,
        appBar: AppBarBuilder.buildGradient(
          title: controller.titleText,
          automaticallyImplyLeading: true,
          gradientColors: [
            ElegantLightTheme.primaryGradient.colors.first,
            ElegantLightTheme.primaryGradient.colors.last,
            ElegantLightTheme.primaryBlue,
          ],
          actions: [
            const SyncStatusIcon(),
            if (!controller.isLoading.value)
              TextButton.icon(
                onPressed: controller.confirmClearForm,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                label: const Text('Limpiar'),
              ),
            const SizedBox(width: AppDimensions.paddingSmall),
          ],
        ),
        body: controller.isLoading.value
            ? const Center(child: LoadingWidget())
            : _buildFormContent(),
      )),
    );
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
          // ── Sección: Proveedor + Prioridad ───────────────────────────
          _elegantSection(
            icon: Icons.storefront_rounded,
            title: 'Proveedor y prioridad',
            accent: const Color(0xFF3B82F6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Proveedor *'),
                Obx(() => SupplierSelectorWidget(
                      selectedSupplier: controller.selectedSupplier.value,
                      controller: controller,
                      onSupplierSelected: controller.selectSupplier,
                      onClearSupplier: controller.clearSupplier,
                      activateOnTextFieldTap: true,
                    )),
                Obx(() => controller.supplierError.value
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _errorHint('Debe seleccionar un proveedor'),
                      )
                    : const SizedBox.shrink()),
                const SizedBox(height: AppDimensions.paddingMedium),
                _fieldLabel('Prioridad'),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PurchaseOrderPriority.values
                          .map((p) => _priorityChip(
                                priority: p,
                                isSelected: controller.priority.value == p,
                                onTap: () => controller.priority.value = p,
                              ))
                          .toList(),
                    )),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // ── Sección: Fechas ──────────────────────────────────────────
          _elegantSection(
            icon: Icons.event_rounded,
            title: 'Fechas',
            accent: const Color(0xFFF59E0B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Fecha de orden *'),
                          Obx(() => _elegantDateField(
                                text: controller.orderDateController.text,
                                icon: Icons.calendar_today_rounded,
                                hasError: controller.orderDateError.value,
                                onTap: controller.selectOrderDate,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Fecha de entrega *'),
                          Obx(() => _elegantDateField(
                                text: controller
                                    .expectedDeliveryDateController.text,
                                icon: Icons.local_shipping_rounded,
                                hasError: controller
                                    .expectedDeliveryDateError.value,
                                onTap:
                                    controller.selectExpectedDeliveryDate,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                Obx(() => (controller.orderDateError.value ||
                        controller.expectedDeliveryDateError.value)
                    ? Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _errorHint(
                          'La fecha de entrega debe ser posterior a la de orden',
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.paddingMedium),

          // ── Sección: Moneda (multi-moneda elegante ya implementado) ─
          _buildCurrencySection(),

          const SizedBox(height: AppDimensions.paddingMedium),

          // ── Sección: Notas ──────────────────────────────────────────
          _elegantSection(
            icon: Icons.edit_note_rounded,
            title: 'Notas',
            accent: const Color(0xFF64748B),
            child: CustomTextField(
              controller: controller.notesController,
              label: 'Notas adicionales',
              hint: 'Instrucciones especiales, referencia, etc.',
              maxLines: 3,
              prefixIcon: Icons.note_alt_rounded,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
        ],
      ),
    );
  }

  /// Tarjeta de sección con header (icono gradient + título) + contenido.
  /// Usa ElegantLightTheme.cardGradient y sombra elevada para mantener
  /// consistencia con el resto de la app.
  Widget _elegantSection({
    required IconData icon,
    required String title,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.12), width: 1),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.75)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  /// Etiqueta de campo consistente con el resto de la app.
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ElegantLightTheme.textSecondary,
        ),
      ),
    );
  }

  /// Mensaje de error elegante con icono.
  Widget _errorHint(String text) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 14, color: Color(0xFFEF4444)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Decoración de input consistente con el tema elegante.
  InputDecoration _elegantInputDecoration({Widget? prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: Color(0xFF3B82F6),
          width: 1.5,
        ),
      ),
    );
  }

  /// Chip de prioridad con icono + color del tema. Reemplaza el dropdown
  /// plano por una selección más visual tipo segmented control.
  Widget _priorityChip({
    required PurchaseOrderPriority priority,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = _getPriorityColor(priority);
    final icon = _getPriorityIcon(priority);
    final label = _getPriorityText(priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withValues(alpha: 0.85)],
                  )
                : LinearGradient(
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Campo de fecha elegante con icono y estados visuales.
  Widget _elegantDateField({
    required String text,
    required IconData icon,
    required bool hasError,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: hasError
                ? const Color(0xFFEF4444)
                : Colors.grey.shade300,
            width: hasError ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6),
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text.isEmpty ? 'Seleccionar…' : text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: text.isEmpty
                      ? Colors.grey.shade500
                      : ElegantLightTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                color: Colors.grey.shade500, size: 22),
          ],
        ),
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
                // Mismo set de formatters que el payment dialog de facturas
                // para que el parseo de tasas sea consistente en toda la app.
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  RateInputFormatter(),
                ],
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
                  'Ingresa los precios de los items directamente en $code. '
                  'Se convierten a $base con la tasa automáticamente y se '
                  'guardan en $base. Si editás la tasa, los precios '
                  'ingresados en $code se recalculan en $base.',
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
      // Buscador SIEMPRE visible en este paso — permite al usuario chequear
      // rápidamente si un producto ya fue agregado antes de guardar.
      final hasActiveItem = controller.activeItemIndex.value >= 0;
      final hasDuplicates = controller.duplicateItemIndices.isNotEmpty;
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
            const SizedBox(height: 8),
            _buildItemSearchBar(),
            if (hasDuplicates) ...[
              const SizedBox(height: 8),
              _buildDuplicatesBanner(),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildDuplicatesBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: Color(0xFFB91C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Productos repetidos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  'No podrás guardar hasta eliminarlos: ${controller.duplicatesSummary}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7F1D1D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSearchBar() {
    return Obx(() {
      final isSearching = controller.itemSearchQuery.value.isNotEmpty;
      final filteredCount = controller.filteredItemIndices.length;
      final totalWithProduct =
          controller.items.where((i) => i.productId.isNotEmpty).length;

      return Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSearching ? AppColors.primary : AppColors.primary.withOpacity(0.35),
            width: isSearching ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isSearching ? 0.15 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  hintText: totalWithProduct > 0
                      ? 'Buscar en $totalWithProduct productos (nombre, SKU o código)…'
                      : 'Buscar productos agregados (nombre, SKU o código)…',
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
      // Suscribirse a los Rx de moneda/tasa para que el Obx reconstruya los
      // items cuando el usuario cambie de moneda o edite la tasa — así cada
      // ProductItemFormWidget recibe las props nuevas.
      final foreignCurrency = controller.selectedPurchaseCurrency.value;
      final currentRate = controller.exchangeRate.value;

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

      final dupes = controller.duplicateItemIndices;

      return ListView.builder(
        controller: controller.itemsScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filteredIndices.length,
        itemBuilder: (context, listIndex) {
          final originalIndex = filteredIndices[listIndex];
          final item = controller.items[originalIndex];
          final isActive = controller.activeItemIndex.value == originalIndex;
          final isDuplicate = dupes.contains(originalIndex);

          final itemWidget = ProductItemFormWidget(
            key: ValueKey('item_${item.productId}_$originalIndex'),
            item: item,
            index: originalIndex,
            isActive: isActive,
            // Multi-moneda: si la PO tiene moneda extranjera seleccionada,
            // el campo "Precio" acepta el valor en esa moneda y convierte.
            foreignCurrency: foreignCurrency,
            baseCurrency: controller.baseCurrencyCode,
            exchangeRate: currentRate,
            onForeignPriceChanged: (value) =>
                controller.updateItemForeignPrice(originalIndex, value),
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

          if (!isDuplicate) return itemWidget;

          // Item duplicado: borde rojo prominente + badge + acción rápida
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: itemWidget,
              ),
              Positioned(
                top: 0,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'REPETIDO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => controller.removeItem(originalIndex),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 10,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          // Sección: toggle de entrega
          _elegantSection(
            icon: Icons.local_shipping_rounded,
            title: 'Información de entrega',
            accent: const Color(0xFF10B981),
            child: Obx(() => SwitchListTile(
                  title: const Text(
                    'Agregar datos de entrega',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Dirección, contacto, teléfono y email',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  value: controller.showDeliveryInfo.value,
                  onChanged: (value) => controller.toggleDeliveryInfo(),
                  activeColor: const Color(0xFF10B981),
                  contentPadding: EdgeInsets.zero,
                )),
          ),

          // Campos de entrega (condicional, con animación)
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: controller.showDeliveryInfo.value
                    ? Padding(
                        key: const ValueKey('delivery-fields'),
                        padding: const EdgeInsets.only(
                            top: AppDimensions.paddingMedium),
                        child: _buildDeliveryInfoSection(),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty')),
              )),

          const SizedBox(height: AppDimensions.paddingMedium),

          // Sección: notas internas
          _elegantSection(
            icon: Icons.lock_person_rounded,
            title: 'Notas internas',
            accent: const Color(0xFF8B5CF6),
            child: CustomTextField(
              controller: controller.internalNotesController,
              label: 'Visibles solo para tu equipo',
              hint: 'Observaciones internas, recordatorios, etc.',
              maxLines: 3,
              prefixIcon: Icons.edit_note_rounded,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    return _elegantSection(
      icon: Icons.pin_drop_rounded,
      title: 'Datos de entrega',
      accent: const Color(0xFF0EA5E9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: controller.deliveryAddressController,
            label: 'Dirección de entrega',
            hint: 'Dirección completa para la entrega',
            prefixIcon: Icons.location_on_rounded,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          CustomTextField(
            controller: controller.contactPersonController,
            label: 'Persona de contacto',
            hint: 'Nombre de quien recibe',
            prefixIcon: Icons.person_rounded,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.contactPhoneController,
                  label: 'Teléfono',
                  hint: 'Número de contacto',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: CustomTextField(
                  controller: controller.contactEmailController,
                  label: 'Email',
                  hint: 'Email de contacto',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
        ],
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