// lib/features/inventory/presentation/screens/inventory_adjustments_screen.dart
//
// Ajuste de stock de un producto, pensado para el dueño: arriba "Hay N", luego
// tres opciones (Sumar / Restar / Poner cantidad exacta), un solo campo, la
// frase de resultado y un botón con el verbo. Lo que se envía al servidor no
// cambia: `adjustmentQuantity` = nueva cantidad − actual.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../controllers/inventory_adjustments_controller.dart';
import '../widgets/confirm_password_dialog.dart';
import '../widgets/product_search_widget.dart';

/// Color, ícono y textos de cada opción.
class AdjustModeStyle {
  final StockAdjustMode mode;
  final String title;
  final String note;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;

  const AdjustModeStyle._(
    this.mode,
    this.title,
    this.note,
    this.icon,
    this.color,
    this.gradient,
  );

  static const add = AdjustModeStyle._(
    StockAdjustMode.add,
    'Sumar unidades',
    'Llegó mercancía o te devolvieron',
    Icons.add,
    ElegantLightTheme.successGreen,
    ElegantLightTheme.successGradient,
  );
  static const subtract = AdjustModeStyle._(
    StockAdjustMode.subtract,
    'Restar unidades',
    'Se dañó, venció o se perdió',
    Icons.remove,
    ElegantLightTheme.errorRed,
    ElegantLightTheme.errorGradient,
  );
  static const exact = AdjustModeStyle._(
    StockAdjustMode.exact,
    'Poner cantidad exacta',
    'Contaste y hay otro número',
    Icons.drag_handle,
    ElegantLightTheme.primaryBlue,
    ElegantLightTheme.primaryGradient,
  );

  static const all = [add, subtract, exact];

  static AdjustModeStyle of(StockAdjustMode mode) =>
      all.firstWhere((s) => s.mode == mode);
}

/// Tarjeta grande de una opción (se usa también en celular, una debajo de otra).
class AdjustModeOption extends StatelessWidget {
  final AdjustModeStyle style;
  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback onTap;

  const AdjustModeOption({
    super.key,
    required this.style,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? style.color : ElegantLightTheme.textTertiary;
    final radius = BorderRadius.circular(14);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color:
            selected
                ? style.color.withValues(alpha: 0.10)
                : ElegantLightTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color:
                selected
                    ? style.color
                    : ElegantLightTheme.textTertiary.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          mouseCursor:
              enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 10 : 14,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 36 : 42,
                  height: compact ? 36 : 42,
                  decoration: BoxDecoration(
                    gradient: enabled ? style.gradient : null,
                    color: enabled ? null : ElegantLightTheme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    style.icon,
                    color:
                        enabled ? Colors.white : ElegantLightTheme.textTertiary,
                    size: compact ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        style.title,
                        style: TextStyle(
                          color:
                              selected ? color : ElegantLightTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        style.note,
                        style: const TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: style.color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de razón que se puede tocar.
class AdjustReasonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AdjustReasonChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color:
          selected
              ? ElegantLightTheme.primaryBlue
              : ElegantLightTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color:
              selected
                  ? ElegantLightTheme.primaryBlue
                  : ElegantLightTheme.textTertiary.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 15, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : ElegantLightTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto con "→" dibujado como ícono (no todas las fuentes traen la flecha).
class ArrowText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const ArrowText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    final parts = text.split('\u2192');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.arrow_forward,
                    size: (style.fontSize ?? 14) * 0.95,
                    color: style.color,
                  ),
                ),
              ),
            TextSpan(text: parts[i]),
          ],
        ],
      ),
      semanticsLabel: text,
    );
  }
}

