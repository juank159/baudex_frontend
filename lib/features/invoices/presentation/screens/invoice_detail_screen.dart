//lib/features/invoices/presentation/screens/invoice_detail_screen.dart
import 'package:baudex_desktop/app/config/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/invoice_detail_controller.dart';
import '../bindings/invoice_binding.dart';
import '../widgets/invoice_status_widget.dart';
import '../widgets/invoice_payment_form_widget.dart';
import '../widgets/invoice_items_list_widget.dart';
import '../widgets/payment_history_widget.dart';
import '../../domain/entities/invoice.dart';
import '../../../credit_notes/presentation/widgets/invoice_credit_notes_widget.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Registrar controlador específico para esta pantalla
    InvoiceBinding.registerDetailController();
    final controller = Get.find<InvoiceDetailController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: _buildFuturisticAppBar(context, controller),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ElegantLightTheme.backgroundColor,
              ElegantLightTheme.cardColor,
            ],
          ),
        ),
        child: GetBuilder<InvoiceDetailController>(
          builder: (controller) {
            if (controller.isLoading) {
              return _buildFuturisticLoadingState();
            }

            if (!controller.hasInvoice) {
              return _buildFuturisticErrorState(context);
            }

            return ResponsiveLayout(
              mobile: _buildFuturisticMobileLayout(context, controller),
              tablet: _buildFuturisticTabletLayout(context, controller),
              desktop: _buildFuturisticDesktopLayout(context, controller),
            );
          },
        ),
      ),
      floatingActionButton: _buildFuturisticFloatingActionButton(
        context,
        controller,
      ),
    );
  }

  // ==================== FUTURISTIC STATES ====================

  Widget _buildFuturisticLoadingState() {
    return Container(
      padding: const EdgeInsets.only(top: kToolbarHeight + 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: ElegantLightTheme.glowShadow,
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cargando detalles de factura...',
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Preparando la experiencia futurista',
              style: TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: ElegantLightTheme.textSecondary.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ElegantLightTheme.primaryGradient.colors.first,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: kToolbarHeight + 20),
      child: Center(
        child: FuturisticContainer(
          margin: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.errorGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Factura no encontrada',
                style: TextStyle(
                  color: ElegantLightTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'La factura que buscas no existe o fue eliminada',
                style: TextStyle(
                  color: ElegantLightTheme.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FuturisticButton(
                text: 'Volver a Facturas',
                icon: Icons.arrow_back,
                onPressed: () => Get.offAllNamed('/invoices'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildFuturisticAppBar(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: ElegantLightTheme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: ElegantLightTheme.primaryGradient.colors.first.withValues(
                alpha: 0.3,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        onPressed: () => Get.offAllNamed(AppRoutes.invoices),
        tooltip: 'Volver a facturas',
      ),
      title: GetBuilder<InvoiceDetailController>(
        builder:
            (controller) => AnimatedContainer(
              duration: ElegantLightTheme.normalAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.invoice?.number ?? 'Factura',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (controller.hasInvoice)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Text(
                        controller.invoice!.customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ),
      actions: [
        // Editar
        GetBuilder<InvoiceDetailController>(
          builder: (controller) => controller.canEdit
              ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                  onPressed: controller.goToEditInvoice,
                  tooltip: 'Editar factura',
                )
              : const SizedBox.shrink(),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          onPressed: () => controller.refreshInvoice(),
          tooltip: 'Refrescar',
        ),

        // Menú
        GetBuilder<InvoiceDetailController>(
          builder: (controller) => PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: ElegantLightTheme.cardColor,
            elevation: 8,
            shadowColor: ElegantLightTheme.primaryBlue.withValues(alpha: 0.3),
            surfaceTintColor: Colors.transparent,
            onSelected: (value) => _handleMenuAction(value, context, controller),
            itemBuilder: (context) => _buildFuturisticMenuItems(controller),
          ),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildFuturisticMenuItems(
    InvoiceDetailController controller,
  ) {
    return [
      if (controller.canPrint)
        PopupMenuItem(
          value: 'print',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildFuturisticMenuItem(
            icon: Icons.print,
            text: 'Imprimir',
            color: Colors.teal,
          ),
        ),
      PopupMenuItem(
        value: 'download_pdf',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: _buildFuturisticMenuItem(
          icon: Icons.picture_as_pdf,
          text: 'Descargar PDF',
          color: Colors.red.shade600,
        ),
      ),
      PopupMenuItem(
        value: 'share',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: _buildFuturisticMenuItem(
          icon: Icons.share,
          text: 'Compartir PDF',
          color: Colors.blue.shade600,
        ),
      ),
      if (controller.canConfirm) ...[
        const PopupMenuDivider(height: 16),
        PopupMenuItem(
          value: 'confirm',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildFuturisticMenuItem(
            icon: Icons.check_circle,
            text: 'Confirmar Factura',
            color: Colors.green.shade600,
          ),
        ),
      ],
      if (controller.canDelete) ...[
        const PopupMenuDivider(height: 16),
        PopupMenuItem(
          value: 'delete',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildFuturisticMenuItem(
            icon: Icons.delete_forever,
            text: 'Eliminar Factura',
            color: Colors.red.shade700,
          ),
        ),
      ],
    ];
  }

  Widget _buildFuturisticMenuItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ElegantLightTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: color.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ==================== FUTURISTIC LAYOUTS ====================

  Widget _buildFuturisticMobileLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: kToolbarHeight + 20,
        left: screenWidth * 0.04,
        right: screenWidth * 0.04,
        bottom: 100,
      ),
      child: Column(
        children: [
          // Header con información clave y estado
          _buildFuturisticMobileHeader(context, controller, isMobile: true),
          const SizedBox(height: 20),

          // ✅ NUEVO: Sistema de tabs como en la referencia
          _buildFuturisticTabs(context, controller, isMobile: true),
          const SizedBox(height: 20),

          // ✅ NUEVO: Contenido del tab seleccionado
          Obx(() => _buildTabContent(context, controller, isMobile: true)),

          // Espacio adicional para el floating action button
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFuturisticTabletLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: kToolbarHeight + 20,
        left: screenWidth * 0.06,
        right: screenWidth * 0.06,
        bottom: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            // Header futurístico optimizado para tablet
            _buildFuturisticTabletHeader(context, controller),
            const SizedBox(height: 32),

            // ✅ NUEVO: Sistema de tabs optimizado para tablet
            _buildFuturisticTabs(context, controller, isTablet: true),
            const SizedBox(height: 32),

            // ✅ NUEVO: Contenido del tab seleccionado optimizado para tablet
            Obx(() => _buildTabContent(context, controller, isTablet: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticDesktopLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        top: kToolbarHeight + 32, // ✅ Spacing optimizado
        left: 48, // ✅ Más espacio izquierdo
        right: 48, // ✅ Spacing balanceado en ambos lados
        bottom: 48, // ✅ Más espacio inferior
      ),
      child: Column(
        children: [
          // Header futurístico optimizado para desktop
          _buildFuturisticDesktopHeader(context, controller),
          const SizedBox(height: 20), // ✅ DRÁSTICO: Spacing mucho más pequeño
          // ✅ NUEVO: Sistema de tabs optimizado para desktop
          _buildFuturisticTabs(context, controller, isDesktop: true),
          const SizedBox(height: 20), // ✅ DRÁSTICO: Spacing mucho más pequeño
          // ✅ NUEVO: Contenido del tab seleccionado optimizado para desktop
          Obx(() => _buildTabContent(context, controller, isDesktop: true)),
        ],
      ),
    );
  }

  // ==================== FUTURISTIC HEADERS ====================

  Widget _buildFuturisticMobileHeader(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = true,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final invoice = controller.invoice!;

    // ✅ DIFERENCIACIÓN REAL: Tamaños específicos para header
    final numberSize =
        isMobile
            ? 18.0
            : isTablet
            ? 24.0
            : 16.0; // Mobile: 18, Tablet: 24, Desktop: 16
    final totalSize =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 14.0; // Mobile: 16, Tablet: 20, Desktop: 14
    final iconSize =
        isMobile
            ? 28.0
            : isTablet
            ? 36.0
            : 24.0; // Mobile: 28, Tablet: 36, Desktop: 24
    final iconPadding =
        isMobile
            ? 14.0
            : isTablet
            ? 18.0
            : 10.0; // Mobile: 14, Tablet: 18, Desktop: 10
    final spacing =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 12.0; // Mobile: 16, Tablet: 20, Desktop: 12

    return FuturisticContainer(
      hasGlow: true,
      child: Column(
        children: [
          // Información principal de la factura
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 16
                        : isTablet
                        ? 18
                        : 12,
                  ),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.number,
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: numberSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacing * 0.25),
                    Text(
                      AppFormatters.formatCurrency(invoice.total),
                      style: TextStyle(
                        color: ElegantLightTheme.primaryGradient.colors.first,
                        fontSize: totalSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado de la factura
          InvoiceStatusWidget(invoice: invoice, showDescription: true),

          // Información de vencimiento si aplica
          if (controller.isOverdue) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.red.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.errorGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Factura vencida hace ${controller.daysOverdue} días',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuturisticTabletHeader(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return _buildFuturisticMobileHeader(context, controller, isTablet: true);
  }

  Widget _buildFuturisticDesktopHeader(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return _buildFuturisticMobileHeader(context, controller, isDesktop: true);
  }

  // ==================== FUTURISTIC CARDS ====================

  /// ✅ NUEVO: Card fusionada Cliente + Totales para desktop
  Widget _buildFuturisticCustomerAndTotalsCard(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final invoice = controller.invoice!;
    final customer = invoice.customer;

    // ✅ DIFERENCIACIÓN REAL: Tamaños específicos para cada dispositivo
    final titleSize =
        isMobile
            ? 14.0
            : isTablet
            ? 18.0
            : 12.0; // Mobile: 14, Tablet: 18, Desktop: 12
    final textSize =
        isMobile
            ? 12.0
            : isTablet
            ? 15.0
            : 10.0; // Mobile: 12, Tablet: 15, Desktop: 10
    final iconSize =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 14.0; // Mobile: 16, Tablet: 20, Desktop: 14
    final cardPadding =
        isMobile
            ? 16.0
            : isTablet
            ? 18.0
            : 10.0; // Mobile: 16, Tablet: 18, Desktop: 10
    final itemSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 8.0; // Mobile: 12, Tablet: 14, Desktop: 8
    final sectionSpacing =
        isMobile
            ? 16.0
            : isTablet
            ? 18.0
            : 10.0; // Mobile: 16, Tablet: 18, Desktop: 10

    return FuturisticContainer(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.start, // ✅ Alinear contenido al inicio
        children: [
          // === SECCIÓN CLIENTE ===
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : isDesktop
                      ? 6
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : isDesktop
                        ? 8
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.infoGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.person, color: Colors.white, size: iconSize),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 14
                        : isDesktop
                        ? 8
                        : 18,
              ),
              Expanded(
                child: Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: itemSpacing),

          // Información del cliente
          if (customer != null) ...[
            _buildFuturisticInfoRow(
              'Nombre',
              invoice.customerName,
              Icons.person_outline,
              Colors.blue,
              textSize,
              isDesktop: isDesktop,
              actionIcon: Icons.visibility_outlined,
              onActionPressed: controller.goToCustomerDetail,
            ),
            if (customer.email.isNotEmpty == true)
              _buildFuturisticInfoRow(
                'Email',
                customer.email ?? '',
                Icons.email_outlined,
                Colors.green,
                textSize,
                isDesktop: isDesktop,
              ),
            if (customer.phone?.isNotEmpty == true)
              _buildFuturisticInfoRow(
                'Teléfono',
                customer.phone ?? '',
                Icons.phone_outlined,
                Colors.orange,
                textSize,
                isDesktop: isDesktop,
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.warningGradient.colors.first
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: ElegantLightTheme.warningGradient.colors.first,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cliente no encontrado',
                      style: TextStyle(
                        color: ElegantLightTheme.warningGradient.colors.first,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: sectionSpacing),

          // === SECCIÓN TOTALES ===
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : isDesktop
                      ? 6
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : isDesktop
                        ? 8
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.successGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 14
                        : isDesktop
                        ? 8
                        : 18,
              ),
              Expanded(
                child: Text(
                  'Totales',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: itemSpacing),

          // Información de totales
          _buildFuturisticInfoRow(
            'Subtotal',
            AppFormatters.formatCurrency(invoice.subtotal),
            Icons.receipt_outlined,
            Colors.blue,
            textSize,
            isDesktop: isDesktop,
          ),
          _buildFuturisticInfoRow(
            'Impuestos (${invoice.taxPercentage.toStringAsFixed(1)}%)',
            AppFormatters.formatCurrency(invoice.taxAmount),
            Icons.percent,
            Colors.orange,
            textSize,
            isDesktop: isDesktop,
          ),
          if (invoice.discountAmount > 0)
            _buildFuturisticInfoRow(
              'Descuento (${invoice.discountPercentage.toStringAsFixed(1)}%)',
              '-${AppFormatters.formatCurrency(invoice.discountAmount)}',
              Icons.local_offer,
              Colors.green,
              textSize,
              isDesktop: isDesktop,
            ),

          // Total destacado
          Container(
            margin: EdgeInsets.only(top: itemSpacing),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.primaryGradient.colors.first
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(invoice.total),
                  style: TextStyle(
                    fontSize: titleSize + 2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Placeholder card cuando no hay información adicional
  Widget _buildFuturisticPlaceholderCard(
    BuildContext context,
    String message,
    IconData icon, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final iconSize =
        isMobile
            ? 22.0
            : isTablet
            ? 20.0
            : isDesktop
            ? 18.0
            : 24.0;
    final textSize =
        isMobile
            ? 16.0
            : isTablet
            ? 14.0
            : isDesktop
            ? 12.0
            : 16.0;
    final cardPadding =
        isMobile
            ? 20.0
            : isTablet
            ? 18.0
            : isDesktop
            ? 16.0
            : 24.0;

    return FuturisticContainer(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: ElegantLightTheme.textSecondary,
              size: iconSize * 2,
            ),
          ),
          SizedBox(height: cardPadding),
          Text(
            message,
            style: TextStyle(
              color: ElegantLightTheme.textSecondary,
              fontSize: textSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticCustomerCard(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final invoice = controller.invoice!;
    final customer = invoice.customer;

    // ✅ RESPONSIVE: Desktop < Tablet < Mobile
    final titleSize =
        isMobile
            ? 20.0
            : isTablet
            ? 18.0
            : isDesktop
            ? 16.0
            : 24.0;
    final textSize =
        isMobile
            ? 16.0
            : isTablet
            ? 14.0
            : isDesktop
            ? 12.0
            : 16.0;
    final iconSize =
        isMobile
            ? 22.0
            : isTablet
            ? 20.0
            : isDesktop
            ? 18.0
            : 26.0;
    final cardPadding =
        isMobile
            ? 20.0
            : isTablet
            ? 18.0
            : isDesktop
            ? 16.0
            : 24.0;
    final itemSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 16.0
            : isDesktop
            ? 6.0
            : 20.0;

    return FuturisticContainer(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : isDesktop
                      ? 6
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : isDesktop
                        ? 8
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.infoGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.person, color: Colors.white, size: iconSize),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 14
                        : isDesktop
                        ? 8
                        : 18,
              ),
              Expanded(
                child: Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: itemSpacing),

          if (customer != null) ...[
            _buildFuturisticInfoRow(
              'Nombre',
              invoice.customerName,
              Icons.person_outline,
              Colors.blue,
              textSize,
              isDesktop: isDesktop,
              actionIcon: Icons.visibility_outlined,
              onActionPressed: controller.goToCustomerDetail,
            ),
            if (customer.email.isNotEmpty == true)
              _buildFuturisticInfoRow(
                'Email',
                customer.email ?? '',
                Icons.email_outlined,
                Colors.green,
                textSize,
                isDesktop: isDesktop,
              ),
            if (customer.phone?.isNotEmpty == true)
              _buildFuturisticInfoRow(
                'Teléfono',
                customer.phone ?? '',
                Icons.phone_outlined,
                Colors.orange,
                textSize,
                isDesktop: isDesktop,
              ),
            if (customer.address?.isNotEmpty == true)
              _buildFuturisticInfoRow(
                'Dirección',
                customer.address!,
                Icons.location_on_outlined,
                Colors.purple,
                textSize,
                isDesktop: isDesktop,
              ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ElegantLightTheme.textSecondary,
                    size: iconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Información del cliente no disponible',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: textSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFuturisticInvoiceInfoCard(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final invoice = controller.invoice!;

    // ✅ DIFERENCIACIÓN REAL: Tamaños específicos para cada dispositivo
    final titleSize =
        isMobile
            ? 14.0
            : isTablet
            ? 18.0
            : 12.0; // Mobile: 14, Tablet: 18, Desktop: 12
    final textSize =
        isMobile
            ? 12.0
            : isTablet
            ? 15.0
            : 10.0; // Mobile: 12, Tablet: 15, Desktop: 10
    final iconSize =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 14.0; // Mobile: 16, Tablet: 20, Desktop: 14
    final cardPadding =
        isMobile
            ? 16.0
            : isTablet
            ? 18.0
            : 10.0; // Mobile: 16, Tablet: 18, Desktop: 10
    final itemSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 8.0; // Mobile: 12, Tablet: 14, Desktop: 8

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.warningGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.description,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 16
                        : 20,
              ),
              Expanded(
                child: Text(
                  'Información de la Factura',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                isMobile
                    ? 16
                    : isTablet
                    ? 20
                    : 24,
          ),

          _buildFuturisticInfoRow(
            'Número',
            invoice.number,
            Icons.numbers,
            Colors.blue,
            textSize,
          ),
          _buildFuturisticInfoRow(
            'Fecha',
            AppFormatters.formatDate(invoice.date),
            Icons.calendar_today,
            Colors.green,
            textSize,
          ),
          _buildFuturisticInfoRow(
            'Vencimiento',
            AppFormatters.formatDate(invoice.dueDate),
            Icons.schedule,
            invoice.isOverdue ? Colors.red : Colors.orange,
            textSize,
          ),
          _buildFuturisticInfoRow(
            'Método de Pago',
            invoice.paymentMethodDisplayName,
            Icons.payment,
            Colors.purple,
            textSize,
          ),
          if (invoice.createdBy?.firstName != null)
            _buildFuturisticInfoRow(
              'Creada por',
              invoice.createdBy!.firstName,
              Icons.person_add,
              Colors.indigo,
              textSize,
            ),
        ],
      ),
    );
  }

  Widget _buildFuturisticItemsCard(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final invoice = controller.invoice!;

    // Tamaños responsivos
    final titleSize =
        isMobile
            ? 18.0
            : isTablet
            ? 20.0
            : 22.0;
    final iconSize =
        isMobile
            ? 20.0
            : isTablet
            ? 22.0
            : 24.0;

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.successGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 16
                        : 20,
              ),
              Expanded(
                child: Text(
                  'Items de la Factura',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.glassGradient,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ElegantLightTheme.successGradient.colors.first
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${invoice.items.length}',
                  style: TextStyle(
                    color: ElegantLightTheme.successGradient.colors.first,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                isMobile
                    ? 16
                    : isTablet
                    ? 20
                    : 24,
          ),

          if (invoice.items.isEmpty)
            Container(
              padding: EdgeInsets.all(
                isMobile
                    ? 20
                    : isTablet
                    ? 24
                    : 32,
              ),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.glassGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: ElegantLightTheme.warningGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size:
                          isMobile
                              ? 32
                              : isTablet
                              ? 40
                              : 48,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    height:
                        isMobile
                            ? 12
                            : isTablet
                            ? 16
                            : 20,
                  ),
                  Text(
                    'No hay items en esta factura',
                    style: TextStyle(
                      fontSize:
                          isMobile
                              ? 16
                              : isTablet
                              ? 18
                              : 20,
                      color: ElegantLightTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            InvoiceItemsListWidget(
              items: invoice.items,
              onItemTap: (item) {
                if (item.productId != null) {
                  controller.goToProductDetail(item.productId);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFuturisticTotalsCard(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
  }) {
    final invoice = controller.invoice!;

    // ✅ DIFERENCIACIÓN REAL: Tamaños específicos para cada dispositivo
    final titleSize =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 14.0; // Mobile: 16, Tablet: 20, Desktop: 14
    final textSize =
        isMobile
            ? 13.0
            : isTablet
            ? 16.0
            : 11.0; // Mobile: 13, Tablet: 16, Desktop: 11
    final totalSize =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 14.0; // Mobile: 16, Tablet: 20, Desktop: 14
    final iconSize =
        isMobile
            ? 18.0
            : isTablet
            ? 24.0
            : 16.0; // Mobile: 18, Tablet: 24, Desktop: 16
    final cardPadding =
        isMobile
            ? 16.0
            : isTablet
            ? 18.0
            : 10.0; // Mobile: 16, Tablet: 18, Desktop: 10
    final itemSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 8.0; // Mobile: 12, Tablet: 14, Desktop: 8

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.primaryGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calculate,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 16
                        : 20,
              ),
              Expanded(
                child: Text(
                  'Totales',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                isMobile
                    ? 16
                    : isTablet
                    ? 20
                    : 24,
          ),

          _buildFuturisticTotalRow(
            'Subtotal',
            invoice.subtotal,
            textSize,
            false,
          ),

          if (invoice.discountAmount > 0 || invoice.discountPercentage > 0) ...[
            if (invoice.discountPercentage > 0)
              _buildFuturisticTotalRow(
                'Descuento (${invoice.discountPercentage}%)',
                -invoice.discountAmount,
                textSize,
                false,
                color: Colors.orange,
              ),
            if (invoice.discountAmount > 0 && invoice.discountPercentage == 0)
              _buildFuturisticTotalRow(
                'Descuento',
                -invoice.discountAmount,
                textSize,
                false,
                color: Colors.orange,
              ),
          ],

          _buildFuturisticTotalRow(
            'Impuestos (${invoice.taxPercentage}%)',
            invoice.taxAmount,
            textSize,
            false,
            color: Colors.blue,
          ),

          const Divider(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.glassGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ElegantLightTheme.primaryGradient.colors.first
                    .withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: _buildFuturisticTotalRow(
              'Total',
              invoice.total,
              totalSize,
              true,
            ),
          ),

          if (invoice.paidAmount > 0) ...[
            SizedBox(
              height:
                  isMobile
                      ? 12
                      : isTablet
                      ? 16
                      : 20,
            ),
            _buildFuturisticTotalRow(
              'Pagado',
              invoice.paidAmount,
              textSize,
              false,
              color: Colors.green,
            ),
            _buildFuturisticTotalRow(
              'Saldo Pendiente',
              invoice.balanceDue,
              textSize,
              false,
              color: invoice.balanceDue > 0 ? Colors.red : Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuturisticAdditionalInfoCard(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final invoice = controller.invoice!;

    // ✅ DIFERENCIACIÓN REAL: Tamaños específicos para cada dispositivo
    final titleSize =
        isMobile
            ? 14.0
            : isTablet
            ? 18.0
            : 12.0; // Mobile: 14, Tablet: 18, Desktop: 12
    final textSize =
        isMobile
            ? 12.0
            : isTablet
            ? 15.0
            : 10.0; // Mobile: 12, Tablet: 15, Desktop: 10
    final iconSize =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 14.0; // Mobile: 16, Tablet: 20, Desktop: 14
    final cardPadding =
        isMobile
            ? 16.0
            : isTablet
            ? 18.0
            : 10.0; // Mobile: 16, Tablet: 18, Desktop: 10
    final itemSpacing =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 8.0; // Mobile: 12, Tablet: 14, Desktop: 8

    return FuturisticContainer(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : isDesktop
                      ? 6
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple,
                      Colors.purple.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : isDesktop
                        ? 8
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(Icons.info, color: Colors.white, size: iconSize),
              ),
              SizedBox(width: itemSpacing),
              Expanded(
                child: Text(
                  'Información Adicional',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: itemSpacing),

          if (invoice.notes?.isNotEmpty == true) ...[
            Container(
              padding: EdgeInsets.all(cardPadding * 1.2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withValues(alpha: 0.08),
                    Colors.blue.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icono destacado
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(itemSpacing * 0.6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade500,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.sticky_note_2_rounded,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: itemSpacing),
                      Text(
                        'Notas',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700,
                          fontSize: textSize + 2,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: itemSpacing),
                  // Contenido de las notas con estilo quote
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: itemSpacing,
                      top: itemSpacing * 0.5,
                      bottom: itemSpacing * 0.5,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.blue.shade400,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      invoice.notes!,
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: textSize + 1,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: itemSpacing * 1.2),
          ],

          if (invoice.terms?.isNotEmpty == true) ...[
            Container(
              padding: EdgeInsets.all(cardPadding * 1.2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withValues(alpha: 0.08),
                    Colors.amber.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icono destacado
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(itemSpacing * 0.6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade600,
                              Colors.amber.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.gavel_rounded,
                          color: Colors.white,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: itemSpacing),
                      Expanded(
                        child: Text(
                          'Términos y Condiciones',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade800,
                            fontSize: textSize + 2,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: itemSpacing),
                  // Contenido de los términos con estilo quote
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      left: itemSpacing,
                      top: itemSpacing * 0.5,
                      bottom: itemSpacing * 0.5,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: Colors.amber.shade500,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      invoice.terms!,
                      style: TextStyle(
                        color: ElegantLightTheme.textPrimary,
                        fontSize: textSize + 1,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuturisticPaymentForm(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.successGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.successGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.payment,
                  color: Colors.white,
                  size:
                      isMobile
                          ? 20.0
                          : isTablet
                          ? 22.0
                          : 24.0,
                ),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 16
                        : 20,
              ),
              Expanded(
                child: Text(
                  'Procesar Pago',
                  style: TextStyle(
                    fontSize:
                        isMobile
                            ? 18.0
                            : isTablet
                            ? 20.0
                            : 22.0,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                isMobile
                    ? 16
                    : isTablet
                    ? 20
                    : 24,
          ),

          InvoicePaymentFormWidget(
            controller: controller,
            onCancel: controller.hidePaymentForm,
            onSubmit: controller.addPayment,
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticActionsCard(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
  }) {
    // Tamaños responsivos
    final titleSize =
        isMobile
            ? 18.0
            : isTablet
            ? 20.0
            : 22.0;
    final iconSize =
        isMobile
            ? 20.0
            : isTablet
            ? 22.0
            : 24.0;

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8
                      : isTablet
                      ? 10
                      : 12,
                ),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(
                    isMobile
                        ? 10
                        : isTablet
                        ? 12
                        : 14,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantLightTheme.warningGradient.colors.first
                          .withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.touch_app,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(
                width:
                    isMobile
                        ? 12
                        : isTablet
                        ? 16
                        : 20,
              ),
              Expanded(
                child: Text(
                  'Acciones',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                isMobile
                    ? 16
                    : isTablet
                    ? 20
                    : 24,
          ),

          // Acciones para facturas con pagos pendientes
          if (controller.canAddPayment) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: ElegantLightTheme.infoGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          controller.invoice?.status ==
                                  InvoiceStatus.partiallyPaid
                              ? 'Continuar Pago'
                              : 'Procesar Pago',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade800,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saldo pendiente: ${AppFormatters.formatCurrency(controller.remainingBalance)}',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Botones específicos según método de pago
            if (controller.invoice!.paymentMethod == PaymentMethod.credit) ...[
              SizedBox(
                width: double.infinity,
                child: FuturisticButton(
                  text:
                      controller.invoice?.status == InvoiceStatus.partiallyPaid
                          ? 'Continuar Pago a Crédito'
                          : 'Agregar Pago a Crédito',
                  icon: Icons.account_balance_wallet,
                  onPressed: controller.showCreditPaymentDialog,
                ),
              ),
            ] else if (controller.invoice!.paymentMethod ==
                    PaymentMethod.check &&
                controller.invoice?.status == InvoiceStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: FuturisticButton(
                  text: 'Confirmar Cheque',
                  icon: Icons.receipt,
                  onPressed: controller.confirmCheckPayment,
                ),
              ),
            ] else if (controller.invoice?.status == InvoiceStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: FuturisticButton(
                  text: 'Confirmar Pago Completo',
                  icon: Icons.check_circle,
                  onPressed: controller.confirmFullPayment,
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FuturisticButton(
                  text: 'Agregar Pago',
                  icon: Icons.payment,
                  onPressed: controller.togglePaymentForm,
                ),
              ),
            ],

            // ✅ NUEVO: Botón de pagos múltiples (siempre disponible si canAddPayment)
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FuturisticButton(
                text: 'Pagos Múltiples',
                icon: Icons.payments,
                onPressed: controller.showMultiplePaymentsDialog,
                gradient: ElegantLightTheme.glassGradient,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Divide el pago entre varios métodos',
              style: TextStyle(
                fontSize: 11,
                color: ElegantLightTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
            Divider(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
          ],

          // Confirmar
          if (controller.canConfirm) ...[
            SizedBox(
              width: double.infinity,
              child: FuturisticButton(
                text: 'Confirmar Factura',
                icon: Icons.check_circle,
                onPressed: controller.confirmInvoice,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Editar
          if (controller.canEdit) ...[
            SizedBox(
              width: double.infinity,
              child: FuturisticButton(
                text: 'Editar',
                icon: Icons.edit,
                onPressed: controller.goToEditInvoice,
                gradient: ElegantLightTheme.glassGradient,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Imprimir
          if (controller.canPrint) ...[
            SizedBox(
              width: double.infinity,
              child: FuturisticButton(
                text: 'Imprimir',
                icon: Icons.print,
                onPressed: controller.goToPrintInvoice,
                gradient: ElegantLightTheme.glassGradient,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Descargar PDF
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => FuturisticButton(
                text:
                    controller.isExportingPdf
                        ? 'Descargando...'
                        : 'Descargar PDF',
                icon:
                    controller.isExportingPdf
                        ? Icons.hourglass_empty
                        : Icons.picture_as_pdf,
                onPressed:
                    controller.isExportingPdf ? null : controller.downloadPdf,
                gradient: ElegantLightTheme.glassGradient,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Compartir PDF
          SizedBox(
            width: double.infinity,
            child: Obx(
              () => FuturisticButton(
                text:
                    controller.isExportingPdf
                        ? 'Compartiendo...'
                        : 'Compartir PDF',
                icon:
                    controller.isExportingPdf
                        ? Icons.hourglass_empty
                        : Icons.share,
                onPressed:
                    controller.isExportingPdf ? null : controller.shareInvoice,
                gradient: ElegantLightTheme.glassGradient,
              ),
            ),
          ),

          if (controller.canCancel || controller.canDelete) ...[
            const SizedBox(height: 20),
            Divider(
              color: ElegantLightTheme.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),

            // Eliminar
            if (controller.canDelete) ...[
              SizedBox(
                width: double.infinity,
                child: FuturisticButton(
                  text: 'Eliminar',
                  icon: Icons.delete,
                  onPressed: controller.deleteInvoice,
                  gradient: ElegantLightTheme.errorGradient,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget? _buildFuturisticFloatingActionButton(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    // Mostrar en móvil y tablet, ocultar en desktop
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (!isMobile && !isTablet) return null;

    return GetBuilder<InvoiceDetailController>(
      builder: (ctrl) {
        final invoice = ctrl.invoice;
        if (invoice == null) return const SizedBox.shrink();

        // Solo mostrar FAB para imprimir cuando la factura está pagada
        // El botón de agregar pago ya está en la sección de pagos
        if (ctrl.canPrint && invoice.status == InvoiceStatus.paid) {
          return _buildAdaptiveFAB(
            context: context,
            onPressed: ctrl.goToPrintInvoice,
            icon: Icons.print,
            label: 'Imprimir',
            color: Colors.green,
            isMobile: isMobile,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// FAB adaptativo que se ajusta al tamaño de pantalla
  Widget _buildAdaptiveFAB({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isMobile,
  }) {
    // Tamaños adaptativos
    final fabHeight = isMobile ? 48.0 : 52.0;
    final iconSize = isMobile ? 20.0 : 22.0;
    final fontSize = isMobile ? 13.0 : 14.0;
    final horizontalPadding = isMobile ? 16.0 : 20.0;
    final borderRadius = fabHeight / 2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          height: fabHeight,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== UTILITY FUNCTIONS ====================

  Widget _buildFuturisticInfoRow(
    String label,
    String value,
    IconData icon,
    Color color,
    double fontSize, {
    bool isDesktop = false,
    IconData? actionIcon,
    VoidCallback? onActionPressed,
  }) {
    // ✅ DRÁSTICO: Spacing ultra compacto para desktop
    final verticalMargin = isDesktop ? 4.0 : 12.0;
    final cardPadding = isDesktop ? 8.0 : 12.0;
    final iconPadding = isDesktop ? 4.0 : 8.0;
    final iconSize = isDesktop ? 12.0 : 16.0;
    final horizontalSpacing = isDesktop ? 8.0 : 12.0;

    return Container(
      margin: EdgeInsets.only(bottom: verticalMargin),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          SizedBox(width: horizontalSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textSecondary,
                    fontSize: fontSize - 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ElegantLightTheme.textPrimary,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
          // ✅ NUEVO: Botón de acción opcional en la parte derecha
          if (actionIcon != null && onActionPressed != null) ...[
            SizedBox(width: horizontalSpacing),
            GestureDetector(
              onTap: onActionPressed,
              child: Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ElegantLightTheme.primaryGradient.colors.first.withValues(
                        alpha: 0.1,
                      ),
                      ElegantLightTheme.primaryGradient.colors.last.withValues(
                        alpha: 0.1,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantLightTheme.primaryGradient.colors.first
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  actionIcon,
                  color: ElegantLightTheme.primaryGradient.colors.first,
                  size: iconSize + 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFuturisticTotalRow(
    String label,
    double amount,
    double fontSize,
    bool isTotal, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              fontSize: fontSize,
              color: color ?? ElegantLightTheme.textSecondary,
            ),
          ),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              fontSize: fontSize,
              color: color ?? ElegantLightTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 1000,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),

            // Estado y resumen
            CustomCard(child: _buildStatusContent(context, controller)),
            SizedBox(height: context.verticalSpacing),

            // Cliente e información en fila
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomCard(
                    child: _buildCustomerContent(context, controller),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomCard(
                    child: _buildInvoiceInfoContent(context, controller),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),

            // Items
            CustomCard(child: _buildItemsContent(context, controller)),
            SizedBox(height: context.verticalSpacing),

            // Totales y formulario de pago en fila
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomCard(
                    child: _buildTotalsContent(context, controller),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GetBuilder<InvoiceDetailController>(
                    builder: (controller) {
                      if (controller.showPaymentForm) {
                        return CustomCard(
                          child: _buildPaymentFormContent(context, controller),
                        );
                      }
                      return CustomCard(
                        child: _buildActionsContent(context, controller),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: context.verticalSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                // Estado
                CustomCard(child: _buildStatusContent(context, controller)),
                const SizedBox(height: 24),

                // Cliente e información
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomCard(
                        child: _buildCustomerContent(context, controller),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: CustomCard(
                        child: _buildInvoiceInfoContent(context, controller),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Items
                CustomCard(child: _buildItemsContent(context, controller)),
                const SizedBox(height: 24),

                // Información adicional
                CustomCard(
                  child: _buildAdditionalInfoContent(context, controller),
                ),
              ],
            ),
          ),
        ),

        // Panel lateral
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(left: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              // Header del panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Resumen de Factura',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Totales
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildTotalsContent(context, controller),
              ),

              // Formulario de pago o acciones
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GetBuilder<InvoiceDetailController>(
                    builder: (controller) {
                      if (controller.showPaymentForm) {
                        return _buildPaymentFormContent(context, controller);
                      }
                      return _buildActionsContent(context, controller);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== CONTENT SECTIONS ====================

  Widget _buildStatusCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildStatusContent(context, controller));
  }

  Widget _buildStatusContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      children: [
        InvoiceStatusWidget(invoice: invoice, showDescription: true),

        if (controller.isOverdue) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Factura vencida hace ${controller.daysOverdue} días',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildCustomerContent(context, controller));
  }

  Widget _buildCustomerContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;
    final customer = invoice.customer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Cliente',
              style: TextStyle(
                fontSize: Responsive.getFontSize(
                  context,
                  mobile: 18,
                  tablet: 20,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            if (customer != null)
              GestureDetector(
                onTap: controller.goToCustomerDetail,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ElegantLightTheme.primaryGradient.colors.first
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ElegantLightTheme.primaryGradient.colors.first
                          .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.visibility_outlined,
                    color: ElegantLightTheme.primaryGradient.colors.first,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (customer != null) ...[
          _buildInfoRow('Nombre', invoice.customerName),
          if (customer.email.isNotEmpty == true)
            _buildInfoRow('Email', customer.email),
          if (customer.phone?.isNotEmpty == true)
            _buildInfoRow('Teléfono', customer.phone!),
          if (customer.address?.isNotEmpty == true)
            _buildInfoRow('Dirección', customer.address!),
        ] else
          Text(
            'Información del cliente no disponible',
            style: TextStyle(color: Colors.grey.shade600),
          ),
      ],
    );
  }

  Widget _buildInvoiceInfoContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de la Factura',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        _buildInfoRow('Número', invoice.number),
        _buildInfoRow(
          'Fecha',
          '${invoice.date.day}/${invoice.date.month}/${invoice.date.year}',
        ),
        _buildInfoRow(
          'Vencimiento',
          '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
        ),
        _buildInfoRow('Método de Pago', invoice.paymentMethodDisplayName),
        _buildInfoRow('Creada por', invoice.createdBy?.firstName ?? 'N/A'),
      ],
    );
  }

  Widget _buildItemsCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildItemsContent(context, controller));
  }

  Widget _buildItemsContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Items de la Factura',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // ✅ MEJORA: Mostrar items con descripción visible o mensaje si está vacío
        if (invoice.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 12),
                Text(
                  'No hay items en esta factura',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          InvoiceItemsListWidget(
            items: invoice.items,
            onItemTap: (item) {
              if (item.productId != null) {
                controller.goToProductDetail(item.productId);
              }
            },
          ),
      ],
    );
  }

  Widget _buildTotalsCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildTotalsContent(context, controller));
  }

  Widget _buildTotalsContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Totales',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        _buildTotalRow('Subtotal', invoice.subtotal),

        if (invoice.discountAmount > 0 || invoice.discountPercentage > 0) ...[
          if (invoice.discountPercentage > 0)
            _buildTotalRow(
              'Descuento (${invoice.discountPercentage}%)',
              -invoice.discountAmount,
            ),
          if (invoice.discountAmount > 0 && invoice.discountPercentage == 0)
            _buildTotalRow('Descuento', -invoice.discountAmount),
        ],

        _buildTotalRow(
          'Impuestos (${invoice.taxPercentage}%)',
          invoice.taxAmount,
        ),

        const Divider(),
        _buildTotalRow('Total', invoice.total, isTotal: true),

        if (invoice.paidAmount > 0) ...[
          const SizedBox(height: 8),
          _buildTotalRow('Pagado', invoice.paidAmount, color: Colors.green),
          _buildTotalRow(
            'Saldo Pendiente',
            invoice.balanceDue,
            color: invoice.balanceDue > 0 ? Colors.red : Colors.green,
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfoCard(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildAdditionalInfoContent(context, controller));
  }

  Widget _buildAdditionalInfoContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    final invoice = controller.invoice!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Adicional',
          style: TextStyle(
            fontSize: Responsive.getFontSize(context, mobile: 18, tablet: 20),
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        if (invoice.notes?.isNotEmpty == true) ...[
          Text(
            'Notas:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(invoice.notes!, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 16),
        ],

        if (invoice.terms?.isNotEmpty == true) ...[
          Text(
            'Términos y Condiciones:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(invoice.terms!, style: const TextStyle(color: Colors.black87)),
        ],
      ],
    );
  }

  Widget _buildPaymentForm(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return CustomCard(child: _buildPaymentFormContent(context, controller));
  }

  Widget _buildPaymentFormContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return InvoicePaymentFormWidget(
      controller: controller,
      onCancel: controller.hidePaymentForm,
      onSubmit: controller.addPayment,
    );
  }

  // ==================== PANEL DE ACCIONES MEJORADO ====================
  // Reemplazar el método _buildActionsContent en invoice_detail_screen.dart

  Widget _buildActionsContent(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // ✅ ACCIONES PARA FACTURAS CON PAGOS PENDIENTES (PENDING O PARTIALLY_PAID)
        if (controller.canAddPayment) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.invoice?.status ==
                                InvoiceStatus.partiallyPaid
                            ? 'Continuar Pago'
                            : 'Procesar Pago',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Saldo pendiente: ${AppFormatters.formatCurrency(controller.remainingBalance)}',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Botones específicos según método de pago
          if (controller.invoice!.paymentMethod == PaymentMethod.credit) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text:
                    controller.invoice?.status == InvoiceStatus.partiallyPaid
                        ? 'Continuar Pago a Crédito'
                        : 'Agregar Pago a Crédito',
                icon: Icons.account_balance_wallet,
                onPressed: controller.showCreditPaymentDialog,
                backgroundColor: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Permite pagos parciales o totales',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (controller.invoice!.paymentMethod == PaymentMethod.check &&
              controller.invoice?.status == InvoiceStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Confirmar Cheque',
                icon: Icons.receipt,
                onPressed: controller.confirmCheckPayment,
                backgroundColor: Colors.orange.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Marca la factura como pagada',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (controller.invoice?.status == InvoiceStatus.pending) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Confirmar Pago Completo',
                icon: Icons.check_circle,
                onPressed: controller.confirmFullPayment,
                backgroundColor: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirma el pago y marca como pagada',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Agregar Pago',
                icon: Icons.payment,
                onPressed: controller.togglePaymentForm,
              ),
            ),
          ],

          // ✅ NUEVO: Botón de pagos múltiples (siempre disponible si canAddPayment)
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Pagos Múltiples',
              icon: Icons.payments,
              type: ButtonType.outline,
              onPressed: controller.showMultiplePaymentsDialog,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Divide el pago entre varios métodos (efectivo + Nequi, etc.)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
        ],

        // Confirmar
        if (controller.canConfirm) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Confirmar Factura',
              icon: Icons.check_circle,
              onPressed: controller.confirmInvoice,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Editar
        if (controller.canEdit) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Editar',
              icon: Icons.edit,
              type: ButtonType.outline,
              onPressed: controller.goToEditInvoice,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Imprimir
        if (controller.canPrint) ...[
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Imprimir',
              icon: Icons.print,
              type: ButtonType.outline,
              onPressed: controller.goToPrintInvoice,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Descargar PDF
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => CustomButton(
              text:
                  controller.isExportingPdf
                      ? 'Descargando...'
                      : 'Descargar PDF',
              icon:
                  controller.isExportingPdf
                      ? Icons.hourglass_empty
                      : Icons.picture_as_pdf,
              type: ButtonType.outline,
              onPressed:
                  controller.isExportingPdf ? null : controller.downloadPdf,
              isLoading: controller.isExportingPdf,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Compartir PDF
        SizedBox(
          width: double.infinity,
          child: Obx(
            () => CustomButton(
              text:
                  controller.isExportingPdf
                      ? 'Compartiendo...'
                      : 'Compartir PDF',
              icon:
                  controller.isExportingPdf
                      ? Icons.hourglass_empty
                      : Icons.share,
              type: ButtonType.outline,
              onPressed:
                  controller.isExportingPdf ? null : controller.shareInvoice,
              isLoading: controller.isExportingPdf,
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (controller.canCancel || controller.canDelete) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Cancelar
          if (controller.canCancel) ...[
            // SizedBox(
            //   width: double.infinity,
            //   child: CustomButton(
            //     text: 'Cancelar Factura',
            //     icon: Icons.cancel,
            //     type: ButtonType.outline,
            //     onPressed: controller.cancelInvoice,
            //     textColor: Colors.orange,
            //   ),
            // ),
            const SizedBox(height: 12),
          ],

          // Eliminar
          if (controller.canDelete) ...[
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Eliminar',
                icon: Icons.delete,
                type: ButtonType.outline,
                onPressed: controller.deleteInvoice,
                textColor: Colors.red,
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ==================== UTILITY WIDGETS ====================

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color:
                    Colors
                        .black87, // ✅ Cambiado de Colors.black54 a Colors.black87
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: color ?? Colors.grey.shade800,
            ),
          ),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Factura no encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La factura que buscas no existe o fue eliminada',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Volver a Facturas',
            onPressed: () => Get.offAllNamed('/invoices'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    if (!context.isMobile) return null;

    return GetBuilder<InvoiceDetailController>(
      builder: (controller) {
        if (controller.showPaymentForm) {
          return FloatingActionButton(
            onPressed: controller.hidePaymentForm,
            backgroundColor: Colors.grey,
            child: const Icon(Icons.close),
          );
        }

        // ✅ LÓGICA CORREGIDA - INCLUIR PARTIALLY_PAID
        if (controller.canAddPayment) {
          // Para facturas PENDING o PARTIALLY_PAID con método CREDIT
          if ((controller.invoice?.status == InvoiceStatus.pending ||
                  controller.invoice?.status == InvoiceStatus.partiallyPaid) &&
              controller.invoice?.paymentMethod == PaymentMethod.credit) {
            return _buildAdaptivePaymentButton(
              onPressed: controller.showCreditPaymentDialog,
              //icon: Icons.monetization_on,
              icon: Icons.add_card_sharp,
              label: '',
              shortLabel: 'Pago',
              backgroundColor: Colors.blue.shade600,
            );
          }

          // Para facturas PENDING con método CHECK
          if (controller.invoice?.status == InvoiceStatus.pending &&
              controller.invoice?.paymentMethod == PaymentMethod.check) {
            return _buildAdaptivePaymentButton(
              onPressed: controller.confirmCheckPayment,
              icon: Icons.receipt,
              label: 'Confirmar Cheque',
              shortLabel: 'Cheque',
              backgroundColor: Colors.orange.shade600,
            );
          }

          // Para facturas PENDING con otros métodos
          if (controller.invoice?.status == InvoiceStatus.pending &&
              (controller.invoice?.paymentMethod == PaymentMethod.cash ||
                  controller.invoice?.paymentMethod ==
                      PaymentMethod.creditCard ||
                  controller.invoice?.paymentMethod ==
                      PaymentMethod.debitCard ||
                  controller.invoice?.paymentMethod ==
                      PaymentMethod.bankTransfer)) {
            return _buildAdaptivePaymentButton(
              onPressed: controller.confirmFullPayment,
              icon: Icons.check_circle,
              label: 'Confirmar Pago',
              shortLabel: 'Confirmar',
              backgroundColor: Colors.green.shade600,
            );
          }

          // Para cualquier otra factura que puede recibir pagos
          return _buildAdaptivePaymentButton(
            onPressed: controller.togglePaymentForm,
            icon: Icons.payment,
            label: 'Agregar Pago',
            shortLabel: 'Pago',
          );
        }

        if (controller.canPrint) {
          return FloatingActionButton(
            onPressed: controller.goToPrintInvoice,
            child: const Icon(Icons.print),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget? _buildBottomActions(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    if (!context.isMobile) return null;

    return GetBuilder<InvoiceDetailController>(
      builder: (controller) {
        if (controller.showPaymentForm) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                if (controller.canEdit) ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Editar',
                      icon: Icons.edit,
                      type: ButtonType.outline,
                      onPressed: controller.goToEditInvoice,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (controller.canConfirm) ...[
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Confirmar',
                      icon: Icons.check_circle,
                      onPressed: controller.confirmInvoice,
                    ),
                  ),
                ] else if (controller.canPrint) ...[
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Imprimir',
                      icon: Icons.print,
                      onPressed: controller.goToPrintInvoice,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== EVENT HANDLERS ====================

  void _handleMenuAction(
    String action,
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    switch (action) {
      case 'print':
        controller.goToPrintInvoice();
        break;
      case 'download_pdf':
        controller.downloadPdf();
        break;
      case 'share':
        controller.shareInvoice();
        break;
      case 'duplicate':
        controller.duplicateInvoice();
        break;
      case 'confirm':
        controller.confirmInvoice();
        break;
      case 'cancel':
        controller.cancelInvoice();
        break;
      case 'delete':
        controller.deleteInvoice();
        break;
    }
  }

  // ==================== CLEAN APP BAR ====================

  PreferredSizeWidget _buildModernAppBar(
    BuildContext context,
    InvoiceDetailController controller,
  ) {
    return AppBar(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.offAllNamed(AppRoutes.invoices),
        tooltip: 'Volver a facturas',
      ),
      title: GetBuilder<InvoiceDetailController>(
        builder:
            (controller) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.invoice?.number ?? 'Factura',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (controller.hasInvoice)
                  Text(
                    controller.invoice!.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
      ),
      actions: [
        // Solo mostrar editar si está en borrador
        GetBuilder<InvoiceDetailController>(
          builder:
              (controller) =>
                  controller.canEdit
                      ? IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: controller.goToEditInvoice,
                        tooltip: 'Editar factura',
                      )
                      : const SizedBox.shrink(),
        ),

        // Refrescar
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () => controller.refreshInvoice(),
          tooltip: 'Refrescar',
        ),

        // Menú de opciones
        GetBuilder<InvoiceDetailController>(
          builder:
              (controller) => PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected:
                    (value) => _handleMenuAction(value, context, controller),
                itemBuilder:
                    (context) => [
                      if (controller.canPrint)
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print, color: Colors.green),
                              SizedBox(width: 12),
                              Text('Imprimir'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, color: Colors.blue),
                            SizedBox(width: 12),
                            Text('Compartir'),
                          ],
                        ),
                      ),
                      // const PopupMenuItem(
                      //   value: 'duplicate',
                      //   child: Row(
                      //     children: [
                      //       Icon(Icons.copy, color: Colors.orange),
                      //       SizedBox(width: 12),
                      //       Text('Duplicar'),
                      //     ],
                      //   ),
                      // ),
                      const PopupMenuDivider(),
                      if (controller.canConfirm)
                        const PopupMenuItem(
                          value: 'confirm',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 12),
                              Text('Confirmar'),
                            ],
                          ),
                        ),
                      if (controller.canCancel)
                        // const PopupMenuItem(
                        //   value: 'cancel',
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.cancel, color: Colors.orange),
                        //       SizedBox(width: 12),
                        //       Text('Cancelar'),
                        //     ],
                        //   ),
                        // ),
                        if (controller.canDelete) ...[
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Eliminar'),
                              ],
                            ),
                          ),
                        ],
                    ],
              ),
        ),
      ],
    );
  }

  // ==================== ADAPTIVE PAYMENT BUTTON ====================

  Widget _buildAdaptivePaymentButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required String shortLabel,
    Color? backgroundColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Obtener el ancho disponible para el botón
        final availableWidth =
            MediaQuery.of(context).size.width - 32; // Padding de pantalla

        // Calcular el ancho aproximado del texto
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Ancho estimado del botón extended (ícono + padding + texto + padding)
        final estimatedButtonWidth =
            56 + 16 + textPainter.width + 16; // Aproximación

        // Si el botón no cabe cómodamente, usar versión compacta
        if (estimatedButtonWidth > availableWidth * 0.8) {
          return FloatingActionButton.extended(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(
              shortLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            backgroundColor: backgroundColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }

        // Si hay espacio suficiente, usar texto completo
        return FloatingActionButton.extended(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          backgroundColor: backgroundColor,
        );
      },
    );
  }

  // ==================== SISTEMA DE TABS ====================

  /// ✅ NUEVO: Sistema de tabs futurístico como en la referencia
  Widget _buildFuturisticTabs(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    // ✅ DIFERENCIACIÓN REAL: Tabs con alturas ajustadas para evitar overflow
    final tabHeight =
        isMobile
            ? 55.0
            : isTablet
            ? 70.0
            : 50.0; // Mobile: 55, Tablet: 70, Desktop: 50 (aumentado)
    final iconSize =
        isMobile
            ? 16.0
            : isTablet
            ? 22.0
            : 14.0; // Mobile: 16, Tablet: 22, Desktop: 14
    final fontSize =
        isMobile
            ? 10.0
            : isTablet
            ? 13.0
            : 9.0; // Mobile: 10, Tablet: 13, Desktop: 9

    return FuturisticContainer(
      child: SizedBox(
        height: tabHeight,
        child: Row(
          children: [
            _buildTabHeader(
              context,
              'General',
              0,
              Icons.info_outline,
              controller,
              iconSize,
              fontSize,
            ),
            _buildTabHeader(
              context,
              'Items',
              1,
              Icons.shopping_cart_outlined,
              controller,
              iconSize,
              fontSize,
            ),
            _buildTabHeader(
              context,
              'Pagos',
              2,
              Icons.payment,
              controller,
              iconSize,
              fontSize,
            ),
            _buildTabHeader(
              context,
              'Historial',
              3,
              Icons.history,
              controller,
              iconSize,
              fontSize,
            ),
            _buildTabHeader(
              context,
              'Créditos',
              4,
              Icons.receipt_long,
              controller,
              iconSize,
              fontSize,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ NUEVO: Tab header individual
  Widget _buildTabHeader(
    BuildContext context,
    String title,
    int index,
    IconData icon,
    InvoiceDetailController controller,
    double iconSize,
    double fontSize,
  ) {
    // ✅ RESPONSIVE: Spacing que se ajusta al tamaño del contenedor
    final spacing =
        fontSize < 10
            ? 2.0
            : fontSize < 12
            ? 3.0
            : 4.0;
    final verticalPadding =
        fontSize < 10
            ? 4.0
            : fontSize < 12
            ? 6.0
            : 8.0;

    return Expanded(
      child: Obx(() {
        final isSelected = controller.selectedTab.value == index;

        return GestureDetector(
          onTap: () => controller.switchTab(index),
          child: AnimatedContainer(
            duration: ElegantLightTheme.normalAnimation,
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: 4,
            ),
            margin: const EdgeInsets.all(1), // ✅ Reducido de 2 a 1
            decoration: BoxDecoration(
              gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize:
                  MainAxisSize.min, // ✅ CLAVE: Minimizar el tamaño de la Column
              children: [
                Icon(
                  icon,
                  color:
                      isSelected
                          ? Colors.white
                          : ElegantLightTheme.textSecondary,
                  size: iconSize,
                ),
                SizedBox(height: spacing), // ✅ Espaciado responsivo
                Flexible(
                  // ✅ CLAVE: Usar Flexible en lugar de Text directo
                  child: Text(
                    title,
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : ElegantLightTheme.textSecondary,
                      fontSize: fontSize,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// ✅ NUEVO: Contenido del tab seleccionado
  /// IMPORTANTE: Este método se llama dentro de un Obx, por lo que debe
  /// acceder a TODOS los observables que quiere escuchar
  Widget _buildTabContent(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    // ✅ CRÍTICO: Leer los observables para que Obx los escuche
    // Sin esto, Obx no detecta cambios en la factura
    final currentInvoice = controller.invoiceRx.value;
    final showPaymentForm = controller.showPaymentFormRx.value;
    final currentTab = controller.selectedTab.value;

    // Log para debug (quitar después de verificar que funciona)
    // ignore: avoid_print
    print('🔄 _buildTabContent rebuild - Tab: $currentTab, Invoice: ${currentInvoice?.id}, ShowForm: $showPaymentForm, Pagos: ${currentInvoice?.payments.length}, PaidAmount: ${currentInvoice?.paidAmount}');

    // ✅ RESPONSIVE: Spacing progresivo Desktop < Tablet < Mobile
    final spacing =
        isMobile
            ? 20.0
            : isTablet
            ? 18.0
            : isDesktop
            ? 16.0
            : 24.0;

    switch (currentTab) {
      case 0: // General
        return _buildGeneralTabContent(
          context,
          controller,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          spacing: spacing,
        );
      case 1: // Items
        return _buildItemsTabContent(
          context,
          controller,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          spacing: spacing,
        );
      case 2: // Pagos
        return _buildPaymentsTabContent(
          context,
          controller,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          spacing: spacing,
        );
      case 3: // Historial
        return _buildHistorialTabContent(
          context,
          controller,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          spacing: spacing,
        );
      case 4: // Notas de Crédito
        return _buildCreditNotesTabContent(
          context,
          controller,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          spacing: spacing,
        );
      default:
        return _buildGeneralTabContent(
          context,
          controller,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          spacing: spacing,
        );
    }
  }

  /// ✅ NUEVO: Tab General - Información básica
  Widget _buildGeneralTabContent(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
    required double spacing,
  }) {
    final invoice = controller.invoice!;

    if (isDesktop) {
      // ✅ Layout desktop: 3 columnas con ancho y altura uniforme
      final hasAdditionalInfo =
          invoice.notes?.isNotEmpty == true ||
          invoice.terms?.isNotEmpty == true;
      const desktopCardHeight = 480.0;

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Columna 1: Cliente + Totales fusionados
            Expanded(
              flex: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: desktopCardHeight),
                child: _buildFuturisticCustomerAndTotalsCard(
                  context,
                  controller,
                  isDesktop: true,
                ),
              ),
            ),
            SizedBox(width: spacing),
            // Columna 2: Información de la factura
            Expanded(
              flex: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: desktopCardHeight),
                child: _buildFuturisticInvoiceInfoCard(
                  context,
                  controller,
                  isDesktop: true,
                ),
              ),
            ),
            SizedBox(width: spacing),
            // Columna 3: Información adicional
            Expanded(
              flex: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: desktopCardHeight),
                child:
                    hasAdditionalInfo
                        ? _buildFuturisticAdditionalInfoCard(
                          context,
                          controller,
                          isDesktop: true,
                        )
                        : _buildFuturisticPlaceholderCard(
                          context,
                          'Sin información adicional',
                          Icons.info_outline,
                          isDesktop: true,
                        ),
              ),
            ),
          ],
        ),
      );
    } else if (isTablet) {
      // ✅ Layout tablet adaptativo según ancho de pantalla
      final hasAdditionalInfo =
          invoice.notes?.isNotEmpty == true ||
          invoice.terms?.isNotEmpty == true;
      final screenWidth = MediaQuery.of(context).size.width;

      // Para tablets pequeñas (< 850px): layout de 2 filas
      // Para tablets grandes (>= 850px): layout de 3 columnas
      final isSmallTablet = screenWidth < 850;

      if (isSmallTablet) {
        // Layout para tablets pequeñas: 2 columnas arriba + 1 fila abajo
        return Column(
          children: [
            // Primera fila: 2 columnas
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Columna 1: Cliente + Totales
                  Expanded(
                    flex: 1,
                    child: _buildFuturisticCustomerAndTotalsCard(
                      context,
                      controller,
                      isTablet: true,
                    ),
                  ),
                  SizedBox(width: spacing),
                  // Columna 2: Información de la factura
                  Expanded(
                    flex: 1,
                    child: _buildFuturisticInvoiceInfoCard(
                      context,
                      controller,
                      isTablet: true,
                    ),
                  ),
                ],
              ),
            ),
            // Segunda fila: Información adicional (ancho completo)
            if (hasAdditionalInfo) ...[
              SizedBox(height: spacing),
              _buildFuturisticAdditionalInfoCard(
                context,
                controller,
                isTablet: true,
              ),
            ],
          ],
        );
      } else {
        // Layout para tablets grandes: 3 columnas
        const tabletCardHeight = 420.0;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Columna 1: Cliente + Totales fusionados
              Expanded(
                flex: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: tabletCardHeight),
                  child: _buildFuturisticCustomerAndTotalsCard(
                    context,
                    controller,
                    isTablet: true,
                  ),
                ),
              ),
              SizedBox(width: spacing),
              // Columna 2: Información de la factura
              Expanded(
                flex: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: tabletCardHeight),
                  child: _buildFuturisticInvoiceInfoCard(
                    context,
                    controller,
                    isTablet: true,
                  ),
                ),
              ),
              SizedBox(width: spacing),
              // Columna 3: Información adicional
              Expanded(
                flex: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: tabletCardHeight),
                  child:
                      hasAdditionalInfo
                          ? _buildFuturisticAdditionalInfoCard(
                            context,
                            controller,
                            isTablet: true,
                          )
                          : _buildFuturisticPlaceholderCard(
                            context,
                            'Sin información adicional',
                            Icons.info_outline,
                            isTablet: true,
                          ),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // ✅ NUEVO Layout mobile: Una columna con altura uniforme por card
      final hasAdditionalInfo =
          invoice.notes?.isNotEmpty == true ||
          invoice.terms?.isNotEmpty == true;
      const mobileCardHeight = 320.0; // ✅ Altura fija para mobile

      return Column(
        children: [
          // Card fusionada Cliente + Totales
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: mobileCardHeight),
            child: _buildFuturisticCustomerAndTotalsCard(
              context,
              controller,
              isMobile: true,
            ),
          ),
          SizedBox(height: spacing),
          // Información de la factura
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: mobileCardHeight),
            child: _buildFuturisticInvoiceInfoCard(
              context,
              controller,
              isMobile: true,
            ),
          ),
          // Información adicional (si existe)
          if (hasAdditionalInfo) ...[
            SizedBox(height: spacing),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 200.0,
              ), // ✅ Altura menor para info adicional
              child: _buildFuturisticAdditionalInfoCard(
                context,
                controller,
                isMobile: true,
              ),
            ),
          ],
        ],
      );
    }
  }

  /// ✅ NUEVO: Tab Items - Lista de productos
  Widget _buildItemsTabContent(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
    required double spacing,
  }) {
    return Column(
      children: [
        _buildFuturisticItemsCard(
          context,
          controller,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
        ),
      ],
    );
  }

  /// ✅ NUEVO: Tab Pagos - Historial completo y formulario de pagos
  /// NOTA: Ya no usa Obx interno porque el Obx padre en _buildTabContent
  /// ahora escucha invoiceRx y showPaymentFormRx
  Widget _buildPaymentsTabContent(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
    required double spacing,
  }) {
    final invoice = controller.invoiceRx.value;
    final showForm = controller.showPaymentFormRx.value;

    if (invoice == null) return const SizedBox.shrink();

    // ✅ CRITICAL FIX: Generar una key única basada en datos que cambian
    // Esto FUERZA a Flutter a reconstruir el widget cuando cambia el invoice
    final paymentKey = ValueKey('payments_${invoice.id}_${invoice.payments.length}_${invoice.paidAmount.toStringAsFixed(2)}');

    print('🔑 PaymentHistoryWidget Key: $paymentKey');

    return Column(
      children: [
        // Historial de pagos con resumen - se actualiza automáticamente
        // ✅ KEY ÚNICA: Fuerza rebuild cuando cambia el número de pagos o monto pagado
        PaymentHistoryWidget(
          key: paymentKey,
          invoice: invoice,
          showSummary: true,
        ),
        SizedBox(height: spacing),

        // Formulario de pago o botón para agregar
        if (showForm)
          _buildFuturisticPaymentForm(
            context,
            controller,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
          )
        else
          _buildAddPaymentCard(
            context,
            controller,
            isMobile: isMobile,
            isTablet: isTablet,
            isDesktop: isDesktop,
            spacing: spacing,
          ),
      ],
    );
  }

  /// ✅ NUEVO: Tab Historial - Información de actividad y estado
  Widget _buildHistorialTabContent(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
    required double spacing,
  }) {
    final invoice = controller.invoice!;

    // ✅ CORRECCIÓN: Tamaños diferenciados correctamente (Desktop más pequeño)
    final titleSize =
        isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 14.0; // Mobile: 16, Tablet: 20, Desktop: 14
    final textSize =
        isMobile
            ? 13.0
            : isTablet
            ? 16.0
            : 11.0; // Mobile: 13, Tablet: 16, Desktop: 11
    final subtitleSize =
        isMobile
            ? 11.0
            : isTablet
            ? 14.0
            : 9.0; // Mobile: 11, Tablet: 14, Desktop: 9
    final iconSizeMain =
        isMobile
            ? 24.0
            : isTablet
            ? 28.0
            : 20.0; // Mobile: 24, Tablet: 28, Desktop: 20
    final iconSizeSmall =
        isMobile
            ? 18.0
            : isTablet
            ? 22.0
            : 16.0; // Mobile: 18, Tablet: 22, Desktop: 16

    if (isDesktop) {
      // ✅ NUEVO: Layout desktop - Una sola columna con contenido completo
      return FuturisticContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === SECCIÓN CRONOLOGÍA ===
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: iconSizeMain,
                  color: ElegantLightTheme.primaryGradient.colors.first,
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Cronología de la Factura',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),

            _buildTimelineItem(
              icon: Icons.add_circle_outline,
              title: 'Factura Creada',
              subtitle: 'Fecha: ${_formatDate(invoice.createdAt)}',
              color: ElegantLightTheme.successGradient.colors.first,
              textSize: textSize,
              subtitleSize: subtitleSize,
              iconSize: iconSizeSmall,
            ),

            if (invoice.status != InvoiceStatus.draft)
              _buildTimelineItem(
                icon: Icons.check_circle_outline,
                title: 'Factura Confirmada',
                subtitle: 'Estado: ${invoice.statusDisplayName}',
                color: ElegantLightTheme.infoGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            if (invoice.isPaid)
              _buildTimelineItem(
                icon: Icons.payment,
                title: 'Factura Pagada',
                subtitle:
                    'Monto: ${AppFormatters.formatCurrency(invoice.paidAmount)}',
                color: ElegantLightTheme.successGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            if (invoice.status == InvoiceStatus.cancelled)
              _buildTimelineItem(
                icon: Icons.cancel_outlined,
                title: 'Factura Cancelada',
                subtitle: 'Estado actual',
                color: ElegantLightTheme.errorGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            SizedBox(height: spacing * 1.5),

            // === SECCIÓN INFORMACIÓN DETALLADA ===
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: iconSizeMain,
                  color: ElegantLightTheme.warningGradient.colors.first,
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Información Detallada',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),

            _buildInfoStatItem(
              'ID de Factura',
              invoice.id,
              Icons.fingerprint,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Número de Items',
              '${invoice.items.length} productos',
              Icons.inventory_2,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Estado Actual',
              invoice.statusDisplayName,
              Icons.info,
              textSize,
              subtitleSize,
            ),
            if (invoice.isOverdue)
              _buildInfoStatItem(
                'Días de Retraso',
                '${invoice.daysOverdue} días',
                Icons.warning,
                textSize,
                subtitleSize,
                color: ElegantLightTheme.errorGradient.colors.first,
              ),

            _buildInfoStatItem(
              'Creado por',
              invoice.createdBy?.firstName ?? 'Usuario',
              Icons.person,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Fecha de Vencimiento',
              _formatDate(invoice.dueDate),
              Icons.schedule,
              textSize,
              subtitleSize,
              color:
                  invoice.isOverdue
                      ? ElegantLightTheme.errorGradient.colors.first
                      : null,
            ),
          ],
        ),
      );
    } else if (isTablet) {
      // ✅ NUEVO: Layout tablet - Una sola columna con contenido completo (igual que desktop)
      return FuturisticContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === SECCIÓN CRONOLOGÍA ===
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: iconSizeMain,
                  color: ElegantLightTheme.primaryGradient.colors.first,
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Cronología de la Factura',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),

            _buildTimelineItem(
              icon: Icons.add_circle_outline,
              title: 'Factura Creada',
              subtitle: 'Fecha: ${_formatDate(invoice.createdAt)}',
              color: ElegantLightTheme.successGradient.colors.first,
              textSize: textSize,
              subtitleSize: subtitleSize,
              iconSize: iconSizeSmall,
            ),

            if (invoice.status != InvoiceStatus.draft)
              _buildTimelineItem(
                icon: Icons.check_circle_outline,
                title: 'Factura Confirmada',
                subtitle: 'Estado: ${invoice.statusDisplayName}',
                color: ElegantLightTheme.infoGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            if (invoice.isPaid)
              _buildTimelineItem(
                icon: Icons.payment,
                title: 'Factura Pagada',
                subtitle:
                    'Monto: ${AppFormatters.formatCurrency(invoice.paidAmount)}',
                color: ElegantLightTheme.successGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            if (invoice.status == InvoiceStatus.cancelled)
              _buildTimelineItem(
                icon: Icons.cancel_outlined,
                title: 'Factura Cancelada',
                subtitle: 'Estado actual',
                color: ElegantLightTheme.errorGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            SizedBox(height: spacing * 1.5),

            // === SECCIÓN INFORMACIÓN DETALLADA ===
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: iconSizeMain,
                  color: ElegantLightTheme.warningGradient.colors.first,
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Información Detallada',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),

            _buildInfoStatItem(
              'ID de Factura',
              invoice.id,
              Icons.fingerprint,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Número de Items',
              '${invoice.items.length} productos',
              Icons.inventory_2,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Estado Actual',
              invoice.statusDisplayName,
              Icons.info,
              textSize,
              subtitleSize,
            ),
            if (invoice.isOverdue)
              _buildInfoStatItem(
                'Días de Retraso',
                '${invoice.daysOverdue} días',
                Icons.warning,
                textSize,
                subtitleSize,
                color: ElegantLightTheme.errorGradient.colors.first,
              ),

            _buildInfoStatItem(
              'Creado por',
              invoice.createdBy?.firstName ?? 'Usuario',
              Icons.person,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Fecha de Vencimiento',
              _formatDate(invoice.dueDate),
              Icons.schedule,
              textSize,
              subtitleSize,
              color:
                  invoice.isOverdue
                      ? ElegantLightTheme.errorGradient.colors.first
                      : null,
            ),
          ],
        ),
      );
    } else {
      // Mobile: Una sola columna con contenido completo como tablet
      return FuturisticContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === SECCIÓN CRONOLOGÍA ===
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: iconSizeMain,
                  color: ElegantLightTheme.primaryGradient.colors.first,
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Cronología de la Factura',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),

            _buildTimelineItem(
              icon: Icons.add_circle_outline,
              title: 'Factura Creada',
              subtitle: 'Fecha: ${_formatDate(invoice.createdAt)}',
              color: ElegantLightTheme.successGradient.colors.first,
              textSize: textSize,
              subtitleSize: subtitleSize,
              iconSize: iconSizeSmall,
            ),

            if (invoice.status != InvoiceStatus.draft)
              _buildTimelineItem(
                icon: Icons.check_circle_outline,
                title: 'Factura Confirmada',
                subtitle: 'Estado: ${invoice.statusDisplayName}',
                color: ElegantLightTheme.infoGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            if (invoice.isPaid)
              _buildTimelineItem(
                icon: Icons.payment,
                title: 'Factura Pagada',
                subtitle:
                    'Monto: ${AppFormatters.formatCurrency(invoice.paidAmount)}',
                color: ElegantLightTheme.successGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            if (invoice.status == InvoiceStatus.cancelled)
              _buildTimelineItem(
                icon: Icons.cancel_outlined,
                title: 'Factura Cancelada',
                subtitle: 'Estado actual',
                color: ElegantLightTheme.errorGradient.colors.first,
                textSize: textSize,
                subtitleSize: subtitleSize,
                iconSize: iconSizeSmall,
              ),

            SizedBox(height: spacing * 1.5),

            // === SECCIÓN INFORMACIÓN DETALLADA ===
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: iconSizeMain,
                  color: ElegantLightTheme.warningGradient.colors.first,
                ),
                SizedBox(width: spacing / 2),
                Text(
                  'Información Detallada',
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),

            _buildInfoStatItem(
              'ID de Factura',
              invoice.id,
              Icons.fingerprint,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Número de Items',
              '${invoice.items.length} productos',
              Icons.inventory_2,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Estado Actual',
              invoice.statusDisplayName,
              Icons.info,
              textSize,
              subtitleSize,
            ),
            if (invoice.isOverdue)
              _buildInfoStatItem(
                'Días de Retraso',
                '${invoice.daysOverdue} días',
                Icons.warning,
                textSize,
                subtitleSize,
                color: ElegantLightTheme.errorGradient.colors.first,
              ),

            _buildInfoStatItem(
              'Creado por',
              invoice.createdBy?.firstName ?? 'Usuario',
              Icons.person,
              textSize,
              subtitleSize,
            ),
            _buildInfoStatItem(
              'Fecha de Vencimiento',
              _formatDate(invoice.dueDate),
              Icons.schedule,
              textSize,
              subtitleSize,
              color:
                  invoice.isOverdue
                      ? ElegantLightTheme.errorGradient.colors.first
                      : null,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required double textSize,
    required double subtitleSize,
    double? iconSize,
  }) {
    // ✅ RESPONSIVE: Usar iconSize pasado o calcular basado en textSize
    final effectiveIconSize = iconSize ?? (textSize * 1.4).clamp(16.0, 24.0);
    final padding = (textSize * 0.6).clamp(6.0, 10.0);
    final spacing = (textSize * 0.8).clamp(10.0, 14.0);
    final bottomPadding = (textSize * 1.2).clamp(12.0, 18.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: effectiveIconSize),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ElegantLightTheme.textPrimary,
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
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
    );
  }

  /// ✅ NUEVO: Tab Notas de Crédito - Muestra las notas de crédito de la factura
  Widget _buildCreditNotesTabContent(
    BuildContext context,
    InvoiceDetailController controller, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
    required double spacing,
  }) {
    final invoice = controller.invoice!;

    return FuturisticContainer(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: InvoiceCreditNotesWidget(invoiceId: invoice.id),
      ),
    );
  }

  /// ✅ NUEVO: Grid de métricas optimizado para el tab historial
  Widget _buildMetricsGrid(
    BuildContext context,
    InvoiceDetailController controller,
    double textSize,
    double subtitleSize,
  ) {
    final invoice = controller.invoice!;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildMetricGridItem(
          'Total Facturado',
          AppFormatters.formatCurrency(invoice.total),
          Icons.monetization_on,
          ElegantLightTheme.successGradient.colors.first,
          textSize,
          subtitleSize,
        ),
        _buildMetricGridItem(
          'Monto Pagado',
          AppFormatters.formatCurrency(invoice.paidAmount),
          Icons.payment,
          ElegantLightTheme.infoGradient.colors.first,
          textSize,
          subtitleSize,
        ),
        _buildMetricGridItem(
          'Balance Pendiente',
          AppFormatters.formatCurrency(invoice.balanceDue),
          Icons.account_balance_wallet,
          invoice.balanceDue > 0
              ? ElegantLightTheme.warningGradient.colors.first
              : ElegantLightTheme.successGradient.colors.first,
          textSize,
          subtitleSize,
        ),
        _buildMetricGridItem(
          'Última Actualización',
          _formatDate(invoice.updatedAt),
          Icons.schedule,
          ElegantLightTheme.textSecondary,
          textSize,
          subtitleSize,
        ),
      ],
    );
  }

  /// ✅ NUEVO: Item del grid de métricas
  Widget _buildMetricGridItem(
    String label,
    String value,
    IconData icon,
    Color color,
    double textSize,
    double subtitleSize,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: ElegantLightTheme.textPrimary,
              fontSize: textSize,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoStatItem(
    String label,
    String value,
    IconData icon,
    double textSize,
    double subtitleSize, {
    Color? color,
  }) {
    // ✅ RESPONSIVE: Calcular tamaños basados en textSize
    final iconSize = (textSize * 1.3).clamp(14.0, 22.0);
    final spacing = (textSize * 0.8).clamp(8.0, 14.0);
    final bottomPadding = (textSize * 0.9).clamp(8.0, 16.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? ElegantLightTheme.textSecondary,
            size: iconSize,
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: ElegantLightTheme.textSecondary,
                    fontSize: subtitleSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color ?? ElegantLightTheme.textPrimary,
                    fontSize: textSize,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Card de resumen de estado de pagos
  Widget _buildPaymentSummaryCard(
    BuildContext context,
    InvoiceDetailController controller, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    required double spacing,
  }) {
    final invoice = controller.invoice!;
    final textSize =
        isMobile
            ? 16.0
            : isTablet
            ? 18.0
            : 14.0;
    final titleSize =
        isMobile
            ? 18.0
            : isTablet
            ? 20.0
            : 16.0;
    final iconSize =
        isMobile
            ? 24.0
            : isTablet
            ? 28.0
            : 22.0;

    return FuturisticContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isMobile
                      ? 8.0
                      : isTablet
                      ? 10.0
                      : 8.0,
                ),
                decoration: BoxDecoration(
                  gradient:
                      invoice.isPaid
                          ? ElegantLightTheme.successGradient
                          : ElegantLightTheme.warningGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  invoice.isPaid ? Icons.check_circle : Icons.access_time,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Pagos',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      invoice.isPaid
                          ? 'Pagada Completamente'
                          : 'Pago Pendiente',
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w500,
                        color:
                            invoice.isPaid
                                ? ElegantLightTheme.successGradient.colors.first
                                : ElegantLightTheme
                                    .warningGradient
                                    .colors
                                    .first,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),

          // Métricas de pago
          Row(
            children: [
              Expanded(
                child: _buildPaymentMetric(
                  'Total Factura',
                  AppFormatters.formatCurrency(invoice.total),
                  Icons.receipt_long,
                  ElegantLightTheme.infoGradient.colors.first,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildPaymentMetric(
                  'Pagado',
                  AppFormatters.formatCurrency(invoice.paidAmount),
                  Icons.payment,
                  ElegantLightTheme.successGradient.colors.first,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildPaymentMetric(
                  'Saldo',
                  AppFormatters.formatCurrency(invoice.balanceDue),
                  Icons.account_balance_wallet,
                  invoice.balanceDue > 0
                      ? ElegantLightTheme.warningGradient.colors.first
                      : ElegantLightTheme.successGradient.colors.first,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMetric(
    String label,
    String value,
    IconData icon,
    Color color, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final textSize =
        isMobile
            ? 14.0
            : isTablet
            ? 16.0
            : 12.0;
    final valueSize =
        isMobile
            ? 16.0
            : isTablet
            ? 18.0
            : 14.0;
    final iconSize =
        isMobile
            ? 18.0
            : isTablet
            ? 20.0
            : 16.0;

    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 10.0,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: iconSize),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: textSize,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              color: ElegantLightTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// ✅ NUEVO: Card de historial de pagos
  Widget _buildPaymentHistoryCard(
    BuildContext context,
    InvoiceDetailController controller, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    required double spacing,
  }) {
    final invoice = controller.invoice!;

    return PaymentHistoryWidget(
      invoice: invoice,
      showSummary: false, // Summary is shown in separate card
    );
  }

  Widget _buildEmptyPaymentHistory({
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    required double spacing,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing * 1.5),
      decoration: BoxDecoration(
        color: ElegantLightTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.payment_outlined,
            size:
                isMobile
                    ? 32.0
                    : isTablet
                    ? 40.0
                    : 28.0,
            color: ElegantLightTheme.textTertiary,
          ),
          SizedBox(height: spacing * 0.5),
          Text(
            'No hay pagos registrados',
            style: TextStyle(
              fontSize:
                  isMobile
                      ? 16.0
                      : isTablet
                      ? 18.0
                      : 14.0,
              color: ElegantLightTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Los pagos aparecerán aquí una vez sean procesados',
            style: TextStyle(
              fontSize:
                  isMobile
                      ? 14.0
                      : isTablet
                      ? 16.0
                      : 12.0,
              color: ElegantLightTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(
    Map<String, dynamic> payment, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final textSize =
        isMobile
            ? 14.0
            : isTablet
            ? 16.0
            : 12.0;
    final subtitleSize =
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 11.0;
    final iconSize =
        isMobile
            ? 18.0
            : isTablet
            ? 20.0
            : 16.0;

    return Container(
      padding: EdgeInsets.all(
        isMobile
            ? 12.0
            : isTablet
            ? 14.0
            : 10.0,
      ),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.glassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ElegantLightTheme.successGradient.colors.first.withValues(
            alpha: 0.3,
          ),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ElegantLightTheme.successGradient.colors.first.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              payment['method']['icon'],
              color: ElegantLightTheme.successGradient.colors.first,
              size: iconSize,
            ),
          ),
          SizedBox(
            width:
                isMobile
                    ? 12.0
                    : isTablet
                    ? 14.0
                    : 10.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        payment['method']['name'],
                        style: TextStyle(
                          fontSize: textSize,
                          fontWeight: FontWeight.w600,
                          color: ElegantLightTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(payment['amount']),
                      style: TextStyle(
                        fontSize: textSize,
                        fontWeight: FontWeight.w700,
                        color: ElegantLightTheme.successGradient.colors.first,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: subtitleSize,
                      color: ElegantLightTheme.textTertiary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(payment['date']),
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                    if (payment['reference'] != null &&
                        payment['reference'].isNotEmpty) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.receipt,
                        size: subtitleSize,
                        color: ElegantLightTheme.textTertiary,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Ref: ${payment['reference']}',
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: ElegantLightTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  /// ✅ REDISEÑADO: Card para agregar nuevo pago - estilo consistente con historial
  Widget _buildAddPaymentCard(
    BuildContext context,
    InvoiceDetailController controller, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    required double spacing,
  }) {
    final invoice = controller.invoice!;
    final canAddPayment = invoice.canAddPayment;

    // Tamaños adaptativos consistentes con PaymentHistoryWidget
    final cardPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);
    final iconSize = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    final titleFontSize = isMobile ? 15.0 : (isTablet ? 16.0 : 18.0);

    if (!canAddPayment) {
      return CustomCard(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header consistente
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: iconSize,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estado de Pago',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      color: ElegantLightTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10,
                    vertical: isMobile ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Completado',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 16),
            // Contenido
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: isMobile ? 32 : 40,
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Factura Pagada',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No se requieren pagos adicionales',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: ElegantLightTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CustomCard(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header consistente con historial de pagos
          Row(
            children: [
              Icon(
                Icons.add_card,
                color: ElegantLightTheme.primaryBlue,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Registrar Pago',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: ElegantLightTheme.textPrimary,
                  ),
                ),
              ),
              // Badge de saldo pendiente
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 10,
                  vertical: isMobile ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppFormatters.formatCurrency(invoice.balanceDue),
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // Info del saldo pendiente
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: ElegantLightTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.orange,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 10 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Pendiente',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: ElegantLightTheme.textSecondary,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(invoice.balanceDue),
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),

          // Botón de agregar pago
          _buildPaymentActionButton(
            context,
            icon: Icons.payment,
            label: 'Agregar Pago',
            subtitle: 'Registrar un pago a esta factura',
            onTap: () => controller.togglePaymentForm(),
            isPrimary: true,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  /// Botón de acción para pagos con estilo consistente
  Widget _buildPaymentActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isMobile,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          decoration: BoxDecoration(
            color: isPrimary
                ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.1)
                : ElegantLightTheme.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPrimary
                  ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.3)
                  : ElegantLightTheme.textTertiary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? ElegantLightTheme.primaryBlue.withValues(alpha: 0.15)
                      : ElegantLightTheme.textTertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isPrimary
                      ? ElegantLightTheme.primaryBlue
                      : ElegantLightTheme.textSecondary,
                  size: isMobile ? 20 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: isPrimary
                            ? ElegantLightTheme.primaryBlue
                            : ElegantLightTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 11,
                        color: ElegantLightTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isPrimary
                    ? ElegantLightTheme.primaryBlue
                    : ElegantLightTheme.textTertiary,
                size: isMobile ? 20 : 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ SIMULACIÓN: Genera historial de pagos basado en el estado actual
  List<Map<String, dynamic>> _generatePaymentHistory(Invoice invoice) {
    final payments = <Map<String, dynamic>>[];

    // ✅ CORREGIDO: Solo mostrar datos reales, sin simulaciones
    // Si hay monto pagado, crear UNA SOLA entrada con el pago real
    if (invoice.paidAmount > 0) {
      payments.add({
        'id': '1',
        'amount': invoice.paidAmount,
        'method': {
          // ✅ Usar paymentMethodDisplayName que incluye el banco si existe
          'name': invoice.paymentMethodDisplayName,
          'icon': invoice.paymentMethodIcon,
        },
        'date': invoice.updatedAt, // Usar fecha real de última actualización
        'reference': 'REF-${invoice.number}-001',
        'notes': 'Pago registrado',
      });
    }

    // ❌ ELIMINADO: No crear pagos simulados adicionales
    // En una implementación real, aquí se consultarían los pagos del backend:
    // return await paymentRepository.getPaymentsByInvoiceId(invoice.id);

    return payments;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
