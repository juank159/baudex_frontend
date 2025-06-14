// lib/features/categories/presentation/screens/category_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/category_detail_controller.dart';
import '../widgets/category_card_widget.dart';
import '../../domain/entities/category.dart';

class CategoryDetailScreen extends GetView<CategoryDetailController> {
  const CategoryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget(message: 'Cargando detalles...');
        }

        if (!controller.hasCategory) {
          return _buildErrorState(context);
        }

        return ResponsiveLayout(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
        );
      }),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Obx(
        () => Text(
          controller.hasCategory ? controller.category!.name : 'Categoría',
        ),
      ),
      elevation: 0,
      actions: [
        // Editar
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: controller.goToEditCategory,
        ),

        // Cambiar estado
        Obx(
          () => IconButton(
            icon: Icon(
              controller.category?.isActive == true
                  ? Icons.toggle_on
                  : Icons.toggle_off,
              color:
                  controller.category?.isActive == true
                      ? Colors.green
                      : Colors.orange,
            ),
            onPressed: controller.showStatusDialog,
          ),
        ),

        // Menú de opciones
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, context),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'create_subcategory',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Crear Subcategoría'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Actualizar'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
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
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Breadcrumbs
        _buildBreadcrumbs(context),

        // Contenido con tabs
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _buildTabBar(context),
                Expanded(child: _buildTabBarView(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: AdaptiveContainer(
        maxWidth: 800,
        child: Column(
          children: [
            SizedBox(height: context.verticalSpacing),
            _buildBreadcrumbs(context),
            SizedBox(height: context.verticalSpacing),
            CustomCard(child: _buildCategoryDetails(context)),
            SizedBox(height: context.verticalSpacing),
            if (controller.hasSubcategories)
              CustomCard(child: _buildSubcategoriesSection(context)),
            SizedBox(height: context.verticalSpacing),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Contenido principal
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                _buildBreadcrumbs(context),
                const SizedBox(height: 24),
                CustomCard(child: _buildCategoryDetails(context)),
                const SizedBox(height: 24),
                if (controller.hasSubcategories)
                  CustomCard(child: _buildSubcategoriesSection(context)),
              ],
            ),
          ),
        ),

        // Panel lateral
        Container(
          width: 350,
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
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Acciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSidebarActions(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    return Obx(() {
      if (controller.breadcrumbs.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.responsivePadding.left),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Wrap(
          children:
              controller.breadcrumbs.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final isLast = index == controller.breadcrumbs.length - 1;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index > 0) ...[
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                    ],
                    GestureDetector(
                      onTap:
                          isLast ? null : () => controller.goToParentCategory(),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color:
                              isLast
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                          fontWeight:
                              isLast ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                );
              }).toList(),
        ),
      );
    });
  }

  Widget _buildTabBar(BuildContext context) {
    return Material(
      color: Colors.white,
      child: TabBar(
        controller: controller.tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(text: 'Detalles'),
          Tab(text: 'Subcategorías'),
          Tab(text: 'Estadísticas'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context) {
    return TabBarView(
      controller: controller.tabController,
      children: [
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: _buildCategoryDetails(context),
        ),
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: _buildSubcategoriesSection(context),
        ),
        SingleChildScrollView(
          padding: context.responsivePadding,
          child: _buildStatsSection(context),
        ),
      ],
    );
  }

  Widget _buildCategoryDetails(BuildContext context) {
    return Obx(() {
      final category = controller.category!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con imagen y título
          Row(
            children: [
              // Imagen de categoría
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image:
                      category.image != null
                          ? DecorationImage(
                            image: NetworkImage(category.image!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    category.image == null
                        ? Icon(
                          Icons.category,
                          size: 40,
                          color: Colors.grey.shade400,
                        )
                        : null,
              ),

              SizedBox(width: context.horizontalSpacing),

              // Información básica
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(
                          context,
                          mobile: 20,
                          tablet: 24,
                          desktop: 28,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            category.isActive
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.status.name.toUpperCase(),
                        style: TextStyle(
                          color:
                              category.isActive
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: context.verticalSpacing * 2),

          // Descripción
          if (category.description != null) ...[
            _buildDetailRow('Descripción', category.description!),
            SizedBox(height: context.verticalSpacing),
          ],

          // Detalles técnicos
          _buildDetailRow('Slug', category.slug),
          SizedBox(height: context.verticalSpacing),

          _buildDetailRow('Orden', category.sortOrder.toString()),
          SizedBox(height: context.verticalSpacing),

          _buildDetailRow(
            'Productos',
            (category.productsCount ?? 0).toString(),
          ),
          SizedBox(height: context.verticalSpacing),

          _buildDetailRow('Nivel', category.level.toString()),
          SizedBox(height: context.verticalSpacing),

          // Fechas
          _buildDetailRow('Creado', _formatDate(category.createdAt)),
          SizedBox(height: context.verticalSpacing),

          _buildDetailRow('Actualizado', _formatDate(category.updatedAt)),
        ],
      );
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoriesSection(BuildContext context) {
    return Obx(() {
      if (!controller.hasSubcategories) {
        return _buildEmptySubcategories(context);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Subcategorías (${controller.subcategories.length})',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              CustomButton(
                text: 'Nueva',
                icon: Icons.add,
                onPressed: controller.goToCreateSubcategory,
              ),
            ],
          ),

          SizedBox(height: context.verticalSpacing),

          ...controller.subcategories.map(
            (subcategory) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CategoryCardWidget(
                category: subcategory,
                onTap: () => controller.goToSubcategory(subcategory.id),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptySubcategories(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.category_outlined, size: 60, color: Colors.grey.shade400),
        SizedBox(height: context.verticalSpacing),
        Text(
          'No hay subcategorías',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: context.verticalSpacing / 2),
        Text(
          'Crea la primera subcategoría para esta categoría',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.verticalSpacing * 2),
        CustomButton(
          text: 'Crear Subcategoría',
          icon: Icons.add,
          onPressed: controller.goToCreateSubcategory,
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Obx(() {
      final category = controller.category!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18),
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: context.verticalSpacing),

          _buildStatCard(
            'Productos Totales',
            (category.productsCount ?? 0).toString(),
            Icons.inventory,
            Colors.blue,
          ),

          SizedBox(height: context.verticalSpacing),

          _buildStatCard(
            'Subcategorías',
            controller.subcategories.length.toString(),
            Icons.category,
            Colors.green,
          ),

          SizedBox(height: context.verticalSpacing),

          _buildStatCard(
            'Nivel de Profundidad',
            category.level.toString(),
            Icons.layers,
            Colors.orange,
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Editar',
            icon: Icons.edit,
            type: ButtonType.outline,
            onPressed: controller.goToEditCategory,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(
            () => CustomButton(
              text:
                  controller.isUpdatingStatus
                      ? 'Cambiando...'
                      : 'Cambiar Estado',
              icon:
                  controller.category?.isActive == true
                      ? Icons.toggle_off
                      : Icons.toggle_on,
              onPressed:
                  controller.isUpdatingStatus
                      ? null
                      : controller.showStatusDialog,
              isLoading: controller.isUpdatingStatus,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Nueva Subcategoría',
            icon: Icons.add,
            onPressed: controller.goToCreateSubcategory,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: 'Editar Categoría',
          icon: Icons.edit,
          onPressed: controller.goToEditCategory,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        Obx(
          () => CustomButton(
            text:
                controller.isUpdatingStatus ? 'Cambiando...' : 'Cambiar Estado',
            icon:
                controller.category?.isActive == true
                    ? Icons.toggle_off
                    : Icons.toggle_on,
            type: ButtonType.outline,
            onPressed:
                controller.isUpdatingStatus
                    ? null
                    : controller.showStatusDialog,
            isLoading: controller.isUpdatingStatus,
            width: double.infinity,
          ),
        ),

        const SizedBox(height: 12),

        CustomButton(
          text: 'Nueva Subcategoría',
          icon: Icons.add,
          type: ButtonType.outline,
          onPressed: controller.goToCreateSubcategory,
          width: double.infinity,
        ),

        const SizedBox(height: 24),

        const Divider(),

        const SizedBox(height: 12),

        CustomButton(
          text: 'Actualizar',
          icon: Icons.refresh,
          type: ButtonType.outline,
          onPressed: controller.refreshData,
          width: double.infinity,
        ),

        const SizedBox(height: 12),

        Obx(
          () => CustomButton(
            text: controller.isDeleting ? 'Eliminando...' : 'Eliminar',
            icon: Icons.delete,
            type: ButtonType.outline,
            onPressed: controller.isDeleting ? null : controller.confirmDelete,
            isLoading: controller.isDeleting,
            width: double.infinity,
            backgroundColor: Colors.red,
          ),
        ),

        const Spacer(),

        // Información de última actualización
        Obx(() {
          if (!controller.hasCategory) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Última actualización',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(controller.category!.updatedAt),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 100, color: Colors.grey.shade400),
          SizedBox(height: context.verticalSpacing),
          Text(
            'Categoría no encontrada',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: context.verticalSpacing / 2),
          Text(
            'La categoría que buscas no existe o ha sido eliminada',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.verticalSpacing * 2),
          CustomButton(
            text: 'Volver a Categorías',
            icon: Icons.arrow_back,
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    if (context.isMobile) {
      return FloatingActionButton(
        onPressed: controller.goToCreateSubcategory,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  // ==================== ACTION METHODS ====================

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'create_subcategory':
        controller.goToCreateSubcategory();
        break;
      case 'refresh':
        controller.refreshData();
        break;
      case 'delete':
        controller.confirmDelete();
        break;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
