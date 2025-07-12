// lib/features/categories/presentation/widgets/category_card_widget.dart
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../domain/entities/category.dart';

class CategoryCardWidget extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompact;

  const CategoryCardWidget({
    super.key,
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con estado y acciones
          Row(
            children: [
              // Icono de categoría
              _buildCategoryIcon(context),
              const SizedBox(width: 12),

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 16),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description!,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 12),
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Estado
              _buildStatusBadge(context),
            ],
          ),

          const SizedBox(height: 12),

          // Información adicional
          if (!isCompact) ...[
            _buildCategoryInfo(context),
            const SizedBox(height: 12),
          ],

          // Acciones
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Icono
          _buildCategoryIcon(context),
          const SizedBox(width: 16),

          // Información principal
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, tablet: 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    category.description!,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, tablet: 14),
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Información adicional
          if (!isCompact) Expanded(flex: 2, child: _buildCategoryInfo(context)),

          const SizedBox(width: 16),

          // Estado y acciones
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(context),
              const SizedBox(height: 8),
              _buildActionButtons(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Icono
          _buildCategoryIcon(context),
          const SizedBox(width: 20),

          // Información principal
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                            context,
                            desktop: 20,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(context),
                  ],
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    category.description!,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, desktop: 14),
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Información adicional
          if (!isCompact) Expanded(flex: 2, child: _buildCategoryInfo(context)),

          const SizedBox(width: 20),

          // Acciones
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final iconSize = context.isMobile ? 40.0 : (context.isTablet ? 48.0 : 56.0);

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color:
            category.isActive
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              category.isActive
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child:
          category.image != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  category.image!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          _buildDefaultIcon(context, iconSize),
                ),
              )
              : _buildDefaultIcon(context, iconSize),
    );
  }

  Widget _buildDefaultIcon(BuildContext context, double iconSize) {
    return Icon(
      category.isParent ? Icons.folder : Icons.category,
      size: iconSize * 0.5,
      color:
          category.isActive
              ? Theme.of(context).primaryColor
              : Colors.grey.shade500,
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = category.isActive ? Colors.green : Colors.orange;
    final text = category.isActive ? 'ACTIVA' : 'INACTIVA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: context.isMobile ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.parent != null)
          _buildInfoItem(
            context,
            'Padre',
            category.parent!.name,
            Icons.arrow_upward,
          ),

        if (category.isParent)
          _buildInfoItem(
            context,
            'Subcategorías',
            '${category.children?.length ?? 0}',
            Icons.account_tree,
          ),

        if (category.productsCount != null)
          _buildInfoItem(
            context,
            'Productos',
            '${category.productsCount}',
            Icons.inventory_2,
          ),

        _buildInfoItem(context, 'Orden', '${category.sortOrder}', Icons.sort),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: context.isMobile ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (context.isMobile) {
      return Row(
        children: [
          if (onEdit != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          if (onEdit != null && onDelete != null) const SizedBox(width: 8),
          if (onDelete != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            tooltip: 'Editar categoría',
            iconSize: context.isDesktop ? 24 : 20,
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            tooltip: 'Eliminar categoría',
            color: Colors.red,
            iconSize: context.isDesktop ? 24 : 20,
          ),
      ],
    );
  }
}
