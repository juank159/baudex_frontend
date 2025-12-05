// lib/features/expenses/presentation/screens/modern_expense_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/app_scaffold.dart';
import '../../../../app/config/routes/app_routes.dart';
import '../controllers/expense_form_controller.dart';
import '../widgets/modern_category_selector_widget.dart';
import '../widgets/modern_expense_selector_widget.dart';
import '../widgets/compact_expense_field.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d,]'), '');
    List<String> parts = digitsOnly.split(',');

    if (parts.length > 2) {
      digitsOnly = '${parts[0]},${parts.sublist(1).join('')}';
      parts = digitsOnly.split(',');
    }

    if (parts.length == 2 && parts[1].length > 2) {
      parts[1] = parts[1].substring(0, 2);
      digitsOnly = '${parts[0]},${parts[1]}';
    }

    if (digitsOnly.isEmpty || digitsOnly == ',') {
      return const TextEditingValue();
    }

    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    if (integerPart.isNotEmpty) {
      int? intValue = int.tryParse(integerPart);
      if (intValue == null) return oldValue;

      final formatter = NumberFormat('#,###', 'es_CO');
      integerPart = formatter.format(intValue);
    }

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

class ModernExpenseFormScreen extends GetView<ExpenseFormController> {
  const ModernExpenseFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentRoute: AppRoutes.expenses,
      appBar: _buildModernAppBar(context),
      body: ResponsiveHelper.isMobile(context)
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
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
      title: Obx(() => Row(
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
              controller.isEditMode ? 'Editar Gasto' : 'Nuevo Gasto',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 16 : 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      )),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => _handleBackPress(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white, size: 20),
          onPressed: () => _showHelp(context),
          tooltip: 'Ayuda',
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(width: 8),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBasicInfoSection(context),
                  const SizedBox(height: 12),
                  _buildExpenseDetailsSection(context),
                  const SizedBox(height: 12),
                  _buildAdditionalInfoSection(context),
                  const SizedBox(height: 12),
                  _buildAttachmentsSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Row(
      children: [
        Expanded(
          flex: isDesktop ? 2 : 1,
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    _buildBasicInfoSection(context),
                    const SizedBox(height: 16),
                    _buildExpenseDetailsSection(context),
                    const SizedBox(height: 16),
                    _buildAdditionalInfoSection(context),
                    const SizedBox(height: 16),
                    _buildAttachmentsSection(context),
                    const SizedBox(height: 16),
                    _buildDesktopActions(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Panel lateral para desktop
        if (isDesktop)
          Container(
            width: MediaQuery.of(context).size.width * 0.25,
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                        ElegantLightTheme.primaryBlueLight.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
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
                          Icons.info_outline,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Información',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ElegantLightTheme.primaryBlue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido del panel
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard(
                          icon: Icons.receipt_long,
                          title: 'Estado',
                          value: _getExpenseStatus(),
                          color: ElegantLightTheme.primaryBlue,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.category,
                          title: 'Categoría',
                          value: controller.selectedCategory.value?.name ?? 'No seleccionada',
                          color: ElegantLightTheme.accentOrange,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.account_balance_wallet,
                          title: 'Tipo',
                          value: controller.selectedType.value?.displayName ?? 'No seleccionado',
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.payment,
                          title: 'Método de Pago',
                          value: controller.selectedPaymentMethod.value?.displayName ?? 'No seleccionado',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Fecha',
                          value: controller.selectedDate.value != null
                              ? '${controller.selectedDate.value!.day}/${controller.selectedDate.value!.month}/${controller.selectedDate.value!.year}'
                              : 'No seleccionada',
                          color: Colors.blue,
                        ),
                      ],
                    )),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: ElegantLightTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: ElegantLightTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getExpenseStatus() {
    if (controller.isEditMode) {
      return 'Editando';
    }
    return 'Nuevo Gasto';
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return FuturisticContainer(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      gradient: ElegantLightTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info,
                  color: ElegantLightTheme.primaryBlue,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Text(
                'Información Básica',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),

          CompactExpenseField(
            controller: controller.descriptionController,
            label: 'Descripción',
            hint: 'Ej: Almuerzo de trabajo con cliente',
            prefixIcon: Icons.description,
            maxLines: 2,
            validator: controller.validateDescription,
          ),

          SizedBox(height: isMobile ? 10 : 12),

          isMobile
              ? Column(
                  children: [
                    CompactExpenseField(
                      controller: controller.amountController,
                      label: 'Monto',
                      hint: '0.00',
                      prefixIcon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [CurrencyInputFormatter()],
                      validator: controller.validateAmount,
                    ),
                    const SizedBox(height: 10),
                    Obx(() => _buildDateSelector(context)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: CompactExpenseField(
                        controller: controller.amountController,
                        label: 'Monto',
                        hint: '0.00',
                        prefixIcon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [CurrencyInputFormatter()],
                        validator: controller.validateAmount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => _buildDateSelector(context)),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                'Fecha',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12 : 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: controller.selectedDate.value != null
                      ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
                color: Colors.white,
                boxShadow: controller.selectedDate.value != null
                    ? [
                        BoxShadow(
                          color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: controller.selectedDate.value != null
                        ? ElegantLightTheme.primaryBlue
                        : ElegantLightTheme.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.selectedDate.value != null
                          ? _formatDate(controller.selectedDate.value!)
                          : 'Seleccionar fecha',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: controller.selectedDate.value != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: controller.selectedDate.value != null
                            ? ElegantLightTheme.textPrimary
                            : ElegantLightTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseDetailsSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return FuturisticContainer(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      gradient: ElegantLightTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: ElegantLightTheme.accentOrange,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Text(
                'Detalles del Gasto',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),

          ModernCategorySelectorWidget(
            controller: controller,
            isRequired: true,
          ),

          SizedBox(height: isMobile ? 10 : 12),

          isMobile
              ? Column(
                  children: [
                    Obx(() => ModernExpenseTypeSelector(
                      value: controller.selectedType.value,
                      onChanged: (type) => controller.selectedType.value = type,
                      isRequired: true,
                    )),
                    const SizedBox(height: 10),
                    Obx(() => ModernPaymentMethodSelector(
                      value: controller.selectedPaymentMethod.value,
                      onChanged: (method) =>
                          controller.selectedPaymentMethod.value = method,
                      isRequired: true,
                    )),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Obx(() => ModernExpenseTypeSelector(
                        value: controller.selectedType.value,
                        onChanged: (type) => controller.selectedType.value = type,
                        isRequired: true,
                      )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ModernPaymentMethodSelector(
                        value: controller.selectedPaymentMethod.value,
                        onChanged: (method) =>
                            controller.selectedPaymentMethod.value = method,
                        isRequired: true,
                      )),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return FuturisticContainer(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      gradient: ElegantLightTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: Colors.blue.shade600,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Text(
                'Información Adicional',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),

          isMobile
              ? Column(
                  children: [
                    CompactExpenseField(
                      controller: controller.vendorController,
                      label: 'Proveedor/Establecimiento',
                      hint: 'Ej: Restaurante El Buen Sabor',
                      prefixIcon: Icons.store,
                      validator: controller.validateVendor,
                    ),
                    const SizedBox(height: 10),
                    CompactExpenseField(
                      controller: controller.invoiceNumberController,
                      label: 'Número de Factura',
                      hint: 'Ej: FAC-001234',
                      prefixIcon: Icons.receipt,
                      validator: controller.validateInvoiceNumber,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: CompactExpenseField(
                        controller: controller.vendorController,
                        label: 'Proveedor/Establecimiento',
                        hint: 'Ej: Restaurante El Buen Sabor',
                        prefixIcon: Icons.store,
                        validator: controller.validateVendor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CompactExpenseField(
                        controller: controller.invoiceNumberController,
                        label: 'Número de Factura',
                        hint: 'Ej: FAC-001234',
                        prefixIcon: Icons.receipt,
                        validator: controller.validateInvoiceNumber,
                      ),
                    ),
                  ],
                ),

          SizedBox(height: isMobile ? 10 : 12),

          CompactExpenseField(
            controller: controller.referenceController,
            label: 'Referencia',
            hint: 'Ej: Proyecto ABC - Reunión con cliente',
            prefixIcon: Icons.bookmark,
            validator: controller.validateReference,
          ),

          SizedBox(height: isMobile ? 10 : 12),

          CompactExpenseField(
            controller: controller.notesController,
            label: 'Notas',
            hint: 'Información adicional sobre el gasto...',
            maxLines: 3,
            prefixIcon: Icons.note,
            validator: controller.validateNotes,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return FuturisticContainer(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      gradient: ElegantLightTheme.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.attach_file,
                  color: Colors.green.shade600,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Text(
                'Adjuntos y Etiquetas',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCompactButton(
                'Adjuntar',
                Icons.attach_file,
                ElegantLightTheme.primaryBlue,
                () => _addAttachment(context),
              ),
              _buildCompactButton(
                'Múltiples',
                Icons.file_copy,
                Colors.green.shade600,
                controller.pickMultipleFiles,
              ),
            ],
          ),

          SizedBox(height: isMobile ? 12 : 14),

          // Indicador de progreso de subida
          Obx(() {
            if (controller.isUploadingAttachments) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        const SizedBox(width: 10),
                        Text(
                          'Subiendo adjuntos...',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(controller.uploadProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ElegantLightTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: controller.uploadProgress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ElegantLightTheme.primaryBlue,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          Obx(() {
            if (controller.attachments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Sin adjuntos',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: controller.attachments.map((attachment) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getFileColor(attachment).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getFileIcon(attachment),
                          color: _getFileColor(attachment),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (attachment.size > 0)
                              Text(
                                attachment.sizeFormatted,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: ElegantLightTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => controller.removeAttachment(attachment),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),

          SizedBox(height: isMobile ? 12 : 14),

          CompactExpenseField(
            controller: controller.tagsController,
            label: 'Etiquetas',
            hint: 'viaje, cliente, urgente (separadas por comas)',
            prefixIcon: Icons.local_offer,
            onChanged: controller.updateTags,
          ),

          const SizedBox(height: 10),

          Obx(() {
            if (controller.tags.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sin etiquetas',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              );
            }

            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: controller.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.primaryGradient.scale(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: 12,
                        color: ElegantLightTheme.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          gradient: _getGradientForColor(color).scale(0.2),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    return Obx(() {
      final description = controller.descriptionController.text;
      final amount = controller.amountController.text;
      final date = controller.selectedDate.value;

      if (description.isEmpty && amount.isEmpty && date == null) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.preview, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'Vista Previa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete el formulario',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          ),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: ElegantLightTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Vista Previa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (description.isNotEmpty) ...[
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],

            if (amount.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient.scale(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$$amount',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (date != null)
              _buildPreviewRow(
                Icons.calendar_today,
                'Fecha',
                _formatDate(date),
                ElegantLightTheme.primaryBlue,
              ),

            if (controller.selectedType.value != null) ...[
              const SizedBox(height: 6),
              _buildPreviewRow(
                Icons.category,
                'Tipo',
                controller.selectedType.value!.displayName,
                ElegantLightTheme.accentOrange,
              ),
            ],

            if (controller.selectedPaymentMethod.value != null) ...[
              const SizedBox(height: 6),
              _buildPreviewRow(
                Icons.payment,
                'Pago',
                controller.selectedPaymentMethod.value!.displayName,
                Colors.green.shade600,
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPreviewRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
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
              Icon(Icons.lightbulb, size: 16, color: ElegantLightTheme.accentOrange),
              const SizedBox(width: 8),
              const Text(
                'Consejos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildTip(
            Icons.description,
            'Descripción clara',
            'Use descripciones específicas',
          ),
          const SizedBox(height: 10),
          _buildTip(
            Icons.receipt,
            'Adjunte recibos',
            'Siempre adjunte el recibo',
          ),
          const SizedBox(height: 10),
          _buildTip(
            Icons.speed,
            'Registro oportuno',
            'Registre lo antes posible',
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: ElegantLightTheme.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 10,
                  color: ElegantLightTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Cancelar',
              Icons.close,
              Colors.grey.shade600,
              () => _handleBackPress(context),
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 10),
          if (!controller.isEditMode) ...[
            Expanded(
              child: Obx(() => _buildActionButton(
                'Borrador',
                Icons.drafts,
                ElegantLightTheme.accentOrange,
                controller.canSave ? () => _saveExpenseAsDraft(context) : null,
              )),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: controller.isEditMode ? 1 : 1,
            child: Obx(() => _buildActionButton(
              controller.isEditMode ? 'Actualizar' : 'Guardar',
              controller.isEditMode ? Icons.check : Icons.save,
              Colors.green.shade600,
              controller.canSave ? () => _saveExpense(context) : null,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Cancelar',
            Icons.close,
            Colors.grey.shade600,
            () => _handleBackPress(context),
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        if (!controller.isEditMode) ...[
          Expanded(
            child: Obx(() => _buildActionButton(
              'Guardar como Borrador',
              Icons.drafts,
              ElegantLightTheme.accentOrange,
              controller.canSave ? () => _saveExpenseAsDraft(context) : null,
            )),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Obx(() => _buildActionButton(
            controller.isEditMode ? 'Actualizar Gasto' : 'Guardar Gasto',
            controller.isEditMode ? Icons.check : Icons.save,
            Colors.green.shade600,
            controller.canSave ? () => _saveExpense(context) : null,
          )),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool isPrimary = true,
  }) {
    final gradient = isPrimary ? _getGradientForColor(color) : null;

    return Container(
      decoration: BoxDecoration(
        gradient: onPressed != null && isPrimary ? gradient : null,
        color: onPressed != null
            ? (isPrimary ? null : color.withValues(alpha: 0.1))
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
        boxShadow: onPressed != null && isPrimary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: controller.isSaving
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: onPressed != null
                            ? (isPrimary ? Colors.white : color)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: onPressed != null
                                ? (isPrimary ? Colors.white : color)
                                : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ElegantLightTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: ElegantLightTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      controller.selectedDate.value = date;
    }
  }

  void _addAttachment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: ElegantLightTheme.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAttachmentOption(
              Icons.camera_alt,
              'Tomar Foto',
              ElegantLightTheme.primaryBlue,
              () {
                Get.back();
                controller.takePhoto();
              },
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            _buildAttachmentOption(
              Icons.photo_library,
              'Elegir de Galería',
              Colors.green.shade600,
              () {
                Get.back();
                controller.pickFromGallery();
              },
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            _buildAttachmentOption(
              Icons.insert_drive_file,
              'Elegir Archivo',
              ElegantLightTheme.accentOrange,
              () {
                Get.back();
                controller.pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: _getGradientForColor(color).scale(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      onTap: onTap,
    );
  }

  Future<void> _saveExpense(BuildContext context) async {
    if (!controller.formKey.currentState!.validate()) return;

    final dateError = controller.validateDate();
    if (dateError != null) {
      _showErrorSnackbar('Error de Validación', dateError);
      return;
    }

    final categoryError = controller.validateCategory();
    if (categoryError != null) {
      _showErrorSnackbar('Error de Validación', categoryError);
      return;
    }

    final typeError = controller.validateType();
    if (typeError != null) {
      _showErrorSnackbar('Error de Validación', typeError);
      return;
    }

    final paymentMethodError = controller.validatePaymentMethod();
    if (paymentMethodError != null) {
      _showErrorSnackbar('Error de Validación', paymentMethodError);
      return;
    }

    final success = await controller.saveExpense();
    if (success) {
      Get.offAllNamed(AppRoutes.expenses);
    }
  }

  Future<void> _saveExpenseAsDraft(BuildContext context) async {
    if (!controller.formKey.currentState!.validate()) return;

    final dateError = controller.validateDate();
    if (dateError != null) {
      _showErrorSnackbar('Error de Validación', dateError);
      return;
    }

    final categoryError = controller.validateCategory();
    if (categoryError != null) {
      _showErrorSnackbar('Error de Validación', categoryError);
      return;
    }

    final typeError = controller.validateType();
    if (typeError != null) {
      _showErrorSnackbar('Error de Validación', typeError);
      return;
    }

    final paymentMethodError = controller.validatePaymentMethod();
    if (paymentMethodError != null) {
      _showErrorSnackbar('Error de Validación', paymentMethodError);
      return;
    }

    final success = await controller.saveExpenseAsDraft();
    if (success) {
      Get.offAllNamed(AppRoutes.expenses);
    }
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _handleBackPress(BuildContext context) {
    if (controller.hasUnsavedChanges) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient.scale(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: ElegantLightTheme.accentOrange, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Descartar Cambios', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: const Text('¿Está seguro que desea salir? Los cambios no guardados se perderán.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Get.back();
                  Get.back();
                },
                child: const Text('Descartar', style: TextStyle(color: Colors.white)),
              ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.infoGradient.scale(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help, color: ElegantLightTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text('Ayuda - Registro de Gastos', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            '• Descripción: Sea específico sobre el gasto realizado\n\n'
            '• Monto: Ingrese el valor total del gasto\n\n'
            '• Fecha: Seleccione la fecha real del gasto\n\n'
            '• Categoría: Elija la categoría que mejor describe el gasto\n\n'
            '• Adjuntos: Incluya siempre el recibo o factura\n\n'
            '• Etiquetas: Use palabras clave para facilitar la búsqueda',
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => Get.back(),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getFileIcon(attachment) {
    if (attachment.isImage) return Icons.image;
    if (attachment.isPDF) return Icons.picture_as_pdf;
    if (attachment.isDocument) return Icons.description;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(attachment) {
    if (attachment.isImage) return Colors.green.shade600;
    if (attachment.isPDF) return Colors.red.shade600;
    if (attachment.isDocument) return ElegantLightTheme.primaryBlue;
    return Colors.grey.shade600;
  }

  LinearGradient _getGradientForColor(Color color) {
    if (color == ElegantLightTheme.primaryBlue) return ElegantLightTheme.primaryGradient;
    if (color == Colors.green.shade600) return ElegantLightTheme.successGradient;
    if (color == ElegantLightTheme.accentOrange) return ElegantLightTheme.warningGradient;
    if (color == Colors.red.shade600) return ElegantLightTheme.errorGradient;
    return ElegantLightTheme.primaryGradient;
  }
}
