// lib/features/customers/presentation/screens/customer_form_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/number_input_formatter.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/custom_text_field_safe.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/customer_form_controller.dart';
import '../../domain/entities/customer.dart';

class CustomerFormScreen extends GetView<CustomerFormController> {
  const CustomerFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: GetBuilder<CustomerFormController>(
          builder: (ctrl) {
            if (ctrl.isLoadingCustomer) {
              return const LoadingWidget(message: 'Cargando cliente...');
            }
            return _buildBody(context);
          },
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
        ),
      ),
      title: GetBuilder<CustomerFormController>(
        builder: (ctrl) => Text(
          ctrl.formTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        // Botón Guardar en AppBar para mobile
        if (Responsive.isMobile(context))
          GetBuilder<CustomerFormController>(
            builder: (ctrl) => TextButton.icon(
              onPressed: ctrl.isSaving ? null : () => _submitForm(),
              icon: ctrl.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                ctrl.isSaving ? 'Guardando...' : 'Guardar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== BODY ====================
  Widget _buildBody(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = !isMobile && !isTablet;

    // Desktop: dos columnas (formulario + sidebar)
    if (isDesktop) {
      return _buildDesktopLayout(context);
    }

    // Mobile/Tablet: solo formulario
    return _buildFormContent(context, isMobile: isMobile, isTablet: isTablet);
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna principal - Formulario
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSection(
                    context,
                    title: 'Información Personal',
                    icon: Icons.person,
                    children: _buildPersonalInfoFields(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Documento de Identidad',
                    icon: Icons.badge,
                    children: _buildDocumentFields(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Información de Contacto',
                    icon: Icons.contact_phone,
                    children: _buildContactFields(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Dirección',
                    icon: Icons.location_on,
                    children: _buildAddressFields(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Configuración',
                    icon: Icons.settings,
                    children: _buildConfigFields(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    title: 'Notas Adicionales',
                    icon: Icons.note,
                    children: _buildNotesFields(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Sidebar derecho
          Container(
            width: 320,
            height: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                left: BorderSide(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSidebarHeader(),
                  const SizedBox(height: 20),
                  _buildFormStatusCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 16),
                  _buildTipsCard(),
                  const SizedBox(height: 20),
                  _buildSidebarActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FORM CONTENT (Mobile/Tablet) ====================
  Widget _buildFormContent(BuildContext context, {required bool isMobile, required bool isTablet}) {
    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSection(
                  context,
                  title: 'Información Personal',
                  icon: Icons.person,
                  children: _buildPersonalInfoFields(context),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Documento de Identidad',
                  icon: Icons.badge,
                  children: _buildDocumentFields(context),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Información de Contacto',
                  icon: Icons.contact_phone,
                  children: _buildContactFields(context),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Dirección',
                  icon: Icons.location_on,
                  children: _buildAddressFields(context),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Configuración',
                  icon: Icons.settings,
                  children: _buildConfigFields(context),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  title: 'Notas Adicionales',
                  icon: Icons.note,
                  children: _buildNotesFields(context),
                ),
                const SizedBox(height: 32),
                if (!isMobile) _buildActionButtons(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SIDEBAR COMPONENTS ====================
  Widget _buildSidebarHeader() {
    return GetBuilder<CustomerFormController>(
      builder: (ctrl) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                ctrl.isEditMode ? Icons.edit : Icons.person_add,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctrl.isEditMode ? 'Editar Cliente' : 'Nuevo Cliente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ctrl.isEditMode
                        ? 'Modifica los datos del cliente'
                        : 'Completa el formulario',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
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

  Widget _buildFormStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.checklist,
                  size: 16,
                  color: ElegantLightTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Estado del Formulario',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Campos obligatorios con validación en tiempo real
          _buildLiveStatusItem(
            'Nombre',
            Icons.person,
            () => controller.firstNameController.text.trim().length >= 2,
            controller.firstNameController,
          ),
          _buildLiveStatusItem(
            'Apellido',
            Icons.person_outline,
            () => controller.lastNameController.text.trim().length >= 2,
            controller.lastNameController,
          ),
          _buildLiveStatusItem(
            'Tipo de Documento',
            Icons.badge,
            () => true, // Siempre tiene valor por defecto
            null,
            alwaysValid: true,
          ),
          // Número de documento con validación de duplicado
          _buildDocumentStatusItem(),
          // Email con validación de duplicado
          _buildEmailStatusItem(),
          _buildLiveStatusItem(
            'Teléfono',
            Icons.phone,
            () => controller.phoneController.text.trim().length >= 7,
            controller.phoneController,
          ),
          const SizedBox(height: 8),
          // Barra de progreso
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildLiveStatusItem(
    String label,
    IconData icon,
    bool Function() isValid,
    TextEditingController? textController, {
    bool alwaysValid = false,
  }) {
    if (alwaysValid) {
      return _buildStatusRow(label, icon, ValidationStatus.valid);
    }

    return AnimatedBuilder(
      animation: textController!,
      builder: (context, child) {
        final valid = isValid();
        return _buildStatusRow(
          label,
          icon,
          valid ? ValidationStatus.valid : ValidationStatus.pending,
        );
      },
    );
  }

  // Validación especial para documento (incluye verificación de duplicado)
  Widget _buildDocumentStatusItem() {
    return _DebouncedStatusItem(
      controller: controller,
      textController: controller.documentNumberController,
      label: 'Número de Documento',
      icon: Icons.numbers,
      minLength: 3,
      isValidating: () => controller.isValidatingDocument,
      isAvailable: () => controller.documentAvailable,
      duplicateLabel: 'Documento ya registrado',
      validatingLabel: 'Verificando documento...',
    );
  }

  // Validación especial para email (incluye verificación de duplicado)
  Widget _buildEmailStatusItem() {
    return _DebouncedStatusItem(
      controller: controller,
      textController: controller.emailController,
      label: 'Email',
      icon: Icons.email,
      minLength: 0,
      customValidator: (text) => GetUtils.isEmail(text),
      isValidating: () => controller.isValidatingEmail,
      isAvailable: () => controller.emailAvailable,
      duplicateLabel: 'Email ya registrado',
      validatingLabel: 'Verificando email...',
    );
  }

  Widget _buildStatusRow(String label, IconData icon, ValidationStatus status) {
    Color iconColor;
    Color textColor;
    FontWeight fontWeight;
    IconData statusIcon;
    Color statusColor;

    switch (status) {
      case ValidationStatus.pending:
        iconColor = ElegantLightTheme.textTertiary;
        textColor = ElegantLightTheme.textSecondary;
        fontWeight = FontWeight.normal;
        statusIcon = Icons.radio_button_unchecked;
        statusColor = Colors.grey.shade400;
        break;
      case ValidationStatus.validating:
        iconColor = ElegantLightTheme.primaryBlue;
        textColor = ElegantLightTheme.primaryBlue;
        fontWeight = FontWeight.w500;
        statusIcon = Icons.hourglass_empty;
        statusColor = ElegantLightTheme.primaryBlue;
        break;
      case ValidationStatus.valid:
        iconColor = ElegantLightTheme.primaryBlue;
        textColor = ElegantLightTheme.textPrimary;
        fontWeight = FontWeight.w500;
        statusIcon = Icons.check_circle;
        statusColor = Colors.green.shade500;
        break;
      case ValidationStatus.duplicate:
        iconColor = Colors.red.shade400;
        textColor = Colors.red.shade600;
        fontWeight = FontWeight.w500;
        statusIcon = Icons.cancel;
        statusColor = Colors.red.shade500;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: status == ValidationStatus.validating
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  )
                : Icon(
                    statusIcon,
                    key: ValueKey(status),
                    size: 16,
                    color: statusColor,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return GetBuilder<CustomerFormController>(
      builder: (ctrl) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            ctrl.firstNameController,
            ctrl.lastNameController,
            ctrl.documentNumberController,
            ctrl.emailController,
            ctrl.phoneController,
          ]),
          builder: (context, child) {
            int completed = 0;
            bool hasErrors = false;
            const total = 6; // Total de campos obligatorios

            // Verificar cada campo
            if (ctrl.firstNameController.text.trim().length >= 2) completed++;
            if (ctrl.lastNameController.text.trim().length >= 2) completed++;
            if (true) completed++; // Tipo de documento siempre válido

            // Documento: válido solo si tiene contenido Y está disponible
            final docText = ctrl.documentNumberController.text.trim();
            if (docText.length >= 3 && ctrl.documentAvailable && !ctrl.isValidatingDocument) {
              completed++;
            } else if (!ctrl.documentAvailable) {
              hasErrors = true;
            }

            // Email: válido solo si tiene formato correcto Y está disponible
            final emailText = ctrl.emailController.text.trim();
            if (GetUtils.isEmail(emailText) && ctrl.emailAvailable && !ctrl.isValidatingEmail) {
              completed++;
            } else if (!ctrl.emailAvailable) {
              hasErrors = true;
            }

            if (ctrl.phoneController.text.trim().length >= 7) completed++;

            final progress = completed / total;
            final percentage = (progress * 100).toInt();

            // Determinar color basado en errores
            Color progressColor;
            if (hasErrors) {
              progressColor = Colors.red;
            } else if (progress == 1.0) {
              progressColor = Colors.green;
            } else {
              progressColor = ElegantLightTheme.primaryBlue;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso',
                      style: TextStyle(
                        fontSize: 11,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 6,
                  ),
                ),
                if (hasErrors)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.red.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Hay datos duplicados, por favor corrígelos',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (progress == 1.0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '¡Formulario completo!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.flash_on,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            'Limpiar formulario',
            Icons.refresh,
            Colors.orange,
            () => _showClearConfirmation(context),
          ),
          const SizedBox(height: 8),
          _buildQuickActionButton(
            'Ver todos los clientes',
            Icons.people,
            ElegantLightTheme.primaryBlue,
            () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Consejos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Los campos con * son obligatorios\n'
            '• El email y documento se verifican automáticamente\n'
            '• Puedes agregar notas para información adicional',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarActionButtons(BuildContext context) {
    return GetBuilder<CustomerFormController>(
      builder: (ctrl) => Column(
        children: [
          // Botón Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ctrl.isSaving ? null : () => _submitForm(),
              icon: ctrl.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: Text(ctrl.submitButtonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Botón Cancelar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: Colors.orange, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Limpiar Formulario'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas limpiar todos los campos del formulario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Limpiar todos los campos y resetear valores por defecto
              controller.clearAllFields();
              Navigator.pop(ctx);
              Get.snackbar(
                'Formulario limpiado',
                'Todos los campos han sido limpiados',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  // ==================== SECTION BUILDER ====================
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.08),
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FIELD ROW BUILDER ====================
  /// Crea una fila de campos que se adapta a mobile/tablet/desktop
  Widget _buildFieldRow(BuildContext context, List<Widget> children) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      // En mobile, campos en columna
      return Column(
        children: children.map((child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          );
        }).toList(),
      );
    }

    // En tablet/desktop, campos en fila
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index > 0 ? 8 : 0,
                right: index < children.length - 1 ? 8 : 0,
              ),
              child: child,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== PERSONAL INFO FIELDS ====================
  List<Widget> _buildPersonalInfoFields(BuildContext context) {
    return [
      _buildFieldRow(context, [
        CustomTextFieldSafe(
          controller: controller.firstNameController,
          label: 'Nombre *',
          hint: 'Ingrese el nombre',
          prefixIcon: Icons.person,
          validator: controller.validateFirstName,
        ),
        CustomTextFieldSafe(
          controller: controller.lastNameController,
          label: 'Apellido *',
          hint: 'Ingrese el apellido',
          prefixIcon: Icons.person_outline,
          validator: controller.validateLastName,
        ),
      ]),
      _buildFieldRow(context, [
        CustomTextFieldSafe(
          controller: controller.companyNameController,
          label: 'Empresa (Opcional)',
          hint: 'Nombre de la empresa',
          prefixIcon: Icons.business,
        ),
        _buildDateSelector(context),
      ]),
    ];
  }

  // ==================== DOCUMENT FIELDS ====================
  List<Widget> _buildDocumentFields(BuildContext context) {
    return [
      _buildFieldRow(context, [
        _buildDocumentTypeSelector(context),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFieldSafe(
              controller: controller.documentNumberController,
              label: 'Número de Documento *',
              hint: 'Ingrese el número',
              prefixIcon: Icons.numbers,
              validator: controller.validateDocumentNumber,
              onChanged: controller.onDocumentNumberChanged,
            ),
            // Indicador de validación
            GetBuilder<CustomerFormController>(
              builder: (ctrl) {
                if (ctrl.isValidatingDocument) {
                  return _buildValidationIndicator(
                    'Verificando...',
                    ElegantLightTheme.primaryBlue,
                    isLoading: true,
                  );
                }
                if (!ctrl.documentAvailable) {
                  return _buildValidationIndicator(
                    'Documento ya registrado',
                    Colors.red,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ]),
    ];
  }

  // ==================== CONTACT FIELDS ====================
  List<Widget> _buildContactFields(BuildContext context) {
    return [
      _buildFieldRow(context, [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextFieldSafe(
              controller: controller.emailController,
              label: 'Email *',
              hint: 'correo@ejemplo.com',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: controller.validateEmail,
              onChanged: controller.onEmailChanged,
            ),
            // Indicador de validación
            GetBuilder<CustomerFormController>(
              builder: (ctrl) {
                if (ctrl.isValidatingEmail) {
                  return _buildValidationIndicator(
                    'Verificando...',
                    ElegantLightTheme.primaryBlue,
                    isLoading: true,
                  );
                }
                if (!ctrl.emailAvailable) {
                  return _buildValidationIndicator(
                    'Email ya registrado',
                    Colors.red,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        CustomTextFieldSafe(
          controller: controller.phoneController,
          label: 'Teléfono *',
          hint: '+57 300 123 4567',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
      ]),
      _buildFieldRow(context, [
        CustomTextFieldSafe(
          controller: controller.mobileController,
          label: 'Celular (Opcional)',
          hint: '+57 300 123 4567',
          prefixIcon: Icons.smartphone,
          keyboardType: TextInputType.phone,
        ),
      ]),
    ];
  }

  // ==================== ADDRESS FIELDS ====================
  List<Widget> _buildAddressFields(BuildContext context) {
    return [
      _buildFieldRow(context, [
        CustomTextFieldSafe(
          controller: controller.addressController,
          label: 'Dirección',
          hint: 'Calle, número, apartamento',
          prefixIcon: Icons.home,
          maxLines: 2,
        ),
      ]),
      _buildFieldRow(context, [
        CustomTextFieldSafe(
          controller: controller.cityController,
          label: 'Ciudad',
          hint: 'Ciudad',
          prefixIcon: Icons.location_city,
        ),
        CustomTextFieldSafe(
          controller: controller.stateController,
          label: 'Departamento/Estado',
          hint: 'Departamento',
          prefixIcon: Icons.map,
        ),
        CustomTextFieldSafe(
          controller: controller.zipCodeController,
          label: 'Código Postal',
          hint: '000000',
          prefixIcon: Icons.pin_drop,
          keyboardType: TextInputType.number,
        ),
      ]),
    ];
  }

  // ==================== CONFIG FIELDS ====================
  List<Widget> _buildConfigFields(BuildContext context) {
    return [
      _buildFieldRow(context, [
        _buildStatusSelector(context),
        CustomTextFieldSafe(
          controller: controller.creditLimitController,
          label: 'Límite de Crédito',
          hint: '3.000.000',
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
          inputFormatters: [
            PriceInputFormatter(),
          ],
        ),
      ]),
      _buildFieldRow(context, [
        CustomTextFieldSafe(
          controller: controller.paymentTermsController,
          label: 'Términos de Pago (días)',
          hint: '30',
          prefixIcon: Icons.calendar_today,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ]),
    ];
  }

  // ==================== NOTES FIELDS ====================
  List<Widget> _buildNotesFields(BuildContext context) {
    return [
      CustomTextFieldSafe(
        controller: controller.notesController,
        label: 'Notas',
        hint: 'Información adicional sobre el cliente...',
        prefixIcon: Icons.note_add,
        maxLines: 4,
      ),
    ];
  }

  // ==================== SELECTOR: DOCUMENT TYPE ====================
  Widget _buildDocumentTypeSelector(BuildContext context) {
    return Obx(() => _buildSelector(
      context,
      label: 'Tipo de Documento *',
      value: _getDocumentTypeName(controller.selectedDocumentType),
      icon: Icons.badge,
      onTap: () => _showDocumentTypeSelector(context),
    ));
  }

  // ==================== SELECTOR: STATUS ====================
  Widget _buildStatusSelector(BuildContext context) {
    return Obx(() => _buildSelector(
      context,
      label: 'Estado',
      value: _getStatusName(controller.selectedStatus),
      icon: Icons.toggle_on,
      iconColor: _getStatusColor(controller.selectedStatus),
      onTap: () => _showStatusSelector(context),
    ));
  }

  // ==================== SELECTOR: DATE ====================
  Widget _buildDateSelector(BuildContext context) {
    return Obx(() => _buildSelector(
      context,
      label: 'Fecha de Nacimiento',
      value: controller.birthDate != null
          ? _formatDate(controller.birthDate!)
          : 'Seleccionar fecha',
      icon: Icons.calendar_today,
      onTap: () => _selectDate(context),
    ));
  }

  // ==================== GENERIC SELECTOR WIDGET ====================
  Widget _buildSelector(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: iconColor ?? ElegantLightTheme.primaryBlue),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: value.contains('Seleccionar')
                  ? ElegantLightTheme.textTertiary
                  : ElegantLightTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== VALIDATION INDICATOR ====================
  Widget _buildValidationIndicator(String text, Color color, {bool isLoading = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          else
            Icon(Icons.error, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================
  Widget _buildActionButtons(BuildContext context) {
    return GetBuilder<CustomerFormController>(
      builder: (ctrl) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: ctrl.isSaving ? null : () => _submitForm(),
              icon: ctrl.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(ctrl.submitButtonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM SHEET: DOCUMENT TYPE ====================
  void _showDocumentTypeSelector(BuildContext context) {
    _showOptionsBottomSheet(
      context,
      title: 'Tipo de Documento',
      options: DocumentType.values.map((type) => _OptionItem(
        value: type,
        label: _getDocumentTypeName(type),
        icon: Icons.badge,
        isSelected: controller.selectedDocumentType == type,
      )).toList(),
      onSelected: (value) => controller.changeDocumentType(value as DocumentType),
    );
  }

  // ==================== BOTTOM SHEET: STATUS ====================
  void _showStatusSelector(BuildContext context) {
    _showOptionsBottomSheet(
      context,
      title: 'Estado del Cliente',
      options: CustomerStatus.values.map((status) => _OptionItem(
        value: status,
        label: _getStatusName(status),
        icon: _getStatusIcon(status),
        iconColor: _getStatusColor(status),
        isSelected: controller.selectedStatus == status,
      )).toList(),
      onSelected: (value) => controller.changeStatus(value as CustomerStatus),
    );
  }

  // ==================== GENERIC BOTTOM SHEET ====================
  void _showOptionsBottomSheet(
    BuildContext context, {
    required String title,
    required List<_OptionItem> options,
    required Function(dynamic) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
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
                      gradient: ElegantLightTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.list, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Options
            ...options.map((option) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (option.iconColor ?? ElegantLightTheme.primaryBlue)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option.icon,
                  color: option.iconColor ?? ElegantLightTheme.primaryBlue,
                  size: 20,
                ),
              ),
              title: Text(option.label),
              trailing: option.isSelected
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    )
                  : null,
              onTap: () {
                onSelected(option.value);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ==================== DATE PICKER ====================
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ElegantLightTheme.primaryBlue,
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

  // ==================== SUBMIT FORM ====================
  void _submitForm() {
    if (controller.formKey.currentState?.validate() ?? false) {
      controller.saveCustomer();
    }
  }

  // ==================== HELPERS ====================
  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.cc:
        return 'Cédula de Ciudadanía';
      case DocumentType.ce:
        return 'Cédula de Extranjería';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.nit:
        return 'NIT';
      case DocumentType.other:
        return 'Otro';
    }
  }

  String _getStatusName(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return 'Activo';
      case CustomerStatus.inactive:
        return 'Inactivo';
      case CustomerStatus.suspended:
        return 'Suspendido';
    }
  }

  Color _getStatusColor(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return Colors.green;
      case CustomerStatus.inactive:
        return Colors.orange;
      case CustomerStatus.suspended:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(CustomerStatus status) {
    switch (status) {
      case CustomerStatus.active:
        return Icons.check_circle;
      case CustomerStatus.inactive:
        return Icons.pause_circle;
      case CustomerStatus.suspended:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// ==================== OPTION ITEM MODEL ====================
class _OptionItem {
  final dynamic value;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool isSelected;

  _OptionItem({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
    this.isSelected = false,
  });
}

// ==================== VALIDATION STATUS ENUM ====================
enum ValidationStatus {
  pending,    // Campo vacío o incompleto (gris)
  validating, // Verificando en servidor (azul con spinner)
  valid,      // Campo válido y disponible (verde)
  duplicate,  // Dato ya registrado (rojo con X)
}

// ==================== DEBOUNCED STATUS ITEM WIDGET ====================
class _DebouncedStatusItem extends StatefulWidget {
  final CustomerFormController controller;
  final TextEditingController textController;
  final String label;
  final IconData icon;
  final int minLength;
  final bool Function(String)? customValidator;
  final bool Function() isValidating;
  final bool Function() isAvailable;
  final String duplicateLabel;
  final String validatingLabel;

  const _DebouncedStatusItem({
    required this.controller,
    required this.textController,
    required this.label,
    required this.icon,
    required this.minLength,
    required this.isValidating,
    required this.isAvailable,
    required this.duplicateLabel,
    required this.validatingLabel,
    this.customValidator,
  });

  @override
  State<_DebouncedStatusItem> createState() => _DebouncedStatusItemState();
}

class _DebouncedStatusItemState extends State<_DebouncedStatusItem> {
  ValidationStatus _status = ValidationStatus.pending;
  String _displayLabel = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _displayLabel = widget.label;
    widget.textController.addListener(_onTextChanged);
    // Verificar estado inicial
    _updateStatus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.textController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Cancelar timer anterior
    _debounceTimer?.cancel();

    final text = widget.textController.text.trim();

    // Si está vacío, mostrar pending inmediatamente
    if (text.isEmpty) {
      setState(() {
        _status = ValidationStatus.pending;
        _displayLabel = widget.label;
      });
      return;
    }

    // Si no cumple validación básica, mostrar pending
    if (widget.customValidator != null) {
      if (!widget.customValidator!(text)) {
        setState(() {
          _status = ValidationStatus.pending;
          _displayLabel = widget.label;
        });
        return;
      }
    } else if (text.length < widget.minLength) {
      setState(() {
        _status = ValidationStatus.pending;
        _displayLabel = widget.label;
      });
      return;
    }

    // Debounce de 500ms antes de actualizar el estado
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateStatus();
    });
  }

  void _updateStatus() {
    if (!mounted) return;

    final text = widget.textController.text.trim();

    // Verificar condiciones
    if (text.isEmpty) {
      setState(() {
        _status = ValidationStatus.pending;
        _displayLabel = widget.label;
      });
      return;
    }

    // Validación personalizada (ej: email)
    if (widget.customValidator != null && !widget.customValidator!(text)) {
      setState(() {
        _status = ValidationStatus.pending;
        _displayLabel = widget.label;
      });
      return;
    }

    // Validación de longitud mínima
    if (widget.customValidator == null && text.length < widget.minLength) {
      setState(() {
        _status = ValidationStatus.pending;
        _displayLabel = widget.label;
      });
      return;
    }

    // Verificar si está validando
    if (widget.isValidating()) {
      setState(() {
        _status = ValidationStatus.validating;
        _displayLabel = widget.validatingLabel;
      });
      // Seguir verificando hasta que termine
      Future.delayed(const Duration(milliseconds: 200), _updateStatus);
      return;
    }

    // Verificar si está disponible
    if (!widget.isAvailable()) {
      setState(() {
        _status = ValidationStatus.duplicate;
        _displayLabel = widget.duplicateLabel;
      });
      return;
    }

    // Todo OK
    setState(() {
      _status = ValidationStatus.valid;
      _displayLabel = widget.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    // También escuchar cambios del controlador GetX
    return GetBuilder<CustomerFormController>(
      builder: (ctrl) {
        // Actualizar estado cuando GetBuilder se reconstruye
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateStatus();
        });

        return _buildRow();
      },
    );
  }

  Widget _buildRow() {
    Color iconColor;
    Color textColor;
    FontWeight fontWeight;
    IconData statusIcon;
    Color statusColor;

    switch (_status) {
      case ValidationStatus.pending:
        iconColor = ElegantLightTheme.textTertiary;
        textColor = ElegantLightTheme.textSecondary;
        fontWeight = FontWeight.normal;
        statusIcon = Icons.radio_button_unchecked;
        statusColor = Colors.grey.shade400;
        break;
      case ValidationStatus.validating:
        iconColor = ElegantLightTheme.primaryBlue;
        textColor = ElegantLightTheme.primaryBlue;
        fontWeight = FontWeight.w500;
        statusIcon = Icons.hourglass_empty;
        statusColor = ElegantLightTheme.primaryBlue;
        break;
      case ValidationStatus.valid:
        iconColor = ElegantLightTheme.primaryBlue;
        textColor = ElegantLightTheme.textPrimary;
        fontWeight = FontWeight.w500;
        statusIcon = Icons.check_circle;
        statusColor = Colors.green.shade500;
        break;
      case ValidationStatus.duplicate:
        iconColor = Colors.red.shade400;
        textColor = Colors.red.shade600;
        fontWeight = FontWeight.w500;
        statusIcon = Icons.cancel;
        statusColor = Colors.red.shade500;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(widget.icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _displayLabel,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _status == ValidationStatus.validating
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  )
                : Icon(
                    statusIcon,
                    key: ValueKey(_status),
                    size: 16,
                    color: statusColor,
                  ),
          ),
        ],
      ),
    );
  }
}
