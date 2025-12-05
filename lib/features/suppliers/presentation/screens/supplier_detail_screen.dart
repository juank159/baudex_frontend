// lib/features/suppliers/presentation/screens/supplier_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../controllers/supplier_detail_controller.dart';
import '../../domain/entities/supplier.dart';

class SupplierDetailScreen extends GetView<SupplierDetailController> {
  const SupplierDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => MainLayout(
        title: controller.displayTitle,
        showBackButton: true,
        actions: [
          if (controller.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: controller.goToEdit,
              tooltip: 'Editar',
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ElegantLightTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: ElegantLightTheme.elevatedShadow,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'toggle_status',
                    enabled: controller.canToggleStatus,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient:
                                controller.supplier.value?.status ==
                                        SupplierStatus.active
                                    ? ElegantLightTheme.warningGradient
                                    : ElegantLightTheme.successGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            controller.supplier.value?.status ==
                                    SupplierStatus.active
                                ? Icons.block
                                : Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          controller.supplier.value?.status ==
                                  SupplierStatus.active
                              ? 'Desactivar'
                              : 'Activar',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'create_purchase_order',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Nueva Orden de Compra',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_purchase_history',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.infoGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Historial de Compras',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: controller.canDelete,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: ElegantLightTheme.errorGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
        body:
            controller.isLoading.value
                ? const Center(child: LoadingWidget())
                : controller.hasSupplier
                ? _buildContent()
                : _buildErrorState(),
      ),
    );
  }

  Widget _buildContent() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Header elegante con gradiente
          _buildElegantHeader(),

          // Tabs modernos
          _buildModernTabs(),

