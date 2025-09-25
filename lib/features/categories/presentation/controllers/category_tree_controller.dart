// lib/features/categories/presentation/controllers/category_tree_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../../app/shared/widgets/safe_text_editing_controller.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/usecases/get_category_tree_usecase.dart';

class CategoryTreeController extends GetxController {
  // Dependencies
  final GetCategoryTreeUseCase _getCategoryTreeUseCase;

  CategoryTreeController({
    required GetCategoryTreeUseCase getCategoryTreeUseCase,
  }) : _getCategoryTreeUseCase = getCategoryTreeUseCase;

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isRefreshing = false.obs;

  // Datos
  final _categoryTree = <CategoryTree>[].obs;
  final _expandedNodes = <String>{}.obs;
  final _selectedNode = Rxn<CategoryTree>();

  // Filtros
  final _searchTerm = ''.obs;
  final _filteredTree = <CategoryTree>[].obs;

  // UI Controllers - Using SafeTextEditingController to prevent disposal errors
  final searchController = SafeTextEditingController(debugLabel: 'CategoryTreeSearch');

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;

  List<CategoryTree> get categoryTree => _categoryTree;
  List<CategoryTree> get filteredTree => _filteredTree;
  Set<String> get expandedNodes => _expandedNodes;
  CategoryTree? get selectedNode => _selectedNode.value;

