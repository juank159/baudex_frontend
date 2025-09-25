// lib/features/suppliers/presentation/screens/supplier_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/ui/layouts/main_layout.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../controllers/supplier_detail_controller.dart';
import '../../domain/entities/supplier.dart';

class SupplierDetailScreen extends GetView<SupplierDetailController> {
  const SupplierDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => MainLayout(
      title: controller.displayTitle,
      actions: [
        if (controller.canEdit)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: controller.goToEdit,
            tooltip: 'Editar',
          ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_status',
              enabled: controller.canToggleStatus,
              child: Row(
                children: [
                  Icon(
                    controller.supplier.value?.status == SupplierStatus.active
                        ? Icons.block
                        : Icons.check_circle,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    controller.supplier.value?.status == SupplierStatus.active
                        ? 'Desactivar'
                        : 'Activar',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'create_purchase_order',
              child: Row(
                children: [
                  Icon(Icons.shopping_cart),
                  SizedBox(width: 8),
                  Text('Nueva Orden de Compra'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view_purchase_history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('Historial de Compras'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              enabled: controller.canDelete,
              child: const Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      body: controller.isLoading.value
          ? const Center(child: LoadingWidget())
          : controller.hasSupplier
              ? _buildContent()
              : _buildErrorState(),
    ));
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Header con información principal
        _buildHeader(),
        
        // Tabs
        DefaultTabController(length: 3, child: _buildTabs()),
        
        // Contenido de tabs
        Expanded(
          child: Obx(() => _buildTabContent()),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Obx(() {
        final supplier = controller.supplier.value!;
        return Column(
          children: [
            Row(
              children: [
                // Avatar mejorado
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: controller.getStatusColor(supplier.status).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: controller.getStatusColor(supplier.status).withOpacity(0.2),
                    child: Text(
                      _getInitials(supplier.name),
                      style: TextStyle(
                        color: controller.getStatusColor(supplier.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: AppDimensions.paddingLarge),
                
                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
                        style: Get.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (supplier.code != null)
                        Row(
                          children: [
                            Icon(Icons.qr_code, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Código: ${supplier.code}',
                              style: Get.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusChip(supplier.status),
                          const SizedBox(width: AppDimensions.paddingSmall),
                          if (supplier.documentType != null && supplier.documentNumber != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.paddingSmall,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.badge, size: 12, color: Colors.blue.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${controller.getDocumentTypeText(supplier.documentType)}: ${supplier.documentNumber}',
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Botones de acción rápida mejorados
                Column(
                  children: [
                    if (supplier.hasEmail)
                      _buildQuickActionButton(
                        Icons.email_outlined,
                        'Email',
                        () => controller.sendEmail(supplier.email!),
                        Colors.blue,
                      ),
                    const SizedBox(height: 8),
                    if (supplier.hasPhone || supplier.hasMobile)
                      _buildQuickActionButton(
                        Icons.phone_outlined,
                        'Llamar',
                        () => controller.callPhone(supplier.phone ?? supplier.mobile!),
                        Colors.green,
                      ),
                    const SizedBox(height: 8),
                    if (supplier.website != null)
                      _buildQuickActionButton(
                        Icons.language_outlined,
                        'Web',
                        () => controller.openWebsite(supplier.website!),
                        Colors.purple,
                      ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingMedium),
            
            // Métricas rápidas
            Row(
              children: [
                Expanded(child: _buildQuickMetric('Términos de Pago', '${supplier.paymentTermsDays} días', Icons.schedule)),
                Expanded(child: _buildQuickMetric('Moneda', supplier.currency, Icons.monetization_on)),
                if (supplier.hasCreditLimit)
                  Expanded(child: _buildQuickMetric('Límite Crédito', controller.formatCurrency(supplier.creditLimit), Icons.credit_card)),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String tooltip, VoidCallback onPressed, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(SupplierStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: controller.getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            controller.getStatusIcon(status),
            size: 14,
            color: controller.getStatusColor(status),
          ),
          const SizedBox(width: 4),
          Text(
            controller.getStatusText(status),
            style: TextStyle(
              color: controller.getStatusColor(status),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        onTap: controller.switchTab,
        tabs: const [
          Tab(
            icon: Icon(Icons.info),
            text: 'General',
          ),
          Tab(
            icon: Icon(Icons.business),
            text: 'Comercial',
          ),
          Tab(
            icon: Icon(Icons.history),
            text: 'Actividad',
          ),
        ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Obx(() {
        final supplier = controller.supplier.value!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información básica mejorada
            _buildEnhancedSection(
              'Información Básica',
              Icons.business,
              [
                _buildEnhancedInfoRow('Nombre Completo', supplier.name, Icons.person),
                if (supplier.code != null)
                  _buildEnhancedInfoRow('Código', supplier.code!, Icons.qr_code),
                if (supplier.documentType != null && supplier.documentNumber != null)
                  _buildEnhancedInfoRow(
                    controller.getDocumentTypeText(supplier.documentType),
                    supplier.documentNumber!,
                    Icons.badge,
                  ),
                if (supplier.contactPerson != null)
                  _buildEnhancedInfoRow('Persona de Contacto', supplier.contactPerson!, Icons.person_outline),
                _buildEnhancedInfoRow('Estado', controller.getStatusText(supplier.status), Icons.info, 
                  statusColor: controller.getStatusColor(supplier.status)),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            
            // Información de contacto mejorada
            if (controller.hasContactInfo)
              _buildEnhancedSection(
                'Información de Contacto',
                Icons.contact_mail,
                [
                  if (supplier.hasEmail)
                    _buildEnhancedInfoRow('Email', supplier.email!, Icons.email, 
                      onTap: () => controller.sendEmail(supplier.email!), isClickable: true),
                  if (supplier.hasPhone)
                    _buildEnhancedInfoRow('Teléfono', supplier.phone!, Icons.phone, 
                      onTap: () => controller.callPhone(supplier.phone!), isClickable: true),
                  if (supplier.hasMobile)
                    _buildEnhancedInfoRow('Móvil', supplier.mobile!, Icons.smartphone, 
                      onTap: () => controller.callPhone(supplier.mobile!), isClickable: true),
                  if (supplier.website != null)
                    _buildEnhancedInfoRow('Sitio Web', supplier.website!, Icons.language, 
                      onTap: () => controller.openWebsite(supplier.website!), isClickable: true),
                ],
              ),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            
            // Información de ubicación
            if (supplier.hasAddress || supplier.city != null || supplier.country != null)
              _buildEnhancedSection(
                'Ubicación',
                Icons.location_on,
                [
                  if (supplier.hasAddress)
                    _buildEnhancedInfoRow('Dirección', supplier.address!, Icons.home),
                  if (supplier.city != null)
                    _buildEnhancedInfoRow('Ciudad', supplier.city!, Icons.location_city),
                  if (supplier.state != null)
                    _buildEnhancedInfoRow('Estado/Provincia', supplier.state!, Icons.map),
                  if (supplier.country != null)
                    _buildEnhancedInfoRow('País', supplier.country!, Icons.flag),
                  if (supplier.postalCode != null)
                    _buildEnhancedInfoRow('Código Postal', supplier.postalCode!, Icons.markunread_mailbox),
                ],
              ),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            
            // Información del sistema
            _buildEnhancedSection(
              'Información del Sistema',
              Icons.settings,
              [
                _buildEnhancedInfoRow('Fecha de Creación', controller.formatDateTime(supplier.createdAt), Icons.schedule),
                _buildEnhancedInfoRow('Última Actualización', controller.formatDateTime(supplier.updatedAt), Icons.update),
                _buildEnhancedInfoRow('ID del Sistema', supplier.id, Icons.fingerprint),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEnhancedSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Text(
                  title,
                  style: Get.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingLarge),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedInfoRow(
    String label, 
    String value, 
    IconData icon, {
    VoidCallback? onTap,
    bool isClickable = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          decoration: BoxDecoration(
            color: isClickable ? Colors.blue.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: isClickable ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: statusColor ?? (isClickable ? Colors.blue : AppColors.primary), 
                size: 18
              ),
              const SizedBox(width: AppDimensions.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Get.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: statusColor ?? (isClickable ? Colors.blue.shade700 : Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              if (isClickable)
                Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommercialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Obx(() {
        final supplier = controller.supplier.value!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información comercial básica
            _buildSection(
              'Información Comercial',
              [
                _buildInfoRow('Moneda', supplier.currency),
                _buildInfoRow('Términos de pago', '${supplier.paymentTermsDays} días'),
                if (supplier.hasCreditLimit)
                  _buildInfoRow('Límite de crédito', controller.formatCurrency(supplier.creditLimit)),
                if (supplier.hasDiscount)
                  _buildInfoRow('Descuento', controller.formatPercentage(supplier.discountPercentage)),
              ],
            ),
            
            const SizedBox(height: AppDimensions.paddingLarge),
            
            // Estadísticas de compras (placeholder)
            _buildSection(
              'Estadísticas',
              [
                _buildInfoRow('Total de órdenes', '0'), // TODO: Implementar con datos reales
                _buildInfoRow('Total comprado', controller.formatCurrency(0.0)),
                _buildInfoRow('Última compra', 'N/A'),
                _buildInfoRow('Promedio mensual', controller.formatCurrency(0.0)),
              ],
            ),
            
            if (supplier.notes != null) ...[
              const SizedBox(height: AppDimensions.paddingLarge),
              _buildSection(
                'Notas',
                [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      supplier.notes!,
                      style: Get.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        children: [
          // Botones de acción
          _buildActionButtons(),
          
          const SizedBox(height: AppDimensions.paddingLarge),
          
          // Historial (placeholder)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppDimensions.paddingMedium),
                  Text(
                    'Historial de actividad',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  Text(
                    'El historial de órdenes de compra y actividad del proveedor aparecerá aquí.',
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Nueva Orden de Compra',
                onPressed: controller.goToCreatePurchaseOrder,
                icon: Icons.shopping_cart,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: CustomButton(
                text: 'Ver Historial',
                onPressed: controller.goToPurchaseHistory,
                type: ButtonType.outline,
                icon: Icons.history,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingMedium),
        Row(
          children: [
            Expanded(
              child: Obx(() => CustomButton(
                text: controller.supplier.value?.status == SupplierStatus.active
                    ? 'Desactivar'
                    : 'Activar',
                onPressed: controller.toggleSupplierStatus,
                type: ButtonType.outline,
                isLoading: controller.isUpdatingStatus.value,
                icon: controller.supplier.value?.status == SupplierStatus.active
                    ? Icons.block
                    : Icons.check_circle,
              )),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Obx(() => CustomButton(
                text: 'Eliminar',
                onPressed: controller.deleteSupplier,
                type: ButtonType.outline,
                isLoading: controller.isDeleting.value,
                icon: Icons.delete,
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingMedium),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: onTap != null ? AppColors.primary : null,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new,
                size: 16,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Error al cargar proveedor',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Obx(() => Text(
            controller.error.value,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          )),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: 'Reintentar',
            onPressed: controller.loadSupplier,
            icon: Icons.refresh,
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
}