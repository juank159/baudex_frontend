// lib/features/products/presentation/screens/product_form_screen.dart
import 'package:baudex_desktop/features/products/presentation/widgets/category_selector_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_form_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/tax_enums.dart';
import '../widgets/compact_text_field.dart';
import '../widgets/unit_selector_widget.dart';
import '../widgets/modern_selector_widget.dart';

// Importa la pantalla del escáner de código de barras
import 'package:baudex_desktop/app/shared/screens/barcode_scanner_screen.dart';

// Formatter para precios con separadores de miles
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el nuevo valor está vacío, devolver tal como está
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover todos los caracteres que no sean dígitos
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Si no hay dígitos, devolver vacío
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Evitar ceros a la izquierda innecesarios
    digitsOnly = digitsOnly.replaceAll(RegExp(r'^0+'), '');
    if (digitsOnly.isEmpty) {
      digitsOnly = '0';
    }

    // Convertir a número y formatear
    final number = int.parse(digitsOnly);
    final formatted = AppFormatters.formatNumber(number);

    // El cursor siempre va al final
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ProductFormScreen extends GetView<ProductFormController> {
  const ProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🖼️ ProductFormScreen: Construyendo pantalla...');
    print('DEBUG: context.isMobile es: ${context.isMobile}');

    return Scaffold(
      appBar: _buildAppBar(context),
      resizeToAvoidBottomInset:
          false, // ✅ Evita que los botones se oculten con el teclado
      body: GetBuilder<ProductFormController>(
        builder: (controller) {
          print(
            '🔄 ProductFormScreen: Reconstruyendo body - isLoading: ${controller.isLoading}',
          );

          if (controller.isLoading) {
            return LoadingWidget(
              message:
                  controller.isEditMode
                      ? 'Cargando producto...'
                      : 'Preparando formulario...',
            );
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(context),
            tablet: _buildTabletLayout(context),
            desktop: _buildDesktopLayout(context),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      title: GetBuilder<ProductFormController>(
        builder:
            (controller) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
        // Previsualizar - Solo desktop/tablet
        if (!isMobile)
          IconButton(
            onPressed: () => controller.previewProduct(),
            icon: const Icon(Icons.visibility, size: 20),
            tooltip: 'Vista previa',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
            ),
          ),

        // Menú compacto
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            foregroundColor: Colors.white,
          ),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder:
              (context) => [
                if (!controller.isEditMode)
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Limpiar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'generate_sku',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.successGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.auto_fix_high,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Generar SKU',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'scan_barcode',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.warningGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Escanear código',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
        Expanded(
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.isMobile ? 16.0 : 20.0),
              child: Column(
                children: [
                  // Información básica
                  _buildBasicInfoSection(context),
                  SizedBox(height: context.verticalSpacing),

                  // Stock y medidas en mobile
                  _buildStockSection(context),
                  SizedBox(height: context.verticalSpacing),

                  // Precios
                  _buildPricesSection(context),
                  SizedBox(height: context.verticalSpacing),

                  // ========== FACTURACIÓN ELECTRÓNICA ==========
                  _buildTaxSection(context),
                  SizedBox(height: context.verticalSpacing),
                  // ========== FIN FACTURACIÓN ELECTRÓNICA ==========

                  // Espaciado adicional para el teclado
                  SizedBox(height: context.verticalSpacing * 2),

                  // Dimensiones en móvil
                  _buildDimensionsSection(context),
                  SizedBox(height: context.verticalSpacing),
                ],
              ),
            ),
          ),
        ),
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: AdaptiveContainer(
                maxWidth: 1000, // Aumentado para tablet
                child: Column(
                  children: [
                    SizedBox(height: context.verticalSpacing),

                    // Información básica
                    FuturisticContainer(
                      padding: const EdgeInsets.all(20),
                      hasGlow: true,
                      child: _buildBasicInfoContent(context),
                    ),
                    SizedBox(height: context.verticalSpacing),

                    // Stock y dimensiones en dos columnas para tablet
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 1,
                            child: FuturisticContainer(
                        padding: const EdgeInsets.all(20),
                        child: _buildStockContent(context),
                      ),
                    ),
                    SizedBox(width: context.horizontalSpacing),
                    Expanded(
                      flex: 1,
                      child: FuturisticContainer(
                        padding: const EdgeInsets.all(20),
                        child: _buildDimensionsContent(context),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.verticalSpacing),

              // Precios
              FuturisticContainer(
                padding: const EdgeInsets.all(20),
                hasGlow: true,
                child: _buildPricesContent(context),
              ),
              SizedBox(height: context.verticalSpacing),

              // ========== FACTURACIÓN ELECTRÓNICA ==========
              FuturisticContainer(
                padding: const EdgeInsets.all(20),
                hasGlow: true,
                child: _buildTaxContent(context),
              ),
              SizedBox(height: context.verticalSpacing),
              // ========== FIN FACTURACIÓN ELECTRÓNICA ==========
            ],
          ),
        ),
      ),
    ),
  ),
  _buildBottomActions(context),
],
);
}


  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Contenido principal - Más ancho
        Expanded(
          flex: 3, // Aumentado de 2 a 3
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.horizontalSpacing * 1.5),
              child: Column(
                children: [
                  // Información básica
                  FuturisticContainer(
                    padding: const EdgeInsets.all(20),
                    hasGlow: true,
                    child: _buildBasicInfoContent(context),
                  ),
                  SizedBox(height: context.verticalSpacing),

                  // Stock y dimensiones en desktop
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: FuturisticContainer(
                          padding: const EdgeInsets.all(20),
                          child: _buildStockContent(context),
                        ),
                      ),
                      SizedBox(width: context.horizontalSpacing),
                      Expanded(
                        flex: 1,
                        child: FuturisticContainer(
                          padding: const EdgeInsets.all(20),
                          child: _buildDimensionsContent(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.verticalSpacing),

                  // Precios
                  FuturisticContainer(
                    padding: const EdgeInsets.all(20),
                    hasGlow: true,
                    child: _buildPricesContent(context),
                  ),
                  SizedBox(height: context.verticalSpacing),

                  // ========== FACTURACIÓN ELECTRÓNICA ==========
                  FuturisticContainer(
                    padding: const EdgeInsets.all(20),
                    hasGlow: true,
                    child: _buildTaxContent(context),
                  ),
                  SizedBox(height: context.verticalSpacing),
                  // ========== FIN FACTURACIÓN ELECTRÓNICA ==========
                ],
              ),
            ),
          ),
        ),

        // Panel lateral - Más compacto
        Container(
          width: MediaQuery.of(context).size.width * 0.25, // Responsive width
          constraints: const BoxConstraints(minWidth: 280, maxWidth: 350),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            border: Border(
              left: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header del panel
              Container(
                padding: EdgeInsets.all(context.horizontalSpacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                      ElegantLightTheme.primaryBlueLight.withValues(
                        alpha: 0.05,
                      ),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: ElegantLightTheme.textTertiary.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Configuración',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.primaryBlue,
                          fontSize: Responsive.getFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido del panel
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(context.horizontalSpacing),
                  child: _buildSidebarContent(context),
                ),
              ),

              // Acciones en el panel
              Padding(
                padding: EdgeInsets.all(context.horizontalSpacing),
                child: _buildSidebarActions(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== SECTIONS ====================

  Widget _buildBasicInfoSection(BuildContext context) {
    return FuturisticContainer(
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      hasGlow: true,
      child: _buildBasicInfoContent(context),
    );
  }

  Widget _buildBasicInfoContent(BuildContext context) {
    final compactSpacing =
        context.isMobile
            ? context.verticalSpacing * 0.6
            : context.verticalSpacing * 0.75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: compactSpacing),

        // Nombre del producto
        CustomTextField(
          controller: controller.nameController,
          label: 'Nombre del Producto *',
          hint: 'Ingresa el nombre del producto',
          prefixIcon: Icons.inventory_2,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El nombre es requerido';
            }
            return null;
          },
        ),
        SizedBox(height: compactSpacing),

        // Descripción - Ahora en ExpansionTile para ahorrar espacio
        if (context.isMobile)
          ExpansionTile(
            title: const Text(
              'Descripción (Opcional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
            children: [
              CustomTextField(
                controller: controller.descriptionController,
                label: 'Descripción',
                hint: 'Descripción detallada del producto',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
            ],
          )
        else
          CustomTextField(
            controller: controller.descriptionController,
            label: 'Descripción',
            hint: 'Descripción detallada del producto',
            prefixIcon: Icons.description,
            maxLines: 2,
          ),
        SizedBox(height: compactSpacing),

        // SKU y Código de barras - Responsive
        if (context.isMobile) ...[
          // En móvil: columna
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: controller.skuController,
                  label: 'SKU *',
                  hint: 'Código único',
                  prefixIcon: Icons.qr_code,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'El SKU es requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElegantButton(
                    text: 'Auto',
                    icon: Icons.auto_fix_high,
                    gradient: ElegantLightTheme.infoGradient,
                    height: 48,
                    onPressed: () {
                      try {
                        controller.generateSku();
                      } catch (e) {
                        print('❌ Error al generar SKU: $e');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // En tablet/desktop: fila
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: controller.skuController,
                  label: 'SKU *',
                  hint: 'Código único del producto',
                  prefixIcon: Icons.qr_code,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'El SKU es requerido';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: context.horizontalSpacing * 0.5),
              SizedBox(
                width: Responsive.isTablet(context) ? 120 : 140,
                child: ElegantButton(
                  text: 'Auto',
                  icon: Icons.auto_fix_high,
                  gradient: ElegantLightTheme.infoGradient,
                  onPressed: () {
                    try {
                      controller.generateSku();
                    } catch (e) {
                      print('❌ Error al generar SKU: $e');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: compactSpacing),

        // Código de barras con escáner
        CustomTextField(
          controller: controller.barcodeController,
          label: 'Código de Barras',
          hint: 'Código de barras del producto',
          prefixIcon: Icons.barcode_reader,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return controller.validateBarcode(value)
                  ? null
                  : 'Código de barras inválido';
            }
            return null;
          },
          suffixIcon: context.isMobile ? Icons.qr_code_scanner : null,
          onSuffixIconPressed:
              context.isMobile
                  ? () async {
                    final scannedCode = await Get.to<String>(
                      () => const BarcodeScannerScreen(),
                    );
                    if (scannedCode != null) {
                      controller.barcodeController.text = scannedCode;
                    }
                  }
                  : null,
        ),
        SizedBox(height: compactSpacing),

        // Tipo y Estado - ExpansionTile en móvil, Row en tablet/desktop
        if (context.isMobile) ...[
          // En móvil: Selector colapsado combinado
          ExpansionTile(
            title: Row(
              children: [
                Icon(Icons.settings, size: 18, color: ElegantLightTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Tipo y Estado',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            children: [
              SafeArea(
                minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    _buildTypeSelector(context),
                    const SizedBox(height: 12),
                    _buildStatusSelector(context),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          // En tablet/desktop: Fila
          Row(
            children: [
              Expanded(child: _buildTypeSelector(context)),
              SizedBox(width: context.horizontalSpacing),
              Expanded(child: _buildStatusSelector(context)),
            ],
          ),
        ],
        SizedBox(height: compactSpacing),

        // Categoría
        _buildCategorySelector(context),
      ],
    );
  }

  Widget _buildStockSection(BuildContext context) {
    return FuturisticContainer(
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      hasGlow: true,
      child: _buildStockContent(context),
    );
  }

  Widget _buildStockContent(BuildContext context) {
    final compactSpacing =
        context.isMobile
            ? context.verticalSpacing * 0.6
            : context.verticalSpacing * 0.75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestión de Stock',
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: compactSpacing),

        // Stock actual y mínimo - Responsive
        if (context.isMobile) ...[
          // En móvil: columna
          CustomTextField(
            controller: controller.stockController,
            label: 'Stock Actual *',
            hint: '0',
            prefixIcon: Icons.inventory,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
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
          SizedBox(height: compactSpacing),
          CustomTextField(
            controller: controller.minStockController,
            label: 'Stock Mínimo *',
            hint: '0',
            prefixIcon: Icons.warning,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
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
          // En tablet/desktop: fila
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.stockController,
                  label: 'Stock Actual *',
                  hint: '0',
                  prefixIcon: Icons.inventory,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
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
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                child: CustomTextField(
                  controller: controller.minStockController,
                  label: 'Stock Mínimo *',
                  hint: '0',
                  prefixIcon: Icons.warning,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
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
        SizedBox(height: compactSpacing),

        // Unidad de medida - Selector moderno
        GetBuilder<ProductFormController>(
          builder:
              (controller) => EnhancedUnitSelectorWidget(
                value: controller.selectedUnit,
                onChanged: (unit) => controller.setSelectedUnit(unit),
                isRequired: false,
              ),
        ),
      ],
    );
  }

  // Nueva sección de dimensiones para móvil
  Widget _buildDimensionsSection(BuildContext context) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: _buildDimensionsContent(context),
    );
  }

  Widget _buildDimensionsContent(BuildContext context) {
    return GetBuilder<ProductFormController>(
      builder:
          (controller) => ExpansionTile(
            title: Text(
              'Dimensiones y Peso',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: const Icon(Icons.straighten),
            initiallyExpanded: false,
            childrenPadding: EdgeInsets.symmetric(
              horizontal: context.horizontalSpacing,
              vertical: context.verticalSpacing * 0.5,
            ),
            children: [
              // Peso
              CustomTextField(
                controller: controller.weightController,
                label: 'Peso (kg)',
                hint: '0.00',
                prefixIcon: Icons.fitness_center,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: context.verticalSpacing),

              // Dimensiones - Responsive
              if (context.isMobile) ...[
                // En móvil: una por fila
                CustomTextField(
                  controller: controller.lengthController,
                  label: 'Largo (cm)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: context.verticalSpacing * 0.75),
                CustomTextField(
                  controller: controller.widthController,
                  label: 'Ancho (cm)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: context.verticalSpacing * 0.75),
                CustomTextField(
                  controller: controller.heightController,
                  label: 'Alto (cm)',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ] else ...[
                // En tablet/desktop: tres columnas
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: controller.lengthController,
                        label: 'Largo (cm)',
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: context.horizontalSpacing * 0.5),
                    Expanded(
                      child: CustomTextField(
                        controller: controller.widthController,
                        label: 'Ancho (cm)',
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: context.horizontalSpacing * 0.5),
                    Expanded(
                      child: CustomTextField(
                        controller: controller.heightController,
                        label: 'Alto (cm)',
                        hint: '0.00',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
    );
  }

  Widget _buildPricesSection(BuildContext context) {
    return FuturisticContainer(
      padding: EdgeInsets.all(context.isMobile ? 16 : 20),
      hasGlow: true,
      child: _buildPricesContent(context),
    );
  }

  Widget _buildPricesContent(BuildContext context) {
    final compactSpacing =
        context.isMobile
            ? context.verticalSpacing * 0.6
            : context.verticalSpacing * 0.75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header responsive
        if (context.isMobile) ...[
          // En móvil: columna
          Text(
            'Precios',
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 16,
                tablet: 18,
                desktop: 20,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: compactSpacing),
          ElegantButton(
            text: 'Calculadora de Precios',
            icon: Icons.calculate,
            gradient: ElegantLightTheme.warningGradient,
            onPressed: () {
              try {
                controller.showPriceCalculator();
              } catch (e) {
                print('❌ Error en calculadora: $e');
              }
            },
            width: double.infinity,
            height: 44,
          ),
        ] else ...[
          // En tablet/desktop: fila
          Row(
            children: [
              Expanded(
                child: Text(
                  'Precios',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElegantButton(
                text:
                    Responsive.isTablet(context)
                        ? 'Calculadora'
                        : 'Calculadora de Precios',
                icon: Icons.calculate,
                gradient: ElegantLightTheme.warningGradient,
                onPressed: () {
                  try {
                    controller.showPriceCalculator();
                  } catch (e) {
                    print('❌ Error en calculadora: $e');
                  }
                },
              ),
            ],
          ),
        ],
        SizedBox(height: compactSpacing),

        // Precio de costo
        CustomTextField(
          controller: controller.costPriceController,
          label: 'Precio de Costo',
          hint: '0',
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
        ),
        SizedBox(height: compactSpacing),

        // Precios de venta - Responsive
        if (context.isMobile) ...[
          // En móvil: dos por fila para ahorrar espacio
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.price1Controller,
                  label: 'Precio Público',
                  hint: '0',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextField(
                  controller: controller.price2Controller,
                  label: 'Mayorista',
                  hint: '0',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
            ],
          ),
          SizedBox(height: compactSpacing),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.price3Controller,
                  label: 'Distribuidor',
                  hint: '0',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomTextField(
                  controller: controller.specialPriceController,
                  label: 'Especial',
                  hint: '0',
                  prefixIcon: Icons.local_offer,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
            ],
          ),
        ] else ...[
          // En tablet/desktop: dos por fila
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.price1Controller,
                  label: 'Precio al Público',
                  hint: '0',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                child: CustomTextField(
                  controller: controller.price2Controller,
                  label: 'Precio Mayorista',
                  hint: '0',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
            ],
          ),
          SizedBox(height: context.verticalSpacing),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.price3Controller,
                  label: 'Precio Distribuidor',
                  hint: '0',
                  prefixIcon: Icons.sell,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
              SizedBox(width: context.horizontalSpacing),
              Expanded(
                child: CustomTextField(
                  controller: controller.specialPriceController,
                  label: 'Precio Especial',
                  hint: '0',
                  prefixIcon: Icons.local_offer,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                ),
              ),
            ],
          ),
        ],

        // Información de márgenes
        _buildMarginInfo(context),
      ],
    );
  }

  Widget _buildMarginInfo(BuildContext context) {
    final costText = controller.costPriceController.text;
    final sellText = controller.price1Controller.text;

    if (costText.isEmpty || sellText.isEmpty) {
      return const SizedBox.shrink();
    }

    final costPrice = double.tryParse(costText) ?? 0;
    final sellPrice = double.tryParse(sellText) ?? 0;
    final margin = controller.calculateMargin(costPrice, sellPrice);

    return Container(
      margin: EdgeInsets.only(top: context.verticalSpacing),
      padding: EdgeInsets.all(context.horizontalSpacing * 0.75),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ElegantLightTheme.successGradient.colors.first.withValues(
              alpha: 0.1,
            ),
            ElegantLightTheme.successGradient.colors.last.withValues(
              alpha: 0.05,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.successGradient.colors.first.withValues(
            alpha: 0.3,
          ),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ElegantLightTheme.successGradient.colors.first.withValues(
              alpha: 0.1,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.successGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.trending_up, color: Colors.white, size: 18),
          ),
          SizedBox(width: context.horizontalSpacing * 0.5),
          Expanded(
            child: Text(
              'Margen de ganancia: ${margin.toStringAsFixed(1)}%',
              style: TextStyle(
                color: ElegantLightTheme.successGradient.colors.last,
                fontWeight: FontWeight.w600,
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SELECTORS ====================

  Widget _buildTypeSelector(BuildContext context) {
    return GetBuilder<ProductFormController>(
      builder:
          (controller) => ModernSelectorWidget<ProductType>(
            label: 'Tipo',
            hint: 'Seleccionar tipo',
            value: controller.productType,
            items: ProductType.values,
            getDisplayText: (type) => _getTypeDisplayName(type),
            getIcon:
                (type) => Icon(
                  _getTypeIcon(type),
                  size: 18,
                  color: _getTypeColor(type),
                ),
            onChanged: (value) {
              if (value != null) {
                try {
                  controller.setProductType(value);
                } catch (e) {
                  print('❌ Error al cambiar tipo: $e');
                }
              }
            },
            isRequired: true,
            validator: (value) => value == null ? 'Selecciona un tipo' : null,
          ),
    );
  }

  IconData _getTypeIcon(ProductType type) {
    switch (type) {
      case ProductType.product:
        return Icons.inventory_2;
      case ProductType.service:
        return Icons.design_services;
    }
  }

  Color _getTypeColor(ProductType type) {
    switch (type) {
      case ProductType.product:
        return ElegantLightTheme.primaryBlue;
      case ProductType.service:
        return Colors.purple.shade600;
    }
  }

  Widget _buildStatusSelector(BuildContext context) {
    return GetBuilder<ProductFormController>(
      id: 'status_selector', // ✅ ID específico para actualizaciones
      builder: (controller) {
        print(
          '🔄 StatusSelector: Rebuilding with status: ${controller.productStatus}',
        );
        return ModernSelectorWidget<ProductStatus>(
          key: ValueKey('status_${controller.productStatus}'), // ✅ Key único
          label: 'Estado',
          hint: 'Seleccionar estado',
          value: controller.productStatus,
          items: ProductStatus.values,
          getDisplayText: (status) => _getStatusDisplayName(status),
          getIcon:
              (status) => Icon(
                _getStatusIcon(status),
                size: 18,
                color: _getStatusColor(status),
              ),
          onChanged: (value) {
            if (value != null) {
              try {
                controller.setProductStatus(value);
              } catch (e) {
                print('❌ Error al cambiar estado: $e');
              }
            }
          },
          isRequired: true,
        );
      },
    );
  }

  IconData _getStatusIcon(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return Icons.check_circle;
      case ProductStatus.inactive:
        return Icons.cancel;
      case ProductStatus.outOfStock:
        return Icons.inventory_outlined;
    }
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return Colors.green.shade600;
      case ProductStatus.inactive:
        return Colors.grey.shade600;
      case ProductStatus.outOfStock:
        return Colors.orange.shade600;
    }
  }

  Widget _buildCategorySelector(BuildContext context) {
    print('🔧 ProductFormScreen: Construyendo selector de categorías');

    return GetBuilder<ProductFormController>(
      builder: (controller) {
        print('   selectedCategoryId: ${controller.selectedCategoryId}');
        print('   selectedCategoryName: ${controller.selectedCategoryName}');

        return CategorySelectorWidget(
          selectedCategoryId: controller.selectedCategoryId,
          selectedCategoryName: controller.selectedCategoryName,
          onCategorySelected: (categoryId, categoryName) {
            print('🎯 Categoría seleccionada: $categoryName ($categoryId)');
            controller.setCategorySelection(categoryId, categoryName);
            // Force UI update to show selection immediately
            controller.update();
          },
          label: 'Categoría',
          hint: 'Seleccionar categoría',
          isRequired: true,
        );
      },
    );
  }

  // ==================== SIDEBAR ====================

  Widget _buildSidebarContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Herramientas',
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 16,
                tablet: 16,
                desktop: 16,
              ),
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          SizedBox(height: context.verticalSpacing),

          ElegantButton(
            text: 'Generar SKU',
            icon: Icons.auto_fix_high,
            gradient: ElegantLightTheme.infoGradient,
            onPressed: () {
              try {
                controller.generateSku();
              } catch (e) {
                print('❌ Error al generar SKU: $e');
              }
            },
            width: double.infinity,
          ),
          SizedBox(height: context.verticalSpacing * 0.75),

          ElegantButton(
            text: 'Calculadora de Precios',
            icon: Icons.calculate,
            gradient: ElegantLightTheme.warningGradient,
            onPressed: () {
              try {
                controller.showPriceCalculator();
              } catch (e) {
                print('❌ Error en calculadora: $e');
              }
            },
            width: double.infinity,
          ),
          SizedBox(height: context.verticalSpacing * 0.75),

          ElegantButton(
            text: 'Previsualizar',
            icon: Icons.preview,
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade600],
            ),
            onPressed: () {
              try {
                controller.previewProduct();
              } catch (e) {
                print('❌ Error en previsualizar: $e');
              }
            },
            width: double.infinity,
          ),

          SizedBox(height: context.verticalSpacing * 1.5),
          const Divider(),
          SizedBox(height: context.verticalSpacing),

          Text(
            'Información',
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 14,
                tablet: 14,
                desktop: 14,
              ),
              fontWeight: FontWeight.w600,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
          SizedBox(height: context.verticalSpacing * 0.75),

          FuturisticContainer(
            padding: EdgeInsets.all(context.horizontalSpacing * 0.75),
            gradient: ElegantLightTheme.cardGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campos requeridos:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Nombre del producto',
                  style: TextStyle(fontSize: 12),
                ),
                const Text('• SKU único', style: TextStyle(fontSize: 12)),
                const Text(
                  '• Tipo de producto',
                  style: TextStyle(fontSize: 12),
                ),
                const Text('• Categoría', style: TextStyle(fontSize: 12)),
                const Text('• Stock inicial', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarActions(BuildContext context) {
    return Column(
      children: [
        GetBuilder<ProductFormController>(
          builder:
              (controller) => ElegantButton(
                text:
                    controller.isSaving
                        ? 'Guardando...'
                        : controller.saveButtonText,
                icon: controller.isEditMode ? Icons.update : Icons.save,
                gradient: ElegantLightTheme.successGradient,
                onPressed:
                    controller.isSaving
                        ? null
                        : () {
                          try {
                            controller.saveProduct();
                          } catch (e) {
                            print('❌ Error al guardar: $e');
                          }
                        },
                isLoading: controller.isSaving,
                width: double.infinity,
              ),
        ),
        SizedBox(height: context.verticalSpacing * 0.75),
        ElegantButton(
          text: 'Cancelar',
          icon: Icons.close,
          gradient: LinearGradient(
            colors: [Colors.grey.shade400, Colors.grey.shade600],
          ),
          onPressed: () => Get.back(),
          width: double.infinity,
        ),
      ],
    );
  }

  // ==================== ACTIONS ====================

  Widget _buildTabletActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElegantButton(
            text: 'Cancelar',
            icon: Icons.close,
            gradient: LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade600],
            ),
            onPressed: () => Get.back(),
          ),
        ),
        SizedBox(width: context.horizontalSpacing),
        Expanded(
          flex: 2,
          child: GetBuilder<ProductFormController>(
            builder:
                (controller) => ElegantButton(
                  text:
                      controller.isSaving
                          ? 'Guardando...'
                          : controller.saveButtonText,
                  icon: controller.isEditMode ? Icons.update : Icons.save,
                  gradient: ElegantLightTheme.successGradient,
                  onPressed:
                      controller.isSaving
                          ? null
                          : () {
                            try {
                              controller.saveProduct();
                            } catch (e) {
                              print('❌ Error al guardar: $e');
                            }
                          },
                  isLoading: controller.isSaving,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : context.responsivePadding.horizontal),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElegantButton(
                text: 'Cancelar',
                icon: Icons.close,
                height: isMobile ? 44 : 48,
                gradient: LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade600],
                ),
                onPressed: () => Get.back(),
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: GetBuilder<ProductFormController>(
                builder:
                    (controller) => ElegantButton(
                      text: controller.isSaving ? 'Guardando...' : 'Guardar',
                      icon: controller.isEditMode ? Icons.update : Icons.save,
                      height: isMobile ? 44 : 48,
                      gradient: ElegantLightTheme.successGradient,
                      onPressed:
                          controller.isSaving
                              ? null
                              : () {
                                try {
                                  controller.saveProduct();
                                } catch (e) {
                                  print('❌ Error al guardar: $e');
                                }
                              },
                      isLoading: controller.isSaving,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    try {
      switch (action) {
        case 'clear':
          _showClearConfirmation(context);
          break;
        case 'preview':
          controller.previewProduct();
          break;
        case 'calculator':
          controller.showPriceCalculator();
          break;
        case 'generate_sku':
          controller.generateSku();
          break;
        case 'scan_barcode':
          _scanBarcode(context);
          break;
      }
    } catch (e) {
      print('❌ Error en acción del menú: $e');
    }
  }

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      final scannedCode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );
      if (scannedCode != null && scannedCode.isNotEmpty) {
        controller.barcodeController.text = scannedCode;
      }
    } catch (e) {
      print('❌ Error al escanear código: $e');
    }
  }

  void _showClearConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Limpiar Formulario'),
        content: const Text(
          '¿Estás seguro que deseas limpiar todos los campos?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              try {
                controller.clearForm();
              } catch (e) {
                print('❌ Error al limpiar formulario: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  // ========== SECCIÓN DE FACTURACIÓN ELECTRÓNICA ==========

  /// Sección de impuestos para móvil
  Widget _buildTaxSection(BuildContext context) {
    return FuturisticContainer(
      padding: const EdgeInsets.all(16),
      hasGlow: true,
      child: _buildTaxContent(context),
    );
  }

  /// Contenido de impuestos para todas las plataformas
  Widget _buildTaxContent(BuildContext context) {
    final compactSpacing = context.verticalSpacing * 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: ElegantLightTheme.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Facturación Electrónica',
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 17, desktop: 18),
                fontWeight: FontWeight.bold,
                color: ElegantLightTheme.primaryBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: compactSpacing * 1.5),

        // Categoría de impuesto (selector elegante)
        GetBuilder<ProductFormController>(
          id: 'tax_selector',
          builder: (controller) {
            return ModernSelectorWidget<TaxCategory>(
              label: 'Categoría de Impuesto',
              hint: 'Seleccionar categoría de impuesto',
              value: controller.selectedTaxCategory,
              items: TaxCategory.values,
              getDisplayText: (category) => category.displayName,
              getIcon: (category) => Icon(
                Icons.monetization_on,
                size: 18,
                color: _getTaxCategoryColor(category),
              ),
              onChanged: (value) => controller.setTaxCategory(value!),
            );
          },
        ),
        SizedBox(height: compactSpacing * 1.5),

        // Fila: Tasa de impuesto y Toggle gravable
        Builder(
          builder: (context) {
            final isMobile = ResponsiveHelper.isMobile(context);
            return Row(
              children: [
                Expanded(
                  flex: isMobile ? 2 : 1,
                  child: CustomTextField(
                    controller: controller.taxRateController,
                    label: 'Tasa (%)',
                    hint: 'Ej: 19',
                    prefixIcon: Icons.percent,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      final rate = double.tryParse(value);
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Ingrese tasa válida (0-100)';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.horizontalSpacing),
                Expanded(
                  flex: isMobile ? 3 : 1,
                  child: GetBuilder<ProductFormController>(
                id: 'tax_section',
                builder: (controller) {
                  final isMobile = ResponsiveHelper.isMobile(context);
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.isTaxable
                            ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isMobile ? 4 : 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_box_outlined,
                          color: controller.isTaxable
                              ? ElegantLightTheme.primaryBlue
                              : Colors.grey.shade400,
                          size: isMobile ? 16 : 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Gravable',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Transform.scale(
                          scale: isMobile ? 0.75 : 0.85,
                          child: Switch(
                            value: controller.isTaxable,
                            onChanged: controller.setTaxable,
                            activeColor: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
          },
        ),
        SizedBox(height: compactSpacing),

        // Descripción del impuesto (opcional)
        CompactTextField(
          controller: controller.taxDescriptionController,
          label: 'Descripción del Impuesto (opcional)',
          maxLines: 2,
          prefixIcon: Icons.description,
        ),
        SizedBox(height: compactSpacing * 1.5),

        // Divisor
        Divider(color: Colors.grey.shade300, height: 1),
        SizedBox(height: compactSpacing * 1.5),

        // Sección de retenciones
        GetBuilder<ProductFormController>(
          id: 'retention_section',
          builder: (controller) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle de retención
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.hasRetention
                          ? ElegantLightTheme.accentOrange.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 18,
                          color: controller.hasRetention
                              ? ElegantLightTheme.accentOrange
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Aplica Retención en la Fuente',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                context,
                                mobile: 12,
                                tablet: 14,
                                desktop: 14,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    value: controller.hasRetention,
                    onChanged: controller.setHasRetention,
                    activeColor: ElegantLightTheme.accentOrange,
                  ),
                ),

                // Campos de retención (solo si está habilitada)
                if (controller.hasRetention) ...[
                  SizedBox(height: compactSpacing),
                  GetBuilder<ProductFormController>(
                    id: 'retention_selector',
                    builder: (controller) {
                      return ModernSelectorWidget<RetentionCategory>(
                        label: 'Tipo de Retención',
                        hint: 'Seleccionar tipo de retención',
                        value: controller.selectedRetentionCategory,
                        items: RetentionCategory.values,
                        getDisplayText: (category) => category.displayName,
                        getIcon: (category) => Icon(
                          Icons.account_balance,
                          size: 18,
                          color: ElegantLightTheme.accentOrange,
                        ),
                        onChanged: (value) => controller.setRetentionCategory(value),
                      );
                    },
                  ),
                  SizedBox(height: compactSpacing),
                  CompactTextField(
                    controller: controller.retentionRateController,
                    label: 'Tasa de Retención (%)',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.percent,
                    validator: (value) {
                      if (!controller.hasRetention) return null;
                      if (value == null || value.isEmpty) return 'Requerido';
                      final rate = double.tryParse(value);
                      if (rate == null || rate < 0 || rate > 100) {
                        return 'Tasa válida (0-100)';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  /// Obtener color para categoría de impuesto
  Color _getTaxCategoryColor(TaxCategory category) {
    switch (category) {
      case TaxCategory.iva:
        return ElegantLightTheme.primaryBlue;
      case TaxCategory.inc:
        return ElegantLightTheme.accentOrange;
      case TaxCategory.incBolsa:
        return Colors.brown;
      case TaxCategory.exento:
        return Colors.green;
      case TaxCategory.noGravado:
        return Colors.grey;
    }
  }

  // ========== FIN SECCIÓN FACTURACIÓN ELECTRÓNICA ==========

  String _getTypeDisplayName(ProductType type) {
    switch (type) {
      case ProductType.product:
        return 'Producto';
      case ProductType.service:
        return 'Servicio';
    }
  }

  String _getStatusDisplayName(ProductStatus status) {
    switch (status) {
      case ProductStatus.active:
        return 'Activo';
      case ProductStatus.inactive:
        return 'Inactivo';
      case ProductStatus.outOfStock:
        return 'Sin Stock';
    }
  }
}
