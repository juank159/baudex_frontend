// lib/features/expenses/presentation/widgets/modern_category_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../domain/entities/expense_category.dart';
import '../controllers/expense_form_controller.dart';
import '../widgets/compact_expense_field.dart';

class ModernCategoryFormDialog extends StatefulWidget {
  final ExpenseCategory? category;
  final Function(ExpenseCategory) onCategorySaved;

  const ModernCategoryFormDialog({
    super.key,
    this.category,
    required this.onCategorySaved,
  });

  @override
  State<ModernCategoryFormDialog> createState() => _ModernCategoryFormDialogState();
}

class _ModernCategoryFormDialogState extends State<ModernCategoryFormDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Color _selectedColor = const Color(0xFF3B82F6); // Blue default
  bool _isLoading = false;

  final List<Color> _availableColors = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFEC4899), // Pink
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFF97316), // Orange
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF84CC16), // Lime
    const Color(0xFFA855F7), // Violet
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Si es edición, cargar datos
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _budgetController.text = widget.category!.monthlyBudget > 0
          ? widget.category!.monthlyBudget.toStringAsFixed(0)
          : '';

      // Parse color
      if (widget.category!.color != null && widget.category!.color!.isNotEmpty) {
        try {
          final colorString = widget.category!.color!.replaceAll('#', '');
          final colorValue = int.parse('FF$colorString', radix: 16);
          _selectedColor = Color(colorValue);
        } catch (e) {
          _selectedColor = _availableColors[0];
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isEdit = widget.category != null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 600,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(context, isEdit),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview Card
                          _buildPreviewCard(context),

                          SizedBox(height: isMobile ? 16 : 20),

                          // Name Field
                          CompactExpenseField(
                            controller: _nameController,
                            label: 'Nombre',
                            hint: 'Ej: Viajes de trabajo',
                            prefixIcon: Icons.label,
                            validator: (value) {
                              if (value?.trim().isEmpty ?? true) {
                                return 'El nombre es requerido';
                              }
                              if (value!.length < 2) {
                                return 'Mínimo 2 caracteres';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 12),

                          // Description Field
                          CompactExpenseField(
                            controller: _descriptionController,
                            label: 'Descripción',
                            hint: 'Descripción de la categoría',
                            prefixIcon: Icons.description,
                            maxLines: 2,
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 12),

                          // Budget Field
                          CompactExpenseField(
                            controller: _budgetController,
                            label: 'Presupuesto Mensual',
                            hint: '0',
                            prefixIcon: Icons.account_balance_wallet,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value?.trim().isNotEmpty == true) {
                                final budget = double.tryParse(value!);
                                if (budget == null || budget < 0) {
                                  return 'Ingrese un presupuesto válido';
                                }
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 16),

                          // Color Selector
                          _buildColorSelector(context),
                        ],
                      ),
                    ),
                  ),
                ),

                // Actions
                _buildActions(context, isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEdit ? Icons.edit : Icons.add_circle,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEdit ? 'Editar Categoría' : 'Nueva Categoría',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final hasName = _nameController.text.isNotEmpty;
    final hasBudget = _budgetController.text.isNotEmpty;
    final hasDescription = _descriptionController.text.isNotEmpty;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 400,
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _selectedColor.withValues(alpha: 0.1),
              _selectedColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _selectedColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _selectedColor,
                        _selectedColor.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _selectedColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasName ? _nameController.text : 'Vista previa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hasName
                          ? ElegantLightTheme.textPrimary
                          : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (hasDescription) ...[
              const SizedBox(height: 8),
              Text(
                _descriptionController.text,
                style: TextStyle(
                  fontSize: 11,
                  color: ElegantLightTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hasBudget) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 12,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${_budgetController.text} / mes',
                      style: TextStyle(
                        fontSize: 11,
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
    );
  }

  Widget _buildColorSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color de la Categoría',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _availableColors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 44 : 40,
                height: isSelected ? 44 : 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: _isLoading ? null : ElegantLightTheme.primaryGradient,
                color: _isLoading ? Colors.grey.shade300 : null,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEdit ? 'Actualizar' : 'Crear Categoría',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = Get.find<ExpenseFormController>();

      final colorHex = '#${_selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
      final budget = double.tryParse(_budgetController.text) ?? 0.0;

      final result = widget.category == null
          ? await controller.createExpenseCategory(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              color: colorHex,
              monthlyBudget: budget,
            )
          : await controller.updateExpenseCategory(
              categoryId: widget.category!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              color: colorHex,
              monthlyBudget: budget,
            );

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
        (category) {
          widget.onCategorySaved(category);
          Navigator.of(context).pop();

          Get.snackbar(
            'Éxito',
            widget.category == null
                ? 'Categoría creada exitosamente'
                : 'Categoría actualizada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo ${widget.category == null ? "crear" : "actualizar"} la categoría: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
