// lib/features/invoices/presentation/screens/product_exchange_screen.dart
//
// Pantalla "Cambio de producto" — responsive (mobile / tablet / desktop).
//
// Layout:
//   - Mobile (<700px):  single column, secciones apiladas verticalmente.
//   - Tablet/Desktop:    2 columnas (devuelto izq | entregado der),
//                        conciliación abajo full-width.
//
// Features:
//   • Selector de productos del catálogo (busca en ProductsController.products)
//   • Selector de bank account (opcional) cuando hay diferencia
//   • Sticky footer con resumen + botón procesar
//   • Snack de éxito ofreciendo opciones (volver, imprimir cuando se conecte
//     impresora térmica si está disponible)

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../bank_accounts/presentation/controllers/bank_accounts_controller.dart';
import '../../../credit_notes/domain/entities/credit_note.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/controllers/products_controller.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/product_exchange.dart';
import '../controllers/product_exchange_controller.dart';

class ProductExchangeScreen extends GetView<ProductExchangeController> {
  const ProductExchangeScreen({super.key});

  // ==================== BREAKPOINTS ====================
  static const double _mobileBreak = 700;
  static const double _tabletBreak = 1100;

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
          return _buildError(controller.error!);
        }
        final invoice = controller.originalInvoice;
        if (invoice == null) {
          return const Center(child: Text('Factura no encontrada'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < _mobileBreak;
            final isTablet = width >= _mobileBreak && width < _tabletBreak;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InvoiceHeader(invoice: invoice, isMobile: isMobile),
                        SizedBox(height: isMobile ? 12 : 16),
                        if (isMobile)
                          _buildMobileLayout(invoice)
                        else
                          _buildWideLayout(invoice, isTablet),
                        SizedBox(height: isMobile ? 12 : 16),
                        _SettlementSection(isMobile: isMobile),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
                _Footer(isMobile: isMobile),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildMobileLayout(Invoice invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReturnedSection(invoice: invoice, isMobile: true),
        const SizedBox(height: 12),
        _DeliveredSection(isMobile: true),
      ],
    );
  }

  Widget _buildWideLayout(Invoice invoice, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ReturnedSection(invoice: invoice, isMobile: false)),
        SizedBox(width: isTablet ? 12 : 16),
        Expanded(child: _DeliveredSection(isMobile: false)),
      ],
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HEADER ====================

