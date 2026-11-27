// lib/features/inventory/presentation/screens/inventory_bulk_adjustments_screen.dart
//
// Ajustes de varios productos a la vez, con el mismo criterio del ajuste
// individual: cada fila dice "Hay 20", se elige + / − / = con un número y se
// lee "20 → 15 (−5)". Lo que se envía al servidor no cambia.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../controllers/inventory_adjustments_controller.dart';
import '../controllers/inventory_bulk_adjustments_controller.dart';
import '../widgets/adjust_admin_only_notice.dart';
import '../widgets/confirm_password_dialog.dart';
import '../widgets/product_search_widget.dart';
import 'inventory_adjustments_screen.dart'
    show AdjustModeStyle, AdjustReasonChip, ArrowText;

class InventoryBulkAdjustmentsScreen
    extends GetView<InventoryBulkAdjustmentsController> {
  const InventoryBulkAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Ajustes masivos',
      showBackButton: true,
      showDrawer: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 760;
            return Obx(() {
              // Solo el administrador ajusta (aunque llegue por ruta directa).
              // (Se lee `isLoading` primero: el Obx siempre observa algo, aunque
              // no haya usuario cargado.)
              final loading = controller.isLoading.value;
              if (!controller.isAllowedToAdjust) {
                return const AdjustAdminOnlyNotice();
              }
              if (loading && controller.warehouses.isEmpty) {
                return const Center(child: LoadingWidget());
              }
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(mobile ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSetupCard(mobile),
                          const SizedBox(height: 16),
                          _buildProductsCard(mobile),
                        ],
                      ),
                    ),
                  ),
                  if (controller.hasItems) _buildFooter(mobile),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  // ──────────────────────── ALMACÉN Y RAZÓN GENERAL ────────────────────────

  Widget _buildSetupCard(bool mobile) {
    final warehouse = Obx(() => _buildWarehouse());
    final note = TextField(
      controller: controller.globalNotesController,
      onChanged: (v) => controller.globalNotes.value = v,
      decoration: brebInputDecoration(
        label: 'Nota para todos (opcional)',
        icon: Icons.notes,
      ),
    );
    return BrebSectionCard(
      icon: Icons.warehouse_outlined,
      title: 'Almacén y razón',
      children: [
        if (mobile) ...[
          warehouse,
          const SizedBox(height: 14),
          note,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: warehouse),
              const SizedBox(width: 16),
              Expanded(child: note),
            ],
          ),
        const SizedBox(height: 16),
        const Text(
          'Razón (para todos los productos)',
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in InventoryBulkAdjustmentsController.generalReasons)
                AdjustReasonChip(
                  label: r,
                  selected: controller.generalReason.value == r,
                  onTap: () => controller.generalReason.value = r,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouse() {
    if (controller.warehouses.isEmpty) {
      return const BrebInlineLoading('Cargando almacenes...');
    }
    if (controller.warehouses.length == 1 &&
        controller.selectedWarehouseId.value.isNotEmpty) {
      return InputDecorator(
        decoration: brebInputDecoration(
          label: 'Almacén',
          icon: Icons.warehouse_outlined,
        ),
        child: Text(
          controller.selectedWarehouseName.value,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: brebInputDecoration(
        label: 'Almacén',
        icon: Icons.warehouse_outlined,
      ),
      // ignore: deprecated_member_use
      value:
          controller.selectedWarehouseId.value.isEmpty
              ? null
              : controller.selectedWarehouseId.value,
      hint: const Text('Elige el almacén'),
      items:
          controller.warehouses
              .map(
                (w) => DropdownMenuItem<String>(
                  value: w.id,
                  child: Text(
                    w.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
      onChanged: (id) {
        if (id == null) return;
        final w = controller.warehouses.firstWhere((w) => w.id == id);
        controller.setSelectedWarehouse(id, w.name);
      },
    );
  }

  // ──────────────────────── PRODUCTOS ────────────────────────

  Widget _buildProductsCard(bool mobile) {
    return BrebSectionCard(
      icon: Icons.inventory_2_outlined,
      title: 'Productos',
      children: [
        ProductSearchWidget(
          hintText: 'Buscar producto para agregar...',
          onProductSelected: controller.addProductToAdjustment,
          searchFunction: controller.searchProducts,
        ),
        const SizedBox(height: 14),
        Obx(() {
          if (!controller.hasItems) {
            return const BrebEmptyState(
              icon: Icons.playlist_add,
              message: 'Busca y agrega los productos que quieres ajustar.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildToolbar(mobile),
              const SizedBox(height: 12),
              for (final item in controller.adjustmentItems)
                _BulkItemRow(
                  key: ValueKey('bulk-row-${item.id}'),
                  item: item,
                  mobile: mobile,
                  onRemove: () => controller.removeAdjustmentItem(item.id),
                  onToggle: () => controller.toggleItemSelection(item.id),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildToolbar(bool mobile) {
    Widget action(IconData icon, String label, VoidCallback onTap) =>
        OutlinedButton.icon(
          style: brebSecondaryButtonStyle().copyWith(
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        action(Icons.select_all, 'Todos', controller.selectAllItems),
        action(Icons.deselect, 'Ninguno', controller.deselectAllItems),
        action(
          Icons.restore,
          'Deshacer cambios',
          controller.resetQuantityForAllSelected,
        ),
        action(Icons.exposure_zero, 'Poner en Cero', _confirmZero),
      ],
    );
  }

  Future<void> _confirmZero() async {
    final n = controller.selectedAdjustableCount;
    if (n == 0) return;
    final ok = await Get.dialog<bool>(
      brebAlertDialog(
        title: brebDialogTitle(
          Icons.exposure_zero,
          n == 1
              ? '¿Dejar en 0 el producto seleccionado?'
              : '¿Dejar en 0 los $n productos seleccionados?',
          gradient: ElegantLightTheme.warningGradient,
        ),
        content: const Text(
          'Cada uno quedará con 0 unidades al guardar. Puedes revisarlos antes.',
          style: TextStyle(color: ElegantLightTheme.textSecondary),
        ),
        actions: [
          TextButton(
            style: brebTextButtonStyle(),
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: brebPrimaryButtonStyle(),
            onPressed: () => Get.back(result: true),
            child: const Text('Dejar en 0'),
          ),
        ],
      ),
    );
    if (ok == true) controller.setQuantityForAllSelected(0);
  }

  // ──────────────────────── PIE: RESUMEN Y BOTÓN ────────────────────────

  Widget _buildFooter(bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24, vertical: 12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Obx(() {
        final count = controller.itemsWithChanges.length;
        final submitting = controller.isCreating.value;
        final valid = controller.isFormValid && !submitting;
        final missing = _missingText();
        final label =
            submitting
                ? 'Guardando...'
                : count == 0
                ? 'Guardar ajustes'
                : count == 1
                ? 'Guardar ajuste de 1 producto'
                : 'Guardar ajustes de $count productos';

        final button = ElevatedButton.icon(
          key: const ValueKey('bulk-submit'),
          style: brebPrimaryButtonStyle().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 50)),
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
          label: Text(label),
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hint != null) ...[hint, const SizedBox(height: 8)],
              button,
            ],
          );
        }
        return Row(
          children: [
            if (hint != null) Expanded(child: hint) else const Spacer(),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280),
              child: button,
            ),
          ],
        );
      }),
    );
  }

  String? _missingText() {
    if (controller.selectedWarehouseId.value.isEmpty) {
      return 'Elige el almacén.';
    }
    if (!controller.hasSelectedItems) return 'Marca al menos un producto.';
    if (controller.hasUnconfirmedSelected) {
      return 'Hay un producto con saldo sin confirmar: espera o quítalo de la lista.';
    }
    final errors = controller.itemsWithErrors;
    if (errors.isNotEmpty) {
      return 'Corrige ${errors.length == 1 ? 'la fila' : 'las ${errors.length} filas'} en rojo.';
    }
    if (controller.itemsWithChanges.isEmpty) {
      return 'Elige + / − / = y escribe la cantidad en cada producto.';
    }
    return null;
  }

  // ──────────────────────── CONFIRMACIÓN CON CONTRASEÑA ────────────────────────

  Future<void> _onApplyPressed() async {
    if (!controller.ensureAllowedToAdjust()) return;
    final itemCount = controller.itemsWithChanges.length;
    final warehouseName = controller.selectedWarehouseName.value;

    final confirmed = await showConfirmPasswordDialog(
      title: 'Confirmar ajustes',
      message:
          itemCount == 1
              ? 'Se cambiará 1 producto en $warehouseName. '
                  'Esta acción no se puede deshacer.'
              : 'Se cambiarán $itemCount productos en $warehouseName. '
                  'Esta acción no se puede deshacer.',
      confirmButtonText: 'Confirmar y aplicar',
    );

    if (confirmed) {
      controller.createBulkAdjustments();
    }
  }
}

/// Una fila: nombre, "Hay 20", + / − / =, número y "20 → 15 (−5)".
class _BulkItemRow extends StatefulWidget {
  final BulkAdjustmentItem item;
  final bool mobile;
  final VoidCallback onRemove;
  final VoidCallback onToggle;

  const _BulkItemRow({
    super.key,
    required this.item,
    required this.mobile,
    required this.onRemove,
    required this.onToggle,
  });

  @override
  State<_BulkItemRow> createState() => _BulkItemRowState();
}

class _BulkItemRowState extends State<_BulkItemRow> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  Worker? _worker;

  /// Campo de nota de la fila abierto (se abre con el ícono de nota).
  bool _showNote = false;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.item.amount.value?.toString() ?? '',
    );
    _note = TextEditingController(text: widget.item.notes.value);
    // Si el número cambia desde fuera ("Poner en Cero", "Deshacer"), el
    // campo lo refleja.
    _worker = ever<int?>(widget.item.amount, (v) {
      final text = v?.toString() ?? '';
      if (_amount.text != text) {
        _amount.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Obx(() {
      final selected = item.isSelected.value;
      final known = item.stockKnown;
      final mode = item.mode.value;
      final plan = item.plan;
      final error = item.errorText;

      final name = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (item.product.sku.isNotEmpty)
            Text(
              item.product.sku,
              style: const TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 12,
              ),
            ),
        ],
      );

      final stock =
          known
              ? Text(
                'Hay ${AppFormatters.formatStock(item.currentQuantity)}',
                style: const TextStyle(
                  color: ElegantLightTheme.primaryBlue,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              )
              : item.stockUnconfirmed
              ? Tooltip(
                message: kUnconfirmedStockMessage,
                child: BrebChip(
                  label:
                      'Hay ${AppFormatters.formatStock(item.currentQuantity)} (sin confirmar)',
                  color: ElegantLightTheme.warningOrange,
                  icon: Icons.hourglass_top,
                ),
              )
              : const BrebChip(
                label: 'No se pudo leer cuánto hay',
                color: ElegantLightTheme.errorRed,
                icon: Icons.error_outline,
              );

      final selector = _ModeSelector(
        mode: mode,
        enabled: known,
        onChanged: item.setMode,
      );

      final field = SizedBox(
        width: widget.mobile ? 96 : 104,
        child: TextField(
          controller: _amount,
          enabled: known && mode != null,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ElegantLightTheme.textPrimary,
          ),
          decoration: brebInputDecoration(label: 'Cantidad').copyWith(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
          ),
          onChanged:
              (t) => item.setAmount(t.trim().isEmpty ? null : int.tryParse(t)),
        ),
      );

      final Widget result;
      if (!known) {
        result = const SizedBox.shrink();
      } else if (error != null) {
        result = Text(
          error,
          style: const TextStyle(
            color: ElegantLightTheme.errorRed,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
      } else if (plan.shortResultText != null) {
        result = ArrowText(
          plan.shortResultText!,
          style: TextStyle(
            color:
                item.adjustmentDifference > 0
                    ? ElegantLightTheme.successGreen
                    : ElegantLightTheme.errorRed,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        );
      } else {
        result = Text(
          mode == null ? 'Sin cambios' : 'Escribe la cantidad',
          style: const TextStyle(
            color: ElegantLightTheme.textTertiary,
            fontSize: 13,
          ),
        );
      }

      final check = Checkbox(
        value: selected,
        onChanged: (_) => widget.onToggle(),
        activeColor: ElegantLightTheme.primaryBlue,
        visualDensity: VisualDensity.compact,
      );
      final hasNote = item.notes.value.trim().isNotEmpty;
      final noteButton = IconButton(
        onPressed: known ? () => setState(() => _showNote = !_showNote) : null,
        tooltip: 'Nota de este producto',
        icon: Icon(
          hasNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
          size: 20,
        ),
        color:
            hasNote
                ? ElegantLightTheme.primaryBlue
                : ElegantLightTheme.textSecondary,
      );
      final remove = IconButton(
        onPressed: widget.onRemove,
        tooltip: 'Quitar de la lista',
        icon: const Icon(Icons.close, size: 20),
        color: ElegantLightTheme.textSecondary,
      );

      final note =
          (known && (_showNote || hasNote))
              ? Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: _note,
                  onChanged: (v) => item.notes.value = v,
                  style: const TextStyle(fontSize: 13),
                  decoration: brebInputDecoration(
                    label: 'Nota de este producto (opcional)',
                  ).copyWith(isDense: true),
                ),
              )
              : const SizedBox.shrink();

      final unconfirmedNotice =
          item.stockUnconfirmed
              ? const Padding(
                padding: EdgeInsets.only(top: 10),
                child: BrebNotice.warning(kUnconfirmedStockMessage),
              )
              : const SizedBox.shrink();

      final borderColor =
          error != null
              ? ElegantLightTheme.errorRed
              : selected
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.45)
              : ElegantLightTheme.textTertiary.withValues(alpha: 0.3);

      final body =
          widget.mobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      check,
                      const SizedBox(width: 4),
                      Expanded(child: name),
                      noteButton,
                      remove,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      stock,
                      const SizedBox(width: 12),
                      Expanded(child: result),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: selector),
                      const SizedBox(width: 10),
                      field,
                    ],
                  ),
                  note,
                  unconfirmedNotice,
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      check,
                      const SizedBox(width: 4),
                      Expanded(flex: 4, child: name),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: known ? 90 : 210,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: stock,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 156, child: selector),
                      const SizedBox(width: 10),
                      field,
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: result),
                      noteButton,
                      remove,
                    ],
                  ),
                  note,
                  unconfirmedNotice,
                ],
              );

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedOpacity(
          duration: ElegantLightTheme.fastAnimation,
          opacity: selected ? 1 : 0.6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: ElegantLightTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: error != null ? 1.5 : 1,
              ),
            ),
            child: body,
          ),
        ),
      );
    });
  }
}

/// Selector + / − / = de una fila.
class _ModeSelector extends StatelessWidget {
  final StockAdjustMode? mode;
  final bool enabled;
  final ValueChanged<StockAdjustMode> onChanged;

  const _ModeSelector({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in AdjustModeStyle.all) ...[
          Expanded(child: _segment(s)),
          if (s != AdjustModeStyle.all.last) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _segment(AdjustModeStyle s) {
    final selected = mode == s.mode;
    final radius = BorderRadius.circular(10);
    final tooltip = switch (s.mode) {
      StockAdjustMode.add => 'Sumar unidades',
      StockAdjustMode.subtract => 'Restar unidades',
      StockAdjustMode.exact => 'Poner cantidad exacta',
    };
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Material(
          color: selected ? s.color : ElegantLightTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? s.color : s.color.withValues(alpha: 0.45),
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? () => onChanged(s.mode) : null,
            child: SizedBox(
              height: 42,
              child: Icon(
                s.icon,
                size: 22,
                color: selected ? Colors.white : s.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
