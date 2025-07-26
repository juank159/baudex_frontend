// lib/features/expenses/presentation/widgets/expense_category_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/expense_categories_controller.dart';
import '../../domain/entities/expense_category.dart';

// Formatter personalizado para montos con formato colombiano
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover todos los caracteres no numéricos excepto coma (para decimales)
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d,]'), '');
    
    // Si hay más de una coma, mantener solo la primera
    List<String> parts = digitsOnly.split(',');
    if (parts.length > 2) {
      digitsOnly = '${parts[0]},${parts.sublist(1).join('')}';
      parts = digitsOnly.split(',');
    }

    // Limitar a 2 decimales después de la coma
    if (parts.length == 2 && parts[1].length > 2) {
      parts[1] = parts[1].substring(0, 2);
      digitsOnly = '${parts[0]},${parts[1]}';
    }

    if (digitsOnly.isEmpty || digitsOnly == ',') {
      return const TextEditingValue();
    }

    // Separar parte entera y decimal
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Formatear la parte entera con puntos como separadores de miles
    if (integerPart.isNotEmpty) {
      // Convertir a número y formatear
      int? intValue = int.tryParse(integerPart);
      if (intValue == null) {
        return oldValue;
      }
      
      // Formatear con puntos como separadores de miles
      integerPart = AppFormatters.formatNumber(intValue);
    }

    // Construir el resultado final
    String formatted = integerPart;
    if (decimalPart != null) {
      formatted += ',$decimalPart';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpenseCategoryFormDialog extends StatefulWidget {
  final ExpenseCategory? category;
  final Function(ExpenseCategory) onCategorySaved;

  const ExpenseCategoryFormDialog({
    super.key,
    this.category,
    required this.onCategorySaved,
  });

  @override
  State<ExpenseCategoryFormDialog> createState() => _ExpenseCategoryFormDialogState();
}

class _ExpenseCategoryFormDialogState extends State<ExpenseCategoryFormDialog> {
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
    Colors.brown,
    Colors.blueGrey,
    Colors.lightGreen,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final category = widget.category!;
    _nameController.text = category.name;
    _descriptionController.text = category.description ?? '';
    _budgetController.text = category.monthlyBudget > 0 
        ? AppFormatters.formatNumber(category.monthlyBudget)
        : '';
    
    // Parse color
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        final colorString = category.color!.replaceAll('#', '');
        final colorValue = int.parse('FF$colorString', radix: 16);
        _selectedColor = Color(colorValue);
      } catch (e) {
        _selectedColor = Colors.blue;
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
    final isEditing = widget.category != null;
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar Categoría' : 'Nueva Categoría',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Form Content - Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          hintText: 'Ej: Viajes de trabajo',
                          prefixIcon: Icon(Icons.label),
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
                      
                      const SizedBox(height: 20),
                      
                      // Descripción
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          hintText: 'Descripción detallada de la categoría',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Presupuesto mensual
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Presupuesto Mensual (opcional)',
                          hintText: '0',
                          prefixText: '\$ ',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          CurrencyInputFormatter(),
                        ],
                        validator: (value) {
                          if (value?.trim().isNotEmpty == true) {
                            final budget = AppFormatters.parseNumber(value!);
                            if (budget == null || budget < 0) {
                              return 'Ingrese un presupuesto válido';
                            }
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Selector de color
                      Text(
                        'Color de la categoría',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Grid de colores con scroll horizontal si es necesario
                      SizedBox(
                        height: MediaQuery.of(context).size.width > 400 ? 120 : 80,
                        child: GridView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 400 ? 8 : 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _availableColors.length,
                          itemBuilder: (context, index) {
                            final color = _availableColors[index];
                            final isSelected = _selectedColor == color;
                            
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = color),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withOpacity(0.5),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
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
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCategory,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Actualizar' : 'Crear'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = Get.find<ExpenseCategoriesController>();
      final isEditing = widget.category != null;
      
      bool success;
      if (isEditing) {
        success = await controller.updateCategory(
          id: widget.category!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
          monthlyBudget: AppFormatters.parseNumber(_budgetController.text) ?? 0.0,
        );
      } else {
        success = await controller.createCategory(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
          monthlyBudget: AppFormatters.parseNumber(_budgetController.text) ?? 0.0,
        );
      }

      if (success) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}