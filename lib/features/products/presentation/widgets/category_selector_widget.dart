// lib/features/products/presentation/widgets/category_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../../app/shared/widgets/custom_text_field.dart';
import '../../../../app/shared/widgets/loading_widget.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/core/utils/responsive_helper.dart';
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
    final isMobile = ResponsiveHelper.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCategorySelector(context),
        borderRadius: BorderRadius.circular(12),
        child: FuturisticContainer(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          gradient: ElegantLightTheme.cardGradient,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: ElegantLightTheme.infoGradient,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: ElegantLightTheme.glowShadow,
                ),
                child: Icon(
                  Icons.category,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$label${isRequired ? ' *' : ''}',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: ElegantLightTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCategoryName ?? hint,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color:
                            selectedCategoryName != null
                                ? ElegantLightTheme.textPrimary
                                : ElegantLightTheme.textTertiary,
                        fontWeight:
                            selectedCategoryName != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(isMobile ? 3 : 4),
                decoration: BoxDecoration(
                  color: ElegantLightTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.arrow_drop_down,
                  color: ElegantLightTheme.primaryBlue,
                  size: isMobile ? 20 : 24,
                ),
              ),
            ],
          ),
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

// Agregamos SingleTickerProviderStateMixin para animaciones

class _CategorySelectorDialogState extends State<CategorySelectorDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchTerm = '';
  String? _selectedCategoryId;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;

    _animationController = AnimationController(
      duration: ElegantLightTheme.normalAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: ElegantLightTheme.elasticCurve,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadCategories();
    _setupSearchListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
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
        print(
          '✅ CategorySelectorDialog: Usando ${categories.length} categorías desde cache',
        );
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

        print(
          '✅ CategorySelectorDialog: ${updatedCategories.length} categorías cargadas desde API',
        );
      }

      // ✅ DEBUG: Imprimir categorías para verificar
      for (int i = 0; i < _categories.length; i++) {
        print('  Categoría $i: ${_categories[i].name} (${_categories[i].id})');
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
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: FuturisticContainer(
                padding: EdgeInsets.all(isMobile ? 20 : 24),
                hasGlow: true,
                child: Container(
                  width:
                      isMobile
                          ? MediaQuery.of(context).size.width * 0.95
                          : isTablet
                          ? MediaQuery.of(context).size.width * 0.85
                          : MediaQuery.of(context).size.width * 0.6,
                  constraints: BoxConstraints(
                    maxWidth: 700,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header con gradiente
                      _buildHeader(context),
                      SizedBox(height: isMobile ? 16 : 20),

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

                      SizedBox(height: isMobile ? 12 : 16),

                      // Lista de categorías
                      Flexible(child: _buildCategoriesList()),

                      SizedBox(height: isMobile ? 16 : 20),

                      // Acciones
                      _buildActions(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ElegantLightTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ElegantLightTheme.glowShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.category, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Seleccionar Categoría',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
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
          child: ElegantButton(
            text: 'Cancelar',
            icon: Icons.close,
            gradient: LinearGradient(
              colors: [Colors.grey.shade400, Colors.grey.shade600],
            ),
            height: 48,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Builder(
            builder: (context) {
              final isMobile = ResponsiveHelper.isMobile(context);
              return ElegantButton(
                text: 'Seleccionar',
                icon: isMobile ? null : Icons.check_circle_outline,
                gradient: ElegantLightTheme.primaryGradient,
                height: 48,
                onPressed:
                    _selectedCategoryId != null ? _confirmSelection : null,
              );
            },
          ),
        ),
      ],
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? ElegantLightTheme.primaryBlue
                              : ElegantLightTheme.textTertiary.withValues(
                                alpha: 0.2,
                              ),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _selectCategory(category),
                      borderRadius: BorderRadius.circular(12),
                      child: FuturisticContainer(
                        padding: const EdgeInsets.all(16),
                        gradient:
                            isSelected
                                ? LinearGradient(
                                  colors: [
                                    ElegantLightTheme.primaryBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    ElegantLightTheme.primaryBlueLight
                                        .withValues(alpha: 0.05),
                                  ],
                                )
                                : ElegantLightTheme.cardGradient,
                        child: Row(
                          children: [
                            // Icono de categoría
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? ElegantLightTheme.primaryGradient
                                        : LinearGradient(
                                          colors: [
                                            Colors.grey.shade300,
                                            Colors.grey.shade400,
                                          ],
                                        ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow:
                                    isSelected
                                        ? ElegantLightTheme.glowShadow
                                        : null,
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
                                              ? ElegantLightTheme.primaryBlue
                                              : ElegantLightTheme.textPrimary,
                                    ),
                                  ),
                                  if (category.description != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      category.description!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: ElegantLightTheme.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient:
                                              ElegantLightTheme.successGradient,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'ACTIVA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (category.productsCount != null)
                                        Text(
                                          '${category.productsCount} productos',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                ElegantLightTheme.textTertiary,
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: ElegantLightTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: ElegantLightTheme.glowShadow,
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
            ElegantButton(
              text: 'Crear Categoría',
              icon: Icons.add,
              gradient: ElegantLightTheme.successGradient,
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
