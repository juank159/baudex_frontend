import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_price.dart';
import '../../domain/entities/tax_enums.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/create_product_usecase.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/get_categories_usecase.dart';
import '../../../inventory/domain/usecases/create_inventory_movement_usecase.dart';
import '../../../inventory/domain/entities/inventory_movement.dart';
import '../../../inventory/domain/repositories/inventory_repository.dart';
import '../../../../app/core/theme/elegant_light_theme.dart';
import '../../../../app/shared/widgets/subscription_error_dialog.dart';
import '../../../inventory/data/datasources/inventory_local_datasource_isar.dart';
import '../../../subscriptions/presentation/controllers/subscription_controller.dart';

const String _draftStorageKey = 'initial_inventory_draft';

class InitialInventoryRow {
  final TextEditingController nameController;
  final TextEditingController barcodeController;
  final TextEditingController costPriceController;
  final TextEditingController sellingPriceController;
  final TextEditingController stockController;
  final TextEditingController minStockController;

  String? categoryId;
  String? categoryName;
  String? errorMessage;
  bool isProcessed;
  bool isSuccess;
  bool isExpanded;

  InitialInventoryRow({
    TextEditingController? nameController,
    TextEditingController? barcodeController,
    TextEditingController? costPriceController,
    TextEditingController? sellingPriceController,
    TextEditingController? stockController,
    TextEditingController? minStockController,
    this.categoryId,
    this.categoryName,
    this.errorMessage,
    this.isProcessed = false,
    this.isSuccess = false,
    this.isExpanded = false,
  })  : nameController = nameController ?? TextEditingController(),
        barcodeController = barcodeController ?? TextEditingController(),
        costPriceController = costPriceController ?? TextEditingController(),
        sellingPriceController = sellingPriceController ?? TextEditingController(),
        stockController = stockController ?? TextEditingController(),
        minStockController = minStockController ?? TextEditingController();

  void dispose() {
    nameController.dispose();
    barcodeController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    stockController.dispose();
    minStockController.dispose();
  }

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      stockController.text.trim().isEmpty &&
      costPriceController.text.trim().isEmpty &&
      sellingPriceController.text.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'name': nameController.text,
        'barcode': barcodeController.text,
        'costPrice': costPriceController.text,
        'sellingPrice': sellingPriceController.text,
        'stock': stockController.text,
        'minStock': minStockController.text,
        'categoryId': categoryId,
        'categoryName': categoryName,
      };

  factory InitialInventoryRow.fromJson(Map<String, dynamic> json) {
    return InitialInventoryRow(
      nameController: TextEditingController(text: json['name'] ?? ''),
      barcodeController: TextEditingController(text: json['barcode'] ?? ''),
      costPriceController: TextEditingController(text: json['costPrice'] ?? ''),
      sellingPriceController: TextEditingController(text: json['sellingPrice'] ?? ''),
      stockController: TextEditingController(text: json['stock'] ?? ''),
      minStockController: TextEditingController(text: json['minStock'] ?? ''),
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
    );
  }
}

class InitialInventoryController extends GetxController {
  final CreateProductUseCase _createProductUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final CreateInventoryMovementUseCase _createMovementUseCase;
  final SecureStorageService _storage = SecureStorageService();

  InitialInventoryController({
    required CreateProductUseCase createProductUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required CreateInventoryMovementUseCase createMovementUseCase,
  })  : _createProductUseCase = createProductUseCase,
        _getCategoriesUseCase = getCategoriesUseCase,
        _createMovementUseCase = createMovementUseCase;

  final rows = <InitialInventoryRow>[].obs;
  final isSubmitting = false.obs;
  final currentProcessingIndex = (-1).obs;
  final successCount = 0.obs;
  final failedCount = 0.obs;
  final globalCategoryId = Rxn<String>();
  final globalCategoryName = Rxn<String>();
  final useGlobalCategory = true.obs;
  final availableCategories = <Category>[].obs;
  final isLoadingCategories = false.obs;
  final hasDraft = false.obs;
  final draftRowCount = 0.obs;

  // ============================================================================
  // BÚSQUEDA Y DETECCIÓN DE DUPLICADOS (en tiempo real)
  // ============================================================================

  /// Texto del buscador — filtra filas por nombre o código de barras
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  /// Índices de filas duplicadas (segunda aparición en adelante). Se detecta
  /// por nombre normalizado o por código de barras. Se recalcula en tiempo
  /// real cada vez que el usuario escribe en esos campos.
  final RxSet<int> duplicateIndices = <int>{}.obs;

