// // lib/features/categories/presentation/controllers/category_form_controller.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../app/core/usecases/usecase.dart';
// import '../../domain/entities/category.dart';
// import '../../domain/entities/category_tree.dart';
// import '../../domain/usecases/create_category_usecase.dart';
// import '../../domain/usecases/update_category_usecase.dart';
// import '../../domain/usecases/get_category_tree_usecase.dart';
// import '../../domain/usecases/get_category_by_id_usecase.dart';
// import '../controllers/categories_controller.dart';

// class CategoryFormController extends GetxController {
//   // Dependencies
//   final CreateCategoryUseCase _createCategoryUseCase;
//   final UpdateCategoryUseCase _updateCategoryUseCase;
//   final GetCategoryTreeUseCase _getCategoryTreeUseCase;
//   final GetCategoryByIdUseCase _getCategoryByIdUseCase;

//   CategoryFormController({
//     required CreateCategoryUseCase createCategoryUseCase,
//     required UpdateCategoryUseCase updateCategoryUseCase,
//     required GetCategoryTreeUseCase getCategoryTreeUseCase,
//     required GetCategoryByIdUseCase getCategoryByIdUseCase,
//   }) : _createCategoryUseCase = createCategoryUseCase,
//        _updateCategoryUseCase = updateCategoryUseCase,
//        _getCategoryTreeUseCase = getCategoryTreeUseCase,
//        _getCategoryByIdUseCase = getCategoryByIdUseCase;

//   // ==================== OBSERVABLES ====================

//   // Estados
//   final _isLoading = false.obs;
//   final _isLoadingParents = false.obs;
//   final _isEditMode = false.obs;
//   final _isLoadingCategory = false.obs;

//   // Datos
//   final Rxn<Category> _currentCategory = Rxn<Category>();
//   final _parentCategories = <CategoryTree>[].obs;
//   final Rxn<CategoryTree> _selectedParent = Rxn<CategoryTree>();

//   // Form controllers
//   final nameController = TextEditingController();
//   final descriptionController = TextEditingController();
//   final slugController = TextEditingController();
//   final imageController = TextEditingController();
//   final metaTitleController = TextEditingController();
//   final metaDescriptionController = TextEditingController();
//   final metaKeywordsController = TextEditingController();

//   // Form state
//   final formKey = GlobalKey<FormState>();
//   final _selectedStatus = CategoryStatus.active.obs;
//   final _sortOrder = 0.obs;
//   final _isSlugManuallyEdited = false.obs;

//   // ==================== GETTERS ====================

//   bool get isLoading => _isLoading.value;
//   bool get isLoadingParents => _isLoadingParents.value;
//   bool get isEditMode => _isEditMode.value;
//   bool get isLoadingCategory => _isLoadingCategory.value;

//   Category? get currentCategory => _currentCategory.value;
//   List<CategoryTree> get parentCategories => _parentCategories;
//   CategoryTree? get selectedParent => _selectedParent.value;

//   CategoryStatus get selectedStatus => _selectedStatus.value;
//   int get sortOrder => _sortOrder.value;
//   bool get isSlugManuallyEdited => _isSlugManuallyEdited.value;
//   bool get hasCategory => _currentCategory.value != null;

//   String get formTitle =>
//       _isEditMode.value ? 'Editar Categoría' : 'Nueva Categoría';
//   String get submitButtonText => _isEditMode.value ? 'Actualizar' : 'Crear';

//   // ==================== LIFECYCLE ====================

//   @override
//   void onInit() {
//     super.onInit();
//     _setupSlugGeneration();
//     loadParentCategories();

//     // Obtener categoryId desde los parámetros de ruta
//     final categoryId = Get.parameters['id'];
//     if (categoryId != null && categoryId.isNotEmpty) {
//       _initEditMode(categoryId);
//     }

//     // También verificar argumentos como fallback (para crear subcategoría)
//     final arguments = Get.arguments;
//     if (arguments != null && arguments is Map<String, dynamic>) {
//       final parentId = arguments['parentId'] as String?;
//       final parentName = arguments['parentName'] as String?;

//       if (parentId != null) {
//         // Buscar y seleccionar la categoría padre
//         _selectParentFromId(parentId);
//       }
//     }
//   }

//   @override
//   void onClose() {
//     nameController.dispose();
//     descriptionController.dispose();
//     slugController.dispose();
//     imageController.dispose();
//     metaTitleController.dispose();
//     metaDescriptionController.dispose();
//     metaKeywordsController.dispose();
//     super.onClose();
//   }

//   // ==================== PUBLIC METHODS ====================

