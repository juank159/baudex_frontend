// lib/features/products/presentation/widgets/modern_category_selector.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/utils/responsive_helper.dart';
import '../../../categories/domain/entities/category.dart';
import '../controllers/product_form_controller.dart';
import '../../../../app/shared/widgets/loading_widget.dart';

class ModernCategorySelector extends StatelessWidget {
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final Function(String categoryId, String categoryName) onCategorySelected;
  final bool isRequired;

  const ModernCategorySelector({
    super.key,
    this.selectedCategoryId,
    this.selectedCategoryName,
    required this.onCategorySelected,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final primaryColor = Theme.of(context).primaryColor;
    final hasValue = selectedCategoryName != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Text(
                'Categoría',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                  color: hasValue 
                    ? primaryColor
                    : Colors.grey.shade700,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                  ),
                ),
            ],
          ),
        ),
        
        // Selector
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasValue
                ? primaryColor.withOpacity(0.3)
                : Colors.grey.shade300,
              width: 1,
            ),
            color: Colors.white,
            boxShadow: hasValue ? [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showCategorySelector(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: isMobile ? 12 : 14,
                ),
                child: Row(
                  children: [
                    // Ícono simple sin fondo
                    Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: hasValue 
                        ? primaryColor
                        : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 12),
                    
                    // Texto
                    Expanded(
                      child: Text(
                        selectedCategoryName ?? 'Seleccionar categoría',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 15,
                          fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                          color: hasValue 
                            ? Colors.grey.shade800 
                            : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    
                    // Flecha
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCategorySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategorySelectorBottomSheet(
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: onCategorySelected,
      ),
    );
  }
}

class _CategorySelectorBottomSheet extends StatefulWidget {
  final String? selectedCategoryId;
  final Function(String categoryId, String categoryName) onCategorySelected;

  const _CategorySelectorBottomSheet({
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<_CategorySelectorBottomSheet> createState() => _CategorySelectorBottomSheetState();
}

class _CategorySelectorBottomSheetState extends State<_CategorySelectorBottomSheet> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController _searchController = TextEditingController();
  
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = false;
  String _searchTerm = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
    _loadCategories();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != _searchTerm) {
        _searchTerm = query;
        _filterCategories();
      }
    });
  }

  void _filterCategories() {
    setState(() {
      if (_searchTerm.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories.where((category) {
          return category.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                 (category.description?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final productFormController = Get.find<ProductFormController>();
      final categories = productFormController.availableCategories;
      
      if (categories.isNotEmpty) {
        setState(() {
          _categories = categories;
          _filteredCategories = _categories;
        });
      } else {
        await productFormController.loadAvailableCategoriesIfNeeded();
        final updatedCategories = productFormController.availableCategories;
        
        setState(() {
          _categories = updatedCategories;
          _filteredCategories = _categories;
        });
      }
    } catch (e) {
      print('Error cargando categorías: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 300),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Seleccionar Categoría',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar categoría...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _searchTerm = '';
                              _filterCategories();
                            },
                            icon: const Icon(Icons.clear, size: 18),
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                
                // Lista de categorías
                Flexible(child: _buildCategoriesList()),
                
                // Padding inferior
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                _searchTerm.isNotEmpty ? Icons.search_off : Icons.category_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _searchTerm.isNotEmpty
                  ? 'No se encontraron categorías'
                  : 'No hay categorías disponibles',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        final isSelected = category.id == _selectedCategoryId;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategoryId = category.id);
                widget.onCategorySelected(category.id, category.name);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Ícono
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        size: 20,
                        color: isSelected 
                          ? Colors.white
                          : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Información
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade800,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Checkmark
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}