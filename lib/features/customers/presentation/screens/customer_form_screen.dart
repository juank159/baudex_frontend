

// lib/features/customers/presentation/screens/customer_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/customer_form_controller.dart';
import '../../domain/entities/customer.dart';

class CustomerFormScreen extends GetView<CustomerFormController> {
  const CustomerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🖼️ CustomerFormScreen: Construyendo pantalla...');

    return Scaffold(
      appBar: _buildAppBar(context),
      // ✅ CAMBIO: GetBuilder en lugar de Obx
      body: GetBuilder<CustomerFormController>(
        builder: (controller) {
          print(
            '🔄 CustomerFormScreen: Reconstruyendo body - isLoadingCustomer: ${controller.isLoadingCustomer}',
          );

          if (controller.isLoadingCustomer) {
            return const LoadingWidget(message: 'Cargando cliente...');
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
    return AppBar(
      // ✅ CAMBIO: GetBuilder en lugar de Obx
      title: GetBuilder<CustomerFormController>(
        builder: (controller) => Text(controller.formTitle),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackPress,
      ),
      actions: [
        // Guardar en desktop
        if (Responsive.isDesktop(context))
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GetBuilder<CustomerFormController>(
              builder:
                  (controller) => CustomButton(
                    text: controller.submitButtonText,
                    icon: Icons.save,
                    onPressed:
                        controller.isSaving ? null : controller.saveCustomer,
                    isLoading: controller.isSaving,
                  ),
            ),
          ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                if (controller.isEditMode) ...[
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Restablecer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('Duplicar Cliente'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                ],
                const PopupMenuItem(
                  value: 'validate',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle),
                      SizedBox(width: 8),
                      Text('Validar Formulario'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Limpiar Todo'),
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
        // Progress indicator
        _buildProgressIndicator(context),

        Expanded(
          child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: _buildForm(context),
          ),
        ),

        // Bottom actions
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 700,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),

            // Progress indicator
            _buildProgressIndicator(context),

            SizedBox(height: context.verticalSpacing),

            // Form in card
            CustomCard(child: _buildForm(context)),

            SizedBox(height: context.verticalSpacing),

            // Actions
            _buildActions(context),

            SizedBox(height: context.verticalSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Main form area
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con progress
                _buildFormHeader(context),

                const SizedBox(height: 32),

                // Personal Information Section
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        'Información Personal',
                        Icons.person,
                        '1 de 4',
                      ),
                      const SizedBox(height: 24),
                      _buildPersonalFields(context),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Contact Information Section
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        'Información de Contacto',
                        Icons.contact_phone,
                        '2 de 4',
                      ),
                      const SizedBox(height: 24),
                      _buildContactFields(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sidebar
        Container(
          width: 380,
          padding: const EdgeInsets.fromLTRB(0, 32, 32, 32),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Form Status Card
                _buildFormStatusCard(context),

                const SizedBox(height: 24),

                // Configuration Section
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        'Configuración',
                        Icons.settings,
                        '3 de 4',
                      ),
                      const SizedBox(height: 16),
                      _buildConfigurationFields(context),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Financial Information Section
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        context,
                        'Información Financiera',
                        Icons.account_balance,
                        '4 de 4',
                      ),
                      const SizedBox(height: 16),
                      _buildFinancialFields(context),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActionsCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding.left),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GetBuilder<CustomerFormController>(
                builder:
                    (controller) => Icon(
                      controller.isEditMode ? Icons.edit : Icons.person_add,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GetBuilder<CustomerFormController>(
                      builder:
                          (controller) => Text(
                            controller.formTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                    ),
                    GetBuilder<CustomerFormController>(
                      builder: (controller) {
                        if (controller.isEditMode && controller.hasCustomer) {
                          return Text(
                            'Editando: ${controller.currentCustomer!.displayName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              if (!context.isMobile) ...[
                GetBuilder<CustomerFormController>(
                  builder:
                      (controller) => Text(
                        _getFormCompletionText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                ),
              ],
            ],
          ),

          if (!context.isMobile) ...[
            const SizedBox(height: 8),
            GetBuilder<CustomerFormController>(
              builder:
                  (controller) => LinearProgressIndicator(
                    value: _calculateFormCompletion(),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GetBuilder<CustomerFormController>(
            builder:
                (controller) => Icon(
                  controller.isEditMode ? Icons.edit : Icons.person_add,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GetBuilder<CustomerFormController>(
                builder:
                    (controller) => Text(
                      controller.formTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
              const SizedBox(height: 4),
              GetBuilder<CustomerFormController>(
                builder: (controller) {
                  if (controller.isEditMode && controller.hasCustomer) {
                    return Text(
                      'Modificando información de ${controller.currentCustomer!.displayName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    );
                  } else {
                    return Text(
                      'Complete la información para registrar un nuevo cliente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    String step,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        if (!context.isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormStatusCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Estado del Formulario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Completion progress
          GetBuilder<CustomerFormController>(
            builder: (controller) {
              final completion = _calculateFormCompletion();
              final completionText = _getFormCompletionText();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        completionText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: completion,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Validation status
          GetBuilder<CustomerFormController>(
            builder:
                (controller) => Column(
                  children: [
                    _buildValidationItem(
                      'Email disponible',
                      controller.emailAvailable,
                      controller.isValidatingEmail,
                    ),
                    _buildValidationItem(
                      'Documento disponible',
                      controller.documentAvailable,
                      controller.isValidatingDocument,
                    ),
                    _buildValidationItem(
                      'Formulario válido',
                      _isFormValid(),
                      false,
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationItem(String label, bool isValid, bool isValidating) {
    IconData icon;
    Color color;

    if (isValidating) {
      icon = Icons.sync;
      color = Colors.orange;
    } else if (isValid) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.cancel;
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (isValidating)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Validar Datos',
              icon: Icons.check_circle,
              type: ButtonType.outline,
              onPressed: _validateForm,
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Limpiar Formulario',
              icon: Icons.clear_all,
              type: ButtonType.outline,
              onPressed: _showClearConfirmation,
            ),
          ),

          GetBuilder<CustomerFormController>(
            builder: (controller) {
              if (controller.isEditMode) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Restablecer',
                        icon: Icons.refresh,
                        type: ButtonType.outline,
                        onPressed: _resetForm,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Ver Todos los Clientes',
              icon: Icons.people,
              type: ButtonType.text,
              onPressed: () => Get.offAllNamed('/customers'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!Responsive.isDesktop(context)) ...[
            _buildPersonalSection(context),
            SizedBox(height: context.verticalSpacing * 2),
            _buildContactSection(context),
            SizedBox(height: context.verticalSpacing * 2),
            _buildConfigurationSection(context),
            SizedBox(height: context.verticalSpacing * 2),
            _buildFinancialSection(context),
          ] else
            _buildPersonalFields(context),
        ],
      ),
    );
  }

  Widget _buildPersonalSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Información Personal',
          Icons.person,
          '1 de 4',
        ),
        const SizedBox(height: 16),
        _buildPersonalFields(context),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Información de Contacto',
          Icons.contact_phone,
          '2 de 4',
        ),
        const SizedBox(height: 16),
        _buildContactFields(context),
      ],
    );
  }

  Widget _buildConfigurationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Configuración', Icons.settings, '3 de 4'),
        const SizedBox(height: 16),
        _buildConfigurationFields(context),
      ],
    );
  }

  Widget _buildFinancialSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Información Financiera',
          Icons.account_balance,
          '4 de 4',
        ),
        const SizedBox(height: 16),
        _buildFinancialFields(context),
      ],
    );
  }

  // Widget _buildPersonalFields(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Nombres
  //       Row(
  //         children: [
  //           Expanded(
  //             child: CustomTextField(
  //               controller: controller.firstNameController,
  //               label: 'Nombre *',
  //               hint: 'Ej: Juan',
  //               prefixIcon: Icons.person,
  //               validator: controller.validateFirstName,
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: CustomTextField(
  //               controller: controller.lastNameController,
  //               label: 'Apellido *',
  //               hint: 'Ej: Pérez',
  //               prefixIcon: Icons.person_outline,
  //               validator: controller.validateLastName,
  //             ),
  //           ),
  //         ],
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Nombre de empresa (opcional)
  //       CustomTextField(
  //         controller: controller.companyNameController,
  //         label: 'Nombre de la Empresa',
  //         hint: 'Ej: Acme Corporation (opcional)',
  //         prefixIcon: Icons.business,
  //         helperText: 'Solo si el cliente representa una empresa',
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Tipo y número de documento
  //       if (context.isMobile) ...[
  //         // En móvil: Una columna para evitar overflow
  //         GetBuilder<CustomerFormController>(
  //           builder:
  //               (controller) => DropdownButtonFormField<DocumentType>(
  //                 value: controller.selectedDocumentType,
  //                 decoration: InputDecoration(
  //                   labelText: 'Tipo de Documento *',
  //                   prefixIcon: const Icon(Icons.badge),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8.0),
  //                   ),
  //                   helperText: 'Seleccione el tipo de documento',
  //                   contentPadding: const EdgeInsets.symmetric(
  //                     horizontal: 12,
  //                     vertical: 16,
  //                   ),
  //                   isDense: false,
  //                 ),
  //                 isExpanded: true, // ✅ CRÍTICO para evitar overflow
  //                 items:
  //                     DocumentType.values.map((type) {
  //                       return DropdownMenuItem(
  //                         value: type,
  //                         child: Text(
  //                           _getDocumentTypeLabel(type, context),
  //                           overflow: TextOverflow.ellipsis,
  //                           style: const TextStyle(fontSize: 14),
  //                         ),
  //                       );
  //                     }).toList(),
  //                 onChanged: (DocumentType? value) {
  //                   if (value != null) {
  //                     controller.changeDocumentType(value);
  //                   }
  //                 },
  //               ),
  //         ),
  //         SizedBox(height: context.verticalSpacing),
  //         CustomTextField(
  //           controller: controller.documentNumberController,
  //           label: 'Número de Documento *',
  //           hint: 'Ej: 12345678',
  //           prefixIcon: Icons.numbers,
  //           validator: controller.validateDocumentNumber,
  //           onChanged: (_) => controller.validateDocumentAvailability(),
  //         ),
  //       ] else ...[
  //         // En tablet/desktop: Fila con proporciones ajustadas
  //         Row(
  //           children: [
  //             Expanded(
  //               flex: 3, // ✅ AUMENTADO: Más espacio para el dropdown
  //               child: GetBuilder<CustomerFormController>(
  //                 builder:
  //                     (controller) => DropdownButtonFormField<DocumentType>(
  //                       value: controller.selectedDocumentType,
  //                       decoration: InputDecoration(
  //                         labelText: 'Tipo de Documento *',
  //                         prefixIcon: const Icon(Icons.badge),
  //                         border: OutlineInputBorder(
  //                           borderRadius: BorderRadius.circular(8.0),
  //                         ),
  //                         helperText: 'Seleccione el tipo de documento',
  //                         contentPadding: const EdgeInsets.symmetric(
  //                           horizontal: 12,
  //                           vertical: 16,
  //                         ),
  //                         isDense: false,
  //                       ),
  //                       isExpanded: true, // ✅ CRÍTICO para evitar overflow
  //                       items:
  //                           DocumentType.values.map((type) {
  //                             return DropdownMenuItem(
  //                               value: type,
  //                               child: Text(
  //                                 _getDocumentTypeLabel(type, context),
  //                                 overflow: TextOverflow.ellipsis,
  //                                 style: const TextStyle(fontSize: 14),
  //                               ),
  //                             );
  //                           }).toList(),
  //                       onChanged: (DocumentType? value) {
  //                         if (value != null) {
  //                           controller.changeDocumentType(value);
  //                         }
  //                       },
  //                     ),
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               flex: 2, // ✅ REDUCIDO: Menos espacio para el número
  //               child: CustomTextField(
  //                 controller: controller.documentNumberController,
  //                 label: 'Número de Documento *',
  //                 hint: 'Ej: 12345678',
  //                 prefixIcon: Icons.numbers,
  //                 validator: controller.validateDocumentNumber,
  //                 onChanged: (_) => controller.validateDocumentAvailability(),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],

  //       // Indicador de disponibilidad del documento
  //       GetBuilder<CustomerFormController>(
  //         builder: (controller) {
  //           if (controller.isValidatingDocument) {
  //             return Padding(
  //               padding: const EdgeInsets.only(top: 8),
  //               child: Row(
  //                 children: [
  //                   const SizedBox(
  //                     width: 16,
  //                     height: 16,
  //                     child: CircularProgressIndicator(strokeWidth: 2),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Verificando disponibilidad...',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: Colors.grey.shade600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }
  //           if (!controller.documentAvailable) {
  //             return const Padding(
  //               padding: EdgeInsets.only(top: 8),
  //               child: Row(
  //                 children: [
  //                   Icon(Icons.error, color: Colors.red, size: 16),
  //                   SizedBox(width: 8),
  //                   Text(
  //                     'Documento ya registrado',
  //                     style: TextStyle(color: Colors.red, fontSize: 12),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }
  //           return const SizedBox.shrink();
  //         },
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Fecha de nacimiento
  //       InkWell(
  //         onTap: () => _selectBirthDate(context),
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: Colors.grey.shade300),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Row(
  //             children: [
  //               const Icon(Icons.calendar_today),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: GetBuilder<CustomerFormController>(
  //                   builder:
  //                       (controller) => Text(
  //                         controller.birthDate != null
  //                             ? 'Fecha de Nacimiento: ${_formatDate(controller.birthDate!)}'
  //                             : 'Fecha de Nacimiento (opcional)',
  //                         style: TextStyle(
  //                           color:
  //                               controller.birthDate != null
  //                                   ? Colors.white
  //                                   : Colors.grey.shade600,
  //                         ),
  //                       ),
  //                 ),
  //               ),
  //               GetBuilder<CustomerFormController>(
  //                 builder: (controller) {
  //                   if (controller.birthDate != null) {
  //                     return IconButton(
  //                       icon: const Icon(Icons.clear),
  //                       onPressed: () => controller.changeBirthDate(null),
  //                     );
  //                   }
  //                   return const SizedBox.shrink();
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildPersonalFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombres
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller.firstNameController,
                label: 'Nombre *',
                hint: 'Ej: Juan',
                prefixIcon: Icons.person,
                validator: controller.validateFirstName,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: controller.lastNameController,
                label: 'Apellido *',
                hint: 'Ej: Pérez',
                prefixIcon: Icons.person_outline,
                validator: controller.validateLastName,
              ),
            ),
          ],
        ),

        SizedBox(height: context.verticalSpacing),

        // Nombre de empresa (opcional)
        CustomTextField(
          controller: controller.companyNameController,
          label: 'Nombre de la Empresa',
          hint: 'Ej: Acme Corporation (opcional)',
          prefixIcon: Icons.business,
          helperText: 'Solo si el cliente representa una empresa',
        ),

        SizedBox(height: context.verticalSpacing),

        // Tipo y número de documento
        if (context.isMobile) ...[
          GetBuilder<CustomerFormController>(
            builder:
                (controller) => DropdownButtonFormField<DocumentType>(
                  value: controller.selectedDocumentType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Documento *',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    helperText: 'Seleccione el tipo de documento',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    isDense: false,
                  ),
                  isExpanded: true,
                  items:
                      DocumentType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            _getDocumentTypeLabel(type, context),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                  onChanged: (DocumentType? value) {
                    if (value != null) {
                      controller.changeDocumentType(value);
                    }
                  },
                ),
          ),
          SizedBox(height: context.verticalSpacing),
          CustomTextField(
            controller: controller.documentNumberController,
            label: 'Número de Documento *',
            hint: 'Ej: 12345678',
            prefixIcon: Icons.numbers,
            validator: controller.validateDocumentNumber,
            // ✅ CAMBIO CRÍTICO: Usar el método correcto
            onChanged: controller.onDocumentNumberChanged,
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GetBuilder<CustomerFormController>(
                  builder:
                      (controller) => DropdownButtonFormField<DocumentType>(
                        value: controller.selectedDocumentType,
                        decoration: InputDecoration(
                          labelText: 'Tipo de Documento *',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          helperText: 'Seleccione el tipo de documento',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          isDense: false,
                        ),
                        isExpanded: true,
                        items:
                            DocumentType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  _getDocumentTypeLabel(type, context),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                        onChanged: (DocumentType? value) {
                          if (value != null) {
                            controller.changeDocumentType(value);
                          }
                        },
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: controller.documentNumberController,
                  label: 'Número de Documento *',
                  hint: 'Ej: 12345678',
                  prefixIcon: Icons.numbers,
                  validator: controller.validateDocumentNumber,
                  // ✅ CAMBIO CRÍTICO: Usar el método correcto
                  onChanged: controller.onDocumentNumberChanged,
                ),
              ),
            ],
          ),
        ],

        // Indicador de disponibilidad del documento
        GetBuilder<CustomerFormController>(
          builder: (controller) {
            if (controller.isValidatingDocument) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verificando disponibilidad...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!controller.documentAvailable) {
              return const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Documento ya registrado',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        SizedBox(height: context.verticalSpacing),

        // Fecha de nacimiento
        InkWell(
          onTap: () => _selectBirthDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 16),
                Expanded(
                  child: GetBuilder<CustomerFormController>(
                    builder:
                        (controller) => Text(
                          controller.birthDate != null
                              ? 'Fecha de Nacimiento: ${_formatDate(controller.birthDate!)}'
                              : 'Fecha de Nacimiento (opcional)',
                          style: TextStyle(
                            color:
                                controller.birthDate != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                          ),
                        ),
                  ),
                ),
                GetBuilder<CustomerFormController>(
                  builder: (controller) {
                    if (controller.birthDate != null) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => controller.changeBirthDate(null),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildContactFields(BuildContext context) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Email
  //       CustomTextField(
  //         controller: controller.emailController,
  //         label: 'Email *',
  //         hint: 'ejemplo@correo.com',
  //         prefixIcon: Icons.email,
  //         validator: controller.validateEmail,
  //         keyboardType: TextInputType.emailAddress,
  //         onChanged: (_) => controller.validateEmailAvailability(),
  //         helperText: 'Dirección de correo electrónico principal',
  //       ),

  //       // Indicador de disponibilidad del email
  //       GetBuilder<CustomerFormController>(
  //         builder: (controller) {
  //           if (controller.isValidatingEmail) {
  //             return Padding(
  //               padding: const EdgeInsets.only(top: 8),
  //               child: Row(
  //                 children: [
  //                   const SizedBox(
  //                     width: 16,
  //                     height: 16,
  //                     child: CircularProgressIndicator(strokeWidth: 2),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     'Verificando disponibilidad...',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: Colors.grey.shade600,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }
  //           if (!controller.emailAvailable) {
  //             return const Padding(
  //               padding: EdgeInsets.only(top: 8),
  //               child: Row(
  //                 children: [
  //                   Icon(Icons.error, color: Colors.red, size: 16),
  //                   SizedBox(width: 8),
  //                   Text(
  //                     'Email ya registrado',
  //                     style: TextStyle(color: Colors.red, fontSize: 12),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }
  //           return const SizedBox.shrink();
  //         },
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Teléfonos
  //       Row(
  //         children: [
  //           Expanded(
  //             child: CustomTextField(
  //               controller: controller.phoneController,
  //               label: 'Teléfono',
  //               hint: '601234567',
  //               prefixIcon: Icons.phone,
  //               keyboardType: TextInputType.phone,
  //               helperText: 'Teléfono fijo (opcional)',
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: CustomTextField(
  //               controller: controller.mobileController,
  //               label: 'Móvil',
  //               hint: '3001234567',
  //               prefixIcon: Icons.phone_android,
  //               keyboardType: TextInputType.phone,
  //               helperText: 'Teléfono móvil (opcional)',
  //             ),
  //           ),
  //         ],
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Dirección
  //       CustomTextField(
  //         controller: controller.addressController,
  //         label: 'Dirección',
  //         hint: 'Calle 123 #45-67',
  //         prefixIcon: Icons.location_on,
  //         maxLines: 2,
  //         helperText: 'Dirección física completa',
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Ciudad y Estado
  //       Row(
  //         children: [
  //           Expanded(
  //             child: CustomTextField(
  //               controller: controller.cityController,
  //               label: 'Ciudad',
  //               hint: 'Cúcuta',
  //               prefixIcon: Icons.location_city,
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: CustomTextField(
  //               controller: controller.stateController,
  //               label: 'Departamento',
  //               hint: 'Norte de Santander',
  //               prefixIcon: Icons.map,
  //             ),
  //           ),
  //         ],
  //       ),

  //       SizedBox(height: context.verticalSpacing),

  //       // Código postal
  //       CustomTextField(
  //         controller: controller.zipCodeController,
  //         label: 'Código Postal',
  //         hint: '540001',
  //         prefixIcon: Icons.local_post_office,
  //         helperText: 'Código postal de la ciudad',
  //       ),
  //     ],
  //   );
  // }

  Widget _buildContactFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        CustomTextField(
          controller: controller.emailController,
          label: 'Email *',
          hint: 'ejemplo@correo.com',
          prefixIcon: Icons.email,
          validator: controller.validateEmail,
          keyboardType: TextInputType.emailAddress,
          // ✅ CAMBIO CRÍTICO: Usar el método correcto
          onChanged: controller.onEmailChanged,
          helperText: 'Dirección de correo electrónico principal',
        ),

        // Indicador de disponibilidad del email
        GetBuilder<CustomerFormController>(
          builder: (controller) {
            if (controller.isValidatingEmail) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verificando disponibilidad...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!controller.emailAvailable) {
              return const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Email ya registrado',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        SizedBox(height: context.verticalSpacing),

        // Teléfonos
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller.phoneController,
                label: 'Teléfono',
                hint: '601234567',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                helperText: 'Teléfono fijo (opcional)',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: controller.mobileController,
                label: 'Móvil',
                hint: '3001234567',
                prefixIcon: Icons.phone_android,
                keyboardType: TextInputType.phone,
                helperText: 'Teléfono móvil (opcional)',
              ),
            ),
          ],
        ),

        SizedBox(height: context.verticalSpacing),

        // Dirección
        CustomTextField(
          controller: controller.addressController,
          label: 'Dirección',
          hint: 'Calle 123 #45-67',
          prefixIcon: Icons.location_on,
          maxLines: 2,
          helperText: 'Dirección física completa',
        ),

        SizedBox(height: context.verticalSpacing),

        // Ciudad y Estado
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller.cityController,
                label: 'Ciudad',
                hint: 'Cúcuta',
                prefixIcon: Icons.location_city,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: controller.stateController,
                label: 'Departamento',
                hint: 'Norte de Santander',
                prefixIcon: Icons.map,
              ),
            ),
          ],
        ),

        SizedBox(height: context.verticalSpacing),

        // Código postal
        CustomTextField(
          controller: controller.zipCodeController,
          label: 'Código Postal',
          hint: '540001',
          prefixIcon: Icons.local_post_office,
          helperText: 'Código postal de la ciudad',
        ),
      ],
    );
  }

  Widget _buildConfigurationFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado
        Text(
          'Estado del Cliente',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GetBuilder<CustomerFormController>(
          builder:
              (controller) => Column(
                children:
                    CustomerStatus.values.map((status) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color:
                              controller.selectedStatus == status
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              controller.selectedStatus == status
                                  ? Border.all(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                  )
                                  : null,
                        ),
                        child: RadioListTile<CustomerStatus>(
                          title: Text(_getStatusLabel(status)),
                          subtitle: Text(_getStatusDescription(status)),
                          value: status,
                          groupValue: controller.selectedStatus,
                          onChanged: (CustomerStatus? value) {
                            if (value != null) {
                              controller.changeStatus(value);
                            }
                          },
                          dense: true,
                        ),
                      );
                    }).toList(),
              ),
        ),
      ],
    );
  }

  Widget _buildFinancialFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Límite de crédito
        CustomTextField(
          controller: controller.creditLimitController,
          label: 'Límite de Crédito',
          hint: '0',
          prefixIcon: Icons.credit_card,
          keyboardType: TextInputType.number,
          validator: controller.validateCreditLimit,
          helperText: 'Monto máximo de crédito permitido',
        ),

        SizedBox(height: context.verticalSpacing),

        // Términos de pago
        CustomTextField(
          controller: controller.paymentTermsController,
          label: 'Términos de Pago (días)',
          hint: '30',
          prefixIcon: Icons.schedule,
          keyboardType: TextInputType.number,
          validator: controller.validatePaymentTerms,
          helperText: 'Días para el pago de facturas',
        ),

        SizedBox(height: context.verticalSpacing),

        // Notas
        CustomTextField(
          controller: controller.notesController,
          label: 'Notas',
          hint: 'Información adicional...',
          prefixIcon: Icons.note,
          maxLines: 3,
          helperText: 'Información adicional sobre el cliente',
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return GetBuilder<CustomerFormController>(
      builder:
          (controller) => Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  type: ButtonType.outline,
                  onPressed: _handleBackPress,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: controller.submitButtonText,
                  icon: Icons.save,
                  onPressed:
                      controller.isSaving ? null : controller.saveCustomer,
                  isLoading: controller.isSaving,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsivePadding.left),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(child: _buildActions(context)),
    );
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'reset':
        _resetForm();
        break;
      case 'duplicate':
        _duplicateCustomer();
        break;
      case 'validate':
        _validateForm();
        break;
      case 'clear':
        _showClearConfirmation();
        break;
    }
  }

  void _handleBackPress() {
    if (_hasUnsavedChanges()) {
      _showUnsavedChangesDialog();
    } else {
      controller.cancel();
    }
  }

  void _resetForm() {
    if (controller.isEditMode && controller.hasCustomer) {
      Get.dialog(
        AlertDialog(
          title: const Text('Restablecer Formulario'),
          content: const Text(
            '¿Estás seguro que deseas restablecer el formulario a los valores originales?\n\n'
            'Se perderán todos los cambios realizados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                controller.loadCustomer(controller.currentCustomer!.id);
                _showSuccess('Formulario restablecido');
              },
              child: const Text('Restablecer'),
            ),
          ],
        ),
      );
    }
  }

  void _duplicateCustomer() {
    if (!controller.isEditMode || !controller.hasCustomer) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Duplicar Cliente'),
        content: const Text(
          '¿Deseas crear un nuevo cliente basado en la información actual?\n\n'
          'Se abrirá un nuevo formulario con los datos copiados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // TODO: Implementar duplicación
              _showSuccess('Funcionalidad de duplicación próximamente');
            },
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );
  }

  void _validateForm() {
    final isValid = controller.formKey.currentState?.validate() ?? false;
    final emailValid = controller.emailAvailable;
    final documentValid = controller.documentAvailable;

    String message;
    if (isValid && emailValid && documentValid) {
      message = '✅ El formulario es válido y está listo para guardar';
      _showSuccess(message);
    } else {
      List<String> errors = [];
      if (!isValid) errors.add('Hay campos con errores');
      if (!emailValid) errors.add('Email no disponible');
      if (!documentValid) errors.add('Documento no disponible');

      message = '❌ Errores encontrados:\n${errors.join('\n')}';
      _showError('Formulario inválido', message);
    }
  }

  void _showClearConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Limpiar Formulario'),
        content: const Text(
          '¿Estás seguro que deseas limpiar todo el formulario?\n\n'
          'Se perderá toda la información ingresada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _clearForm();
              _showSuccess('Formulario limpiado');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cambios sin Guardar'),
        content: const Text(
          'Hay cambios sin guardar en el formulario.\n\n'
          '¿Qué deseas hacer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Continuar Editando'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancel();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir sin Guardar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.saveCustomer();
            },
            child: const Text('Guardar y Salir'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          controller.birthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.changeBirthDate(picked);
    }
  }

  void _clearForm() {
    controller.firstNameController.clear();
    controller.lastNameController.clear();
    controller.companyNameController.clear();
    controller.emailController.clear();
    controller.phoneController.clear();
    controller.mobileController.clear();
    controller.documentNumberController.clear();
    controller.addressController.clear();
    controller.cityController.clear();
    controller.stateController.clear();
    controller.zipCodeController.clear();
    controller.creditLimitController.text = '0';
    controller.paymentTermsController.text = '30';
    controller.notesController.clear();

    controller.changeStatus(CustomerStatus.active);
    controller.changeDocumentType(DocumentType.cc);
    controller.changeBirthDate(null);
  }

  // ==================== HELPER METHODS ====================

  bool _hasUnsavedChanges() {
    // TODO: Implementar lógica para detectar cambios
    return controller.firstNameController.text.isNotEmpty ||
        controller.lastNameController.text.isNotEmpty ||
        controller.emailController.text.isNotEmpty;
  }

  bool _isFormValid() {
    return controller.firstNameController.text.isNotEmpty &&
        controller.lastNameController.text.isNotEmpty &&
        controller.emailController.text.isNotEmpty &&
        controller.documentNumberController.text.isNotEmpty &&
        controller.emailAvailable &&
        controller.documentAvailable;
  }

  double _calculateFormCompletion() {
    int totalFields = 7; // Campos requeridos
    int completedFields = 0;

    if (controller.firstNameController.text.isNotEmpty) completedFields++;
    if (controller.lastNameController.text.isNotEmpty) completedFields++;
    if (controller.emailController.text.isNotEmpty) completedFields++;
    if (controller.documentNumberController.text.isNotEmpty) completedFields++;
    if (controller.creditLimitController.text.isNotEmpty) completedFields++;
    if (controller.paymentTermsController.text.isNotEmpty) completedFields++;
    if (controller.emailAvailable && controller.documentAvailable)
      completedFields++;

    return completedFields / totalFields;
  }

  String _getFormCompletionText() {
    final completion = _calculateFormCompletion();
    final percentage = (completion * 100).round();
    return '$percentage% completado';
  }

  String _getDocumentTypeLabel(DocumentType type, BuildContext context) {
    // En móvil, usar nombres más cortos para evitar overflow
    if (context.isMobile) {
      switch (type) {
        case DocumentType.cc:
          return 'C.C.';
        case DocumentType.nit:
          return 'NIT';
        case DocumentType.ce:
          return 'C.E.';
        case DocumentType.passport:
          return 'Pasaporte';
        case DocumentType.other:
          return 'Otro';
      }
    } else {
      // En tablet/desktop, usar nombres completos
      switch (type) {
        case DocumentType.cc:
          return 'Cédula de Ciudadanía';
        case DocumentType.nit:
          return 'NIT';
        case DocumentType.ce:
          return 'Cédula de Extranjería';
        case DocumentType.passport:
          return 'Pasaporte';
        case DocumentType.other:
          return 'Otro';
      }
    }
  }

  String _getStatusLabel(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Activo';
      case CustomerStatus.inactive:
        return 'Inactivo';
      case CustomerStatus.suspended:
        return 'Suspendido';
    }
  }

  String _getStatusDescription(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Cliente puede realizar transacciones';
      case CustomerStatus.inactive:
        return 'Cliente temporalmente inactivo';
      case CustomerStatus.suspended:
        return 'Cliente suspendido por políticas';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }
}
