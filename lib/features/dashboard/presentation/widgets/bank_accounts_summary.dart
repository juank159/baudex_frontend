// lib/features/dashboard/presentation/widgets/bank_accounts_summary.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/network/network_info.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/data/local/enums/isar_enums.dart';
import '../../../../app/data/local/isar_database.dart';
import '../../../bank_accounts/data/models/isar/isar_bank_account.dart';
import '../../../invoices/data/models/isar/isar_invoice.dart';

class BankAccountSummary {
  final String id;
  final String name;
  final String? bankName;
  final String? accountNumber;
  final String type;
  final String? icon;
  final double currentBalance;
  // Histórico (toda la vida de la cuenta, sin filtro de fecha)
  final double totalReceived;
  final int paymentCount;
  final double creditPaymentTotal;
  final int creditPaymentCount;

  // Filtrados por período (cash basis: pagos cuya paymentDate ∈ rango).
  // Backend < 2026-04-20 no enviaba los Period de créditos → fallback a 0.
  final double totalReceivedPeriod;
  final int paymentCountPeriod;
  final double creditPaymentTotalPeriod;
  final int creditPaymentCountPeriod;

  final bool isDefault;
  final bool isActive;

  BankAccountSummary({
    required this.id,
    required this.name,
    this.bankName,
    this.accountNumber,
    required this.type,
    this.icon,
    required this.currentBalance,
    required this.totalReceived,
    required this.paymentCount,
    required this.creditPaymentTotal,
    required this.creditPaymentCount,
    required this.totalReceivedPeriod,
    required this.paymentCountPeriod,
    required this.creditPaymentTotalPeriod,
    required this.creditPaymentCountPeriod,
    required this.isDefault,
    required this.isActive,
  });

  factory BankAccountSummary.fromJson(Map<String, dynamic> json) {
    return BankAccountSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bankName: json['bankName']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      type: json['type']?.toString() ?? 'cash',
      icon: json['icon']?.toString(),
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      totalReceived: (json['totalReceived'] as num?)?.toDouble() ?? 0.0,
      paymentCount: (json['paymentCount'] as num?)?.toInt() ?? 0,
      creditPaymentTotal: (json['creditPaymentTotal'] as num?)?.toDouble() ?? 0.0,
      creditPaymentCount: (json['creditPaymentCount'] as num?)?.toInt() ?? 0,
      totalReceivedPeriod: (json['totalReceivedPeriod'] as num?)?.toDouble() ?? 0.0,
      paymentCountPeriod: (json['paymentCountPeriod'] as num?)?.toInt() ?? 0,
      creditPaymentTotalPeriod: (json['creditPaymentTotalPeriod'] as num?)?.toDouble() ?? 0.0,
      creditPaymentCountPeriod: (json['creditPaymentCountPeriod'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  double get grandTotal => totalReceived + creditPaymentTotal;
  int get totalPayments => paymentCount + creditPaymentCount;

  /// Totales filtrados por período (respetan el filtro de fecha del dashboard).
  /// Ahora los créditos también se filtran por paymentDate (antes se sumaba el
  /// histórico, causando el bug de "créditos = 500K" sin actividad del día).
  double get grandTotalPeriod => totalReceivedPeriod + creditPaymentTotalPeriod;
  int get totalPaymentsPeriod => paymentCountPeriod + creditPaymentCountPeriod;

  /// Obtiene el número de cuenta enmascarado (****1234)
  String get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.isEmpty) return '';
    if (accountNumber!.length <= 4) return accountNumber!;
    return '****${accountNumber!.substring(accountNumber!.length - 4)}';
  }
}

class BankAccountsSummaryWidget extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const BankAccountsSummaryWidget({
    super.key,
    this.startDate,
    this.endDate,
  });

  @override
  State<BankAccountsSummaryWidget> createState() => _BankAccountsSummaryWidgetState();
}

