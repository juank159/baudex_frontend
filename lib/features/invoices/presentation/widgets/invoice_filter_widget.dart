// lib/features/invoices/presentation/widgets/invoice_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../controllers/invoice_list_controller.dart';
import '../../domain/entities/invoice.dart';

class InvoiceFilterWidget extends StatefulWidget {
  final InvoiceListController controller;

  const InvoiceFilterWidget({super.key, required this.controller});

  @override
  State<InvoiceFilterWidget> createState() => _InvoiceFilterWidgetState();
}

class _InvoiceFilterWidgetState extends State<InvoiceFilterWidget> {
  // Controladores para los filtros
  late InvoiceStatus? _selectedStatus;
  late PaymentMethod? _selectedPaymentMethod;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late double? _minAmount;
  late double? _maxAmount;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _initializeFilters() {
    _selectedStatus = widget.controller.selectedStatus;
    _selectedPaymentMethod = widget.controller.selectedPaymentMethod;
    _startDate = widget.controller.startDate;
    _endDate = widget.controller.endDate;
    _minAmount = widget.controller.minAmount;
    _maxAmount = widget.controller.maxAmount;

    _minAmountController.text = _minAmount?.toString() ?? '';
    _maxAmountController.text = _maxAmount?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusFilter(context),
                  const SizedBox(height: 20),
                  _buildPaymentMethodFilter(context),
                  const SizedBox(height: 20),
                  _buildDateRangeFilter(context),
                  const SizedBox(height: 20),
                  _buildAmountRangeFilter(context),
                  const SizedBox(height: 20),
                  _buildQuickFilters(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.filter_list,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Filtros de Facturas',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Estado de la Factura'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'Todos',
              _selectedStatus == null,
              () => setState(() => _selectedStatus = null),
            ),
            ...InvoiceStatus.values.map(
              (status) => _buildFilterChip(
                status.displayName,
                _selectedStatus == status,
                () => setState(() => _selectedStatus = status),
                color: _getStatusColor(status),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Método de Pago'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'Todos',
              _selectedPaymentMethod == null,
              () => setState(() => _selectedPaymentMethod = null),
            ),
            ...PaymentMethod.values.map(
              (method) => _buildFilterChip(
                method.displayName,
                _selectedPaymentMethod == method,
                () => setState(() => _selectedPaymentMethod = method),
                icon: _getPaymentMethodIcon(method),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rango de Fechas'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateSelector(
                context,
                'Fecha Inicio',
                _startDate,
                (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateSelector(
                context,
                'Fecha Fin',
                _endDate,
                (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateButton('Hoy', () => _setDateRange(0)),
            _buildQuickDateButton('Esta Semana', () => _setDateRange(7)),
            _buildQuickDateButton('Este Mes', () => _setDateRange(30)),
            _buildQuickDateButton('Últimos 3 Meses', () => _setDateRange(90)),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rango de Montos'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _minAmountController,
                label: 'Monto Mínimo',
                hint: '0.00',
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  _minAmount = double.tryParse(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _maxAmountController,
                label: 'Monto Máximo',
                hint: '999999.99',
                prefixIcon: Icons.money_off,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  _maxAmount = double.tryParse(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickAmountButton(
              '< \$100',
              () => _setAmountRange(null, 100),
            ),
            _buildQuickAmountButton(
              '\$100 - \$500',
              () => _setAmountRange(100, 500),
            ),
            _buildQuickAmountButton(
              '\$500 - \$1000',
              () => _setAmountRange(500, 1000),
            ),
            _buildQuickAmountButton(
              '> \$1000',
              () => _setAmountRange(1000, null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Filtros Rápidos'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: context.isMobile ? 3 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: context.isMobile ? 2.5 : 3,
          children: [
            _buildQuickFilterCard(
              'Vencidas',
              Icons.error,
              Colors.red,
              () => _applyQuickFilter(InvoiceStatus.overdue),
            ),
            _buildQuickFilterCard(
              'Pendientes',
              Icons.schedule,
              Colors.orange,
              () => _applyQuickFilter(InvoiceStatus.pending), // Incluye parcialmente pagadas
            ),
            _buildQuickFilterCard(
              'Pagadas',
              Icons.check_circle,
              Colors.green,
              () => _applyQuickFilter(InvoiceStatus.paid),
            ),
            _buildQuickFilterCard(
              'Borradores',
              Icons.edit,
              Colors.grey,
              () => _applyQuickFilter(InvoiceStatus.draft),
            ),
            _buildQuickFilterCard(
              'Este Mes',
              Icons.calendar_month,
              Colors.blue,
              () => _setDateRange(30),
            ),
            _buildQuickFilterCard(
              'Efectivo',
              Icons.money,
              Colors.purple,
              () => _applyPaymentMethodFilter(PaymentMethod.cash),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        if (_hasActiveFilters()) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getActiveFiltersText(),
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Limpiar Filtros',
                type: ButtonType.outline,
                onPressed: _clearAllFilters,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Aplicar Filtros',
                icon: Icons.filter_alt,
                onPressed: _applyFilters,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
    IconData? icon,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? Colors.white : (color ?? Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color ?? Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateSelector(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () => _showDatePicker(context, selectedDate, onChanged),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? _formatDate(selectedDate)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color:
                          selectedDate != null
                              ? Colors.black87
                              : Colors.grey.shade500,
                    ),
                  ),
                ),
                if (selectedDate != null)
                  GestureDetector(
                    onTap: () => onChanged(null),
                    child: Icon(
                      Icons.clear,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildQuickAmountButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildQuickFilterCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _setDateRange(int days) {
    final now = DateTime.now();
    setState(() {
      _endDate = now;
      _startDate = now.subtract(Duration(days: days));
    });
  }

  void _setAmountRange(double? min, double? max) {
    setState(() {
      _minAmount = min;
      _maxAmount = max;
      _minAmountController.text = min?.toString() ?? '';
      _maxAmountController.text = max?.toString() ?? '';
    });
  }

  void _applyQuickFilter(InvoiceStatus status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  void _applyPaymentMethodFilter(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPaymentMethod = null;
      _startDate = null;
      _endDate = null;
      _minAmount = null;
      _maxAmount = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    // Aplicar filtros en el controlador
    widget.controller.filterByStatus(_selectedStatus);
    widget.controller.filterByPaymentMethod(_selectedPaymentMethod);
    widget.controller.filterByDateRange(_startDate, _endDate);
    widget.controller.filterByAmountRange(_minAmount, _maxAmount);

    Navigator.of(context).pop();
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedPaymentMethod != null ||
        _startDate != null ||
        _endDate != null ||
        _minAmount != null ||
        _maxAmount != null;
  }

  String _getActiveFiltersText() {
    final filters = <String>[];

    if (_selectedStatus != null) {
      filters.add('Estado: ${_selectedStatus!.displayName}');
    }
    if (_selectedPaymentMethod != null) {
      filters.add('Pago: ${_selectedPaymentMethod!.displayName}');
    }
    if (_startDate != null || _endDate != null) {
      filters.add('Fechas seleccionadas');
    }
    if (_minAmount != null || _maxAmount != null) {
      filters.add('Montos filtrados');
    }

    return '${filters.length} filtro${filters.length != 1 ? 's' : ''} activo${filters.length != 1 ? 's' : ''}';
  }

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime? selectedDate,
    Function(DateTime?) onChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.grey;
      case InvoiceStatus.partiallyPaid:
        return Colors.blue;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.receipt;
      case PaymentMethod.credit:
        return Icons.account_balance_wallet;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