          // Contenido de tabs
          Expanded(child: Obx(() => _buildTabContent())),
        ],
      ),
    );
  }

  Widget _buildElegantHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final avatarRadius = isSmall ? 20.0 : 24.0;
        final titleSize = isSmall ? 16.0 : 18.0;

        return Container(
          decoration: BoxDecoration(
            gradient: ElegantLightTheme.primaryGradient,
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Obx(() {
            final supplier = controller.supplier.value!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar compacto
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _getStatusGradient(supplier.status),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.white,
                      child: Text(
                        _getInitials(supplier.name),
                        style: TextStyle(
                          color: _getStatusColor(supplier.status),
                          fontWeight: FontWeight.bold,
                          fontSize: avatarRadius * 0.6,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Nombre del proveedor
                  Expanded(
                    child: Text(
                      supplier.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Estado - alineado a la derecha
                  _buildCompactStatusBadge(supplier.status),

                  const SizedBox(width: 12),

                  // Botones de acción
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (supplier.hasEmail)
                        _buildCompactActionButton(
                          Icons.email_outlined,
                          () => controller.sendEmail(supplier.email!),
                        ),
                      if (supplier.hasPhone || supplier.hasMobile) ...[
                        const SizedBox(width: 6),
                        _buildCompactActionButton(
                          Icons.phone_outlined,
                          () => controller.callPhone(
                            supplier.phone ?? supplier.mobile!,
                          ),
                        ),
                      ],
                      if (supplier.website != null) ...[
                        const SizedBox(width: 6),
                        _buildCompactActionButton(
                          Icons.language_outlined,
                          () => controller.openWebsite(supplier.website!),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCompactStatusBadge(SupplierStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: _getStatusGradient(status),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(controller.getStatusIcon(status), size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            controller.getStatusText(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    LinearGradient gradient,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildElegantStatusBadge(SupplierStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: _getStatusGradient(status),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(status).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(controller.getStatusIcon(status), size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            controller.getStatusText(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabs() {
    return Obx(
      () => ElegantContainer(
        child: Column(
          children: [
            // Tab headers
            Row(
              children: [
                _buildTabHeader('General', 0, Icons.info),
                _buildTabHeader('Comercial', 1, Icons.business),
                _buildTabHeader('Actividad', 2, Icons.history),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader(String title, int index, IconData icon) {
    final isSelected = controller.selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.switchTab(index),
        child: AnimatedContainer(
          duration: ElegantLightTheme.normalAnimation,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? ElegantLightTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? ElegantLightTheme.glowShadow : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Colors.white : ElegantLightTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : ElegantLightTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (controller.selectedTab.value) {
      case 0:
        return _buildGeneralTab();
      case 1:
        return _buildCommercialTab();
      case 2:
        return _buildActivityTab();
      default:
        return _buildGeneralTab();
    }
  }

  Widget _buildGeneralTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final outerPadding = isSmall ? 8.0 : 12.0;
        final sectionSpacing = isSmall ? 8.0 : 12.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(outerPadding),
          child: Obx(() {
            final supplier = controller.supplier.value!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información básica con diseño elegante
                _buildElegantSection(
                  'Información Básica',
                  Icons.business,
                  ElegantLightTheme.primaryGradient,
                  [
                    _buildElegantInfoRow(
                      'Nombre Completo',
                      supplier.name,
                      Icons.person,
                    ),
                    if (supplier.code != null)
                      _buildElegantInfoRow(
                        'Código',
                        supplier.code!,
                        Icons.qr_code,
                      ),
                    if (supplier.documentNumber != null)
                      _buildElegantInfoRow(
                        controller.getDocumentTypeText(supplier.documentType),
                        supplier.documentNumber,
                        Icons.badge,
                      ),
                    if (supplier.contactPerson != null)
                      _buildElegantInfoRow(
                        'Persona de Contacto',
                        supplier.contactPerson!,
                        Icons.person_outline,
                      ),
                    _buildElegantInfoRow(
                      'Estado',
                      controller.getStatusText(supplier.status),
                      Icons.info,
                      statusGradient: _getStatusGradient(supplier.status),
                    ),
                  ],
                ),

                SizedBox(height: sectionSpacing),

                // Información de contacto elegante
                if (controller.hasContactInfo)
                  _buildElegantSection(
                    'Información de Contacto',
                    Icons.contact_mail,
                    ElegantLightTheme.infoGradient,
                    [
                      if (supplier.hasEmail)
                        _buildElegantInfoRow(
                          'Email',
                          supplier.email!,
                          Icons.email,
                          onTap: () => controller.sendEmail(supplier.email!),
                          isClickable: true,
                        ),
                      if (supplier.hasPhone)
                        _buildElegantInfoRow(
                          'Teléfono',
                          supplier.phone!,
                          Icons.phone,
                          onTap: () => controller.callPhone(supplier.phone!),
                          isClickable: true,
                        ),
                      if (supplier.hasMobile)
                        _buildElegantInfoRow(
                          'Móvil',
                          supplier.mobile!,
                          Icons.smartphone,
                          onTap: () => controller.callPhone(supplier.mobile!),
                          isClickable: true,
                        ),
                      if (supplier.website != null)
                        _buildElegantInfoRow(
                          'Sitio Web',
                          supplier.website!,
                          Icons.language,
                          onTap:
                              () => controller.openWebsite(supplier.website!),
                          isClickable: true,
                        ),
                    ],
                  ),

                if (controller.hasContactInfo) SizedBox(height: sectionSpacing),

                // Información de ubicación
                if (supplier.hasAddress ||
                    supplier.city != null ||
                    supplier.country != null)
                  _buildElegantSection(
                    'Ubicación',
                    Icons.location_on,
                    ElegantLightTheme.warningGradient,
                    [
                      if (supplier.hasAddress)
                        _buildElegantInfoRow(
                          'Dirección',
                          supplier.address!,
                          Icons.home,
                        ),
                      if (supplier.city != null)
                        _buildElegantInfoRow(
                          'Ciudad',
                          supplier.city!,
                          Icons.location_city,
                        ),
                      if (supplier.state != null)
                        _buildElegantInfoRow(
                          'Estado/Provincia',
                          supplier.state!,
                          Icons.map,
                        ),
                      if (supplier.country != null)
                        _buildElegantInfoRow(
                          'País',
                          supplier.country!,
                          Icons.flag,
                        ),
                      if (supplier.postalCode != null)
                        _buildElegantInfoRow(
                          'Código Postal',
                          supplier.postalCode!,
                          Icons.markunread_mailbox,
                        ),
                    ],
                  ),

                if (supplier.hasAddress ||
                    supplier.city != null ||
                    supplier.country != null)
                  SizedBox(height: sectionSpacing),

                // Información del sistema
                _buildElegantSection(
                  'Información del Sistema',
                  Icons.settings,
                  LinearGradient(
                    colors: [
                      ElegantLightTheme.textSecondary.withOpacity(0.7),
                      ElegantLightTheme.textSecondary.withOpacity(0.5),
                    ],
                  ),
                  [
                    _buildElegantInfoRow(
                      'Fecha de Creación',
                      controller.formatDateTime(supplier.createdAt),
                      Icons.schedule,
                    ),
                    _buildElegantInfoRow(
                      'Última Actualización',
                      controller.formatDateTime(supplier.updatedAt),
                      Icons.update,
                    ),
                    _buildElegantInfoRow(
                      'ID del Sistema',
                      supplier.id,
                      Icons.fingerprint,
                    ),
                  ],
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildElegantSection(
    String title,
    IconData icon,
    LinearGradient gradient,
    List<Widget> children,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final iconSize = isSmall ? 16.0 : 20.0;
        final iconPadding = isSmall ? 6.0 : 8.0;
        final titleSize = isSmall ? 14.0 : 16.0;
        final borderRadius = isSmall ? 10.0 : 12.0;
        final headerPadding = isSmall ? 10.0 : 12.0;
        final contentPadding = isSmall ? 10.0 : 12.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: ElegantLightTheme.elevatedShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con gradiente compacto
              Container(
                padding: EdgeInsets.all(headerPadding),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(borderRadius),
                    topRight: Radius.circular(borderRadius),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPadding),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: iconSize),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Contenido compacto
              Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Column(children: children),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElegantInfoRow(
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
    bool isClickable = false,
    LinearGradient? statusGradient,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final rowPadding = isSmall ? 8.0 : 10.0;
        final bottomMargin = isSmall ? 6.0 : 8.0;
        final iconSize = isSmall ? 14.0 : 16.0;
        final iconPadding = isSmall ? 5.0 : 6.0;
        final labelSize = isSmall ? 10.0 : 11.0;
        final valueSize = isSmall ? 12.0 : 13.0;
        final borderRadius = isSmall ? 8.0 : 10.0;
        final arrowSize = isSmall ? 12.0 : 14.0;

        return Padding(
          padding: EdgeInsets.only(bottom: bottomMargin),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: EdgeInsets.all(rowPadding),
              decoration: BoxDecoration(
                gradient:
                    isClickable
                        ? LinearGradient(
                          colors: [
                            ElegantLightTheme.primaryBlue.withOpacity(0.05),
                            ElegantLightTheme.primaryBlue.withOpacity(0.02),
                          ],
                        )
                        : statusGradient != null
                        ? LinearGradient(
                          colors:
                              statusGradient.colors
                                  .map((c) => c.withOpacity(0.1))
                                  .toList(),
                        )
                        : LinearGradient(
                          colors: [
                            ElegantLightTheme.cardColor,
                            ElegantLightTheme.backgroundColor,
                          ],
                        ),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color:
                      isClickable
                          ? ElegantLightTheme.primaryBlue.withOpacity(0.2)
                          : statusGradient != null
                          ? statusGradient.colors.first.withOpacity(0.3)
                          : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      gradient:
                          statusGradient ??
                          (isClickable
                              ? ElegantLightTheme.primaryGradient
                              : LinearGradient(
                                colors: [
                                  ElegantLightTheme.textSecondary.withOpacity(
                                    0.2,
                                  ),
                                  ElegantLightTheme.textSecondary.withOpacity(
                                    0.1,
                                  ),
                                ],
                              )),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      color:
                          statusGradient != null || isClickable
                              ? Colors.white
                              : ElegantLightTheme.textSecondary,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isSmall ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: ElegantLightTheme.textSecondary,
                            fontSize: labelSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: isSmall ? 2 : 3),
                        Text(
                          value,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                isClickable
                                    ? ElegantLightTheme.primaryBlue
                                    : ElegantLightTheme.textPrimary,
                            fontSize: valueSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isClickable)
                    Container(
                      padding: EdgeInsets.all(isSmall ? 4 : 5),
                      decoration: BoxDecoration(
                        gradient: ElegantLightTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        size: arrowSize,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommercialTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final outerPadding = isSmall ? 8.0 : 12.0;
        final sectionSpacing = isSmall ? 8.0 : 12.0;
        final notesPadding = isSmall ? 8.0 : 10.0;
        final notesBorderRadius = isSmall ? 8.0 : 10.0;
        final notesFontSize = isSmall ? 12.0 : 13.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(outerPadding),
          child: Obx(() {
            final supplier = controller.supplier.value!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información comercial básica
                _buildElegantSection(
                  'Información Comercial',
                  Icons.business_center,
                  ElegantLightTheme.primaryGradient,
                  [
                    _buildElegantInfoRow(
                      'Moneda',
                      supplier.currency,
                      Icons.attach_money,
                    ),
                    _buildElegantInfoRow(
                      'Términos de pago',
                      '${supplier.paymentTermsDays} días',
                      Icons.schedule,
                    ),
                    if (supplier.hasCreditLimit)
                      _buildElegantInfoRow(
                        'Límite de crédito',
                        controller.formatCurrency(supplier.creditLimit),
                        Icons.credit_card,
                      ),
                    if (supplier.hasDiscount)
                      _buildElegantInfoRow(
                        'Descuento',
                        controller.formatPercentage(
                          supplier.discountPercentage,
                        ),
                        Icons.discount,
                      ),
                  ],
                ),

                SizedBox(height: sectionSpacing),

                // Estadísticas de compras
                _buildElegantSection(
                  'Estadísticas',
                  Icons.analytics,
                  ElegantLightTheme.infoGradient,
                  [
                    _buildElegantInfoRow(
                      'Total de órdenes',
                      '0',
                      Icons.shopping_cart,
                    ), // TODO: Implementar con datos reales
                    _buildElegantInfoRow(
                      'Total comprado',
                      controller.formatCurrency(0.0),
                      Icons.monetization_on,
                    ),
                    _buildElegantInfoRow(
                      'Última compra',
                      'N/A',
                      Icons.calendar_today,
                    ),
                    _buildElegantInfoRow(
                      'Promedio mensual',
                      controller.formatCurrency(0.0),
                      Icons.trending_up,
                    ),
                  ],
                ),

                if (supplier.notes != null) ...[
                  SizedBox(height: sectionSpacing),
                  _buildElegantSection(
                    'Notas',
                    Icons.note,
                    ElegantLightTheme.warningGradient,
                    [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(notesPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ElegantLightTheme.cardColor,
                              ElegantLightTheme.backgroundColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            notesBorderRadius,
                          ),
                          border: Border.all(
                            color: ElegantLightTheme.textTertiary.withOpacity(
                              0.2,
                            ),
                          ),
                        ),
                        child: Text(
                          supplier.notes!,
                          style: TextStyle(
                            color: ElegantLightTheme.textPrimary,
                            fontSize: notesFontSize,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final outerPadding = isSmall ? 8.0 : 12.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(outerPadding),
          child: Column(
            children: [
              // Botones de acción
              _buildElegantActionButtons(),

              SizedBox(height: isSmall ? 8.0 : 12.0),

              // Historial (placeholder) - compacto
              Container(
                padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmall ? 10.0 : 12.0),
                  boxShadow: ElegantLightTheme.elevatedShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmall ? 12.0 : 16.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ElegantLightTheme.textTertiary.withOpacity(0.1),
                            ElegantLightTheme.textTertiary.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        size: isSmall ? 40.0 : 50.0,
                        color: ElegantLightTheme.textTertiary,
                      ),
                    ),
                    SizedBox(height: isSmall ? 8.0 : 12.0),
                    Text(
                      'Historial de actividad',
                      style: TextStyle(
                        fontSize: isSmall ? 16.0 : 18.0,
                        fontWeight: FontWeight.bold,
                        color: ElegantLightTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: isSmall ? 4.0 : 6.0),
                    Text(
                      'El historial de órdenes de compra y actividad del proveedor aparecerá aquí.',
                      style: TextStyle(
                        color: ElegantLightTheme.textSecondary,
                        fontSize: isSmall ? 12.0 : 13.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildElegantActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final isMedium =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final buttonSpacing = isSmall ? 6.0 : 8.0;
        final verticalSpacing = isSmall ? 6.0 : 8.0;
        final buttonHeight = isSmall ? 36.0 : 40.0;

        // En móvil: 2 columnas (2x2 grid)
        // En tablet: 2 columnas (2x2 grid)
        // En desktop: 4 columnas (1 fila)
        if (isSmall || isMedium) {
          return Column(
            children: [
              // Primera fila: Nueva Orden + Ver Historial
              Row(
                children: [
                  Expanded(
                    child: _buildCompactButton(
                      text: isSmall ? 'Nueva Orden' : 'Nueva Orden',
                      onPressed: controller.goToCreatePurchaseOrder,
                      icon: Icons.shopping_cart,
                      gradient: ElegantLightTheme.primaryGradient,
                      height: buttonHeight,
                      isSmall: isSmall,
                    ),
                  ),
                  SizedBox(width: buttonSpacing),
                  Expanded(
                    child: _buildCompactButton(
                      text: isSmall ? 'Historial' : 'Historial',
                      onPressed: controller.goToPurchaseHistory,
                      icon: Icons.history,
                      gradient: ElegantLightTheme.infoGradient,
                      height: buttonHeight,
                      isSmall: isSmall,
                    ),
                  ),
                ],
              ),
              SizedBox(height: verticalSpacing),
              // Segunda fila: Activar/Desactivar + Eliminar
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _buildCompactButton(
                        text:
                            controller.supplier.value?.status ==
                                    SupplierStatus.active
                                ? 'Desactivar'
                                : 'Activar',
                        onPressed: controller.toggleSupplierStatus,
                        isLoading: controller.isUpdatingStatus.value,
                        icon:
                            controller.supplier.value?.status ==
                                    SupplierStatus.active
                                ? Icons.block
                                : Icons.check_circle,
                        gradient:
                            controller.supplier.value?.status ==
                                    SupplierStatus.active
                                ? ElegantLightTheme.warningGradient
                                : ElegantLightTheme.successGradient,
                        height: buttonHeight,
                        isSmall: isSmall,
                      ),
                    ),
                  ),
                  SizedBox(width: buttonSpacing),
                  Expanded(
                    child: Obx(
                      () => _buildCompactButton(
                        text: 'Eliminar',
                        onPressed: controller.deleteSupplier,
                        isLoading: controller.isDeleting.value,
                        icon: Icons.delete,
                        gradient: ElegantLightTheme.errorGradient,
                        height: buttonHeight,
                        isSmall: isSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop: Una sola fila con 4 botones
          return Row(
            children: [
              Expanded(
                child: _buildCompactButton(
                  text: 'Nueva Orden de Compra',
                  onPressed: controller.goToCreatePurchaseOrder,
                  icon: Icons.shopping_cart,
                  gradient: ElegantLightTheme.primaryGradient,
                  height: buttonHeight,
                  isSmall: false,
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: _buildCompactButton(
                  text: 'Ver Historial',
                  onPressed: controller.goToPurchaseHistory,
                  icon: Icons.history,
                  gradient: ElegantLightTheme.infoGradient,
                  height: buttonHeight,
                  isSmall: false,
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: Obx(
                  () => _buildCompactButton(
                    text:
                        controller.supplier.value?.status ==
                                SupplierStatus.active
                            ? 'Desactivar'
                            : 'Activar',
                    onPressed: controller.toggleSupplierStatus,
                    isLoading: controller.isUpdatingStatus.value,
                    icon:
                        controller.supplier.value?.status ==
                                SupplierStatus.active
                            ? Icons.block
                            : Icons.check_circle,
                    gradient:
                        controller.supplier.value?.status ==
                                SupplierStatus.active
                            ? ElegantLightTheme.warningGradient
                            : ElegantLightTheme.successGradient,
                    height: buttonHeight,
                    isSmall: false,
                  ),
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: Obx(
                  () => _buildCompactButton(
                    text: 'Eliminar',
                    onPressed: controller.deleteSupplier,
                    isLoading: controller.isDeleting.value,
                    icon: Icons.delete,
                    gradient: ElegantLightTheme.errorGradient,
                    height: buttonHeight,
                    isSmall: false,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCompactButton({
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
    required LinearGradient gradient,
    required double height,
    required bool isSmall,
    bool isLoading = false,
  }) {
    final fontSize = isSmall ? 11.0 : 12.0;
    final iconSize = isSmall ? 14.0 : 16.0;
    final horizontalPadding = isSmall ? 8.0 : 12.0;
    final verticalPadding = isSmall ? 6.0 : 8.0;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(8),
          boxShadow: ElegantLightTheme.elevatedShadow,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(icon, color: Colors.white, size: iconSize),
                  if (text.isNotEmpty) SizedBox(width: isSmall ? 4 : 6),
                  if (text.isNotEmpty)
                    Flexible(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ElegantLightTheme.errorGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ElegantLightTheme.errorGradient.colors.first
                      .withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          const Text(
            'Error al cargar proveedor',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ElegantLightTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Obx(
            () => Text(
              controller.error.value,
              style: const TextStyle(
                color: ElegantLightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          ElegantButton(
            text: 'Reintentar',
            onPressed: controller.loadSupplier,
            icon: Icons.refresh,
            gradient: ElegantLightTheme.primaryGradient,
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_status':
        controller.toggleSupplierStatus();
        break;
      case 'create_purchase_order':
        controller.goToCreatePurchaseOrder();
        break;
      case 'view_purchase_history':
        controller.goToPurchaseHistory();
        break;
      case 'delete':
        controller.deleteSupplier();
        break;
    }
  }

  String _getInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, 2).toUpperCase();
    }
    return 'PR';
  }

  Color _getStatusColor(SupplierStatus status) {
    switch (status) {
      case SupplierStatus.active:
        return const Color(0xFF10B981); // Green
      case SupplierStatus.inactive:
        return const Color(0xFFF59E0B); // Orange
      case SupplierStatus.blocked:
        return const Color(0xFFEF4444); // Red
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
}
