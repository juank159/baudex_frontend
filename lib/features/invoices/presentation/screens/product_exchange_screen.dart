// lib/features/invoices/presentation/screens/product_exchange_screen.dart
//
// Pantalla "Cambio de producto" — el cliente devuelve items de una factura
// previa Y lleva otros nuevos en una sola transacción.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../credit_notes/domain/entities/credit_note.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/product_exchange.dart';
import '../controllers/product_exchange_controller.dart';

class ProductExchangeScreen extends GetView<ProductExchangeController> {
  const ProductExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Cambio de producto'),
        backgroundColor: ElegantLightTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: ElegantLightTheme.primaryBlue,
            ),
          );
        }
        if (controller.error != null && controller.originalInvoice == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    controller.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }
        final invoice = controller.originalInvoice;
        if (invoice == null) {
          return const Center(child: Text('Factura no encontrada'));
        }

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InvoiceHeader(invoice: invoice),
                  const SizedBox(height: 16),
                  _ReturnedSection(invoice: invoice),
                  const SizedBox(height: 16),
                  _DeliveredSection(),
                  const SizedBox(height: 16),
                  _SettlementSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _Footer(),
          ],
        );
      }),
    );
  }
}

// ==================== HEADER ====================

class _InvoiceHeader extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceHeader({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined,
              color: ElegantLightTheme.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Factura ${invoice.number}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${invoice.customer?.fullName ?? "Cliente"} · ${AppFormatters.formatCurrency(invoice.total)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
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

// ==================== RETURNED ITEMS ====================

class _ReturnedSection extends GetView<ProductExchangeController> {
  final Invoice invoice;
  const _ReturnedSection({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items devueltos',
      icon: Icons.undo,
      iconColor: Colors.orange,
      child: Column(
        children: invoice.items
            .map((item) => _ReturnedItemRow(invoiceItem: item))
            .toList(),
      ),
    );
  }
}

class _ReturnedItemRow extends GetView<ProductExchangeController> {
  final InvoiceItem invoiceItem;
  const _ReturnedItemRow({required this.invoiceItem});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final returned = controller.returnedItems[invoiceItem.id];
      final qty = returned?.quantity ?? 0;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceItem.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Facturado: ${invoiceItem.quantity.toStringAsFixed(0)} × ${AppFormatters.formatCurrency(invoiceItem.unitPrice)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Stepper de cantidad
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: qty > 0
                        ? () => controller.setReturnedItem(invoiceItem, qty - 1)
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      qty.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: qty < invoiceItem.quantity
                        ? () => controller.setReturnedItem(invoiceItem, qty + 1)
                        : null,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ==================== NEW ITEMS ====================

class _DeliveredSection extends GetView<ProductExchangeController> {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items entregados',
      icon: Icons.shopping_bag_outlined,
      iconColor: ElegantLightTheme.primaryBlue,
      child: Obx(() {
        final items = controller.newItems;
        return Column(
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Sin items entregados — solo devolución',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ...items.asMap().entries.map(
                  (entry) =>
                      _NewItemRow(index: entry.key, item: entry.value),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar item entregado'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    final descCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar item entregado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceCtrl,
              decoration:
                  const InputDecoration(labelText: 'Precio unitario'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final qty = double.tryParse(qtyCtrl.text) ?? 0;
      final price = double.tryParse(priceCtrl.text) ?? 0;
      if (descCtrl.text.isNotEmpty && qty > 0 && price > 0) {
        controller.addNewItem(ExchangeNewItem(
          description: descCtrl.text,
          quantity: qty,
          unitPrice: price,
        ));
      }
    }
  }
}

class _NewItemRow extends GetView<ProductExchangeController> {
  final int index;
  final ExchangeNewItem item;
  const _NewItemRow({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  '${item.quantity.toStringAsFixed(0)} × ${AppFormatters.formatCurrency(item.unitPrice)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.formatCurrency(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () => controller.removeNewItem(index),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

// ==================== SETTLEMENT ====================

class _SettlementSection extends GetView<ProductExchangeController> {
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Conciliación',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Colors.green,
      child: Obx(() {
        final diff = controller.difference;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(
              'Total devuelto',
              AppFormatters.formatCurrency(controller.totalReturned),
              Colors.orange,
            ),
            _row(
              'Total entregado',
              AppFormatters.formatCurrency(controller.totalDelivered),
              ElegantLightTheme.primaryBlue,
            ),
            const Divider(),
            _row(
              controller.differenceLabel,
              AppFormatters.formatCurrency(diff.abs()),
              diff < 0 ? Colors.green : Colors.red,
              bold: true,
            ),
            const SizedBox(height: 12),
            if (diff != 0) ...[
              const Text(
                'Cómo conciliar:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              ...controller.availableSettlementModes.map(
                (mode) => RadioListTile<ExchangeSettlementMode>(
                  title: Text(_settlementLabel(mode)),
                  subtitle: Text(
                    _settlementDescription(mode),
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: mode,
                  groupValue: controller.settlementMode,
                  onChanged: (v) {
                    if (v != null) controller.settlementMode = v;
                  },
                  dense: true,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _settlementLabel(ExchangeSettlementMode m) {
    switch (m) {
      case ExchangeSettlementMode.cashRefund:
        return 'Devolver efectivo al cliente';
      case ExchangeSettlementMode.storeCredit:
        return 'Crédito a favor del cliente';
      case ExchangeSettlementMode.cashPayment:
        return 'Cliente paga la diferencia';
      case ExchangeSettlementMode.exact:
        return 'Cambio neto (sin diferencia)';
    }
  }

  String _settlementDescription(ExchangeSettlementMode m) {
    switch (m) {
      case ExchangeSettlementMode.cashRefund:
        return 'Sale dinero de caja';
      case ExchangeSettlementMode.storeCredit:
        return 'El cliente lo usa en compras futuras (recomendado)';
      case ExchangeSettlementMode.cashPayment:
        return 'El cliente paga ahora';
      case ExchangeSettlementMode.exact:
        return '';
    }
  }
}

// ==================== FOOTER ====================

class _Footer extends GetView<ProductExchangeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canProcess = controller.returnedItems.isNotEmpty;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canProcess && !controller.isProcessing
                  ? () async {
                      final result = await controller.processExchange();
                      if (result != null) {
                        Get.back(result: result);
                      }
                    }
                  : null,
              icon: controller.isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(
                controller.isProcessing
                    ? 'Procesando...'
                    : 'Procesar cambio',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ==================== HELPER WIDGET ====================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Wrapper para que Linter no marque CreditNoteReason como unused.
// ignore: unused_element
void _keepImports(CreditNoteReason r) {}
