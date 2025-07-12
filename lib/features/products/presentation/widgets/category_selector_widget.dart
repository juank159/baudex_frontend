// lib/features/products/presentation/widgets/category_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/custom_button.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../controllers/product_form_controller.dart';

class CategorySelectorWidget extends StatelessWidget {
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final Function(String categoryId, String categoryName) onCategorySelected;
  final String label;
  final String hint;
  final bool isRequired;

  const CategorySelectorWidget({
    super.key,
    this.selectedCategoryId,
    this.selectedCategoryName,
    required this.onCategorySelected,
    this.label = 'Categoría',
    this.hint = 'Seleccionar categoría',
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCategorySelector(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.category,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label${isRequired ? ' *' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedCategoryName ?? hint,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          selectedCategoryName != null
                              ? Colors.black87
                              : Colors.grey.shade500,
                      fontWeight:
                          selectedCategoryName != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600, size: 24),
          ],
        ),
      ),
    );
  }

  void _showCategorySelector(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => CategorySelectorDialog(
            selectedCategoryId: selectedCategoryId,
            onCategorySelected: onCategorySelected,
          ),
    );
  }
}

class CategorySelectorDialog extends StatefulWidget {
  final String? selectedCategoryId;
  final Function(String categoryId, String categoryName) onCategorySelected;

  const CategorySelectorDialog({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelectorDialog> createState() => _CategorySelectorDialogState();
}

class _CategorySelectorDialogState extends State<CategorySelectorDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchTerm = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _loadCategories();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != _searchTerm) {
        _searchTerm = query;
        if (query.isEmpty) {
          setState(() {
            _filteredCategories = _categories;
            _isSearching = false;
          });
        } else if (query.length >= 2) {
          // ✅ USAR SOLO FILTRO LOCAL en lugar de SearchCategoriesUseCase
          _searchCategoriesLocally(query);
        }
      }
    });
  }

  Future<void> _loadCategories() async {
    print('🔍 CategorySelectorDialog: Obteniendo categorías...');
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Usar el controller del ProductForm para obtener categorías desde cache
      final productFormController = Get.find<ProductFormController>();
      final categories = productFormController.availableCategories;
      
      if (categories.isNotEmpty) {
        print('✅ CategorySelectorDialog: Usando ${categories.length} categorías desde cache');
        setState(() {
          _categories = categories;
          _filteredCategories = _categories;
        });
      } else {
        print('🔄 CategorySelectorDialog: Cache vacío, cargando desde API...');
        // Si no hay categorías en cache, cargar usando el método del controller
        await productFormController.loadAvailableCategoriesIfNeeded();
        final updatedCategories = productFormController.availableCategories;
        
        setState(() {
          _categories = updatedCategories;
          _filteredCategories = _categories;
        });
        
        print('✅ CategorySelectorDialog: ${updatedCategories.length} categorías cargadas desde API');
      }

      // ✅ DEBUG: Imprimir categorías para verificar
      for (int i = 0; i < _categories.length; i++) {
        print(
          '  Categoría $i: ${_categories[i].name} (${_categories[i].id})',
        );
      }
    } catch (e) {
      print('💥 CategorySelectorDialog: Error inesperado: $e');
      _showError('Error inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ MÉTODO ACTUALIZADO: Solo filtro local
  void _searchCategoriesLocally(String query) {
    print('🔍 CategorySelectorDialog: Buscando localmente: "$query"');
    setState(() {
      _isSearching = true;
    });

    // Simular delay de búsqueda
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final filtered =
            _categories.where((category) {
              return category.name.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (category.description?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false);
            }).toList();

        print(
          '✅ CategorySelectorDialog: ${filtered.length} categorías encontradas para "$query"',
        );

        setState(() {
          _filteredCategories = filtered;
          _isSearching = false;
        });
      }
    });
  }

  void _selectCategory(Category category) {
    print(
      '🎯 CategorySelectorDialog: Categoría seleccionada: ${category.name}',
    );
    setState(() {
      _selectedCategoryId = category.id;
    });
  }

  void _confirmSelection() {
    if (_selectedCategoryId != null) {
      final selectedCategory = _filteredCategories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
        orElse:
            () =>
                _categories.firstWhere((cat) => cat.id == _selectedCategoryId),
      );

      print(
        '✅ CategorySelectorDialog: Confirmando selección: ${selectedCategory.name}',
      );
      widget.onCategorySelected(selectedCategory.id, selectedCategory.name);
      Navigator.of(context).pop();
    } else {
      print('⚠️ CategorySelectorDialog: No hay categoría seleccionada');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.category,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Seleccionar Categoría',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Búsqueda
            CustomTextField(
              controller: _searchController,
              label: 'Buscar categoría',
              hint: 'Escribe para buscar...',
              prefixIcon: Icons.search,
              suffixIcon: _searchTerm.isNotEmpty ? Icons.clear : null,
              onSuffixIconPressed:
                  _searchTerm.isNotEmpty
                      ? () {
                        _searchController.clear();
                        _searchTerm = '';
                        setState(() {
                          _filteredCategories = _categories;
                        });
                      }
                      : null,
            ),

            const SizedBox(height: 16),

            // Lista de categorías
            Expanded(child: _buildCategoriesList()),

            const SizedBox(height: 20),

            // Acciones
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancelar',
                    type: ButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Seleccionar',
                    onPressed:
                        _selectedCategoryId != null ? _confirmSelection : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Cargando categorías...');
    }

    if (_filteredCategories.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Header de resultados
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.list, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${_filteredCategories.length} categoría${_filteredCategories.length != 1 ? 's' : ''} disponible${_filteredCategories.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isSearching) ...[
                const Spacer(),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Lista
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _filteredCategories.length,
              itemBuilder: (context, index) {
                final category = _filteredCategories[index];
                final isSelected = category.id == _selectedCategoryId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectCategory(category),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : Colors.white,
                          border: Border.all(
                            color:
                                isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // Icono de categoría
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.folder,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                size: 20,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Información de la categoría
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.black87,
                                    ),
                                  ),
                                  if (category.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      category.description!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'ACTIVA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (category.productsCount != null)
                                        Text(
                                          '${category.productsCount} productos',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Indicador de selección
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isSearchMode = _searchTerm.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearchMode ? Icons.search_off : Icons.folder_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearchMode
                ? 'No se encontraron categorías'
                : 'No hay categorías disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearchMode
                ? 'Intenta con otros términos de búsqueda'
                : 'Crea tu primera categoría para comenzar',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (!isSearchMode) ...[
            const SizedBox(height: 20),
            CustomButton(
              text: 'Crear Categoría',
              icon: Icons.add,
              onPressed: () {
                Navigator.of(context).pop();
                Get.toNamed('/categories/create');
              },
            ),
          ],
        ],
      ),
    );
  }
}