class InventoryAdjustmentsScreen
    extends GetView<InventoryAdjustmentsController> {
  const InventoryAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Ajustar inventario',
      showBackButton: true,
      showDrawer: false,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.warehouses.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              final mobile = constraints.maxWidth < 600;
              final left = _buildWhereCard();
              final right = _buildActionCard(mobile);

              return SingleChildScrollView(
                padding: EdgeInsets.all(mobile ? 16.0 : 24.0),
                child:
                    wide
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: left),
                            const SizedBox(width: 24),
                            Expanded(flex: 6, child: right),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [left, const SizedBox(height: 16), right],
                        ),
              );
            },
          );
        }),
      ),
    );
  }

  // ──────────────────────── IZQUIERDA: ALMACÉN, PRODUCTO, "HAY N" ────────────────────────

  Widget _buildWhereCard() {
    return BrebSectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Producto',
      children: [
        Obx(() => _buildWarehouseContent()),
        const SizedBox(height: 16),
        _label('Producto'),
        const SizedBox(height: 8),
        ProductSearchWidget(
          hintText: 'Buscar producto por nombre o SKU...',
          onProductSelected: controller.selectProduct,
          searchFunction: controller.searchProducts,
        ),
        const SizedBox(height: 16),
        Obx(() => _buildStockHeadline()),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: ElegantLightTheme.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _buildWarehouseContent() {
    if (controller.warehouses.isEmpty) {
      return const BrebInlineLoading('Cargando almacenes...');
    }

    if (controller.warehouses.length == 1 &&
        controller.selectedWarehouseId.value.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Almacén'),
          const SizedBox(height: 8),
          _singleWarehouse(),
        ],
      );
    }
    return _warehouseDropdown();
  }

  Widget _singleWarehouse() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warehouse_outlined,
            color: ElegantLightTheme.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.selectedWarehouseName.value,
              style: const TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warehouseDropdown() {
    return DropdownButtonFormField<String>(
      decoration: brebInputDecoration(
        label: 'Almacén',
        icon: Icons.warehouse_outlined,
      ),
      isExpanded: true,
      value:
          controller.selectedWarehouseId.value.isNotEmpty
              ? controller.selectedWarehouseId.value
              : null,
      hint: const Text('Elige el almacén'),
      items:
          controller.warehouses.map((warehouse) {
            return DropdownMenuItem<String>(
              value: warehouse.id,
              child: Text(
                warehouse.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: ElegantLightTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
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

  /// "Hay 20 unidades de (producto) en (almacén)".
  Widget _buildStockHeadline() {
    if (controller.selectedProductId.value.isEmpty) {
      return const BrebEmptyState(
        icon: Icons.search,
        message: 'Busca el producto que quieres ajustar.',
      );
    }
    if (controller.isLoadingBalance.value) {
      return const BrebInlineLoading('Leyendo cuántas unidades hay...');
    }
    final balance = controller.currentBalance.value;
    if (balance == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrebNotice.error(
            'No pudimos leer cuántas unidades hay de '
            '${controller.selectedProductName.value}. Sin ese dato no se '
            'puede ajustar.',
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: brebSecondaryButtonStyle(),
            onPressed: controller.loadCurrentBalance,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Volver a intentar'),
          ),
        ],
      );
    }

    final qty = controller.currentStock.value;
    final warehouse =
        controller.selectedWarehouseId.value.isNotEmpty
            ? controller.selectedWarehouseName.value
            : null;
    const strong = TextStyle(
      fontWeight: FontWeight.w800,
      color: ElegantLightTheme.textPrimary,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            key: const ValueKey('adjust-headline'),
            TextSpan(
              style: const TextStyle(
                fontSize: 20,
                height: 1.35,
                color: ElegantLightTheme.textSecondary,
              ),
              children: [
                const TextSpan(text: 'Hay '),
                TextSpan(
                  text: AppFormatters.formatStock(qty),
                  style: strong.copyWith(
                    fontSize: 30,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
                TextSpan(
                  text:
                      controller.isStockUnconfirmed
                          ? (qty == 1
                              ? ' unidad (sin confirmar) de '
                              : ' unidades (sin confirmar) de ')
                          : (qty == 1 ? ' unidad de ' : ' unidades de '),
                ),
                TextSpan(
                  text: controller.selectedProductName.value,
                  style: strong,
                ),
                if (warehouse != null) ...[
                  const TextSpan(text: ' en '),
                  TextSpan(text: warehouse, style: strong),
                ],
              ],
            ),
          ),
          if (controller.isStockUnconfirmed) ...[
            const SizedBox(height: 12),
            const BrebNotice.warning(kUnconfirmedStockMessage),
          ],
          if (balance.reservedQuantity > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.lock_clock_outlined,
                  size: 18,
                  color: ElegantLightTheme.warningOrange,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    balance.reservedQuantity == 1
                        ? '1 está apartada en pedidos'
                        : '${balance.reservedQuantity} están apartadas en pedidos',
                    style: const TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────── DERECHA: OPCIÓN, CANTIDAD, RAZÓN, RESULTADO ────────────────────────

  Widget _buildActionCard(bool mobile) {
    return BrebSectionCard(
      icon: Icons.tune,
      title: '¿Qué quieres hacer?',
      children: [
        Obx(() {
          final enabled = controller.canAdjust;
          final mode = controller.mode.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!enabled) ...[
                _buildNotReadyNotice(),
                const SizedBox(height: 12),
              ],
              _buildModeOptions(enabled, mode, mobile),
              if (enabled && mode != null) ...[
                const SizedBox(height: 20),
                _buildAmountRow(mode, mobile),
                const SizedBox(height: 18),
                _buildReasons(mode),
                const SizedBox(height: 14),
                TextField(
                  controller: controller.notesController,
                  onChanged: (v) => controller.notes.value = v,
                  decoration: brebInputDecoration(
                    label: 'Nota (opcional)',
                    icon: Icons.notes,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildResult(),
              const SizedBox(height: 14),
              _buildSubmitRow(mobile),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildNotReadyNotice() {
    if (controller.selectedWarehouseId.value.isEmpty) {
      return const BrebNotice.info('Primero elige el almacén.');
    }
    if (controller.selectedProductId.value.isEmpty) {
      return const BrebNotice.info('Primero busca y elige el producto.');
    }
    if (controller.isLoadingBalance.value) {
      return const BrebNotice.info(
        'Espera: estamos leyendo cuántas unidades hay.',
      );
    }
    if (controller.isStockUnconfirmed) {
      return const BrebNotice.warning(
        'El saldo aún no está confirmado. Espera un momento y vuelve a elegir el producto.',
      );
    }
    return const BrebNotice.warning(
      'No se puede ajustar sin saber cuántas unidades hay. Vuelve a intentar.',
    );
  }

  Widget _buildModeOptions(bool enabled, StockAdjustMode? mode, bool mobile) {
    Widget option(AdjustModeStyle s) => AdjustModeOption(
      key: ValueKey('adjust-mode-${s.mode.name}'),
      style: s,
      selected: mode == s.mode,
      enabled: enabled,
      compact: mobile,
      onTap: () => controller.setMode(s.mode),
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in AdjustModeStyle.all) ...[
                option(s),
                if (s != AdjustModeStyle.all.last) const SizedBox(height: 10),
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in AdjustModeStyle.all) ...[
                Expanded(child: option(s)),
                if (s != AdjustModeStyle.all.last) const SizedBox(width: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountRow(StockAdjustMode mode, bool mobile) {
    final amountField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StockAdjustmentPlan.questionFor(mode),
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('adjust-amount'),
          controller: controller.amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ElegantLightTheme.textPrimary,
          ),
          decoration: brebInputDecoration(label: 'Unidades', hint: '0'),
          onChanged:
              (t) => controller.setAmount(
                t.trim().isEmpty ? null : int.tryParse(t),
              ),
        ),
      ],
    );

    if (!controller.showUnitCostField) return amountField;

    final costField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Costo por unidad',
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('adjust-unit-cost'),
          controller: controller.unitCostController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
          ],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
          decoration: brebInputDecoration(
            label: 'Costo',
            icon: Icons.attach_money,
          ),
          onChanged:
              (t) =>
                  controller.unitCost.value = AppFormatters.parseRate(t) ?? 0.0,
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [amountField, const SizedBox(height: 14), costField],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: amountField),
        const SizedBox(width: 14),
        Expanded(child: costField),
      ],
    );
  }

  Widget _buildReasons(StockAdjustMode mode) {
    final reasons = reasonsForMode(mode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Razón',
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in reasons)
              AdjustReasonChip(
                label: r,
                selected: controller.reason.value == r,
                onTap: () => controller.setReasonFromPredefined(r),
              ),
          ],
        ),
      ],
    );
  }

  /// "Hay 20 → quedarán 15 (−5)" o el error que impide guardar.
  Widget _buildResult() {
    if (!controller.canAdjust || controller.mode.value == null) {
      return const SizedBox.shrink();
    }
    final plan = controller.plan;
    final error = plan.error;
    if (error != null) {
      return BrebNotice.error(error);
    }
    final text = plan.resultText;
    if (text == null) return const SizedBox.shrink();
    final color = controller.getAdjustmentColor();
    final cost = controller.costText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrowText(
            text,
            key: const ValueKey('adjust-result'),
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (cost != null) ...[
            const SizedBox(height: 4),
            Text(
              cost,
              key: const ValueKey('adjust-cost'),
              style: const TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitRow(bool mobile) {
    final submitting = controller.isCreating.value;
    final valid = controller.isFormValid && !submitting;
    // El error de cantidad ya se ve en la frase; aquí solo lo que falte.
    final missing =
        controller.plan.error == null && controller.canAdjust
            ? controller.blockingReason
            : null;

    final button = ElevatedButton.icon(
      key: const ValueKey('adjust-submit'),
      style: brebPrimaryButtonStyle().copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      ),
      onPressed: valid ? _onApplyPressed : null,
      icon:
          submitting
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : const Icon(Icons.check, size: 20),
      label: Text(submitting ? 'Guardando...' : controller.submitButtonText),
    );

    final hint =
        missing == null
            ? null
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: ElegantLightTheme.warningOrange,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    missing,
                    key: const ValueKey('adjust-missing'),
                    style: const TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[hint, const SizedBox(height: 10)],
          button,
        ],
      );
    }
    return Row(
      children: [
        if (hint != null) Expanded(child: hint) else const Spacer(),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240),
          child: button,
        ),
      ],
    );
  }

  // ──────────────────────── CONFIRMACIÓN CON CONTRASEÑA ────────────────────────

  /// Pide la contraseña del usuario antes de aplicar el ajuste. Igual
  /// que en ajustes masivos — cualquier modificación de inventario es
  /// sensible y debe confirmarse explícitamente.
  Future<void> _onApplyPressed() async {
    final product = controller.selectedProductName.value;
    final warehouse = controller.selectedWarehouseName.value;
    final plan = controller.plan;
    final confirmed = await showConfirmPasswordDialog(
      title: 'Confirmar ajuste de inventario',
      message:
          '"$product" en $warehouse: ${plan.resultText ?? ''}. '
          'Esta acción no se puede deshacer.',
      confirmButtonText: 'Confirmar y aplicar',
    );
    if (confirmed) {
      controller.createAdjustment();
    }
  }
}
