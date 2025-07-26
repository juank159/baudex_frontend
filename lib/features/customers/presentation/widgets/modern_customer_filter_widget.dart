// lib/features/customers/presentation/widgets/modern_customer_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../domain/entities/customer.dart';
import '../controllers/customers_controller.dart';

class ModernCustomerFilterWidget extends GetView<CustomersController> {
  const ModernCustomerFilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header compacto
        _buildFilterHeader(context),
        const SizedBox(height: 16),

        // Filtros principales
        _buildStatusFilter(context),
        const SizedBox(height: 12),
        _buildQuickFilters(context),
        const SizedBox(height: 12),
        _buildSortingOptions(context),
      ],
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.tune,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Filtros de Búsqueda',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.clearFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear, size: 12, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Limpiar',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.traffic,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              const Text(
                'Estado del Cliente',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CustomerStatus.values.map((status) {
              return _buildStatusChip(status, false); // Simplificado sin estado
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(CustomerStatus status, bool isSelected) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case CustomerStatus.active:
        color = Colors.green;
        text = 'Activos';
        icon = Icons.check_circle;
        break;
      case CustomerStatus.inactive:
        color = Colors.orange;
        text = 'Inactivos';
        icon = Icons.pause_circle;
        break;
      case CustomerStatus.suspended:
        color = Colors.red;
        text = 'Suspendidos';
        icon = Icons.cancel;
        break;
    }

    return GestureDetector(
      onTap: () {}, // Simplificado sin funcionalidad
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              const Text(
                'Filtros Rápidos',
                style: TextStyle(
                  fontSize: 13,
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
                'Con Crédito',
                Icons.credit_card,
                Colors.blue,
                () {},
              ),
              _buildQuickFilterChip(
                'Con Balance',
                Icons.account_balance_wallet,
                Colors.orange,
                () {},
              ),
              _buildQuickFilterChip(
                'Empresas',
                Icons.business,
                Colors.purple,
                () {},
              ),
              _buildQuickFilterChip(
                'Personas',
                Icons.person,
                Colors.green,
                () {},
              ),
              _buildQuickFilterChip(
                'Sin Órdenes',
                Icons.shopping_cart_outlined,
                Colors.grey,
                () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String text, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortingOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sort,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ordenar Por',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildSortOption('Nombre A-Z', 'name_asc', Icons.sort_by_alpha),
              _buildSortOption('Nombre Z-A', 'name_desc', Icons.sort_by_alpha),
              _buildSortOption('Fecha (Recientes)', 'date_desc', Icons.access_time),
              _buildSortOption('Fecha (Antiguos)', 'date_asc', Icons.access_time),
              _buildSortOption('Mayor Balance', 'balance_desc', Icons.trending_up),
              _buildSortOption('Más Órdenes', 'orders_desc', Icons.shopping_cart),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(String text, String value, IconData icon) {
    final isSelected = false; // Simplificado
    
    return GestureDetector(
      onTap: () {}, // Simplificado
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}