// lib/features/expenses/presentation/widgets/modern_category_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/expense_category.dart';
import '../controllers/expense_form_controller.dart';
import 'modern_category_form_dialog.dart';
import 'budget_indicator_widget.dart';

class ModernCategorySelectorWidget extends StatelessWidget {
  final ExpenseFormController controller;
  final bool isRequired;

  const ModernCategorySelectorWidget({
    super.key,
    required this.controller,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                'Categoría',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showCreateCategoryDialog(context),
                icon: Icon(
                  Icons.add_circle,
                  size: 16,
                  color: ElegantLightTheme.primaryBlue,
                ),
                label: Text(
                  'Nueva',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),

        Obx(() {
          if (controller.isLoadingCategories) {
            return Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.white,
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (controller.categories.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildCategorySelector(context);
        }),
      ],
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Obx(() {
      final hasValue = controller.selectedCategory.value != null;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCategoryBottomSheet(context),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isMobile ? 12 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasValue
                    ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                width: hasValue ? 1.5 : 1,
              ),
              color: Colors.white,
              boxShadow: hasValue
                  ? [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Indicador de color
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: hasValue
                        ? _getCategoryColor(controller.selectedCategory.value!)
                        : Colors.grey.shade300,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: hasValue
                        ? [
                            BoxShadow(
                              color: _getCategoryColor(controller.selectedCategory.value!)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: hasValue
                      ? Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasValue
                            ? controller.selectedCategory.value!.name
                            : 'Seleccionar categoría',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                          color: hasValue
                              ? ElegantLightTheme.textPrimary
                              : ElegantLightTheme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasValue && controller.selectedCategory.value!.description?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            controller.selectedCategory.value!.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: ElegantLightTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Icono
                Icon(
                  Icons.arrow_drop_down,
                  color: hasValue
                      ? ElegantLightTheme.primaryBlue
                      : ElegantLightTheme.textTertiary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 32,
                color: ElegantLightTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay categorías disponibles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateCategoryDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Crear Categoría',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ElegantLightTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: ElegantLightTheme.primaryBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seleccionar Categoría',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Categories List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.categories.where((c) => c.isActive).length,
                  itemBuilder: (context, index) {
                    final category = controller.categories.where((c) => c.isActive).toList()[index];
                    final isSelected = controller.selectedCategory.value?.id == category.id;

                    return _buildCategoryOption(context, category, isSelected);
                  },
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreateCategoryDialog(context);
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nueva Categoría'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryOption(BuildContext context, ExpenseCategory category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.selectedCategory.value = category;
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? ElegantLightTheme.primaryGradient.scale(0.1)
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Color indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(category).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.category,
                    color: Colors.white,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? ElegantLightTheme.primaryBlue
                              : ElegantLightTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          category.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: ElegantLightTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (category.hasStats && category.monthlyBudget > 0) ...[
                        const SizedBox(height: 8),
                        BudgetIndicatorWidget(
                          category: category,
                          isCompact: true,
                        ),
                      ] else if (category.monthlyBudget > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.successGradient.scale(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 10,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.formattedBudget,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Checkmark
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ModernCategoryFormDialog(
        onCategorySaved: (category) {
          controller.categories.add(category);
          controller.selectedCategory.value = category;
        },
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        final colorString = category.color!.replaceAll('#', '');
        final colorValue = int.parse('FF$colorString', radix: 16);
        return Color(colorValue);
      } catch (e) {
        // Fallback to default color
      }
    }

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];

    final index = category.name.hashCode % colors.length;
    return colors[index.abs()];
  }
}
