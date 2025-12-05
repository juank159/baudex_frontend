// lib/features/expenses/presentation/screens/expenses_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/app_scaffold.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../controllers/enhanced_expenses_controller.dart';
import '../widgets/modern_expense_card_widget.dart';
import '../widgets/modern_expense_stats_widget.dart';
import '../widgets/modern_expense_filter_widget.dart';
import '../../domain/entities/expense.dart';

class ExpensesListScreen extends GetView<EnhancedExpensesController> {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.expenses,
      appBar: _buildModernAppBar(context),
      body:
          ResponsiveHelper.isMobile(context)
              ? _buildMobileLayout(context)
              : _buildDesktopLayout(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return AppBar(
      title: Text(
        'Gestión de Gastos',
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      actions: [
        // Chip de filtro de fecha activo - MEJORADO
        Obx(() {
          final hasFilter =
              controller.startDate != null || controller.endDate != null;
          if (!hasFilter && controller.currentPeriod == 'all') {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDateRangePickerDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getCurrentPeriodText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => controller.clearDateFilters(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.grey.shade600,
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
        }),

        // Menú de opciones - MEJORADO
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
          ),
          onSelected: (value) => _handleMenuAction(value, context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 50),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'date_filter',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filtrar por Fecha',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'filters',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Más Filtros',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          size: 20,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Actualizar',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
        ),

        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando gastos...');
      }

      return Column(
        children: [
          // Estadísticas ultra compactas
          _buildCompactStats(context),

          // Búsqueda compacta
          _buildMobileSearch(context),

          // Lista de gastos
          Expanded(child: _buildExpensesList(context)),
        ],
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget(message: 'Cargando gastos...');
      }

      return Row(
        children: [
          // Panel lateral - SOLO EN DESKTOP
          if (isDesktop)
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: _buildSidebarContent(context),
            ),

          // Área principal
          Expanded(
            child: Column(
              children: [
                // Toolbar superior adaptable (solo desktop)
                if (isDesktop) _buildDesktopToolbar(context),

                // ✅ Banner compacto de resumen
                _buildCompactStats(context),

                // ✅ Search field (para tablets y desktop sin sidebar)
                if (!isDesktop)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _buildSearchField(context),
                  ),

                // Lista de gastos
                Expanded(child: _buildExpensesList(context)),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSidebarContent(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Header del panel compacto
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dashboard,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Panel de Control',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Búsqueda
        Padding(
          padding: const EdgeInsets.all(12),
          child: _buildSearchField(context),
        ),

        const SizedBox(height: 12),

        // Filtros
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: ModernExpenseFilterWidget(),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCompactStats(BuildContext context) {
    return Obx(() {
      if (controller.stats != null) {
        return ModernExpenseStatsWidget(
          stats: controller.stats!,
          isCompact: true,
          periodLabel: _getPeriodLabel(),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildMobileSearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: _buildSearchField(context),
    );
  }

  Widget _buildDesktopToolbar(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Información de resultados
          Expanded(
            child: Obx(() {
              final total = controller.totalItems;
              final current = controller.expenses.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lista de Gastos',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mostrando $current de $total gastos',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isTablet ? 12 : 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),

          SizedBox(width: isTablet ? 8 : 16),

          // Acciones adaptables según pantalla
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Nuevo Gasto - Adaptable
              if (isDesktop)
                // Desktop: Botón con texto
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.goToCreateExpense,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nuevo Gasto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Tablet: Solo icono
                Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.goToCreateExpense,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Obx(() {
      final hasSearch = controller.searchTerm.isNotEmpty;
      final totalResults = controller.totalItems;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                hasSearch
                    ? ElegantLightTheme.primaryBlue.withOpacity(0.4)
                    : Colors.grey.shade300,
            width: hasSearch ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  hasSearch
                      ? ElegantLightTheme.primaryBlue.withOpacity(0.1)
                      : Colors.black.withOpacity(0.04),
              blurRadius: hasSearch ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icono de búsqueda con animación o indicador de carga
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Obx(() {
                if (controller.isSearching) {
                  return SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  );
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    hasSearch ? Icons.search_outlined : Icons.search,
                    key: ValueKey(hasSearch),
                    color:
                        hasSearch
                            ? ElegantLightTheme.primaryBlue
                            : Colors.grey.shade500,
                    size: 22,
                  ),
                );
              }),
            ),

            // Campo de texto
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: (value) => controller.updateSearch(value),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w500,
                  color: ElegantLightTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar gastos por descripción, vendor...',
                  hintStyle: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                ),
              ),
            ),

            // Contador de resultados (si hay búsqueda activa)
            if (hasSearch && !isMobile) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 14,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalResults',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botón de limpiar
            if (hasSearch)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      controller.searchController.clear();
                      controller.updateSearch('');
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildExpensesList(BuildContext context) {
    return Obx(() {
      final expenses = controller.expenses;

      if (expenses.isEmpty && !controller.isLoading) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.refreshExpenses();
        },
        child: ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length + (controller.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= expenses.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final expense = expenses[index];
            return ModernExpenseCardWidget(
              expense: expense,
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
    final isMobile = ResponsiveHelper.isMobile(context);
    final hasSearch = controller.searchTerm.isNotEmpty;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? 340 : 480),
        margin: const EdgeInsets.all(24),
        padding: EdgeInsets.all(isMobile ? 32 : 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono con gradiente circular
            Container(
              width: isMobile ? 100 : 120,
              height: isMobile ? 100 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      hasSearch
                          ? [
                            ElegantLightTheme.accentOrange.withOpacity(0.1),
                            ElegantLightTheme.accentOrange.withOpacity(0.05),
                          ]
                          : [
                            ElegantLightTheme.primaryBlue.withOpacity(0.1),
                            ElegantLightTheme.primaryBlue.withOpacity(0.05),
                          ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off : Icons.receipt_long_outlined,
                size: isMobile ? 50 : 60,
                color:
                    hasSearch
                        ? ElegantLightTheme.accentOrange
                        : ElegantLightTheme.primaryBlue,
              ),
            ),

            SizedBox(height: isMobile ? 24 : 32),

            // Título
            Text(
              hasSearch
                  ? 'No se encontraron gastos'
                  : 'No hay gastos registrados',
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Descripción
            Text(
              hasSearch
                  ? 'Intenta con otros términos de búsqueda o ajusta los filtros aplicados'
                  : 'Comienza a registrar tus gastos para llevar un mejor control de tus finanzas',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: isMobile ? 14 : 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isMobile ? 28 : 36),

            // Botón elegante
            if (hasSearch)
              _buildElegantButton(
                context: context,
                text: 'Limpiar Búsqueda',
                icon: Icons.clear_all,
                color: ElegantLightTheme.accentOrange,
                onPressed: controller.clearFilters,
                isOutline: true,
              )
            else
              _buildElegantButton(
                context: context,
                text: 'Registrar Primer Gasto',
                icon: Icons.add_circle_outline,
                color: ElegantLightTheme.primaryBlue,
                onPressed: controller.goToCreateExpense,
                isOutline: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isOutline,
  }) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 32,
            vertical: isMobile ? 14 : 16,
          ),
          decoration: BoxDecoration(
            gradient:
                isOutline
                    ? null
                    : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.8)],
                    ),
            color: isOutline ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOutline ? color : color.withOpacity(0.3),
              width: isOutline ? 2 : 1,
            ),
            boxShadow:
                isOutline
                    ? null
                    : [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isOutline ? color : Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  color: isOutline ? color : Colors.white,
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return const SizedBox.shrink();
    }

    if (ResponsiveHelper.isMobile(context)) {
      return Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            ...ElegantLightTheme.glowShadow,
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => controller.goToCreateExpense(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          ...ElegantLightTheme.glowShadow,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => controller.goToCreateExpense(),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Nuevo Gasto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con diseño moderno
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.primaryBlue.withOpacity(
                            0.05,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: ElegantLightTheme.glowShadow,
                              ),
                              child: const Icon(
                                Icons.filter_list,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Filtros de Gastos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: ElegantLightTheme.textTertiary
                                    .withOpacity(0.1),
                                foregroundColor:
                                    ElegantLightTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const ModernExpenseFilterWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _showRefreshSuccess() {
    Get.snackbar(
      'Actualizado',
      'Los gastos se han actualizado correctamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  // Métodos para el filtro de fechas
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

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'date_filter':
        _showDateRangePickerDialog(context);
        break;
      case 'filters':
        _showFilters(context);
        break;
      case 'refresh':
        controller.refreshExpenses().then((_) => _showRefreshSuccess());
        break;
    }
  }

  Future<void> _showDateRangePickerDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Container(
              width:
                  ResponsiveHelper.isMobile(context)
                      ? MediaQuery.of(context).size.width * 0.9
                      : 450,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ElegantLightTheme.primaryBlue.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header elegante con gradiente
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Filtrar por Período',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                  ),

                  // Contenido del diálogo
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Sección de períodos rápidos
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: ElegantLightTheme.primaryBlue
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.flash_on,
                                  size: 18,
                                  color: ElegantLightTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Períodos Rápidos',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildPeriodChip(context, 'Hoy', 'today'),
                              _buildPeriodChip(context, 'Esta Semana', 'week'),
                              _buildPeriodChip(context, 'Este Mes', 'month'),
                              _buildPeriodChip(context, 'Todos', 'all'),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Divider elegante
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.grey.shade300,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'O',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.grey.shade300,
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Sección de rango personalizado
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_calendar,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rango Personalizado',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ✅ Layout responsive: Column en móvil, Row en desktop
                          ResponsiveHelper.isMobile(context)
                              ? Column(
                                children: [
                                  Obx(
                                    () => _buildDateField(
                                      context,
                                      label: 'Fecha Desde',
                                      date: controller.startDate,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              controller.startDate ??
                                              DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                          locale: const Locale('es', 'ES'),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary:
                                                      ElegantLightTheme
                                                          .primaryBlue,
                                                  onPrimary: Colors.white,
                                                  surface: Colors.white,
                                                  onSurface:
                                                      Colors.grey.shade800,
                                                ),
                                                textButtonTheme:
                                                    TextButtonThemeData(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            ElegantLightTheme
                                                                .primaryBlue,
                                                        textStyle:
                                                            const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                    ),
                                                datePickerTheme: DatePickerThemeData(
                                                  backgroundColor: Colors.white,
                                                  headerBackgroundColor:
                                                      ElegantLightTheme
                                                          .primaryBlue,
                                                  headerForegroundColor:
                                                      Colors.white,
                                                  dayForegroundColor:
                                                      WidgetStateProperty.resolveWith(
                                                        (states) {
                                                          if (states.contains(
                                                            WidgetState
                                                                .selected,
                                                          )) {
                                                            return Colors.white;
                                                          }
                                                          return Colors
                                                              .grey
                                                              .shade800;
                                                        },
                                                      ),
                                                  dayBackgroundColor:
                                                      WidgetStateProperty.resolveWith((
                                                        states,
                                                      ) {
                                                        if (states.contains(
                                                          WidgetState.selected,
                                                        )) {
                                                          return ElegantLightTheme
                                                              .primaryBlue;
                                                        }
                                                        return Colors
                                                            .transparent;
                                                      }),
                                                  todayForegroundColor:
                                                      WidgetStateProperty.all(
                                                        ElegantLightTheme
                                                            .primaryBlue,
                                                      ),
                                                  todayBackgroundColor:
                                                      WidgetStateProperty.all(
                                                        Colors.transparent,
                                                      ),
                                                  todayBorder: BorderSide(
                                                    color:
                                                        ElegantLightTheme
                                                            .primaryBlue,
                                                    width: 2,
                                                  ),
                                                  dayOverlayColor:
                                                      WidgetStateProperty.resolveWith((
                                                        states,
                                                      ) {
                                                        if (states.contains(
                                                          WidgetState.hovered,
                                                        )) {
                                                          return ElegantLightTheme
                                                              .primaryBlue
                                                              .withOpacity(0.1);
                                                        }
                                                        return null;
                                                      }),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                dialogTheme: DialogThemeData(
                                                  backgroundColor: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          controller.setDateRange(
                                            start: picked,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Obx(
                                    () => _buildDateField(
                                      context,
                                      label: 'Fecha Hasta',
                                      date: controller.endDate,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              controller.endDate ??
                                              DateTime.now(),
                                          firstDate:
                                              controller.startDate ??
                                              DateTime(2020),
                                          lastDate: DateTime.now(),
                                          locale: const Locale('es', 'ES'),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary:
                                                      ElegantLightTheme
                                                          .primaryBlue,
                                                  onPrimary: Colors.white,
                                                  surface: Colors.white,
                                                  onSurface:
                                                      Colors.grey.shade800,
                                                ),
                                                textButtonTheme:
                                                    TextButtonThemeData(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor:
                                                            ElegantLightTheme
                                                                .primaryBlue,
                                                        textStyle:
                                                            const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                            ),
                                                      ),
                                                    ),
                                                datePickerTheme: DatePickerThemeData(
                                                  backgroundColor: Colors.white,
                                                  headerBackgroundColor:
                                                      ElegantLightTheme
                                                          .primaryBlue,
                                                  headerForegroundColor:
                                                      Colors.white,
                                                  dayForegroundColor:
                                                      WidgetStateProperty.resolveWith(
                                                        (states) {
                                                          if (states.contains(
                                                            WidgetState
                                                                .selected,
                                                          )) {
                                                            return Colors.white;
                                                          }
                                                          return Colors
                                                              .grey
                                                              .shade800;
                                                        },
                                                      ),
                                                  dayBackgroundColor:
                                                      WidgetStateProperty.resolveWith((
                                                        states,
                                                      ) {
                                                        if (states.contains(
                                                          WidgetState.selected,
                                                        )) {
                                                          return ElegantLightTheme
                                                              .primaryBlue;
                                                        }
                                                        return Colors
                                                            .transparent;
                                                      }),
                                                  todayForegroundColor:
                                                      WidgetStateProperty.all(
                                                        ElegantLightTheme
                                                            .primaryBlue,
                                                      ),
                                                  todayBackgroundColor:
                                                      WidgetStateProperty.all(
                                                        Colors.transparent,
                                                      ),
                                                  todayBorder: BorderSide(
                                                    color:
                                                        ElegantLightTheme
                                                            .primaryBlue,
                                                    width: 2,
                                                  ),
                                                  dayOverlayColor:
                                                      WidgetStateProperty.resolveWith((
                                                        states,
                                                      ) {
                                                        if (states.contains(
                                                          WidgetState.hovered,
                                                        )) {
                                                          return ElegantLightTheme
                                                              .primaryBlue
                                                              .withOpacity(0.1);
                                                        }
                                                        return null;
                                                      }),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                ),
                                                dialogTheme: DialogThemeData(
                                                  backgroundColor: Colors.white,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (picked != null) {
                                          controller.setDateRange(end: picked);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              )
                              : Row(
                                children: [
                                  Expanded(
                                    child: Obx(
                                      () => _buildDateField(
                                        context,
                                        label: 'Fecha Desde',
                                        date: controller.startDate,
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                controller.startDate ??
                                                DateTime.now(),
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime.now(),
                                            locale: const Locale('es', 'ES'),
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(
                                                  context,
                                                ).copyWith(
                                                  colorScheme:
                                                      ColorScheme.light(
                                                        primary:
                                                            ElegantLightTheme
                                                                .primaryBlue,
                                                        onPrimary: Colors.white,
                                                        surface: Colors.white,
                                                        onSurface:
                                                            Colors
                                                                .grey
                                                                .shade800,
                                                      ),
                                                  textButtonTheme:
                                                      TextButtonThemeData(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor:
                                                              ElegantLightTheme
                                                                  .primaryBlue,
                                                          textStyle:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                  datePickerTheme: DatePickerThemeData(
                                                    backgroundColor:
                                                        Colors.white,
                                                    headerBackgroundColor:
                                                        ElegantLightTheme
                                                            .primaryBlue,
                                                    headerForegroundColor:
                                                        Colors.white,
                                                    dayForegroundColor:
                                                        WidgetStateProperty.resolveWith(
                                                          (states) {
                                                            if (states.contains(
                                                              WidgetState
                                                                  .selected,
                                                            )) {
                                                              return Colors
                                                                  .white;
                                                            }
                                                            return Colors
                                                                .grey
                                                                .shade800;
                                                          },
                                                        ),
                                                    dayBackgroundColor:
                                                        WidgetStateProperty.resolveWith((
                                                          states,
                                                        ) {
                                                          if (states.contains(
                                                            WidgetState
                                                                .selected,
                                                          )) {
                                                            return ElegantLightTheme
                                                                .primaryBlue;
                                                          }
                                                          return Colors
                                                              .transparent;
                                                        }),
                                                    todayForegroundColor:
                                                        WidgetStateProperty.all(
                                                          ElegantLightTheme
                                                              .primaryBlue,
                                                        ),
                                                    todayBackgroundColor:
                                                        WidgetStateProperty.all(
                                                          Colors.transparent,
                                                        ),
                                                    todayBorder: BorderSide(
                                                      color:
                                                          ElegantLightTheme
                                                              .primaryBlue,
                                                      width: 2,
                                                    ),
                                                    dayOverlayColor:
                                                        WidgetStateProperty.resolveWith((
                                                          states,
                                                        ) {
                                                          if (states.contains(
                                                            WidgetState.hovered,
                                                          )) {
                                                            return ElegantLightTheme
                                                                .primaryBlue
                                                                .withOpacity(
                                                                  0.1,
                                                                );
                                                          }
                                                          return null;
                                                        }),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                  dialogTheme: DialogThemeData(
                                                    backgroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            controller.setDateRange(
                                              start: picked,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Obx(
                                      () => _buildDateField(
                                        context,
                                        label: 'Fecha Hasta',
                                        date: controller.endDate,
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                controller.endDate ??
                                                DateTime.now(),
                                            firstDate:
                                                controller.startDate ??
                                                DateTime(2020),
                                            lastDate: DateTime.now(),
                                            locale: const Locale('es', 'ES'),
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(
                                                  context,
                                                ).copyWith(
                                                  colorScheme:
                                                      ColorScheme.light(
                                                        primary:
                                                            ElegantLightTheme
                                                                .primaryBlue,
                                                        onPrimary: Colors.white,
                                                        surface: Colors.white,
                                                        onSurface:
                                                            Colors
                                                                .grey
                                                                .shade800,
                                                      ),
                                                  textButtonTheme:
                                                      TextButtonThemeData(
                                                        style: TextButton.styleFrom(
                                                          foregroundColor:
                                                              ElegantLightTheme
                                                                  .primaryBlue,
                                                          textStyle:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                  datePickerTheme: DatePickerThemeData(
                                                    backgroundColor:
                                                        Colors.white,
                                                    headerBackgroundColor:
                                                        ElegantLightTheme
                                                            .primaryBlue,
                                                    headerForegroundColor:
                                                        Colors.white,
                                                    dayForegroundColor:
                                                        WidgetStateProperty.resolveWith(
                                                          (states) {
                                                            if (states.contains(
                                                              WidgetState
                                                                  .selected,
                                                            )) {
                                                              return Colors
                                                                  .white;
                                                            }
                                                            return Colors
                                                                .grey
                                                                .shade800;
                                                          },
                                                        ),
                                                    dayBackgroundColor:
                                                        WidgetStateProperty.resolveWith((
                                                          states,
                                                        ) {
                                                          if (states.contains(
                                                            WidgetState
                                                                .selected,
                                                          )) {
                                                            return ElegantLightTheme
                                                                .primaryBlue;
                                                          }
                                                          return Colors
                                                              .transparent;
                                                        }),
                                                    todayForegroundColor:
                                                        WidgetStateProperty.all(
                                                          ElegantLightTheme
                                                              .primaryBlue,
                                                        ),
                                                    todayBackgroundColor:
                                                        WidgetStateProperty.all(
                                                          Colors.transparent,
                                                        ),
                                                    todayBorder: BorderSide(
                                                      color:
                                                          ElegantLightTheme
                                                              .primaryBlue,
                                                      width: 2,
                                                    ),
                                                    dayOverlayColor:
                                                        WidgetStateProperty.resolveWith((
                                                          states,
                                                        ) {
                                                          if (states.contains(
                                                            WidgetState.hovered,
                                                          )) {
                                                            return ElegantLightTheme
                                                                .primaryBlue
                                                                .withOpacity(
                                                                  0.1,
                                                                );
                                                          }
                                                          return null;
                                                        }),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                  ),
                                                  dialogTheme: DialogThemeData(
                                                    backgroundColor:
                                                        Colors.white,
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            controller.setDateRange(
                                              end: picked,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          // Botones de acción elegantes
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    controller.clearDateFilters();
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.clear_all,
                                        size: 18,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Limpiar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: ElegantLightTheme.successGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Aplicar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, String period) {
    return Obx(() {
      final isSelected = controller.currentPeriod == period;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? ElegantLightTheme.primaryBlue
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              controller.setPeriod(period);
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
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

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final hasDate = date != null;

    String formatDate(DateTime date) {
      const months = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                hasDate
                    ? ElegantLightTheme.primaryBlue.withOpacity(0.05)
                    : Colors.grey.shade50,
            border: Border.all(
              color:
                  hasDate
                      ? ElegantLightTheme.primaryBlue.withOpacity(0.4)
                      : Colors.grey.shade300,
              width: hasDate ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow:
                hasDate
                    ? [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      hasDate
                          ? ElegantLightTheme.primaryBlue.withOpacity(0.15)
                          : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasDate ? Icons.event_available : Icons.calendar_today,
                  size: 20,
                  color:
                      hasDate
                          ? ElegantLightTheme.primaryBlue
                          : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            hasDate
                                ? ElegantLightTheme.primaryBlue
                                : Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date != null ? formatDate(date) : 'Toca para seleccionar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasDate ? FontWeight.w700 : FontWeight.w500,
                        color:
                            hasDate
                                ? Colors.grey.shade800
                                : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color:
                    hasDate
                        ? ElegantLightTheme.primaryBlue
                        : Colors.grey.shade600,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NUEVO: Helper para obtener etiqueta del período activo
  String _getPeriodLabel() {
    final period = controller.currentPeriod;
    final hasDateRange =
        controller.startDate != null || controller.endDate != null;

    if (hasDateRange &&
        controller.startDate != null &&
        controller.endDate != null) {
      // Rango personalizado
      final start = controller.startDate!;
      final end = controller.endDate!;
      return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
    } else if (hasDateRange && controller.startDate != null) {
      final start = controller.startDate!;
      return 'Desde ${start.day}/${start.month}/${start.year}';
    } else if (hasDateRange && controller.endDate != null) {
      final end = controller.endDate!;
      return 'Hasta ${end.day}/${end.month}/${end.year}';
    }

    // Períodos predefinidos
    switch (period) {
      case 'today':
        return 'Hoy';
      case 'week':
        return 'Esta Semana';
      case 'month':
        return 'Este Mes';
      case 'all':
        return 'Todos los Períodos';
      default:
        return 'Período Actual';
    }
  }
}
