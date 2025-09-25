// lib/features/expenses/presentation/screens/expense_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/services/file_service.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../controllers/expense_form_controller.dart';
import '../widgets/expense_category_selector_widget.dart';
import '../../domain/entities/expense.dart';

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

class ExpenseFormScreen extends GetView<ExpenseFormController> {
  const ExpenseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(
        () => Text(controller.isEditMode ? 'Editar Gasto' : 'Nuevo Gasto'),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBackPress(context),
      ),
      actions: [
        // Botón de ayuda
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showHelp(context),
        ),

        // Guardar (solo en desktop/tablet)
        if (!GetPlatform.isMobile)
          Obx(
            () => IconButton(
              icon: const Icon(Icons.save),
              onPressed:
                  controller.canSave ? () => _saveExpense(context) : null,
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildFormContent(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        // Formulario principal
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildFormContent(context),
          ),
        ),

        // Panel lateral con vista previa
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _buildPreviewPanel(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Formulario principal
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildFormContent(context),
            ),
          ),
        ),

        // Panel lateral con vista previa y consejos
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(flex: 2, child: _buildPreviewPanel(context)),
                const Divider(height: 1),
                Expanded(flex: 1, child: _buildTipsPanel(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información básica
          _buildBasicInfoSection(context),

          const SizedBox(height: 24),

          // Detalles del gasto
          _buildExpenseDetailsSection(context),

          const SizedBox(height: 24),

          // Información adicional
          _buildAdditionalInfoSection(context),

          const SizedBox(height: 24),

          // Adjuntos y etiquetas
          _buildAttachmentsSection(context),

          // Espacio para el bottom bar en móvil
          if (GetPlatform.isMobile) const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Básica',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Descripción
            CustomTextField(
              controller: controller.descriptionController,
              label: 'Descripción *',
              hint: 'Ej: Almuerzo de trabajo con cliente',
              maxLines: 2,
              validator: controller.validateDescription,
            ),

            const SizedBox(height: 16),

            // Monto y Fecha - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  // En móvil, mostrar uno debajo del otro
                  CustomTextField(
                    controller: controller.amountController,
                    label: 'Monto *',
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      CurrencyInputFormatter(),
                    ],
                    validator: controller.validateAmount,
                  ),

                  const SizedBox(height: 16),

                  Obx(
                    () => InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha *',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          controller.selectedDate.value != null
                              ? _formatDate(controller.selectedDate.value!)
                              : 'Seleccionar fecha',
                          style:
                              controller.selectedDate.value != null
                                  ? null
                                  : TextStyle(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  // En tablet, mostrar lado a lado
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: controller.amountController,
                      label: 'Monto *',
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: controller.validateAmount,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha *',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            controller.selectedDate.value != null
                                ? _formatDate(controller.selectedDate.value!)
                                : 'Seleccionar fecha',
                            style:
                                controller.selectedDate.value != null
                                    ? null
                                    : TextStyle(
                                      color: Theme.of(context).hintColor,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  // En desktop, mostrar lado a lado
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: controller.amountController,
                      label: 'Monto *',
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: controller.validateAmount,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fecha *',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            controller.selectedDate.value != null
                                ? _formatDate(controller.selectedDate.value!)
                                : 'Seleccionar fecha',
                            style:
                                controller.selectedDate.value != null
                                    ? null
                                    : TextStyle(
                                      color: Theme.of(context).hintColor,
                                    ),
                          ),
                        ),
                      ),
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

  Widget _buildExpenseDetailsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles del Gasto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Categoría
            ExpenseCategorySelectorWidget(controller: controller),

            const SizedBox(height: 16),

            // Tipo y Método de Pago - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  // En móvil, mostrar uno debajo del otro
                  Obx(
                    () => DropdownButtonFormField<ExpenseType>(
                      value: controller.selectedType.value,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Gasto *',
                      ),
                      isExpanded: true, // Importante para evitar overflow
                      items:
                          ExpenseType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(
                                type.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (type) => controller.selectedType.value = type,
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un tipo de gasto';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Obx(
                    () => DropdownButtonFormField<PaymentMethod>(
                      value: controller.selectedPaymentMethod.value,
                      decoration: const InputDecoration(
                        labelText: 'Método de Pago *',
                      ),
                      isExpanded: true, // Importante para evitar overflow
                      items:
                          PaymentMethod.values.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(
                                method.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged:
                          (method) =>
                              controller.selectedPaymentMethod.value = method,
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un método de pago';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  // En tablet, mostrar lado a lado con más espacio
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<ExpenseType>(
                        value: controller.selectedType.value,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Gasto *',
                        ),
                        isExpanded: true,
                        items:
                            ExpenseType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged:
                            (type) => controller.selectedType.value = type,
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione un tipo de gasto';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<PaymentMethod>(
                        value: controller.selectedPaymentMethod.value,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago *',
                        ),
                        isExpanded: true,
                        items:
                            PaymentMethod.values.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(
                                  method.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                        onChanged:
                            (method) =>
                                controller.selectedPaymentMethod.value = method,
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione un método de pago';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  // En desktop, mostrar lado a lado con espacio completo
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<ExpenseType>(
                        value: controller.selectedType.value,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Gasto *',
                        ),
                        isExpanded: true,
                        items:
                            ExpenseType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.displayName),
                              );
                            }).toList(),
                        onChanged:
                            (type) => controller.selectedType.value = type,
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione un tipo de gasto';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<PaymentMethod>(
                        value: controller.selectedPaymentMethod.value,
                        decoration: const InputDecoration(
                          labelText: 'Método de Pago *',
                        ),
                        isExpanded: true,
                        items:
                            PaymentMethod.values.map((method) {
                              return DropdownMenuItem(
                                value: method,
                                child: Text(method.displayName),
                              );
                            }).toList(),
                        onChanged:
                            (method) =>
                                controller.selectedPaymentMethod.value = method,
                        validator: (value) {
                          if (value == null) {
                            return 'Seleccione un método de pago';
                          }
                          return null;
                        },
                      ),
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

  Widget _buildAdditionalInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Adicional',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Proveedor y Número de Factura - Responsive
            ResponsiveLayout(
              mobile: Column(
                children: [
                  // En móvil, mostrar uno debajo del otro
                  CustomTextField(
                    controller: controller.vendorController,
                    label: 'Proveedor/Establecimiento',
                    hint: 'Ej: Restaurante El Buen Sabor',
                    validator: controller.validateVendor,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: controller.invoiceNumberController,
                    label: 'Número de Factura',
                    hint: 'Ej: FAC-001234',
                    validator: controller.validateInvoiceNumber,
                  ),
                ],
              ),
              tablet: Row(
                children: [
                  // En tablet y desktop, mostrar lado a lado
                  Expanded(
                    child: CustomTextField(
                      controller: controller.vendorController,
                      label: 'Proveedor/Establecimiento',
                      hint: 'Ej: Restaurante El Buen Sabor',
                      validator: controller.validateVendor,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: CustomTextField(
                      controller: controller.invoiceNumberController,
                      label: 'Número de Factura',
                      hint: 'Ej: FAC-001234',
                      validator: controller.validateInvoiceNumber,
                    ),
                  ),
                ],
              ),
              desktop: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: controller.vendorController,
                      label: 'Proveedor/Establecimiento',
                      hint: 'Ej: Restaurante El Buen Sabor',
                      validator: controller.validateVendor,
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: CustomTextField(
                      controller: controller.invoiceNumberController,
                      label: 'Número de Factura',
                      hint: 'Ej: FAC-001234',
                      validator: controller.validateInvoiceNumber,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Referencia
            CustomTextField(
              controller: controller.referenceController,
              label: 'Referencia',
              hint: 'Ej: Proyecto ABC - Reunión con cliente',
              validator: controller.validateReference,
            ),

            const SizedBox(height: 16),

            // Notas
            CustomTextField(
              controller: controller.notesController,
              label: 'Notas',
              hint: 'Información adicional sobre el gasto...',
              maxLines: 3,
              validator: controller.validateNotes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjuntos y Etiquetas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Botones para agregar adjuntos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _addAttachment(context),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Agregar Adjunto'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.pickMultipleFiles,
                  icon: const Icon(Icons.file_copy),
                  label: const Text('Múltiples'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Lista de adjuntos
            Obx(() {
              if (controller.attachments.isEmpty) {
                return Text(
                  'Sin adjuntos',
                  style: TextStyle(color: Theme.of(context).hintColor),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    controller.attachments.map((attachment) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // Icono según tipo de archivo
                              Icon(
                                _getFileIcon(attachment),
                                color: _getFileColor(attachment),
                                size: 20,
                              ),
                              const SizedBox(width: 8),

                              // Información del archivo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      attachment.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (attachment.size > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        attachment.sizeFormatted,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Botón eliminar
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed:
                                    () =>
                                        controller.removeAttachment(attachment),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              );
            }),

            const SizedBox(height: 16),

            // Etiquetas
            CustomTextField(
              controller: controller.tagsController,
              label: 'Etiquetas',
              hint: 'viaje, cliente, urgente (separadas por comas)',
              onChanged: controller.updateTags,
            ),

            const SizedBox(height: 8),

            // Vista previa de etiquetas
            Obx(() {
              if (controller.tags.isEmpty) {
                return Text(
                  'Sin etiquetas',
                  style: TextStyle(color: Theme.of(context).hintColor),
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    controller.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                      );
                    }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vista Previa', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          Expanded(
            child: Obx(() {
              final description = controller.descriptionController.text;
              final amount = controller.amountController.text;
              final date = controller.selectedDate.value;

              if (description.isEmpty && amount.isEmpty && date == null) {
                return Center(
                  child: Text(
                    'Complete el formulario para ver la vista previa',
                    style: TextStyle(color: Theme.of(context).hintColor),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (description.isNotEmpty) ...[
                        Text(
                          description,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (amount.isNotEmpty) ...[
                        Text(
                          '\$${_formatCurrency(double.tryParse(amount) ?? 0)}',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (date != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (controller.selectedType.value != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.category,
                              size: 16,
                              color: Theme.of(context).hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              controller.selectedType.value!.displayName,
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Consejos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              children: [
                _buildTip(
                  context,
                  Icons.lightbulb,
                  'Descripción clara',
                  'Use descripciones específicas que identifiquen claramente el gasto.',
                ),
                const SizedBox(height: 12),
                _buildTip(
                  context,
                  Icons.receipt,
                  'Adjunte recibos',
                  'Siempre adjunte el recibo o factura para facilitar la aprobación.',
                ),
                const SizedBox(height: 12),
                _buildTip(
                  context,
                  Icons.speed,
                  'Registro oportuno',
                  'Registre los gastos lo antes posible para no olvidar detalles.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    if (!GetPlatform.isMobile) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              onPressed: () => _handleBackPress(context),
              type: ButtonType.outline,
            ),
          ),
          const SizedBox(width: 16),
          // Si está en modo edición, mostrar solo el botón Actualizar
          if (controller.isEditMode)
            Expanded(
              flex: 2,
              child: Obx(
                () => CustomButton(
                  text: 'Actualizar',
                  onPressed:
                      controller.canSave ? () => _saveExpense(context) : null,
                  isLoading: controller.isSaving,
                ),
              ),
            )
          // Si está creando un nuevo expense, mostrar dos botones
          else ...[
            Expanded(
              child: Obx(
                () => CustomButton(
                  text: 'Borrador',
                  onPressed:
                      controller.canSave
                          ? () => _saveExpenseAsDraft(context)
                          : null,
                  isLoading: controller.isSaving,
                  type: ButtonType.outline,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(
                () => CustomButton(
                  text: 'Guardar',
                  onPressed:
                      controller.canSave ? () => _saveExpense(context) : null,
                  isLoading: controller.isSaving,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Métodos auxiliares
  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      controller.selectedDate.value = date;
    }
  }

  void _addAttachment(BuildContext context) {
    // Implementar selector de archivos
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Get.back();
                  controller.takePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de Galería'),
                onTap: () {
                  Get.back();
                  controller.pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Elegir Archivo'),
                onTap: () {
                  Get.back();
                  controller.pickFile();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _saveExpense(BuildContext context) async {
    // Validar formulario
    if (!controller.formKey.currentState!.validate()) {
      return;
    }

    // Validaciones adicionales para campos no incluidos en el Form
    final dateError = controller.validateDate();
    if (dateError != null) {
      Get.snackbar(
        'Error de Validación',
        dateError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final categoryError = controller.validateCategory();
    if (categoryError != null) {
      Get.snackbar(
        'Error de Validación',
        categoryError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final typeError = controller.validateType();
    if (typeError != null) {
      Get.snackbar(
        'Error de Validación',
        typeError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final paymentMethodError = controller.validatePaymentMethod();
    if (paymentMethodError != null) {
      Get.snackbar(
        'Error de Validación',
        paymentMethodError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    // Intentar guardar
    final success = await controller.saveExpense();
    if (success) {
      // Navegar a la lista de gastos después de crear/actualizar
      Get.offAllNamed(AppRoutes.expenses);
    }
  }

  Future<void> _saveExpenseAsDraft(BuildContext context) async {
    // Validar formulario
    if (!controller.formKey.currentState!.validate()) {
      return;
    }

    // Validaciones adicionales para campos no incluidos en el Form
    final dateError = controller.validateDate();
    if (dateError != null) {
      Get.snackbar(
        'Error de Validación',
        dateError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final categoryError = controller.validateCategory();
    if (categoryError != null) {
      Get.snackbar(
        'Error de Validación',
        categoryError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final typeError = controller.validateType();
    if (typeError != null) {
      Get.snackbar(
        'Error de Validación',
        typeError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final paymentMethodError = controller.validatePaymentMethod();
    if (paymentMethodError != null) {
      Get.snackbar(
        'Error de Validación',
        paymentMethodError,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    // Intentar guardar como borrador
    final success = await controller.saveExpenseAsDraft();
    if (success) {
      // Navegar a la lista de gastos después de crear como borrador
      Get.offAllNamed(AppRoutes.expenses);
    }
  }

  void _handleBackPress(BuildContext context) {
    if (controller.hasUnsavedChanges) {
      Get.dialog(
        AlertDialog(
          title: const Text('Descartar Cambios'),
          content: const Text(
            '¿Está seguro que desea salir? Los cambios no guardados se perderán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Get.back(); // Cerrar diálogo
                Get.back(); // Cerrar pantalla
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
    } else {
      Get.back();
    }
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ayuda - Registro de Gastos'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '• Descripción: Sea específico sobre el gasto realizado\n\n'
                    '• Monto: Ingrese el valor total del gasto\n\n'
                    '• Fecha: Seleccione la fecha real del gasto\n\n'
                    '• Categoría: Elija la categoría que mejor describe el gasto\n\n'
                    '• Adjuntos: Incluya siempre el recibo o factura\n\n'
                    '• Etiquetas: Use palabras clave para facilitar la búsqueda',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  IconData _getFileIcon(attachment) {
    if (attachment.isImage) {
      return Icons.image;
    } else if (attachment.isPDF) {
      return Icons.picture_as_pdf;
    } else if (attachment.isDocument) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(attachment) {
    if (attachment.isImage) {
      return Colors.green;
    } else if (attachment.isPDF) {
      return Colors.red;
    } else if (attachment.isDocument) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
}
