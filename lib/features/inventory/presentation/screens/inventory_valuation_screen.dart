// lib/features/inventory/presentation/screens/inventory_valuation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../breb/presentation/widgets/breb_ui.dart';
import '../widgets/inventory_states.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/inventory_balance_controller.dart';
import 'package:baudex_desktop/app/core/theme/futuristic_notifications.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';

class InventoryValuationScreen extends GetView<InventoryBalanceController> {
  const InventoryValuationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Valoración de inventario',
      showBackButton: true,
      showDrawer: false,
      actions: _buildAppBarActions(),
      body: ColoredBox(
        color: ElegantLightTheme.backgroundColor,
        child: SizedBox.expand(
          child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 600;
            return SingleChildScrollView(
              padding: EdgeInsets.all(narrow ? 12 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderSection(narrow),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.isLoading.value &&
                            controller.valuationData.isEmpty) {
                          return const SizedBox(
                            height: 260,
                            child: InventoryLoadingState(
                              'Cargando valoración de inventario...',
                            ),
                          );
                        }

                        if (controller.error.value.isNotEmpty &&
                            controller.valuationData.isEmpty) {
                          return InventoryErrorState(
                            title: 'No se pudo cargar la valoración',
                            message: friendlyInventoryError(
                              controller.error.value,
                              what: 'la valoración',
                            ),
                            onRetry: controller.loadValuation,
                          );
                        }

                        return _buildValuationContent(narrow);
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        onPressed: () => _showExportOptions(),
        icon: const Icon(Icons.download),
        tooltip: 'Exportar',
      ),
      PopupMenuButton<String>(
        tooltip: 'Más opciones',
        onSelected: (value) {
          switch (value) {
            case 'refresh':
              controller.loadValuation();
              break;
            case 'filter':
              _showFilterOptions();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'refresh',
            child: Row(
              children: [
                Icon(Icons.refresh, color: ElegantLightTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Actualizar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'filter',
            child: Row(
              children: [
                Icon(Icons.filter_list, color: ElegantLightTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Filtros'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      );

  Widget _buildHeaderSection(bool narrow) {
    final cards = [
      _buildSummaryCard(
        title: 'Valor total',
        value: Obx(
          () => _summaryValue(
            AppFormatters.formatCurrency(
              controller.valuationData['totalValue'] ?? 0,
            ),
            ElegantLightTheme.primaryBlue,
          ),
        ),
        icon: Icons.monetization_on,
        gradient: ElegantLightTheme.primaryGradient,
      ),
      _buildSummaryCard(
        title: 'Productos',
        value: Obx(
          () => _summaryValue(
            AppFormatters.formatNumber(
              controller.valuationData['totalProducts']?.toInt() ?? 0,
            ),
            ElegantLightTheme.primaryBlue,
          ),
        ),
        icon: Icons.inventory,
        gradient: ElegantLightTheme.infoGradient,
      ),
      _buildSummaryCard(
        title: 'Unidades',
        value: Obx(
          () => _summaryValue(
            AppFormatters.formatNumber(
              controller.valuationData['totalUnits']?.toInt() ?? 0,
            ),
            ElegantLightTheme.successGreen,
          ),
        ),
        icon: Icons.inventory_2,
        gradient: ElegantLightTheme.successGradient,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (narrow) ...[
          cards[0],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          ),
        ] else
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
              const SizedBox(width: 16),
              Expanded(child: cards[2]),
            ],
          ),
        const SizedBox(height: 16),
        if (narrow) ...[
          _buildDateSelector(),
          const SizedBox(height: 12),
          _buildWarehouseFilter(),
        ] else
          Row(
            children: [
              Expanded(child: _buildDateSelector()),
              const SizedBox(width: 16),
              Expanded(child: _buildWarehouseFilter()),
            ],
          ),
      ],
    );
  }

  Widget _summaryValue(String text, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required Widget value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration,
      child: Row(
        children: [
          BrebIconBadge(icon: icon, gradient: gradient, size: 20, glow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBox({
    required String label,
    required IconData icon,
    required Widget value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: ElegantLightTheme.surfaceColor,
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: ElegantLightTheme.primaryBlue, size: 20),
              const SizedBox(width: 12),
              Expanded(child: value),
              const Icon(
                Icons.arrow_drop_down,
                color: ElegantLightTheme.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return _buildFilterBox(
      label: 'Fecha de valoración',
      icon: Icons.calendar_today,
      value: Obx(
        () => Text(
          controller.selectedDate.value != null
              ? AppFormatters.formatDate(controller.selectedDate.value!)
              : 'Hoy',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildWarehouseFilter() {
    return _buildFilterBox(
      label: 'Almacén',
      icon: Icons.warehouse,
      value: Obx(
        () => Text(
          controller.selectedWarehouse.value.isNotEmpty
              ? controller.selectedWarehouse.value
              : 'Todos los almacenes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildValuationContent(bool narrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Valuation method selector
        _buildValuationMethodSelector(narrow),

        const SizedBox(height: 16),

        // Results section
        Container(
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const BrebIconBadge(
                      icon: Icons.analytics,
                      gradient: ElegantLightTheme.primaryGradient,
                      size: 18,
                      glow: false,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resultados de valoración',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          Obx(
                            () => Text(
                              controller.lastUpdated.value != null
                                  ? 'Actualizado: ${AppFormatters.formatDateTime(controller.lastUpdated.value!)}'
                                  : 'Aún sin actualizar',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ElegantLightTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.25),
              ),
              Obx(() {
                if (controller.valuationData.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: BrebEmptyState(
                      icon: Icons.inventory_2_outlined,
                      message:
                          'No hay datos de valoración todavía. Cuando haya productos con existencias, aquí verás su valor.',
                    ),
                  );
                }

                return _buildValuationDetails();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValuationMethodSelector(bool narrow) {
    final options = [
      _buildMethodOption(
        'FIFO',
        'Primero en entrar, primero en salir',
        'fifo',
        Icons.trending_up,
        narrow,
      ),
      _buildMethodOption(
        'Costo promedio',
        'Basado en costo promedio ponderado',
        'average',
        Icons.analytics,
        narrow,
      ),
      _buildMethodOption(
        'Último costo',
        'Basado en el último precio de compra',
        'latest',
        Icons.schedule,
        narrow,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Método de valoración',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (narrow)
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              options[i],
            ]
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: options[0]),
                  const SizedBox(width: 12),
                  Expanded(child: options[1]),
                  const SizedBox(width: 12),
                  Expanded(child: options[2]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(
    String title,
    String description,
    String method,
    IconData icon,
    bool narrow,
  ) {
    return Obx(() {
      final isSelected = controller.selectedValuationMethod.value == method;
      final color =
          isSelected ? ElegantLightTheme.primaryBlue : ElegantLightTheme.textSecondary;
      final texts = Column(
        crossAxisAlignment:
            narrow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: narrow ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? ElegantLightTheme.primaryBlue
                  : ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            textAlign: narrow ? TextAlign.start : TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ],
      );

      return Material(
        color: isSelected
            ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.08)
            : ElegantLightTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? ElegantLightTheme.primaryBlue
                : ElegantLightTheme.textTertiary.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            controller.selectedValuationMethod.value = method;
            controller.loadValuation();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: narrow
                ? Row(
                    children: [
                      Icon(icon, color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: texts),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: ElegantLightTheme.primaryBlue,
                          size: 20,
                        ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(height: 8),
                      texts,
                    ],
                  ),
          ),
        ),
      );
    });
  }

  /// Antes aquí había desgloses "por categoría", "por almacén" e "impacto de
  /// movimientos" con números inventados (calculados con `hashCode` y nombres
  /// ficticios). El servidor solo devuelve totales, que ya están arriba; sin
  /// dato real no se muestra ninguna sección.
  Widget _buildValuationDetails() => const SizedBox.shrink();

  void _showExportOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Valoración',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: ElegantLightTheme.errorRed),
              title: const Text('Exportar a PDF'),
              subtitle: const Text('Reporte detallado con gráficos'),
              onTap: () {
                Get.back();
                controller.exportBalancesToPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: ElegantLightTheme.successGreen),
              title: const Text('Exportar a Excel'),
              subtitle: const Text('Datos para análisis adicional'),
              onTap: () {
                Get.back();
                controller.exportBalancesToExcel();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ElegantLightTheme.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filtros de Valorización',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('Filtrar por Almacén'),
              subtitle: const Text('Seleccionar almacenes específicos'),
              onTap: () {
                Get.back();
                controller.showFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Filtrar por Categoría'),
              subtitle: const Text('Seleccionar categorías de productos'),
              onTap: () {
                Get.back();
                controller.showFilters();
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on),
              title: const Text('Rango de Valores'),
              subtitle: const Text('Filtrar por valor de inventario'),
              onTap: () {
                Get.back();
                _showValueRangeFilter();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showValueRangeFilter() {
    final minController = TextEditingController();
    final maxController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: ElegantLightTheme.surfaceColor,
        shape: brebDialogShape,
        title: brebDialogTitle(Icons.monetization_on, 'Rango de valores'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtrar productos por valor de inventario'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: brebInputDecoration(label: 'Valor mínimo')
                        .copyWith(prefixText: '\$ '),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: brebInputDecoration(label: 'Valor máximo')
                        .copyWith(prefixText: '\$ '),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: brebTextButtonStyle(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: brebPrimaryButtonStyle(),
            onPressed: () {
              Get.back();
              FuturisticNotifications.showInfo('Filtro aplicado', 'Rango de valores configurado');
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
