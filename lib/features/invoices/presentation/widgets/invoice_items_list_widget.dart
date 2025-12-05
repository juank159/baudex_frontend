// lib/features/invoices/presentation/widgets/invoice_items_list_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../domain/entities/invoice_item.dart';

class InvoiceItemsListWidget extends StatelessWidget {
  final List<InvoiceItem> items;
  final Function(InvoiceItem)? onItemTap;
  final Function(InvoiceItem)? onItemEdit;
  final Function(InvoiceItem)? onItemDelete;
  final bool isEditable;
  final bool showProductInfo;

  const InvoiceItemsListWidget({
    super.key,
    required this.items,
    this.onItemTap,
    this.onItemEdit,
    this.onItemDelete,
    this.isEditable = false,
    this.showProductInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return ResponsiveLayout(
      mobile: _buildMobileList(context),
      tablet: _buildTabletList(context),
      desktop: _buildDesktopTable(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay items en esta factura',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context) {
    return Column(
      children:
          items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildMobileItemCard(context, item, index);
          }).toList(),
    );
  }

  Widget _buildMobileItemCard(
    BuildContext context,
    InvoiceItem item,
    int index,
  ) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onItemTap != null ? () => onItemTap!(item) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black, // ✅ AGREGADO COLOR NEGRO
                          ),
                        ),
                        if (showProductInfo &&
                            item.productSku?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SKU: ${item.productSku}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isEditable) _buildActionButtons(context, item),
                ],
              ),
              const SizedBox(height: 12),

              // Información de cantidad y precio
              Row(
                children: [
                  _buildInfoChip(
                    '${item.quantity} ${item.displayUnit}',
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    AppFormatters.formatCurrency(item.unitPrice),
                    Icons.attach_money,
                    Colors.green,
                  ),
                ],
              ),

              // Descuentos si aplican
              if (item.totalDiscount > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.discount,
                        color: Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Descuento: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (item.discountPercentage > 0)
                        Text(
                          '${item.discountPercentage}% ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      Text(
                        '(${AppFormatters.formatCurrency(item.totalDiscount)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),
              const Divider(),

              // Subtotal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(item.finalSubtotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),

              // Notas si existen
              if (item.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Nota: ${item.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletList(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Cantidad',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Precio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Descuento',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Subtotal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (isEditable) SizedBox(width: 80),
            ],
          ),
        ),

        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildTabletItemRow(context, item, index);
        }),
      ],
    );
  }

  Widget _buildTabletItemRow(
    BuildContext context,
    InvoiceItem item,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: InkWell(
        onTap: onItemTap != null ? () => onItemTap!(item) : null,
        child: Row(
          children: [
            // Descripción
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black, // ✅ AGREGADO COLOR NEGRO
                    ),
                  ),
                  if (showProductInfo &&
                      item.productSku?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${item.productSku}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (item.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Cantidad
            Expanded(
              flex: 1,
              child: Text('${item.quantity} ${item.displayUnit}'),
            ),

            // Precio
            Expanded(
              flex: 1,
              child: Text(AppFormatters.formatCurrency(item.unitPrice)),
            ),

            // Descuento
            Expanded(
              flex: 1,
              child:
                  item.totalDiscount > 0
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.discountPercentage > 0)
                            Text('${item.discountPercentage}%'),
                          Text(
                            AppFormatters.formatCurrency(item.totalDiscount),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      )
                      : const Text('-'),
            ),

            // Subtotal
            Expanded(
              flex: 1,
              child: Text(
                AppFormatters.formatCurrency(item.finalSubtotal),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            // Acciones
            if (isEditable) _buildActionButtons(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // Para numeración
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Descripción',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Cantidad',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Precio Unit.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Descuento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Subtotal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isEditable) const SizedBox(width: 100),
              ],
            ),
          ),

          // Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildDesktopTableRow(context, item, index);
          }),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(
    BuildContext context,
    InvoiceItem item,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
      ),
      child: InkWell(
        onTap: onItemTap != null ? () => onItemTap!(item) : null,
        child: Row(
          children: [
            // Número
            SizedBox(
              width: 40,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Descripción
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black, // ✅ AGREGADO COLOR NEGRO
                    ),
                  ),
                  if (showProductInfo &&
                      item.productSku?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            'SKU: ${item.productSku}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.productBarcode?.isNotEmpty == true) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'Código: ${item.productBarcode}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (item.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Cantidad
            Expanded(
              flex: 1,
              child: Text(
                '${item.quantity} ${item.displayUnit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            // Precio
            Expanded(
              flex: 1,
              child: Text(
                AppFormatters.formatCurrency(item.unitPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            // Descuento
            Expanded(
              flex: 1,
              child:
                  item.totalDiscount > 0
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.discountPercentage > 0)
                            Text(
                              '${item.discountPercentage}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            AppFormatters.formatCurrency(item.totalDiscount),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        '-',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
            ),

            // Subtotal
            Expanded(
              flex: 1,
              child: Text(
                AppFormatters.formatCurrency(item.finalSubtotal),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
              ),
            ),

            // Acciones
            if (isEditable) _buildActionButtons(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, InvoiceItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onItemEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () => onItemEdit!(item),
            tooltip: 'Editar',
            color: Colors.blue.shade600,
          ),
        if (onItemDelete != null)
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: () => onItemDelete!(item),
            tooltip: 'Eliminar',
            color: Colors.red.shade600,
          ),
      ],
    );
  }
}