class _BankAccountsSummaryWidgetState extends State<BankAccountsSummaryWidget> {
  final DioClient _dioClient = Get.find<DioClient>();

  List<BankAccountSummary> _accounts = [];
  bool _isLoading = true;
  String? _error;
  int _loadVersion = 0; // Previene race condition al cambiar filtros rápido

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(BankAccountsSummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recargar datos si cambian los filtros de fecha
    if (oldWidget.startDate != widget.startDate || oldWidget.endDate != widget.endDate) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final thisVersion = ++_loadVersion;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // OFFLINE-FIRST: Cargar datos desde ISAR inmediatamente
    await _loadDataOffline(thisVersion);
    if (thisVersion != _loadVersion) return;

    // Luego refrescar desde servidor en background
    _refreshFromServer(thisVersion);
  }

  /// Refresca datos desde el servidor en background (no bloquea UI)
  void _refreshFromServer(int version) {
    () async {
      try {
        final networkInfo = Get.find<NetworkInfo>();
        if (!await networkInfo.isConnected) return;
        if (version != _loadVersion) return;

        final queryParams = <String, String>{};
        if (widget.startDate != null) {
          queryParams['startDate'] = widget.startDate!.toIso8601String().split('T')[0];
        }
        if (widget.endDate != null) {
          queryParams['endDate'] = widget.endDate!.toIso8601String().split('T')[0];
        }

        final uri = Uri(
          path: '/bank-accounts/summary',
          queryParameters: queryParams.isEmpty ? null : queryParams,
        );

        final response = await _dioClient.get(uri.toString());

        if (version != _loadVersion) return;

        dynamic accountsData;
        if (response.data is Map && response.data['data'] != null) {
          accountsData = response.data['data'];
        } else if (response.data is List) {
          accountsData = response.data;
        }

        if (accountsData is List && mounted) {
          final list = accountsData as List;
          setState(() {
            _accounts = list
                .map<BankAccountSummary>((item) => BankAccountSummary.fromJson(item as Map<String, dynamic>))
                .toList();
          });
          debugPrint('🌐 Bank accounts actualizado desde servidor: ${_accounts.length} cuentas');
        }
      } catch (e) {
        debugPrint('⚠️ Error refreshing bank accounts from server: $e');
      }
    }();
  }

