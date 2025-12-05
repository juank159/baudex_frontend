import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/purchase_order.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class CustomReceiveQuantities {
  final String itemId;
  final int orderedQuantity;
  int receivedQuantity;
  int damagedQuantity;
  int missingQuantity;
  String? notes;
  String? supplierLotNumber;
  DateTime? expirationDate;
  bool isExpanded;

  CustomReceiveQuantities({
    required this.itemId,
    required this.orderedQuantity,
    this.receivedQuantity = 0,
    this.damagedQuantity = 0,
    this.missingQuantity = 0,
    this.notes,
    this.supplierLotNumber,
    this.expirationDate,
    this.isExpanded = false, // Por defecto colapsado
  });

  // Los faltantes no se "procesan", simplemente no llegaron
  int get totalProcessed => receivedQuantity + damagedQuantity;
  int get totalAccounted =>
      receivedQuantity + damagedQuantity + missingQuantity;
  int get pendingQuantity => orderedQuantity - totalAccounted;
  bool get isValid => totalAccounted <= orderedQuantity;
  bool get isComplete => totalAccounted == orderedQuantity;
}

class CustomReceiveDialog extends StatefulWidget {
  final List<PurchaseOrderItem> items;
  final Function(Map<String, CustomReceiveQuantities>) onConfirm;

  const CustomReceiveDialog({
    super.key,
    required this.items,
    required this.onConfirm,
  });

  @override
  State<CustomReceiveDialog> createState() => _CustomReceiveDialogState();
}

class _CustomReceiveDialogState extends State<CustomReceiveDialog> {
  late Map<String, CustomReceiveQuantities> quantities;
  late Map<String, TextEditingController> receivedControllers;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    quantities = {};
    receivedControllers = {};

