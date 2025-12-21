// lib/features/dashboard/presentation/widgets/expense_pie_chart.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_text_styles.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/dashboard_controller.dart';

class ExpensePieChart extends StatefulWidget {
  const ExpensePieChart({super.key});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int touchedIndex = -1;

  // Colores para las categorías del pie chart
  static const List<Color> categoryColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF84CC16), // Lime
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: ElegantLightTheme.glassDecoration(
            borderColor: ElegantLightTheme.primaryBlue.withOpacity(0.3),
            gradient: ElegantLightTheme.glassGradient,
          ),
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
          child: Obx(() {
            if (controller.isLoadingExpenseChart) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final expensesByCategory = controller.expensesByCategory;

            if (expensesByCategory.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  _buildEmptyState(),
                ],
              );
            }

            // En mobile: header arriba, luego contenido
            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 14),
                  Flexible(
                    child: _buildMobileLayout(expensesByCategory),
                  ),
                ],
              );
            }

            // En desktop: header + pie chart en la izquierda, leyenda en la derecha
            return _buildDesktopLayout(expensesByCategory);
          }),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEF4444), // Red sólido
                Color(0xFFDC2626), // Red dark sólido
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.pie_chart,
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
                'Gastos por Categoría',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Distribución de gastos del período',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin datos de gastos',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay gastos registrados en este período',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, double> expensesByCategory) {
    // Envolver todo en SingleChildScrollView para evitar overflow
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140, // Más compacto para móvil
            child: _buildPieChart(expensesByCategory, isMobile: true),
          ),
          const SizedBox(height: 10),
          _buildLegend(expensesByCategory, compact: true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Map<String, double> expensesByCategory) {
    final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Alinea todo arriba
      children: [
        // Columna izquierda: Header + Pie chart
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 4), // Más cerca del header (subir)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 48, top: 0), // Mover a la derecha y arriba
                  child: _buildPieChart(expensesByCategory, isMobile: false),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Columna derecha: Total Gastos (fijo) + Categorías (scroll)
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Gastos - FIJO (fuera del scroll)
              _buildTotalGastosCard(total, compact: false),
              const SizedBox(height: 12),
              // Lista de categorías - CON SCROLL
              Flexible(
                child: SingleChildScrollView(
                  child: _buildCategoryList(expensesByCategory, compact: false),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Map<String, double> expensesByCategory, {bool isMobile = false}) {
    final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final entries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tamaños más pequeños para móvil
    final centerRadius = isMobile ? 30.0 : 50.0;
    final normalRadius = isMobile ? 40.0 : 60.0;
    final touchedRadius = isMobile ? 48.0 : 70.0;
    final titleFontSize = isMobile ? 10.0 : 14.0;

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: isMobile ? 1 : 2,
        centerSpaceRadius: centerRadius,
        sections: entries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final isTouched = index == touchedIndex;
          final percentage = (entry.value / total * 100);
          final color = categoryColors[index % categoryColors.length];

          return PieChartSectionData(
            // Gradiente radial con reflejo blanco (como las barras)
            gradient: RadialGradient(
              center: Alignment.topLeft, // El reflejo viene de arriba-izquierda
              radius: 1.2,
              colors: [
                Colors.white.withOpacity(0.4), // Reflejo blanco sutil
                color.withOpacity(0.85),
                color, // Color sólido en el centro
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            value: entry.value,
            title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: isTouched ? touchedRadius : normalRadius,
            titleStyle: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                ),
              ],
            ),
            badgeWidget: isTouched && !isMobile
                ? _buildBadge(entry.key, entry.value, color)
                : null,
            badgePositionPercentageOffset: 1.3,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBadge(String category, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            AppFormatters.formatCurrency(amount.toInt()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Card de "Total Gastos" (fija, no scroll)
  Widget _buildTotalGastosCard(double total, {bool compact = false}) {
    final headerPadding = compact ? 8.0 : 10.0;
    final iconSize = compact ? 16.0 : 18.0;
    final labelFontSize = compact ? 10.0 : 11.0;
    final valueFontSize = compact ? 13.0 : 15.0;

    return Container(
      padding: EdgeInsets.all(headerPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(
          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: ElegantLightTheme.primaryBlue,
            size: iconSize,
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Gastos',
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(total.toInt()),
                  style: TextStyle(
                    color: ElegantLightTheme.primaryBlue,
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Lista de categorías (solo las cards de categorías, más compactas)
  Widget _buildCategoryList(Map<String, double> expensesByCategory, {bool compact = false}) {
    final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final entries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tamaños más compactos para desktop/tablet
    final itemPadding = compact ? 6.0 : 7.0; // Reducido de 10.0
    final itemSpacing = compact ? 4.0 : 5.0; // Reducido de 8.0
    final categoryFontSize = compact ? 11.0 : 11.0; // Reducido de 12.0
    final amountFontSize = compact ? 11.0 : 12.0; // Reducido de 13.0
    final percentFontSize = compact ? 9.0 : 10.0; // Reducido de 11.0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: entries.asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        final percentage = (entry.value / total * 100);
        final color = categoryColors[index % categoryColors.length];
        final isTouched = index == touchedIndex;

        return Padding(
          padding: EdgeInsets.only(bottom: itemSpacing),
          child: GestureDetector(
            onTap: () {
              setState(() {
                touchedIndex = isTouched ? -1 : index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(itemPadding),
              decoration: BoxDecoration(
                color: isTouched
                    ? color.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(compact ? 8 : 8),
                border: Border.all(
                  color: isTouched
                      ? color.withValues(alpha: 0.5)
                      : color.withValues(alpha: 0.2),
                  width: isTouched ? 2 : 1,
                ),
                boxShadow: isTouched
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 10 : 10,
                    height: compact ? 10 : 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: compact ? 2 : 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: categoryFontSize,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: compact ? 1 : 1),
                        Text(
                          AppFormatters.formatCurrency(entry.value.toInt()),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: amountFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 6,
                      vertical: compact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(compact ? 6 : 6),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: percentFontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(Map<String, double> expensesByCategory, {bool compact = false}) {
    final total = expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final entries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Tamaños compactos para móvil
    final headerPadding = compact ? 8.0 : 12.0;
    final iconSize = compact ? 16.0 : 20.0;
    final labelFontSize = compact ? 10.0 : 11.0;
    final valueFontSize = compact ? 13.0 : 16.0;
    final itemPadding = compact ? 6.0 : 10.0;
    final itemSpacing = compact ? 4.0 : 8.0;
    final categoryFontSize = compact ? 11.0 : 12.0;
    final amountFontSize = compact ? 11.0 : 13.0;
    final percentFontSize = compact ? 9.0 : 11.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total header
        Container(
          padding: EdgeInsets.all(headerPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 8 : 12),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: ElegantLightTheme.primaryBlue,
                size: iconSize,
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Gastos',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(total.toInt()),
                      style: TextStyle(
                        color: ElegantLightTheme.primaryBlue,
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 10 : 16),
        // Category list
        ...entries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final percentage = (entry.value / total * 100);
          final color = categoryColors[index % categoryColors.length];
          final isTouched = index == touchedIndex;

          return Padding(
            padding: EdgeInsets.only(bottom: itemSpacing),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  touchedIndex = isTouched ? -1 : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(itemPadding),
                decoration: BoxDecoration(
                  color: isTouched
                      ? color.withValues(alpha: 0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
                  border: Border.all(
                    color: isTouched
                        ? color.withValues(alpha: 0.5)
                        : color.withValues(alpha: 0.2),
                    width: isTouched ? 2 : 1,
                  ),
                  boxShadow: isTouched
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 10 : 12,
                      height: compact ? 10 : 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: compact ? 2 : 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: categoryFontSize,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: compact ? 1 : 2),
                          Text(
                            AppFormatters.formatCurrency(entry.value.toInt()),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: amountFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 8,
                        vertical: compact ? 2 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(compact ? 6 : 8),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: percentFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
