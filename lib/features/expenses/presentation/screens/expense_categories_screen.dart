// lib/features/expenses/presentation/screens/expense_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/formatters.dart';
import '../controllers/expense_categories_controller.dart';
import '../widgets/expense_category_form_dialog.dart';
import '../../domain/entities/expense_category.dart';

class ExpenseCategoriesScreen extends GetView<ExpenseCategoriesController> {
  const ExpenseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Categorías'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshCategories(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(context),
          
          // Search Bar
          _buildSearchBar(context),
          
          // Categories List
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredCategories.isEmpty) {
                return _buildEmptyState(context);
              }

              return _buildCategoriesList(context);
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Categoría'),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total',
                  controller.totalCategories.toString(),
                  Icons.category,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Activas',
                  controller.activeCategories.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Inactivas',
                  controller.inactiveCategories.toString(),
                  Icons.pause_circle,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Presupuesto',
                  AppFormatters.formatCurrency(controller.totalBudget),
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) => controller.updateSearchQuery(value),
        decoration: InputDecoration(
          hintText: 'Buscar categorías...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.updateSearchQuery(''),
                )
              : const SizedBox.shrink()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshCategories(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.filteredCategories.length,
        itemBuilder: (context, index) {
          final category = controller.filteredCategories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ExpenseCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(category),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.category, color: Colors.white, size: 20),
        ),
        title: Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                category.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (category.monthlyBudget > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.formattedBudget,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: category.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.isActive ? 'Activa' : 'Inactiva',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: category.isActive ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCategoryAction(context, category, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    category.isActive ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(category.isActive ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showCategoryDetails(context, category),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'No se encontraron categorías'
                : 'No hay categorías creadas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'Intenta con otros términos de búsqueda'
                : 'Crea tu primera categoría de gastos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: 24),
          if (controller.searchQuery.value.isEmpty)
            ElevatedButton.icon(
              onPressed: () => _showCreateCategoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear Primera Categoría'),
            ),
        ],
      ),
    );
  }

  void _handleCategoryAction(
    BuildContext context,
    ExpenseCategory category,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(context, category);
        break;
      case 'toggle_status':
        controller.toggleCategoryStatus(category);
        break;
      case 'delete':
        _showDeleteConfirmation(context, category);
        break;
    }
  }

  void _showCreateCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExpenseCategoryFormDialog(
        onCategorySaved: (category) {
          // Category is already added by the controller
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => ExpenseCategoryFormDialog(
        category: category,
        onCategorySaved: (updatedCategory) {
          // Category is already updated by the controller
        },
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, ExpenseCategory category) {
    controller.selectCategory(category);
    // TODO: Navigate to category details screen if needed
  }

  void _showDeleteConfirmation(BuildContext context, ExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la categoría "${category.name}"?\n\n'
          'Esta acción no se puede deshacer y puede afectar los gastos existentes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.deleteCategory(category.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        final colorString = category.color!.replaceAll('#', '');
        final colorValue = int.parse('FF$colorString', radix: 16);
        return Color(colorValue);
      } catch (e) {
        // Si no se puede parsear el color, usar color por defecto
      }
    }
    
    // Colores por defecto basados en el hash del nombre
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
    ];
    
    final index = category.name.hashCode % colors.length;
    return colors[index.abs()];
  }
}