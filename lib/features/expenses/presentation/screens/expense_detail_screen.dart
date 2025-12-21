// lib/features/expenses/presentation/screens/expense_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/expense_detail_controller.dart';
import '../../domain/entities/expense.dart';

class ExpenseDetailScreen extends GetView<ExpenseDetailController> {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantLightTheme.backgroundColor,
      appBar: _buildElegantAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Cargando detalles del gasto...');
        }

        final expense = controller.expense.value;
        if (expense == null) {
          return _buildErrorState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context, expense),
          tablet: _buildTabletLayout(context, expense),
          desktop: _buildDesktopLayout(context, expense),
        );
      }),
      //floatingActionButton: _buildMobileFAB(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  // ==================== ELEGANT APP BAR ====================
  PreferredSizeWidget _buildElegantAppBar(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

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
      title: Obx(
        () => Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Icon(
                _getExpenseTypeIcon(controller.expense.value?.type),
                size: isMobile ? 18 : 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.expense.value?.description ??
                        'Detalle del Gasto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (controller.expense.value != null)
                    Text(
                      controller.expense.value!.formattedAmount,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: () => Get.back(),
      ),
      actions: [
        if (controller.expense.value != null) ...[
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed:
                () => Get.toNamed(
                  '/expenses/edit/${controller.expense.value?.id}',
                ),
            tooltip: 'Editar gasto',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, context),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            itemBuilder:
                (context) => [
                  _buildPopupMenuItem(
                    'approve',
                    Icons.check_circle,
                    'Aprobar',
                    ElegantLightTheme.successGradient,
                  ),
                  _buildPopupMenuItem(
                    'reject',
                    Icons.cancel,
                    'Rechazar',
                    ElegantLightTheme.warningGradient,
                  ),
                  _buildPopupMenuItem(
                    'duplicate',
                    Icons.copy,
                    'Duplicar',
                    ElegantLightTheme.infoGradient,
                  ),
                  const PopupMenuDivider(),
                  _buildPopupMenuItem(
                    'delete',
                    Icons.delete,
                    'Eliminar',
                    ElegantLightTheme.errorGradient,
                    isDestructive: true,
                  ),
                ],
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String label,
    LinearGradient gradient, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isDestructive
                      ? Colors.red.shade600
                      : ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(BuildContext context, Expense expense) {
    return RefreshIndicator(
      onRefresh: () async => controller.loadExpense(),
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildExpenseProfileCard(context, expense),
            const SizedBox(height: 12),
            _buildQuickMetricsRow(context, expense),
            const SizedBox(height: 12),
            _buildDetailsCard(context, expense),
            const SizedBox(height: 12),
            _buildPaymentInfoCard(context, expense),
            const SizedBox(height: 12),
            _buildStatusCard(context, expense),
            if (expense.attachments?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildAttachmentsCard(context, expense),
            ],
            if (expense.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildNotesCard(context, expense),
            ],
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  // ==================== TABLET LAYOUT ====================
  Widget _buildTabletLayout(BuildContext context, Expense expense) {
    return RefreshIndicator(
      onRefresh: () async => controller.loadExpense(),
      color: ElegantLightTheme.primaryBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // Header compacto
                _buildCompactHeader(context, expense),
                const SizedBox(height: 12),

                // Fila 1: Detalles y Pago
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildCompactDetailsCard(context, expense),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactPaymentCard(context, expense),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Fila 2: Estado y Acciones
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildCompactStatusCard(context, expense),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactActionsCard(context, expense),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Attachments y Notas (ancho completo)
                if (expense.attachments?.isNotEmpty == true ||
                    expense.notes?.isNotEmpty == true)
                  _buildCompactExtrasCard(context, expense),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== DESKTOP LAYOUT ====================
  Widget _buildDesktopLayout(BuildContext context, Expense expense) {
    return Row(
      children: [
        // Main Content Area
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => controller.loadExpense(),
            color: ElegantLightTheme.primaryBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildExpenseProfileCard(context, expense),
                  const SizedBox(height: 16),
                  _buildQuickMetricsRow(context, expense),
                  const SizedBox(height: 16),

                  // Detalles y Pago en una fila
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildDetailsCard(context, expense)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPaymentInfoCard(context, expense),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notas y Attachments
                  if (expense.notes?.isNotEmpty == true) ...[
                    _buildNotesCard(context, expense),
                    const SizedBox(height: 16),
                  ],
                  if (expense.attachments?.isNotEmpty == true)
                    _buildAttachmentsCard(context, expense),
                ],
              ),
            ),
          ),
        ),

        // Right Sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ElegantLightTheme.cardColor,
                ElegantLightTheme.backgroundColor,
              ],
            ),
            border: Border(
              left: BorderSide(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSidebarStatusSection(context, expense),
                const SizedBox(height: 16),
                _buildActionsCard(context, expense),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== PROFILE CARD ====================
  Widget _buildExpenseProfileCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono grande del tipo de gasto
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _getExpenseTypeGradient(expense.type),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getExpenseTypeColor(
                        expense.type,
                      ).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getExpenseTypeIcon(expense.type),
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.description,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ElegantLightTheme.textPrimary,
                            ),
                          ),
                        ),
                        _buildStatusBadge(expense.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.type.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: ElegantLightTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppFormatters.formatDate(expense.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: ElegantLightTheme.textSecondary,
                          ),
                        ),
                        if (expense.vendor != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.store,
                            size: 14,
                            color: ElegantLightTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            expense.vendor!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: ElegantLightTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Monto destacado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  ElegantLightTheme.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.attach_money,
                  size: 28,
                  color: ElegantLightTheme.primaryBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  expense.formattedAmount,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ElegantLightTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK METRICS ====================
  Widget _buildQuickMetricsRow(BuildContext context, Expense expense) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: _getExpenseTypeIcon(expense.type),
            label: 'Tipo',
            value: expense.type.displayName,
            gradient: _getExpenseTypeGradient(expense.type),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.payment,
            label: 'Método',
            value: expense.paymentMethod.displayName,
            gradient: ElegantLightTheme.infoGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: _getStatusIcon(expense.status),
            label: 'Estado',
            value: _getStatusLabel(expense.status),
            gradient: _getStatusGradient(expense.status),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
  }) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: ElegantLightTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DETAILS CARD ====================
  Widget _buildDetailsCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Detalles',
            Icons.info_outline,
            ElegantLightTheme.primaryGradient,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Descripción', expense.description),
          _buildInfoRow('Tipo', expense.type.displayName),
          _buildInfoRow('Fecha', AppFormatters.formatDate(expense.date)),
          if (expense.vendor != null)
            _buildInfoRow('Proveedor', expense.vendor!),
          if (expense.invoiceNumber != null)
            _buildInfoRow('Nº Factura', expense.invoiceNumber!),
          if (expense.reference != null)
            _buildInfoRow('Referencia', expense.reference!),
          if (expense.tags?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            const Text(
              'Etiquetas',
              style: TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  expense.tags!
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ElegantLightTheme.primaryBlue.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ElegantLightTheme.primaryBlue.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: ElegantLightTheme.primaryBlue,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== PAYMENT INFO CARD ====================
  Widget _buildPaymentInfoCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Información de Pago',
            Icons.payment,
            ElegantLightTheme.successGradient,
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Monto', expense.formattedAmount),
          _buildInfoRow('Método', expense.paymentMethod.displayName),
          if (expense.paidAt != null)
            _buildInfoRow(
              'Pagado el',
              AppFormatters.formatDate(expense.paidAt!),
            ),
          if (expense.approvedAt != null) ...[
            _buildInfoRow(
              'Aprobado el',
              AppFormatters.formatDate(expense.approvedAt!),
            ),
            if (expense.approvedBy != null)
              _buildInfoRow('Aprobado por', expense.approvedBy!),
          ],
          if (expense.rejectedAt != null) ...[
            _buildInfoRow(
              'Rechazado el',
              AppFormatters.formatDate(expense.rejectedAt!),
            ),
            if (expense.rejectionReason != null)
              _buildInfoRow('Motivo', expense.rejectionReason!),
          ],
        ],
      ),
    );
  }

  // ==================== STATUS CARD ====================
  Widget _buildStatusCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Estado y Flujo',
            Icons.timeline,
            ElegantLightTheme.infoGradient,
          ),
          const SizedBox(height: 16),
          _buildStatusTimeline(expense),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(Expense expense) {
    final steps = <_TimelineStep>[];

    // Siempre mostrar cuando fue creado
    steps.add(
      _TimelineStep(
        icon: Icons.add_circle,
        label: 'Creado',
        date: expense.createdAt,
        isCompleted: true,
        color: const Color(0xFF3B82F6),
      ),
    );

    // Mostrar estado actual según el flujo
    switch (expense.status) {
      case ExpenseStatus.draft:
        steps.add(
          _TimelineStep(
            icon: Icons.edit_note,
            label: 'En Borrador',
            date: expense.updatedAt,
            isCompleted: true,
            color: const Color(0xFF6B7280),
          ),
        );
        break;
      case ExpenseStatus.pending:
        steps.add(
          _TimelineStep(
            icon: Icons.hourglass_empty,
            label: 'Pendiente de Aprobación',
            date: expense.updatedAt,
            isCompleted: true,
            color: const Color(0xFFF59E0B),
          ),
        );
        break;
      case ExpenseStatus.approved:
        steps.add(
          _TimelineStep(
            icon: Icons.check_circle,
            label: 'Aprobado',
            date: expense.approvedAt ?? expense.updatedAt,
            isCompleted: true,
            color: const Color(0xFF10B981),
          ),
        );
        break;
      case ExpenseStatus.rejected:
        steps.add(
          _TimelineStep(
            icon: Icons.cancel,
            label: 'Rechazado',
            date: expense.rejectedAt ?? expense.updatedAt,
            isCompleted: true,
            color: const Color(0xFFEF4444),
          ),
        );
        break;
      case ExpenseStatus.paid:
        // Si fue aprobado antes de ser pagado
        if (expense.approvedAt != null) {
          steps.add(
            _TimelineStep(
              icon: Icons.check_circle,
              label: 'Aprobado',
              date: expense.approvedAt!,
              isCompleted: true,
              color: const Color(0xFF10B981),
            ),
          );
        }
        steps.add(
          _TimelineStep(
            icon: Icons.paid,
            label: 'Pagado',
            date: expense.paidAt ?? expense.updatedAt,
            isCompleted: true,
            color: const Color(0xFF3B82F6),
          ),
        );
        break;
    }

    return Column(
      children:
          steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: step.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(step.icon, size: 16, color: step.color),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 24,
                        color: ElegantLightTheme.textTertiary.withValues(
                          alpha: 0.2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: step.color,
                          ),
                        ),
                        Text(
                          AppFormatters.formatDateTime(step.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: ElegantLightTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  // ==================== ATTACHMENTS CARD ====================
  Widget _buildAttachmentsCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Adjuntos',
            Icons.attach_file,
            ElegantLightTheme.warningGradient,
          ),
          const SizedBox(height: 16),
          ...expense.attachments!.map(
            (attachment) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ElegantLightTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ElegantLightTheme.primaryBlue.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileIcon(attachment),
                      size: 20,
                      color: ElegantLightTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      attachment,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ElegantLightTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, size: 20),
                    color: ElegantLightTheme.primaryBlue,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NOTES CARD ====================
  Widget _buildNotesCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader('Notas', Icons.note, ElegantLightTheme.infoGradient),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ElegantLightTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              expense.notes!,
              style: const TextStyle(
                fontSize: 14,
                color: ElegantLightTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR STATUS SECTION ====================
  Widget _buildSidebarStatusSection(BuildContext context, Expense expense) {
    final color = _getStatusColor(expense.status);

    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.04)],
      ),
      child: Column(
        children: [
          // Icono grande con estado
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: _getStatusGradient(expense.status),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _getStatusIcon(expense.status),
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getStatusLabel(expense.status),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getStatusDescription(expense.status),
            style: const TextStyle(
              fontSize: 13,
              color: ElegantLightTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildSidebarInfoRow(
            icon: Icons.calendar_today,
            label: 'Fecha del gasto',
            value: AppFormatters.formatDate(expense.date),
          ),
          const SizedBox(height: 12),
          _buildSidebarInfoRow(
            icon: Icons.attach_money,
            label: 'Monto total',
            value: expense.formattedAmount,
            valueColor: ElegantLightTheme.primaryBlue,
          ),
          const SizedBox(height: 12),
          _buildSidebarInfoRow(
            icon: _getExpenseTypeIcon(expense.type),
            label: 'Tipo de gasto',
            value: expense.type.displayName,
          ),
          if (expense.vendor != null) ...[
            const SizedBox(height: 12),
            _buildSidebarInfoRow(
              icon: Icons.store,
              label: 'Proveedor',
              value: expense.vendor!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: ElegantLightTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: ElegantLightTheme.textTertiary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ElegantLightTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== ACTIONS CARD ====================
  Widget _buildActionsCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            'Acciones',
            Icons.flash_on,
            ElegantLightTheme.warningGradient,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.edit,
            label: 'Editar Gasto',
            color: ElegantLightTheme.primaryBlue,
            onTap: () => Get.toNamed('/expenses/edit/${expense.id}'),
          ),
          const SizedBox(height: 8),
          if (expense.status == ExpenseStatus.draft ||
              expense.status == ExpenseStatus.pending)
            _buildActionButton(
              icon: Icons.check_circle,
              label: 'Aprobar',
              color: const Color(0xFF10B981),
              onTap: () => _handleMenuAction('approve', context),
            ),
          if (expense.status == ExpenseStatus.draft ||
              expense.status == ExpenseStatus.pending) ...[
            const SizedBox(height: 8),
            _buildActionButton(
              icon: Icons.cancel,
              label: 'Rechazar',
              color: const Color(0xFFF59E0B),
              onTap: () => _handleMenuAction('reject', context),
            ),
          ],
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.copy,
            label: 'Duplicar',
            color: const Color(0xFF8B5CF6),
            onTap: () => _handleMenuAction('duplicate', context),
          ),
          const SizedBox(height: 8),
          _buildActionButton(
            icon: Icons.delete,
            label: 'Eliminar',
            color: const Color(0xFFEF4444),
            onTap: () => _handleMenuAction('delete', context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: color.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== COMPACT CARDS (TABLET) ====================
  Widget _buildCompactHeader(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: _getExpenseTypeGradient(expense.type),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getExpenseTypeIcon(expense.type),
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expense.description,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ElegantLightTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(expense.status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: ElegantLightTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppFormatters.formatDate(expense.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    if (expense.vendor != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.store,
                        size: 12,
                        color: ElegantLightTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        expense.vendor!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildCompactMetric(
            expense.formattedAmount,
            'Monto',
            ElegantLightTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: ElegantLightTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDetailsCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactCardHeader(
            'Detalles',
            Icons.info_outline,
            ElegantLightTheme.primaryGradient,
          ),
          const SizedBox(height: 12),
          _buildCompactInfoRow('Tipo', expense.type.displayName),
          _buildCompactInfoRow('Método', expense.paymentMethod.displayName),
          if (expense.invoiceNumber != null)
            _buildCompactInfoRow('Nº Factura', expense.invoiceNumber!),
          if (expense.reference != null)
            _buildCompactInfoRow('Referencia', expense.reference!),
        ],
      ),
    );
  }

  Widget _buildCompactPaymentCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactCardHeader(
            'Pago',
            Icons.payment,
            ElegantLightTheme.successGradient,
          ),
          const SizedBox(height: 12),
          _buildCompactInfoRow('Monto', expense.formattedAmount),
          if (expense.paidAt != null)
            _buildCompactInfoRow(
              'Pagado',
              AppFormatters.formatDate(expense.paidAt!),
            ),
          if (expense.approvedBy != null)
            _buildCompactInfoRow('Aprobador', expense.approvedBy!),
        ],
      ),
    );
  }

  Widget _buildCompactStatusCard(BuildContext context, Expense expense) {
    final color = _getStatusColor(expense.status);

    return _FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactCardHeader(
            'Estado',
            Icons.flag,
            _getStatusGradient(expense.status),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getStatusIcon(expense.status),
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusLabel(expense.status),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      _getStatusDescription(expense.status),
                      style: const TextStyle(
                        fontSize: 11,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionsCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactCardHeader(
            'Acciones',
            Icons.flash_on,
            ElegantLightTheme.warningGradient,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.edit,
                  label: 'Editar',
                  color: ElegantLightTheme.primaryBlue,
                  onTap: () => Get.toNamed('/expenses/edit/${expense.id}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.check_circle,
                  label: 'Aprobar',
                  color: const Color(0xFF10B981),
                  onTap: () => _handleMenuAction('approve', context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.copy,
                  label: 'Duplicar',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _handleMenuAction('duplicate', context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactActionButton(
                  icon: Icons.delete,
                  label: 'Eliminar',
                  color: const Color(0xFFEF4444),
                  onTap: () => _handleMenuAction('delete', context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactExtrasCard(BuildContext context, Expense expense) {
    return _FuturisticContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (expense.notes?.isNotEmpty == true) ...[
            _buildCompactCardHeader(
              'Notas',
              Icons.note,
              ElegantLightTheme.infoGradient,
            ),
            const SizedBox(height: 8),
            Text(
              expense.notes!,
              style: const TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (expense.attachments?.isNotEmpty == true) ...[
            if (expense.notes?.isNotEmpty == true) const SizedBox(height: 12),
            _buildCompactCardHeader(
              'Adjuntos',
              Icons.attach_file,
              ElegantLightTheme.warningGradient,
            ),
            const SizedBox(height: 8),
            Text(
              '${expense.attachments!.length} archivo(s) adjunto(s)',
              style: const TextStyle(
                fontSize: 12,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================
  Widget _buildCardHeader(
    String title,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactCardHeader(
    String title,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ElegantLightTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ElegantLightTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ElegantLightTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ExpenseStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Widget _buildMobileFAB(BuildContext context) {
  //   return Obx(() {
  //     if (controller.expense.value == null) return const SizedBox.shrink();

  //     return FloatingActionButton.extended(
  //       onPressed:
  //           () => Get.toNamed('/expenses/edit/${controller.expense.value!.id}'),
  //       backgroundColor: ElegantLightTheme.primaryBlue,
  //       icon: const Icon(Icons.edit, color: Colors.white),
  //       label: const Text(
  //         'Editar',
  //         style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
  //       ),
  //     );
  //   });
  // }

  // ==================== RESPONSIVE FLOATING ACTION BUTTON ====================
  Widget? _buildFloatingActionButton(BuildContext context) {
    return Obx(() {
      // Si el gasto no ha cargado, no mostrar nada.
      if (controller.expense.value == null) {
        return const SizedBox.shrink();
      }

      // 1. Desktop y Tablet: Ocultar el FAB.
      // Las acciones están en las tarjetas o en el sidebar.
      if (!Responsive.isMobile(context)) {
        // Esto cubre Desktop y Tablet
        return const SizedBox.shrink();
      }

      // 2. Mobile: FAB Compacto (solo icono).
      // Este es el único tamaño de pantalla donde se muestra el FAB.
      return FloatingActionButton(
        onPressed:
            () => Get.toNamed('/expenses/edit/${controller.expense.value!.id}'),
        backgroundColor: ElegantLightTheme.primaryBlue,
        child: const Icon(Icons.edit, color: Colors.white, size: 24),
        tooltip: 'Editar Gasto',
      );
    });
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: _FuturisticContainer(
        width: 400,
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.errorGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gasto no encontrado',
              style: TextStyle(
                fontSize: 20,
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El gasto que buscas no existe o ha sido eliminado',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ElegantLightTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  void _handleMenuAction(String value, BuildContext context) {
    switch (value) {
      case 'approve':
        controller.approveExpense();
        break;
      case 'reject':
        _showRejectDialog(context);
        break;
      case 'duplicate':
        Get.toNamed(
          '/expenses/create',
          arguments: {'duplicate': controller.expense.value},
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar Gasto'),
        content: const Text(
          '¿Está seguro de que desea eliminar este gasto? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implementar eliminación cuando el método esté disponible
              Get.snackbar('Info', 'Funcionalidad de eliminación pendiente');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Rechazar Gasto'),
        content: const Text('¿Está seguro de que desea rechazar este gasto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Implementar rechazo cuando el método esté disponible
              Get.snackbar('Info', 'Funcionalidad de rechazo pendiente');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  IconData _getExpenseTypeIcon(ExpenseType? type) {
    switch (type) {
      case ExpenseType.operating:
        return Icons.business;
      case ExpenseType.administrative:
        return Icons.admin_panel_settings;
      case ExpenseType.sales:
        return Icons.point_of_sale;
      case ExpenseType.financial:
        return Icons.account_balance;
      case ExpenseType.extraordinary:
        return Icons.star;
      default:
        return Icons.receipt_long;
    }
  }

  LinearGradient _getExpenseTypeGradient(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return ElegantLightTheme.primaryGradient;
      case ExpenseType.administrative:
        return ElegantLightTheme.infoGradient;
      case ExpenseType.sales:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case ExpenseType.financial:
        return const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        );
      case ExpenseType.extraordinary:
        return ElegantLightTheme.warningGradient;
    }
  }

  Color _getExpenseTypeColor(ExpenseType type) {
    switch (type) {
      case ExpenseType.operating:
        return ElegantLightTheme.primaryBlue;
      case ExpenseType.administrative:
        return const Color(0xFF0EA5E9);
      case ExpenseType.sales:
        return const Color(0xFF8B5CF6);
      case ExpenseType.financial:
        return const Color(0xFF14B8A6);
      case ExpenseType.extraordinary:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return const Color(0xFF6B7280);
      case ExpenseStatus.pending:
        return const Color(0xFFF59E0B);
      case ExpenseStatus.approved:
        return const Color(0xFF10B981);
      case ExpenseStatus.rejected:
        return const Color(0xFFEF4444);
      case ExpenseStatus.paid:
        return const Color(0xFF3B82F6);
    }
  }

  LinearGradient _getStatusGradient(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
        );
      case ExpenseStatus.pending:
        return ElegantLightTheme.warningGradient;
      case ExpenseStatus.approved:
        return ElegantLightTheme.successGradient;
      case ExpenseStatus.rejected:
        return ElegantLightTheme.errorGradient;
      case ExpenseStatus.paid:
        return ElegantLightTheme.primaryGradient;
    }
  }

  IconData _getStatusIcon(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return Icons.edit_note;
      case ExpenseStatus.pending:
        return Icons.hourglass_empty;
      case ExpenseStatus.approved:
        return Icons.check_circle;
      case ExpenseStatus.rejected:
        return Icons.cancel;
      case ExpenseStatus.paid:
        return Icons.paid;
    }
  }

  String _getStatusLabel(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return 'Borrador';
      case ExpenseStatus.pending:
        return 'Pendiente';
      case ExpenseStatus.approved:
        return 'Aprobado';
      case ExpenseStatus.rejected:
        return 'Rechazado';
      case ExpenseStatus.paid:
        return 'Pagado';
    }
  }

  String _getStatusDescription(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return 'Este gasto está en borrador';
      case ExpenseStatus.pending:
        return 'Esperando aprobación';
      case ExpenseStatus.approved:
        return 'Gasto aprobado para pago';
      case ExpenseStatus.rejected:
        return 'Gasto rechazado';
      case ExpenseStatus.paid:
        return 'Gasto pagado exitosamente';
    }
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }
}

// ==================== HELPER CLASS ====================
class _TimelineStep {
  final IconData icon;
  final String label;
  final DateTime date;
  final bool isCompleted;
  final Color color;

  _TimelineStep({
    required this.icon,
    required this.label,
    required this.date,
    required this.isCompleted,
    required this.color,
  });
}

// ==================== FUTURISTIC CONTAINER ====================
class _FuturisticContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final LinearGradient? gradient;

  const _FuturisticContainer({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.width,
    this.height,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ElegantLightTheme.cardColor,
                ElegantLightTheme.backgroundColor,
              ],
            ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
