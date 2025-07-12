// lib/features/customers/presentation/widgets/customer_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../domain/entities/customer.dart';
import '../controllers/customers_controller.dart';

class CustomerFilterWidget extends GetView<CustomersController> {
  const CustomerFilterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header optimizado
        _buildFilterHeader(context),

        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),

        // Filtros
        _buildStatusFilter(context),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
        _buildDocumentTypeFilter(context),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
        _buildLocationFilters(context),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
        _buildSortingOptions(context),
        SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
        _buildQuickFilters(context),
      ],
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    final headerPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 16.0,
    );

    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 18.0, // Reducido de 22 a 18
    );

    final titleSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 16.0, // Reducido de 20 a 16
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: headerPadding),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: Theme.of(context).primaryColor,
            size: iconSize,
          ),
          SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small)),
          Text(
            'Filtros',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: controller.clearFilters,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.responsiveValue(context, mobile: 8, tablet: 12, desktop: 12),
                vertical: ResponsiveHelper.responsiveValue(context, mobile: 4, tablet: 6, desktop: 6),
              ),
            ),
            child: Text(
              'Limpiar',
              style: TextStyle(
                fontSize: ResponsiveHelper.responsiveValue(context, mobile: 12, tablet: 13, desktop: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Estado', Icons.toggle_on),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
          Obx(() {
            return Column(
              children: [
                _buildStatusOption(
                  context,
                  'Todos',
                  null,
                  controller.currentStatus == null,
                ),
                _buildStatusOption(
                  context,
                  'Activos',
                  CustomerStatus.active,
                  controller.currentStatus == CustomerStatus.active,
                ),
                _buildStatusOption(
                  context,
                  'Inactivos',
                  CustomerStatus.inactive,
                  controller.currentStatus == CustomerStatus.inactive,
                ),
                _buildStatusOption(
                  context,
                  'Suspendidos',
                  CustomerStatus.suspended,
                  controller.currentStatus == CustomerStatus.suspended,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeFilter(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Tipo de Documento', Icons.badge),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
          Obx(() {
            return Column(
              children: [
                _buildDocumentTypeOption(
                  context,
                  'Todos',
                  null,
                  controller.currentDocumentType == null,
                ),
                _buildDocumentTypeOption(
                  context,
                  'Cédula de Ciudadanía',
                  DocumentType.cc,
                  controller.currentDocumentType == DocumentType.cc,
                ),
                _buildDocumentTypeOption(
                  context,
                  'NIT',
                  DocumentType.nit,
                  controller.currentDocumentType == DocumentType.nit,
                ),
                _buildDocumentTypeOption(
                  context,
                  'Cédula de Extranjería',
                  DocumentType.ce,
                  controller.currentDocumentType == DocumentType.ce,
                ),
                _buildDocumentTypeOption(
                  context,
                  'Pasaporte',
                  DocumentType.passport,
                  controller.currentDocumentType == DocumentType.passport,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLocationFilters(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Ubicación', Icons.location_on),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
          Text(
            'Filtros de ubicación pendientes de implementar',
            style: TextStyle(
              fontSize: ResponsiveHelper.responsiveValue(context, mobile: 11, tablet: 12, desktop: 12),
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortingOptions(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Ordenar por', Icons.sort),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
          Obx(() {
            return Column(
              children: [
                _buildSortOption(
                  context,
                  'Más recientes',
                  'createdAt',
                  'DESC',
                  controller.sortBy == 'createdAt' && controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Más antiguos',
                  'createdAt',
                  'ASC',
                  controller.sortBy == 'createdAt' && controller.sortOrder == 'ASC',
                ),
                _buildSortOption(
                  context,
                  'Nombre (A-Z)',
                  'firstName',
                  'ASC',
                  controller.sortBy == 'firstName' && controller.sortOrder == 'ASC',
                ),
                _buildSortOption(
                  context,
                  'Nombre (Z-A)',
                  'firstName',
                  'DESC',
                  controller.sortBy == 'firstName' && controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Mayor crédito',
                  'creditLimit',
                  'DESC',
                  controller.sortBy == 'creditLimit' && controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Mayor balance',
                  'currentBalance',
                  'DESC',
                  controller.sortBy == 'currentBalance' && controller.sortOrder == 'DESC',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: 12,
          tablet: 16,
          desktop: 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Filtros rápidos', Icons.flash_on),
          SizedBox(height: ResponsiveHelper.getVerticalSpacing(context, size: SpacingSize.small)),
          Wrap(
            spacing: ResponsiveHelper.responsiveValue(context, mobile: 6, tablet: 8, desktop: 8),
            runSpacing: ResponsiveHelper.responsiveValue(context, mobile: 6, tablet: 8, desktop: 8),
            children: [
              _buildQuickFilterChip(
                context,
                'Con crédito',
                Icons.credit_card,
                () => Get.snackbar('Info', 'Filtro pendiente de implementar'),
              ),
              _buildQuickFilterChip(
                context,
                'Con balance pendiente',
                Icons.account_balance_wallet,
                () => Get.snackbar('Info', 'Filtro pendiente de implementar'),
              ),
              _buildQuickFilterChip(
                context,
                'Con órdenes',
                Icons.shopping_cart,
                () => Get.snackbar('Info', 'Filtro pendiente de implementar'),
              ),
              _buildQuickFilterChip(
                context,
                'Empresas',
                Icons.business,
                () => Get.snackbar('Info', 'Filtro pendiente de implementar'),
              ),
              _buildQuickFilterChip(
                context,
                'Personas naturales',
                Icons.person,
                () => Get.snackbar('Info', 'Filtro pendiente de implementar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 WIDGETS OPTIMIZADOS PARA TAMAÑOS

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 18.0, // Reducido de 20 a 18
    );

    final titleSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 13.0,
      tablet: 14.0,
      desktop: 15.0, // Reducido para mejor proporción
    );

    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: iconSize),
        SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small)),
        Text(
          title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    CustomerStatus? status,
    bool isSelected,
  ) {
    final optionPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );

    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 18.0, // Reducido de 20 a 18
    );

    final textSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 13.0,
      tablet: 14.0,
      desktop: 14.0,
    );

    final statusIndicatorSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 6.0,
      tablet: 7.0,
      desktop: 8.0,
    );

    return InkWell(
      onTap: () => controller.applyStatusFilter(status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: optionPadding,
          vertical: optionPadding * 0.75,
        ),
        margin: EdgeInsets.only(bottom: ResponsiveHelper.responsiveValue(context, mobile: 2, tablet: 3, desktop: 4)),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade400,
              size: iconSize,
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: textSize,
                ),
              ),
            ),
            if (status != null) ...[
              const SizedBox(width: 8),
              Container(
                width: statusIndicatorSize,
                height: statusIndicatorSize,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTypeOption(
    BuildContext context,
    String label,
    DocumentType? documentType,
    bool isSelected,
  ) {
    final optionPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );

    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 18.0,
    );

    final textSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 13.0,
      tablet: 14.0,
      desktop: 14.0,
    );

    return InkWell(
      onTap: () => controller.applyDocumentTypeFilter(documentType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: optionPadding,
          vertical: optionPadding * 0.75,
        ),
        margin: EdgeInsets.only(bottom: ResponsiveHelper.responsiveValue(context, mobile: 2, tablet: 3, desktop: 4)),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade400,
              size: iconSize,
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: textSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String sortBy,
    String sortOrder,
    bool isSelected,
  ) {
    final optionPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );

    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 18.0,
    );

    final textSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 13.0,
      tablet: 14.0,
      desktop: 14.0,
    );

    final arrowSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );

    return InkWell(
      onTap: () => controller.changeSorting(sortBy, sortOrder),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: optionPadding,
          vertical: optionPadding * 0.75,
        ),
        margin: EdgeInsets.only(bottom: ResponsiveHelper.responsiveValue(context, mobile: 2, tablet: 3, desktop: 4)),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade400,
              size: iconSize,
            ),
            SizedBox(width: ResponsiveHelper.getHorizontalSpacing(context, size: SpacingSize.small)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: textSize,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                sortOrder == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
                size: arrowSize,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final chipPadding = ResponsiveHelper.responsiveValue(
      context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );

    final iconSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );

    final textSize = ResponsiveHelper.responsiveValue(
      context,
      mobile: 11.0,
      tablet: 12.0,
      desktop: 12.0,
    );

    return ActionChip(
      onPressed: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: chipPadding * 0.75,
        vertical: chipPadding * 0.5,
      ),
      avatar: Icon(icon, size: iconSize),
      label: Text(
        label, 
        style: TextStyle(fontSize: textSize),
      ),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
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
}