    for (var item in widget.items) {
      final quantity = CustomReceiveQuantities(
        itemId: item.id,
        orderedQuantity: item.quantity.toInt(),
        receivedQuantity: 0, // Se calculará automáticamente
        damagedQuantity: 0,
        missingQuantity: 0,
      );

      // Calcular la cantidad recibida automáticamente
      _autoAdjustQuantities(quantity);

      quantities[item.id] = quantity;
      receivedControllers[item.id] = TextEditingController(
        text: quantity.receivedQuantity.toString(),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Dispose de todos los controllers
    for (var controller in receivedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _autoAdjustQuantities(CustomReceiveQuantities quantity) {
    // Cálculo automático: recibidos = total - dañados - faltantes
    int calculatedReceived =
        quantity.orderedQuantity -
        quantity.damagedQuantity -
        quantity.missingQuantity;

    // Asegurar que la cantidad recibida no sea negativa
    quantity.receivedQuantity = calculatedReceived.clamp(
      0,
      quantity.orderedQuantity,
    );

    // Actualizar el controlador de texto si existe
    final controller = receivedControllers[quantity.itemId];
    if (controller != null) {
      controller.text = quantity.receivedQuantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              ElegantLightTheme.backgroundColor.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(child: _buildContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withOpacity(0.1),
            ElegantLightTheme.primaryBlueLight.withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2,
              color: ElegantLightTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recepción Personalizada',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Especifica las cantidades recibidas por producto',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: ElegantLightTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: widget.items.map((item) => _buildItemCard(item)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(PurchaseOrderItem item) {
    final quantity = quantities[item.id]!;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ), // Reducido de 16 a 8 (50% menos)
      padding: const EdgeInsets.all(12), // Reducido de 20 a 12 (40% menos)
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              quantity.isValid
                  ? (quantity.isComplete
                      ? const Color(0xFF10B981)
                      : ElegantLightTheme.primaryBlue)
                  : const Color(0xFFEF4444),
          width: quantity.isValid ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del producto (siempre visible)
          GestureDetector(
            onTap: () {
              setState(() {
                quantity.isExpanded = !quantity.isExpanded;
              });
            },
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Vista colapsada: mostrar cantidades básicas
                      if (!quantity.isExpanded)
                        Text(
                          'Pedido: ${item.quantity} • Recibido: ${quantity.receivedQuantity}',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      // Vista expandida: mostrar código del producto
                      if (quantity.isExpanded)
                        Text(
                          'Código: ${item.productCode ?? 'N/A'}',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pedido: ${item.quantity.toInt()}',
                    style: TextStyle(
                      color: ElegantLightTheme.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  quantity.isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: ElegantLightTheme.textSecondary,
                  size: 24,
                ),
              ],
            ),
          ),

          // Contenido expandible
          if (quantity.isExpanded) ...[
            const SizedBox(height: 8),

            // Campos de cantidad
            Row(
              children: [
                Expanded(
                  child: _buildQuantityField(
                    label: 'Recibido (Calculado)',
                    value: quantity.receivedQuantity,
                    color: const Color(0xFF10B981), // Verde éxito
                    readOnly: true,
                    controller: receivedControllers[item.id],
                    onChanged: (value) {
                      // No hacer nada, es de solo lectura
                    },
                  ),
                ),
                const SizedBox(width: 8), // Reducido de 12 a 8
                Expanded(
                  child: _buildQuantityField(
                    label: 'Dañado',
                    value: quantity.damagedQuantity,
                    color: const Color(0xFFF59E0B), // Naranja advertencia
                    onChanged: (value) {
                      setState(() {
                        quantity.damagedQuantity = value;
                        // Recalcular automáticamente para mantener coherencia
                        _autoAdjustQuantities(quantity);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8), // Reducido de 12 a 8
                Expanded(
                  child: _buildQuantityField(
                    label: 'Faltante',
                    value: quantity.missingQuantity,
                    color: const Color(0xFFEF4444), // Rojo error
                    onChanged: (value) {
                      setState(() {
                        quantity.missingQuantity = value;
                        // Recalcular automáticamente para mantener coherencia
                        _autoAdjustQuantities(quantity);
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6), // Reducido de 12 a 6
            // Status indicator
            _buildStatusIndicator(quantity),

            const SizedBox(height: 8), // Reducido de 16 a 8
            // Campo de notas
            TextField(
              style: TextStyle(color: ElegantLightTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                labelStyle: TextStyle(color: ElegantLightTheme.textSecondary),
                hintText: 'Ej: Producto dañado por transporte',
                hintStyle: TextStyle(
                  color: ElegantLightTheme.textSecondary.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: ElegantLightTheme.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ElegantLightTheme.primaryBlue),
                ),
              ),
              maxLines: 1, // Reducido de 2 a 1 línea
              onChanged: (value) {
                quantity.notes = value.isEmpty ? null : value;
              },
            ),
          ], // Cierre del condicional if (quantity.isExpanded)
        ],
      ),
    );
  }

  Widget _buildQuantityField({
    required String label,
    required int value,
    required Color color,
    required Function(int) onChanged,
    bool readOnly = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2), // Reducido de 4 a 2
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: TextFormField(
            controller: controller,
            initialValue: controller == null ? value.toString() : null,
            style: TextStyle(
              color: readOnly ? color.withOpacity(0.7) : color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            keyboardType: readOnly ? TextInputType.none : TextInputType.number,
            readOnly: readOnly,
            inputFormatters:
                readOnly ? [] : [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
              ), // Reducido de 12 a 8
              suffixIcon:
                  readOnly
                      ? Icon(
                        Icons.calculate,
                        color: color.withOpacity(0.5),
                        size: 16,
                      )
                      : null,
            ),
            onChanged:
                readOnly
                    ? null
                    : (text) {
                      final newValue = int.tryParse(text) ?? 0;
                      onChanged(newValue);
                    },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(CustomReceiveQuantities quantity) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!quantity.isValid) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Error: Total excede la cantidad pedida';
      statusIcon = Icons.error;
    } else if (quantity.isComplete) {
      statusColor = const Color(0xFF10B981);
      statusText = 'Completo: Todas las cantidades registradas';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Pendiente: ${quantity.pendingQuantity} sin procesar';
      statusIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isValid = quantities.values.every((q) => q.isValid);
    final hasChanges = quantities.values.any(
      (q) =>
          q.receivedQuantity != q.orderedQuantity ||
          q.damagedQuantity > 0 ||
          q.missingQuantity > 0,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed:
                isValid
                    ? () {
                      widget.onConfirm(quantities);
                      Navigator.of(context).pop();
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isValid
                      ? ElegantLightTheme.primaryBlue
                      : ElegantLightTheme.textSecondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Confirmar Recepción',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
