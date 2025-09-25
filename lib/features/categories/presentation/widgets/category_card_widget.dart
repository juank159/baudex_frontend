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
      padding: const EdgeInsets.all(3.0), // ✅ REDUCIDO A LA MITAD: de 6 a 3
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Minimizar altura
        children: [
          // Header con estado y acciones - TODO EN UNA LÍNEA
          Row(
            children: [
              // Icono de categoría más pequeño
              _buildCategoryIcon(context),
              const SizedBox(width: 3), // ✅ REDUCIDO A LA MITAD: de 6 a 3

              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 10), // ✅ REDUCIDO: de 12 a 10
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.description != null) ...[
                      const SizedBox(height: 1), // ✅ REDUCIDO A LA MITAD: de 2 a 1
                      Text(
                        category.description!,
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 8), // ✅ REDUCIDO: de 9 a 8
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1, // ✅ Solo 1 línea para ahorrar espacio
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Estado más pequeño
              _buildStatusBadge(context),
              
              const SizedBox(width: 2), // ✅ REDUCIDO A LA MITAD: de 4 a 2
              
              // ✅ SOLO ICONOS DE ACCIÓN EN MÓVIL
              _buildMobileActionIcons(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0), // ✅ REDUCIDO A LA MITAD: de 8 a 4
      child: Row(
        children: [
          // Icono
          _buildCategoryIcon(context),
          const SizedBox(width: 5), // ✅ REDUCIDO A LA MITAD: de 10 a 5

          // Información principal
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, tablet: 13), // ✅ REDUCIDO: de 15 a 13
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 2), // ✅ REDUCIDO A LA MITAD: de 4 a 2
                  Text(
                    category.description!,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, tablet: 10), // ✅ REDUCIDO: de 12 a 10
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1, // ✅ REDUCIDO: de 2 a 1 línea
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Información adicional
          if (!isCompact) Expanded(flex: 2, child: _buildCategoryInfo(context)),

          const SizedBox(width: 5), // ✅ REDUCIDO A LA MITAD: de 10 a 5

          // Estado y acciones
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(context),
              const SizedBox(height: 4), // ✅ REDUCIDO A LA MITAD: de 8 a 4
              _buildActionButtons(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0), // ✅ REDUCIDO A LA MITAD: de 8 a 4
      child: Row(
        children: [
          // Icono
          _buildCategoryIcon(context),
          const SizedBox(width: 6), // ✅ REDUCIDO A LA MITAD: de 12 a 6

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
                            desktop: 14, // ✅ REDUCIDO: de 16 a 14
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4), // ✅ REDUCIDO A LA MITAD: de 8 a 4
                    _buildStatusBadge(context),
                  ],
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 3), // ✅ REDUCIDO A LA MITAD: de 6 a 3
                  Text(
                    category.description!,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, desktop: 10), // ✅ REDUCIDO: de 12 a 10
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1, // ✅ REDUCIDO: de 2 a 1 línea
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Información adicional
          if (!isCompact) Expanded(flex: 2, child: _buildCategoryInfo(context)),

          const SizedBox(width: 6), // ✅ REDUCIDO A LA MITAD: de 12 a 6

          // Acciones
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final iconSize = context.isMobile ? 16.0 : (context.isTablet ? 22.0 : 26.0); // ✅ REDUCIDO A LA MITAD: móvil 20→16, tablet 28→22, desktop 32→26

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
      padding: EdgeInsets.symmetric(
        horizontal: context.isMobile ? 2 : 3, // ✅ REDUCIDO A LA MITAD: móvil 4→2, otros 6→3
        vertical: context.isMobile ? 1 : 2 // ✅ REDUCIDO A LA MITAD: móvil 2→1, otros 3→2
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.isMobile ? 4 : 6), // ✅ REDUCIDO: móvil 6→4, otros 8→6
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: context.isMobile ? 6 : 8, // ✅ REDUCIDO: móvil 7→6, otros 10→8
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
      padding: const EdgeInsets.only(bottom: 2), // ✅ REDUCIDO A LA MITAD: de 4 a 2
      child: Row(
        children: [
          Icon(icon, size: 8, color: Colors.grey.shade500), // ✅ REDUCIDO: de 12 a 8
          const SizedBox(width: 2), // ✅ REDUCIDO A LA MITAD: de 4 a 2
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: context.isMobile ? 8 : 9, // ✅ REDUCIDO: móvil 10→8, otros 11→9
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: context.isMobile ? 8 : 9, // ✅ REDUCIDO: móvil 10→8, otros 11→9
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

  /// ✅ NUEVO: Solo iconos para móvil (más compacto)
  Widget _buildMobileActionIcons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(2), // ✅ REDUCIDO A LA MITAD: de 4 a 2
              child: Icon(
                Icons.edit,
                size: 12, // ✅ REDUCIDO: de 16 a 12
                color: Colors.blue.shade600,
              ),
            ),
          ),
        if (onEdit != null && onDelete != null) const SizedBox(width: 2), // ✅ REDUCIDO A LA MITAD: de 4 a 2
        if (onDelete != null)
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(2), // ✅ REDUCIDO A LA MITAD: de 4 a 2
              child: Icon(
                Icons.delete,
                size: 12, // ✅ REDUCIDO: de 16 a 12
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // En móvil ya no usamos este método, usamos _buildMobileActionIcons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            tooltip: 'Editar categoría',
            iconSize: context.isDesktop ? 14 : 12, // ✅ REDUCIDO: desktop 18→14, tablet 16→12
            visualDensity: VisualDensity.compact, // ✅ COMPACTO
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            tooltip: 'Eliminar categoría',
            color: Colors.red,
            iconSize: context.isDesktop ? 14 : 12, // ✅ REDUCIDO: desktop 18→14, tablet 16→12
            visualDensity: VisualDensity.compact, // ✅ COMPACTO
          ),
      ],
    );
  }
}
