// lib/features/suppliers/presentation/screens/supplier_form_screen.dart
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
import '../../domain/entities/supplier.dart';

class SupplierFormScreen extends GetView<SupplierFormController> {
  const SupplierFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => MainLayout(
      title: controller.titleText,
      body: controller.isLoading.value
          ? const Center(child: LoadingWidget())
          : Column(
              children: [
                Expanded(child: _buildForm()),
                _buildBottomBar(),
              ],
            ),
    ));
  }

  Widget _buildForm() {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Form content
          Expanded(
            child: PageView(
              controller: PageController(initialPage: 0),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildContactInfoStep(),
                _buildCommercialInfoStep(),
              ],
            ),
          ),
        ],
      ),
    );
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
            children: List.generate(3, (index) {
              return Expanded(
                child: Obx(() => Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < 2 ? AppDimensions.paddingSmall : 0,
                  ),
                  decoration: BoxDecoration(
                    color: controller.currentStep.value >= index
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              );
            }),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Obx(() => Text(
            controller.getStepTitle(controller.currentStep.value),
            style: Get.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre (obligatorio)
          Obx(() => CustomTextField(
            controller: controller.nameController,
            label: 'Nombre del proveedor *',
            hint: 'Ingrese el nombre del proveedor',
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'El nombre es obligatorio';
              }
              return null;
            },
            errorText: controller.nameError.value ? 'El nombre es obligatorio' : null,
          )),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Código
          CustomTextField(
            controller: controller.codeController,
            label: 'Código',
            hint: 'Código único del proveedor',
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Tipo de documento y número
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Obx(() => CustomDropdown<DocumentType>(
                  value: controller.documentType.value,
                  label: 'Tipo de documento',
                  hintText: 'Seleccione',
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
                child: CustomTextField(
                  controller: controller.documentNumberController,
                  label: 'Número de documento',
                  hint: 'Número',
                  keyboardType: TextInputType.text,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Persona de contacto
          CustomTextField(
            controller: controller.contactPersonController,
            label: 'Persona de contacto',
            hint: 'Nombre del contacto principal',
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Estado
          Obx(() => CustomDropdown<SupplierStatus>(
            value: controller.status.value,
            label: 'Estado',
            items: SupplierStatus.values
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusText(status)),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                controller.status.value = value;
              }
            },
          )),
        ],
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de contacto',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Email
          Obx(() => CustomTextField(
            controller: controller.emailController,
            label: 'Email',
            hint: 'email@ejemplo.com',
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
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.phoneController,
                  label: 'Teléfono fijo',
                  hint: '(1) 234-5678',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: CustomTextField(
                  controller: controller.mobileController,
                  label: 'Teléfono móvil',
                  hint: '300 123 4567',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Dirección
          CustomTextField(
            controller: controller.addressController,
            label: 'Dirección',
            hint: 'Dirección completa',
            maxLines: 2,
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Ciudad y estado
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.cityController,
                  label: 'Ciudad',
                  hint: 'Ciudad',
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: CustomTextField(
                  controller: controller.stateController,
                  label: 'Estado/Departamento',
                  hint: 'Estado',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // País y código postal
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.countryController,
                  label: 'País',
                  hint: 'País',
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: CustomTextField(
                  controller: controller.postalCodeController,
                  label: 'Código postal',
                  hint: 'CP',
                  keyboardType: TextInputType.text,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Sitio web
          CustomTextField(
            controller: controller.websiteController,
            label: 'Sitio web',
            hint: 'https://www.ejemplo.com',
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información comercial',
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Moneda y términos de pago
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.currencyController,
                  label: 'Moneda',
                  hint: 'COP',
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: CustomTextField(
                  controller: controller.paymentTermsController,
                  label: 'Términos de pago (días)',
                  hint: '30',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Límite de crédito y descuento
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: controller.creditLimitController,
                  label: 'Límite de crédito',
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: CustomTextField(
                  controller: controller.discountPercentageController,
                  label: 'Descuento (%)',
                  hint: '0.0',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.paddingMedium),
          
          // Notas
          CustomTextField(
            controller: controller.notesController,
            label: 'Notas',
            hint: 'Notas adicionales...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
          // Botón anterior
          if (!controller.isFirstStep)
            Expanded(
              child: CustomButton(
                text: 'Anterior',
                onPressed: controller.previousStep,
                type: ButtonType.outline,
              ),
            ),
          
          if (!controller.isFirstStep)
            const SizedBox(width: AppDimensions.paddingMedium),
          
          // Botón siguiente/guardar
          Expanded(
            flex: controller.isFirstStep ? 1 : 1,
            child: CustomButton(
              text: controller.isLastStep 
                  ? controller.saveButtonText 
                  : 'Siguiente',
              onPressed: controller.canProceed 
                  ? (controller.isLastStep ? controller.saveSupplier : controller.nextStep)
                  : null,
              isLoading: controller.isSaving.value,
            ),
          ),
        ],
      )),
    );
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