  /// Índices (en `rows`) que coinciden con `searchQuery`. Si el query está
  /// vacío retorna todos. Búsqueda por nombre y código de barras.
  List<int> get filteredRowIndices {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      return List.generate(rows.length, (i) => i);
    }
    final indices = <int>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final n = r.nameController.text.toLowerCase();
      final b = r.barcodeController.text.toLowerCase();
      if (n.contains(q) || b.contains(q)) indices.add(i);
    }
    return indices;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  /// Engancha listeners a una fila para que los cambios disparen la
  /// re-validación de duplicados Y de completitud automáticamente.
  void _attachRowListeners(InitialInventoryRow row) {
    row.nameController.addListener(_onRowFieldChanged);
    row.barcodeController.addListener(_onRowFieldChanged);
    row.costPriceController.addListener(_onRowFieldChanged);
    row.sellingPriceController.addListener(_onRowFieldChanged);
    row.stockController.addListener(_onRowFieldChanged);
    row.minStockController.addListener(_onRowFieldChanged);
  }

  void _detachRowListeners(InitialInventoryRow row) {
    row.nameController.removeListener(_onRowFieldChanged);
    row.barcodeController.removeListener(_onRowFieldChanged);
    row.costPriceController.removeListener(_onRowFieldChanged);
    row.sellingPriceController.removeListener(_onRowFieldChanged);
    row.stockController.removeListener(_onRowFieldChanged);
    row.minStockController.removeListener(_onRowFieldChanged);
  }

  /// Un tick que obliga a re-computar validación por fila. Se incrementa
  /// en CADA tecleo en cualquier campo de cualquier fila. Los getters
  /// reactivos lo leen para que los `Obx` se re-construyan.
  final RxInt _rowFieldsTick = 0.obs;

  void _onRowFieldChanged() {
    _rowFieldsTick.value++;
    _recalculateDuplicates();
  }

  // ============================================================================
  // VALIDACIÓN DE CAMPOS REQUERIDOS POR FILA
  // ============================================================================

  /// Devuelve los nombres de campos requeridos que están vacíos en una fila.
  /// Campos requeridos: name, barcode, costPrice, sellingPrice, stock, minStock.
  /// Si la fila está totalmente vacía, retorna lista vacía (no se valida).
  Set<String> missingFieldsFor(int index) {
    _rowFieldsTick.value; // suscripción para Obx
    if (index < 0 || index >= rows.length) return const {};
    final r = rows[index];
    if (r.isEmpty) return const {}; // vacía: no se valida
    final missing = <String>{};
    if (r.nameController.text.trim().isEmpty) missing.add('name');
    if (r.barcodeController.text.trim().isEmpty) missing.add('barcode');
    if (r.costPriceController.text.trim().isEmpty) missing.add('costPrice');
    if (r.sellingPriceController.text.trim().isEmpty) {
      missing.add('sellingPrice');
    }
    if (r.stockController.text.trim().isEmpty) missing.add('stock');
    if (r.minStockController.text.trim().isEmpty) missing.add('minStock');
    return missing;
  }

  /// Índices de filas que tienen datos parciales pero les falta al menos
  /// un campo requerido. Las filas vacías NO cuentan (puede haber slots
  /// listos para llenar).
  List<int> get incompleteRowIndices {
    _rowFieldsTick.value; // suscripción para Obx
    final incomplete = <int>[];
    for (var i = 0; i < rows.length; i++) {
      if (missingFieldsFor(i).isNotEmpty) incomplete.add(i);
    }
    return incomplete;
  }

  /// True si se puede agregar una nueva fila (todas las filas iniciadas
  /// están completas). Una fila vacía NO bloquea, pero una parcial sí.
  bool get canAddNewRow => incompleteRowIndices.isEmpty;

  /// Resumen corto de filas incompletas para mostrar en banner.
  String get incompleteSummary {
    final incomplete = incompleteRowIndices;
    if (incomplete.isEmpty) return '';
    final names = incomplete
        .map((i) => rows[i].nameController.text.trim())
        .map((n) => n.isEmpty ? '(sin nombre)' : n)
        .take(3)
        .toList();
    final extra = incomplete.length > names.length ? '…' : '';
    return '${names.join(', ')}$extra';
  }

  /// Recorre todas las filas y marca como duplicadas (por índice) aquellas
  /// cuyo nombre o código de barras coincida con una fila previa. Ignora
  /// filas totalmente vacías. Se ejecuta en cada tecleo.
  void _recalculateDuplicates() {
    final dupes = <int>{};
    for (var i = 1; i < rows.length; i++) {
      final a = rows[i];
      final an = a.nameController.text.trim().toLowerCase();
      final ab = a.barcodeController.text.trim().toLowerCase();
      if (an.isEmpty && ab.isEmpty) continue;
      for (var j = 0; j < i; j++) {
        final b = rows[j];
        final bn = b.nameController.text.trim().toLowerCase();
        final bb = b.barcodeController.text.trim().toLowerCase();
        final matchName = an.isNotEmpty && an == bn;
        final matchBarcode = ab.isNotEmpty && ab == bb;
        if (matchName || matchBarcode) {
          dupes.add(i);
          break;
        }
      }
    }
    // RxSet no permite `.value = ...` — usamos clear + addAll
    duplicateIndices
      ..clear()
      ..addAll(dupes);
  }

  /// Descripción corta de los duplicados para mostrar en banner.
  String get duplicatesSummary {
    if (duplicateIndices.isEmpty) return '';
    final names = duplicateIndices
        .map((i) => rows[i].nameController.text.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .take(3)
        .toList();
    if (names.isEmpty) {
      return '${duplicateIndices.length} fila(s) con datos repetidos';
    }
    final extra = duplicateIndices.length > names.length ? '…' : '';
    return '${names.join(', ')}$extra';
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await loadCategories();
    final loaded = await loadDraft();
    if (!loaded) {
      for (int i = 0; i < 3; i++) {
        addRow();
      }
    }
  }

  @override
  void onClose() {
    saveDraft();
    for (var row in rows) {
      _detachRowListeners(row);
      row.dispose();
    }
    rows.clear();
    searchController.dispose();
    super.onClose();
  }

  // ============================================================================
  // DRAFT PERSISTENCE
  // ============================================================================

  Future<void> saveDraft() async {
    try {
      // Excluir filas vacías Y filas ya creadas exitosamente
      final pendingRows = rows.where((r) => !r.isEmpty && !(r.isProcessed && r.isSuccess)).toList();
      if (pendingRows.isEmpty) {
        await _storage.delete(_draftStorageKey);
        hasDraft.value = false;
        draftRowCount.value = 0;
        return;
      }

      final draftData = {
        'rows': pendingRows.map((r) => r.toJson()).toList(),
        'globalCategoryId': globalCategoryId.value,
        'globalCategoryName': globalCategoryName.value,
        'useGlobalCategory': useGlobalCategory.value,
        'savedAt': DateTime.now().toIso8601String(),
      };

      await _storage.write(_draftStorageKey, jsonEncode(draftData));
      hasDraft.value = true;
      draftRowCount.value = pendingRows.length;
    } catch (e) {
      print('Error saving draft: $e');
    }
  }

  /// Valida que un categoryId exista en las categorías disponibles
  bool _isCategoryValid(String? categoryId) {
    if (categoryId == null) return false;
    return availableCategories.any((c) => c.id == categoryId);
  }

  Future<bool> loadDraft() async {
    try {
      final data = await _storage.read(_draftStorageKey);
      if (data == null) {
        hasDraft.value = false;
        return false;
      }

      final json = jsonDecode(data) as Map<String, dynamic>;
      final rowList = json['rows'] as List<dynamic>?;
      if (rowList == null || rowList.isEmpty) {
        hasDraft.value = false;
        return false;
      }

      // Restore rows
      for (var rowJson in rowList) {
        final row = InitialInventoryRow.fromJson(rowJson as Map<String, dynamic>);
        // Validar que el categoryId del borrador aún existe
        if (!_isCategoryValid(row.categoryId)) {
          row.categoryId = null;
          row.categoryName = null;
        }
        _attachRowListeners(row);
        rows.add(row);
      }
      _recalculateDuplicates();

      // Restore global category (validar que aún existe)
      final savedGlobalCatId = json['globalCategoryId'] as String?;
      if (_isCategoryValid(savedGlobalCatId)) {
        globalCategoryId.value = savedGlobalCatId;
        globalCategoryName.value = json['globalCategoryName'];
      } else {
        globalCategoryId.value = null;
        globalCategoryName.value = null;
      }
      useGlobalCategory.value = json['useGlobalCategory'] ?? true;

      hasDraft.value = true;
      draftRowCount.value = rowList.length;
      return true;
    } catch (e) {
      print('Error loading draft: $e');
      return false;
    }
  }

  Future<void> clearDraft() async {
    try {
      await _storage.delete(_draftStorageKey);
      hasDraft.value = false;
      draftRowCount.value = 0;
    } catch (e) {
      print('Error clearing draft: $e');
    }
  }

  // ============================================================================
  // ROW MANAGEMENT
  // ============================================================================

  void addRow() {
    // Proteger: no dejar agregar nueva fila si hay filas con datos
    // parciales. Evita listas con filas a medias.
    if (!canAddNewRow) {
      _showIncompleteRowsBlocked(action: 'agregar una nueva fila');
      _expandFirstIncomplete();
      return;
    }
    _collapseAllRows();
    final newRow = InitialInventoryRow(isExpanded: true);
    _attachRowListeners(newRow);
    rows.add(newRow);
    _recalculateDuplicates();
  }

  /// Muestra snack rojo y expande la primera fila incompleta. Se usa cuando
  /// el usuario intenta agregar/duplicar filas pero hay pendientes.
  void _showIncompleteRowsBlocked({required String action}) {
    final incomplete = incompleteRowIndices;
    if (incomplete.isEmpty) return;
    Get.snackbar(
      'Completa los campos',
      'Hay ${incomplete.length} fila(s) con campos vacíos. '
          'Llena nombre, código de barras, costo, precio, stock y stock mín '
          'antes de $action.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: ElegantLightTheme.errorRed,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.warning_rounded, color: Colors.white),
    );
  }

  void _expandFirstIncomplete() {
    final incomplete = incompleteRowIndices;
    if (incomplete.isEmpty) return;
    final firstIdx = incomplete.first;
    for (var i = 0; i < rows.length; i++) {
      final shouldExpand = i == firstIdx;
      if (rows[i].isExpanded != shouldExpand) {
        rows[i].isExpanded = shouldExpand;
        rows[i] = rows[i]; // trigger Obx
      }
    }
  }

  void removeRow(int index) {
    if (index < 0 || index >= rows.length) return;
    if (rows.length <= 1) {
      Get.snackbar(
        'Aviso',
        'Debe mantener al menos una fila',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ElegantLightTheme.warningGradient.colors.first,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    final row = rows.removeAt(index);
    _detachRowListeners(row);
    row.dispose();
    _recalculateDuplicates();
  }

  void duplicateRow(int index) {
    if (index < 0 || index >= rows.length) return;
    if (!canAddNewRow) {
      _showIncompleteRowsBlocked(action: 'duplicar esta fila');
      _expandFirstIncomplete();
      return;
    }
    _collapseAllRows();
    final src = rows[index];
    final newRow = InitialInventoryRow(
      nameController: TextEditingController(text: src.nameController.text),
      barcodeController: TextEditingController(text: src.barcodeController.text),
      costPriceController: TextEditingController(text: src.costPriceController.text),
      sellingPriceController: TextEditingController(text: src.sellingPriceController.text),
      stockController: TextEditingController(text: src.stockController.text),
      minStockController: TextEditingController(text: src.minStockController.text),
      categoryId: src.categoryId,
      categoryName: src.categoryName,
      isExpanded: true,
    );
    _attachRowListeners(newRow);
    rows.insert(index + 1, newRow);
    _recalculateDuplicates();
  }

  void addMultipleRows(int count) {
    if (!canAddNewRow) {
      _showIncompleteRowsBlocked(action: 'agregar más filas');
      _expandFirstIncomplete();
      return;
    }
    _collapseAllRows();
    for (int i = 0; i < count; i++) {
      final r = InitialInventoryRow();
      _attachRowListeners(r);
      rows.add(r);
    }
    // Expandir la última fila agregada
    if (rows.isNotEmpty) {
      rows.last.isExpanded = true;
      rows[rows.length - 1] = rows.last;
    }
    _recalculateDuplicates();
  }

  void _collapseAllRows() {
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].isExpanded) {
        rows[i].isExpanded = false;
        rows[i] = rows[i];
      }
    }
  }

  void toggleExpand(int index) {
    if (index < 0 || index >= rows.length) return;
    final row = rows[index];
    row.isExpanded = !row.isExpanded;
    rows[index] = row; // trigger Obx
  }

  // ============================================================================
  // SKU GENERATION (interno, auto-generado al crear)
  // ============================================================================

  String _generateSkuForRow(int index) {
    if (index < 0 || index >= rows.length) return 'PRD000';
    final row = rows[index];
    final name = row.nameController.text.trim().toUpperCase();
    String prefix = 'PRD';
    if (name.isNotEmpty) {
      prefix = name.length >= 3
          ? name.substring(0, 3)
          : name.padRight(3, 'X');
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = index.toString().padLeft(2, '0');
    return '$prefix${timestamp.substring(7)}$suffix';
  }

  // ============================================================================
  // CATEGORY MANAGEMENT
  // ============================================================================

  Future<void> loadCategories() async {
    try {
      isLoadingCategories.value = true;
      final result = await _getCategoriesUseCase(
        const GetCategoriesParams(
          page: 1,
          limit: 100,
          status: CategoryStatus.active,
          onlyParents: true,
          sortBy: 'name',
          sortOrder: 'ASC',
        ),
      );
      result.fold(
        (failure) {
          Get.snackbar(
            'Error',
            'No se pudieron cargar las categorias: ${failure.message}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: ElegantLightTheme.errorGradient.colors.first,
            colorText: Colors.white,
          );
        },
        (paginatedCategories) {
          availableCategories.value = paginatedCategories.data;
          // Auto-seleccionar si solo hay una categoría disponible
          if (paginatedCategories.data.length == 1) {
            final cat = paginatedCategories.data.first;
            setGlobalCategory(cat.id, cat.name);
            useGlobalCategory.value = true;
          }
        },
      );
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void setGlobalCategory(String? categoryId, String? categoryName) {
    globalCategoryId.value = categoryId;
    globalCategoryName.value = categoryName;
    if (useGlobalCategory.value) {
      for (int i = 0; i < rows.length; i++) {
        rows[i].categoryId = categoryId;
        rows[i].categoryName = categoryName;
        rows[i] = rows[i];
      }
    }
  }

  void setRowCategory(int index, String? categoryId, String? categoryName) {
    if (index < 0 || index >= rows.length) return;
    rows[index].categoryId = categoryId;
    rows[index].categoryName = categoryName;
    rows[index] = rows[index];
  }

  void toggleUseGlobalCategory(bool enabled) {
    useGlobalCategory.value = enabled;
    if (enabled) {
      final catId = globalCategoryId.value;
      final catName = globalCategoryName.value;
      for (int i = 0; i < rows.length; i++) {
        rows[i].categoryId = catId;
        rows[i].categoryName = catName;
        rows[i] = rows[i];
      }
    }
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  String? validateRow(int index) {
    if (index < 0 || index >= rows.length) return 'Indice invalido';
    final row = rows[index];
    final name = row.nameController.text.trim();
    final stock = row.stockController.text.trim();
    final costPrice = row.costPriceController.text.trim();
    final sellingPrice = row.sellingPriceController.text.trim();

    if (name.isEmpty) return 'Nombre obligatorio';
    if (stock.isEmpty) return 'Stock obligatorio';

    final stockValue = AppFormatters.parseNumber(stock) ?? 0.0;
    if (stockValue <= 0) return 'Stock debe ser mayor a 0';

    final costValue = costPrice.isEmpty ? 0.0 : (AppFormatters.parseNumber(costPrice) ?? 0.0);
    final sellingValue = sellingPrice.isEmpty ? 0.0 : (AppFormatters.parseNumber(sellingPrice) ?? 0.0);
    if (costValue <= 0 && sellingValue <= 0) return 'Ingrese al menos un precio';

    return null;
  }

  List<String> validateAll() {
    final errors = <String>[];
    int validCount = 0;

    for (int i = 0; i < rows.length; i++) {
      if (rows[i].isEmpty) continue;

      final error = validateRow(i);
      if (error != null) {
        errors.add('Fila ${i + 1}: $error');
      } else {
        validCount++;
      }
    }

    if (validCount == 0 && errors.isEmpty) errors.add('Debe completar al menos un producto');

    if (useGlobalCategory.value &&
        (globalCategoryId.value == null || globalCategoryId.value!.isEmpty) &&
        availableCategories.length != 1) {
      errors.add('Seleccione una categoria global');
    }

    return errors;
  }

  void showValidationErrors(List<String> errors) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: ElegantLightTheme.errorGradient.colors.first),
            const SizedBox(width: 8),
            const Expanded(child: Text('Errores de Validacion', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Corrija los siguientes errores:'),
              const SizedBox(height: 12),
              ...errors.map((error) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(error, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  // ============================================================================
  // WAREHOUSE HELPER
  // ============================================================================

  String? _getDefaultWarehouseId() {
    final warehouses = InventoryLocalDataSourceIsar.getWarehousesMemoryCache();
    if (warehouses == null || warehouses.isEmpty) return null;
    // Buscar almacén principal, o usar el primero disponible
    final main = warehouses.cast<dynamic>().firstWhere(
      (w) => w.isMainWarehouse == true,
      orElse: () => warehouses.first,
    );
    return main.id as String;
  }

  // ============================================================================
  // SUBMISSION
  // ============================================================================

  Future<void> submitAll() async {
    // Corte duro: filas incompletas no se envían
    if (incompleteRowIndices.isNotEmpty) {
      _showIncompleteRowsBlocked(action: 'crear los productos');
      _expandFirstIncomplete();
      return;
    }

    // Corte duro: productos duplicados no se envían (ni se guardan).
    // Protege contra errores del usuario cuando la lista tiene muchas filas.
    if (duplicateIndices.isNotEmpty) {
      final list = duplicatesSummary;
      Get.snackbar(
        'Hay productos repetidos',
        list.isEmpty
            ? 'Elimina las filas duplicadas antes de crear los productos.'
            : 'Duplicados: $list. Elimínalos antes de continuar.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: ElegantLightTheme.errorRed,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: const Icon(Icons.error_rounded, color: Colors.white),
      );
      return;
    }

    final errors = validateAll();
    if (errors.isNotEmpty) {
      showValidationErrors(errors);
      return;
    }

    // 🔒 PREFLIGHT DE SUSCRIPCIÓN — funciona ONLINE y OFFLINE porque consulta
    // la suscripción cacheada (fecha de vencimiento). Si está expirada, NO
    // llamamos al use case: guardamos los datos como borrador y mostramos
    // el dialog de renovación. Evita perder el trabajo del usuario y no
    // llena la cola de sync con 50 operaciones que van a fallar.
    if (_isSubscriptionExpiredCached()) {
      await saveDraft();
      _showSubscriptionExpiredDialog();
      return;
    }

    try {
      isSubmitting.value = true;
      successCount.value = 0;
      failedCount.value = 0;
      currentProcessingIndex.value = 0;

      final validRows = <int>[];
      for (int i = 0; i < rows.length; i++) {
        if (!rows[i].isEmpty) validRows.add(i);
      }

      for (int i = 0; i < validRows.length; i++) {
        final rowIndex = validRows[i];
        currentProcessingIndex.value = i + 1;

        final success = await _submitRow(rowIndex);
        if (success) {
          successCount.value++;
        } else {
          failedCount.value++;
        }

        rows[rowIndex].isProcessed = true;
        rows[rowIndex].isSuccess = success;
        rows[rowIndex] = rows[rowIndex];
      }

      // Limpiar filas exitosas y actualizar borrador
      if (failedCount.value == 0) {
        // Todo exitoso: limpiar todo y borrar borrador
        _removeSuccessfulRows();
        await clearDraft();
      } else {
        // Parcial: remover exitosos automáticamente y guardar fallidos como borrador.
        // IMPORTANTE: esto es crítico cuando la suscripción está expirada y TODAS
        // las filas fallan — el usuario no debe perder su trabajo.
        _removeSuccessfulRows();
        await saveDraft();
      }

      // Si todas las filas fallaron por suscripción expirada, mostrar el
      // diálogo específico de renovación (no el genérico "Resultado").
      if (_allFailedBySubscription()) {
        _showSubscriptionExpiredDialog();
      } else {
        showSummaryDialog();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error inesperado: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: ElegantLightTheme.errorGradient.colors.first,
        colorText: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
      currentProcessingIndex.value = -1;
    }
  }

  /// Consulta la suscripción cacheada (sin hacer request al servidor) y
  /// determina si está expirada. Funciona offline porque solo lee el
  /// `endDate` + flag `isExpired` del último estado conocido.
  /// Si no hay SubscriptionController registrado, retorna false (no bloqueamos
  /// operaciones por un servicio no inicializado).
  bool _isSubscriptionExpiredCached() {
    try {
      if (!Get.isRegistered<SubscriptionController>()) return false;
      final sub = Get.find<SubscriptionController>().subscription;
      if (sub == null) return false;
      final daysRemaining = sub.endDate.difference(DateTime.now()).inDays;
      return sub.isExpired || daysRemaining <= 0;
    } catch (_) {
      return false;
    }
  }

  /// Detecta si TODAS las filas fallidas tienen un error de suscripción
  /// expirada. Solo entonces mostramos el diálogo específico de renovación
  /// en vez del genérico "Resultado".
  bool _allFailedBySubscription() {
    if (failedCount.value == 0) return false;
    if (successCount.value > 0) return false; // Parcial → dialog normal
    final failedRows = rows.where((r) => r.isProcessed && !r.isSuccess && r.errorMessage != null);
    if (failedRows.isEmpty) return false;
    return failedRows.every((r) => _isSubscriptionError(r.errorMessage!));
  }

  bool _isSubscriptionError(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('suscripción ha expirado') ||
        lower.contains('suscripcion ha expirado') ||
        lower.contains('actualice su plan') ||
        lower.contains('subscription expired') ||
        lower.contains('subscription has expired');
  }

  void _showSubscriptionExpiredDialog() {
    final pending = rows.where((r) => !r.isEmpty).length;
    SubscriptionErrorDialog.showSubscriptionExpired(
      customMessage: pending > 0
          ? 'No pudimos crear los productos porque tu suscripción está '
              'vencida. Tus $pending producto${pending == 1 ? '' : 's'} '
              'quedó guardado como borrador — no perdiste nada. '
              'Renueva tu plan y reintenta.'
          : 'Tu suscripción está vencida. Renueva tu plan para continuar '
              'creando productos.',
      onUpgradePressed: () {
        Get.toNamed('/settings/subscription');
      },
    );
  }

  Future<bool> _submitRow(int index) async {
    final row = rows[index];
    try {
      final name = row.nameController.text.trim();
      final sku = _generateSkuForRow(index);
      final barcode = row.barcodeController.text.trim();
      final stock = AppFormatters.parseNumber(row.stockController.text.trim()) ?? 0.0;
      final minStock = row.minStockController.text.trim().isEmpty
          ? 0.0
          : (AppFormatters.parseNumber(row.minStockController.text.trim()) ?? 0.0);
      final costPrice = row.costPriceController.text.trim().isEmpty
          ? 0.0
          : (AppFormatters.parseNumber(row.costPriceController.text.trim()) ?? 0.0);
      final sellingPrice = row.sellingPriceController.text.trim().isEmpty
          ? 0.0
          : (AppFormatters.parseNumber(row.sellingPriceController.text.trim()) ?? 0.0);

      String? categoryId;
      if (useGlobalCategory.value) {
        categoryId = globalCategoryId.value;
      } else {
        categoryId = row.categoryId;
      }

      // Fallback: si no hay categoría y solo hay una disponible, usarla
      if ((categoryId == null || categoryId.isEmpty) && availableCategories.length == 1) {
        categoryId = availableCategories.first.id;
      }

      if (categoryId == null || categoryId.isEmpty) {
        row.errorMessage = 'Categoria no seleccionada';
        rows[index] = row;
        return false;
      }

      // Solo precio de venta en el producto (NO costo — el costo va al lote FIFO)
      final prices = <CreateProductPriceParams>[];
      if (sellingPrice > 0) {
        prices.add(CreateProductPriceParams(type: PriceType.price1, name: 'Precio Publico', amount: sellingPrice));
      }

      // Crear producto con stock=0 y sin precio de costo
      // El stock se agrega via movimiento de inventario para respetar FIFO
      final params = CreateProductParams(
        name: name,
        sku: sku,
        barcode: barcode.isEmpty ? null : barcode,
        categoryId: categoryId,
        stock: 0,
        minStock: minStock,
        type: ProductType.product,
        status: ProductStatus.active,
        prices: prices,
        isTaxable: false,
        taxCategory: TaxCategory.noGravado,
        taxRate: 0,
      );

      final result = await _createProductUseCase(params);

      // Extraer producto o error
      Product? createdProduct;
      String? productError;
      result.fold(
        (failure) => productError = failure.message,
        (product) => createdProduct = product,
      );

      if (productError != null) {
        row.errorMessage = 'Error: $productError';
        rows[index] = row;
        return false;
      }

      // Producto creado — ahora crear movimiento de inventario para el stock inicial
      // El unitCost va directamente al lote/batch (sin crear ProductPrice de costo)
      if (stock > 0) {
        final unitCost = costPrice > 0
            ? costPrice
            : (sellingPrice > 0 ? sellingPrice * 0.7 : 1000.0);

        final warehouseId = _getDefaultWarehouseId();

        final movementResult = await _createMovementUseCase(
          CreateInventoryMovementParams(
            productId: createdProduct!.id,
            type: InventoryMovementType.inbound,
            reason: InventoryMovementReason.purchase,
            quantity: stock.round(),
            unitCost: unitCost,
            warehouseId: warehouseId,
            notes: 'Stock inicial - Inventario inicial',
          ),
        );

        String? movementError;
        movementResult.fold(
          (failure) => movementError = failure.message,
          (_) {},
        );

        if (movementError != null) {
          row.errorMessage = 'Producto creado pero error en stock: $movementError';
          rows[index] = row;
          return false;
        }
      }

      row.errorMessage = null;
      rows[index] = row;
      return true;
    } catch (e) {
      row.errorMessage = 'Excepcion: $e';
      rows[index] = row;
      return false;
    }
  }

  // ============================================================================
  // UI HELPERS
  // ============================================================================

  void confirmResetAll() {
    final nonEmptyCount = rows.where((r) => !r.isEmpty).length;
    if (nonEmptyCount == 0) {
      _doResetAll();
      return;
    }

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ElegantLightTheme.warningGradient.colors.first),
            const SizedBox(width: 8),
            const Expanded(child: Text('Limpiar todo', overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Text(
          'Se eliminaran $nonEmptyCount producto${nonEmptyCount == 1 ? '' : 's'} con datos.\n\nEsta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              _doResetAll();
            },
            child: Text('Limpiar', style: TextStyle(color: ElegantLightTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  void _doResetAll() {
    for (var row in rows) {
      row.dispose();
    }
    rows.clear();
    successCount.value = 0;
    failedCount.value = 0;
    currentProcessingIndex.value = -1;
    addMultipleRows(3);
    clearDraft();
  }

  void showSummaryDialog() {
    // Capturar valores antes de mostrar (las filas exitosas ya fueron removidas)
    final succeeded = successCount.value;
    final failed = failedCount.value;

    // Recopilar info de filas fallidas (las que quedaron en la lista)
    final failedInfo = <String>[];
    for (var row in rows) {
      if (row.errorMessage != null) {
        failedInfo.add('${row.nameController.text}: ${row.errorMessage}');
      }
    }

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(
              failed == 0 ? Icons.check_circle : Icons.info_outline,
              color: failed == 0
                  ? ElegantLightTheme.successGradient.colors.first
                  : ElegantLightTheme.warningGradient.colors.first,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                failed == 0 ? 'Productos Creados' : 'Resultado',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (succeeded > 0)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.successGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$succeeded producto${succeeded == 1 ? '' : 's'} creado${succeeded == 1 ? '' : 's'} exitosamente',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              if (failed > 0) ...[
                if (succeeded > 0) const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: ElegantLightTheme.errorGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$failed producto${failed == 1 ? '' : 's'} con error',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Los productos con error se mantienen en la lista para que pueda corregirlos y reintentar.',
                  style: TextStyle(fontSize: 12, color: ElegantLightTheme.textSecondary),
                ),
                if (failedInfo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: failedInfo.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${failedInfo[index]}',
                            style: TextStyle(fontSize: 11, color: ElegantLightTheme.errorRed),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
              if (failed == 0 && succeeded > 0) ...[
                const SizedBox(height: 10),
                Text(
                  'Puede seguir agregando productos o salir de esta pantalla.',
                  style: TextStyle(fontSize: 12, color: ElegantLightTheme.textSecondary),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              successCount.value = 0;
              failedCount.value = 0;
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _removeSuccessfulRows() {
    final remaining = <InitialInventoryRow>[];
    for (var row in rows) {
      if (row.isProcessed && row.isSuccess) {
        row.dispose();
      } else {
        // Resetear estado para permitir reintentar
        if (row.isProcessed && !row.isSuccess) {
          row.isProcessed = false;
        }
        remaining.add(row);
      }
    }
    rows.value = remaining;
    if (rows.isEmpty) addMultipleRows(3);
  }
}