//   /// Guardar categoría (crear o actualizar)
//   Future<void> saveCategory() async {
//     if (!formKey.currentState!.validate()) return;

//     _isLoading.value = true;

//     try {
//       if (_isEditMode.value) {
//         await _updateCategory();
//       } else {
//         await _createCategory();
//       }
//     } finally {
//       _isLoading.value = false;
//     }
//   }

//   /// Cargar categorías padre
//   Future<void> loadParentCategories() async {
//     _isLoadingParents.value = true;

//     try {
//       final result = await _getCategoryTreeUseCase(const NoParams());

//       result.fold(
//         (failure) {
//           _showError('Error al cargar categorías padre', failure.message);
//           _parentCategories.clear();
//         },
//         (categories) {
//           _parentCategories.value = categories;

//           // Si estamos en modo edición y hay una categoría padre, seleccionarla
//           if (_isEditMode.value && _currentCategory.value?.parentId != null) {
//             _selectParentFromId(_currentCategory.value!.parentId!);
//           }
//         },
//       );
//     } finally {
//       _isLoadingParents.value = false;
//     }
//   }

//   /// Cambiar estado seleccionado
//   void changeStatus(CategoryStatus status) {
//     _selectedStatus.value = status;
//   }

//   /// Cambiar categoría padre
//   void changeParent(CategoryTree? parent) {
//     _selectedParent.value = parent;
//   }

//   /// Cambiar orden
//   void changeSortOrder(int order) {
//     _sortOrder.value = order;
//   }

//   /// Generar slug automáticamente
//   void generateSlug() {
//     final name = nameController.text.trim();
//     if (name.isNotEmpty && !_isSlugManuallyEdited.value) {
//       final slug = _generateSlugFromName(name);
//       slugController.text = slug;
//     }
//   }

//   /// Marcar slug como editado manualmente
//   void markSlugAsManuallyEdited() {
//     _isSlugManuallyEdited.value = true;
//   }

//   /// Reiniciar formulario
//   void resetForm() {
//     formKey.currentState?.reset();
//     nameController.clear();
//     descriptionController.clear();
//     slugController.clear();
//     imageController.clear();
//     metaTitleController.clear();
//     metaDescriptionController.clear();
//     metaKeywordsController.clear();

//     _selectedStatus.value = CategoryStatus.active;
//     _selectedParent.value = null;
//     _sortOrder.value = 0;
//     _isSlugManuallyEdited.value = false;
//     _currentCategory.value = null;
//     _isEditMode.value = false;
//   }

//   /// Cancelar y volver
//   void cancel() {
//     Get.back();
//   }

//   // ==================== VALIDATION METHODS ====================

//   /// Validar nombre
//   String? validateName(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'El nombre es requerido';
//     }
//     if (value.trim().length < 2) {
//       return 'El nombre debe tener al menos 2 caracteres';
//     }
//     if (value.trim().length > 100) {
//       return 'El nombre no puede exceder 100 caracteres';
//     }
//     return null;
//   }

//   /// Validar slug
//   String? validateSlug(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'El slug es requerido';
//     }
//     if (value.trim().length < 2) {
//       return 'El slug debe tener al menos 2 caracteres';
//     }
//     if (value.trim().length > 50) {
//       return 'El slug no puede exceder 50 caracteres';
//     }

//     // Validar formato del slug
//     final slugRegex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
//     if (!slugRegex.hasMatch(value.trim())) {
//       return 'El slug debe contener solo letras minúsculas, números y guiones';
//     }

//     return null;
//   }

//   /// Validar descripción
//   String? validateDescription(String? value) {
//     if (value != null && value.trim().length > 1000) {
//       return 'La descripción no puede exceder 1000 caracteres';
//     }
//     return null;
//   }

//   /// Validar imagen URL
//   String? validateImageUrl(String? value) {
//     if (value != null && value.trim().isNotEmpty) {
//       final urlRegex = RegExp(
//         r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
//       );
//       if (!urlRegex.hasMatch(value.trim())) {
//         return 'Ingresa una URL válida';
//       }
//     }
//     return null;
//   }

//   // ==================== PRIVATE METHODS ====================

//   /// Configurar generación automática de slug
//   void _setupSlugGeneration() {
//     nameController.addListener(() {
//       if (!_isSlugManuallyEdited.value) {
//         generateSlug();
//       }
//     });
//   }

//   /// Inicializar modo edición
//   void _initEditMode(String categoryId) {
//     _isEditMode.value = true;
//     _loadCategoryForEdit(categoryId);
//   }

