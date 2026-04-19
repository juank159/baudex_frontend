// lib/features/expenses/presentation/widgets/expense_category_selector_widget.dart
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/errors/failures.dart';
import '../controllers/expense_form_controller.dart';
import '../../domain/entities/expense_category.dart';

class ExpenseCategorySelectorWidget extends StatelessWidget {
  final ExpenseFormController controller;

  const ExpenseCategorySelectorWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categoría *',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Obx(() {
              if (controller.selectedCategory.value != null) {
                return TextButton.icon(
                  onPressed: () => _showCategoryFormDialog(
                    context,
                    categoryToEdit: controller.selectedCategory.value!,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Editar', style: TextStyle(fontSize: 12)),
                );
              }
              return const SizedBox.shrink();
            }),
            TextButton.icon(
              onPressed: () => _showCategoryFormDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nueva', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Obx(() {
          if (controller.isLoadingCategories) {
            return const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator()),
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
    return Obx(() => DropdownButtonFormField<ExpenseCategory>(
      value: controller.selectedCategory.value,
      decoration: InputDecoration(
        hintText: 'Seleccionar categoría',
        prefixIcon: controller.selectedCategory.value != null
            ? Icon(
                Icons.category,
                color: _getCategoryColor(controller.selectedCategory.value!),
              )
            : const Icon(Icons.category),
        suffixIcon: controller.selectedCategory.value != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => controller.selectedCategory.value = null,
              )
            : null,
      ),
      items: controller.categories
          .where((category) => category.isActive)
          .map((category) => DropdownMenuItem<ExpenseCategory>(
            value: category,
            child: _buildCategoryItem(context, category),
          ))
          .toList(),
      onChanged: (category) => controller.selectedCategory.value = category,
      validator: (value) {
        if (value == null) {
          return 'Seleccione una categoría';
        }
        return null;
      },
      isExpanded: true,
      menuMaxHeight: 400,
      itemHeight: null, // Permite altura dinámica
      isDense: false, // Desactiva el modo denso para más espacio
    ));
  }

  Widget _buildCategoryItem(BuildContext context, ExpenseCategory category) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60), // Altura mínima garantizada
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Indicador de color
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: _getCategoryColor(category),
              shape: BoxShape.circle,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Información de la categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.2, // Reduce line height para mejor control
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (category.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    category.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      height: 1.2, // Reduce line height
                    ),
                    maxLines: 2, // Permite 2 líneas para descripción más larga
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Presupuesto mensual
          if (category.monthlyBudget > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.formattedBudget,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
          ],

        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 32,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay categorías disponibles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _showCategoryFormDialog(context),
            child: const Text('Crear Primera Categoría'),
          ),
        ],
      ),
    );
  }

  void _showCategoryFormDialog(BuildContext context, {ExpenseCategory? categoryToEdit}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        categoryToEdit: categoryToEdit,
        onCategorySaved: (category) {
          if (categoryToEdit != null) {
            // Reemplazar en la lista
            final idx = controller.categories.indexWhere((c) => c.id == categoryToEdit.id);
            if (idx >= 0) {
              controller.categories[idx] = category;
            }
            // Actualizar selección si era la editada
            if (controller.selectedCategory.value?.id == categoryToEdit.id) {
              controller.selectedCategory.value = category;
            }
          } else {
            controller.categories.add(category);
            controller.selectedCategory.value = category;
          }
        },
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        // Convertir color hexadecimal a Color
        final colorString = category.color!.replaceAll('#', '');
        final colorValue = int.parse('FF$colorString', radix: 16);
        return Color(colorValue);
      } catch (e) {
        // Si no se puede parsear el color, usar color por defecto
      }
    }
    
    // Colores por defecto basados en el hash del nombre
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

class _CategoryFormDialog extends StatefulWidget {
  final ExpenseCategory? categoryToEdit;
  final Function(ExpenseCategory) onCategorySaved;

  const _CategoryFormDialog({
    this.categoryToEdit,
    required this.onCategorySaved,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  bool get isEditMode => widget.categoryToEdit != null;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
    Colors.red,
    Colors.cyan,
    Colors.lime,
    Colors.deepPurple,
  ];

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final cat = widget.categoryToEdit!;
      _nameController.text = cat.name;
      _descriptionController.text = cat.description ?? '';
      if (cat.monthlyBudget > 0) {
        _budgetController.text = cat.monthlyBudget.toStringAsFixed(0);
      }
      if (cat.color != null && cat.color!.isNotEmpty) {
        try {
          final colorString = cat.color!.replaceAll('#', '');
          final colorValue = int.parse('FF$colorString', radix: 16);
          final parsed = Color(colorValue);
          // Buscar el color más cercano en la lista
          final match = _availableColors.cast<Color?>().firstWhere(
            (c) => c!.value == parsed.value,
            orElse: () => null,
          );
          if (match != null) _selectedColor = match;
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditMode ? 'Editar Categoría' : 'Nueva Categoría'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Viajes de trabajo',
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'El nombre es requerido';
                  }
                  if (value!.length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Descripción de la categoría',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 16),
              
              // Presupuesto mensual
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Presupuesto Mensual (opcional)',
                  hintText: '0',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.trim().isNotEmpty == true) {
                    final budget = double.tryParse(value!);
                    if (budget == null || budget < 0) {
                      return 'Ingrese un presupuesto válido';
                    }
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Selector de color
              Text(
                'Color',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditMode ? 'Guardar' : 'Crear'),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = Get.find<ExpenseFormController>();
      final colorHex = '#${_selectedColor.value.toRadixString(16).substring(2)}';
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      final budget = double.tryParse(_budgetController.text) ?? 0.0;

      final Either<Failure, ExpenseCategory> result;

      if (isEditMode) {
        result = await controller.updateExpenseCategory(
          categoryId: widget.categoryToEdit!.id,
          name: _nameController.text.trim(),
          description: description,
          color: colorHex,
          monthlyBudget: budget,
        );
      } else {
        result = await controller.createExpenseCategory(
          name: _nameController.text.trim(),
          description: description,
          color: colorHex,
          monthlyBudget: budget,
        );
      }

      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade800,
            icon: const Icon(Icons.error, color: Colors.red),
          );
        },
        (category) {
          widget.onCategorySaved(category);
          Navigator.of(context).pop();

          Get.snackbar(
            isEditMode ? 'Categoría actualizada' : 'Categoría creada',
            isEditMode ? 'Cambios guardados' : 'Categoría creada exitosamente',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade100,
            colorText: Colors.green.shade800,
            icon: const Icon(Icons.check_circle, color: Colors.green),
            duration: const Duration(seconds: 2),
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo guardar la categoría: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}