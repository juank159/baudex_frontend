// lib/features/expenses/presentation/screens/expenses_list_screen.dart
import '../controllers/enhanced_expenses_controller.dart';
import '../widgets/expense_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_drawer.dart';
import '../controllers/enhanced_expenses_controller.dart';
import '../widgets/expense_card_widget.dart';
import '../widgets/enhanced_expense_stats_widget.dart';
import '../../domain/entities/expense.dart';

class ExpensesListScreen extends GetView<EnhancedExpensesController> {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: const AppDrawer(currentRoute: '/expenses'),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.receipt_long, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gastos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Obx(() {
                final stats = controller.stats;
                if (stats == null) return const SizedBox.shrink();
                return Text(
                  '${stats.totalExpenses} registros • ${stats.formattedTotalAmount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                );
              }),
            ],
          ),
        ],
      ),
      elevation: 0,
      actions: [
        // Indicador de período actual
        Obx(
          () => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                _getCurrentPeriodText(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshExpenses,
          tooltip: 'Actualizar',
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'filters',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list),
                      SizedBox(width: 8),
                      Text('Filtros'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Exportar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'analytics',
                  child: Row(
                    children: [
                      Icon(Icons.analytics),
                      SizedBox(width: 8),
                      Text('Análisis'),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Estadísticas principales en móvil
        Container(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final stats = controller.stats;
            if (stats == null) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return EnhancedExpenseStatsWidget(stats: stats, compact: true);
          }),
        ),

        // Filtros rápidos para móvil
        _buildMobileQuickFilters(context),

        // Lista de gastos
        Expanded(child: _buildExpensesList(context)),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Panel lateral con estadísticas y filtros
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildStatsSection(context),
              const Divider(),
              _buildQuickFilters(context),
              const Divider(),
              _buildSearchBar(context),
            ],
          ),
        ),

        // Lista principal
        Expanded(child: _buildExpensesList(context)),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Panel lateral izquierdo
        Container(
          width: 350,
          height: double.infinity, // Ocupar toda la altura disponible
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: 0,
            ), // Sin padding vertical extra
            child: Column(
              children: [
                _buildStatsSection(context),
                const Divider(),
                _buildQuickFilters(context),
                const Divider(),
                _buildAdvancedFilters(context),
              ],
            ),
          ),
        ),

        // Contenido principal
        Expanded(
          child: Column(
            children: [
              // Barra de herramientas
              _buildToolbar(context),

              // Lista de gastos
              Expanded(child: _buildExpensesList(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, {bool compact = false}) {
    return Container(
      margin:
          compact
              ? const EdgeInsets.all(16)
              : const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16,
              ), // Menos margen superior en desktop
      child: Obx(() {
        final stats = controller.stats;
        if (stats == null) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (compact) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  stats.formattedTotalAmount,
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Este Mes',
                  stats.formattedMonthlyAmount,
                  Icons.calendar_month,
                  Colors.green,
                ),
              ),
            ],
          );
        }

        return EnhancedExpenseStatsWidget(stats: stats);
      }),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(
        () => CustomTextField(
          controller: controller.searchController,
          label: 'Buscar',
          hint: 'Buscar gastos...',
          prefixIcon: Icons.search,
          onChanged: controller.updateSearch,
          suffixIcon: controller.searchTerm.isNotEmpty ? Icons.clear : null,
          onSuffixIconPressed:
              controller.searchTerm.isNotEmpty
                  ? () {
                    controller.searchController.clear();
                    controller.updateSearch('');
                  }
                  : null,
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros Rápidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Filtro por estado
          _buildStatusFilterChips(),

          const SizedBox(height: 12),

          // Filtro por tipo
          _buildTypeFilterChips(),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8, // Añadido espaciado vertical entre filas
            children: [
              // Opción "Todos"
              _buildUniformFilterChip(
                'Todos',
                controller.currentStatus == null,
                () => controller.applyStatusFilter(null),
              ),

              // Opciones específicas
              ...ExpenseStatus.values.map(
                (status) => _buildUniformFilterChip(
                  status.displayName,
                  controller.currentStatus == status,
                  () => controller.applyStatusFilter(status),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8, // Añadido espaciado vertical entre filas
            children: [
              // Opción "Todos"
              _buildUniformFilterChip(
                'Todos',
                controller.currentType == null,
                () => controller.applyTypeFilter(null),
              ),

              // Opciones específicas
              ...ExpenseType.values.map(
                (type) => _buildUniformFilterChip(
                  type.displayName,
                  controller.currentType == type,
                  () => controller.applyTypeFilter(type),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros Avanzados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Filtro por fecha
          _buildDateFilter(context),

          const SizedBox(height: 16),

          // Botón limpiar filtros
          Obx(() {
            final hasFilters =
                controller.currentStatus != null ||
                controller.currentType != null ||
                controller.selectedCategoryId != null ||
                controller.startDate != null ||
                controller.endDate != null ||
                controller.searchTerm.isNotEmpty;

            return hasFilters
                ? SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Limpiar Filtros',
                    onPressed: controller.clearFilters,
                    type: ButtonType.outline,
                  ),
                )
                : const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rango de Fechas',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => OutlinedButton.icon(
                  onPressed: () => _selectStartDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    controller.startDate != null
                        ? _formatDate(controller.startDate!)
                        : 'Desde',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Obx(
                () => OutlinedButton.icon(
                  onPressed: () => _selectEndDate(context),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    controller.endDate != null
                        ? _formatDate(controller.endDate!)
                        : 'Hasta',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUniformFilterChip(
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 90, // Ancho fijo para todos los chips
      child: FilterChip(
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Contador de resultados
          Obx(
            () => Text(
              '${controller.totalItems} gastos encontrados',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

          const Spacer(),

          // Ordenamiento
          _buildSortDropdown(context),

          const SizedBox(width: 16),

          // Vista
          _buildViewToggle(context),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, size: 16),
            const SizedBox(width: 8),
            Obx(
              () => Text(
                _getSortDisplayName(controller.sortBy, controller.sortOrder),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'createdAt:DESC',
              child: Text('Más recientes'),
            ),
            const PopupMenuItem(
              value: 'createdAt:ASC',
              child: Text('Más antiguos'),
            ),
            const PopupMenuItem(
              value: 'amount:DESC',
              child: Text('Mayor monto'),
            ),
            const PopupMenuItem(
              value: 'amount:ASC',
              child: Text('Menor monto'),
            ),
            const PopupMenuItem(
              value: 'description:ASC',
              child: Text('A-Z Descripción'),
            ),
            const PopupMenuItem(
              value: 'description:DESC',
              child: Text('Z-A Descripción'),
            ),
          ],
      onSelected: (value) {
        final parts = value.split(':');
        controller.changeSorting(parts[0], parts[1]);
      },
    );
  }

  Widget _buildViewToggle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              // Cambiar a vista de lista
            },
            tooltip: 'Vista Lista',
          ),
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: () {
              // Cambiar a vista de tarjetas
            },
            tooltip: 'Vista Tarjetas',
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: LoadingWidget());
      }

      if (!controller.hasExpenses) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshExpenses,
        child: ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount:
              controller.expenses.length + (controller.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= controller.expenses.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final expense = controller.expenses[index];
            return ExpenseCardWidget(
              expense: expense,
              compact: true, // Activar modo compacto por defecto
              onTap: () => controller.showExpenseDetails(expense.id),
              onEdit: () => controller.goToEditExpense(expense.id),
              onDelete: () => controller.confirmDelete(expense),
              onApprove:
                  expense.canBeApproved
                      ? () => controller.confirmApprove(expense)
                      : null,
              onSubmit:
                  expense.canBeSubmitted
                      ? () => controller.submitExpense(expense.id)
                      : null,
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay gastos registrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza agregando tu primer gasto',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Agregar Gasto',
            onPressed: controller.goToCreateExpense,
            icon: Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: controller.goToCreateExpense,
      tooltip: 'Nuevo Gasto', // Tooltip que aparece en hover en desktop
      child: const Icon(Icons.add),
    );
  }

  // Métodos auxiliares
  void _showMobileSearch(BuildContext context) {
    // Implementar búsqueda móvil
    Get.snackbar(
      'Próximamente',
      'La búsqueda avanzada estará disponible pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showFilters(BuildContext context) {
    // Implementar filtros avanzados
    Get.snackbar(
      'Próximamente',
      'Los filtros avanzados estarán disponibles pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'filters':
        _showAdvancedFilters(context);
        break;
      case 'export':
        _showExportOptions(context);
        break;
      case 'analytics':
        controller.goToExpenseAnalytics();
        break;
    }
  }

  void _showAdvancedFilters(BuildContext context) {
    // Implementar filtros avanzados
    Get.snackbar(
      'Próximamente',
      'Los filtros avanzados estarán disponibles pronto',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Exportar a PDF'),
                subtitle: const Text('Reporte detallado en PDF'),
                onTap: () {
                  Get.back();
                  controller.exportToPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Exportar a Excel'),
                subtitle: const Text('Hoja de cálculo con todos los datos'),
                onTap: () {
                  Get.back();
                  controller.exportToExcel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartir Resumen'),
                subtitle: const Text('Enviar resumen por email o mensaje'),
                onTap: () {
                  Get.back();
                  controller.shareExpensesSummary();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      controller.applyDateFilter(date, controller.endDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.endDate ?? DateTime.now(),
      firstDate: controller.startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      controller.applyDateFilter(controller.startDate, date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMobileQuickFilters(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Búsqueda
          Expanded(
            flex: 3,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: controller.searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar gastos...',
                  hintStyle: TextStyle(fontSize: 14),
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: controller.updateSearch,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filtro por período
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).primaryColor),
              ),
              child: PopupMenuButton<String>(
                onSelected: controller.setPeriodFilter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.date_range,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Obx(
                          () => Text(
                            controller.currentPeriod,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(value: 'today', child: Text('Hoy')),
                      const PopupMenuItem(
                        value: 'week',
                        child: Text('Esta Semana'),
                      ),
                      const PopupMenuItem(
                        value: 'month',
                        child: Text('Este Mes'),
                      ),
                      const PopupMenuItem(value: 'all', child: Text('Todos')),
                    ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPeriodText() {
    final period = controller.currentPeriod;
    switch (period) {
      case 'today':
        return 'Hoy';
      case 'week':
        return 'Semana';
      case 'month':
        return 'Mes';
      default:
        return 'Todos';
    }
  }

  String _getSortDisplayName(String sortBy, String sortOrder) {
    switch ('$sortBy:$sortOrder') {
      case 'createdAt:DESC':
        return 'Más recientes';
      case 'createdAt:ASC':
        return 'Más antiguos';
      case 'amount:DESC':
        return 'Mayor monto';
      case 'amount:ASC':
        return 'Menor monto';
      case 'description:ASC':
        return 'A-Z';
      case 'description:DESC':
        return 'Z-A';
      default:
        return 'Fecha';
    }
  }
}
