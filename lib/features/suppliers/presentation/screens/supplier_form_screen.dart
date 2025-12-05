// lib/features/suppliers/presentation/screens/supplier_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../controllers/supplier_form_controller.dart';
import '../widgets/supplier_form_sections.dart';
import '../../domain/entities/supplier.dart';

class SupplierFormScreen extends GetView<SupplierFormController> {
  const SupplierFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => MainLayout(
      title: controller.titleText,
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showHelp,
          tooltip: 'Ayuda',
        ),
      ],
      body: controller.isLoading.value
          ? const Center(child: LoadingWidget())
          : Column(
              children: [
                // Indicador de progreso elegante
                _buildElegantProgressIndicator(),

                // Contenido del formulario
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        children: [
                          _buildElegantBasicInformationSection(),
                          const SizedBox(height: AppDimensions.paddingMedium),
                          _buildElegantContactInformationSection(),
                          const SizedBox(height: AppDimensions.paddingMedium),
                          _buildElegantLocationSection(),
                          const SizedBox(height: AppDimensions.paddingMedium),
                          _buildElegantCommercialInformationSection(),
                          const SizedBox(height: AppDimensions.paddingMedium),
                          _buildElegantAdditionalInformationSection(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Barra de acciones elegante
                _buildElegantBottomActionBar(),
              ],
            ),
    ));
  }

  Widget _buildElegantProgressIndicator() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final isMedium = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        // Ajustes responsive
        final padding = isSmall ? 12.0 : (isMedium ? 14.0 : AppDimensions.paddingLarge);
        final iconPadding = isSmall ? 10.0 : 14.0;
        final iconSize = isSmall ? 20.0 : 26.0;
        final spacing = isSmall ? 10.0 : 16.0;
        final titleSize = isSmall ? 14.0 : 16.0;
        final subtitleSize = isSmall ? 11.0 : 12.0;
        final badgeHorizontalPadding = isSmall ? 10.0 : 14.0;
        final badgeVerticalPadding = isSmall ? 6.0 : 8.0;
        final badgeIconSize = isSmall ? 14.0 : 16.0;
        final badgeFontSize = isSmall ? 11.0 : 13.0;

        if (isSmall) {
          // Layout compacto para móvil: Columna con badge debajo
          return Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila superior: Icono + Texto
                  Row(
                    children: [
                      // Icono con gradiente
                      Container(
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: ElegantLightTheme.glowShadow,
                        ),
                        child: Icon(
                          Icons.business,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: spacing),
                      // Información
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información del Proveedor',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ElegantLightTheme.textPrimary,
                                fontSize: titleSize,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Complete todos los campos marcados con *',
                              style: TextStyle(
                                color: ElegantLightTheme.textSecondary,
                                fontSize: subtitleSize,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Badge de validación en la parte inferior
                  Obx(() => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: badgeHorizontalPadding,
                      vertical: badgeVerticalPadding,
                    ),
                    decoration: BoxDecoration(
                      gradient: controller.isFormValid.value
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (controller.isFormValid.value
                                  ? ElegantLightTheme.successGradient.colors.first
                                  : ElegantLightTheme.warningGradient.colors.first)
                              .withValues(alpha:0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.isFormValid.value ? Icons.check_circle : Icons.info,
                          size: badgeIconSize,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.isFormValid.value ? 'Válido' : 'Incompleto',
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          );
        } else {
          // Layout horizontal para tablet/desktop
          return Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  // Icono con gradiente
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: ElegantLightTheme.glowShadow,
                    ),
                    child: Icon(
                      Icons.business,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacing),
                  // Información
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del Proveedor',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ElegantLightTheme.textPrimary,
                            fontSize: titleSize,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Complete todos los campos marcados con * (obligatorios)',
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: subtitleSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge de validación elegante
                  Obx(() => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: badgeHorizontalPadding,
                      vertical: badgeVerticalPadding,
                    ),
                    decoration: BoxDecoration(
                      gradient: controller.isFormValid.value
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (controller.isFormValid.value
                                  ? ElegantLightTheme.successGradient.colors.first
                                  : ElegantLightTheme.warningGradient.colors.first)
                              .withValues(alpha:0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.isFormValid.value ? Icons.check_circle : Icons.info,
                          size: badgeIconSize,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.isFormValid.value ? 'Válido' : 'Incompleto',
                          style: TextStyle(
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildElegantBasicInformationSection() {
    return _buildElegantFormSection(
      title: 'Información Básica',
      subtitle: 'Datos principales del proveedor',
      icon: Icons.badge,
      gradient: ElegantLightTheme.primaryGradient,
      children: [
        // Nombre del proveedor (obligatorio)
        Obx(() => _buildElegantTextField(
          controller: controller.nameController,
          label: 'Nombre del Proveedor *',
          hint: 'Ej: Distribuidora ABC S.A.S.',
          prefixIcon: Icons.business_center,
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'El nombre del proveedor es obligatorio';
            }
            if (value!.length < 2) {
              return 'El nombre debe tener al menos 2 caracteres';
            }
            if (value.length > 200) {
              return 'El nombre no puede exceder 200 caracteres';
            }
            return null;
          },
          errorText: controller.nameError.value ? 'El nombre es obligatorio' : null,
        )),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Código y persona de contacto
        Row(
          children: [
            Expanded(
              child: _buildElegantTextField(
                controller: controller.codeController,
                label: 'Código del Proveedor',
                hint: 'Ej: PROV001',
                prefixIcon: Icons.qr_code,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildElegantTextField(
                controller: controller.contactPersonController,
                label: 'Persona de Contacto',
                hint: 'Ej: Juan Pérez',
                prefixIcon: Icons.person,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Tipo y número de documento - Responsive
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;

            if (isSmall) {
              // En móvil: Una columna vertical
              return Column(
                children: [
                  Obx(() => _buildElegantDropdown<DocumentType>(
                    value: controller.documentType.value,
                    label: 'Tipo de Documento *',
                    hintText: 'Seleccionar',
                    prefixIcon: Icons.description,
                    items: DocumentType.values
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(_getDocumentTypeText(type)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      controller.documentType.value = value;
                    },
                  )),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Obx(() => _buildElegantTextField(
                    controller: controller.documentNumberController,
                    label: 'Número de Documento *',
                    hint: 'Ej: 900123456-7',
                    prefixIcon: Icons.numbers,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Número de documento requerido';
                      }
                      return null;
                    },
                    errorText: controller.documentNumberError.value
                        ? 'Número de documento requerido'
                        : null,
                    onChanged: (value) {
                      controller.documentNumber.value = value ?? '';
                    },
                  )),
                ],
              );
            } else {
              // En tablet/desktop: Una fila horizontal
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Obx(() => _buildElegantDropdown<DocumentType>(
                      value: controller.documentType.value,
                      label: 'Tipo de Documento *',
                      hintText: 'Seleccionar',
                      prefixIcon: Icons.description,
                      items: DocumentType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getDocumentTypeText(type)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        controller.documentType.value = value;
                      },
                    )),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    flex: 3,
                    child: Obx(() => _buildElegantTextField(
                      controller: controller.documentNumberController,
                      label: 'Número de Documento *',
                      hint: 'Ej: 900123456-7',
                      prefixIcon: Icons.numbers,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) {
                          return 'Número de documento requerido';
                        }
                        return null;
                      },
                      errorText: controller.documentNumberError.value
                          ? 'Número de documento requerido'
                          : null,
                      onChanged: (value) {
                        controller.documentNumber.value = value ?? '';
                      },
                    )),
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Estado del proveedor - Selector moderno
        Obx(() => StatusSelectorWidget(
          selectedStatus: controller.status.value,
          onChanged: (status) => controller.status.value = status,
        )),
      ],
    );
  }

  Widget _buildElegantContactInformationSection() {
    return _buildElegantFormSection(
      title: 'Información de Contacto',
      subtitle: 'Datos para comunicación con el proveedor',
      icon: Icons.contact_mail,
      gradient: ElegantLightTheme.infoGradient,
      isCollapsible: true,
      children: [
        // Email
        Obx(() => _buildElegantTextField(
          controller: controller.emailController,
          label: 'Correo Electrónico',
          hint: 'proveedor@empresa.com',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          inputFormatters: [
            LengthLimitingTextInputFormatter(100),
          ],
          validator: (value) {
            if (value?.isNotEmpty == true) {
              if (!GetUtils.isEmail(value!)) {
                return 'Ingrese un email válido';
              }
              if (value.length > 100) {
                return 'El email no puede exceder 100 caracteres';
              }
            }
            return null;
          },
          errorText: controller.emailError.value ? 'Email inválido' : null,
        )),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Teléfonos
        Row(
          children: [
            Expanded(
              child: _buildElegantTextField(
                controller: controller.phoneController,
                label: 'Teléfono Fijo',
                hint: '(1) 234-5678',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildElegantTextField(
                controller: controller.mobileController,
                label: 'Teléfono Móvil',
                hint: '300 123 4567',
                prefixIcon: Icons.smartphone,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Sitio web
        _buildElegantTextField(
          controller: controller.websiteController,
          label: 'Sitio Web',
          hint: 'https://www.proveedor.com',
          prefixIcon: Icons.language,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildElegantLocationSection() {
    return _buildElegantFormSection(
      title: 'Información de Ubicación',
      subtitle: 'Dirección y datos de localización',
      icon: Icons.location_on,
      gradient: ElegantLightTheme.warningGradient,
      isCollapsible: true,
      children: [
        // Dirección
        _buildElegantTextField(
          controller: controller.addressController,
          label: 'Dirección',
          hint: 'Calle 123 # 45-67',
          prefixIcon: Icons.home,
          maxLines: 2,
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Ciudad y Estado
        Row(
          children: [
            Expanded(
              child: _buildElegantTextField(
                controller: controller.cityController,
                label: 'Ciudad',
                hint: 'Bogotá',
                prefixIcon: Icons.location_city,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildElegantTextField(
                controller: controller.stateController,
                label: 'Estado/Departamento',
                hint: 'Cundinamarca',
                prefixIcon: Icons.map,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // País y código postal
        Row(
          children: [
            Expanded(
              child: _buildElegantTextField(
                controller: controller.countryController,
                label: 'País',
                hint: 'Colombia',
                prefixIcon: Icons.flag,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildElegantTextField(
                controller: controller.postalCodeController,
                label: 'Código Postal',
                hint: '111111',
                prefixIcon: Icons.markunread_mailbox,
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElegantCommercialInformationSection() {
    return _buildElegantFormSection(
      title: 'Información Comercial',
      subtitle: 'Términos comerciales y condiciones de pago',
      icon: Icons.monetization_on,
      gradient: ElegantLightTheme.successGradient,
      isCollapsible: true,
      initiallyExpanded: false,
      children: [
        // Moneda y términos de pago - Responsive
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;

            if (isSmall) {
              // Móvil: disposición vertical
              return Column(
                children: [
                  CurrencySelectorWidget(
                    selectedCurrency: controller.currencyController.text,
                    onChanged: (currency) => controller.currencyController.text = currency,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  PaymentTermsWidget(
                    controller: controller.paymentTermsController,
                  ),
                ],
              );
            } else {
              // Tablet/Desktop: disposición horizontal
              return Row(
                children: [
                  Expanded(
                    child: CurrencySelectorWidget(
                      selectedCurrency: controller.currencyController.text,
                      onChanged: (currency) => controller.currencyController.text = currency,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMedium),
                  Expanded(
                    child: PaymentTermsWidget(
                      controller: controller.paymentTermsController,
                    ),
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: AppDimensions.paddingMedium),

        // Límite de crédito y descuento
        Row(
          children: [
            Expanded(
              child: _buildElegantTextField(
                controller: controller.creditLimitController,
                label: 'Límite de Crédito',
                hint: '0.00',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  PriceInputFormatter(),
                ],
                validator: (value) {
                  if (value?.isNotEmpty == true) {
                    final amount = NumberInputFormatter.getNumericValue(value!);
                    if (amount == null || amount < 0) {
                      return 'Debe ser un número válido mayor o igual a 0';
                    }
                    // Validate max value for decimal(15,2): 999,999,999,999.99
                    if (amount > 9999999999999.99) {
                      return 'El valor no puede exceder 9,999,999,999,999.99';
                    }
                    // Validate max 2 decimal places
                    final parts = value.replaceAll(',', '').split('.');
                    if (parts.length > 1 && parts[1].length > 2) {
                      return 'Solo se permiten 2 decimales';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: _buildElegantTextField(
                controller: controller.discountPercentageController,
                label: 'Descuento (%)',
                hint: '0.00',
                prefixIcon: Icons.discount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value?.isNotEmpty == true) {
                    final discount = double.tryParse(value!);
                    if (discount == null || discount < 0 || discount > 100) {
                      return 'Debe ser un porcentaje entre 0.00 y 100.00';
                    }
                    // Validate max 2 decimal places
                    final parts = value.split('.');
                    if (parts.length > 1 && parts[1].length > 2) {
                      return 'Solo se permiten 2 decimales';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildElegantAdditionalInformationSection() {
    return _buildElegantFormSection(
      title: 'Información Adicional',
      subtitle: 'Notas y observaciones especiales',
      icon: Icons.note_add,
      gradient: LinearGradient(
        colors: [
          ElegantLightTheme.textSecondary.withValues(alpha:0.7),
          ElegantLightTheme.textSecondary.withValues(alpha:0.5),
        ],
      ),
      isCollapsible: true,
      initiallyExpanded: false,
      children: [
        _buildElegantTextField(
          controller: controller.notesController,
          label: 'Notas y Observaciones',
          hint: 'Información adicional sobre el proveedor...',
          prefixIcon: Icons.notes,
          maxLines: 4,
        ),
      ],
    );
  }

  // Widget helper para crear secciones de formulario elegantes
  Widget _buildElegantFormSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
    bool isCollapsible = false,
    bool initiallyExpanded = true,
  }) {
    if (isCollapsible) {
      return _ElegantCollapsibleSection(
        title: title,
        subtitle: subtitle,
        icon: icon,
        gradient: gradient,
        initiallyExpanded: initiallyExpanded,
        children: children,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con gradiente
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha:0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // Widget helper para text fields elegantes
  Widget _buildElegantTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? errorText,
    void Function(String?)? onChanged,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType ?? TextInputType.text,
      validator: validator,
      errorText: errorText,
      onChanged: onChanged,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
    );
  }

  // Método helper para extraer el texto de un DropdownMenuItem
  String _getDropdownDisplayText<T>(List<DropdownMenuItem<T>> items, T value) {
    try {
      final item = items.firstWhere((item) => item.value == value);
      final child = item.child;

      // Si el child es un Text, extraemos su data
      if (child is Text) {
        return child.data ?? '';
      }

      // Si no es un Text, intentamos obtener su representación como string
      return child.toString();
    } catch (e) {
      return '';
    }
  }

  // Widget helper para dropdowns elegantes
  Widget _buildElegantDropdown<T>({
    required T? value,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showElegantDropdownBottomSheet<T>(
          context: Get.context!,
          label: label,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: const EdgeInsets.all(16),
          gradient: ElegantLightTheme.cardGradient,
          child: Row(
            children: [
              // Icono con gradiente en contenedor circular
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  prefixIcon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Label y valor con tipografía elegante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value != null
                          ? _getDropdownDisplayText(items, value)
                          : hintText,
                      style: TextStyle(
                        fontSize: 16,
                        color: value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                        fontWeight: value != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),

              // Icono de dropdown en contenedor con background azul
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.arrow_drop_down,
                  color: ElegantLightTheme.primaryBlue,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método para mostrar bottom sheet elegante con opciones del dropdown
  void _showElegantDropdownBottomSheet<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha:0.2),
              width: 1,
            ),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con gradiente azul
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Seleccionar $label',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha:0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de opciones con animaciones
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = item.value == value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onChanged(item.value);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        ElegantLightTheme.primaryBlue.withValues(alpha:0.1),
                                        ElegantLightTheme.primaryBlueLight.withValues(alpha:0.05),
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? ElegantLightTheme.primaryBlue
                                    : ElegantLightTheme.textTertiary.withValues(alpha:0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Texto
                                Expanded(
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? ElegantLightTheme.primaryBlue
                                          : ElegantLightTheme.textPrimary,
                                    ),
                                    child: item.child,
                                  ),
                                ),

                                // Opción seleccionada con gradiente y check icon
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
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Padding inferior para el gesto
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantBottomActionBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 400;
        final isMedium = constraints.maxWidth >= 400 && constraints.maxWidth < 600;
        final containerPadding = isSmall ? 10.0 : (isMedium ? 12.0 : AppDimensions.paddingLarge);
        final spacing = isSmall ? 6.0 : (isMedium ? 8.0 : AppDimensions.paddingLarge);
        final buttonHeight = isSmall ? 44.0 : (isMedium ? 46.0 : 48.0);

        // Padding interno del botón más compacto en móvil
        final buttonPadding = isSmall
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
            : (isMedium
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 20, vertical: 12));

        return Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha:0.15),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(containerPadding),
            child: Obx(() => Row(
              children: [
                // Botón cancelar - siempre en fila
                Expanded(
                  child: ElegantButton(
                    text: 'Cancelar',
                    onPressed: () => Get.back(),
                    icon: Icons.close,
                    gradient: LinearGradient(
                      colors: [
                        ElegantLightTheme.textSecondary.withValues(alpha:0.7),
                        ElegantLightTheme.textSecondary.withValues(alpha:0.5),
                      ],
                    ),
                    height: buttonHeight,
                    padding: buttonPadding,
                  ),
                ),

                SizedBox(width: spacing),

                // Botón guardar/crear - siempre en fila con mismo tamaño
                Expanded(
                  child: ElegantButton(
                    text: controller.saveButtonText,
                    onPressed: controller.isFormValid.value ? controller.saveSupplier : null,
                    isLoading: controller.isSaving.value,
                    icon: controller.isEditMode.value ? Icons.save : Icons.add,
                    gradient: controller.isFormValid.value
                        ? ElegantLightTheme.primaryGradient
                        : LinearGradient(
                            colors: [
                              ElegantLightTheme.textTertiary.withValues(alpha:0.5),
                              ElegantLightTheme.textTertiary.withValues(alpha:0.3),
                            ],
                          ),
                    height: buttonHeight,
                    padding: buttonPadding,
                  ),
                ),
              ],
            )),
          ),
        );
      },
    );
  }

  void _showHelp() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header elegante con gradiente
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                decoration: const BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.help_outline, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ayuda - Formulario de Proveedores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHelpItem(
                      'Campos marcados con (*) son obligatorios',
                      'Debe completar estos campos para guardar el proveedor',
                      Icons.star,
                      ElegantLightTheme.errorGradient,
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      'Código del proveedor',
                      'Identificador único, si no se especifica se generará automáticamente',
                      Icons.qr_code,
                      ElegantLightTheme.infoGradient,
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      'Términos de pago',
                      'Días que el proveedor otorga para el pago (ej: 30 días)',
                      Icons.schedule,
                      ElegantLightTheme.warningGradient,
                    ),
                    const SizedBox(height: 12),
                    _buildHelpItem(
                      'Límite de crédito',
                      'Monto máximo de crédito disponible con este proveedor',
                      Icons.credit_card,
                      ElegantLightTheme.successGradient,
                    ),
                  ],
                ),
              ),
              // Botón cerrar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingLarge,
                  0,
                  AppDimensions.paddingLarge,
                  AppDimensions.paddingLarge,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElegantButton(
                    text: 'Entendido',
                    onPressed: () => Get.back(),
                    icon: Icons.check_circle,
                    gradient: ElegantLightTheme.primaryGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon, LinearGradient gradient) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha:0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getDocumentTypeText(DocumentType type) {
    switch (type) {
      case DocumentType.nit:
        return 'NIT';
      case DocumentType.cc:
        return 'Cédula de Ciudadanía';
      case DocumentType.ce:
        return 'Cédula de Extranjería';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.rut:
        return 'RUT';
      case DocumentType.other:
        return 'Otro';
    }
  }

  LinearGradient _getStatusGradient(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return ElegantLightTheme.successGradient;
      case SupplierStatus.inactive:
        return ElegantLightTheme.warningGradient;
      case SupplierStatus.blocked:
        return ElegantLightTheme.errorGradient;
    }
  }

  String _getStatusText(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return 'Activo';
      case SupplierStatus.inactive:
        return 'Inactivo';
      case SupplierStatus.blocked:
        return 'Bloqueado';
    }
  }

  IconData _getStatusIcon(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return Icons.check_circle;
      case SupplierStatus.inactive:
        return Icons.pause_circle;
      case SupplierStatus.blocked:
        return Icons.block;
    }
  }
}

// Widget stateful para manejar la animación del ExpansionTile
class _ElegantCollapsibleSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _ElegantCollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.initiallyExpanded,
    required this.children,
  });

  @override
  State<_ElegantCollapsibleSection> createState() => _ElegantCollapsibleSectionState();
}

class _ElegantCollapsibleSectionState extends State<_ElegantCollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Header clickeable
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono decorado con gradiente
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: widget.gradient.scale(0.8),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: Icon(widget.icon, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),

                    // Título y subtítulo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ElegantLightTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Icono expand/collapse
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Contenido colapsable
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.children,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
