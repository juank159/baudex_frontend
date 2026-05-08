// lib/features/cash_register/presentation/screens/cash_register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/services/tenant_datetime_service.dart';
import '../../domain/entities/cash_register.dart';
import '../controllers/cash_register_controller.dart';

/// Pantalla principal de Caja Registradora.
///
/// 2 estados visuales según `controller.hasOpenRegister`:
///   - Sin caja abierta → tarjeta grande con botón "Abrir Caja".
///   - Con caja abierta → resumen del turno + botón "Cerrar Caja".
class CashRegisterScreen extends GetView<CashRegisterController> {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja Registradora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refrescar',
            onPressed: controller.loadCurrent,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () {
              controller.loadHistory();
              Get.toNamed('/cash-register/history');
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value &&
            controller.currentState.value.cashRegister == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.isNotEmpty &&
            !controller.hasOpenRegister) {
          return _buildErrorView();
        }
        return RefreshIndicator(
          onRefresh: controller.loadCurrent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: controller.hasOpenRegister
                ? _buildOpenView(context)
                : _buildClosedView(context),
          ),
        );
      }),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
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
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.point_of_sale_rounded,
                  size: 56, color: Colors.amber.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Caja cerrada',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay turno activo. Abre la caja para empezar a registrar '
              'ventas en efectivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.lock_open_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Abrir Caja',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                onPressed: () => _showOpenDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ESTADO: CAJA ABIERTA — resumen del turno
  // ═══════════════════════════════════════════════════════════════
  Widget _buildOpenView(BuildContext context) {
    final reg = controller.openRegister!;
    final s = controller.summary;
    final expected = controller.expectedAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOpenHeader(reg, expected),
        const SizedBox(height: 16),
        _buildBreakdownCard(reg, s, expected),
        const SizedBox(height: 16),
        _buildCloseButton(context),
      ],
    );
  }

  Widget _buildOpenHeader(CashRegister reg, double expected) {
    final tz = Get.isRegistered<TenantDateTimeService>()
        ? Get.find<TenantDateTimeService>()
        : null;
    final formattedOpen = tz != null
        ? AppFormatters.formatDateTime(reg.openedAt)
        : reg.openedAt.toIso8601String();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade500, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300.withOpacity(0.4),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Turno Activo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildDurationChip(reg.duration),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Efectivo esperado en caja',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatCurrency(expected),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                'Abierta: $formattedOpen',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
              if (reg.openedByName != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.person, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  reg.openedByName!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final txt = h > 0 ? '${h}h ${m}m' : '${m}m';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        txt,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildBreakdownCard(
    CashRegister reg,
    CashRegisterSummary s,
    double expected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildRow(
            icon: Icons.savings_rounded,
            label: 'Saldo inicial',
            amount: reg.openingAmount,
            color: Colors.blueGrey.shade600,
          ),
          const Divider(height: 24),
          _buildRow(
            icon: Icons.point_of_sale_rounded,
            label: 'Ventas en efectivo',
            sub: '${s.cashSalesCount} pago${s.cashSalesCount != 1 ? "s" : ""}',
            amount: s.cashSales,
            color: Colors.green.shade700,
          ),
          if (s.cashExpenses > 0) ...[
            const SizedBox(height: 12),
            _buildRow(
              icon: Icons.receipt_long_rounded,
              label: 'Gastos pagados',
              sub:
                  '${s.cashExpensesCount} gasto${s.cashExpensesCount != 1 ? "s" : ""}',
              amount: -s.cashExpenses,
              color: Colors.orange.shade700,
            ),
          ],
          if (s.creditNotesTotal > 0) ...[
            const SizedBox(height: 12),
            _buildRow(
              icon: Icons.assignment_return_outlined,
              label: 'Notas de crédito',
              sub:
                  '${s.creditNotesCount} NC aplicada${s.creditNotesCount != 1 ? "s" : ""}',
              amount: -s.creditNotesTotal,
              color: Colors.red.shade700,
            ),
          ],
          const Divider(height: 24, thickness: 1),
          _buildRow(
            icon: Icons.account_balance_wallet_rounded,
            label: 'EFECTIVO ESPERADO',
            amount: expected,
            color: Colors.indigo.shade800,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required String label,
    String? sub,
    required double amount,
    required Color color,
    bool bold = false,
  }) {
    final isNegative = amount < 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
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
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                  letterSpacing: bold ? 0.4 : 0,
                ),
              ),
              if (sub != null)
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        Text(
          '${isNegative ? '−' : ''}${AppFormatters.formatCurrency(amount.abs())}',
          style: TextStyle(
            fontSize: bold ? 18 : 15,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.lock_outline_rounded),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Cerrar Caja',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _showCloseDialog(context),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _showOpenDialog(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_open_rounded,
            color: Colors.green.shade700, size: 36),
        title: const Text('Abrir caja'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ingresa el efectivo físico con el que arrancas el turno '
                  '(fondo de caja, vueltas, etc).',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Saldo inicial',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el saldo inicial (puede ser 0)';
                    }
                    final n = double.tryParse(v.replaceAll(',', ''));
                    if (n == null || n < 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLength: 200,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          Obx(() => FilledButton.icon(
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_open_rounded),
                label: Text(controller.isSubmitting.value
                    ? 'Abriendo...'
                    : 'Abrir caja'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700),
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final amount = double.tryParse(
                                amountCtrl.text.replaceAll(',', '')) ??
                            0;
                        final desc = notesCtrl.text.trim();
                        final ok = await controller.open(
                          openingAmount: amount,
                          openingNotes: desc.isEmpty ? null : desc,
                        );
                        if (ok) Navigator.of(ctx).pop(true);
                      },
              )),
        ],
      ),
    );
    amountCtrl.dispose();
    notesCtrl.dispose();
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
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.lock_outline_rounded,
            color: Colors.red.shade700, size: 36),
        title: const Text('Cerrar caja'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.indigo.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Efectivo esperado en caja',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.indigo.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              AppFormatters.formatCurrency(expected),
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.indigo.shade800,
                                fontWeight: FontWeight.w800,
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Efectivo contado físicamente *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                    helperText:
                        'Cuenta el dinero en caja y registra el monto real.',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Cuenta el efectivo y registra el monto';
                    }
                    final n = double.tryParse(v.replaceAll(',', ''));
                    if (n == null || n < 0) return 'Monto inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesCtrl,
                  maxLength: 200,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText:
                        'Ej: faltante por vuelto extra dado, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          Obx(() => FilledButton.icon(
                icon: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_outline_rounded),
                label: Text(controller.isSubmitting.value
                    ? 'Cerrando...'
                    : 'Cerrar caja'),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700),
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final actual = double.tryParse(
                                actualCtrl.text.replaceAll(',', '')) ??
                            0;
                        final desc = notesCtrl.text.trim();
                        final ok = await controller.close(
                          closingActualAmount: actual,
                          closingNotes: desc.isEmpty ? null : desc,
                        );
                        if (ok) Navigator.of(ctx).pop(true);
                      },
              )),
        ],
      ),
    );
    actualCtrl.dispose();
    notesCtrl.dispose();
  }
}