//   /// Cargar categoría para edición
//   Future<void> _loadCategoryForEdit(String categoryId) async {
//     _isLoadingCategory.value = true;

//     try {
//       final result = await _getCategoryByIdUseCase(
//         GetCategoryByIdParams(id: categoryId),
//       );

//       result.fold(
//         (failure) {
//           _showError('Error al cargar categoría', failure.message);
//           // Si falla cargar la categoría, volver al listado
//           Get.back();
//         },
//         (category) {
//           _populateFormWithCategory(category);
//         },
//       );
//     } finally {
//       _isLoadingCategory.value = false;
//     }
//   }

//   /// Poblar formulario con datos de categoría
//   void _populateFormWithCategory(Category category) {
//     _currentCategory.value = category;

//     // Llenar campos del formulario
//     nameController.text = category.name;
//     descriptionController.text = category.description ?? '';
//     slugController.text = category.slug;
//     imageController.text = category.image ?? '';
//     _selectedStatus.value = category.status;
//     _sortOrder.value = category.sortOrder;

//     // Buscar y seleccionar la categoría padre si existe
//     if (category.parentId != null) {
//       _selectParentFromId(category.parentId!);
//     }

//     _isSlugManuallyEdited.value = true;

//     print('✅ Categoría cargada para edición: ${category.name}');
//   }

//   /// Seleccionar padre por ID
//   void _selectParentFromId(String parentId) {
//     // Buscar en las categorías padre ya cargadas
//     final parent = _findParentById(parentId);
//     if (parent != null) {
//       _selectedParent.value = parent;
//     } else {
//       // Si no están cargadas aún, intentar cuando se carguen
//       ever(_parentCategories, (List<CategoryTree> categories) {
//         if (categories.isNotEmpty) {
//           final parent = _findParentById(parentId);
//           if (parent != null) {
//             _selectedParent.value = parent;
//           }
//         }
//       });
//     }
//   }

//   /// Buscar categoría padre por ID
//   CategoryTree? _findParentById(String parentId) {
//     for (final category in _parentCategories) {
//       if (category.id == parentId) {
//         return category;
//       }
//       // Buscar en hijos recursivamente
//       final found = _findInChildren(category, parentId);
//       if (found != null) return found;
//     }
//     return null;
//   }

//   /// Buscar en hijos recursivamente
//   CategoryTree? _findInChildren(CategoryTree parent, String targetId) {
//     if (parent.children != null) {
//       for (final child in parent.children!) {
//         if (child.id == targetId) {
//           return child;
//         }
//         final found = _findInChildren(child, targetId);
//         if (found != null) return found;
//       }
//     }
//     return null;
//   }

//   /// Crear nueva categoría
//   Future<void> _createCategory() async {
//     final result = await _createCategoryUseCase(
//       CreateCategoryParams(
//         name: nameController.text.trim(),
//         description:
//             descriptionController.text.trim().isEmpty
//                 ? null
//                 : descriptionController.text.trim(),
//         slug: slugController.text.trim(),
//         image:
//             imageController.text.trim().isEmpty
//                 ? null
//                 : imageController.text.trim(),
//         status: _selectedStatus.value,
//         sortOrder: _sortOrder.value,
//         parentId: _selectedParent.value?.id,
//       ),
//     );

//     result.fold(
//       (failure) {
//         _showError('Error al crear categoría', failure.message);
//       },
//       (category) {
//         _showSuccess('Categoría creada exitosamente');

//         // Refrescar la lista antes de navegar
//         _refreshCategoriesList();

//         // Pequeño delay para que se complete el refresh
//         Future.delayed(const Duration(milliseconds: 500), () {
//           Get.offAllNamed('/categories');
//         });
//       },
//     );
//   }

//   /// Actualizar categoría existente
//   Future<void> _updateCategory() async {
//     if (_currentCategory.value == null) {
//       _showError('Error', 'No hay categoría para actualizar');
//       return;
//     }

//     final result = await _updateCategoryUseCase(
//       UpdateCategoryParams(
//         id: _currentCategory.value!.id,
//         name: nameController.text.trim(),
//         description:
//             descriptionController.text.trim().isEmpty
//                 ? null
//                 : descriptionController.text.trim(),
//         slug: slugController.text.trim(),
//         image:
//             imageController.text.trim().isEmpty
//                 ? null
//                 : imageController.text.trim(),
//         status: _selectedStatus.value,
//         sortOrder: _sortOrder.value,
//         parentId: _selectedParent.value?.id,
//       ),
//     );

