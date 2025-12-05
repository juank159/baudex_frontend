// lib/features/customer_credits/presentation/pages/credit_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../data/models/customer_credit_model.dart';
import '../../domain/entities/customer_credit.dart';
import '../controllers/customer_credit_controller.dart';
import '../widgets/add_credit_payment_dialog.dart';

/// Página de detalle de un crédito con tema Elegant
class CreditDetailPage extends StatefulWidget {
  final String creditId;

  const CreditDetailPage({
    super.key,
    required this.creditId,
  });

  @override
  State<CreditDetailPage> createState() => _CreditDetailPageState();
}

class _CreditDetailPageState extends State<CreditDetailPage>
    with SingleTickerProviderStateMixin {
  late CustomerCreditController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CustomerCreditController>();

    // Animaciones de entrada
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
    super.dispose();
  }

  Future<void> _loadData() async {
    await _controller.getCreditById(widget.creditId);
    await _controller.loadCreditTransactions(widget.creditId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false, // El AppBar ya maneja el top
        child: Container(
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
          if (_controller.isLoading.value) {
            return _buildLoadingState();
          }

          final credit = _controller.selectedCredit.value;
          if (credit == null) {
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
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                    left: 16,
                    right: 16,
                    bottom: 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCreditHeader(credit),
                      const SizedBox(height: 16),
                      _buildCreditSummary(credit),
                      const SizedBox(height: 16),
                      // Mostrar origen del crédito si viene de una factura
                      if (credit.invoiceId != null) ...[
                        _buildCreditOriginSection(credit),
                        const SizedBox(height: 16),
                      ],
                      _buildInfoSection(credit),
                      const SizedBox(height: 16),
                      _buildTransactionsSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Detalle del Crédito',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      actions: [
        Obx(() {
          final credit = _controller.selectedCredit.value;
          if (credit == null || !credit.canReceivePayment) {
            return const SizedBox.shrink();
          }
          return PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              _buildPopupMenuItem(
                value: 'add_payment',
                icon: Icons.payment,
                label: 'Agregar Pago',
                color: Colors.green,
              ),
              _buildPopupMenuItem(
                value: 'add_debt',
                icon: Icons.trending_up,
                label: 'Agregar Deuda',
                color: Colors.orange,
              ),
              if (credit.canBeCancelled)
                _buildPopupMenuItem(
                  value: 'cancel',
                  icon: Icons.cancel,
                  label: 'Cancelar Crédito',
                  color: Colors.red,
                ),
            ],
          );
        }),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
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
            label,
            style: TextStyle(
              color: color == Colors.red ? color : ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      final credit = _controller.selectedCredit.value;
      if (credit == null || !credit.canReceivePayment) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.successGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            ...ElegantLightTheme.glowShadow,
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _navigateToAddPayment(credit),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payment, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Agregar Pago',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(Icons.credit_card, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cargando crédito...',
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: ElegantLightTheme.cardColor,
                valueColor: AlwaysStoppedAnimation<Color>(ElegantLightTheme.primaryBlue),
              ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.errorGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.error_outline, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'No se pudo cargar el crédito',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta nuevamente',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _loadData,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Reintentar',
                        style: TextStyle(
                          color: Colors.white,
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
    );
  }

  Widget _buildCreditHeader(CustomerCredit credit) {
    final statusColor = _getStatusColor(credit.status);
    final isOverdue = credit.isOverdue;

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue
              ? Colors.red.withValues(alpha: 0.3)
              : ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          ...ElegantLightTheme.elevatedShadow,
          if (isOverdue)
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar con gradiente
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (credit.customerName ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credit.customerName ?? 'Cliente',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (credit.invoiceNumber != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            size: 12,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Factura: ${credit.invoiceNumber}',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Badge de estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(credit.status),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          credit.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditSummary(CustomerCredit credit) {
    final statusColor = _getStatusColor(credit.status);
    final progress = credit.paidPercentage / 100;
    final isOverdue = credit.isOverdue;

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título con icono
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(Icons.analytics, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Resumen del Crédito',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),

            if (credit.description != null && credit.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, size: 16, color: ElegantLightTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        credit.description!,
                        style: TextStyle(
                          color: ElegantLightTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Cards de montos
            Row(
              children: [
                Expanded(
                  child: _buildAmountCard(
                    label: 'Total',
                    amount: credit.originalAmount,
                    color: ElegantLightTheme.primaryBlue,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAmountCard(
                    label: 'Pagado',
                    amount: credit.paidAmount,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAmountCard(
                    label: 'Pendiente',
                    amount: credit.balanceDue,
                    color: isOverdue ? Colors.red : Colors.orange,
                    icon: Icons.pending,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Barra de progreso animada
            _buildAnimatedProgressBar(
              progress: progress,
              color: statusColor,
              percentage: credit.paidPercentage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatters.formatCurrency(amount),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgressBar({
    required double progress,
    required Color color,
    required double percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, size: 16, color: color),
                  const SizedBox(width: 8),
                  const Text(
                    'Progreso del Pago',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage),
                duration: ElegantLightTheme.slowAnimation,
                curve: ElegantLightTheme.smoothCurve,
                builder: (context, value, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${value.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de progreso con fondo visible (lo que falta por pagar)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return Stack(
                children: [
                  // FONDO - Muestra lo que FALTA por pagar (gris-azulado claro)
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE4EF), // Gris-azulado claro visible
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  // BARRA DE PROGRESO - Muestra lo PAGADO
                  FractionallySizedBox(
                    widthFactor: animatedProgress,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.85)],
                        ),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: _ShimmerEffect(color: color, height: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Formatear valor monetario de string a formato profesional
  /// Convierte "50000", "$50,000", "50.000" a formato estandarizado
  String _formatCurrencyValue(String value) {
    // Remover símbolos y espacios
    String cleanValue = value.replaceAll(RegExp(r'[\$\s]'), '');

    // Intentar parsear el número
    // Manejar formato con comas como separador de miles (ej: 50,000)
    // o con puntos como separador de miles (ej: 50.000)
    cleanValue = cleanValue.replaceAll(',', '');

    // Si el valor tiene punto y más de 2 decimales después, es separador de miles
    if (cleanValue.contains('.')) {
      final parts = cleanValue.split('.');
      if (parts.length == 2 && parts[1].length == 3) {
        // Es formato europeo (50.000 = 50000)
        cleanValue = cleanValue.replaceAll('.', '');
      }
    }

    final numValue = double.tryParse(cleanValue);
    if (numValue != null) {
      return AppFormatters.formatCurrency(numValue);
    }

    // Si no se puede parsear, devolver el valor original con formato básico
    return value.startsWith('\$') ? value : '\$$value';
  }

  /// Parsear las notas estructuradas del crédito
  /// Retorna un Map con la información parseada
  /// Formato del backend:
  /// 📄 FACTURA ORIGEN
  ///    • Número: XXX
  ///    • Fecha: XXX
  ///    • Total: $XXX
  /// 💰 PAGOS REALIZADOS
  ///    1. $X - Método (cuenta)
  /// 📊 SALDO PENDIENTE
  ///    • Monto del crédito: $X
  ///    • Porcentaje pendiente: X%
  /// 📅 INFORMACIÓN ADICIONAL
  ///    • Generado: XXX
  Map<String, dynamic> _parseCreditNotes(String notes) {
    final result = <String, dynamic>{
      'invoiceNumber': null,
      'invoiceDate': null,
      'invoiceTotal': null,
      'payments': <Map<String, String>>[],
      'totalPaid': null,
      'pendingAmount': null,
      'pendingPercentage': null,
      'generationDate': null,
      'additionalNotes': null,
    };

    final lines = notes.split('\n');
    bool inPaymentsSection = false;
    bool inNotesSection = false;
    final additionalNotesLines = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();

      // Detectar secciones
      if (trimmedLine.contains('PAGOS REALIZADOS')) {
        inPaymentsSection = true;
        inNotesSection = false;
        continue;
      }
      if (trimmedLine.contains('SALDO PENDIENTE')) {
        inPaymentsSection = false;
        inNotesSection = false;
        continue;
      }
      if (trimmedLine.contains('INFORMACIÓN ADICIONAL')) {
        inPaymentsSection = false;
        inNotesSection = false;
        continue;
      }
      if (trimmedLine.startsWith('📝 NOTAS') || trimmedLine == '📝 NOTAS') {
        inNotesSection = true;
        inPaymentsSection = false;
        continue;
      }

      // Parsear información de factura (después de 📄 FACTURA ORIGEN)
      if (trimmedLine.startsWith('• Número:')) {
        result['invoiceNumber'] = trimmedLine.replaceFirst('• Número:', '').trim();
      } else if (trimmedLine.startsWith('• Fecha:') && result['invoiceDate'] == null) {
        result['invoiceDate'] = trimmedLine.replaceFirst('• Fecha:', '').trim();
      } else if (trimmedLine.startsWith('• Total:')) {
        // Formatear el valor de total de factura
        final rawValue = trimmedLine.replaceFirst('• Total:', '').trim();
        result['invoiceTotal'] = _formatCurrencyValue(rawValue);
      }

      // Parsear pagos (formato: "1. $5,000 - Efectivo (Cuenta)")
      if (inPaymentsSection) {
        // Línea de pago: "1. $5,000 - Efectivo" o "1. $5,000 - Efectivo (Cuenta)"
        final paymentRegex = RegExp(r'^\d+\.\s+(\$[\d,.]+)\s+-\s+(.+)$');
        final match = paymentRegex.firstMatch(trimmedLine);
        if (match != null) {
          // Formatear el monto del pago
          final amount = _formatCurrencyValue(match.group(1)!);
          var methodPart = match.group(2)!;
          String? account;

          // Extraer cuenta si existe (entre paréntesis)
          final accountMatch = RegExp(r'^(.+?)\s*\((.+)\)$').firstMatch(methodPart);
          if (accountMatch != null) {
            methodPart = accountMatch.group(1)!.trim();
            account = accountMatch.group(2)!.trim();
          }

          (result['payments'] as List<Map<String, String>>).add({
            'amount': amount,
            'method': methodPart,
            if (account != null) 'account': account,
          });
        }
        // Total pagado
        if (trimmedLine.startsWith('Total pagado:')) {
          final rawValue = trimmedLine.replaceFirst('Total pagado:', '').trim();
          result['totalPaid'] = _formatCurrencyValue(rawValue);
        }
      }

      // Parsear saldo pendiente
      if (trimmedLine.startsWith('• Monto del crédito:')) {
        final rawValue = trimmedLine.replaceFirst('• Monto del crédito:', '').trim();
        result['pendingAmount'] = _formatCurrencyValue(rawValue);
      } else if (trimmedLine.startsWith('• Porcentaje pendiente:')) {
        result['pendingPercentage'] = trimmedLine.replaceFirst('• Porcentaje pendiente:', '').trim();
      }

      // Parsear fecha de generación
      if (trimmedLine.startsWith('• Generado:')) {
        result['generationDate'] = trimmedLine.replaceFirst('• Generado:', '').trim();
      }

      // Acumular notas adicionales
      if (inNotesSection && trimmedLine.isNotEmpty && !trimmedLine.startsWith('═')) {
        additionalNotesLines.add(trimmedLine);
      }
    }

    // Consolidar notas adicionales
    if (additionalNotesLines.isNotEmpty) {
      result['additionalNotes'] = additionalNotesLines.join(' ').trim();
    }

    return result;
  }

  /// Parsear notas simples del formato antiguo
  /// Formato: "Crédito creado automáticamente por pago parcial. Total factura: $50,000, Pagado: $5,000"
  Map<String, dynamic> _parseSimpleNotes(String notes) {
    final result = <String, dynamic>{
      'invoiceTotal': null,
      'totalPaid': null,
      'description': notes,
    };

    // Buscar Total factura
    final totalMatch = RegExp(r'Total factura:\s*\$?([\d,.]+)').firstMatch(notes);
    if (totalMatch != null) {
      result['invoiceTotal'] = _formatCurrencyValue(totalMatch.group(1)!);
    }

    // Buscar Pagado
    final paidMatch = RegExp(r'Pagado:\s*\$?([\d,.]+)').firstMatch(notes);
    if (paidMatch != null) {
      result['totalPaid'] = _formatCurrencyValue(paidMatch.group(1)!);
    }

    return result;
  }

  /// Sección que muestra el origen del crédito (cuando viene de una factura)
  Widget _buildCreditOriginSection(CustomerCredit credit) {
    // Parsear las notas si existen y tienen el formato esperado
    final hasStructuredNotes = credit.notes != null &&
        credit.notes!.contains('DETALLE DEL CRÉDITO');

    // Detectar notas simples del formato antiguo
    final hasSimpleNotes = credit.notes != null &&
        !hasStructuredNotes &&
        (credit.notes!.contains('Total factura:') || credit.notes!.contains('Pagado:'));

    final parsedNotes = hasStructuredNotes
        ? _parseCreditNotes(credit.notes!)
        : hasSimpleNotes
            ? _parseSimpleNotes(credit.notes!)
            : <String, dynamic>{};

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          ...ElegantLightTheme.elevatedShadow,
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con gradiente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.12),
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(Icons.receipt_long, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Origen del Crédito',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Generado desde factura parcial',
                        style: TextStyle(
                          fontSize: 12,
                          color: ElegantLightTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.link, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        credit.invoiceNumber ?? 'Vinculado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la factura origen (notas estructuradas)
                if (hasStructuredNotes && parsedNotes['invoiceNumber'] != null) ...[
                  _buildOriginInfoCard(
                    title: 'Factura Origen',
                    icon: Icons.description,
                    color: ElegantLightTheme.primaryBlue,
                    children: [
                      _buildOriginDetailRow(
                        'Número',
                        parsedNotes['invoiceNumber'] ?? credit.invoiceNumber ?? '-',
                        Icons.tag,
                      ),
                      if (parsedNotes['invoiceDate'] != null)
                        _buildOriginDetailRow(
                          'Fecha',
                          parsedNotes['invoiceDate']!,
                          Icons.calendar_today,
                        ),
                      if (parsedNotes['invoiceTotal'] != null)
                        _buildOriginDetailRow(
                          'Total Factura',
                          parsedNotes['invoiceTotal']!,
                          Icons.attach_money,
                          valueColor: ElegantLightTheme.primaryBlue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else if (hasSimpleNotes || credit.invoiceNumber != null) ...[
                  // Mostrar info básica o de notas simples
                  _buildOriginInfoCard(
                    title: 'Factura Origen',
                    icon: Icons.description,
                    color: ElegantLightTheme.primaryBlue,
                    children: [
                      if (credit.invoiceNumber != null)
                        _buildOriginDetailRow(
                          'Número',
                          credit.invoiceNumber!,
                          Icons.tag,
                        ),
                      if (hasSimpleNotes && parsedNotes['invoiceTotal'] != null)
                        _buildOriginDetailRow(
                          'Total Factura',
                          parsedNotes['invoiceTotal']!,
                          Icons.attach_money,
                          valueColor: ElegantLightTheme.primaryBlue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Pagos realizados (notas estructuradas)
                if (hasStructuredNotes && (parsedNotes['payments'] as List).isNotEmpty) ...[
                  _buildOriginInfoCard(
                    title: 'Pagos Realizados',
                    icon: Icons.payment,
                    color: Colors.green,
                    children: [
                      ...(parsedNotes['payments'] as List<Map<String, String>>).map((payment) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getPaymentMethodIcon(payment['method']),
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment['method'] ?? 'Pago',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: ElegantLightTheme.textPrimary,
                                      ),
                                    ),
                                    if (payment['account'] != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        payment['account']!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: ElegantLightTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                payment['amount'] ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // Mostrar total pagado si está disponible
                      if (parsedNotes['totalPaid'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Pagado',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                              ),
                              Text(
                                parsedNotes['totalPaid']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else if (hasSimpleNotes && parsedNotes['totalPaid'] != null) ...[
                  // Para notas simples, mostrar solo el total pagado
                  _buildOriginInfoCard(
                    title: 'Pago Inicial',
                    icon: Icons.payment,
                    color: Colors.green,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withValues(alpha: 0.12),
                              Colors.green.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 24,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monto Pagado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ElegantLightTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    parsedNotes['totalPaid']!,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Saldo pendiente (este crédito)
                if (hasStructuredNotes && parsedNotes['pendingAmount'] != null) ...[
                  _buildOriginInfoCard(
                    title: 'Saldo Pendiente',
                    icon: Icons.pending,
                    color: Colors.orange,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withValues(alpha: 0.12),
                              Colors.orange.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Monto del Crédito',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ElegantLightTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    parsedNotes['pendingAmount']!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (parsedNotes['pendingPercentage'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  parsedNotes['pendingPercentage']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Fecha de generación y notas adicionales
                if (hasStructuredNotes && parsedNotes['generationDate'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: ElegantLightTheme.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generado: ${parsedNotes['generationDate']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ElegantLightTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (hasStructuredNotes && parsedNotes['additionalNotes'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parsedNotes['additionalNotes']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: ElegantLightTheme.textSecondary,
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
        ],
      ),
    );
  }

  /// Card de información de origen
  Widget _buildOriginInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  /// Fila de detalle de origen
  Widget _buildOriginDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: ElegantLightTheme.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? ElegantLightTheme.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(CustomerCredit credit) {
    // Determinar si las notas son estructuradas (del sistema)
    final hasStructuredNotes = credit.notes != null &&
        credit.notes!.contains('DETALLE DEL CRÉDITO');

    // Detectar notas simples del formato antiguo (ya se muestran en sección de origen)
    final hasSimpleNotes = credit.notes != null &&
        !hasStructuredNotes &&
        (credit.notes!.contains('Total factura:') || credit.notes!.contains('Pagado:'));

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.infoGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.glowShadow,
                  ),
                  child: const Icon(Icons.info_outline, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Información',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Fecha de creación',
              value: DateFormat('dd/MM/yyyy HH:mm').format(credit.createdAt),
              color: ElegantLightTheme.primaryBlue,
            ),
            if (credit.dueDate != null)
              _buildInfoRow(
                icon: Icons.event,
                label: 'Fecha de vencimiento',
                value: DateFormat('dd/MM/yyyy').format(credit.dueDate!),
                color: credit.isOverdue ? Colors.red : Colors.orange,
                isHighlighted: credit.isOverdue,
              ),
            if (credit.createdByName != null)
              _buildInfoRow(
                icon: Icons.person,
                label: 'Creado por',
                value: credit.createdByName!,
                color: Colors.purple,
              ),
            // Solo mostrar notas si NO son estructuradas ni simples (ya se muestran en la sección de origen)
            if (credit.notes != null && credit.notes!.isNotEmpty && !hasStructuredNotes && !hasSimpleNotes)
              _buildInfoRow(
                icon: Icons.note,
                label: 'Notas',
                value: credit.notes!,
                color: Colors.teal,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isHighlighted ? 0.12 : 0.06),
            color.withValues(alpha: isHighlighted ? 0.06 : 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isHighlighted ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isHighlighted ? color : ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final transactions = _controller.currentCreditTransactions;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.history, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Historial de Movimientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Text(
                      '${transactions.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            Obx(() {
              final transactions = _controller.currentCreditTransactions.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (transactions.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history,
                            size: 40,
                            color: ElegantLightTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay movimientos registrados',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: transactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final transaction = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: ElegantLightTheme.smoothCurve,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: _buildTransactionItem(transaction),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Obtener nombre legible del método de pago
  /// Si hay bankAccountName, lo usa. Si no, traduce el paymentMethod
  String _getPaymentMethodDisplayName(String? method, String? bankAccountName) {
    // Si hay nombre de cuenta bancaria, usarlo directamente
    if (bankAccountName != null && bankAccountName.isNotEmpty) {
      return bankAccountName;
    }

    // Si no hay método, asumir efectivo
    if (method == null || method.isEmpty) return 'Efectivo';

    switch (method.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'bank_transfer':
        return 'Transferencia';
      case 'nequi':
        return 'Nequi';
      case 'daviplata':
        return 'Daviplata';
      case 'credit_card':
        return 'Tarjeta de Crédito';
      case 'debit_card':
        return 'Tarjeta Débito';
      case 'pse':
        return 'PSE';
      case 'other':
        return 'Otro';
      default:
        // Si es un nombre personalizado, mostrarlo capitalizado
        if (method.contains('_')) {
          return method.split('_').map((word) =>
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
          ).join(' ');
        }
        return method.isNotEmpty
            ? '${method[0].toUpperCase()}${method.substring(1)}'
            : 'Efectivo';
    }
  }

  /// Obtener icono del método de pago
  IconData _getPaymentMethodIcon(String? method) {
    if (method == null || method.isEmpty) return Icons.money;

    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'nequi':
      case 'daviplata':
        return Icons.phone_android;
      case 'credit_card':
        return Icons.credit_card;
      case 'debit_card':
        return Icons.credit_card;
      case 'pse':
        return Icons.language;
      default:
        return Icons.payment;
    }
  }

  /// Extrae el saldo generado de la descripción si existe el patrón [SALDO_GENERADO:XXXX]
  double? _extractGeneratedBalance(String? description) {
    if (description == null) return null;
    final match = RegExp(r'\[SALDO_GENERADO:(\d+(?:\.\d+)?)\]').firstMatch(description);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  /// Limpia la descripción removiendo el patrón [SALDO_GENERADO:XXXX]
  String? _cleanDescription(String? description) {
    if (description == null) return null;
    final cleaned = description.replaceAll(RegExp(r'\s*\[SALDO_GENERADO:\d+(?:\.\d+)?\]'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  Widget _buildTransactionItem(CreditTransactionModel transaction) {
    final isPayment = transaction.type == CreditTransactionType.payment ||
        transaction.type == CreditTransactionType.balanceUsed;
    final isCharge = transaction.type == CreditTransactionType.charge;
    final isDebtIncrease = transaction.type == CreditTransactionType.debtIncrease;

    // Detectar si el pago generó saldo a favor
    final generatedBalance = _extractGeneratedBalance(transaction.description);
    final cleanedDescription = _cleanDescription(transaction.description);

    Color transactionColor;
    IconData transactionIcon;
    String transactionLabel;
    String transactionSign;
    LinearGradient gradient;

    if (isPayment) {
      transactionColor = Colors.green;
      transactionIcon = transaction.type == CreditTransactionType.balanceUsed
          ? Icons.account_balance_wallet
          : Icons.payment;
      transactionLabel = transaction.type == CreditTransactionType.balanceUsed
          ? 'Saldo a Favor'
          : 'Pago';
      transactionSign = '-';
      gradient = ElegantLightTheme.successGradient;
    } else if (isCharge) {
      transactionColor = ElegantLightTheme.primaryBlue;
      transactionIcon = Icons.receipt_long;
      transactionLabel = 'Deuda Inicial';
      transactionSign = '+';
      gradient = ElegantLightTheme.primaryGradient;
    } else if (isDebtIncrease) {
      transactionColor = Colors.orange;
      transactionIcon = Icons.trending_up;
      transactionLabel = 'Aumento de Deuda';
      transactionSign = '+';
      gradient = ElegantLightTheme.warningGradient;
    } else {
      transactionColor = ElegantLightTheme.textSecondary;
      transactionIcon = Icons.swap_horiz;
      transactionLabel = 'Movimiento';
      transactionSign = '';
      gradient = ElegantLightTheme.glassGradient;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            transactionColor.withValues(alpha: 0.06),
            transactionColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: transactionColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: transactionColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(transactionIcon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$transactionSign${AppFormatters.formatCurrency(transaction.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: transactionColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yy').format(transaction.createdAt),
                        style: TextStyle(
                          color: ElegantLightTheme.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Label de tipo de transacción + método de pago + saldo generado
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              transactionColor.withValues(alpha: 0.12),
                              transactionColor.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transactionLabel,
                          style: TextStyle(
                            color: transactionColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      // Mostrar método de pago para pagos
                      if (isPayment) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPaymentMethodIcon(transaction.paymentMethod),
                                size: 11,
                                color: ElegantLightTheme.primaryBlue,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _getPaymentMethodDisplayName(
                                  transaction.paymentMethod,
                                  transaction.bankAccountName,
                                ),
                                style: TextStyle(
                                  color: ElegantLightTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Badge de saldo a favor generado (si el pago generó saldo)
                      if (generatedBalance != null && generatedBalance > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.teal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.savings,
                                size: 11,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '+${AppFormatters.formatCurrency(generatedBalance)} a favor',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Mostrar descripción solo si NO es automática (abono via...)
                  if (cleanedDescription != null &&
                      cleanedDescription.isNotEmpty &&
                      !cleanedDescription.toLowerCase().startsWith('abono via')) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notes,
                            size: 12,
                            color: ElegantLightTheme.textTertiary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cleanedDescription,
                              style: TextStyle(
                                color: ElegantLightTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildTransactionMeta(
                        icon: Icons.access_time,
                        value: DateFormat('HH:mm').format(transaction.createdAt),
                      ),
                      const SizedBox(width: 12),
                      _buildTransactionMeta(
                        icon: Icons.account_balance,
                        value: 'Saldo: ${AppFormatters.formatCurrency(transaction.balanceAfter)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionMeta({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 10, color: ElegantLightTheme.textTertiary),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: ElegantLightTheme.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      case CreditStatus.cancelled:
        return ElegantLightTheme.textTertiary;
      case CreditStatus.overdue:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(CreditStatus status) {
    switch (status) {
      case CreditStatus.pending:
        return Icons.schedule;
      case CreditStatus.partiallyPaid:
        return Icons.timelapse;
      case CreditStatus.paid:
        return Icons.check_circle;
      case CreditStatus.cancelled:
        return Icons.cancel;
      case CreditStatus.overdue:
        return Icons.warning;
    }
  }

  void _handleMenuAction(String action) {
    final credit = _controller.selectedCredit.value;
    if (credit == null) return;

    switch (action) {
      case 'add_payment':
        _navigateToAddPayment(credit);
        break;
      case 'add_debt':
        _showAddDebtDialog(credit);
        break;
      case 'cancel':
        _confirmCancelCredit(credit);
        break;
    }
  }

  void _navigateToAddPayment(CustomerCredit credit) async {
    final result = await Get.dialog<bool>(
      AddCreditPaymentDialog(credit: credit),
      barrierDismissible: false,
    );

    if (result == true) {
      _loadData();
    }
  }

  void _showAddDebtDialog(CustomerCredit credit) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Agregar Deuda',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.1),
                      Colors.orange.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 18, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Text('Saldo actual: '),
                    Text(
                      AppFormatters.formatCurrency(credit.balanceDue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Monto a agregar *',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ElegantLightTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '¿Qué está llevando? *',
                  hintText: 'Ej: Compra adicional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: ElegantLightTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: ElegantLightTheme.textSecondary),
            ),
          ),
          Obx(() => Container(
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _controller.isProcessing.value
                        ? null
                        : () async {
                            final amount = double.tryParse(amountController.text) ?? 0;
                            if (amount <= 0) {
                              Get.snackbar(
                                'Error',
                                'El monto debe ser mayor a cero',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            if (descriptionController.text.trim().isEmpty) {
                              Get.snackbar(
                                'Error',
                                'La descripción es obligatoria',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            final success = await _controller.addAmountToCredit(
                              creditId: credit.id,
                              amount: amount,
                              description: descriptionController.text.trim(),
                            );

                            if (success) {
                              Get.back();
                              _loadData();
                            }
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: _controller.isProcessing.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Agregar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _confirmCancelCredit(CustomerCredit credit) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cancelar Crédito',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¿Está seguro de cancelar este crédito de ${AppFormatters.formatCurrency(credit.originalAmount)}?',
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('No'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.errorGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  Get.back();
                  final success = await _controller.cancelCredit(credit.id);
                  if (success) {
                    Get.back();
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text(
                    'Sí, cancelar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Efecto shimmer animado para barras de progreso
class _ShimmerEffect extends StatefulWidget {
  final Color color;
  final double height;

  const _ShimmerEffect({
    required this.color,
    required this.height,
  });

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
