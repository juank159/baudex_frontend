// lib/features/customer_credits/presentation/pages/customer_account_unified_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../data/models/customer_credit_model.dart';
import '../../domain/entities/customer_credit.dart';
import '../controllers/customer_credit_controller.dart';
import '../widgets/add_debt_dialog.dart';
import '../widgets/add_credit_payment_dialog.dart';
import 'credit_detail_page.dart';

/// Pagina unificada de cuenta del cliente
/// Muestra resumen, créditos (facturas + directos), historial y acciones
class CustomerAccountUnifiedPage extends StatefulWidget {
  final String customerId;
  final String? customerName;
  final CustomerCreditSummary? initialSummary;

  const CustomerAccountUnifiedPage({
    super.key,
    required this.customerId,
    this.customerName,
    this.initialSummary,
  });

  @override
  State<CustomerAccountUnifiedPage> createState() => _CustomerAccountUnifiedPageState();
}

class _CustomerAccountUnifiedPageState extends State<CustomerAccountUnifiedPage> {
  late CustomerCreditController controller;

  CustomerCreditSummary? _summary;
  bool _isLoading = false;
  bool _hasError = false;

  // Tab seleccionado: 0 = Directos, 1 = Facturas
  int _selectedCreditTypeTab = 0;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomerCreditController>();

    // Usar datos iniciales si los hay (carga instantánea)
    _summary = widget.initialSummary;

    // Cargar datos frescos en background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Si ya tenemos datos, mostrar loading sutil
    // Si no tenemos datos, mostrar loading completo
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      // Cargar créditos y cuenta del cliente en paralelo
      await Future.wait([
        controller.loadCredits(),
        controller.getCustomerAccount(widget.customerId),
      ]);

      // Generar el resumen actualizado desde los créditos recargados
      final summary = controller.getCustomerCreditSummary(widget.customerId);

