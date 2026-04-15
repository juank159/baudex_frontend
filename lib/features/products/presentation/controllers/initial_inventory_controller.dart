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
import '../../../inventory/data/datasources/inventory_local_datasource_isar.dart';

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
      row.dispose();
    }
    rows.clear();
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
        rows.add(row);
      }

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
    _collapseAllRows();
    final newRow = InitialInventoryRow(isExpanded: true);
    rows.add(newRow);
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
    row.dispose();
  }

  void duplicateRow(int index) {
    if (index < 0 || index >= rows.length) return;
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
    rows.insert(index + 1, newRow);
  }

  void addMultipleRows(int count) {
    _collapseAllRows();
    for (int i = 0; i < count; i++) {
      rows.add(InitialInventoryRow());
    }
    // Expandir la última fila agregada
    if (rows.isNotEmpty) {
      rows.last.isExpanded = true;
      rows[rows.length - 1] = rows.last;
    }
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
    final errors = validateAll();
    if (errors.isNotEmpty) {
      showValidationErrors(errors);
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
        // Parcial: remover exitosos automáticamente y guardar fallidos como borrador
        _removeSuccessfulRows();
        await saveDraft();
      }

      showSummaryDialog();
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