//     result.fold(
//       (failure) {
//         _showError('Error al actualizar categoría', failure.message);
//       },
//       (category) {
//         _showSuccess('Categoría actualizada exitosamente');

//         // Refrescar la lista antes de navegar
//         _refreshCategoriesList();

//         // Pequeño delay para que se complete el refresh
//         Future.delayed(const Duration(milliseconds: 500), () {
//           Get.offAllNamed('/categories');
//         });
//       },
//     );
//   }

//   /// Refrescar la lista de categorías
//   void _refreshCategoriesList() {
//     try {
//       // Buscar el CategoriesController si existe
//       if (Get.isRegistered<CategoriesController>()) {
//         final categoriesController = Get.find<CategoriesController>();
//         categoriesController.refreshCategories();
//         print('✅ Lista de categorías refrescada exitosamente');
//       }
//     } catch (e) {
//       print('⚠️ No se pudo refrescar la lista de categorías: $e');
//     }
//   }

//   /// Generar slug desde nombre
//   String _generateSlugFromName(String name) {
//     return name
//         .toLowerCase()
//         .trim()
//         .replaceAll(RegExp(r'[áàäâ]'), 'a')
//         .replaceAll(RegExp(r'[éèëê]'), 'e')
//         .replaceAll(RegExp(r'[íìïî]'), 'i')
//         .replaceAll(RegExp(r'[óòöô]'), 'o')
//         .replaceAll(RegExp(r'[úùüû]'), 'u')
//         .replaceAll('ñ', 'n')
//         .replaceAll('ç', 'c')
//         .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
//         .replaceAll(RegExp(r'\s+'), '-')
//         .replaceAll(RegExp(r'-+'), '-')
//         .replaceAll(RegExp(r'^-|-$'), '');
//   }

//   /// Mostrar mensaje de error
//   void _showError(String title, String message) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.red.shade100,
//       colorText: Colors.red.shade800,
//       icon: const Icon(Icons.error, color: Colors.red),
//       duration: const Duration(seconds: 4),
//     );
//   }

//   /// Mostrar mensaje de éxito
//   void _showSuccess(String message) {
//     Get.snackbar(
//       'Éxito',
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: Colors.green.shade100,
//       colorText: Colors.green.shade800,
//       icon: const Icon(Icons.check_circle, color: Colors.green),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

// lib/features/categories/presentation/controllers/category_form_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/usecases/usecase.dart';
import '../../../../app/shared/widgets/safe_text_editing_controller.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';
import '../../domain/usecases/get_category_tree_usecase.dart';
import '../../domain/usecases/get_category_by_id_usecase.dart';
import '../controllers/categories_controller.dart';

class CategoryFormController extends GetxController {
  // Dependencies
  final CreateCategoryUseCase _createCategoryUseCase;
  final UpdateCategoryUseCase _updateCategoryUseCase;
  final GetCategoryTreeUseCase _getCategoryTreeUseCase;
  final GetCategoryByIdUseCase _getCategoryByIdUseCase;

  CategoryFormController({
    required CreateCategoryUseCase createCategoryUseCase,
    required UpdateCategoryUseCase updateCategoryUseCase,
    required GetCategoryTreeUseCase getCategoryTreeUseCase,
    required GetCategoryByIdUseCase getCategoryByIdUseCase,
  }) : _createCategoryUseCase = createCategoryUseCase,
       _updateCategoryUseCase = updateCategoryUseCase,
       _getCategoryTreeUseCase = getCategoryTreeUseCase,
       _getCategoryByIdUseCase = getCategoryByIdUseCase;

  // ==================== OBSERVABLES ====================

  // Estados
  final _isLoading = false.obs;
  final _isLoadingParents = false.obs;
  final _isEditMode = false.obs;
  final _isLoadingCategory = false.obs;

  // Datos
  final Rxn<Category> _currentCategory = Rxn<Category>(null); // ✅ EXPLÍCITO
  final _parentCategories = <CategoryTree>[].obs;
  final Rxn<CategoryTree> _selectedParent = Rxn<CategoryTree>(
    null,
  ); // ✅ EXPLÍCITO

  // Form controllers - Using SafeTextEditingController to prevent disposal errors
  final nameController = SafeTextEditingController(debugLabel: 'CategoryFormName');
  final descriptionController = SafeTextEditingController(debugLabel: 'CategoryFormDescription');
  final slugController = SafeTextEditingController(debugLabel: 'CategoryFormSlug');
  final imageController = SafeTextEditingController(debugLabel: 'CategoryFormImage');
  final metaTitleController = SafeTextEditingController(debugLabel: 'CategoryFormMetaTitle');
  final metaDescriptionController = SafeTextEditingController(debugLabel: 'CategoryFormMetaDescription');
  final metaKeywordsController = SafeTextEditingController(debugLabel: 'CategoryFormMetaKeywords');