      if (mounted) {
        setState(() {
          _summary = summary ?? _summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    // Padding horizontal basado en el tamaño de pantalla
    final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      body: Column(
        children: [
          // Header fijo
          _buildHeader(context, horizontalPadding),

          // Contenido - Desktop tiene scroll por columna, móvil scroll general
          Expanded(
            child: isDesktop
                ? Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: _buildContent(context, isDesktop, isTablet),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(horizontalPadding),
                      child: _buildContent(context, isDesktop, isTablet),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context, double horizontalPadding) {
    final customerName = widget.customerName ?? _summary?.customerName ?? 'Cliente';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra superior con botones
              Row(
                children: [
                  // Botón volver
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  // Botón refresh
                  _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : IconButton(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                ],
              ),

              const SizedBox(height: 16),

              // Info del cliente
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _summary?.customerInitials ?? customerName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildHeaderBadge(
                              '${_summary?.totalCredits ?? 0} créditos',
                              Colors.white.withValues(alpha: 0.2),
                            ),
                            if (_summary?.hasOverdueCredits ?? false)
                              _buildHeaderBadge(
                                '${_summary?.overdueCredits ?? 0} vencidos',
                                Colors.red.withValues(alpha: 0.3),
                                icon: Icons.warning,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Resumen de montos - 3 columnas
              Row(
                children: [
                  Expanded(
                    child: _buildHeaderStat(
                      'Total Original',
                      AppFormatters.formatCurrency(_summary?.totalOriginalAmount ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeaderStat(
                      'Pagado',
                      AppFormatters.formatCurrency(_summary?.totalPaidAmount ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildHeaderStat(
                      'Pendiente',
                      AppFormatters.formatCurrency(_summary?.totalBalanceDue ?? 0),
                      isHighlighted: (_summary?.totalBalanceDue ?? 0) > 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(String text, Color bgColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.orange.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? Colors.orange.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDesktop, bool isTablet) {
    // Solo mostrar loading completo si no hay datos previos
    if (_isLoading && _summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.credit_card, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Cargando créditos...',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mostrar error si falló la carga y no hay datos
    if (_hasError && _summary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar datos',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // En desktop, mostrar en grid de 2 columnas si hay espacio
    if (isDesktop) {
      return _buildDesktopLayout();
    }

    // En tablet y móvil, mostrar en columna
    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    final invoiceCredits = _summary?.invoiceCredits ?? [];
    final directCredits = _summary?.directCredits ?? [];

    // Calcular totales pendientes
    final directPending = directCredits.fold<double>(
      0, (sum, c) => sum + c.balanceDue,
    );
    final invoicePending = invoiceCredits.fold<double>(
      0, (sum, c) => sum + c.balanceDue,
    );

    // Dos columnas con scroll independiente
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda - Créditos Directos
        Expanded(
          child: _buildScrollableColumn(
            title: 'Créditos Directos',
            icon: Icons.account_balance_wallet,
            credits: directCredits,
            totalPending: directPending,
            emptyMessage: 'Sin créditos directos',
          ),
        ),

        const SizedBox(width: 20),

        // Columna derecha - Créditos de Facturas
        Expanded(
          child: _buildScrollableColumn(
            title: 'Créditos Facturas',
            icon: Icons.receipt_long,
            credits: invoiceCredits,
            totalPending: invoicePending,
            emptyMessage: 'Sin créditos de facturas',
          ),
        ),
      ],
    );
  }

  /// Columna con scroll independiente para desktop
  Widget _buildScrollableColumn({
    required String title,
    required IconData icon,
    required List<CustomerCreditModel> credits,
    required double totalPending,
    required String emptyMessage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Header fijo de la columna
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              credits.length.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ElegantLightTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Pendiente: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: ElegantLightTheme.textSecondary,
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(totalPending),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: totalPending > 0 ? Colors.orange.shade700 : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón refresh
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _loadData,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.refresh,
                              size: 18,
                              color: ElegantLightTheme.textSecondary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista scrolleable de créditos
          Expanded(
            child: credits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: ElegantLightTheme.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            emptyMessage,
                            style: TextStyle(
                              color: ElegantLightTheme.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    itemCount: credits.length,
                    itemBuilder: (context, index) {
                      return _buildCreditCard(credits[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final directCredits = _summary?.directCredits ?? [];
    final invoiceCredits = _summary?.invoiceCredits ?? [];

    // Calcular totales pendientes
    final directPending = directCredits.fold<double>(
      0, (sum, c) => sum + c.balanceDue,
    );
    final invoicePending = invoiceCredits.fold<double>(
      0, (sum, c) => sum + c.balanceDue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de tabs (Directos / Facturas)
        _buildCreditTypeTabSelector(
          directCount: directCredits.length,
          invoiceCount: invoiceCredits.length,
          directPending: directPending,
          invoicePending: invoicePending,
        ),

        const SizedBox(height: 16),

        // Contenido según tab seleccionado
        if (_selectedCreditTypeTab == 0) ...[
          // Tab Directos
          if (directCredits.isNotEmpty) ...[
            ...directCredits.map((credit) => _buildCreditCard(credit)),
          ] else
            _buildEmptySectionMessage('No hay créditos directos'),
        ] else ...[
          // Tab Facturas
          if (invoiceCredits.isNotEmpty) ...[
            ...invoiceCredits.map((credit) => _buildCreditCard(credit)),
          ] else
            _buildEmptySectionMessage('No hay créditos de facturas'),
        ],

        // Mensaje si no hay créditos en general
        if (_summary == null || _summary!.credits.isEmpty)
          _buildEmptyState(),

        const SizedBox(height: 100), // Espacio para el FAB
      ],
    );
  }

  /// Selector de tipo de crédito (Directos / Facturas)
  Widget _buildCreditTypeTabSelector({
    required int directCount,
    required int invoiceCount,
    required double directPending,
    required double invoicePending,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCreditTypeTabButton(
              title: 'Directos',
              icon: Icons.account_balance_wallet,
              count: directCount,
              totalPending: directPending,
              index: 0,
              isSelected: _selectedCreditTypeTab == 0,
            ),
          ),
          Expanded(
            child: _buildCreditTypeTabButton(
              title: 'Facturas',
              icon: Icons.receipt_long,
              count: invoiceCount,
              totalPending: invoicePending,
              index: 1,
              isSelected: _selectedCreditTypeTab == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditTypeTabButton({
    required String title,
    required IconData icon,
    required int count,
    required double totalPending,
    required int index,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: ElegantLightTheme.normalAnimation,
      curve: ElegantLightTheme.smoothCurve,
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _selectedCreditTypeTab = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Fila superior: icono, título y contador
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : ElegantLightTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : ElegantLightTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : ElegantLightTheme.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Fila inferior: total pendiente
                Text(
                  AppFormatters.formatCurrency(totalPending),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.9)
                        : (totalPending > 0 ? Colors.orange.shade700 : Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySectionMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: ElegantLightTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: ElegantLightTheme.textTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(CustomerCreditModel credit) {
    final isOverdue = credit.isOverdue;
    final progress = credit.originalAmount > 0
        ? credit.paidAmount / credit.originalAmount
        : 0.0;
    final percentage = (progress * 100).clamp(0.0, 100.0);

    Color statusColor;
    switch (credit.status) {
      case CreditStatus.pending:
        statusColor = Colors.orange;
        break;
      case CreditStatus.partiallyPaid:
        statusColor = ElegantLightTheme.primaryBlue;
        break;
      case CreditStatus.paid:
        statusColor = Colors.green;
        break;
      case CreditStatus.cancelled:
        statusColor = ElegantLightTheme.textTertiary;
        break;
      case CreditStatus.overdue:
        statusColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withValues(alpha: 0.4)
              : ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _navigateToCreditDetail(credit),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (credit.invoiceNumber != null)
                            Text(
                              'Factura: ${credit.invoiceNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ElegantLightTheme.textSecondary,
                              ),
                            ),
                          if (credit.description != null)
                            Text(
                              credit.description!,
                              style: TextStyle(
                                fontSize: credit.invoiceNumber != null ? 11 : 13,
                                color: credit.invoiceNumber != null
                                    ? ElegantLightTheme.textTertiary
                                    : ElegantLightTheme.textPrimary,
                                fontWeight: credit.invoiceNumber != null
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        credit.status.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Amounts row
                Row(
                  children: [
                    _buildAmountColumn('Original', credit.originalAmount, ElegantLightTheme.textPrimary),
                    _buildAmountColumn('Pagado', credit.paidAmount, Colors.green),
                    _buildAmountColumn(
                      'Saldo',
                      credit.balanceDue,
                      isOverdue ? Colors.red : Colors.orange,
                      isBold: true,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [statusColor.withValues(alpha: 0.8), statusColor],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),

                // Actions
                if (credit.canReceivePayment) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (credit.dueDate != null) ...[
                        Icon(
                          isOverdue ? Icons.warning : Icons.calendar_today,
                          size: 12,
                          color: isOverdue ? Colors.red : ElegantLightTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOverdue
                              ? 'Vencido'
                              : AppFormatters.formatDate(credit.dueDate),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue ? Colors.red : ElegantLightTheme.textTertiary,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),

                      // Botón agregar deuda (solo para créditos directos)
                      if (credit.invoiceId == null)
                        TextButton.icon(
                          onPressed: () => _showAddDebtDialog(credit),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Agregar', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: Colors.orange,
                          ),
                        ),

                      const SizedBox(width: 4),

                      // Botón abonar
                      Container(
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.successGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showPaymentDialog(credit),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payment, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Abonar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: ElegantLightTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.credit_card_off,
                size: 40,
                color: ElegantLightTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin créditos activos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este cliente no tiene créditos pendientes',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    final pendingDirect = _summary?.pendingDirectCredit;

    if (pendingDirect != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.warningGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAddDebtDialog(pendingDirect),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Agregar Deuda',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _createNewDirectCredit,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Nuevo Crédito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Navegar a la página de detalle del crédito para ver historial de movimientos
  void _navigateToCreditDetail(CustomerCreditModel credit) async {
    await Get.to(
      () => CreditDetailPage(creditId: credit.id),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );

    // Al regresar, recargar datos por si hubo cambios (pagos, etc.)
    if (mounted) {
      await _loadData();
    }
  }

  void _showPaymentDialog(CustomerCreditModel credit) async {
    final result = await Get.dialog<bool>(
      AddCreditPaymentDialog(credit: credit),
      barrierDismissible: false,
    );

    if (result == true) {
      // Recargar todos los datos para reflejar el pago
      await _loadData();
    }
  }

  void _showAddDebtDialog(CustomerCreditModel credit) async {
    final result = await Get.dialog<bool>(
      AddDebtDialog(credit: credit),
      barrierDismissible: false,
    );

    if (result == true) {
      // La data ya fue recargada en el diálogo, solo actualizar el summary
      if (mounted) {
        final summary = controller.getCustomerCreditSummary(widget.customerId);
        setState(() {
          _summary = summary ?? _summary;
        });
      }
    }
  }

  void _createNewDirectCredit() async {
    Get.snackbar(
      'Crear Crédito',
      'Ir a crear nuevo crédito para ${widget.customerName ?? "este cliente"}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