  String get searchTerm => _searchTerm.value;
  bool get hasCategories => _categoryTree.isNotEmpty;
  bool get isSearchMode => _searchTerm.value.isNotEmpty;

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    loadCategoryTree();
    _setupSearchListener();
  }

  @override
  void onClose() {
    print('🔧 CategoryTreeController: Iniciando dispose...');
    
    // SafeTextEditingController handles safe disposal automatically
    if (!searchController.isDisposed) {
      searchController.dispose();
      print('✅ CategoryTreeController: searchController disposed');
    } else {
      print('⚠️ CategoryTreeController: searchController ya estaba disposed');
    }
    
    super.onClose();
    print('✅ CategoryTreeController: Dispose completado');
  }

  // ==================== PUBLIC METHODS ====================

  /// Cargar árbol de categorías
  Future<void> loadCategoryTree({bool showLoading = true}) async {
    if (showLoading) _isLoading.value = true;

    try {
      final result = await _getCategoryTreeUseCase(const NoParams());

      result.fold(
        (failure) {
          _showError('Error al cargar árbol de categorías', failure.message);
          _categoryTree.clear();
          _filteredTree.clear();
        },
        (tree) {
          _categoryTree.value = tree;
          _applySearchFilter();
        },
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Refrescar árbol
  Future<void> refreshTree() async {
    _isRefreshing.value = true;
    await loadCategoryTree(showLoading: false);
    _isRefreshing.value = false;
  }

  /// Expandir/colapsar nodo
  void toggleNodeExpansion(String nodeId) {
    if (_expandedNodes.contains(nodeId)) {
      _expandedNodes.remove(nodeId);
    } else {
      _expandedNodes.add(nodeId);
    }
  }

  /// Expandir nodo
  void expandNode(String nodeId) {
    _expandedNodes.add(nodeId);
  }

  /// Colapsar nodo
  void collapseNode(String nodeId) {
    _expandedNodes.remove(nodeId);
  }

  /// Expandir todos los nodos
  void expandAll() {
    _expandedNodes.clear();
    _addAllNodeIds(_categoryTree);
  }

  /// Colapsar todos los nodos
  void collapseAll() {
    _expandedNodes.clear();
  }

  /// Seleccionar nodo
  void selectNode(CategoryTree? node) {
    _selectedNode.value = node;
  }

  /// Verificar si un nodo está expandido
  bool isNodeExpanded(String nodeId) {
    return _expandedNodes.contains(nodeId);
  }

  /// Verificar si un nodo está seleccionado
  bool isNodeSelected(String nodeId) {
    return _selectedNode.value?.id == nodeId;
  }

  /// Buscar en el árbol
  void searchInTree(String query) {
    _searchTerm.value = query.trim();
    _applySearchFilter();
  }

  /// Limpiar búsqueda
  void clearSearch() {
    _searchTerm.value = '';
    searchController.clear();
    _applySearchFilter();
  }

  /// Encontrar categoría por ID
  CategoryTree? findCategoryById(String id) {
    return _findCategoryInTree(_categoryTree, id);
  }

  /// Obtener ruta completa de una categoría
  List<CategoryTree> getCategoryPath(String categoryId) {
    final path = <CategoryTree>[];
    _buildCategoryPath(_categoryTree, categoryId, path);
    return path.reversed.toList();
  }

  /// Expandir ruta hacia una categoría específica
  void expandPathToCategory(String categoryId) {
    final path = getCategoryPath(categoryId);
    for (final category in path) {
      expandNode(category.id);
    }
  }

  // ==================== UI HELPERS ====================

  /// Ir a crear subcategoría
  void createSubcategory(CategoryTree parent) {
    Get.toNamed(
      '/categories/create',
      arguments: {'parentId': parent.id, 'parentName': parent.name},
    );
  }

  /// Ir a editar categoría
  void editCategory(CategoryTree category) {
    Get.toNamed('/categories/edit/${category.id}');
  }

  /// Mostrar detalles de categoría
  void showCategoryDetails(CategoryTree category) {
    Get.toNamed('/categories/detail/${category.id}');
  }

  /// Mostrar menú contextual
  void showContextMenu(CategoryTree category, Offset position) {
    // TODO: Implementar menú contextual con opciones
    // - Editar
    // - Crear subcategoría
    // - Eliminar
    // - Ver productos
  }

  // ==================== PRIVATE METHODS ====================

  /// Configurar listener de búsqueda
  void _setupSearchListener() {
    searchController.addListener(() {
      searchInTree(searchController.text);
    });
  }

  /// Aplicar filtro de búsqueda
  void _applySearchFilter() {
    if (_searchTerm.value.isEmpty) {
      _filteredTree.value = _categoryTree;
    } else {
      _filteredTree.value = _filterTree(
        _categoryTree,
        _searchTerm.value.toLowerCase(),
      );
      // Expandir nodos que contienen resultados
      _expandNodesWithResults();
    }
  }

  /// Filtrar árbol por término de búsqueda
  List<CategoryTree> _filterTree(List<CategoryTree> tree, String searchTerm) {
    final filtered = <CategoryTree>[];

    for (final category in tree) {
      final matchesSearch = category.name.toLowerCase().contains(searchTerm);
      final filteredChildren =
          category.children != null
              ? _filterTree(category.children!, searchTerm)
              : <CategoryTree>[];

      if (matchesSearch || filteredChildren.isNotEmpty) {
        // Crear una copia con hijos filtrados
        final filteredCategory = CategoryTree(
          id: category.id,
          name: category.name,
          slug: category.slug,
          image: category.image,
          sortOrder: category.sortOrder,
          children:
              filteredChildren.isNotEmpty
                  ? filteredChildren
                  : category.children,
          productsCount: category.productsCount,
          level: category.level,
          hasChildren: category.hasChildren,
        );
        filtered.add(filteredCategory);
      }
    }

    return filtered;
  }

  /// Expandir nodos que contienen resultados de búsqueda
  void _expandNodesWithResults() {
    _expandNodesRecursively(_filteredTree);
  }

  /// Expandir nodos recursivamente
  void _expandNodesRecursively(List<CategoryTree> tree) {
    for (final category in tree) {
      if (category.hasChildren) {
        expandNode(category.id);
        if (category.children != null) {
          _expandNodesRecursively(category.children!);
        }
      }
    }
  }

  /// Agregar todos los IDs de nodos para expansión completa
  void _addAllNodeIds(List<CategoryTree> tree) {
    for (final category in tree) {
      if (category.hasChildren) {
        _expandedNodes.add(category.id);
        if (category.children != null) {
          _addAllNodeIds(category.children!);
        }
      }
    }
  }

  /// Encontrar categoría en el árbol
  CategoryTree? _findCategoryInTree(List<CategoryTree> tree, String id) {
    for (final category in tree) {
      if (category.id == id) {
        return category;
      }
      if (category.children != null) {
        final found = _findCategoryInTree(category.children!, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Construir ruta de categoría
  bool _buildCategoryPath(
    List<CategoryTree> tree,
    String targetId,
    List<CategoryTree> path,
  ) {
    for (final category in tree) {
      path.add(category);

      if (category.id == targetId) {
        return true;
      }

      if (category.children != null) {
        if (_buildCategoryPath(category.children!, targetId, path)) {
          return true;
        }
      }

      path.removeLast();
    }
    return false;
  }

  /// Mostrar mensaje de error
  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }
}
