// lib/features/cash_register/presentation/screens/cash_register_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../../../../app/presentation/widgets/sync_status_indicator.dart';
import '../../domain/entities/cash_register.dart';
import '../controllers/cash_register_controller.dart';

/// Pantalla principal de Caja Registradora.
/// Estilo: ElegantLightTheme con AppBar gradient + drawer + cards glass.
class CashRegisterScreen extends GetView<CashRegisterController> {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      drawer: const AppDrawer(),
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.currentState.value.cashRegister == null) {
          return _buildLoadingState();
        }
        if (controller.errorMessage.isNotEmpty &&
            !controller.hasOpenRegister) {
          return _buildErrorView();
        }
        return RefreshIndicator(
          onRefresh: controller.loadCurrent,
          color: ElegantLightTheme.primaryBlue,
          backgroundColor: ElegantLightTheme.surfaceColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: controller.hasOpenRegister
                ? _buildOpenView(context)
                : _buildClosedView(context),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR (gradient, drawer, sync icon)
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(Icons.point_of_sale_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Caja Registradora',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 19,
              shadows: [
                Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2)),
              ],
            ),
          ),
        ],
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Menú',
        ),
      ),
      actions: [
        const SyncStatusIcon(),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refrescar',
          onPressed: controller.loadCurrent,
        ),
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white),
          tooltip: 'Historial',
          onPressed: () {
            controller.loadHistory();
            Get.toNamed('/cash-register/history');
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color:
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: CircularProgressIndicator(
              color: ElegantLightTheme.primaryBlue,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando estado de caja...',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.errorRed
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
              onPressed: controller.loadCurrent,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ESTADO: SIN CAJA ABIERTA
  // ═══════════════════════════════════════════════════════════════
  Widget _buildClosedView(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: ElegantLightTheme.glassDecoration(
                borderColor: ElegantLightTheme.warningOrange
                    .withValues(alpha: 0.3),
                gradient: ElegantLightTheme.glassGradient,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.warningGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.warningOrange
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        size: 56, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Caja cerrada',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: ElegantLightTheme.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para empezar a registrar ventas en efectivo, abre la '
                    'caja con el saldo inicial del turno.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ElegantLightTheme.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue
                                .withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showOpenDialog(context),
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_open_rounded,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'Abrir Caja',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ESTADO: CAJA ABIERTA
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOpenView(BuildContext context) {
    final reg = controller.openRegister!;
    final s = controller.summary;
    final expected = controller.expectedAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOpenHero(reg, expected),
        const SizedBox(height: AppDimensions.spacingMedium),
        _buildBreakdownCard(reg, s, expected),
        const SizedBox(height: AppDimensions.spacingMedium),
        _buildCloseButton(context),
        const SizedBox(height: AppDimensions.spacingLarge),
      ],
    );
  }

  Widget _buildOpenHero(CashRegister reg, double expected) {
    final formattedOpen = AppFormatters.formatDateTime(reg.openedAt);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.successGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.successGreen
                    .withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_open_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Turno Activo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  _buildDurationChip(reg.duration),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'EFECTIVO ESPERADO EN CAJA',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppFormatters.formatCurrency(expected),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _buildHeroChip(
                    icon: Icons.access_time_rounded,
                    label: formattedOpen,
                  ),
                  if (reg.openedByName != null)
                    _buildHeroChip(
                      icon: Icons.person_outline_rounded,
                      label: reg.openedByName!,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final txt = h > 0 ? '${h}h ${m}m' : '${m}m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        txt,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12),
      ),
    );
  }

  Widget _buildBreakdownCard(
    CashRegister reg,
    CashRegisterSummary s,
    double expected,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: ElegantLightTheme.glassDecoration(
            borderColor:
                ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
            gradient: ElegantLightTheme.glassGradient,
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.calculate_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Resumen del turno',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRow(
                icon: Icons.savings_rounded,
                label: 'Saldo inicial',
                amount: reg.openingAmount,
                gradient: ElegantLightTheme.infoGradient,
              ),
              const SizedBox(height: 8),
              _buildRow(
                icon: Icons.point_of_sale_rounded,
                label: 'Ventas en efectivo',
                sub:
                    '${s.cashSalesCount} pago${s.cashSalesCount != 1 ? "s" : ""}',
                amount: s.cashSales,
                gradient: ElegantLightTheme.successGradient,
              ),
              if (s.cashExpenses > 0) ...[
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.receipt_long_rounded,
                  label: 'Gastos pagados',
                  sub:
                      '${s.cashExpensesCount} gasto${s.cashExpensesCount != 1 ? "s" : ""}',
                  amount: -s.cashExpenses,
                  gradient: ElegantLightTheme.warningGradient,
                ),
              ],
              if (s.creditNotesTotal > 0) ...[
                const SizedBox(height: 8),
                _buildRow(
                  icon: Icons.assignment_return_outlined,
                  label: 'Notas de crédito',
                  sub:
                      '${s.creditNotesCount} NC aplicada${s.creditNotesCount != 1 ? "s" : ""}',
                  amount: -s.creditNotesTotal,
                  gradient: ElegantLightTheme.errorGradient,
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue
                          .withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'EFECTIVO ESPERADO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(expected),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    String? sub,
    required double amount,
    required LinearGradient gradient,
  }) {
    final isNegative = amount < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: gradient.colors.first.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: gradient.colors.first.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: TextStyle(
                      fontSize: 11,
                      color: ElegantLightTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isNegative ? '−' : ''}${AppFormatters.formatCurrency(amount.abs())}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isNegative
                  ? ElegantLightTheme.errorRed
                  : ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.errorGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.errorRed.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCloseDialog(context),
          borderRadius: BorderRadius.circular(14),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Cerrar Caja',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS (theme elegant)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showOpenDialog(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
              ),
              // SingleChildScrollView protege contra overflows masivos
              // cuando el teclado del celular invade el viewport y el
              // dialog ya no cabe. Sin esto el RenderFlex tira el famoso
              // "A RenderFlex overflowed by 99880 pixels".
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.successGreen
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock_open_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Abrir caja',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa el efectivo físico con el que arrancas el '
                      'turno (fondo de caja, vueltas, etc).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: ElegantLightTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amountCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      style: TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Saldo inicial',
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                            color: ElegantLightTheme.successGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                        filled: true,
                        fillColor: ElegantLightTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: ElegantLightTheme.textTertiary
                                  .withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: ElegantLightTheme.successGreen,
                              width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Ingresa el saldo (puede ser 0)';
                        }
                        final n =
                            double.tryParse(v.replaceAll(',', ''));
                        if (n == null || n < 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLength: 200,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        filled: true,
                        fillColor: ElegantLightTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: ElegantLightTheme.textTertiary
                                  .withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                side: BorderSide(
                                    color: ElegantLightTheme
                                        .textTertiary
                                        .withValues(alpha: 0.4)),
                              ),
                            ),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                  color: ElegantLightTheme
                                      .textSecondary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Obx(() => Container(
                                decoration: BoxDecoration(
                                  gradient: controller
                                          .isSubmitting.value
                                      ? null
                                      : ElegantLightTheme
                                          .successGradient,
                                  color: controller
                                          .isSubmitting.value
                                      ? ElegantLightTheme
                                          .textTertiary
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  boxShadow: controller
                                          .isSubmitting.value
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: ElegantLightTheme
                                                .successGreen
                                                .withValues(
                                                    alpha: 0.3),
                                            blurRadius: 10,
                                            offset:
                                                const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    onTap: controller
                                            .isSubmitting.value
                                        ? null
                                        : () async {
                                            if (!formKey
                                                .currentState!
                                                .validate())
                                              return;
                                            final amount = double
                                                    .tryParse(
                                                        amountCtrl
                                                            .text
                                                            .replaceAll(
                                                                ',',
                                                                '')) ??
                                                0;
                                            final desc = notesCtrl
                                                .text
                                                .trim();
                                            final ok =
                                                await controller
                                                    .open(
                                              openingAmount: amount,
                                              openingNotes:
                                                  desc.isEmpty
                                                      ? null
                                                      : desc,
                                            );
                                            if (ok)
                                              Navigator.of(ctx)
                                                  .pop(true);
                                          },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        children: [
                                          if (controller
                                              .isSubmitting.value)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          else
                                            const Icon(
                                                Icons
                                                    .lock_open_rounded,
                                                color: Colors.white,
                                                size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            controller
                                                    .isSubmitting
                                                    .value
                                                ? 'Abriendo...'
                                                : 'Abrir caja',
                                            style:
                                                const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Dispose AFTER el siguiente frame.
    //
    // Bug previo: cuando `showDialog` retorna por Navigator.pop, la
    // animación de cierre del Dialog sigue corriendo unos frames más
    // (transitions.dart `_AnimatedState.didUpdateWidget` rebuilds).
    // Hacer dispose inmediatamente provoca
    // "A TextEditingController was used after being disposed" +
    // "_dependents.isEmpty" del Inherited.
    //
    // Retrasar el dispose hasta después del frame siguiente garantiza
    // que la animación de cierre terminó antes de matar el controller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      amountCtrl.dispose();
      notesCtrl.dispose();
    });
    if (result == true) controller.loadCurrent();
  }

  Future<void> _showCloseDialog(BuildContext context) async {
    final reg = controller.openRegister;
    if (reg == null) return;
    final expected = controller.expectedAmount;
    final actualCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
              ),
              // Scrollable defensivo — el teclado al desplegar reduce
              // el viewport y este dialog tiene varios campos. Sin esto
              // RenderFlex tira "overflowed by 99880 pixels".
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient:
                              ElegantLightTheme.errorGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ElegantLightTheme.errorRed
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 30),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Cerrar caja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantLightTheme.primaryBlue
                                .withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'EFECTIVO ESPERADO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white
                                        .withValues(alpha: 0.85),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  AppFormatters.formatCurrency(
                                      expected),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: actualCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]')),
                      ],
                      style: TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Efectivo contado físicamente *',
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                            color: ElegantLightTheme.errorRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                        helperText:
                            'Cuenta el dinero en caja y registra el monto real.',
                        filled: true,
                        fillColor: ElegantLightTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: ElegantLightTheme.textTertiary
                                  .withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: ElegantLightTheme.errorRed,
                              width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Cuenta el efectivo y registra el monto';
                        }
                        final n =
                            double.tryParse(v.replaceAll(',', ''));
                        if (n == null || n < 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesCtrl,
                      maxLength: 200,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Ej: faltante por vuelto extra...',
                        filled: true,
                        fillColor: ElegantLightTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: ElegantLightTheme.textTertiary
                                  .withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop(false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                                side: BorderSide(
                                    color: ElegantLightTheme
                                        .textTertiary
                                        .withValues(alpha: 0.4)),
                              ),
                            ),
                            child: Text('Cancelar',
                                style: TextStyle(
                                    color: ElegantLightTheme
                                        .textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Obx(() => Container(
                                decoration: BoxDecoration(
                                  gradient: controller
                                          .isSubmitting.value
                                      ? null
                                      : ElegantLightTheme
                                          .errorGradient,
                                  color: controller
                                          .isSubmitting.value
                                      ? ElegantLightTheme
                                          .textTertiary
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  boxShadow: controller
                                          .isSubmitting.value
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: ElegantLightTheme
                                                .errorRed
                                                .withValues(
                                                    alpha: 0.3),
                                            blurRadius: 10,
                                            offset:
                                                const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    onTap: controller
                                            .isSubmitting.value
                                        ? null
                                        : () async {
                                            if (!formKey
                                                .currentState!
                                                .validate())
                                              return;
                                            final actual = double
                                                    .tryParse(
                                                        actualCtrl
                                                            .text
                                                            .replaceAll(
                                                                ',',
                                                                '')) ??
                                                0;
                                            final desc = notesCtrl
                                                .text
                                                .trim();
                                            final ok =
                                                await controller
                                                    .close(
                                              closingActualAmount:
                                                  actual,
                                              closingNotes:
                                                  desc.isEmpty
                                                      ? null
                                                      : desc,
                                            );
                                            if (ok)
                                              Navigator.of(ctx)
                                                  .pop(true);
                                          },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 14),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        children: [
                                          if (controller
                                              .isSubmitting.value)
                                            const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          else
                                            const Icon(
                                                Icons
                                                    .lock_outline_rounded,
                                                color: Colors.white,
                                                size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            controller
                                                    .isSubmitting
                                                    .value
                                                ? 'Cerrando...'
                                                : 'Cerrar caja',
                                            style:
                                                const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Ver nota en _showOpenDialog. Mismo bug, mismo fix.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      actualCtrl.dispose();
      notesCtrl.dispose();
    });
  }
}
