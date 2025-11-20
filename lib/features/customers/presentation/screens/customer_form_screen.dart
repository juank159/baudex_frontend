

// lib/features/customers/presentation/screens/customer_form_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
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
      body: SafeArea(
        child: GetBuilder<CustomerFormController>(
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
      ),
      title: GetBuilder<CustomerFormController>(
        builder: (controller) => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                controller.isEditMode ? Icons.edit : Icons.person_add,
                size: isMobile ? 18 : 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                controller.formTitle,
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackPress,
      ),
      actions: [
        // Menú de opciones
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, context),
          tooltip: 'Opciones',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            foregroundColor: Colors.white,
          ),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          itemBuilder: (context) => [
            if (controller.isEditMode) ...[
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
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
                      'Restablecer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.successGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.copy,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Duplicar Cliente',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            PopupMenuItem(
              value: 'validate',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.infoGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Validar Formulario',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.clear_all,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Limpiar Todo',
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
            gradient: ElegantLightTheme.cardGradient,
            border: Border(
              left: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
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
        border: Border(
          bottom: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GetBuilder<CustomerFormController>(
                builder:
                    (controller) => Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient.scale(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        controller.isEditMode ? Icons.edit : Icons.person_add,
                        color: ElegantLightTheme.primaryBlue,
                        size: 18,
                      ),
                    ),
              ),
              const SizedBox(width: 12),
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
                              color: ElegantLightTheme.textPrimary,
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
                              color: ElegantLightTheme.textSecondary,
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
                      (controller) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.cardGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          _getFormCompletionText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                      ),
                ),
              ],
            ],
          ),

          if (!context.isMobile) ...[
            const SizedBox(height: 12),
            GetBuilder<CustomerFormController>(
              builder:
                  (controller) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _calculateFormCompletion(),
                      backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ElegantLightTheme.primaryBlue,
                      ),
                      minHeight: 6,
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
            gradient: ElegantLightTheme.primaryGradient.scale(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GetBuilder<CustomerFormController>(
            builder:
                (controller) => Icon(
                  controller.isEditMode ? Icons.edit : Icons.person_add,
                  color: ElegantLightTheme.primaryBlue,
                  size: 32,
                ),
          ),
        ),

        const SizedBox(width: 20),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GetBuilder<CustomerFormController>(
                builder:
                    (controller) => Text(
                      controller.formTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
              ),
              const SizedBox(height: 8),
              GetBuilder<CustomerFormController>(
                builder: (controller) {
                  if (controller.isEditMode && controller.hasCustomer) {
                    return Text(
                      'Modificando información de ${controller.currentCustomer!.displayName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    );
                  } else {
                    return Text(
                      'Complete la información para registrar un nuevo cliente',
                      style: TextStyle(
                        fontSize: 14,
                        color: ElegantLightTheme.textSecondary,
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: ElegantLightTheme.glowShadow,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 17, desktop: 18),
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
        ),
        if (!context.isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.cardGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              step,
              style: TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.primaryBlue,
                fontWeight: FontWeight.w700,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.assessment,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Estado del Formulario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

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
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                      Text(
                        completionText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completion,
                      backgroundColor: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ElegantLightTheme.primaryBlue,
                      ),
                      minHeight: 6,
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
                (controller) {
                  final email = controller.emailController.text.trim();
                  final isEmailFormatValid = email.isEmpty || _isValidEmail(email);
                  final phone = controller.phoneController.text.trim();
                  final isPhoneValid = phone.isEmpty || phone.length >= 7;

                  return Column(
                    children: [
                      _buildValidationItem(
                        'Email formato válido',
                        isEmailFormatValid,
                        false,
                      ),
                      _buildValidationItem(
                        'Email disponible',
                        controller.emailAvailable,
                        controller.isValidatingEmail,
                      ),
                      _buildValidationItem(
                        'Teléfono válido',
                        isPhoneValid,
                        false,
                      ),
                      _buildValidationItem(
                        'Documento disponible',
                        controller.documentAvailable,
                        controller.isValidatingDocument,
                      ),
                      _buildValidationItem(
                        'Campos obligatorios completos',
                        _areRequiredFieldsFilled(),
                        false,
                      ),
                      _buildValidationItem(
                        'Formulario válido',
                        _isFormValid(),
                        false,
                      ),
                    ],
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _buildValidationItem(String label, bool isValid, bool isValidating) {
    IconData icon;
    LinearGradient gradient;
    Color iconColor;

    if (isValidating) {
      icon = Icons.sync;
      gradient = ElegantLightTheme.warningGradient;
      iconColor = ElegantLightTheme.accentOrange;
    } else if (isValid) {
      icon = Icons.check_circle;
      gradient = ElegantLightTheme.successGradient;
      iconColor = Colors.green.shade600;
    } else {
      icon = Icons.cancel;
      gradient = ElegantLightTheme.errorGradient;
      iconColor = Colors.red.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient.scale(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          if (isValidating)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 12),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ElegantLightTheme.textPrimary,
              ),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Botón Validar Datos
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.infoGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _validateForm,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Validar Datos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón Limpiar Formulario
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.warningGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: ElegantLightTheme.elevatedShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showClearConfirmation,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.clear_all, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Limpiar Formulario',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          GetBuilder<CustomerFormController>(
            builder: (controller) {
              if (controller.isEditMode) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    // Botón Restablecer
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient.scale(0.8),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: ElegantLightTheme.elevatedShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _resetForm,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Restablecer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 20),
          Divider(color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),

          // Botón Ver Todos los Clientes
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: ElegantLightTheme.primaryBlue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.offAllNamed('/customers'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, color: ElegantLightTheme.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Ver Todos los Clientes',
                        style: TextStyle(
                          color: ElegantLightTheme.primaryBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
            // Ahora todo está integrado en _buildPersonalSection con secciones colapsables
            _buildPersonalSection(context),
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
        // Header de sección principal
        _buildSectionHeader(
          context,
          'Información Básica',
          Icons.person,
          '1 de 4',
        ),
        const SizedBox(height: 16),

        // CAMPOS OBLIGATORIOS SIEMPRE VISIBLES
        Row(
          children: [
            Expanded(
              child: CustomTextFieldSafe(
                controller: controller.firstNameController,
                label: 'Nombre *',
                hint: 'Ej: Juan',
                prefixIcon: Icons.person,
                validator: controller.validateFirstName,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextFieldSafe(
                controller: controller.lastNameController,
                label: 'Apellido *',
                hint: 'Ej: Pérez',
                prefixIcon: Icons.person_outline,
                validator: controller.validateLastName,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        CustomTextFieldSafe(
          controller: controller.emailController,
          label: 'Email *',
          hint: 'correo@ejemplo.com',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: controller.validateEmail,
          onChanged: controller.onEmailChanged,
          helperText: 'Dirección de correo electrónico principal',
        ),

        // Indicador de disponibilidad del email
        GetBuilder<CustomerFormController>(
          builder: (controller) {
            if (controller.isValidatingEmail) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Verificando disponibilidad...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!controller.emailAvailable) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade50,
                      Colors.red.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.errorGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Email ya registrado',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 16),

        CustomTextFieldSafe(
          controller: controller.phoneController,
          label: 'Teléfono *',
          hint: '+51 999 999 999',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          helperText: 'Teléfono de contacto principal',
        ),

        const SizedBox(height: 16),

        // DOCUMENTO - CAMPO OBLIGATORIO
        if (context.isMobile) ...[
          GetBuilder<CustomerFormController>(
            builder: (controller) => Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<DocumentType>(
                value: controller.selectedDocumentType,
                decoration: InputDecoration(
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge, color: Colors.white, size: 18),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
                isExpanded: true,
                selectedItemBuilder: (BuildContext context) {
                  return DocumentType.values.map((type) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tipo de Documento *',
                        style: TextStyle(
                          fontSize: 14,
                          color: ElegantLightTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: DocumentType.values.map((type) {
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
          const SizedBox(height: 16),
          CustomTextFieldSafe(
            controller: controller.documentNumberController,
            label: 'Número de Documento *',
            hint: 'Ej: 12345678',
            prefixIcon: Icons.numbers,
            validator: controller.validateDocumentNumber,
            onChanged: controller.onDocumentNumberChanged,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GetBuilder<CustomerFormController>(
                  builder: (controller) => Container(
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.glassGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<DocumentType>(
                      value: controller.selectedDocumentType,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.badge, color: Colors.white, size: 18),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      isExpanded: true,
                      selectedItemBuilder: (BuildContext context) {
                        // ✅ Siempre mostrar "Tipo de Documento *" sin importar la selección
                        return DocumentType.values.map((type) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tipo de Documento *',
                              style: TextStyle(
                                fontSize: 14,
                                color: ElegantLightTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      items: DocumentType.values.map((type) {
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
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomTextFieldSafe(
                  controller: controller.documentNumberController,
                  label: 'Número de Documento *',
                  hint: 'Ej: 12345678',
                  prefixIcon: Icons.numbers,
                  validator: controller.validateDocumentNumber,
                  onChanged: controller.onDocumentNumberChanged,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Indicador de disponibilidad del documento
        GetBuilder<CustomerFormController>(
          builder: (controller) {
            if (controller.isValidatingDocument) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Verificando disponibilidad...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!controller.documentAvailable) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade50,
                      Colors.red.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.errorGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Documento ya registrado',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 24),

        // SECCIÓN COLAPSABLE: Información Adicional
        Obx(() => _buildCollapsibleSection(
          context: context,
          title: 'Información Adicional',
          icon: Icons.info_outline,
          isExpanded: controller.showAdditionalInfo.value,
          onToggle: () => controller.showAdditionalInfo.toggle(),
          badge: 'Opcional',
          child: Column(
            children: [
              CustomTextFieldSafe(
                controller: controller.companyNameController,
                label: 'Nombre de la Empresa',
                hint: 'Ej: Acme Corporation',
                prefixIcon: Icons.business,
                helperText: 'Solo si el cliente representa una empresa',
              ),
              const SizedBox(height: 16),

              // Fecha de Nacimiento - ESTILO MEJORADO
              GetBuilder<CustomerFormController>(
                builder: (controller) => Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectBirthDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Icono decorado
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.infoGradient,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: ElegantLightTheme.glowShadow,
                              ),
                              child: const Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Contenido
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Fecha de Nacimiento',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: ElegantLightTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    controller.birthDate != null
                                        ? _formatDate(controller.birthDate!)
                                        : 'Seleccionar fecha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: controller.birthDate != null
                                          ? ElegantLightTheme.textPrimary
                                          : ElegantLightTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Botón limpiar (si hay fecha seleccionada)
                            if (controller.birthDate != null)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.red.shade600,
                                ),
                                onPressed: () => controller.changeBirthDate(null),
                                tooltip: 'Limpiar fecha',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.arrow_drop_down,
                                  color: ElegantLightTheme.primaryBlue,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )),

        const SizedBox(height: 16),

        // SECCIÓN COLAPSABLE: Contacto Adicional
        Obx(() => _buildCollapsibleSection(
          context: context,
          title: 'Información de Contacto Adicional',
          icon: Icons.contact_phone,
          isExpanded: controller.showAdditionalContact.value,
          onToggle: () => controller.showAdditionalContact.toggle(),
          badge: 'Opcional',
          child: Column(
            children: [
              CustomTextFieldSafe(
                controller: controller.mobileController,
                label: 'Teléfono Móvil',
                hint: '+51 999 999 999',
                prefixIcon: Icons.smartphone,
                keyboardType: TextInputType.phone,
                helperText: 'Teléfono móvil adicional',
              ),
              const SizedBox(height: 16),
              CustomTextFieldSafe(
                controller: controller.addressController,
                label: 'Dirección',
                hint: 'Calle, número, distrito',
                prefixIcon: Icons.location_on,
                maxLines: 2,
                helperText: 'Dirección física completa',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextFieldSafe(
                      controller: controller.cityController,
                      label: 'Ciudad',
                      hint: 'Lima',
                      prefixIcon: Icons.location_city,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextFieldSafe(
                      controller: controller.stateController,
                      label: 'Provincia/Estado',
                      hint: 'Lima',
                      prefixIcon: Icons.map,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextFieldSafe(
                controller: controller.zipCodeController,
                label: 'Código Postal',
                hint: '15001',
                prefixIcon: Icons.pin_drop,
                keyboardType: TextInputType.number,
                helperText: 'Código postal de la ciudad',
              ),
            ],
          ),
        )),

        const SizedBox(height: 16),

        // SECCIÓN COLAPSABLE: Configuración
        Obx(() => _buildCollapsibleSection(
          context: context,
          title: 'Configuración del Cliente',
          icon: Icons.settings,
          isExpanded: controller.showConfiguration.value,
          onToggle: () => controller.showConfiguration.toggle(),
          badge: 'Opcional',
          child: _buildConfigurationFields(context),
        )),

        const SizedBox(height: 16),

        // SECCIÓN COLAPSABLE: Información Financiera
        Obx(() => _buildCollapsibleSection(
          context: context,
          title: 'Información Financiera',
          icon: Icons.account_balance_wallet,
          isExpanded: controller.showFinancial.value,
          onToggle: () => controller.showFinancial.toggle(),
          badge: 'Opcional',
          child: _buildFinancialFields(context),
        )),
      ],
    );
  }

  Widget _buildCollapsibleSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
    String? badge,
  }) {
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
              onTap: onToggle,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(12),
                bottom: isExpanded ? Radius.zero : const Radius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icono decorado
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient.scale(0.3),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: ElegantLightTheme.glowShadow,
                      ),
                      child: Icon(icon, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),

                    // Título
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                        ),
                      ),
                    ),

                    // Badge opcional
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Icono expand/collapse
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
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
            child: isExpanded
                ? Container(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    // Esta sección ya no se usa en mobile/tablet porque se integró en _buildPersonalSection
    // Solo se mantiene para retrocompatibilidad con desktop si es necesario
    return const SizedBox.shrink();
  }

  Widget _buildConfigurationSection(BuildContext context) {
    // Esta sección ya no se usa en mobile/tablet porque se integró en _buildPersonalSection
    return const SizedBox.shrink();
  }

  Widget _buildFinancialSection(BuildContext context) {
    // Esta sección ya no se usa en mobile/tablet porque se integró en _buildPersonalSection
    return const SizedBox.shrink();
  }

  Widget _buildPersonalFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombres
        Row(
          children: [
            Expanded(
              child: CustomTextFieldSafe(
                controller: controller.firstNameController,
                label: 'Nombre *',
                hint: 'Ej: Juan',
                prefixIcon: Icons.person,
                validator: controller.validateFirstName,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextFieldSafe(
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
        CustomTextFieldSafe(
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
                (controller) => Container(
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.glassGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<DocumentType>(
                    value: controller.selectedDocumentType,
                    decoration: InputDecoration(
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.badge, color: Colors.white, size: 18),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (BuildContext context) {
                      return DocumentType.values.map((type) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tipo de Documento *',
                            style: TextStyle(
                              fontSize: 14,
                              color: ElegantLightTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList();
                    },
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
          SizedBox(height: context.verticalSpacing),
          CustomTextFieldSafe(
            controller: controller.documentNumberController,
            label: 'Número de Documento *',
            hint: 'Ej: 12345678',
            prefixIcon: Icons.numbers,
            validator: controller.validateDocumentNumber,
            onChanged: controller.onDocumentNumberChanged,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GetBuilder<CustomerFormController>(
                  builder:
                      (controller) => Container(
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.glassGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<DocumentType>(
                          value: controller.selectedDocumentType,
                          decoration: InputDecoration(
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: ElegantLightTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.badge, color: Colors.white, size: 18),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            isDense: true,
                          ),
                          isExpanded: true,
                          selectedItemBuilder: (BuildContext context) {
                            return DocumentType.values.map((type) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Tipo de Documento *',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ElegantLightTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList();
                          },
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
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomTextFieldSafe(
                  controller: controller.documentNumberController,
                  label: 'Número de Documento *',
                  hint: 'Ej: 12345678',
                  prefixIcon: Icons.numbers,
                  validator: controller.validateDocumentNumber,
                  onChanged: controller.onDocumentNumberChanged,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],

        // Indicador de disponibilidad del documento
        GetBuilder<CustomerFormController>(
          builder: (controller) {
            if (controller.isValidatingDocument) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Verificando disponibilidad...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!controller.documentAvailable) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade50,
                      Colors.red.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.errorGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Documento ya registrado',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
        Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.glassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: ElegantLightTheme.textSecondary.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectBirthDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.infoGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
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
                                        ? ElegantLightTheme.textPrimary
                                        : ElegantLightTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: controller.birthDate != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                      ),
                    ),
                    GetBuilder<CustomerFormController>(
                      builder: (controller) {
                        if (controller.birthDate != null) {
                          return IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () => controller.changeBirthDate(null),
                            tooltip: 'Limpiar fecha',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                              foregroundColor: Colors.red,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        CustomTextFieldSafe(
          controller: controller.emailController,
          label: 'Email *',
          hint: 'ejemplo@correo.com',
          prefixIcon: Icons.email,
          validator: controller.validateEmail,
          keyboardType: TextInputType.emailAddress,
          onChanged: controller.onEmailChanged,
          helperText: 'Dirección de correo electrónico principal',
        ),

        // Indicador de disponibilidad del email
        GetBuilder<CustomerFormController>(
          builder: (controller) {
            if (controller.isValidatingEmail) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Verificando disponibilidad...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!controller.emailAvailable) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade50,
                      Colors.red.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.errorGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Email ya registrado',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
              child: CustomTextFieldSafe(
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
              child: CustomTextFieldSafe(
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
        CustomTextFieldSafe(
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
              child: CustomTextFieldSafe(
                controller: controller.cityController,
                label: 'Ciudad',
                hint: 'Cúcuta',
                prefixIcon: Icons.location_city,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextFieldSafe(
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
        CustomTextFieldSafe(
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.toggle_on,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Estado del Cliente',
              style: TextStyle(
                fontSize: Responsive.getFontSize(context),
                fontWeight: FontWeight.w700,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GetBuilder<CustomerFormController>(
          builder:
              (controller) => Column(
                children:
                    CustomerStatus.values.map((status) {
                      final isSelected = controller.selectedStatus == status;
                      final gradient = _getStatusGradient(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    gradient.colors[0].withValues(alpha: 0.15),
                                    gradient.colors[1].withValues(alpha: 0.1),
                                  ],
                                )
                              : ElegantLightTheme.glassGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? gradient.colors[0].withValues(alpha: 0.5)
                                : ElegantLightTheme.textSecondary.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: gradient.colors[0].withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: RadioListTile<CustomerStatus>(
                            title: Text(
                              _getStatusLabel(status),
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              _getStatusDescription(status),
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: status,
                            groupValue: controller.selectedStatus,
                            onChanged: (CustomerStatus? value) {
                              if (value != null) {
                                controller.changeStatus(value);
                              }
                            },
                            dense: true,
                            activeColor: gradient.colors[0],
                          ),
                        ),
                      );
                    }).toList(),
              ),
        ),
      ],
    );
  }

  LinearGradient _getStatusGradient(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return ElegantLightTheme.successGradient;
      case CustomerStatus.inactive:
        return ElegantLightTheme.warningGradient;
      case CustomerStatus.suspended:
        return ElegantLightTheme.errorGradient;
    }
  }

  Widget _buildFinancialFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Límite de crédito
        CustomTextFieldSafe(
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
        CustomTextFieldSafe(
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
        CustomTextFieldSafe(
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
    final isMobile = Responsive.isMobile(context);

    return GetBuilder<CustomerFormController>(
      builder:
          (controller) => Row(
            children: [
              Expanded(
                child: Container(
                  height: isMobile ? 44 : 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleBackPress,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.close,
                              color: ElegantLightTheme.primaryBlue,
                              size: isMobile ? 18 : 20,
                            ),
                            SizedBox(width: isMobile ? 6 : 8),
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                color: ElegantLightTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Container(
                  height: isMobile ? 44 : 48,
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: ElegantLightTheme.elevatedShadow,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: controller.isSaving ? null : controller.saveCustomer,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: controller.isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save,
                                    color: Colors.white,
                                    size: isMobile ? 18 : 20,
                                  ),
                                  SizedBox(width: isMobile ? 6 : 8),
                                  Text(
                                    controller.submitButtonText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
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
        gradient: ElegantLightTheme.cardGradient,
        border: Border(
          top: BorderSide(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Restablecer Formulario',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro que deseas restablecer el formulario a los valores originales?\n\n'
            'Se perderán todos los cambios realizados.',
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: ElegantLightTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => Get.back(),
              child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: ElegantLightTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Get.back();
                controller.loadCustomer(controller.currentCustomer!.id);
                _showSuccess('Formulario restablecido');
              },
              child: const Text('Restablecer', style: TextStyle(fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.successGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Duplicar Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '¿Deseas crear un nuevo cliente basado en la información actual?\n\n'
          'Se abrirá un nuevo formulario con los datos copiados.',
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ElegantLightTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: ElegantLightTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              // TODO: Implementar duplicación
              _showSuccess('Funcionalidad de duplicación próximamente');
            },
            child: const Text('Duplicar', style: TextStyle(fontWeight: FontWeight.w600)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.clear_all, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Limpiar Formulario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro que deseas limpiar todo el formulario?\n\n'
          'Se perderá toda la información ingresada.',
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ElegantLightTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              backgroundColor: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              _clearForm();
              _showSuccess('Formulario limpiado');
            },
            child: const Text('Limpiar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.warningGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cambios sin Guardar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Hay cambios sin guardar en el formulario.\n\n'
          '¿Qué deseas hacer?',
          style: TextStyle(
            color: ElegantLightTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: ElegantLightTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () => Get.back(),
            child: const Text('Continuar Editando', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              backgroundColor: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              controller.cancel();
            },
            child: const Text('Salir sin Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: ElegantLightTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              controller.saveCustomer();
            },
            child: const Text('Guardar y Salir', style: TextStyle(fontWeight: FontWeight.w600)),
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
    int totalFields = 0;
    int completedFields = 0;

    // ✅ CAMPOS OBLIGATORIOS (6 campos)
    totalFields += 6;

    // 1. Nombre
    if (controller.firstNameController.text.trim().isNotEmpty) {
      completedFields++;
    }

    // 2. Apellido
    if (controller.lastNameController.text.trim().isNotEmpty) {
      completedFields++;
    }

    // 3. Email (debe estar lleno Y tener formato válido)
    final email = controller.emailController.text.trim();
    if (email.isNotEmpty && _isValidEmail(email)) {
      completedFields++;
    }

    // 4. Teléfono
    if (controller.phoneController.text.trim().isNotEmpty) {
      completedFields++;
    }

    // 5. Tipo de Documento
    if (controller.selectedDocumentType != null) {
      completedFields++;
    }

    // 6. Número de Documento (debe estar lleno Y disponible)
    final docNumber = controller.documentNumberController.text.trim();
    if (docNumber.isNotEmpty && controller.documentAvailable) {
      completedFields++;
    }

    // ✅ CAMPOS OPCIONALES IMPORTANTES (peso menor)
    // Agregar 0.5 puntos por cada campo opcional completado
    double optionalPoints = 0;
    int maxOptionalPoints = 4;

    // Dirección
    if (controller.addressController.text.trim().isNotEmpty) {
      optionalPoints += 0.5;
    }

    // Ciudad
    if (controller.cityController.text.trim().isNotEmpty) {
      optionalPoints += 0.5;
    }

    // Teléfono móvil
    if (controller.mobileController.text.trim().isNotEmpty) {
      optionalPoints += 0.5;
    }

    // Fecha de nacimiento
    if (controller.birthDate != null) {
      optionalPoints += 0.5;
    }

    // Límite de crédito
    if (controller.creditLimitController.text.trim().isNotEmpty) {
      optionalPoints += 0.5;
    }

    // Términos de pago
    if (controller.paymentTermsController.text.trim().isNotEmpty) {
      optionalPoints += 0.5;
    }

    // Notas
    if (controller.notesController.text.trim().isNotEmpty) {
      optionalPoints += 0.5;
    }

    // Estado
    if (controller.selectedStatus != null) {
      optionalPoints += 0.5;
    }

    // Calcular porcentaje: campos obligatorios tienen más peso
    double completion = (completedFields + optionalPoints) / (totalFields + maxOptionalPoints);

    return completion.clamp(0.0, 1.0);
  }

  // ✅ Validación de email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // ✅ Verificar si los campos obligatorios están llenos
  bool _areRequiredFieldsFilled() {
    return controller.firstNameController.text.trim().isNotEmpty &&
        controller.lastNameController.text.trim().isNotEmpty &&
        controller.emailController.text.trim().isNotEmpty &&
        controller.phoneController.text.trim().isNotEmpty &&
        controller.selectedDocumentType != null &&
        controller.documentNumberController.text.trim().isNotEmpty;
  }

  String _getFormCompletionText() {
    final completion = _calculateFormCompletion();
    final percentage = (completion * 100).round();
    return '$percentage% completado';
  }

  String _getDocumentTypeLabel(DocumentType type, BuildContext context) {
    // En TODAS las pantallas, usar nombres cortos y claros
    switch (type) {
      case DocumentType.cc:
        return 'DNI';
      case DocumentType.nit:
        return 'RUC';
      case DocumentType.ce:
        return 'CE';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.other:
        return 'Otro';
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
      backgroundColor: Colors.red.shade50,
      colorText: Colors.red.shade900,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.errorGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error, color: Colors.white, size: 20),
      ),
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      boxShadows: ElegantLightTheme.elevatedShadow,
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green.shade900,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.successGradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: ElegantLightTheme.glowShadow,
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
      ),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      boxShadows: ElegantLightTheme.elevatedShadow,
    );
  }
}