  // Form state
  final formKey = GlobalKey<FormState>();
  final _selectedStatus = CategoryStatus.active.obs;
  final _sortOrder = 0.obs;
  final _isSlugManuallyEdited = false.obs;

  // ==================== GETTERS ====================

  bool get isLoading => _isLoading.value;
  bool get isLoadingParents => _isLoadingParents.value;
  bool get isEditMode => _isEditMode.value;
  bool get isLoadingCategory => _isLoadingCategory.value;

  Category? get currentCategory => _currentCategory.value;
  List<CategoryTree> get parentCategories => _parentCategories;
  CategoryTree? get selectedParent => _selectedParent.value;

  // ✅ NUEVO GETTER CRÍTICO: Para el dropdown
  String? get selectedParentId => _selectedParent.value?.id;

  CategoryStatus get selectedStatus => _selectedStatus.value;
  int get sortOrder => _sortOrder.value;
  bool get isSlugManuallyEdited => _isSlugManuallyEdited.value;
  bool get hasCategory => _currentCategory.value != null;

  String get formTitle =>
      _isEditMode.value ? 'Editar Categoría' : 'Nueva Categoría';
  String get submitButtonText => _isEditMode.value ? 'Actualizar' : 'Crear';

  // ==================== LIFECYCLE ====================

  @override
  void onInit() {
    super.onInit();
    print('🚀 CategoryFormController onInit started');

    _setupSlugGeneration();

    // ✅ CORRECCIÓN: Cargar categorías padre PRIMERO
    loadParentCategories();

    // Obtener categoryId desde los parámetros de ruta
    final categoryId = Get.parameters['id'];
    print('📝 Category ID from params: $categoryId');

    if (categoryId != null && categoryId.isNotEmpty) {
      print('🔧 Entering edit mode for: $categoryId');
      _initEditMode(categoryId);
    }

    // También verificar argumentos como fallback (para crear subcategoría)
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final parentId = arguments['parentId'] as String?;
      print('👨‍👩‍👧‍👦 Parent ID from arguments: $parentId');

      if (parentId != null) {
        // ✅ CORRECCIÓN: Esperar a que se carguen las categorías padre
        ever(_parentCategories, (List<CategoryTree> categories) {
          if (categories.isNotEmpty && _selectedParent.value == null) {
            print('🔍 Attempting to select parent from arguments: $parentId');
            _selectParentFromId(parentId);
          }
        });
      }
    }

    print('✅ CategoryFormController onInit completed');

