// lib/features/customers/presentation/widgets/customer_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
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
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.clearFilters,
                child: const Text('Limpiar'),
              ),
            ],
          ),
        ),

        // Filtros
        _buildStatusFilter(context),
        const SizedBox(height: 16),
        _buildDocumentTypeFilter(context),
        const SizedBox(height: 16),
        _buildLocationFilters(context),
        const SizedBox(height: 16),
        _buildSortingOptions(context),
        const SizedBox(height: 16),
        _buildQuickFilters(context),
      ],
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.toggle_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Estado',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

  Widget _buildStatusOption(
    BuildContext context,
    String label,
    CustomerStatus? status,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => controller.applyStatusFilter(status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (status != null) ...[
              const Spacer(),
              Container(
                width: 8,
                height: 8,
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

  Widget _buildDocumentTypeFilter(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tipo de Documento',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

  Widget _buildDocumentTypeOption(
    BuildContext context,
    String label,
    DocumentType? documentType,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => controller.applyDocumentTypeFilter(documentType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildLocationFilters(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ubicación',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TODO: Implementar filtros de ciudad y estado
          const Text(
            'Filtros de ubicación pendientes de implementar',
            style: TextStyle(
              fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sort, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ordenar por',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            return Column(
              children: [
                _buildSortOption(
                  context,
                  'Más recientes',
                  'createdAt',
                  'DESC',
                  controller.sortBy == 'createdAt' &&
                      controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Más antiguos',
                  'createdAt',
                  'ASC',
                  controller.sortBy == 'createdAt' &&
                      controller.sortOrder == 'ASC',
                ),
                _buildSortOption(
                  context,
                  'Nombre (A-Z)',
                  'firstName',
                  'ASC',
                  controller.sortBy == 'firstName' &&
                      controller.sortOrder == 'ASC',
                ),
                _buildSortOption(
                  context,
                  'Nombre (Z-A)',
                  'firstName',
                  'DESC',
                  controller.sortBy == 'firstName' &&
                      controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Mayor crédito',
                  'creditLimit',
                  'DESC',
                  controller.sortBy == 'creditLimit' &&
                      controller.sortOrder == 'DESC',
                ),
                _buildSortOption(
                  context,
                  'Mayor balance',
                  'currentBalance',
                  'DESC',
                  controller.sortBy == 'currentBalance' &&
                      controller.sortOrder == 'DESC',
                ),
              ],
            );
          }),
        ],
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
    return InkWell(
      onTap: () => controller.changeSorting(sortBy, sortOrder),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                sortOrder == 'ASC' ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filtros rápidos',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickFilterChip(
                context,
                'Con crédito',
                Icons.credit_card,
                () {
                  // Filtrar clientes con límite de crédito > 0
                  Get.snackbar('Info', 'Filtro pendiente de implementar');
                },
              ),
              _buildQuickFilterChip(
                context,
                'Con balance pendiente',
                Icons.account_balance_wallet,
                () {
                  // Filtrar clientes con balance > 0
                  Get.snackbar('Info', 'Filtro pendiente de implementar');
                },
              ),
              _buildQuickFilterChip(
                context,
                'Con órdenes',
                Icons.shopping_cart,
                () {
                  // Filtrar clientes con órdenes > 0
                  Get.snackbar('Info', 'Filtro pendiente de implementar');
                },
              ),
              _buildQuickFilterChip(context, 'Empresas', Icons.business, () {
                // Filtrar clientes que son empresas (tienen companyName)
                Get.snackbar('Info', 'Filtro pendiente de implementar');
              }),
              _buildQuickFilterChip(
                context,
                'Personas naturales',
                Icons.person,
                () {
                  // Filtrar clientes que son personas (no tienen companyName)
                  Get.snackbar('Info', 'Filtro pendiente de implementar');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
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
