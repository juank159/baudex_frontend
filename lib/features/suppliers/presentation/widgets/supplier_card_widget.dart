// lib/features/suppliers/presentation/widgets/supplier_card_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/config/themes/app_colors.dart';
import '../../../../app/config/themes/app_dimensions.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/supplier.dart';

class SupplierCardWidget extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const SupplierCardWidget({
    super.key,
    required this.supplier,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con nombre y estado
              _buildHeader(),
              
              const SizedBox(height: 4),
              
              // Información de contacto
              _buildContactInfo(),
              
              const SizedBox(height: 4),
              
              // Información comercial
              _buildCommercialInfo(),
              
              if (showActions) ...[
                const SizedBox(height: 6),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar con iniciales
        CircleAvatar(
          radius: 14,
          backgroundColor: _getStatusColor().withOpacity(0.2),
          child: Text(
            _getInitials(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        
        const SizedBox(width: 6),
        
        // Nombre y código
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                supplier.name,
                style: Get.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (supplier.code != null)
                Text(
                  'Código: ${supplier.code}',
                  style: Get.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
        
        // Estado
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 10,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 2),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final contactItems = <Widget>[];
    
    // Documento
    if (supplier.documentType != null && supplier.documentNumber != null) {
      contactItems.add(_buildInfoItem(
        Icons.badge_outlined,
        '${_getDocumentTypeText()}: ${supplier.documentNumber}',
        Colors.orange,
      ));
    }
    
    if (contactItems.isEmpty) {
      return _buildInfoItem(
        Icons.info_outline,
        'Sin información de documento',
        Colors.grey,
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 2,
      children: contactItems,
    );
  }

  Widget _buildCommercialInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildCommercialItem(
            'Moneda',
            supplier.currency,
            Icons.monetization_on_outlined,
          ),
        ),
        Expanded(
          child: _buildCommercialItem(
            'Términos',
            '${supplier.paymentTermsDays} días',
            Icons.schedule_outlined,
          ),
        ),
        if (supplier.hasCreditLimit)
          Expanded(
            child: _buildCommercialItem(
              'Crédito',
              AppFormatters.formatCurrency(supplier.creditLimit),
              Icons.credit_card_outlined,
            ),
          ),
        if (supplier.hasDiscount)
          Expanded(
            child: _buildCommercialItem(
              'Descuento',
              '${supplier.discountPercentage.toStringAsFixed(1)}%',
              Icons.discount_outlined,
            ),
          ),
      ],
    );
  }

  Widget _buildCommercialItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 10,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 7,
            ),
          ),
          Text(
            value,
            style: Get.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 10,
          color: color,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            text,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Fecha de actualización
        Expanded(
          child: Text(
            'Actualizado: ${AppFormatters.formatDate(supplier.updatedAt)}',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
              fontSize: 8,
            ),
          ),
        ),
        
        // Botones de acción
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
          tooltip: 'Editar',
          iconSize: 14,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Eliminar',
          iconSize: 14,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          color: Colors.red.shade600,
        ),
      ],
    );
  }

  // Helper methods
  String _getInitials() {
    final words = supplier.name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, 2).toUpperCase();
    }
    return 'PR';
  }

  Color _getStatusColor() {
    switch (supplier.status) {
      case SupplierStatus.active:
        return Colors.green;
      case SupplierStatus.inactive:
        return Colors.orange;
      case SupplierStatus.blocked:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (supplier.status) {
      case SupplierStatus.active:
        return Icons.check_circle;
      case SupplierStatus.inactive:
        return Icons.pause_circle;
      case SupplierStatus.blocked:
        return Icons.block;
    }
  }

  String _getStatusText() {
    switch (supplier.status) {
      case SupplierStatus.active:
        return 'Activo';
      case SupplierStatus.inactive:
        return 'Inactivo';
      case SupplierStatus.blocked:
        return 'Bloqueado';
    }
  }

  String _getDocumentTypeText() {
    switch (supplier.documentType) {
      case DocumentType.nit:
        return 'NIT';
      case DocumentType.cc:
        return 'CC';
      case DocumentType.ce:
        return 'CE';
      case DocumentType.passport:
        return 'Pasaporte';
      case DocumentType.rut:
        return 'RUT';
      case DocumentType.other:
        return 'Otro';
      case null:
        return 'Documento';
    }
  }
}