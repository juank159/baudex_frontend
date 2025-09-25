// lib/features/expenses/presentation/screens/enhanced_expenses_list_screen.dart
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

class EnhancedExpensesListScreen extends GetView<EnhancedExpensesController> {
  const EnhancedExpensesListScreen({super.key});

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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                );
              }),
            ],
          ),
        ],
      ),
      elevation: 0,
      actions: [
        // Indicador de período actual
        Obx(() => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(
              _getCurrentPeriodText(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            side: BorderSide(color: Theme.of(context).primaryColor),
          ),
        )),
        
        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: controller.refreshExpenses,
          tooltip: 'Actualizar',
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder: (context) => [
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
        Expanded(
          child: _buildExpensesList(context),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Panel lateral
        Container(
          width: 320,
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
              // Estadísticas
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Obx(() {
                    final stats = controller.stats;
                    if (stats == null) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return EnhancedExpenseStatsWidget(stats: stats);
                  }),
                ),
              ),
              
              const Divider(),
              
              // Filtros y búsqueda
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchBar(context),
                      const SizedBox(height: 16),
                      _buildQuickFilters(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista principal
        Expanded(
          child: _buildExpensesList(context),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Panel lateral izquierdo - Estadísticas
        Container(
          width: 380,
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
              // Header del panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dashboard de Gastos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Estadísticas
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Obx(() {
                    final stats = controller.stats;
                    if (stats == null) {
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return EnhancedExpenseStatsWidget(stats: stats);
                  }),
                ),
              ),
            ],
          ),
        ),
        
        // Contenido principal
        Expanded(
          child: Column(
            children: [
              // Barra de herramientas
              _buildDesktopToolbar(context),
              
              // Lista de gastos
              Expanded(
                child: _buildExpensesList(context),
              ),
            ],
          ),
        ),
      ],
    );
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
                        child: Obx(() => Text(
                          controller.currentPeriod,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        )),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'today', child: Text('Hoy')),
                  const PopupMenuItem(value: 'week', child: Text('Esta Semana')),
                  const PopupMenuItem(value: 'month', child: Text('Este Mes')),
                  const PopupMenuItem(value: 'all', child: Text('Todos')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Búsqueda avanzada
          Expanded(
            flex: 2,
            child: _buildSearchBar(context),
          ),
          
          const SizedBox(width: 16),
          
          // Filtros rápidos
          Expanded(
            flex: 3,
            child: _buildQuickFilters(context),
          ),
          
          const SizedBox(width: 16),
          
          // Contador de resultados
          Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${controller.totalItems} gastos',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Obx(() => CustomTextField(
      controller: controller.searchController,
      label: 'Buscar gastos',
      hint: 'Descripción, categoría, monto...',
      prefixIcon: Icons.search,
      onChanged: controller.updateSearch,
      suffixIcon: controller.searchTerm.isNotEmpty ? Icons.clear : null,
      onSuffixIconPressed: controller.searchTerm.isNotEmpty 
        ? () {
            controller.searchController.clear();
            controller.updateSearch('');
          }
        : null,
    ));
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Filtro por período
        Obx(() => _buildFilterChip(
          'Período: ${controller.currentPeriod}',
          true,
          () => _showPeriodSelector(context),
          color: Theme.of(context).primaryColor,
        )),
        
        // Filtro por estado
        Obx(() => _buildFilterChip(
          'Estado: ${controller.currentStatus?.displayName ?? "Todos"}',
          controller.currentStatus != null,
          () => _showStatusSelector(context),
          color: Colors.blue,
        )),
        
        // Filtro por tipo
        Obx(() => _buildFilterChip(
          'Tipo: ${controller.currentType?.displayName ?? "Todos"}',
          controller.currentType != null,
          () => _showTypeSelector(context),
          color: Colors.green,
        )),
        
        // Limpiar filtros
        Obx(() {
          final hasFilters = controller.hasActiveFilters;
          if (!hasFilters) return const SizedBox.shrink();
          
          return _buildFilterChip(
            'Limpiar',
            false,
            controller.clearFilters,
            color: Colors.red,
            icon: Icons.clear,
          );
        }),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isActive,
    VoidCallback onTap, {
    Color? color,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
            ? (color ?? Theme.of(Get.context!).primaryColor).withOpacity(0.1)
            : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
              ? (color ?? Theme.of(Get.context!).primaryColor)
              : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isActive 
                  ? (color ?? Theme.of(Get.context!).primaryColor)
                  : Colors.grey[600],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive 
                  ? (color ?? Theme.of(Get.context!).primaryColor)
                  : Colors.grey[600],
              ),
            ),
          ],
        ),
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
          itemCount: controller.expenses.length + (controller.isLoadingMore ? 1 : 0),
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
              compact: ResponsiveHelper.isMobile(context),
              onTap: () => controller.showExpenseDetails(expense.id),
              onEdit: () => controller.goToEditExpense(expense.id),
              onDelete: () => controller.confirmDelete(expense),
              onApprove: expense.canBeApproved
                  ? () => controller.confirmApprove(expense)
                  : null,
              onSubmit: expense.canBeSubmitted
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay gastos registrados',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza registrando tu primer gasto para llevar el control de tus finanzas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                text: 'Agregar Gasto',
                onPressed: controller.goToCreateExpense,
                icon: Icons.add,
              ),
              const SizedBox(width: 16),
              CustomButton(
                text: 'Ver Tutorial',
                onPressed: () {
                  // Mostrar tutorial
                },
                type: ButtonType.outline,
                icon: Icons.help_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (!ResponsiveHelper.isMobile(context)) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: controller.goToCreateExpense,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo Gasto'),
      tooltip: 'Registrar nuevo gasto',
    );
  }

  // Métodos auxiliares
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

  void _showPeriodSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.today),
            title: const Text('Hoy'),
            onTap: () {
              controller.setPeriodFilter('today');
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Esta Semana'),
            onTap: () {
              controller.setPeriodFilter('week');
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Este Mes'),
            onTap: () {
              controller.setPeriodFilter('month');
              Get.back();
            },
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('Todos los Períodos'),
            onTap: () {
              controller.setPeriodFilter('all');
              Get.back();
            },
          ),
        ],
      ),
    );
  }

  void _showStatusSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Todos los Estados'),
            onTap: () {
              controller.applyStatusFilter(null);
              Get.back();
            },
          ),
          ...ExpenseStatus.values.map((status) => ListTile(
            title: Text(status.displayName),
            onTap: () {
              controller.applyStatusFilter(status);
              Get.back();
            },
          )),
        ],
      ),
    );
  }

  void _showTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Todos los Tipos'),
            onTap: () {
              controller.applyTypeFilter(null);
              Get.back();
            },
          ),
          ...ExpenseType.values.map((type) => ListTile(
            title: Text(type.displayName),
            onTap: () {
              controller.applyTypeFilter(type);
              Get.back();
            },
          )),
        ],
      ),
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
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
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
}