// lib/features/suppliers/presentation/screens/supplier_form_screen_new.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_dropdown.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/supplier_form_controller.dart';
import '../widgets/supplier_form_sections.dart';
import '../../domain/entities/supplier.dart';

class SupplierFormScreen extends GetView<SupplierFormController> {
  const SupplierFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => MainLayout(
      title: controller.titleText,
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
                // Progress indicator
                _buildProgressIndicator(),
                
                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        children: [
                          _buildBasicInformationSection(),
                          _buildContactInformationSection(),
                          _buildLocationSection(),
                          _buildCommercialInformationSection(),
                          _buildAdditionalInformationSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom action bar
                _buildBottomActionBar(),
              ],
            ),
    ));
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Proveedor',
                      style: Get.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Complete todos los campos marcados con * (obligatorios)',
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: controller.isFormValid.value 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.isFormValid.value 
                          ? Icons.check_circle 
                          : Icons.info,
                      size: 16,
                      color: controller.isFormValid.value 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      controller.isFormValid.value ? 'Válido' : 'Incompleto',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: controller.isFormValid.value 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return FormSectionWidget(
      title: 'Información Básica',
      subtitle: 'Datos principales del proveedor',
      icon: Icons.badge,
      children: [
        // Nombre del proveedor (obligatorio)
        Obx(() => CustomTextField(
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
        FormRowWidget(
          children: [
            CustomTextField(
              controller: controller.codeController,
              label: 'Código del Proveedor',
              hint: 'Ej: PROV001',
              prefixIcon: Icons.qr_code,
            ),
            CustomTextField(
              controller: controller.contactPersonController,
              label: 'Persona de Contacto',
              hint: 'Ej: Juan Pérez',
              prefixIcon: Icons.person,
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Tipo y número de documento (validación condicional)
        FormRowWidget(
          flex: [2, 3],
          children: [
            Obx(() => CustomDropdown<DocumentType>(
              value: controller.documentType.value,
              label: 'Tipo de Documento *',
              hintText: 'Seleccionar',
              prefixIcon: const Icon(Icons.description),
              items: DocumentType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(_getDocumentTypeText(type)),
                      ))
                  .toList(),
              onChanged: (value) {
                controller.documentType.value = value;
                // La validación se maneja automáticamente por los listeners
              },
              validator: (value) => value == null ? 'Tipo de documento requerido' : null,
            )),
            Obx(() => CustomTextField(
              controller: controller.documentNumberController,
              label: 'Número de Documento *',
              hint: 'Ej: 900123456-7',
              prefixIcon: Icons.numbers,
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Número de documento requerido';
                }
                return null;
              },
              errorText: controller.documentNumberError.value ? 'Número de documento requerido' : null,
              onChanged: (value) {
                controller.documentNumber.value = value ?? '';
                // La validación se maneja automáticamente por los listeners
              },
            )),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Estado del proveedor
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado del Proveedor *',
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Row(
              children: SupplierStatus.values.map((status) => 
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StatusChipWidget(
                      status: status,
                      isSelected: controller.status.value == status,
                      onTap: () => controller.status.value = status,
                    ),
                  ),
                ),
              ).toList(),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInformationSection() {
    return FormSectionWidget(
      title: 'Información de Contacto',
      subtitle: 'Datos para comunicación con el proveedor',
      icon: Icons.contact_mail,
      isCollapsible: true,
      children: [
        // Email
        Obx(() => CustomTextField(
          controller: controller.emailController,
          label: 'Correo Electrónico',
          hint: 'proveedor@empresa.com',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isNotEmpty == true && !GetUtils.isEmail(value!)) {
              return 'Ingrese un email válido';
            }
            return null;
          },
          errorText: controller.emailError.value ? 'Email inválido' : null,
        )),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Teléfonos
        FormRowWidget(
          children: [
            CustomTextField(
              controller: controller.phoneController,
              label: 'Teléfono Fijo',
              hint: '(1) 234-5678',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            CustomTextField(
              controller: controller.mobileController,
              label: 'Teléfono Móvil',
              hint: '300 123 4567',
              prefixIcon: Icons.smartphone,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Sitio web
        CustomTextField(
          controller: controller.websiteController,
          label: 'Sitio Web',
          hint: 'https://www.proveedor.com',
          prefixIcon: Icons.language,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return FormSectionWidget(
      title: 'Información de Ubicación',
      subtitle: 'Dirección y datos de localización',
      icon: Icons.location_on,
      isCollapsible: true,
      children: [
        // Dirección
        CustomTextField(
          controller: controller.addressController,
          label: 'Dirección',
          hint: 'Calle 123 # 45-67',
          prefixIcon: Icons.home,
          maxLines: 2,
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Ciudad y Estado
        FormRowWidget(
          children: [
            CustomTextField(
              controller: controller.cityController,
              label: 'Ciudad',
              hint: 'Bogotá',
              prefixIcon: Icons.location_city,
            ),
            CustomTextField(
              controller: controller.stateController,
              label: 'Estado/Departamento',
              hint: 'Cundinamarca',
              prefixIcon: Icons.map,
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // País y código postal
        FormRowWidget(
          children: [
            CustomTextField(
              controller: controller.countryController,
              label: 'País',
              hint: 'Colombia',
              prefixIcon: Icons.flag,
            ),
            CustomTextField(
              controller: controller.postalCodeController,
              label: 'Código Postal',
              hint: '111111',
              prefixIcon: Icons.markunread_mailbox,
              keyboardType: TextInputType.text,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommercialInformationSection() {
    return FormSectionWidget(
      title: 'Información Comercial',
      subtitle: 'Términos comerciales y condiciones de pago',
      icon: Icons.monetization_on,
      children: [
        // Moneda y términos de pago
        FormRowWidget(
          children: [
            CurrencySelectorWidget(
              selectedCurrency: controller.currencyController.text,
              onChanged: (currency) => controller.currencyController.text = currency,
            ),
            PaymentTermsWidget(
              controller: controller.paymentTermsController,
            ),
          ],
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Límite de crédito y descuento
        FormRowWidget(
          children: [
            CustomTextField(
              controller: controller.creditLimitController,
              label: 'Límite de Crédito',
              hint: '0.00',
              prefixIcon: Icons.credit_card,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final amount = double.tryParse(value!);
                  if (amount == null || amount < 0) {
                    return 'Debe ser un número válido mayor o igual a 0';
                  }
                }
                return null;
              },
            ),
            CustomTextField(
              controller: controller.discountPercentageController,
              label: 'Descuento (%)',
              hint: '0.0',
              prefixIcon: Icons.discount,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final discount = double.tryParse(value!);
                  if (discount == null || discount < 0 || discount > 100) {
                    return 'Debe ser un porcentaje entre 0 y 100';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInformationSection() {
    return FormSectionWidget(
      title: 'Información Adicional',
      subtitle: 'Notas y observaciones especiales',
      icon: Icons.note_add,
      isCollapsible: true,
      initiallyExpanded: false,
      children: [
        CustomTextField(
          controller: controller.notesController,
          label: 'Notas y Observaciones',
          hint: 'Información adicional sobre el proveedor...',
          prefixIcon: Icons.notes,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(() => Row(
        children: [
          // Botón cancelar
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              onPressed: () => Get.back(),
              type: ButtonType.outline,
              icon: Icons.close,
            ),
          ),
          
          const SizedBox(width: AppDimensions.paddingMedium),
          
          // Botón guardar
          Expanded(
            flex: 2,
            child: CustomButton(
              text: controller.saveButtonText,
              onPressed: controller.isFormValid.value 
                  ? controller.saveSupplier 
                  : null,
              isLoading: controller.isSaving.value,
              icon: controller.isEditMode.value ? Icons.save : Icons.add,
            ),
          ),
        ],
      )),
    );
  }

  void _showHelp() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Ayuda - Formulario de Proveedores'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              '• Campos marcados con (*) son obligatorios',
              'Debe completar estos campos para guardar el proveedor',
            ),
            _buildHelpItem(
              '• Código del proveedor',
              'Identificador único, si no se especifica se generará automáticamente',
            ),
            _buildHelpItem(
              '• Términos de pago',
              'Días que el proveedor otorga para el pago (ej: 30 días)',
            ),
            _buildHelpItem(
              '• Límite de crédito',
              'Monto máximo de crédito disponible con este proveedor',
            ),
          ],
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

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
}