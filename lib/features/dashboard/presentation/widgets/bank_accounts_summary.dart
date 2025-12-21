// lib/features/dashboard/presentation/widgets/bank_accounts_summary.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/utils/formatters.dart';

class BankAccountSummary {
  final String id;
  final String name;
  final String? bankName;
  final String? accountNumber;
  final String type;
  final String? icon;
  final double currentBalance;
  final double totalReceived;
  final double totalReceivedPeriod;
  final int paymentCount;
  final int paymentCountPeriod;
  final int creditPaymentCount;
  final double creditPaymentTotal;
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
    required this.totalReceivedPeriod,
    required this.paymentCount,
    required this.paymentCountPeriod,
    required this.creditPaymentCount,
    required this.creditPaymentTotal,
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
      totalReceivedPeriod: (json['totalReceivedPeriod'] as num?)?.toDouble() ?? 0.0,
      paymentCount: (json['paymentCount'] as num?)?.toInt() ?? 0,
      paymentCountPeriod: (json['paymentCountPeriod'] as num?)?.toInt() ?? 0,
      creditPaymentCount: (json['creditPaymentCount'] as num?)?.toInt() ?? 0,
      creditPaymentTotal: (json['creditPaymentTotal'] as num?)?.toDouble() ?? 0.0,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  double get grandTotal => totalReceived + creditPaymentTotal;
  int get totalPayments => paymentCount + creditPaymentCount;

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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Construir query parameters con filtros de fecha
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

      // El backend envía {success: true, data: [...]}
      dynamic accountsData;

      if (response.data is Map && response.data['data'] != null) {
        // Formato: {success: true, data: [...]}
        accountsData = response.data['data'];
      } else if (response.data is List) {
        // Formato directo: [...]
        accountsData = response.data;
      }

      if (accountsData is List) {
        _accounts = accountsData
            .map((item) => BankAccountSummary.fromJson(item as Map<String, dynamic>))
            .toList();
        debugPrint('✅ Bank accounts loaded: ${_accounts.length} cuentas');
      }
    } catch (e) {
      _error = 'Error al cargar cuentas: ${e.toString()}';
      debugPrint('Error loading bank accounts summary: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    final totalBalance = _accounts.fold<double>(0, (sum, acc) => sum + acc.currentBalance);

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
                  'Saldo total: ${AppFormatters.formatCurrency(totalBalance.toInt())}',
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
              // Saldo actual
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Saldo',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 9,  // Reducido de 10
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(account.currentBalance.toInt()),
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
                  AppFormatters.formatCurrency(account.totalReceived.toInt()),
                  '${account.paymentCount} pagos',
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
                  AppFormatters.formatCurrency(account.grandTotal.toInt()),
                  '${account.totalPayments} pagos',
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