  /// Carga cuentas bancarias desde ISAR y calcula totales desde pagos de facturas
  Future<void> _loadDataOffline(int version) async {
    try {
      final isar = IsarDatabase.instance.database;

      // 1. Cargar cuentas bancarias activas desde ISAR
      final isarAccounts = await isar.isarBankAccounts
          .filter()
          .deletedAtIsNull()
          .isActiveEqualTo(true)
          .findAll();

      if (version != _loadVersion) return; // Descartado: filtro cambió

      if (isarAccounts.isEmpty) {
        _accounts = [];
        debugPrint('📴 Bank accounts offline: sin cuentas en ISAR');
        if (version == _loadVersion && mounted) setState(() => _isLoading = false);
        return;
      }

      // Capturar fechas del widget al momento de la carga (consistencia)
      final startDate = widget.startDate;
      final endDate = widget.endDate;

      // 2. Cargar facturas filtradas por invoice.date (consistente con backend)
      // IMPORTANTE: Filtrar por fecha de factura, NO por paymentDate,
      // para que los totales coincidan con el dashboard (totalRevenue)
      final allInvoices = await (() async {
        if (startDate != null && endDate != null) {
          final startDay = DateTime(startDate.year, startDate.month, startDate.day);
          final endDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
          return isar.isarInvoices
              .filter()
              .deletedAtIsNull()
              .dateBetween(startDay, endDay)
              .findAll();
        } else {
          return isar.isarInvoices
              .filter()
              .deletedAtIsNull()
              .findAll();
        }
      })();

      if (version != _loadVersion) return; // Descartado: filtro cambió

      // 3. Extraer todos los pagos de las facturas (ya filtradas por fecha)
      final allPayments = <Map<String, dynamic>>[];
      for (var invoice in allInvoices) {
        if (invoice.paymentsJson != null && invoice.paymentsJson!.isNotEmpty && invoice.paymentsJson != '[]') {
          try {
            final decoded = jsonDecode(invoice.paymentsJson!);
            if (decoded is List) {
              for (var payment in decoded) {
                if (payment is Map<String, dynamic>) {
                  allPayments.add(payment);
                }
              }
            }
          } catch (_) {}
        }
      }

      // 4. Agrupar pagos por bankAccountId
      final paymentsByAccount = <String, List<Map<String, dynamic>>>{};
      for (var payment in allPayments) {
        final accountId = payment['bankAccountId']?.toString();
        if (accountId != null && accountId.isNotEmpty) {
          paymentsByAccount.putIfAbsent(accountId, () => []);
          paymentsByAccount[accountId]!.add(payment);
        }
      }

      if (version != _loadVersion) return; // Descartado: filtro cambió

      // 5. Construir BankAccountSummary para cada cuenta
      final accounts = isarAccounts.map((account) {
        // Pagos ya están filtrados por fecha de factura (paso 2)
        final filteredPayments = paymentsByAccount[account.serverId] ?? [];

        // Separar pagos normales de creditos
        final normalPayments = filteredPayments.where((p) =>
            p['paymentMethod']?.toString() != 'credit').toList();
        final creditPayments = filteredPayments.where((p) =>
            p['paymentMethod']?.toString() == 'credit').toList();

        final totalReceived = normalPayments.fold(0.0,
            (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));
        final creditPaymentTotal = creditPayments.fold(0.0,
            (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

        // Para totalReceivedPeriod, usamos los mismos filtrados (ya están filtrados por fecha)
        final totalReceivedPeriod = totalReceived;

        return BankAccountSummary(
          id: account.serverId,
          name: account.name,
          bankName: account.bankName,
          accountNumber: account.accountNumber,
          type: _mapIsarBankAccountType(account.type),
          icon: account.icon,
          currentBalance: totalReceived + creditPaymentTotal,
          totalReceived: totalReceived,
          paymentCount: normalPayments.length,
          creditPaymentTotal: creditPaymentTotal,
          creditPaymentCount: creditPayments.length,
          // En offline los "normalPayments"/"creditPayments" ya fueron filtrados
          // por fecha previamente, por lo tanto Period == total para offline.
          totalReceivedPeriod: totalReceivedPeriod,
          paymentCountPeriod: normalPayments.length,
          creditPaymentTotalPeriod: creditPaymentTotal,
          creditPaymentCountPeriod: creditPayments.length,
          isDefault: account.isDefault,
          isActive: account.isActive,
        );
      }).toList();

      if (version != _loadVersion) return; // Descartado: filtro cambió

      // Ordenar: default primero, luego por nombre
      accounts.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });

      _accounts = accounts;
      debugPrint('📴 Bank accounts offline: ${_accounts.length} cuentas desde ISAR');
    } catch (e) {
      if (version != _loadVersion) return;
      debugPrint('❌ Error loading bank accounts offline: $e');
      _error = 'Error al cargar cuentas offline';
    } finally {
      if (version == _loadVersion && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapIsarBankAccountType(IsarBankAccountType type) {
    switch (type) {
      case IsarBankAccountType.cash:
        return 'cash';
      case IsarBankAccountType.savings:
        return 'savings';
      case IsarBankAccountType.checking:
        return 'checking';
      case IsarBankAccountType.digitalWallet:
        return 'digital_wallet';
      case IsarBankAccountType.creditCard:
        return 'credit_card';
      case IsarBankAccountType.debitCard:
        return 'debit_card';
      case IsarBankAccountType.other:
        return 'other';
      default:
        return type.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          ...ElegantLightTheme.elevatedShadow,
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _buildErrorState()
          else if (_accounts.isEmpty)
            _buildEmptyState()
          else
            _buildAccountsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalBalance = _accounts.fold<double>(0, (sum, acc) => sum + acc.totalReceivedPeriod);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ElegantLightTheme.glowShadow,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuentas Bancarias',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: ElegantLightTheme.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recibido: ${AppFormatters.formatCurrency(totalBalance.toInt())}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ElegantLightTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadData,
            icon: Icon(
              Icons.refresh,
              color: ElegantLightTheme.primaryBlue,
            ),
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: _accounts.map((account) => _buildAccountCard(account)).toList(),
      ),
    );
  }

  Widget _buildAccountCard(BankAccountSummary account) {
    final color = _getAccountColor(account.type);
    final icon = _getAccountIcon(account.type, account.icon);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),  // Reducido de 12
      padding: const EdgeInsets.all(12),  // Reducido de 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),  // Reducido de 16
        border: Border.all(
          color: account.isDefault
              ? color.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: account.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,  // Reducido de 8
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la cuenta
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),  // Reducido de 10
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),  // Reducido de 12
                ),
                child: Icon(icon, color: color, size: 20),  // Reducido de 24
              ),
              const SizedBox(width: 10),  // Reducido de 12
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Principal',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (account.maskedAccountNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.maskedAccountNumber,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                          fontSize: 11,  // Reducido
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Recibido en el período
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Recibido',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,  // Reducido de 10
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(account.totalReceivedPeriod.toInt()),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontSize: 16,  // Reducido de 18
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),  // Reducido de 12
          // Estadísticas
          Container(
            padding: const EdgeInsets.all(10),  // Reducido de 12
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),  // Reducido de 12
            ),
            child: Row(
              children: [
                _buildStatItem(
                  'Facturas',
                  AppFormatters.formatCurrency(account.totalReceivedPeriod.toInt()),
                  '${account.paymentCountPeriod} pagos',
                  Colors.green,
                ),
                Container(
                  width: 1,
                  height: 32,  // Reducido de 40
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 10),  // Reducido de 12
                ),
                _buildStatItem(
                  'Créditos',
                  AppFormatters.formatCurrency(account.creditPaymentTotal.toInt()),
                  '${account.creditPaymentCount} pagos',
                  Colors.blue,
                ),
                Container(
                  width: 1,
                  height: 32,  // Reducido de 40
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 10),  // Reducido de 12
                ),
                _buildStatItem(
                  'Total',
                  AppFormatters.formatCurrency(account.grandTotalPeriod.toInt()),
                  '${account.totalPaymentsPeriod} pagos',
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subtitle, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,  // Reducido de 10
            ),
          ),
          const SizedBox(height: 1),  // Reducido de 2
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 12,  // Reducido de 13
            ),
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 8,  // Reducido de 9
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin cuentas bancarias',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tus cuentas bancarias para ver el resumen aquí',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Color _getAccountColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green.shade600;
      case 'savings':
        return Colors.blue.shade600;
      case 'checking':
        return Colors.indigo.shade600;
      case 'digital_wallet':
        return Colors.purple.shade600;
      case 'credit_card':
        return Colors.orange.shade600;
      case 'debit_card':
        return Colors.teal.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getAccountIcon(String type, String? customIcon) {
    if (customIcon != null) {
      switch (customIcon) {
        case 'money':
          return Icons.money;
        case 'credit_card':
          return Icons.credit_card;
        case 'phone_android':
          return Icons.phone_android;
        case 'account_balance':
          return Icons.account_balance;
        case 'savings':
          return Icons.savings;
        case 'wallet':
          return Icons.wallet;
      }
    }

    switch (type) {
      case 'cash':
        return Icons.money;
      case 'savings':
        return Icons.savings;
      case 'checking':
        return Icons.account_balance;
      case 'digital_wallet':
        return Icons.phone_android;
      case 'credit_card':
        return Icons.credit_card;
      case 'debit_card':
        return Icons.payment;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
