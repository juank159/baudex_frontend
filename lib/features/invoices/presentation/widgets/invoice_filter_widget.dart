// lib/features/invoices/presentation/widgets/invoice_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../controllers/invoice_list_controller.dart';
import '../../domain/entities/invoice.dart';
import '../../../bank_accounts/domain/entities/bank_account.dart';
import '../../../bank_accounts/domain/repositories/bank_account_repository.dart';

/// Modelo para representar un tipo de método de pago único
class PaymentMethodFilter {
  final String name;
  final BankAccountType type;
  final IconData icon;
  final int count; // Cantidad de cuentas de este tipo

  const PaymentMethodFilter({
    required this.name,
    required this.type,
    required this.icon,
    required this.count,
  });
}

class InvoiceFilterWidget extends StatefulWidget {
  final InvoiceListController controller;

  const InvoiceFilterWidget({super.key, required this.controller});

  @override
  State<InvoiceFilterWidget> createState() => _InvoiceFilterWidgetState();
}

class _InvoiceFilterWidgetState extends State<InvoiceFilterWidget> {
  // Estados de filtros
  InvoiceStatus? _selectedStatus;
  String? _selectedPaymentMethodName; // Cambiado: ahora es el NOMBRE del método de pago
  DateTime? _startDate;
  DateTime? _endDate;

  // Filtro rápido seleccionado (para mostrar visualmente cuál está activo)
  int? _selectedQuickFilter; // 0=Hoy, 7=Esta semana, 30=Este mes, 90=Últimos 3 meses

