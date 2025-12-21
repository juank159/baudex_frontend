// lib/features/bank_accounts/presentation/screens/bank_account_movements_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../domain/entities/bank_account_transaction.dart';
import '../controllers/bank_account_movements_controller.dart';
import '../widgets/movement_card.dart';

/// Pantalla de movimientos/transacciones de una cuenta bancaria
class BankAccountMovementsScreen extends GetView<BankAccountMovementsController> {
  const BankAccountMovementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el ID de la cuenta de los argumentos
    final String accountId = Get.arguments as String;

    // Inicializar el controller con el ID de la cuenta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.init(accountId);
    });

    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading.value && controller.transactions.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        if (controller.hasError.value) {
          return _buildErrorView();
        }

        return _buildBody(context);
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(() => Text(
            controller.account.value?.name ?? 'Movimientos',
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          )),
      backgroundColor: ElegantLightTheme.surfaceColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.1),
      iconTheme: const IconThemeData(color: ElegantLightTheme.textPrimary),
      actions: [
        // Búsqueda
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: ElegantLightTheme.primaryBlue,
            ),
            tooltip: 'Buscar',
            onPressed: () => _showSearchDialog(context),
          ),
        ),
        const SizedBox(width: 8),

        // Filtros de fecha
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(
              Icons.date_range_rounded,
              color: ElegantLightTheme.primaryBlue,
            ),
            tooltip: 'Filtrar por fecha',
            onSelected: (value) => controller.setPresetFilter(value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: ElegantLightTheme.surfaceColor,
            itemBuilder: (context) => [
              _buildMenuItem('Hoy', 'today', Icons.today_rounded),
              _buildMenuItem('Esta semana', 'week', Icons.view_week_rounded),
              _buildMenuItem('Este mes', 'month', Icons.calendar_month_rounded),
              _buildMenuItem('Este año', 'year', Icons.calendar_today_rounded),
              _buildMenuItem('Todas', 'all', Icons.all_inclusive),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Refrescar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: ElegantLightTheme.primaryBlue,
            ),
            tooltip: 'Refrescar',
            onPressed: () => controller.refresh(),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String text, String value, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: ElegantLightTheme.primaryBlue,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      color: ElegantLightTheme.primaryBlue,
      child: CustomScrollView(
        slivers: [
          // Información de la cuenta
          SliverToBoxAdapter(
            child: _buildAccountInfo(),
          ),

          // Resumen de transacciones
          SliverToBoxAdapter(
            child: _buildSummary(),
          ),

          // Filtros activos
          Obx(() {
            if (controller.hasActiveFilters) {
              return SliverToBoxAdapter(
                child: _buildActiveFilters(),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }),

          // Lista de transacciones
          Obx(() {
            if (!controller.hasTransactions) {
              return SliverFillRemaining(
                child: _buildEmptyState(),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.isMobile(context) ? 16 : 24,
                vertical: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < controller.transactions.length) {
                      return MovementCard(
                        transaction: controller.transactions[index],
                      );
                    } else if (controller.hasMorePages) {
                      // Trigger load more
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        controller.loadMore();
                      });
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: LoadingWidget()),
                      );
                    }
                    return null;
                  },
                  childCount: controller.transactions.length +
                      (controller.hasMorePages ? 1 : 0),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Obx(() {
      final accountInfo = controller.accountInfo.value;
      if (accountInfo == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ElegantLightTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: ElegantLightTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountInfo.name,
                        style: const TextStyle(
                          color: ElegantLightTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (accountInfo.accountNumber != null)
                        Text(
                          '****${accountInfo.accountNumber!.substring(accountInfo.accountNumber!.length - 4)}',
                          style: const TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saldo actual:',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(accountInfo.currentBalance),
                  style: const TextStyle(
                    color: ElegantLightTheme.primaryBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummary() {
    return Obx(() {
      final summary = controller.summary.value;
      if (summary == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ElegantLightTheme.successGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.successGreen.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Total ingresos',
              summary.totalIncome,
              Icons.arrow_downward_rounded,
              ElegantLightTheme.successGreen,
            ),
            Container(
              width: 1,
              height: 40,
              color: ElegantLightTheme.textSecondary.withOpacity(0.2),
            ),
            _buildSummaryItem(
              'Transacciones',
              summary.transactionCount.toDouble(),
              Icons.receipt_long_rounded,
              ElegantLightTheme.primaryBlue,
              isCount: true,
            ),
            Container(
              width: 1,
              height: 40,
              color: ElegantLightTheme.textSecondary.withOpacity(0.2),
            ),
            _buildSummaryItem(
              'Promedio',
              summary.averageTransaction,
              Icons.trending_up_rounded,
              ElegantLightTheme.warningOrange,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    IconData icon,
    Color color, {
    bool isCount = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          isCount
              ? value.toInt().toString()
              : NumberFormat.currency(
                  symbol: '\$',
                  decimalDigits: 0,
                ).format(value),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ElegantLightTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_alt_rounded,
            color: ElegantLightTheme.primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Obx(() {
              final filters = <String>[];
              if (controller.startDate.value != null) {
                filters.add(
                    'Desde ${DateFormat('dd/MM/yyyy').format(controller.startDate.value!)}');
              }
              if (controller.endDate.value != null) {
                filters.add(
                    'Hasta ${DateFormat('dd/MM/yyyy').format(controller.endDate.value!)}');
              }
              if (controller.searchQuery.value.isNotEmpty) {
                filters.add('Búsqueda: "${controller.searchQuery.value}"');
              }
              return Text(
                filters.join(' • '),
                style: const TextStyle(
                  color: ElegantLightTheme.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }),
          ),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              color: ElegantLightTheme.primaryBlue,
              size: 18,
            ),
            onPressed: () => controller.clearFilters(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: ElegantLightTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay movimientos',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No se encontraron transacciones en este período',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
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
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: ElegantLightTheme.errorRed.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar movimientos',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Obx(() => Text(
                  controller.errorMessage.value,
                  style: const TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController(
      text: controller.searchQuery.value,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Buscar transacciones',
          style: TextStyle(
            color: ElegantLightTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Cliente, factura...',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: ElegantLightTheme.primaryBlue,
            ),
          ),
          autofocus: true,
          onSubmitted: (value) {
            controller.searchTransactions(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.searchTransactions(searchController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ElegantLightTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}
