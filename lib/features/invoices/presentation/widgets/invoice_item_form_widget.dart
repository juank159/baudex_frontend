// lib/features/invoices/presentation/widgets/invoice_item_form_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../invoices/data/models/invoice_form_models.dart';

class InvoiceItemFormWidget extends StatefulWidget {
  final InvoiceItemFormData item;
  final int? index;
  final Function(InvoiceItemFormData)? onUpdate;
  final Function(InvoiceItemFormData)? onSave;
  final VoidCallback? onRemove;
  final VoidCallback? onCancel;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isDialog;
  final bool isExpanded;

  const InvoiceItemFormWidget({
    super.key,
    required this.item,
    this.index,
    this.onUpdate,
    this.onSave,
    this.onRemove,
    this.onCancel,
    this.onMoveUp,
    this.onMoveDown,
    this.isDialog = false,
    this.isExpanded = false,
  });

  @override
  State<InvoiceItemFormWidget> createState() => _InvoiceItemFormWidgetState();
}

class _InvoiceItemFormWidgetState extends State<InvoiceItemFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _discountPercentageController;
  late TextEditingController _discountAmountController;
  late TextEditingController _unitController;
  late TextEditingController _notesController;

  bool _isExpanded = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _isExpanded = widget.isExpanded || widget.isDialog;
    _isEditing = widget.isDialog || widget.item.id.isEmpty;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _unitPriceController = TextEditingController(
      text: widget.item.unitPrice.toString(),
    );
    _discountPercentageController = TextEditingController(
      text: widget.item.discountPercentage.toString(),
    );
    _discountAmountController = TextEditingController(
      text: widget.item.discountAmount.toString(),
    );
    _unitController = TextEditingController(text: widget.item.unit ?? 'pcs');
    _notesController = TextEditingController(text: widget.item.notes ?? '');

    // Add listeners for real-time updates
    _descriptionController.addListener(_onFieldChanged);
    _quantityController.addListener(_onFieldChanged);
    _unitPriceController.addListener(_onFieldChanged);
    _discountPercentageController.addListener(_onFieldChanged);
    _discountAmountController.addListener(_onFieldChanged);
    _unitController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  void _disposeControllers() {
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountPercentageController.dispose();
    _discountAmountController.dispose();
    _unitController.dispose();
    _notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) {
      return _buildDialogContent(context);
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child:
          _isExpanded
              ? _buildExpandedContent(context)
              : _buildCollapsedContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDialogHeader(context),
          const SizedBox(height: 20),
          _buildForm(context),
          const SizedBox(height: 20),
          _buildDialogActions(context),
        ],
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.shopping_cart,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          widget.item.id.isEmpty ? 'Agregar Item' : 'Editar Item',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = true),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.index != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.index! + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.description.isNotEmpty
                            ? widget.item.description
                            : 'Descripción del item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.item.quantity} ${widget.item.unit} × \$${widget.item.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${widget.item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (widget.item.discountPercentage > 0 ||
                        widget.item.discountAmount > 0)
                      Text(
                        'Desc: ${widget.item.discountPercentage > 0 ? "${widget.item.discountPercentage}%" : "\$${widget.item.discountAmount.toStringAsFixed(2)}"}',
                        style: TextStyle(
                          color: Colors.orange.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                _buildActionButtons(context),
              ],
            ),
            if (widget.item.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.item.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpandedHeader(context),
          const SizedBox(height: 16),
          _buildForm(context),
          const SizedBox(height: 16),
          _buildExpandedActions(context),
        ],
      ),
    );
  }

  Widget _buildExpandedHeader(BuildContext context) {
    return Row(
      children: [
        if (widget.index != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Item ${widget.index! + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Icon(Icons.edit, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          _isEditing ? 'Editando Item' : 'Item de Factura',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up),
          onPressed: () => setState(() => _isExpanded = false),
          tooltip: 'Contraer',
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Descripción
          CustomTextField(
            controller: _descriptionController,
            label: 'Descripción *',
            hint: 'Nombre del producto o servicio',
            prefixIcon: Icons.inventory_2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La descripción es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Cantidad y Unidad
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _quantityController,
                  label: 'Cantidad *',
                  hint: '1',
                  prefixIcon: Icons.numbers,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requerido';
                    }
                    final quantity = double.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Cantidad inválida';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: CustomTextField(
                  controller: _unitController,
                  label: 'Unidad',
                  hint: 'pcs',
                  prefixIcon: Icons.straighten,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Precio unitario
          CustomTextField(
            controller: _unitPriceController,
            label: 'Precio Unitario *',
            hint: '0.00',
            prefixIcon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El precio es requerido';
              }
              final price = double.tryParse(value);
              if (price == null || price < 0) {
                return 'Precio inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Descuentos
          ExpansionTile(
            title: const Text('Descuentos (Opcional)'),
            leading: const Icon(Icons.discount),
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _discountPercentageController,
                      label: 'Descuento %',
                      hint: '0',
                      prefixIcon: Icons.percent,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final discount = double.tryParse(value);
                          if (discount == null ||
                              discount < 0 ||
                              discount > 100) {
                            return 'Entre 0 y 100';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _discountAmountController,
                      label: 'Descuento \$',
                      hint: '0.00',
                      prefixIcon: Icons.money_off,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final discount = double.tryParse(value);
                          if (discount == null || discount < 0) {
                            return 'Mayor a 0';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),

          // Notas
          CustomTextField(
            controller: _notesController,
            label: 'Notas (Opcional)',
            hint: 'Información adicional...',
            prefixIcon: Icons.note,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Cálculo en tiempo real
          _buildCalculationSummary(context),
        ],
      ),
    );
  }

  Widget _buildCalculationSummary(BuildContext context) {
    final currentItem = _getCurrentItemData();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del Item',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Base:',
            '${currentItem.quantity} × \$${currentItem.unitPrice.toStringAsFixed(2)}',
            currentItem.quantity * currentItem.unitPrice,
          ),
          if (currentItem.discountPercentage > 0 ||
              currentItem.discountAmount > 0) ...[
            _buildSummaryRow(
              'Descuento:',
              '',
              -(currentItem.quantity *
                      currentItem.unitPrice *
                      currentItem.discountPercentage /
                      100 +
                  currentItem.discountAmount),
            ),
          ],
          const Divider(),
          _buildSummaryRow(
            'Subtotal:',
            '',
            currentItem.subtotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String description,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue.shade800 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 8),
          if (description.isNotEmpty)
            Expanded(
              child: Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
              ),
            ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.blue.shade800 : Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onMoveUp != null)
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
            onPressed: widget.onMoveUp,
            tooltip: 'Mover arriba',
          ),
        if (widget.onMoveDown != null)
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            onPressed: widget.onMoveDown,
            tooltip: 'Mover abajo',
          ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => setState(() => _isExpanded = true),
          tooltip: 'Editar',
          color: Colors.blue.shade600,
        ),
        if (widget.onRemove != null)
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: widget.onRemove,
            tooltip: 'Eliminar',
            color: Colors.red.shade600,
          ),
      ],
    );
  }

  Widget _buildExpandedActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            type: ButtonType.outline,
            onPressed: () {
              if (widget.isDialog && widget.onCancel != null) {
                widget.onCancel!();
              } else {
                setState(() => _isExpanded = false);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: 'Guardar Cambios',
            icon: Icons.save,
            onPressed: _saveChanges,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Cancelar',
            type: ButtonType.outline,
            onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: CustomButton(
            text: widget.item.id.isEmpty ? 'Agregar Item' : 'Guardar Cambios',
            icon: widget.item.id.isEmpty ? Icons.add : Icons.save,
            onPressed: _saveChanges,
          ),
        ),
      ],
    );
  }

  void _onFieldChanged() {
    if (widget.onUpdate != null && !widget.isDialog) {
      final updatedItem = _getCurrentItemData();
      widget.onUpdate!(updatedItem);
    }
  }

  InvoiceItemFormData _getCurrentItemData() {
    return InvoiceItemFormData(
      id: widget.item.id,
      description: _descriptionController.text,
      quantity: double.tryParse(_quantityController.text) ?? 1,
      unitPrice: double.tryParse(_unitPriceController.text) ?? 0,
      discountPercentage:
          double.tryParse(_discountPercentageController.text) ?? 0,
      discountAmount: double.tryParse(_discountAmountController.text) ?? 0,
      unit: _unitController.text.isNotEmpty ? _unitController.text : 'pcs',
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      productId: widget.item.productId,
    );
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final updatedItem = _getCurrentItemData();

      if (widget.onSave != null) {
        widget.onSave!(updatedItem);
      } else if (widget.onUpdate != null) {
        widget.onUpdate!(updatedItem);
        setState(() => _isExpanded = false);
      }
    }
  }
}