  // Métodos de pago agrupados por nombre (Nequi, Bancolombia, Efectivo, etc.)
  List<PaymentMethodFilter> _paymentMethods = [];
  bool _isLoadingPaymentMethods = true;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _loadPaymentMethods();
  }

  void _initializeFilters() {
    _selectedStatus = widget.controller.selectedStatus;
    _selectedPaymentMethodName = widget.controller.selectedBankAccountName;
    _startDate = widget.controller.startDate;
    _endDate = widget.controller.endDate;

    // Detectar si hay un filtro rápido aplicado basado en las fechas
    _selectedQuickFilter = _detectQuickFilter();
  }

  /// Detecta qué filtro rápido está aplicado basándose en las fechas
  int? _detectQuickFilter() {
    if (_startDate == null || _endDate == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Normalizar las fechas para comparar solo día/mes/año
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    // Verificar si es "Hoy" (startDate y endDate son hoy)
    if (startDay == today && endDay == today) {
      return 0;
    }

    // Verificar los otros rangos
    final daysDifference = endDay.difference(startDay).inDays;

    // Esta semana (7 días)
    if (daysDifference == 7 && endDay == today) {
      return 7;
    }

    // Este mes (30 días)
    if (daysDifference == 30 && endDay == today) {
      return 30;
    }

    // Últimos 3 meses (90 días)
    if (daysDifference == 90 && endDay == today) {
      return 90;
    }

    // No coincide con ningún filtro rápido (fecha manual)
    return null;
  }

  /// Cargar y agrupar métodos de pago por nombre único (case-insensitive)
  Future<void> _loadPaymentMethods() async {
    try {
      final repository = Get.find<BankAccountRepository>();
      final result = await repository.getActiveBankAccounts();

      result.fold(
        (failure) {
          print('⚠️ Error al cargar métodos de pago: ${failure.message}');
          setState(() => _isLoadingPaymentMethods = false);
        },
        (accounts) {
          // Agrupar cuentas por nombre NORMALIZADO (case-insensitive)
          // Ej: "Nequi", "nequi", "NEQUI" -> todas agrupadas bajo "Nequi"
          final Map<String, List<BankAccount>> groupedAccounts = {};
          final Map<String, String> normalizedToDisplayName = {};

          for (final account in accounts) {
            // Normalizar el nombre a minúsculas para agrupar
            final normalizedName = account.name.toLowerCase().trim();

            if (!groupedAccounts.containsKey(normalizedName)) {
              groupedAccounts[normalizedName] = [];
              // Guardar el nombre con formato capitalizado para mostrar
              normalizedToDisplayName[normalizedName] = _capitalizeFirst(account.name.trim());
            }
            groupedAccounts[normalizedName]!.add(account);
          }

          // Convertir a lista de PaymentMethodFilter
          final methods = groupedAccounts.entries.map((entry) {
            final firstAccount = entry.value.first;
            final displayName = normalizedToDisplayName[entry.key]!;
            return PaymentMethodFilter(
              name: displayName, // Nombre formateado para mostrar
              type: firstAccount.type,
              icon: firstAccount.typeIcon,
              count: entry.value.length,
            );
          }).toList();

          // Ordenar: primero por tipo, luego por nombre
          methods.sort((a, b) {
            final typeCompare = a.type.index.compareTo(b.type.index);
            if (typeCompare != 0) return typeCompare;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

          setState(() {
            _paymentMethods = methods;
            _isLoadingPaymentMethods = false;
          });
        },
      );
    } catch (e) {
      print('⚠️ Error al cargar métodos de pago: $e');
      setState(() => _isLoadingPaymentMethods = false);
    }
  }

  /// Capitaliza la primera letra de un string
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtros',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          if (_hasActiveFilters())
                            Text(
                              '${_countActiveFilters()} filtro${_countActiveFilters() > 1 ? 's' : ''} activo${_countActiveFilters() > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: ElegantLightTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_hasActiveFilters())
                      TextButton.icon(
                        onPressed: _clearAllFilters,
                        icon: Icon(
                          Icons.clear_all_rounded,
                          size: 18,
                          color: ElegantLightTheme.accentOrange,
                        ),
                        label: Text(
                          'Limpiar',
                          style: TextStyle(
                            color: ElegantLightTheme.accentOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                // Resumen de filtros activos
                if (_hasActiveFilters()) ...[
                  const SizedBox(height: 12),
                  _buildActiveFiltersChips(),
                ],
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusSection(),
                  const SizedBox(height: 24),
                  _buildBankAccountSection(),
                  const SizedBox(height: 24),
                  _buildDateRangeSection(),
                  const SizedBox(height: 24),
                  _buildQuickFiltersSection(),
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
          // Apply button
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: ElegantLightTheme.primaryBlue,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Estado', Icons.flag_rounded),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              label: 'Todos',
              isSelected: _selectedStatus == null,
              onTap: () => setState(() => _selectedStatus = null),
              color: ElegantLightTheme.textSecondary,
            ),
            _buildFilterChip(
              label: 'Pagadas',
              isSelected: _selectedStatus == InvoiceStatus.paid,
              onTap: () => setState(() => _selectedStatus = InvoiceStatus.paid),
              color: const Color(0xFF10B981),
              icon: Icons.check_circle_outline_rounded,
            ),
            _buildFilterChip(
              label: 'Pendientes',
              isSelected: _selectedStatus == InvoiceStatus.pending,
              onTap: () => setState(() => _selectedStatus = InvoiceStatus.pending),
              color: ElegantLightTheme.accentOrange,
              icon: Icons.schedule_rounded,
            ),
            _buildFilterChip(
              label: 'Vencidas',
              isSelected: _selectedStatus == InvoiceStatus.overdue,
              onTap: () => setState(() => _selectedStatus = InvoiceStatus.overdue),
              color: const Color(0xFFEF4444),
              icon: Icons.warning_amber_rounded,
            ),
            _buildFilterChip(
              label: 'Canceladas',
              isSelected: _selectedStatus == InvoiceStatus.cancelled,
              onTap: () => setState(() => _selectedStatus = InvoiceStatus.cancelled),
              color: const Color(0xFF6B7280),
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Método de Pago', Icons.account_balance_wallet_rounded),
        const SizedBox(height: 12),
        if (_isLoadingPaymentMethods)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(ElegantLightTheme.primaryBlue),
                ),
              ),
            ),
          )
        else if (_paymentMethods.isEmpty)
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: ElegantLightTheme.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay métodos de pago registrados',
                    style: TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(
                label: 'Todos',
                isSelected: _selectedPaymentMethodName == null,
                onTap: () => setState(() => _selectedPaymentMethodName = null),
                color: ElegantLightTheme.textSecondary,
              ),
              ..._paymentMethods.map((method) => _buildFilterChip(
                label: method.name,
                isSelected: _selectedPaymentMethodName == method.name,
                onTap: () => setState(() => _selectedPaymentMethodName = method.name),
                color: _getBankAccountColor(method.type),
                icon: method.icon,
              )),
            ],
          ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rango de Fechas', Icons.date_range_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: _startDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : 'Desde',
                icon: Icons.calendar_today_rounded,
                onTap: () => _selectDate(true),
                hasValue: _startDate != null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: ElegantLightTheme.textTertiary,
                size: 20,
              ),
            ),
            Expanded(
              child: _buildDateButton(
                label: _endDate != null
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : 'Hasta',
                icon: Icons.calendar_today_rounded,
                onTap: () => _selectDate(false),
                hasValue: _endDate != null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasValue
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.1)
              : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: hasValue
                  ? ElegantLightTheme.primaryBlue
                  : ElegantLightTheme.textTertiary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: hasValue
                      ? ElegantLightTheme.primaryBlue
                      : ElegantLightTheme.textTertiary,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Filtros Rápidos', Icons.flash_on_rounded),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickFilterChip(
              label: 'Hoy',
              icon: Icons.today_rounded,
              isSelected: _selectedQuickFilter == 0,
              onTap: () => _setDateRange(0),
            ),
            _buildQuickFilterChip(
              label: 'Esta semana',
              icon: Icons.view_week_rounded,
              isSelected: _selectedQuickFilter == 7,
              onTap: () => _setDateRange(7),
            ),
            _buildQuickFilterChip(
              label: 'Este mes',
              icon: Icons.calendar_month_rounded,
              isSelected: _selectedQuickFilter == 30,
              onTap: () => _setDateRange(30),
            ),
            _buildQuickFilterChip(
              label: 'Últimos 3 meses',
              icon: Icons.date_range_rounded,
              isSelected: _selectedQuickFilter == 90,
              onTap: () => _setDateRange(90),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : ElegantLightTheme.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.15)
              : ElegantLightTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ElegantLightTheme.primaryBlue
                : ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
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
              color: ElegantLightTheme.primaryBlue,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: ElegantLightTheme.primaryBlue,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: ElegantLightTheme.primaryBlue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ElegantLightTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElegantLightTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Aplicar Filtros',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBankAccountColor(BankAccountType type) {
    switch (type) {
      case BankAccountType.digitalWallet:
        return const Color(0xFF8B5CF6); // Purple
      case BankAccountType.savings:
        return ElegantLightTheme.primaryBlue;
      case BankAccountType.checking:
        return const Color(0xFF0891B2); // Cyan
      case BankAccountType.cash:
        return const Color(0xFF10B981); // Green
      case BankAccountType.creditCard:
        return ElegantLightTheme.accentOrange;
      case BankAccountType.debitCard:
        return const Color(0xFF6366F1); // Indigo
      default:
        return ElegantLightTheme.textSecondary;
    }
  }

  void _setDateRange(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    setState(() {
      _selectedQuickFilter = days;
      _endDate = endOfDay;

      if (days == 0) {
        // Hoy: desde las 00:00 de hoy hasta las 23:59 de hoy
        _startDate = today;
      } else {
        // Otros: desde hace X días hasta hoy
        _startDate = today.subtract(Duration(days: days));
      }
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ElegantLightTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: ElegantLightTheme.surfaceColor,
              onSurface: ElegantLightTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Limpiar filtro rápido cuando se selecciona fecha manualmente
        _selectedQuickFilter = null;

        if (isStartDate) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          // Para fecha fin, usar el final del día
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null ||
        _selectedPaymentMethodName != null ||
        _startDate != null ||
        _endDate != null;
  }

  int _countActiveFilters() {
    int count = 0;
    if (_selectedStatus != null) count++;
    if (_selectedPaymentMethodName != null) count++;
    if (_startDate != null || _endDate != null) count++; // Fechas cuentan como 1
    return count;
  }

  Widget _buildActiveFiltersChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Chip de estado
        if (_selectedStatus != null)
          _buildActiveFilterChip(
            label: _selectedStatus!.displayName,
            icon: _getStatusIcon(_selectedStatus!),
            color: _getStatusColor(_selectedStatus!),
            onRemove: () => setState(() => _selectedStatus = null),
          ),

        // Chip de método de pago
        if (_selectedPaymentMethodName != null)
          _buildActiveFilterChip(
            label: _selectedPaymentMethodName!,
            icon: Icons.account_balance_wallet_rounded,
            color: ElegantLightTheme.primaryBlue,
            onRemove: () => setState(() => _selectedPaymentMethodName = null),
          ),

        // Chip de fechas
        if (_startDate != null || _endDate != null)
          _buildActiveFilterChip(
            label: _getDateRangeLabel(),
            icon: Icons.date_range_rounded,
            color: const Color(0xFF8B5CF6), // Purple
            onRemove: () => setState(() {
              _startDate = null;
              _endDate = null;
              _selectedQuickFilter = null;
            }),
          ),
      ],
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRangeLabel() {
    if (_selectedQuickFilter != null) {
      switch (_selectedQuickFilter) {
        case 0:
          return 'Hoy';
        case 7:
          return 'Esta semana';
        case 30:
          return 'Este mes';
        case 90:
          return 'Últimos 3 meses';
      }
    }

    // Formato de fecha personalizada
    if (_startDate != null && _endDate != null) {
      final startStr = '${_startDate!.day}/${_startDate!.month}';
      final endStr = '${_endDate!.day}/${_endDate!.month}';
      return '$startStr - $endStr';
    } else if (_startDate != null) {
      return 'Desde ${_startDate!.day}/${_startDate!.month}';
    } else if (_endDate != null) {
      return 'Hasta ${_endDate!.day}/${_endDate!.month}';
    }

    return 'Fechas';
  }

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.edit_note_rounded;
      case InvoiceStatus.pending:
        return Icons.pending_rounded;
      case InvoiceStatus.paid:
        return Icons.check_circle_rounded;
      case InvoiceStatus.partiallyPaid:
        return Icons.pie_chart_rounded;
      case InvoiceStatus.overdue:
        return Icons.warning_rounded;
      case InvoiceStatus.cancelled:
        return Icons.cancel_rounded;
      case InvoiceStatus.credited:
        return Icons.credit_card_rounded;
      case InvoiceStatus.partiallyCredited:
        return Icons.credit_score_rounded;
    }
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return ElegantLightTheme.textSecondary;
      case InvoiceStatus.pending:
        return ElegantLightTheme.accentOrange;
      case InvoiceStatus.paid:
        return const Color(0xFF10B981); // Green
      case InvoiceStatus.partiallyPaid:
        return ElegantLightTheme.primaryBlue;
      case InvoiceStatus.overdue:
        return const Color(0xFFEF4444); // Red
      case InvoiceStatus.cancelled:
        return ElegantLightTheme.textTertiary;
      case InvoiceStatus.credited:
        return const Color(0xFF8B5CF6); // Purple
      case InvoiceStatus.partiallyCredited:
        return const Color(0xFFA78BFA); // Light Purple
    }
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPaymentMethodName = null;
      _selectedQuickFilter = null;
      _startDate = null;
      _endDate = null;
    });
  }

  void _applyFilters() {
    // Usar el método optimizado que hace UNA sola llamada al servidor
    widget.controller.applyFilters(
      status: _selectedStatus,
      bankAccountName: _selectedPaymentMethodName,
      startDate: _startDate,
      endDate: _endDate,
    );
    Navigator.of(context).pop();
  }
}
