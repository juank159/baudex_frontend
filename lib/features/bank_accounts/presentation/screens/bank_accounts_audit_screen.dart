import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../data/datasources/bank_account_remote_datasource.dart';

/// Pantalla de Auditoría de Saldos Bancarios (Phase 0.4).
///
/// Detecta desfases entre el `currentBalance` guardado en cada cuenta
/// y el saldo reconstruido a partir de los movimientos. Permite al admin
/// recalcular cuentas individualmente.
///
/// Solo es accesible para admin. La protección final está en el backend
/// (endpoints exigen ADMIN o ADMIN/MANAGER), pero también se filtra por
/// `PermissionGate.canDelete('bank_accounts')` en el botón que abre la
/// pantalla — recalcular es una acción destructiva sobre saldos.
class BankAccountsAuditScreen extends StatefulWidget {
  const BankAccountsAuditScreen({super.key});

  @override
  State<BankAccountsAuditScreen> createState() =>
      _BankAccountsAuditScreenState();
}

class _BankAccountsAuditScreenState extends State<BankAccountsAuditScreen> {
  late final BankAccountRemoteDataSource _ds;
  final RxBool _loading = true.obs;
  final RxBool _recalculating = false.obs;
  final RxList<Map<String, dynamic>> _results = <Map<String, dynamic>>[].obs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = Get.find<BankAccountRemoteDataSource>();
    _audit();
  }

  Future<void> _audit() async {
    _loading.value = true;
    _error = null;
    try {
      final list = await _ds.auditAccounts();
      _results.assignAll(list);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _recalculate(String accountId, String accountName) async {
    if (_recalculating.value) return;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.calculate_rounded,
            color: ElegantLightTheme.warningOrange, size: 36),
        title: Text('Recalcular $accountName'),
        content: const Text(
          'Esta operación reescribe el saldo de la cuenta y de cada uno '
          'de sus movimientos basándose en la suma cronológica.\n\n'
          'Es seguro de ejecutar — corrige el desfase. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.calculate_rounded, size: 16),
            label: const Text('Recalcular'),
            style: FilledButton.styleFrom(
              backgroundColor: ElegantLightTheme.warningOrange,
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    _recalculating.value = true;
    try {
      final result = await _ds.recalculateBalance(accountId);
      Get.snackbar(
        'Balance recalculado',
        '$accountName: ${AppFormatters.formatCurrency((result['newBalance'] as num?)?.toDouble() ?? 0)} '
            '(${result['movementCount']} movimientos)',
        snackPosition: SnackPosition.TOP,
        backgroundColor:
            ElegantLightTheme.successGreen.withValues(alpha: 0.12),
        colorText: ElegantLightTheme.successGreen,
        icon: Icon(Icons.check_circle, color: ElegantLightTheme.successGreen),
        duration: const Duration(seconds: 4),
      );
      // Re-auditar para refrescar la lista (la cuenta corregida desaparece).
      await _audit();
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo recalcular: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: ElegantLightTheme.errorRed.withValues(alpha: 0.12),
        colorText: ElegantLightTheme.errorRed,
      );
    } finally {
      _recalculating.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      body: Column(
        children: [
          _Header(onRefresh: _audit, loading: _loading),
          Expanded(
            child: Obx(() {
              if (_loading.value && _results.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_error != null && _results.isEmpty) {
                return _ErrorState(message: _error!, onRetry: _audit);
              }
              if (_results.isEmpty) {
                return const _AllGoodState();
              }
              return RefreshIndicator(
                onRefresh: _audit,
                color: ElegantLightTheme.primaryBlue,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final item = _results[i];
                    return _DiscrepancyCard(
                      item: item,
                      isRecalculating: _recalculating,
                      onRecalculate: () => _recalculate(
                        item['bankAccountId']?.toString() ?? '',
                        item['accountName']?.toString() ?? 'Cuenta',
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  final RxBool loading;
  const _Header({required this.onRefresh, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fact_check_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auditoría de Saldos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Detecta y corrige desfases bancarios',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Obx(() => loading.value
                ? const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    icon:
                        const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: onRefresh,
                    tooltip: 'Auditar de nuevo',
                  )),
          ],
        ),
      ),
    );
  }
}

class _DiscrepancyCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final RxBool isRecalculating;
  final VoidCallback onRecalculate;
  const _DiscrepancyCard({
    required this.item,
    required this.isRecalculating,
    required this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    final stored = (item['storedBalance'] as num?)?.toDouble() ?? 0;
    final computed = (item['computedBalance'] as num?)?.toDouble() ?? 0;
    final diff = (item['difference'] as num?)?.toDouble() ?? 0;
    final movementCount = item['movementCount'] as int? ?? 0;
    final accountName = item['accountName']?.toString() ?? 'Cuenta';
    final isOverstated = diff > 0; // stored > computed

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.neuomorphicShadow,
        border: Border.all(
          color: ElegantLightTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.warningGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '$movementCount movimientos',
                        style: TextStyle(
                          fontSize: 11,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.errorRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          ElegantLightTheme.errorRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${isOverstated ? "+" : ""}${AppFormatters.formatCurrency(diff)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ElegantLightTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _BalanceRow(
                    label: 'Saldo guardado',
                    value: stored,
                    color: isOverstated
                        ? ElegantLightTheme.errorRed
                        : ElegantLightTheme.warningOrange,
                  ),
                  const SizedBox(height: 6),
                  _BalanceRow(
                    label: 'Saldo correcto (movimientos)',
                    value: computed,
                    color: ElegantLightTheme.successGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Obx(() => FilledButton.icon(
                  onPressed:
                      isRecalculating.value ? null : onRecalculate,
                  icon: isRecalculating.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.calculate_rounded, size: 18),
                  label: Text(isRecalculating.value
                      ? 'Recalculando...'
                      : 'Recalcular saldo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: ElegantLightTheme.warningOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _BalanceRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ),
        Text(
          AppFormatters.formatCurrency(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AllGoodState extends StatelessWidget {
  const _AllGoodState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.successGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.successGreen
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Todo cuadra',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todas las cuentas tienen el saldo correcto.\n'
              'No hay desfases entre el balance guardado y los movimientos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: ElegantLightTheme.errorRed),
            const SizedBox(height: 16),
            Text(
              'No se pudo auditar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
