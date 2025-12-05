// lib/features/inventory/presentation/screens/create_transfer_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/create_transfer_controller.dart';
import '../widgets/transfer_form/transfer_basic_form.dart';
import '../widgets/transfer_form/warehouse_selection_section.dart';
import '../widgets/transfer_form/transfer_summary_section.dart';

class CreateTransferScreen extends GetView<CreateTransferController> {
  const CreateTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: controller.formTitle,
      showBackButton: true,
      showDrawer: false,
      actions: _buildAppBarActions(),
      body: _buildResponsiveBody(context),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: controller.resetForm,
        tooltip: 'Resetear formulario',
      ),
      const SizedBox(width: AppDimensions.paddingSmall),
    ];
  }

  Widget _buildResponsiveBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1200;
        final isDesktop = screenWidth >= 1200;

        // Usar layout simple para todas las pantallas
        return _buildSimpleLayout();
      },
    );
  }

  // ==================== SIMPLE LAYOUT ====================

  Widget _buildSimpleLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encabezado
            _buildPageHeader(),
            const SizedBox(height: AppDimensions.paddingXLarge),

            // 2. Selección de almacenes
            const WarehouseSelectionSection(),
            const SizedBox(height: AppDimensions.paddingXLarge),

            // 3. Selección de productos
            const TransferBasicForm(),
            const SizedBox(height: AppDimensions.paddingXLarge),

            // 4. Notas adicionales
            _buildNotesSection(),
            const SizedBox(height: AppDimensions.paddingXLarge),

            // 5. Botones de acción
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // ==================== MOBILE LAYOUT (DEPRECATED) ===================="

  Widget _buildMobileLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          // Progress indicator
          Obx(() => _buildMobileProgress()),

          // Form content
          Expanded(
            child: PageView(
              controller: PageController(),
              children: [
                _buildStep1Mobile(), // Product & Quantity
                _buildStep2Mobile(), // Warehouses
                _buildStep3Mobile(), // Summary & Submit
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProgress() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: [
          _buildProgressStep(1, 'Producto', true),
          Expanded(child: _buildProgressLine(true)),
          _buildProgressStep(2, 'Almacenes', false),
          Expanded(child: _buildProgressLine(false)),
          _buildProgressStep(3, 'Resumen', false),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                isActive
                    ? ElegantLightTheme.primaryGradient
                    : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                    ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                isActive ? ElegantLightTheme.primaryBlue : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient:
            isActive
                ? ElegantLightTheme.primaryGradient
                : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade300],
                ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildStep1Mobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Paso 1', 'Seleccionar Producto y Cantidad'),
          const SizedBox(height: AppDimensions.paddingLarge),
          const TransferBasicForm(),
        ],
      ),
    );
  }

  Widget _buildStep2Mobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Paso 2', 'Seleccionar Almacenes'),
          const SizedBox(height: AppDimensions.paddingLarge),
          const WarehouseSelectionSection(),
        ],
      ),
    );
  }

  Widget _buildStep3Mobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Paso 3', 'Confirmar Transferencia'),
          const SizedBox(height: AppDimensions.paddingLarge),
          const TransferSummarySection(),
          const SizedBox(height: AppDimensions.paddingXLarge),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String step, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: Get.textTheme.titleLarge?.copyWith(
            color: ElegantLightTheme.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Get.textTheme.headlineSmall?.copyWith(
            color: ElegantLightTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==================== TABLET LAYOUT ====================

  Widget _buildTabletLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          // Form panel (left)
          Expanded(flex: 2, child: _buildFormPanel()),

          // Divider
          Container(width: 1, color: Colors.grey.shade300),

          // Summary panel (right)
          Expanded(flex: 1, child: _buildSummaryPanel()),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información de la Transferencia'),
          const SizedBox(height: AppDimensions.paddingLarge),

          const TransferBasicForm(),
          const SizedBox(height: AppDimensions.paddingXLarge),

          const WarehouseSelectionSection(),
          const SizedBox(height: AppDimensions.paddingXLarge),

          _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100.withValues(alpha: 0.5),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.summarize, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Resumen',
                  style: Get.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: const TransferSummarySection(),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildSubmitButton(),
          ),
        ],
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================

  Widget _buildDesktopLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ElegantLightTheme.backgroundColor,
            ElegantLightTheme.backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          // Main form (left - 60%)
          Expanded(flex: 3, child: _buildDesktopMainForm()),

          // Divider
          Container(width: 1, color: Colors.grey.shade300),

          // Summary sidebar (right - 40%)
          Expanded(flex: 2, child: _buildDesktopSidebar()),
        ],
      ),
    );
  }

  Widget _buildDesktopMainForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: AppDimensions.paddingXLarge),

          const TransferBasicForm(),
          const SizedBox(height: AppDimensions.paddingXLarge),

          const WarehouseSelectionSection(),
          const SizedBox(height: AppDimensions.paddingXLarge),

          _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.preview, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vista Previa de la Transferencia',
                    style: Get.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: const TransferSummarySection(),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSubmitButton(),
                const SizedBox(height: AppDimensions.paddingMedium),
                _buildCancelButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION BUTTONS ====================

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Resumen compacto de la transferencia
        Obx(() => _buildCompactSummary()),
        const SizedBox(height: AppDimensions.paddingLarge),

        // Botones de acción
        Row(
          children: [
            Expanded(child: _buildCancelButton()),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(flex: 2, child: _buildSubmitButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactSummary() {
    final hasValidData =
        controller.transferItems.isNotEmpty &&
        controller.selectedFromWarehouseId.value.isNotEmpty &&
        controller.selectedToWarehouseId.value.isNotEmpty;

    if (!hasValidData) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.elevatedShadow,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: ElegantLightTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen de la Transferencia',
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildSummaryRow(
            'Productos:',
            '${controller.transferItems.length} ${controller.transferItems.length == 1 ? 'producto' : 'productos'}',
            Icons.inventory_2,
          ),
          const SizedBox(height: 8),

          _buildSummaryRow(
            'De:',
            controller.getWarehouseName(
              controller.selectedFromWarehouseId.value,
            ),
            Icons.outbox,
          ),
          const SizedBox(height: 8),

          _buildSummaryRow(
            'Hacia:',
            controller.getWarehouseName(controller.selectedToWarehouseId.value),
            Icons.inbox,
          ),
          const SizedBox(height: 8),

          _buildSummaryRow(
            'Total items:',
            '${controller.transferItems.fold<int>(0, (sum, item) => sum + item.quantity)} unidades',
            Icons.numbers,
          ),

          // Estado de validación
          const SizedBox(height: 12),
          Obx(() => _buildValidationStatus()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildValidationStatus() {
    final isValid = controller.isFormValid.value;
    final hasStockError = controller.quantityError.value.contains(
      'Stock insuficiente',
    );

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isValid) {
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
      statusText = 'Listo para transferir';
    } else if (hasStockError) {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.warning;
      statusText = 'Stock insuficiente';
    } else {
      statusColor = Colors.orange.shade700;
      statusIcon = Icons.info;
      statusText = 'Completa todos los campos';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== COMMON WIDGETS ===================="

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.swap_horizontal_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva Transferencia',
                  style: Get.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transfiere productos entre almacenes de forma segura',
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: ElegantLightTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Get.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: ElegantLightTheme.textPrimary,
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notas adicionales'),
        const SizedBox(height: AppDimensions.paddingMedium),

        Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.cardGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: TextFormField(
            controller: controller.notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Agrega notas adicionales sobre esta transferencia...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(
      () => Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient:
              controller.canSubmit
                  ? ElegantLightTheme.primaryGradient
                  : LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade400],
                  ),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              controller.canSubmit
                  ? [
                    BoxShadow(
                      color: ElegantLightTheme.primaryBlue.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.canSubmit ? controller.createTransfer : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              child:
                  controller.isCreating.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            controller.submitButtonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Cancelar',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