    // ✅ AGREGAR AL FINAL:
    // Debugging después de un pequeño delay
    Future.delayed(const Duration(seconds: 2), () {
      printDebugInfo();
      debugDropdownState();
    });
  }

  @override
  void onClose() {
    // SafeTextEditingController handles safe disposal automatically
    nameController.dispose();
    descriptionController.dispose();
    slugController.dispose();
    imageController.dispose();
    metaTitleController.dispose();
    metaDescriptionController.dispose();
    metaKeywordsController.dispose();
    super.onClose();
    print('🗑️ CategoryFormController disposed safely');
  }

  // ==================== PUBLIC METHODS ====================

  /// Guardar categoría (crear o actualizar)
  Future<void> saveCategory() async {
    print('🚀 CategoryFormController: Iniciando saveCategory()');
    
    // Log tenant information for debugging
    await _logTenantInfo();
    
    // Validar campos manualmente si FormKey no está disponible
    if (!_validateFieldsManually()) {
      print('❌ Validación manual falló');
      return;
    }
    
    print('✅ Validación exitosa, procediendo con la creación');
    
    // Generar slug automáticamente si está vacío
    if (slugController.text.trim().isEmpty) {
      final generatedSlug = _generateSlugFromName(nameController.text.trim());
      slugController.text = generatedSlug;
      print('🔧 Slug generado automáticamente: $generatedSlug');
    }

    _isLoading.value = true;

    try {
      if (_isEditMode.value) {
        await _updateCategory();
      } else {
        await _createCategory();
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Cargar categorías padre
  Future<void> loadParentCategories() async {
    print('📂 Loading parent categories...');
    _isLoadingParents.value = true;

    try {
      final result = await _getCategoryTreeUseCase(const NoParams());

      result.fold(
        (failure) {
          print('❌ Error loading parent categories: ${failure.message}');
          _showError('Error al cargar categorías padre', failure.message);
          _parentCategories.clear();
        },
        (categories) {
          print('✅ Parent categories loaded: ${categories.length}');
          _parentCategories.value = categories;

          // Si estamos en modo edición y hay una categoría padre, seleccionarla
          if (_isEditMode.value && _currentCategory.value?.parentId != null) {
            print(
              '🔗 Selecting parent for edit mode: ${_currentCategory.value!.parentId}',
            );
            _selectParentFromId(_currentCategory.value!.parentId!);
          }
        },
      );
    } finally {
      _isLoadingParents.value = false;
    }
  }

  /// Cambiar estado seleccionado
  void changeStatus(CategoryStatus status) {
    _selectedStatus.value = status;
    print('🔄 Status changed to: ${status.name}');
  }

  /// ✅ CORRECCIÓN: Cambiar categoría padre con logs
  void changeParent(CategoryTree? parent) {
    _selectedParent.value = parent;
    print(
      '🔄 Parent changed to: ${parent?.name ?? "null"} (ID: ${parent?.id ?? "null"})',
    );
  }

  /// Cambiar orden
  void changeSortOrder(int order) {
    _sortOrder.value = order;
    print('🔄 Sort order changed to: $order');
  }

  /// Generar slug automáticamente
  void generateSlug() {
    final name = nameController.text.trim();
    if (name.isNotEmpty && !_isSlugManuallyEdited.value) {
      final slug = _generateSlugFromName(name);
      slugController.text = slug;
    }
  }

  /// Marcar slug como editado manualmente
  void markSlugAsManuallyEdited() {
    _isSlugManuallyEdited.value = true;
  }

  /// Reiniciar formulario
  void resetForm() {
    formKey.currentState?.reset();
    nameController.clear();
    descriptionController.clear();
    slugController.clear();
    imageController.clear();
    metaTitleController.clear();
    metaDescriptionController.clear();
    metaKeywordsController.clear();

    _selectedStatus.value = CategoryStatus.active;
    _selectedParent.value = null;
    _sortOrder.value = 0;
    _isSlugManuallyEdited.value = false;
    _currentCategory.value = null;
    _isEditMode.value = false;
  }

  /// Cancelar y volver
  void cancel() {
    Get.back();
  }

  // ==================== VALIDATION METHODS ====================

  /// Validar nombre
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (value.trim().length > 100) {
      return 'El nombre no puede exceder 100 caracteres';
    }
    return null;
  }

  /// Validar slug
  String? validateSlug(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El slug es requerido';
    }
    if (value.trim().length < 2) {
      return 'El slug debe tener al menos 2 caracteres';
    }
    if (value.trim().length > 50) {
      return 'El slug no puede exceder 50 caracteres';
    }

    // Validar formato del slug
    final slugRegex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
    if (!slugRegex.hasMatch(value.trim())) {
      return 'El slug debe contener solo letras minúsculas, números y guiones';
    }

    return null;
  }

  /// Validar descripción
  String? validateDescription(String? value) {
    if (value != null && value.trim().length > 1000) {
      return 'La descripción no puede exceder 1000 caracteres';
    }
    return null;
  }

  /// Validar imagen URL
  String? validateImageUrl(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      );
      if (!urlRegex.hasMatch(value.trim())) {
        return 'Ingresa una URL válida';
      }
    }
    return null;
  }

  // ==================== PRIVATE METHODS ====================

  /// Configurar generación automática de slug
  void _setupSlugGeneration() {
    nameController.addListener(() {
      if (!_isSlugManuallyEdited.value) {
        generateSlug();
      }
    });
  }

  /// Inicializar modo edición
  void _initEditMode(String categoryId) {
    _isEditMode.value = true;
    _loadCategoryForEdit(categoryId);
  }

  /// Cargar categoría para edición
  Future<void> _loadCategoryForEdit(String categoryId) async {
    print('📖 Loading category for edit: $categoryId');
    _isLoadingCategory.value = true;

    try {
      final result = await _getCategoryByIdUseCase(
        GetCategoryByIdParams(id: categoryId),
      );

      result.fold(
        (failure) {
          print('❌ Error loading category: ${failure.message}');
          _showError('Error al cargar categoría', failure.message);
          // Si falla cargar la categoría, volver al listado
          Get.back();
        },
        (category) {
          print('✅ Category loaded: ${category.name}');
          _populateFormWithCategory(category);
        },
      );
    } finally {
      _isLoadingCategory.value = false;
    }
  }

  /// ✅ CORRECCIÓN: Poblar formulario con datos de categoría
  void _populateFormWithCategory(Category category) {
    print('🏗️ Populating form with category: ${category.name}');
    _currentCategory.value = category;

    // Llenar campos del formulario
    nameController.text = category.name;
    descriptionController.text = category.description ?? '';
    slugController.text = category.slug;
    imageController.text = category.image ?? '';
    _selectedStatus.value = category.status;
    _sortOrder.value = category.sortOrder;

    // ✅ CORRECCIÓN: Manejar parent de forma más robusta
    if (category.parentId != null) {
      print('🔗 Category has parent ID: ${category.parentId}');
      _selectParentFromId(category.parentId!);
    } else {
      print('🚫 Category has no parent');
      _selectedParent.value = null;
    }

    _isSlugManuallyEdited.value = true;
    print('✅ Form populated successfully');
  }

  /// ✅ CORRECCIÓN: Seleccionar padre por ID con mejor manejo
  void _selectParentFromId(String parentId) {
    print('🔍 Searching for parent with ID: $parentId');

    // Buscar en las categorías padre ya cargadas
    final parent = _findParentById(parentId);
    if (parent != null) {
      print('✅ Parent found immediately: ${parent.name}');
      _selectedParent.value = parent;
    } else {
      print('⏳ Parent not found, waiting for categories to load...');

      // Si no están cargadas aún, intentar cuando se carguen
      ever(_parentCategories, (List<CategoryTree> categories) {
        if (categories.isNotEmpty && _selectedParent.value == null) {
          print('🔄 Retrying parent search after categories loaded...');
          final foundParent = _findParentById(parentId);
          if (foundParent != null) {
            print('✅ Parent found after reload: ${foundParent.name}');
            _selectedParent.value = foundParent;
          } else {
            print('❌ Parent still not found: $parentId');
          }
        }
      });
    }
  }

  /// Buscar categoría padre por ID
  CategoryTree? _findParentById(String parentId) {
    for (final category in _parentCategories) {
      if (category.id == parentId) {
        return category;
      }
      // Buscar en hijos recursivamente
      final found = _findInChildren(category, parentId);
      if (found != null) return found;
    }
    return null;
  }

  /// Buscar en hijos recursivamente
  CategoryTree? _findInChildren(CategoryTree parent, String targetId) {
    if (parent.children != null) {
      for (final child in parent.children!) {
        if (child.id == targetId) {
          return child;
        }
        final found = _findInChildren(child, targetId);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Crear nueva categoría
  Future<void> _createCategory() async {
    print('🆕 CategoryFormController: Creating new category...');
    
    final params = CreateCategoryParams(
      name: nameController.text.trim(),
      description:
          descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
      slug: slugController.text.trim(),
      image:
          imageController.text.trim().isEmpty
              ? null
              : imageController.text.trim(),
      status: _selectedStatus.value,
      sortOrder: _sortOrder.value,
      parentId: _selectedParent.value?.id,
    );
    
    print('📋 CategoryFormController: Request parameters:');
    print('   🏷️  Name: ${params.name}');
    print('   📝 Description: ${params.description}');
    print('   🔗 Slug: ${params.slug}');
    print('   🖼️  Image: ${params.image}');
    print('   📊 Status: ${params.status?.name}');
    print('   🔢 Sort Order: ${params.sortOrder}');
    print('   👨‍👩‍👧‍👦 Parent ID: ${params.parentId}');
    
    final result = await _createCategoryUseCase(params);

    result.fold(
      (failure) {
        print('❌ CategoryFormController: Error creating category');
        print('   📄 Failure type: ${failure.runtimeType}');
        print('   📄 Failure message: ${failure.message}');
        _showError('Error al crear categoría', failure.message);
      },
      (category) {
        print('✅ CategoryFormController: Category created successfully');
        print('   🆔 Category ID: ${category.id}');
        print('   🏷️  Category Name: ${category.name}');
        print('   🔗 Category Slug: ${category.slug}');
        print('   📊 Category Status: ${category.status.name}');
        _showSuccess('Categoría creada exitosamente');

        // Refrescar la lista antes de navegar
        _refreshCategoriesList();

        // Pequeño delay para que se complete el refresh
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAllNamed('/categories');
        });
      },
    );
  }

  /// Actualizar categoría existente
  Future<void> _updateCategory() async {
    if (_currentCategory.value == null) {
      _showError('Error', 'No hay categoría para actualizar');
      return;
    }

    print('🔄 Updating category: ${_currentCategory.value!.name}');
    final result = await _updateCategoryUseCase(
      UpdateCategoryParams(
        id: _currentCategory.value!.id,
        name: nameController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        slug: slugController.text.trim(),
        image:
            imageController.text.trim().isEmpty
                ? null
                : imageController.text.trim(),
        status: _selectedStatus.value,
        sortOrder: _sortOrder.value,
        parentId: _selectedParent.value?.id,
      ),
    );

    result.fold(
      (failure) {
        print('❌ Error updating category: ${failure.message}');
        _showError('Error al actualizar categoría', failure.message);
      },
      (category) {
        print('✅ Category updated successfully: ${category.name}');
        _showSuccess('Categoría actualizada exitosamente');

        // Refrescar la lista antes de navegar
        _refreshCategoriesList();

        // Pequeño delay para que se complete el refresh
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.offAllNamed('/categories');
        });
      },
    );
  }

  /// Refrescar la lista de categorías
  void _refreshCategoriesList() {
    try {
      // Buscar el CategoriesController si existe
      if (Get.isRegistered<CategoriesController>()) {
        final categoriesController = Get.find<CategoriesController>();
        categoriesController.refreshCategories();
        print('✅ Lista de categorías refrescada exitosamente');
      }
    } catch (e) {
      print('⚠️ No se pudo refrescar la lista de categorías: $e');
    }
  }

  /// Generar slug desde nombre
  String _generateSlugFromName(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
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

  /// Mostrar mensaje de éxito
  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }

  // ==================== VALIDATION METHODS ====================

  /// Validar campos manualmente (sin depender del FormKey)
  bool _validateFieldsManually() {
    List<String> errors = [];
    
    // Validar nombre (requerido)
    if (nameController.text.trim().isEmpty) {
      errors.add('El nombre es requerido');
    } else if (nameController.text.trim().length < 2) {
      errors.add('El nombre debe tener al menos 2 caracteres');
    }
    
    // Validar slug (se genera automáticamente, pero verificar)
    if (slugController.text.trim().isEmpty) {
      errors.add('El slug es requerido');
    }
    
    // Si hay errores, mostrarlos
    if (errors.isNotEmpty) {
      _showError('Validación', errors.join('\n'));
      return false;
    }
    
    return true;
  }

  // ==================== DEBUGGING METHODS ====================

  /// Obtener información de estado para debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'isLoading': _isLoading.value,
      'isLoadingParents': _isLoadingParents.value,
      'isEditMode': _isEditMode.value,
      'isLoadingCategory': _isLoadingCategory.value,
      'hasCurrentCategory': _currentCategory.value != null,
      'currentCategoryId': _currentCategory.value?.id,
      'currentCategoryName': _currentCategory.value?.name,
      'parentCategoriesCount': _parentCategories.length,
      'selectedParent': _selectedParent.value?.name,
      'selectedParentId': _selectedParent.value?.id,
      'selectedStatus': _selectedStatus.value.name,
      'sortOrder': _sortOrder.value,
    };
  }

  /// Imprimir información de debugging
  void printDebugInfo() {
    final info = getDebugInfo();
    print('🐛 CategoryFormController Debug Info:');
    info.forEach((key, value) {
      print('   $key: $value');
    });
  }

  /// Verificar estado del dropdown
  void debugDropdownState() {
    print('📋 DROPDOWN DEBUG STATE:');
    print('   isLoadingParents: ${_isLoadingParents.value}');
    print('   parentCategories.length: ${_parentCategories.length}');
    print('   selectedParent: ${_selectedParent.value?.name ?? "null"}');
    print('   selectedParentId: ${_selectedParent.value?.id ?? "null"}');
    print('   currentCategory: ${_currentCategory.value?.name ?? "null"}');

    if (_parentCategories.isNotEmpty) {
      print('   Available parents:');
      for (final cat in _parentCategories) {
        print('     - ${cat.name} (${cat.id})');
      }
    }
  }

  /// Log tenant information for debugging
  Future<void> _logTenantInfo() async {
    try {
      final secureStorage = Get.find<SecureStorageService>();
      final tenantSlug = await secureStorage.getTenantSlug();
      final userData = await secureStorage.getUserData();
      
      print('🏢 ==================== TENANT DEBUG INFO ====================');
      print('🔍 Current tenant slug: $tenantSlug');
      print('👤 User data available: ${userData != null}');
      if (userData != null) {
        print('   📧 User email: ${userData['email']}');
        print('   🆔 User ID: ${userData['id']}');
      }
      print('🏢 ==================== END TENANT DEBUG INFO ====================');
    } catch (e) {
      print('❌ Error getting tenant info: $e');
    }
  }
}
