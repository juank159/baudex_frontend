// lib/features/customer_credits/presentation/pages/customer_account_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../data/models/customer_credit_model.dart';
import '../../domain/entities/customer_credit.dart';
import '../controllers/customer_credit_controller.dart';
import 'credit_detail_page.dart';

/// Página de Cuenta Corriente del Cliente
/// Muestra un resumen consolidado de:
/// - Deudas por facturas
/// - Créditos directos
/// - Saldo a favor disponible
class CustomerAccountPage extends StatefulWidget {
  final String customerId;
  final String? customerName;

  const CustomerAccountPage({
    super.key,
    required this.customerId,
    this.customerName,
  });

  @override
  State<CustomerAccountPage> createState() => _CustomerAccountPageState();
}

class _CustomerAccountPageState extends State<CustomerAccountPage>
    with SingleTickerProviderStateMixin {
  late CustomerCreditController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CustomerCreditController>();

    _animationController = AnimationController(
      duration: ElegantLightTheme.slowAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.smoothCurve,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.clearCustomerAccount();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _controller.getCustomerAccount(widget.customerId);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Ancho máximo del contenido para desktop/tablet
    final maxContentWidth = isDesktop ? 800.0 : (isTablet ? 600.0 : screenWidth);
    final horizontalPadding = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false, // El AppBar ya maneja el top
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ElegantLightTheme.backgroundColor,
                ElegantLightTheme.cardColor,
              ],
            ),
          ),
          child: Obx(() {
          if (_controller.isLoadingAccount.value) {
            return _buildLoadingState();
          }

          final account = _controller.customerAccount.value;
          if (account == null) {
            return _buildErrorState();
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: ElegantLightTheme.primaryBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                          left: horizontalPadding,
                          right: horizontalPadding,
                          bottom: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCustomerHeader(account),
                            const SizedBox(height: 16),
                            _buildSummaryCards(account, isDesktop: isDesktop),
                            const SizedBox(height: 20),
                            if (account.invoiceCredits.isNotEmpty) ...[
                              _buildSectionTitle(
                                'Deudas por Facturas',
                                Icons.receipt_long,
                                Colors.orange,
                                count: account.invoiceCredits.length,
                              ),
                              const SizedBox(height: 12),
                              _buildCreditsList(account.invoiceCredits, isInvoice: true, isDesktop: isDesktop),
                              const SizedBox(height: 20),
                            ],
                            if (account.directCredits.isNotEmpty) ...[
                              _buildSectionTitle(
                                'Créditos Directos',
                                Icons.credit_card,
                                ElegantLightTheme.primaryBlue,
                                count: account.directCredits.length,
                              ),
                              const SizedBox(height: 12),
                              _buildCreditsList(account.directCredits, isInvoice: false, isDesktop: isDesktop),
                              const SizedBox(height: 20),
                            ],
                            if (account.hasBalance) ...[
                              _buildSectionTitle(
                                'Saldo a Favor',
                                Icons.account_balance_wallet,
                                Colors.green,
                              ),
                              const SizedBox(height: 12),
                              _buildBalanceCard(account),
                            ],
                            if (!account.hasDebt && !account.hasBalance)
                              _buildEmptyState(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.customerName ?? 'Cuenta Corriente',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando cuenta corriente...',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No se pudo cargar la cuenta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader(CustomerAccountModel account) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.customer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cuenta Corriente',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(CustomerAccountModel account, {bool isDesktop = false}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Deuda Total',
                value: account.summary.totalDebt,
                icon: Icons.trending_up,
                color: account.summary.totalDebt > 0 ? Colors.red : Colors.green,
                isAmount: true,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Saldo a Favor',
                value: account.summary.availableBalance,
                icon: Icons.account_balance_wallet,
                color: Colors.green,
                isAmount: true,
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        _buildNetBalanceCard(account),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
    bool isAmount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ElegantLightTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAmount ? AppFormatters.formatCurrency(value) : value.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(CustomerAccountModel account) {
    final netBalance = account.summary.netBalance;
    final isPositive = netBalance > 0;
    final color = isPositive ? Colors.red : Colors.green;
    final label = isPositive ? 'Por Pagar' : (netBalance < 0 ? 'A Favor' : 'Sin Saldo');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isPositive
            ? LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.1),
                  Colors.red.withValues(alpha: 0.05),
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.05),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive ? Icons.warning_amber_rounded : Icons.check_circle,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance Neto',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(netBalance.abs()),
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    int? count,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCreditsList(List<CustomerCreditModel> credits, {required bool isInvoice, bool isDesktop = false}) {
    return Column(
      children: credits.map((credit) => Padding(
        padding: EdgeInsets.only(bottom: isDesktop ? 14 : 10),
        child: _buildCreditCard(credit, isInvoice: isInvoice),
      )).toList(),
    );
  }

  Widget _buildCreditCard(CustomerCreditModel credit, {required bool isInvoice}) {
    final statusColor = _getStatusColor(credit.status);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _navigateToCreditDetail(credit.id),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.neuomorphicShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isInvoice ? Colors.orange : ElegantLightTheme.primaryBlue)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isInvoice ? Icons.receipt_long : Icons.credit_card,
                      color: isInvoice ? Colors.orange : ElegantLightTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isInvoice
                              ? 'Factura ${credit.invoiceNumber ?? '#${credit.id.substring(0, 8)}'}'
                              : credit.description ?? 'Crédito Directo',
                          style: const TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(credit.createdAt),
                          style: const TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(credit.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monto Original',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(credit.originalAmount),
                          style: const TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pagado',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(credit.paidAmount),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Saldo',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppFormatters.formatCurrency(credit.balanceDue),
                          style: TextStyle(
                            color: credit.balanceDue > 0 ? Colors.red : Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (credit.paidAmount > 0) ...[
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final progress = credit.originalAmount > 0
                      ? credit.paidAmount / credit.originalAmount
                      : 0.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 ? Colors.green : ElegantLightTheme.primaryBlue,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% pagado',
                        style: const TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(CustomerAccountModel account) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.successGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Disponible',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatCurrency(account.clientBalance.balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (account.clientBalance.lastTransaction != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Última transacción: ${DateFormat('dd/MM/yyyy').format(account.clientBalance.lastTransaction!)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin movimientos pendientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este cliente no tiene deudas ni saldo a favor registrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreditDetail(String creditId) {
    Get.to(
      () => CreditDetailPage(creditId: creditId),
      transition: Transition.rightToLeft,
    );
  }

  Color _getStatusColor(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return Colors.orange;
      case CreditStatus.partiallyPaid:
        return ElegantLightTheme.primaryBlue;
      case CreditStatus.paid:
        return Colors.green;
      case CreditStatus.overdue:
        return Colors.red;
      case CreditStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusLabel(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return 'Pendiente';
      case CreditStatus.partiallyPaid:
        return 'Parcial';
      case CreditStatus.paid:
        return 'Pagado';
      case CreditStatus.overdue:
        return 'Vencido';
      case CreditStatus.cancelled:
        return 'Cancelado';
    }
  }
}