class _InvoiceHeader extends StatelessWidget {
  final Invoice invoice;
  final bool isMobile;
  const _InvoiceHeader({required this.invoice, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: ElegantLightTheme.primaryBlue,
            size: isMobile ? 20 : 24,
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Factura ${invoice.number}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${invoice.customer?.fullName ?? "Cliente"} · ${AppFormatters.formatCurrency(invoice.total)}',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
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
  final bool isMobile;
  const _ReturnedSection({required this.invoice, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items devueltos',
      icon: Icons.undo,
      iconColor: Colors.orange,
      isMobile: isMobile,
      child: Column(
        children: invoice.items
            .map((item) =>
                _ReturnedItemRow(invoiceItem: item, isMobile: isMobile))
            .toList(),
      ),
    );
  }
}

class _ReturnedItemRow extends GetView<ProductExchangeController> {
  final InvoiceItem invoiceItem;
  final bool isMobile;
  const _ReturnedItemRow({required this.invoiceItem, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final returned = controller.returnedItems[invoiceItem.id];
      final qty = returned?.quantity ?? 0;
      final selected = qty > 0;

      return Container(
        margin: EdgeInsets.symmetric(vertical: isMobile ? 4 : 6),
        padding: EdgeInsets.all(isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.orange.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Colors.orange.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceItem.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 12 : 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Facturado: ${invoiceItem.quantity.toStringAsFixed(0)} × ${AppFormatters.formatCurrency(invoiceItem.unitPrice)}',
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: isMobile ? 14 : 16),
                    onPressed: qty > 0
                        ? () => controller.setReturnedItem(invoiceItem, qty - 1)
                        : null,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 28 : 32,
                      minHeight: isMobile ? 28 : 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  SizedBox(
                    width: isMobile ? 30 : 36,
                    child: Text(
                      qty.toStringAsFixed(0),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: isMobile ? 14 : 16),
                    onPressed: qty < invoiceItem.quantity
                        ? () => controller.setReturnedItem(invoiceItem, qty + 1)
                        : null,
                    constraints: BoxConstraints(
                      minWidth: isMobile ? 28 : 32,
                      minHeight: isMobile ? 28 : 32,
                    ),
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
  final bool isMobile;
  const _DeliveredSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Items entregados',
      icon: Icons.shopping_bag_outlined,
      iconColor: ElegantLightTheme.primaryBlue,
      isMobile: isMobile,
      child: Obx(() {
        final items = controller.newItems;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin items entregados — solo devolución',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ...items.asMap().entries.map(
                  (entry) => _NewItemRow(
                    index: entry.key,
                    item: entry.value,
                    isMobile: isMobile,
                  ),
                ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showProductPicker(context),
              icon: Icon(Icons.add_shopping_cart, size: isMobile ? 16 : 18),
              label: Text(
                'Agregar producto',
                style: TextStyle(fontSize: isMobile ? 12 : 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showProductPicker(BuildContext context) async {
    final picked = await Get.dialog<ExchangeNewItem>(
      const _ProductPickerDialog(),
    );
    if (picked != null) {
      controller.addNewItem(picked);
    }
  }
}

class _NewItemRow extends GetView<ProductExchangeController> {
  final int index;
  final ExchangeNewItem item;
  final bool isMobile;
  const _NewItemRow({
    required this.index,
    required this.item,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 3 : 4),
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 12 : 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.quantity.toStringAsFixed(0)} × ${AppFormatters.formatCurrency(item.unitPrice)}',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.formatCurrency(item.subtotal),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
          IconButton(
            onPressed: () => controller.removeNewItem(index),
            icon: Icon(
              Icons.close,
              size: isMobile ? 16 : 18,
              color: Colors.red,
            ),
            constraints: BoxConstraints(
              minWidth: isMobile ? 32 : 40,
              minHeight: isMobile ? 32 : 40,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ==================== PRODUCT PICKER DIALOG ====================

class _ProductPickerDialog extends StatefulWidget {
  const _ProductPickerDialog();

  @override
  State<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends State<_ProductPickerDialog> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  Product? _selectedProduct;
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final dialogWidth = isMobile ? width * 0.92 : 480.0;

    final productsCtrl = Get.isRegistered<ProductsController>()
        ? Get.find<ProductsController>()
        : null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _selectedProduct == null
                  ? 'Seleccionar producto'
                  : 'Configurar item',
              style: TextStyle(
                fontSize: isMobile ? 15 : 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedProduct == null) ...[
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar por nombre, SKU o código',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
              ),
              const SizedBox(height: 12),
              if (productsCtrl == null)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Catálogo no disponible. Intenta abrir la pantalla de Productos primero.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Flexible(
                  child: Obx(() {
                    final products = productsCtrl.products
                        .where((p) {
                          if (_search.isEmpty) return true;
                          final s = _search;
                          return p.name.toLowerCase().contains(s) ||
                              p.sku.toLowerCase().contains(s) ||
                              (p.barcode?.toLowerCase().contains(s) ?? false);
                        })
                        .where((p) => p.status == ProductStatus.active)
                        .toList();
                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _search.isEmpty
                              ? 'No hay productos cargados'
                              : 'Sin resultados para "$_search"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (ctx, i) {
                        final p = products[i];
                        final price = (p.prices?.isNotEmpty ?? false)
                            ? p.prices!.first.amount
                            : 0.0;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          dense: true,
                          title: Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'SKU: ${p.sku} · Stock: ${p.stock.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Text(
                            AppFormatters.formatCurrency(price),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.primaryBlue,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedProduct = p;
                              _priceCtrl.text = price.toStringAsFixed(0);
                            });
                          },
                        );
                      },
                    );
                  }),
                ),
            ] else ...[
              // Configurar cantidad y precio
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedProduct!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'SKU: ${_selectedProduct!.sku}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedProduct = null;
                        _searchCtrl.clear();
                        _search = '';
                      }),
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio unitario',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(result: null),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedProduct == null ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ElegantLightTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    if (qty <= 0 || price <= 0 || _selectedProduct == null) {
      Get.snackbar(
        'Datos incompletos',
        'Cantidad y precio deben ser mayores a 0',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    Get.back(
      result: ExchangeNewItem(
        productId: _selectedProduct!.id,
        description: _selectedProduct!.name,
        quantity: qty,
        unitPrice: price,
        unit: _selectedProduct!.unit,
      ),
    );
  }
}

// ==================== SETTLEMENT ====================

class _SettlementSection extends GetView<ProductExchangeController> {
  final bool isMobile;
  const _SettlementSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Conciliación',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Colors.green,
      isMobile: isMobile,
      child: Obx(() {
        final diff = controller.difference;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(
              'Total devuelto',
              AppFormatters.formatCurrency(controller.totalReturned),
              Colors.orange,
              isMobile,
            ),
            _row(
              'Total entregado',
              AppFormatters.formatCurrency(controller.totalDelivered),
              ElegantLightTheme.primaryBlue,
              isMobile,
            ),
            const Divider(),
            _row(
              controller.differenceLabel,
              AppFormatters.formatCurrency(diff.abs()),
              diff < 0 ? Colors.green : (diff > 0 ? Colors.red : Colors.grey),
              isMobile,
              bold: true,
            ),
            const SizedBox(height: 12),
            if (diff != 0) ...[
              Text(
                'Cómo conciliar:',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ...controller.availableSettlementModes.map(
                (mode) => RadioListTile<ExchangeSettlementMode>(
                  title: Text(
                    _settlementLabel(mode),
                    style: TextStyle(fontSize: isMobile ? 12 : 13),
                  ),
                  subtitle: Text(
                    _settlementDescription(mode),
                    style: TextStyle(fontSize: isMobile ? 10 : 11),
                  ),
                  value: mode,
                  groupValue: controller.settlementMode,
                  onChanged: (v) {
                    if (v != null) controller.settlementMode = v;
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              // Selector de banco solo cuando aplica (cashPayment / cashRefund)
              if (controller.settlementMode ==
                      ExchangeSettlementMode.cashPayment ||
                  controller.settlementMode ==
                      ExchangeSettlementMode.cashRefund) ...[
                const SizedBox(height: 12),
                _BankAccountPicker(isMobile: isMobile),
              ],
            ],
          ],
        );
      }),
    );
  }

  Widget _row(String label, String value, Color color, bool isMobile,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? (isMobile ? 13 : 14) : (isMobile ? 12 : 13),
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? (isMobile ? 15 : 16) : (isMobile ? 13 : 14),
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

// ==================== BANK ACCOUNT PICKER ====================

class _BankAccountPicker extends GetView<ProductExchangeController> {
  final bool isMobile;
  const _BankAccountPicker({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BankAccountsController>()) {
      // Bank accounts no disponible — sin selector, va a caja general.
      return const SizedBox.shrink();
    }
    final bankCtrl = Get.find<BankAccountsController>();

    return Obx(() {
      final accounts = bankCtrl.bankAccounts;
      if (accounts.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Sin cuentas bancarias configuradas — usará caja general',
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cuenta para registrar el movimiento:',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String?>(
            value: controller.bankAccountId,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isMobile ? 8 : 12,
              ),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Caja general (efectivo)'),
              ),
              ...accounts.map((acc) {
                return DropdownMenuItem<String?>(
                  value: acc.id,
                  child: Text(
                    acc.bankName != null
                        ? '${acc.name} — ${acc.bankName}'
                        : acc.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (v) => controller.bankAccountId = v,
          ),
        ],
      );
    });
  }
}

// ==================== FOOTER ====================

class _Footer extends GetView<ProductExchangeController> {
  final bool isMobile;
  const _Footer({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canProcess = controller.returnedItems.isNotEmpty;
      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
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
                  ? SizedBox(
                      width: isMobile ? 16 : 18,
                      height: isMobile ? 16 : 18,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.swap_horiz, size: isMobile ? 18 : 20),
              label: Text(
                controller.isProcessing ? 'Procesando...' : 'Procesar cambio',
                style: TextStyle(fontSize: isMobile ? 14 : 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
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
  final bool isMobile;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
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
              Icon(icon, color: iconColor, size: isMobile ? 16 : 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          child,
        ],
      ),
    );
  }
}

// Wrapper para que Linter no marque CreditNoteReason como unused.
// ignore: unused_element
void _keepImports(CreditNoteReason r) {}
