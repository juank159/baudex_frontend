// lib/features/products/presentation/screens/modern_product_form_screen.dart
import 'package:baudex_desktop/features/products/presentation/widgets/modern_selector_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_form_controller.dart';
import '../../domain/entities/product.dart';
import '../widgets/compact_text_field.dart';
import '../widgets/unit_selector_widget.dart';
import '../widgets/modern_category_selector.dart';
import '../../../../app/shared/screens/barcode_scanner_screen.dart';

class ModernProductFormScreen extends GetView<ProductFormController> {
  const ModernProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildModernAppBar(context),
      body: GetBuilder<ProductFormController>(
        builder: (controller) {
          if (controller.isLoading) {
            return LoadingWidget(
              message:
                  controller.isEditMode
                      ? 'Cargando producto...'
                      : 'Preparando formulario...',
            );
          }

          return Form(
            key: controller.formKey,
            child:
                ResponsiveHelper.isMobile(context)
                    ? _buildMobileLayout(context)
                    : _buildDesktopLayout(context),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: GetBuilder<ProductFormController>(
        builder:
            (controller) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    controller.isEditMode ? Icons.edit : Icons.add,
                    size: isMobile ? 18 : 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    controller.pageTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 16 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
      ),
      actions: [
        // Calculadora rápida
        IconButton(
          onPressed: () => controller.showPriceCalculator(),
          icon: const Icon(Icons.calculate, size: 20),
          tooltip: 'Calculadora',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
          ),
        ),

        // Generar SKU
        IconButton(
          onPressed: () => controller.generateSku(),
          icon: const Icon(Icons.auto_fix_high, size: 20),
          tooltip: 'Generar SKU',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
          ),
        ),

        // Previsualizar - Solo desktop/tablet
        if (!isMobile)
          IconButton(
            onPressed: () => controller.previewProduct(),
            icon: const Icon(Icons.visibility, size: 20),
            tooltip: 'Vista previa',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Contenido scrolleable
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100, // Espacio para botones fijos
          ),
          child: Column(
            children: [
              _buildBasicSection(context),
              const SizedBox(height: 16),
              _buildStockSection(context),
              const SizedBox(height: 16),
              _buildPricesSection(context),
              const SizedBox(height: 16),
              _buildDimensionsSection(context), // Movido al final
            ],
          ),
        ),
        // Botones fijos en la parte inferior
        _buildMobileActions(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildBasicSection(context),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStockSection(context)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildDimensionsSection(context)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPricesSection(context),
              ],
            ),
          ),
        ),

        // Panel lateral
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              _buildSidebarHeader(context),
              Expanded(child: _buildSidebarContent(context)),
              _buildSidebarActions(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Información Básica',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nombre y descripción
          CompactTextField(
            controller: controller.nameController,
            label: 'Nombre del Producto',
            hint: 'Ingresa el nombre del producto',
            isRequired: true,
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'El nombre es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CompactTextField(
            controller: controller.descriptionController,
            label: 'Descripción',
            hint: 'Descripción del producto (opcional)',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // SKU y código de barras
          if (ResponsiveHelper.isMobile(context)) ...[
            CompactActionField(
              controller: controller.skuController,
              label: 'SKU',
              hint: 'Código único del producto',
              prefixIcon: Icons.qr_code,
              actionIcon: Icons.auto_fix_high,
              onActionPressed: () => controller.generateSku(),
              isRequired: true,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'El SKU es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CompactActionField(
              controller: controller.barcodeController,
              label: 'Código de Barras',
              hint: 'Código de barras (opcional)',
              prefixIcon: Icons.barcode_reader,
              actionIcon: Icons.qr_code_scanner,
              onActionPressed: () => _scanBarcode(),
              keyboardType: TextInputType.number,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CompactTextField(
                    controller: controller.skuController,
                    label: 'SKU',
                    hint: 'Código único del producto',
                    prefixIcon: Icons.qr_code,
                    isRequired: true,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'El SKU es requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactActionField(
                    controller: controller.barcodeController,
                    label: 'Código de Barras',
                    hint: 'Opcional',
                    prefixIcon: Icons.barcode_reader,
                    actionIcon: Icons.qr_code_scanner,
                    onActionPressed: () => _scanBarcode(),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Tipo, Estado y Categoría
          if (ResponsiveHelper.isMobile(context)) ...[
            _buildTypeSelector(context),
            const SizedBox(height: 16),
            _buildStatusSelector(context),
            const SizedBox(height: 16),
            _buildCategorySelector(context),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildTypeSelector(context)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatusSelector(context)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCategorySelector(context),
          ],
        ],
      ),
    );
  }

  Widget _buildStockSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Stock y Medidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stock actual y mínimo
          if (ResponsiveHelper.isMobile(context)) ...[
            CompactNumberField(
              controller: controller.stockController,
              label: 'Stock Actual',
              hint: '0',
              prefixIcon: Icons.inventory,
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Stock requerido';
                }
                final stock = AppFormatters.parseNumber(value);
                if (stock == null || stock < 0) {
                  return 'Stock inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CompactNumberField(
              controller: controller.minStockController,
              label: 'Stock Mínimo',
              hint: '0',
              prefixIcon: Icons.warning,
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Stock mínimo requerido';
                }
                final minStock = AppFormatters.parseNumber(value);
                if (minStock == null || minStock < 0) {
                  return 'Stock mínimo inválido';
                }
                return null;
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: CompactNumberField(
                    controller: controller.stockController,
                    label: 'Stock Actual',
                    hint: '0',
                    prefixIcon: Icons.inventory,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Stock requerido';
                      }
                      final stock = AppFormatters.parseNumber(value);
                      if (stock == null || stock < 0) {
                        return 'Stock inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactNumberField(
                    controller: controller.minStockController,
                    label: 'Stock Mínimo',
                    hint: '0',
                    prefixIcon: Icons.warning,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Stock mínimo requerido';
                      }
                      final minStock = AppFormatters.parseNumber(value);
                      if (minStock == null || minStock < 0) {
                        return 'Stock mínimo inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Unidad de medida
          GetBuilder<ProductFormController>(
            builder:
                (controller) => EnhancedUnitSelectorWidget(
                  value: controller.selectedUnit,
                  onChanged: (unit) => controller.setSelectedUnit(unit),
                  isRequired: false,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.straighten,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dimensiones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),

          CompactNumberField(
            controller: controller.weightController,
            label: 'Peso',
            hint: '0.0',
            suffix: 'kg',
            prefixIcon: Icons.fitness_center,
            allowDecimals: true,
          ),
          const SizedBox(height: 16),

          CompactNumberField(
            controller: controller.lengthController,
            label: 'Largo',
            hint: '0.0',
            suffix: 'cm',
            prefixIcon: Icons.straighten,
            allowDecimals: true,
          ),
          const SizedBox(height: 16),

          CompactNumberField(
            controller: controller.widthController,
            label: 'Ancho',
            hint: '0.0',
            suffix: 'cm',
            prefixIcon: Icons.straighten,
            allowDecimals: true,
          ),
          const SizedBox(height: 16),

          CompactNumberField(
            controller: controller.heightController,
            label: 'Alto',
            hint: '0.0',
            suffix: 'cm',
            prefixIcon: Icons.straighten,
            allowDecimals: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPricesSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Configuración de Precios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => controller.showPriceCalculator(),
                icon: const Icon(Icons.calculate, size: 20),
                tooltip: 'Calculadora de precios',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Precio de costo
          CompactPriceField(
            controller: controller.costPriceController,
            label: 'Precio de Costo',
            hint: '0',
          ),
          const SizedBox(height: 16),

          // Precios de venta
          if (ResponsiveHelper.isMobile(context)) ...[
            CompactPriceField(
              controller: controller.price1Controller,
              label: 'Precio al Público',
              hint: '0',
            ),
            const SizedBox(height: 16),
            CompactPriceField(
              controller: controller.price2Controller,
              label: 'Precio Mayorista',
              hint: '0',
            ),
            const SizedBox(height: 16),
            CompactPriceField(
              controller: controller.price3Controller,
              label: 'Precio Distribuidor',
              hint: '0',
            ),
            const SizedBox(height: 16),
            CompactPriceField(
              controller: controller.specialPriceController,
              label: 'Precio Especial',
              hint: '0',
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: CompactPriceField(
                    controller: controller.price1Controller,
                    label: 'Precio al Público',
                    hint: '0',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactPriceField(
                    controller: controller.price2Controller,
                    label: 'Precio Mayorista',
                    hint: '0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CompactPriceField(
                    controller: controller.price3Controller,
                    label: 'Precio Distribuidor',
                    hint: '0',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CompactPriceField(
                    controller: controller.specialPriceController,
                    label: 'Precio Especial',
                    hint: '0',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    return GetBuilder<ProductFormController>(
      builder:
          (controller) => ModernSelectorWidget<ProductType>(
            label: 'Tipo de Producto',
            hint: 'Seleccionar tipo',
            value: controller.productType,
            items: ProductType.values,
            getDisplayText:
                (type) => type == ProductType.product ? 'Producto' : 'Servicio',
            getIcon:
                (type) => Icon(
                  type == ProductType.product ? Icons.inventory_2 : Icons.build,
                  size: 18,
                  color:
                      type == ProductType.product ? Colors.blue : Colors.orange,
                ),
            onChanged: (value) => controller.setProductType(value!),
            isRequired: true,
          ),
    );
  }

  Widget _buildStatusSelector(BuildContext context) {
    return GetBuilder<ProductFormController>(
      builder:
          (controller) => ModernSelectorWidget<ProductStatus>(
            label: 'Estado',
            hint: 'Seleccionar estado',
            value: controller.productStatus,
            items: ProductStatus.values,
            getDisplayText:
                (status) =>
                    status == ProductStatus.active ? 'Activo' : 'Inactivo',
            getIcon:
                (status) => Icon(
                  status == ProductStatus.active
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 18,
                  color:
                      status == ProductStatus.active
                          ? Colors.green
                          : Colors.red,
                ),
            onChanged: (value) => controller.setProductStatus(value!),
            isRequired: true,
          ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    return GetBuilder<ProductFormController>(
      builder:
          (controller) => ModernCategorySelector(
            selectedCategoryId: controller.selectedCategoryId,
            selectedCategoryName: controller.selectedCategoryName,
            onCategorySelected: (categoryId, categoryName) {
              controller.setCategorySelection(categoryId, categoryName);
            },
            isRequired: true,
          ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.settings,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Herramientas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          CustomButton(
            text: 'Generar SKU',
            icon: Icons.auto_fix_high,
            type: ButtonType.outline,
            onPressed: () => controller.generateSku(),
            width: double.infinity,
          ),
          const SizedBox(height: 12),

          CustomButton(
            text: 'Calculadora',
            icon: Icons.calculate,
            type: ButtonType.outline,
            onPressed: () => controller.showPriceCalculator(),
            width: double.infinity,
          ),
          const SizedBox(height: 12),

          CustomButton(
            text: 'Vista Previa',
            icon: Icons.visibility,
            type: ButtonType.outline,
            onPressed: () => controller.previewProduct(),
            width: double.infinity,
          ),
          const SizedBox(height: 24),

          const Text(
            'Información',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campos obligatorios:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text('• Nombre del producto', style: TextStyle(fontSize: 11)),
                Text('• SKU único', style: TextStyle(fontSize: 11)),
                Text('• Tipo de producto', style: TextStyle(fontSize: 11)),
                Text('• Estado', style: TextStyle(fontSize: 11)),
                Text('• Stock inicial', style: TextStyle(fontSize: 11)),
                Text('• Categoría', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          GetBuilder<ProductFormController>(
            builder:
                (controller) => CustomButton(
                  text:
                      controller.isSaving
                          ? 'Guardando...'
                          : controller.saveButtonText,
                  icon: controller.isEditMode ? Icons.update : Icons.save,
                  onPressed:
                      controller.isSaving
                          ? null
                          : () => controller.saveProduct(),
                  isLoading: controller.isSaving,
                  width: double.infinity,
                ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Cancelar',
            type: ButtonType.outline,
            onPressed: () => Get.back(),
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActions(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  type: ButtonType.outline,
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: GetBuilder<ProductFormController>(
                  builder:
                      (controller) => CustomButton(
                        text:
                            controller.isSaving
                                ? 'Guardando...'
                                : controller.saveButtonText,
                        icon: controller.isEditMode ? Icons.update : Icons.save,
                        onPressed:
                            controller.isSaving
                                ? null
                                : () => controller.saveProduct(),
                        isLoading: controller.isSaving,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final scannedCode = await Get.to<String>(
        () => const BarcodeScannerScreen(),
      );
      if (scannedCode != null && scannedCode.isNotEmpty) {
        controller.barcodeController.text = scannedCode;
      }
    } catch (e) {
      print('❌ Error al escanear código: $e');
      Get.snackbar(
        'Error',
        'No se pudo escanear el código de barras',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }
}
